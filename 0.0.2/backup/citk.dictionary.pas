unit citk.dictionary;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

procedure DisplayDictionary;

implementation

uses
  citk.DataGridForm, citk.DataObject, SQLDB, citk.global, DBGrids, citk.persistence;

type
  { TDictionaryColumns }

  TDictionaryColumns = class(TSetDataGridColumnsHelper)
  public
    procedure SetOnSetDataGridColumns(ADBGrid: TDBGrid); override;
  end;

{ TDictionaryColumns }

procedure TDictionaryColumns.SetOnSetDataGridColumns(ADBGrid: TDBGrid);
var
  i: integer;
begin
  inherited SetOnSetDataGridColumns(ADBGrid);
  with ADBGrid.Columns.Add do
  begin
    FieldName:='cledic';
    Width := 150;
  end;
  with ADBGrid.Columns.Add do
  begin
    FieldName:='coddic';
    Width := 150;
  end;
  with ADBGrid.Columns.Add do
  begin
    FieldName:='libdic';
    Width := 250;
  end;
  for i := 1 to 9 do
    with ADBGrid.Columns.Add do
    begin
      FieldName:='pardc'+IntToStr(i);
      Width := 150;
    end;
end;

type

  { TDictionary }

  TDictionary = class(TInterfacedObject, IDictionary)
  public
    function GetSQL: string;
  end;
  { TDictionary }

  function TDictionary.GetSQL: string;
  begin
    Result := 'SELECT * FROM dictionnaire ORDER BY cledic, coddic';
  end;

procedure DisplayDictionary;
var
  F: TDataGridForm;
  dao: IDataObject;
  Q: TSQLQuery;
  dbgh: TSetDataGridColumnsHelper;
  dic: IDictionary;
begin
  dao := TFirebirdDataObject.Create(glCnx,glTrx);
  Q := TSQLQuery.Create(nil);     dbgh := nil;
  try
    Q.SQLConnection:=glCnx;
    Q.Transaction:=glTrx;
    dic := TDictionary.Create;
    Q.SQL.Add(dic.GetSQL);
    Q.ReadOnly:=True;
    dbgh := TDictionaryColumns.Create;
    F := TDataGridForm.Create(nil, dao);
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

end.

