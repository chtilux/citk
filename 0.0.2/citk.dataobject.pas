unit citk.DataObject;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, sqldb;

type
  IDataObject = interface
  ['{277355F4-20C8-4CF0-A63F-53EB721FBBF0}']
    function GetConnector: TSQLConnector;
    procedure SetConnector(AValue: TSQLConnector);
    property Connector: TSQLConnector read GetConnector write SetConnector;
    function GetTransaction: TSQLTransaction;
    procedure SetTransaction(AValue: TSQLTransaction);
    property Transaction: TSQLTransaction read GetTransaction write SetTransaction;
    function GetQuery: TSQLQuery;
  end;

  { TFirebirdDataObject }

  TFirebirdDataObject = class(TInterfacedObject, IDataObject)
  private
    FConnector: TSQLConnector;
    FTransaction: TSQLTransaction;
    function GetConnector: TSQLConnector;
    function GetTransaction: TSQLTransaction;
    procedure SetConnector(AValue: TSQLConnector);
    procedure SetTransaction(AValue: TSQLTransaction);
  public
    constructor Create(AConnector: TSQLConnector; ATransaction: TSQLTransaction); virtual;
    property Connector: TSQLConnector read GetConnector write SetConnector;
    property Transaction: TSQLTransaction read GetTransaction write SetTransaction;
    function GetQuery: TSQLQuery;
  end;

implementation

{ TFirebirdDataObject }

function TFirebirdDataObject.GetConnector: TSQLConnector;
begin
  Result := FConnector;
end;

function TFirebirdDataObject.GetTransaction: TSQLTransaction;
begin
  Result := FTransaction;
end;

procedure TFirebirdDataObject.SetConnector(AValue: TSQLConnector);
begin
  FConnector:=AValue;
end;

procedure TFirebirdDataObject.SetTransaction(AValue: TSQLTransaction);
begin
  if FTransaction=AValue then Exit;
  FTransaction:=AValue;
end;

constructor TFirebirdDataObject.Create(AConnector: TSQLConnector;
  ATransaction: TSQLTransaction);
begin
  FConnector:=AConnector;
  FTransaction:=ATransaction;
end;

function TFirebirdDataObject.GetQuery: TSQLQuery;
begin
  Result := TSQLQuery.Create(nil);
  Result.SQLConnection:=Connector;
  Result.Transaction:=Transaction;
end;

end.

