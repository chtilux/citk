unit citk.login;
(*
    This file is part of citk.

    CelineInTheKitchen software suite. Copyright (C) 2022 Luc Lacroix
      chtilux software

  *** BEGIN LICENSE BLOCK *****
  Version: MPL 1.1/GPL 2.0/LGPL 2.1

  The contents of this file are subject to the Mozilla Public License Version
  1.1 (the "License"); you may not use this file except in compliance with
  the License. You may obtain a copy of the License at
  http://www.mozilla.org/MPL

  Software distributed under the License is distributed on an "AS IS" basis,
  WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
  for the specific language governing rights and limitations under the License.

  The Original Code is citk.

  The Initial Developer of the Original Code is Luc Lacroix.

  Portions created by the Initial Developer are Copyright (C) 2022
  the Initial Developer. All Rights Reserved.

  Contributor(s):
    Luc Lacroix (chtilux)

  Alternatively, the contents of this file may be used under the terms of
  either the GNU General Public License Version 2 or later (the "GPL"), or
  the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
  in which case the provisions of the GPL or the LGPL are applicable instead
  of those above. If you wish to allow use of your version of this file only
  under the terms of either the GPL or the LGPL, and not to allow others to
  use your version of this file under the terms of the MPL, indicate your
  decision by deleting the provisions above and replace them with the notice
  and other provisions required by the GPL or the LGPL. If you do not delete
  the provisions above, a recipient may use your version of this file under
  the terms of any one of the MPL, the GPL or the LGPL.

  ***** END LICENSE BLOCK *****

*)

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, citk.global, citk.loginDialog;

function Login(Info: TInfo): boolean;

implementation

uses
  Controls, citk.firebird, citk.User,
  IBConnection, citk.database, citk.dictionary;

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
  try
    sel := SelectSQLDirect(dic.GetPasswordChar);
  except
    on E:EIBDatabaseError do
    begin
      if (Pos('Table unknown', E.Message) > 0) and
         (Pos('DICTIONNAIRE', E.Message) > 0) then
      begin
        RunDatabaseScript(Info);
        sel := SelectSQLDirect(dic.GetPasswordChar);
      end;
    end
    else
      raise;
  end;

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
begin
  Result := False;
  try
    { il faut afficher la fenêtre de connexion }
    DoBeforeLogin(Info);
    Info.Log(Format('User=%s, Password=%s',[Info.User.Login,Info.User.Password]));
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

    //if (Info.User.Login='') or (Info.User.Password='')  or (CompareText(Info.user.Password, Info.DefaultUserPassword)=0) then
    //begin
    //
    //  dlg := TLoginW.Create(nil, Info);
    //  try
    //    if dlg.ShowModal = mrOk then
    //    begin
    //      Info.User.Login:=dlg.UserNameEdit.Text;
    //      Info.Log('Logged as ' + Info.User.Login);
    //      Info.LoggedIn:= True;
    //      Result := True;
    //    end
    //    else
    //      Info.Log('Not logged in');
    //  finally
    //    dlg.Free;
    //  end;
    //end
    //else
    //begin
    //  try
    //    if FBTableExists('USERS') then
    //    begin
    //      { contrôler le tupple login/password }
    //      user := TUsers.Create(TFirebirdPersistence.Create(Info.Cnx, Info.Crypter));
    //      Info.LoggedIn:=user.LoginPasswordIsValid(Info.User);
    //    end
    //    else
    //    begin
    //      Info.User.Login:='SYSDBA';
    //      Info.LoggedIn := True;
    //      Info.Log('Logged in as SYSDBA');
    //    end;
    //  except
    //    on E:EAssertionFailed do
    //    begin
    //      Info.Log(E.Message);
    //      Info.User.Login:='SYSDBA';
    //      Info.LoggedIn := True;
    //      Info.Log('Logged in as SYSDBA');
    //    end
    //    else
    //      raise;
    //  end;
    //  Result := Info.LoggedIn;
    //end;
  except
    on E:EIBDatabaseError do
    begin
      Info.Log(E.Message);
      raise;
    end
    else
      raise;
  end;
end;

end.

