unit citk.encrypt;
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
  Classes, SysUtils;

type
  IEncrypter = interface
    ['{C994BB10-C9A4-4584-8EF1-6B2B2D8F654D}']
    function Encrypt(const Value: string): string;
    function Decrypt(const Value: string): string;
    function GetPublicKey: string;
    procedure SetPublicKey(AValue: string);
    property PublicKey: string read GetPublicKey write SetPublicKey;
  end;

  { TEncrypter }

  TEncrypter = class(TInterfacedObject, IEncrypter)
  private
    FPublicKey: string;
    function GetPublicKey: string;
    procedure SetPublicKey(AValue: string);
  public
    constructor Create; virtual; overload;
    constructor Create(const PublicKey: string); virtual; overload;
    function Encrypt(const Value: string): string;
    function Decrypt(const Value: string): string;
    property PublicKey: string read GetPublicKey write SetPublicKey;
  end;

implementation

uses
  Chtilux.Crypt;

{ TEncrypter }

procedure TEncrypter.SetPublicKey(AValue: string);
begin
  if FPublicKey=AValue then Exit;
  FPublicKey:=AValue;
end;

function TEncrypter.GetPublicKey: string;
begin
  Result := FPublicKey;
end;

constructor TEncrypter.Create;
begin
  FPublicKey:='';
end;

constructor TEncrypter.Create(const PublicKey: string);
begin
  FPublicKey:=PublicKey;
end;

function TEncrypter.Encrypt(const Value: string): string;
begin
  if FPublicKey.IsEmpty then
    Result := Value
  else
    Result := Chtilux.Crypt.EnCrypt(FPublicKey, Value);
end;

function TEncrypter.Decrypt(const Value: string): string;
begin
  if FPublicKey.IsEmpty then
    Result := Value
  else
    Result := Chtilux.Crypt.DeCrypt(FPublicKey, Value);
end;

end.

