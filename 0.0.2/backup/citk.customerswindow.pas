unit citk.customersWindow;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls,
  citk.DataGridForm, SQLDB, DB, DBGrids, DBCtrls;

type

  { TCustomersColumns }

  TCustomersColumns = class(TSetDataGridColumnsHelper)
  public
    procedure SetOnSetDataGridColumns(ADBGrid: TDBGrid); override;
  end;

{ TCustomersW }

  TCustomersW = class(TDataGridForm)
    CustomersTab: TTabControl;
    SearchEdit: TEdit;
    Label1: TLabel;
    procedure CustomersTabChange(Sender: TObject);
    procedure DataGridKeyPress(Sender: TObject; var Key: char);
    procedure DataNavClick(Sender: TObject; Button: TDBNavButtonType);
    procedure FormCreate(Sender: TObject);
    procedure SearchEditChange(Sender: TObject);
  private
    function GetPrimaryKey: integer;
  public
    procedure QueryBeforePost(DataSet: TDataSet);
    procedure QueryAfterPost(Dataset: TDataset);
  end;

  procedure DisplayCustomers;

var
  CustomersW: TCustomersW;

implementation

{$R *.lfm}

uses
  citk.customers, citk.Global;

procedure DisplayCustomers;
var
  F: TCustomersW;
  Q: TSQLQuery;
  cust: ICustomers;
  dgh: TSetDataGridColumnsHelper;
begin
  F := TCustomersW.Create(nil, glGlobalInfo);
  try
    Q := TSQLQuery.Create(F);
    Q.SQLConnection:=F.DataObject.Connector;
    Q.Transaction:=F.DataObject.Transaction;
    cust := TCustomers.Create;
    Q.SQL.Add(cust.GetSQL);
    Q.Params[0].AsString := '%';
    Q.BeforePost:=@F.QueryBeforePost;
    Q.AfterPost:=@F.QueryAfterPost;
    dgh := TCustomersColumns.Create;
    F.OnSetDataGridColumns:=@dgh.SetOnSetDataGridColumns;
    F.Query := Q;
    Q.Open;
    F.ShowModal;
  finally
    F.Free;
    dgh.Free;
  end;
end;

{ TCustomersColumns }

procedure TCustomersColumns.SetOnSetDataGridColumns(ADBGrid: TDBGrid);
begin
  inherited SetOnSetDataGridColumns(ADBGrid);
  with ADBGrid.Columns.Add do
  begin
    FieldName:='sercust';
    Width := 80;
    Alignment:=taCenter;
    Visible:=True;
    ReadOnly := True;
    Title.Caption:='ID';
  end;
  with ADBGrid.Columns.Add do
  begin
    FieldName:='custname';
    Width := 250;
    Title.Caption:='Customer Name';
  end;
end;

{ TCustomersW }

procedure TCustomersW.FormCreate(Sender: TObject);
var
  a: Char;
begin
  CustomersTab.Tabs.BeginUpdate;
  for a := 'A' to 'Z' do
    CustomersTab.Tabs.Add(string(a));
  CustomersTab.Tabs.Insert(0,'ALL');
  CustomersTab.Tabs.EndUpdate;
end;

procedure TCustomersW.SearchEditChange(Sender: TObject);
begin
  CustomersTab.TabIndex := 0;
  CustomersTabChange(CustomersTab);
  Query.DisableControls;
  try
    Query.Close;
    Query.Params[0].AsString := Query.Params[0].AsString + TEdit(Sender).Text + '%';
  finally
    Query.Open;
    Query.EnableControls;
  end;
end;

procedure TCustomersW.QueryBeforePost(DataSet: TDataSet);
begin
  { primary key }
  if (Dataset.State = dsInsert) and (Dataset.FieldByName('sercust').IsNull) then
    Dataset.FieldByName('sercust').AsInteger:=GetPrimaryKey;
end;

procedure TCustomersW.QueryAfterPost(Dataset: TDataset);
begin
  Query.ApplyUpdates;
  DataObject.Transaction.CommitRetaining;
  Query.Refresh;
end;

function TCustomersW.GetPrimaryKey: integer;
var
  cust: ICustomers;
begin
  with TSQLQuery.Create(nil) do
  begin
    try
      SQLConnection:=Self.DataObject.Connector;
      Transaction:=Self.DataObject.Transaction;
      cust := TCustomers.Create;
      SQL.Add(cust.GetPKSQL);
      Open;
      Result:=Fields[0].AsInteger;
      Close;
    finally
      Free;
    end;
  end;
end;

procedure TCustomersW.CustomersTabChange(Sender: TObject);
begin
  Query.DisableControls;
  try
    Query.Close;
    Query.Params[0].AsString := '%';
    if TTabControl(Sender).TabIndex > 0 then
      Query.Params[0].AsString := Query.Params[0].AsString + TTabControl(Sender).Tabs[TTabControl(Sender).TabIndex] + '%';
  finally
    Query.Open;
    Query.EnableControls;
  end;
end;

procedure TCustomersW.DataGridKeyPress(Sender: TObject; var Key: char);
begin
  Key := UpCase(Key);
end;

procedure TCustomersW.DataNavClick(Sender: TObject; Button: TDBNavButtonType);
begin
  if Button = nbInsert then
  begin
    DataGrid.SetFocus;
    DataGrid.SelectedField := Query.FieldByName('custname');
  end;
end;

end.

