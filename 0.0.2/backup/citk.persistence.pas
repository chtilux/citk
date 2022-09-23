unit citk.persistence;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, citk.encrypt, sqldb;

type
  IPersistence = interface
  ['{9C3AAA81-6616-4EF5-8C83-B5B6C8CCED79}']
    function LoginExists(const Login: string; out Active, UserMustSetPassword: boolean): boolean;
    function LoginPasswordIsValid(const Login, Password: string; out Active, UserMustSetPassword: boolean): boolean;
    procedure SetUserPassword(const Login, Password: string);
  end;

  { TPersistence }

  TPersistence = class(TInterfacedObject, IPersistence)
  public
    function LoginExists(const Login: string; out Active, UserMustSetPassword: boolean): boolean; virtual;
    function LoginPasswordIsValid(const Login, Password: string; out Active, UserMustSetPassword: boolean): boolean; virtual;
    procedure SetUserPassword(const Login, Password: string); virtual;
  end;

  { TFirebirdPersistence }

  TFirebirdPersistence = class(TPersistence)
  private
    FConnection: TSQLConnector;
    FCrypter: IEncrypter;
    procedure SetConnection(AValue: TSQLConnector);
  public
    constructor Create(Connection: TSQLConnector; Crypter: IEncrypter); virtual;
    function LoginExists(const Login: string; out Active, UserMustSetPassword: boolean): boolean; override;
    function LoginPasswordIsValid(const Login, Password: string; out Active, UserMustSetPassword: boolean): boolean; override;
    property Connection: TSQLConnector read FConnection write SetConnection;
    procedure SetUserPassword(const Login, Password: string); override;
  end;

  IDictionary = interface
  ['{DEB022DB-0701-42AC-A626-CBD3C002F47D}']
    function GetSQL: string;
    function GetPasswordChar: string;
  end;

  { TDictionary }

  TDictionary = class(TInterfacedObject, IDictionary)
  public
    function GetSQL: string;
    function GetPasswordChar: string;
  end;

  IProducts = interface
  ['{68DAA6BD-8276-43DA-BBD2-AF99C65050A0}']
    function GetSQL: string;
    function GetPKSQL: string;
    function GetPriceSQL(const AType: string): string;
    function GetInsertPriceSQL: string;
    function GetUpdatePriceSQL: string;
    function GetDeletePriceSQL: string;
    function GetDeleteProductPricesSQL: string;
  end;

  { TProducts }

  TProducts = class(TInterfacedObject, IProducts)
  public
    function GetSQL: string;
    function GetPKSQL: string;
    function GetPriceSQL(const AType: string): string;
    function GetInsertPriceSQL: string;
    function GetUpdatePriceSQL: string;
    function GetDeletePriceSQL: string;
    function GetDeleteProductPricesSQL: string;
  end;

implementation

uses
  ZDataset, Chtilux.Crypt;

{ TProducts }

function TProducts.GetSQL: string;
begin
  Result := 'SELECT serprd, codprd, libprd, active'
           +' FROM products'
           +' ORDER BY libprd';
end;

function TProducts.GetPKSQL: string;
begin
  Result := 'SELECT GEN_ID(SEQ_PRODUCTS,1) FROM rdb$database';
end;

function TProducts.GetPriceSQL(const AType: string): string;
begin
  Result := 'SELECT serprc,serprd,dateff,qtymin,price,ptype'
           +' FROM prices'
           +' WHERE serprd = :serprd'
           +'   AND ptype = ' + QuotedStr(AType)
           +' ORDER BY dateff DESC';
end;

function TProducts.GetInsertPriceSQL: string;
begin
  Result := 'INSERT INTO prices(serprc,serprd,dateff,qtymin,price,ptype)'
           +' VALUES (:serprc,:serprd,:dateff,:qtymin,:price,:ptype)';
end;

function TProducts.GetUpdatePriceSQL: string;
begin
  Result := 'UPDATE prices'
           +' SET dateff = :dateff'
           +'    ,qtymin = :qtymin'
           +'    ,price  = :price'
           +' WHERE serprc = :serprc';
end;

