unit citk.customers;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

type
  ICustomers = interface
  ['{A8C5CDA4-65E2-4D9A-9A83-4B98576D4F00}']
    function GetSQL: string;
    function GetPKSQL: string;
  end;

  { TCustomers }

  TCustomers = class(TInterfacedObject, ICustomers)
  public
    function GetSQL: string;
    function GetPKSQL: string;
  end;

implementation

uses
  citk.customersWindow, SQLDB;

{ TCustomers }

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

end.

