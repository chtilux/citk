unit citk.customers;

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