function TProducts.GetDeletePriceSQL: string;
begin
  Result := 'DELETE FROM prices WHERE serprc = :serprc';
end;

function TProducts.GetDeleteProductPricesSQL: string;
begin
  Result := 'DELETE FROM prices WHERE serprd = :serprd';
end;

{ TPersistence }

function TPersistence.LoginExists(const Login: string; out Active,
  UserMustSetPassword: boolean): boolean;
begin
  Result := False;
end;

function TPersistence.LoginPasswordIsValid(const Login, Password: string; out Active, UserMustSetPassword: boolean): boolean;
begin
  Result := False;
end;

procedure TPersistence.SetUserPassword(const Login, Password: string);
begin
end;

{ TFirebirdPersistence }

procedure TFirebirdPersistence.SetConnection(AValue: TSQLConnector);
begin
  if FConnection=AValue then Exit;
  FConnection:=AValue;
end;

constructor TFirebirdPersistence.Create(Connection: TSQLConnector; Crypter: IEncrypter);
begin
  FConnection:=Connection;
  FCrypter:=Crypter;
end;

function TFirebirdPersistence.LoginExists(const Login: string; out Active,
  UserMustSetPassword: boolean): boolean;
var
  z: TSQLQuery;
begin
  UserMustSetPassword:=False;
  z := TSQLQuery.Create(nil);
  try
    z.SQLConnection := FConnection;
    z.Transaction:=FConnection.Transaction;
    z.SQL.Add('SELECT login, password, active'
             +' FROM users'
             +' WHERE login = :login');
    z.Params[0].AsString:=Login;
    z.Open;
    Result := not z.Eof;
    { le record existe }
    if Result then
    begin
      { l'utilisateur est-il actif }
      Active := z.Fields[2].AsBoolean;
      if z.Fields[1].AsString = FCrypter.PublicKey then
        UserMustSetPassword:=True;
    end;
  finally
    z.Free;
  end;
end;

function TFirebirdPersistence.LoginPasswordIsValid(const Login, Password: string; out Active, UserMustSetPassword: boolean): boolean;
var
  z: TSQLQuery;
begin
  UserMustSetPassword:=False;
  z := TSQLQuery.Create(nil);
  try
    z.SQLConnection := FConnection;
    z.Transaction:=FConnection.Transaction;
    z.SQL.Add('SELECT login, password, active'
             +' FROM users'
             +' WHERE login = :login');
    z.Params[0].AsString:=Login;
    z.Open;
    { le record existe }
    if not z.Eof then
    begin
      { comparaison du mot de passe entré par l'utilisateur avec le mot de passe crypté }
      Result := Password = FCrypter.Decrypt(z.Fields[1].AsString);
      { si c'est correct }
      if Result then
        { l'utilisateur est-il actif }
        Active := z.Fields[2].AsBoolean
      else
      begin
        { si le mot de passe de la base de données est le mot de passe par défaut, l'utilisateur doit encoder son mot de passe }
        if z.Fields[1].AsString = FCrypter.PublicKey then
          UserMustSetPassword:=True
        else
          Result := inherited;
      end;
    end
    else
      Result := inherited;
  finally
    z.Free;
  end;
end;

procedure TFirebirdPersistence.SetUserPassword(const Login, Password: string);
var
  z: TSQLQuery;
begin
  z := TSQLQuery.Create(nil);
  try
    z.SQLConnection := FConnection;
    z.Transaction:=FConnection.Transaction;
    z.SQL.Add('UPDATE users'
             +' SET password = :password'
             +' WHERE login = :login');
    z.Params[0].AsString:=Password;
    z.Params[1].AsString:=Login;
    z.ExecSQL;
    FConnection.Transaction.Commit;
  finally
    z.Free;
  end;
end;

{ TDictionary }

function TDictionary.GetSQL: string;
begin
  Result := 'SELECT * FROM dictionnaire ORDER BY cledic, coddic';
end;

function TDictionary.GetPasswordChar: string;
begin
  Result := 'SELECT pardc1 as PasswordChar FROM dictionnaire'
           +' WHERE cledic = ' + 'security'.QuotedString
           +'   AND coddic = ' + 'password char'.QuotedString;
end;

end.

