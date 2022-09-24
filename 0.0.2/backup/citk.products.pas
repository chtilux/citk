unit citk.products;

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
    FVATRate: double;
    procedure SetVATRate(AValue: double);
  public
    property VATRate: double read FVATRate write SetVATRate;
  end;

implementation

{ TProduct }

procedure TProduct.SetVATRate(AValue: double);
begin
  if FVATRate=AValue then Exit;
  FVATRate:=AValue;
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
      SQL.Add('SELECT t.rate'
             +' FROM tautva t INNER JOIN products p ON t.codtva = p.codtva'
             +' WHERE p.serprd = :ID'
             +'   AND t.dateff = (SELECT MAX(x.dateff) FROM tautva x'
             +'                     WHERE x.codtva = t.codtva'
             +'                       AND x.dateff <= CURRENT_TIMESTAMP)');
      Params[0].AsInteger:=ID;
      Open;
      Result.VATRate := Fields[0].AsFloat;
      Close;
    finally
      Free;
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

