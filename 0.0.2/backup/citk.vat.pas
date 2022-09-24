unit citk.vat;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

type

  { IVAT }

  IVAT = Interface
  ['{B0A5A0DA-3327-447A-8E87-9054D0F35ED3}']
    function GetSQL: string;
  end;

  { TVAT }

  TVAT = class(TInterfacedObject, IVAT)
  public
    function GetSQL: string;
  end;

  procedure DisplayVAT;

implementation

uses
  citk.DataGridForm, citk.DataObject, SQLDB, citk.global, DBGrids,
  citk.VATWindow;

type

  { TVATColumns }

  TVATColumns = class(TSetDataGridColumnsHelper)
  public
    procedure SetOnSetDataGridColumns(ADBGrid: TDBGrid); override;
  end;

procedure DisplayVAT;
var
  F: TDataGridForm;
  dao: IDataObject;
  Q: TSQLQuery;
  dbgh: TSetDataGridColumnsHelper;
  vat: IVAT;
begin
  dao := TFirebirdDataObject.Create(glCnx,glTrx);
  Q := TSQLQuery.Create(nil);     dbgh := nil;
  try
    Q.SQLConnection:=glCnx;
    Q.Transaction:=glTrx;
    vat := TVAT.Create;
    Q.SQL.Add(vat.GetSQL);
    dbgh := TVATColumns.Create;
    F := TVATW.Create(nil, dao);
    try
      F.Query := Q;
      F.Query.Open;
      F.OnSetDataGridColumns:=@dbgh.SetOnSetDataGridColumns;
      F.ShowModal;
    finally
      F.Free;
    end;
  finally
    Q.Free;
    dbgh.Free;
  end;
end;

function TVAT.GetSQL: string;
begin
  Result := 'SELECT codtva, libtva FROM tva ORDER BY 1';
end;

{ TVATColumns }

procedure TVATColumns.SetOnSetDataGridColumns(ADBGrid: TDBGrid);
begin
  inherited SetOnSetDataGridColumns(ADBGrid);
  with ADBGrid.Columns.Add do
  begin
    FieldName:='codtva';
    Width := 150;
  end;
  with ADBGrid.Columns.Add do
  begin
    FieldName:='libtva';
    Width := 250;
  end;
end;

end.

