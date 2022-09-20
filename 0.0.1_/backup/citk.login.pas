unit citk.login;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, citk.global, citk.loginDialog;

function Login(Info: TInfo): boolean;

implementation

uses
  Chtilux.Crypt, ZConnection, ZClasses, Controls, citk.firebird;

procedure DoBeforeLogin(Info: TInfo);
var
  sel: TStrings;
  PasswordChar: string;
begin
  PasswordChar := Info.PasswordChar;
  citk.Firebird.SetConnection(Info.Cnx);
  citk.firebird.SetLogger(Info.Logger);
  sel := SelectSQLDirect('SELECT pardc1 as PasswordChar FROM dictionnaire'
                        +' WHERE cledic = ' + 'security'.QuotedString
                        +'   AND coddic = ' + 'password char'.QuotedString);
  try
    PasswordChar := sel.Values['PasswordChar'].Trim;
    if not PasswordChar.IsEmpty then
    begin
      Info.PasswordChar:=PasswordChar[1];
      Log('Setting Password char to ' + Info.PasswordChar);
    end;
  finally
    sel.Free;
  end;
end;

function Login(Info: TInfo): boolean;
var
  dlg: TLoginW;
begin
  Result := False;
  if Info.Cnx.Connected then
    Info.Cnx.Disconnect;
  Info.Cnx.User:=Info.DBA;
  Info.Cnx.Password:=Decrypt(Info.Key, Info.DBAPwd);
  try
    Info.Cnx.Connect;
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
  except
    on E:EZSQLException do
    begin
      Info.Log(E.Message);
      raise;
    end
    else
      raise;
  end;
end;

end.

