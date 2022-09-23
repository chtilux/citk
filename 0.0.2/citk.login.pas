unit citk.login;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, citk.global, citk.loginDialog;

function Login(Info: TInfo): boolean;

implementation

uses
  Chtilux.Crypt{, ZConnection, ZClasses}, DB, Controls, citk.firebird, citk.persistence, citk.User;

procedure DoBeforeLogin(Info: TInfo);
var
  sel: TStrings;
  PasswordChar: string;
  dic: IDictionary;
begin
  PasswordChar := Info.PasswordChar;
  citk.Firebird.SetConnection(Info.Cnx, Info.Transaction);
  citk.firebird.SetLogger(Info.Logger);
  dic := TDictionary.Create;
  sel := SelectSQLDirect(dic.GetPasswordChar);
  try
    PasswordChar := sel.Values['PasswordChar'].Trim;
    if not PasswordChar.IsEmpty then
    begin
      Info.PasswordChar:=PasswordChar[1];
      Info.Log('Setting Password char to ' + Info.PasswordChar);
    end;
  finally
    sel.Free;
  end;
end;

function Login(Info: TInfo): boolean;
var
  dlg: TLoginW;
  user: IUsers;
begin
  Result := False;
  if Info.Cnx.Connected then
    Info.Cnx.Connected:=False;
  Info.Cnx.UserName:=Info.DBA;
  Info.Cnx.Password:=Decrypt(Info.Key, Info.DBAPwd);
  try
    Info.Cnx.Connected:=True;
    { il faut afficher la fenêtre de connexion }
    if (Info.User.Login='') or (Info.User.Password='')  or (CompareText(Info.user.Password, Info.DefaultUserPassword)=0) then
    begin
      DoBeforeLogin(Info);
      dlg := TLoginW.Create(nil, Info);
      try
        if dlg.ShowModal = mrOk then
        begin
          Info.User.Login:=dlg.UserNameEdit.Text;
          Info.Log('Logged as ' + Info.User.Login);
          Info.LoggedIn:= True;
          Result := True;
        end
        else
          Info.Log('Not logged in');
      finally
        dlg.Free;
      end;
    end
    else
    begin
      try
        if FBTableExists('USERS') then
        begin
          { contrôler le tupple login/password }
          user := TUsers.Create(TFirebirdPersistence.Create(Info.Cnx, Info.Crypter));
          Info.LoggedIn:=user.LoginPasswordIsValid(Info.User);
        end
        else
        begin
          Info.User.Login:='SYSDBA';
          Info.LoggedIn := True;
          Info.Log('Logged in as SYSDBA');
        end;
      except
        on E:EAssertionFailed do
        begin
          Info.Log(E.Message);
          Info.User.Login:='SYSDBA';
          Info.LoggedIn := True;
          Info.Log('Logged in as SYSDBA');
        end
        else
          raise;
      end;
      Result := Info.LoggedIn;
    end;
  except
    on E:EDatabaseError do
    begin
      Info.Log(E.Message);
      raise;
    end
    else
      raise;
  end;
end;

end.

