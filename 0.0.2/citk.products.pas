unit citk.products;
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
  TProduct = class;

  IProducts = interface
  ['{68DAA6BD-8276-43DA-BBD2-AF99C65050A0}']
    function GetSQL: string;
    function GetPKSQL: string;
    function GetPriceSQL(const AType: string): string;
    function GetInsertPriceSQL: string;
    function GetUpdatePriceSQL: string;
    function GetDeletePriceSQL: string;
    function GetDeleteProductPricesSQL: string;
    //function GetEventProducts(const serevt: integer): string;
    function GetProduct(const ID: integer): TProduct;
  end;

  { TProducts }

  TProducts = class(TInterfacedObject, IProducts)
  private
    FDataObject: IDataObject;
  public
    constructor Create; overload;                overload;
    constructor Create(DataObject: IDataObject); overload;
    function GetSQL: string;
    function GetPKSQL: string;
    function GetPriceSQL(const AType: string): string;
    function GetInsertPriceSQL: string;
    function GetUpdatePriceSQL: string;
    function GetDeletePriceSQL: string;
    function GetDeleteProductPricesSQL: string;
    //function GetEventProducts(const serevt: integer): string;
    function GetProduct(const ID: integer): TProduct;
  end;

  TProduct = class(TObject)
  private
    FVATCode: string;
    FVATRate: double;
    procedure SetVATCode(AValue: string);
    procedure SetVATRate(AValue: double);
  public
    property VATRate: double read FVATRate write SetVATRate;
    property VATCode: string read FVATCode write SetVATCode;
  end;

implementation

{ TProduct }

procedure TProduct.SetVATRate(AValue: double);
begin
  if FVATRate=AValue then Exit;
  FVATRate:=AValue;
end;

procedure TProduct.SetVATCode(AValue: string);
begin
  if FVATCode=AValue then Exit;
  FVATCode:=AValue;
end;

{ TProduct }

{ TProducts }

constructor TProducts.Create;
begin

end;

constructor TProducts.Create(DataObject: IDataObject);
begin
  FDataObject:=DataObject;
  Create;
end;

function TProducts.GetSQL: string;
begin
  Result := 'SELECT serprd, codprd, libprd, active, codtva'
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

function TProducts.GetProduct(const ID: integer): TProduct;
begin
  Result := TProduct.Create;
  Result.VATRate:=0;
  with FDataObject.GetQuery do
  begin
    try
      SQL.Add('SELECT t.rate, p.codtva'
             +' FROM tautva t INNER JOIN products p ON t.codtva = p.codtva'
             +' WHERE p.serprd = :ID'
             +'   AND t.dateff = (SELECT MAX(x.dateff) FROM tautva x'
             +'                     WHERE x.codtva = t.codtva'
             +'                       AND x.dateff <= CURRENT_TIMESTAMP)');
      Params[0].AsInteger:=ID;
      Open;
      Result.VATRate := Fields[0].AsFloat;
      Result.FVATCode:=Fields[1].AsString;
      Close;
    finally
      Free;
    end;
  end;
end;

//
//function TProducts.GetEventProducts(const serevt: integer): string;
//begin
//  Result := 'SELECT serprd,libprd,price'
//           +' FROM event_detail'
//           +' WHERE serevt = :serevt'
//           +' ORDER BY numseq';
//end;

end.

