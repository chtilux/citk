unit citk.customers;
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
  Classes, SysUtils, citk.DataObject;

type
  ECustomers = class(Exception);
  ICustomers = interface
  ['{A8C5CDA4-65E2-4D9A-9A83-4B98576D4F00}']
    function GetSQL: string;
    function GetPKSQL: string;
    function GetCustomerName(const ID: integer): string;
    function GetCustomerName(const ANamePart: string): string;
  end;

  { TCustomers }

  TCustomers = class(TInterfacedObject, ICustomers)
  private
    FDataObject: IDataObject;
  public
    constructor Create; overload;
    constructor Create(DataObject: IDataObject); overload;
    function GetSQL: string;
    function GetPKSQL: string;
    function GetCustomerName(const ID: integer): string; overload;
    function GetCustomerName(const ANamePart: string): string; overload;
  end;

implementation

uses
  SQLDB;

{ TCustomers }

constructor TCustomers.Create;
begin

end;

constructor TCustomers.Create(DataObject: IDataObject);
begin
  FDataObject:=DataObject;
  Create;
end;

function TCustomers.GetSQL: string;
begin
  Result := 'SELECT sercust, custname'
           +' FROM customers'
           +' WHERE custname LIKE :custname'
           +' ORDER BY custname';
end;

function TCustomers.GetPKSQL: string;
begin
  Result := 'SELECT GEN_ID(SEQ_CUSTOMERS,1) FROM rdb$database';
end;

function TCustomers.GetCustomerName(const ID: integer): string;
begin
  with FDataObject.GetQuery do
  begin
    try
      SQL.Add('SELECT custname FROM customers WHERE sercust = :ID');
      Params[0].AsInteger:=ID;
      Open;
      if not Eof then
        Result := Fields[0].AsString
      else
        raise ECustomers.CreateFmt('Customer %d does not exists !', [ID]);
    finally
      Free;
    end
  end;
end;

function TCustomers.GetCustomerName(const ANamePart: string): string;
begin
  with FDataObject.GetQuery do
  begin
    try
      SQL.Add('SELECT FIRST 1 custname FROM customers WHERE custname like :APart');
      Params[0].AsString:='%'+ANamePart+'%';
      Open;
      if not Eof then
        Result := Fields[0].AsString
      else
        raise ECustomers.CreateFmt('Customer %s does not exists !', [ANamePart]);
    finally
      Free;
    end
  end;
end;

end.

