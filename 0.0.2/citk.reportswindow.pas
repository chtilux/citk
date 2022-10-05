unit citk.ReportsWindow;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  DBGrids, CheckLst, citk.DataObject, SQLDB, DB;

type

  { TReportsW }

  TReportsW = class(TForm)
    CustomerGroupByBox: TCheckBox;
    DataSource: TDataSource;
    ProductGroupByBox: TCheckBox;
    EventGroupByBox: TCheckBox;
    PeriodGroupByBox: TCheckBox;
    CheckGroup1: TCheckGroup;
    DBGrid1: TDBGrid;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    CustomersList: TCheckListBox;
    ProductsList: TCheckListBox;
    EventsList: TCheckListBox;
    PeriodsList: TCheckListBox;
    SelectionBox: TGroupBox;
    procedure CustomersListClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FDataObject: IDataObject;
    FQuery: TSQLQuery;
    procedure DisplayData;
    procedure GetReportsFilters;
  public
    constructor Create(AOwner: TComponent; DataObject: IDataObject); reintroduce; overload;
  end;

implementation

{$R *.lfm}

type
  TItemObject = class(TObject)
  public
    id: integer;
    lib: string;
  end;

{ TReportsW }

constructor TReportsW.Create(AOwner: TComponent; DataObject: IDataObject);
begin
  inherited Create(AOwner);
  FDataObject:=DataObject;
  FQuery := FDataObject.GetQuery;
  DataSource.Dataset := FQuery;
  GetReportsFilters;
end;

procedure TReportsW.GetReportsFilters;
var
  z: TSQLQuery;
  io: TItemObject;
begin
  z := FDataObject.GetQuery;
  try
    { Lister les clients }
    z.SQL.Clear;
    z.SQL.Add('SELECT sercust, custname FROM customers'
             +' ORDER BY 2');
    z.Open;
    while not z.Eof do
    begin
      io := TItemObject.Create;
      io.id:=z.Fields[0].AsInteger;
      io.lib:=z.Fields[1].AsString;
      CustomersList.Items.AddObject(io.lib, io);
      z.Next;
    end;
    z.Close;
    { Lister les produits }
    z.SQL.Clear;
    z.SQL.Add('SELECT serprd,libprd FROM products'
             +' ORDER BY 2');
    z.Open;
    while not z.Eof do
    begin
      io := TItemObject.Create;
      io.id:=z.Fields[0].AsInteger;
      io.lib:=z.Fields[1].AsString;
      ProductsList.Items.AddObject(io.lib, io);
      z.Next;
    end;
    z.Close;
    { Lister les évènements }
    z.SQL.Clear;
    z.SQL.Add('SELECT serevt,begevt,libevt FROM event'
             +' ORDER BY 2');
    z.Open;
    while not z.Eof do
    begin
      io := TItemObject.Create;
      io.id:=z.Fields[0].AsInteger;
      io.lib:=Format('%s-%s',[z.Fields[1].AsString,z.Fields[2].AsString]);
      EventsList.Items.AddObject(io.lib, io);
      z.Next;
    end;
    z.Close;
    { Lister les périodes }
    z.SQL.Clear;
    z.SQL.Add('SELECT DISTINCT'
             +'       EXTRACT(YEAR FROM b.datbill)*100+EXTRACT(MONTH FROM b.datbill) id'
             +'      ,EXTRACT(YEAR FROM b.datbill) annee'
             +'      ,EXTRACT(MONTH FROM b.datbill) mois'
             +' FROM bill b'
             +' ORDER BY 1');
    z.Open;
    while not z.Eof do
    begin
      io := TItemObject.Create;
      io.id:=z.Fields[0].AsInteger;
      io.lib:=Format('%s-%.2d',[z.Fields[1].AsString,z.Fields[2].AsInteger]);
      PeriodsList.Items.AddObject(io.lib, io);
      z.Next;
    end;
    z.Close;
  finally
    z.Free;
  end;
end;

procedure TReportsW.FormDestroy(Sender: TObject);
var
  i: integer;
begin
  FQuery.Free;
  for i := 0 to CustomersList.Count-1 do TItemObject(CustomersList.Items.Objects[i]).Free;
  for i := 0 to ProductsList.Count-1 do TItemObject(ProductsList.Items.Objects[i]).Free;
  for i := 0 to EventsList.Count-1 do TItemObject(EventsList.Items.Objects[i]).Free;
  for i := 0 to PeriodsList.Count-1 do TItemObject(PeriodsList.Items.Objects[i]).Free;
end;

procedure TReportsW.CustomersListClick(Sender: TObject);
begin
  DisplayData;
end;

procedure TReportsW.FormShow(Sender: TObject);
begin
  DisplayData;
end;

procedure TReportsW.DisplayData;
var
  select,
  where,
  group: string;
  groupCount, i: integer;
begin
  FQuery.DisableControls;
  try
    FQuery.Close;
    FQuery.SQL.Clear;
    select:=''; where:='';group:='';groupCount:=0;
    if CustomerGroupByBox.Checked then
    begin
      select := select + ',c.custname';
      Inc(GroupCount);
    end;
    if ProductGroupByBox.Checked then
    begin
      select := select + ',UPPER(bd.libprd)libprd';
      Inc(GroupCount);
    end;
    if EventGroupByBox.Checked then
    begin
      select := select + ',ev.libevt';
      Inc(GroupCount);
    end;
    if PeriodGroupByBox.Checked then
    begin
      select := select + ',EXTRACT(YEAR FROM b.datbill)*100+EXTRACT(MONTH FROM b.datbill) period';
      Inc(GroupCount);
    end;

    if not select.IsEmpty then
    begin
      Delete(select,1,1);
      select := 'SELECT ' + select + ', SUM(quantity) qty, SUM(amount) chida';
      where := ' FROM bill_detail bd'
              +'      LEFT JOIN bill b ON bd.serbill = b.serbill'
              +'      LEFT JOIN customers c ON b.customerid = c.sercust'
              +'      LEFT JOIN bill_event bv ON b.serbill = bv.serbill'
              +'      LEFT JOIN event ev ON bv.serevt = ev.serevt';
      for i:=1 to GroupCount do
        group := Format('%s,%d',[group, i]);
      Delete(group,1,1);
      group := ' GROUP BY ' + group;
    end
    else
    begin
      select := 'SELECT UPPER(bd.libprd)libprd, SUM(quantity) qty, SUM(amount) chida';
      where := ' FROM bill_detail bd'
              +'      LEFT JOIN bill b ON bd.serbill = b.serbill'
              +'      LEFT JOIN customers c ON b.customerid = c.sercust'
              +'      LEFT JOIN bill_event bv ON b.serbill = bv.serbill'
              +'      LEFT JOIN event ev ON bv.serevt = ev.serevt';
      group := ' GROUP BY 1'
              +' ORDER BY 3 DESC, 2';
    end;
    FQuery.SQL.Add(select);
    FQuery.SQL.Add(where);
    FQuery.SQL.Add(group);
  finally
    try
      DBGrid1.Columns.Clear;
      FQuery.Open;
      ShowMessage(FQuery.SQL.Text);
    except
      ShowMessage(FQuery.SQL.Text);
    end;
    FQuery.EnableControls;
  end;
end;

end.

