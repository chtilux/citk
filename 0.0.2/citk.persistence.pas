unit citk.persistence;
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

