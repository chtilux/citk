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
    property Connector: TSQLConnector read GetConnector write SetConnector;
    property Transaction: TSQLTransaction read GetTransaction write SetTransaction;
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

end.

