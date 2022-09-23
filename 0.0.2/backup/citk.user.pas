unit citk.user;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, citk.persistence, citk.encrypt;

type

  { IUserInfo }

  IUserInfo = interface
  ['{93A48A24-6E96-43C7-A500-619D7207CC2D}']
    function GetLogin: string;
    function GetSetPassword: boolean;
    procedure SetLogin(AValue: string);
    function GetPassword: string;
    procedure SetPassword(AValue: string);
    function GetActive: boolean;
    procedure SetActive(AValue: boolean);
    procedure SetSetPassword(AValue: boolean);
    property Login: string read GetLogin write SetLogin;
    property Password: string read GetPassword write SetPassword;
    property Active: boolean read GetActive write SetActive;
    property UserMustSetPassword: boolean read GetSetPassword write SetSetPassword;
  end;

  EUserInfo = class(Exception);

  { TUserInfo }

  TUserInfo = class(TInterfacedObject, IUserInfo)
  private
    FLogin: string;
    FPassword: string;
    FSetPassword: boolean;
  private
    FActive: boolean;
    function GetActive: boolean;
    function GetLogin: string;
    function GetSetPassword: boolean;
    procedure SetActive(AValue: boolean);
    procedure SetLogin(AValue: string);
    function GetPassword: string;
    procedure SetPassword(AValue: string);
    procedure SetSetPassword(AValue: boolean);
  public
    constructor Create(const Login, Password: string); virtual; overload;
    constructor Create; virtual; overload;
    property Login: string read GetLogin write SetLogin;
    property Password: string read GetPassword write SetPassword;
    property Active: boolean read GetActive write SetActive;
    property UserMustSetPassword: boolean read GetSetPassword write SetSetPassword;
  end;

  IUsers = interface
  ['{FA618070-8F29-4AE3-8470-286D313BAFEF}']
    function LoginExists(User: IUserInfo): boolean;
    function LoginPasswordIsValid(User: IUserinfo): boolean;
    procedure SetUserPassword(User: IUserInfo; Crypter: IEncrypter);
  end;

  { TUsers }

  TUsers = class(TInterfacedObject, IUsers)
  private
    FPersistence: IPersistence;
  public
    constructor Create(Persistence: IPersistence); virtual;
    function LoginExists(User: IUserInfo): boolean;
    function LoginPasswordIsValid(User: IUserinfo): boolean;
    procedure SetUserPassword(User: IUserInfo; Crypter: IEncrypter);
  end;

implementation

uses
  Chtilux.Crypt;

{ TUsers }

constructor TUsers.Create(Persistence: IPersistence);
begin
  FPersistence := Persistence;
end;

function TUsers.LoginExists(User: IUserInfo): boolean;
var
  Active, UserMustSetPassword: boolean;
begin
  Result := FPersistence.LoginExists(User.Login, Active, UserMustSetPassword);
  if Result then
  begin
    User.Active:=Active;
    User.UserMustSetPassword := UserMustSetPassword;
  end;
end;

function TUsers.LoginPasswordIsValid(User: IUserinfo): boolean;
var
  Active, UserMustSetPassword: boolean;
begin
  Result := FPersistence.LoginPasswordIsValid(User.Login, User.Password, Active, UserMustSetPassword);
  if Result then
  begin
    User.Active:=Active;
    User.UserMustSetPassword := UserMustSetPassword;
  end;
end;

procedure TUsers.SetUserPassword(User: IUserInfo; Crypter: IEncrypter);
begin
  FPersistence.SetUserPassword(User.Login, Crypter.encrypt(User.Password));
end;

{ TUserInfo }

function TUserInfo.GetLogin: string;
begin
  Result := FLogin;
end;

function TUserInfo.GetSetPassword: boolean;
begin
  Result := FSetPassword;
end;

function TUserInfo.GetActive: boolean;
begin
  Result := FActive;
end;

procedure TUserInfo.SetActive(AValue: boolean);
begin
  if FActive=AValue then Exit;
  FActive:=AValue;
end;

procedure TUserInfo.SetLogin(AValue: string);
begin
  if FLogin=AValue then Exit;
//  FLogin:=AValue.ToUpper;
  FLogin:=AValue;
end;

function TUserInfo.GetPassword: string;
begin
  Result := FPassword;
end;

procedure TUserInfo.SetPassword(AValue: string);
begin
  if FPassword=AValue then Exit;
  FPassword:=AValue;
end;

procedure TUserInfo.SetSetPassword(AValue: boolean);
begin
  if FSetPassword=AValue then Exit;
  FSetPassword:=AValue;
end;

constructor TUserInfo.Create(const Login, Password: string);
begin
  Self.Login:=Login;
  Self.Password:=Password;
  Self.Active:=False;
  Self.UserMustSetPassword:=False;
end;

constructor TUserInfo.Create;
begin
  Create('','');
end;

end.

