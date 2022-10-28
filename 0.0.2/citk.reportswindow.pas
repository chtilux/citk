unit citk.ReportsWindow;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  DBGrids, CheckLst, Buttons, findControl, citk.DataObject, SQLDB, DB;

type

  { TReportsW }

  TReportsW = class(TForm)
    ExportToExcelButton: TBitBtn;
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
    procedure ExportToExcelButtonClick(Sender: TObject);
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

uses
  citk.Global, DateUtils, DriveOleExcel, ComObj;

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
  ProductGroupByBox.Checked:=True;
  //DisplayData;
end;

procedure TReportsW.DisplayData;
  function StartOfPeriod(const p: integer): TDateTime;
  var
    y,m: word;
  begin
    y := p div 100;
    m := p - y * 100;
    Result := StartOfAMonth(y,m);
  end;

  function EndOfPeriod(const p: integer): TDateTime;
  var
    y,m,d: word;
  begin
    y := p div 100;
    m := p - y * 100;
    Result := EndOfAMonth(y,m);
  end;

var
  select,
  from,
  where,
  group,
  cid,pid,eid,period: string;
  groupCount, i, p: integer;
begin
  FQuery.DisableControls;
  try
    FQuery.Close;
    FQuery.SQL.Clear;
    select:=''; where:='';group:='';groupCount:=0;
    if not(CustomerGroupByBox.Checked or ProductGroupByBox.Checked or EventGroupByBox.Checked or PeriodGroupByBox.Checked) then
    begin
      ProductGroupByBox.OnClick:=nil;
      ProductGroupByBox.Checked:=True;
      ProductGroupByBox.OnClick:=@CustomersListClick;
    end;
    if CustomerGroupByBox.Checked then
    begin
      select := select + ',UPPER(c.custname) custname';
      Inc(GroupCount);
    end;
    if ProductGroupByBox.Checked then
    begin
      select := select + ',UPPER(bd.libprd)libprd';
      Inc(GroupCount);
    end;
    if EventGroupByBox.Checked then
    begin
      select := select + ',UPPER(ev.libevt) libevt';
      Inc(GroupCount);
    end;
    if PeriodGroupByBox.Checked then
    begin
      select := select + ',EXTRACT(YEAR FROM b.datbill)*100+EXTRACT(MONTH FROM b.datbill) period';
      Inc(GroupCount);
    end;

    from := ' FROM bill_detail bd'
           +'      LEFT JOIN bill b ON bd.serbill = b.serbill'
           +'      LEFT JOIN customers c ON b.customerid = c.sercust'
           +'      LEFT JOIN bill_event bv ON b.serbill = bv.serbill'
           +'      LEFT JOIN event ev ON bv.serevt = ev.serevt';

    if not select.IsEmpty then
    begin
      Delete(select,1,1);
      select := 'SELECT ' + select + ', SUM(quantity) qty, SUM(amount) chida';
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

    { where if ... }
    cid:='';
    for i:=0 to CustomersList.Items.Count-1 do
    begin
      if CustomersList.Checked[i] then
        cid := Format('%s,%d',[cid,TItemObject(CustomersList.Items.Objects[i]).id]);
    end;
    Delete(cid,1,1);
    if not cid.IsEmpty then
      cid := Format('b.customerid in (%s)',[cid]);

    pid:='';
    for i:=0 to ProductsList.Items.Count-1 do
    begin
      if ProductsList.Checked[i] then
        pid := Format('%s,%d',[pid,TItemObject(ProductsList.Items.Objects[i]).id]);
    end;
    Delete(pid,1,1);
    if not pid.IsEmpty then
    begin
      pid := Format('bd.serprd in (%s)',[pid]);
      if not cid.IsEmpty then
        pid := ' AND ' + pid;
    end;

    eid:='';
    for i:=0 to EventsList.Items.Count-1 do
    begin
      if EventsList.Checked[i] then
        eid := Format('%s,%d',[eid,TItemObject(EventsList.Items.Objects[i]).id]);
    end;
    Delete(eid,1,1);
    if not eid.IsEmpty then
    begin
      eid := Format('bv.serevt in (%s)',[eid]);
      if not(cid.IsEmpty and pid.IsEmpty) then
        eid := ' AND ' + eid;
    end;

    period:='';
    for i:=0 to PeriodsList.Items.Count-1 do
    begin
      if PeriodsList.Checked[i] then
      begin
        p := TItemObject(PeriodsList.Items.Objects[i]).id;
        period:=Format('%s OR (b.datbill BETWEEN %s AND %s)',[period, FormatDateTime('yyyy-mm-dd',StartOfPeriod(p)).QuotedString, FormatDateTime('yyyy-mm-dd', EndOfPeriod(p)).QuotedString]);
      end;
    end;
    Delete(period, 1, 4);
    if not Period.IsEmpty then
    begin
      period := '(' + period + ')';
      if not(cid.IsEmpty and pid.IsEmpty and eid.IsEmpty) then
        period := ' AND ' + period;
    end;

    if not(pid.IsEmpty and cid.IsEmpty and eid.IsEmpty and period.IsEmpty) then
      where := cid + pid + eid + period;

    if not(where.IsEmpty) then
      where := 'WHERE ' + where;

    FQuery.SQL.Add(select);
    FQuery.SQL.Add(from);
    FQuery.SQL.Add(where);
    FQuery.SQL.Add(group);
  finally
    try
      DBGrid1.Columns.Clear;
      FQuery.Open;
    except
      on E:Exception do
      begin
        glGlobalInfo.Log(E.Message);
        raise;
      end;
    end;
    FQuery.EnableControls;
    for i:= 0 to DBGrid1.Columns.Count-1 do
      DBGrid1.Columns[i].Width:=110;
  end;
end;

procedure TReportsW.ExportToExcelButtonClick(Sender: TObject);
var
  XLApp: Variant;
  Wkb: Variant;
  sht: Variant;
  row, col: integer;
begin
  CreerInstanceDeExcel(XLApp, True);
  try
    CreerNouveauClasseur(wkb, xlapp);
    sht := wkb.ActiveSheet;
    row := 1;
    for col := 1 to FQuery.FieldCount do
      sht.Cells[row,col]:=FQuery.Fields[Pred(col)].FieldName;
    FQuery.First;
    while not FQuery.Eof do
    begin
      Inc(row);
      for col := 1 to FQuery.FieldCount do
        sht.Cells[row,col]:=FQuery.Fields[Pred(col)].AsString;
      FQuery.Next;
    end;
  finally
    XLApp:=Unassigned;
  end;
end;

end.

