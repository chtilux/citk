unit citk.login;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, citk.global, citk.loginDialog;

procedure Login(Info: TInfo);

implementation

uses
  Chtilux.Crypt, ZConnection, ZClasses, Controls;

procedure Login(Info: TInfo);
var
  dlg: TLoginW;
begin
  if Info.Cnx.Connected then
    Info.Cnx.Disconnect;
  Info.Cnx.User:=Info.DBA;
  Info.Cnx.Password:=Decrypt(Info.Key, Info.DBAPwd);
  try
    Info.Cnx.Connect;
    dlg := TLoginW.Create(nil, Info);
    try
      if dlg.ShowModal = mrOk then
      begin
        Info.User.Login:=dlg.UserNameEdit.Text;
        Info.Log('Logged as ' + Info.User.Login);
      end;
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

