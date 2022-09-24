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

implementation

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

end.

