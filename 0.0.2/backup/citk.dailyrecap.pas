unit citk.DailyRecap;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, citk.Output, SQLDB, citk.DataObject, citk.PDFOutput;

type
  IDailyRecap = interface
  ['{DA7B71CC-C180-4A31-9273-67085EEA322F}']
    function GetSQL: string;
    procedure Print(const datbill: TDate; OutputMode: IOutput);
  end;

  { TDailyRecap }

  TDailyRecap = class(TInterfacedObject, IDailyRecap)
  private
    FDataObject: IDataObject;
    procedure PrintWithoutSUM(const datbill: TDate; OutputMode: IOutput);
  public
    constructor Create; overload;
    constructor Create(DataObject: IDataObject); overload;
    function GetSQL: string;
    procedure Print(const datbill: TDate; OutputMode: IOutput);
  end;

  { TDailyRecapOutput }

  TDailyRecapOutput = class(TPdfOutput)
  public
    procedure Print(master, detail, vat: TSQLQuery); override; overload;
    procedure Print(master, detail, vat: TStrings); overload;
  end;

implementation

uses
  FPPDF;

type
  TMaster = class
  public
    paymentMethod: string;
    total: double;
    DueDate: TDate;
  end;

  TDetail = class
  public
    total: double;
  end;

  TVat = class
    VatRate: double;
    TTC: double;
  end;

{ TDailyRecap }

constructor TDailyRecap.Create;
begin

end;

constructor TDailyRecap.Create(DataObject: IDataObject);
begin
  FDataObject:=DataObject;
  Create;
end;

function TDailyRecap.GetSQL: string;
begin
  Result := 'SELECT DISTINCT datbill FROM bill ORDER BY 1 DESC';
end;

procedure TDailyRecap.Print(const datbill: TDate; OutputMode: IOutput);
var
  master,
  detail,
  vat: TSQLQuery;
begin
  PrintWithoutSUM(datbill, OutputMode);

  { la fonction SUM semblent ne pas fonctionner, impossible de récupérer une valeur }
  //detail := nil; vat := nil;
  //master := FDataObject.GetQuery;
  //try
  //  master.SQL.Add('SELECT'
  //                +'  paymentmethod, SUM(quantity * price) AS total'
  //                +' FROM bill_detail bd'
  //                +'   INNER JOIN bill b ON bd.serbill = b.serbill'
  //                +' WHERE b.datbill = :datbill'
  //                +' GROUP BY 1'
  //                +' ORDER BY 1');
  //  master.ParamByName('datbill').AsDateTime:=datbill;
  //  master.Open;
  //
  //  detail := FDataObject.GetQuery;
  //  detail.SQL.Add('SELECT'
  //                +'  SUM(quantity * price) AS total'
  //                +' FROM bill_detail bd'
  //                +'   INNER JOIN bill b ON bd.serbill = b.serbill'
  //                +' WHERE b.datbill = :datbill');
  //  detail.ParamByName('datbill').AsDateTime:=datbill;
  //
  //  vat := FDataObject.GetQuery;
  //  vat.SQL.Add('SELECT vatrate,SUM(htv+vat) AS ttc'
  //             +' FROM bill_vat bv'
  //             +'   INNER JOIN bill b ON bv.serbill = b.serbill'
  //             +' WHERE b.datbill = :datbill'
  //             +' GROUP BY 1'
  //             +' ORDER BY 1');
  //  vat.ParamByName('datbill').AsDateTime:=datbill;
  //
  //  detail.Open;
  //  vat.Open;
  //
  //  OutputMode.Print(master, detail, vat);
  //finally
  //  master.Free;
  //  detail.Free;
  //  vat.Free;
  //end;
end;

procedure TDailyRecap.PrintWithoutSUM(const datbill: TDate; OutputMode: IOutput);
var
  master, detail, vat: TStrings;
  z: TSQLQuery;
  m: TMaster;
  d: TDetail;
  v: TVat;
  group: string;
  i: integer;
begin
  detail := nil; vat := nil; z:=nil;
  z := FDataObject.GetQuery;

  master:=TStringList.Create;
  try
    z.SQL.Add('SELECT'
             +'  paymentmethod, quantity * price AS total'
             +' FROM bill_detail bd'
             +'   INNER JOIN bill b ON bd.serbill = b.serbill'
             +' WHERE b.datbill = :datbill'
             +' ORDER BY 1');
    z.ParamByName('datbill').AsDateTime:=datbill;
    z.Open;
    group := '';
    while not z.Eof do
    begin
      if CompareText(group, z.Fields[0].AsString)<>0 then
      begin
        group:=z.Fields[0].AsString;
        m := TMaster.Create;
        m.paymentMethod:=z.Fields[0].AsString;
        m.total:=0;
        m.DueDate:=datbill;
        master.AddObject(m.paymentMethod, m);
      end;
      m.total:=m.total+z.Fields[1].AsFloat;
      z.Next;
    end;
    z.Close;

    z.SQL.Clear;
    z.SQL.Add('SELECT'
             +'  quantity * price AS total'
             +' FROM bill_detail bd'
             +'   INNER JOIN bill b ON bd.serbill = b.serbill'
             +' WHERE b.datbill = :datbill');
    z.ParamByName('datbill').AsDateTime:=datbill;
    z.open;
    detail := TStringList.Create;
    d := TDetail.Create;
    d.total:=0;
    while not z.Eof do
    begin
      d.total:=d.total+z.Fields[0].AsFloat;
      z.Next;
    end;
    z.Close;
    detail.AddObject('total',d);

    z.SQL.Clear;
    z.SQL.Add('SELECT vatrate,htv+vat AS ttc'
             +' FROM bill_vat bv'
             +'   INNER JOIN bill b ON bv.serbill = b.serbill'
             +' WHERE b.datbill = :datbill'
             +' ORDER BY 1');
    z.ParamByName('datbill').AsDateTime:=datbill;
    z.Open;
    group := '';
    vat:=TStringList.Create;
    while not z.Eof do
    begin
      if CompareText(group, z.Fields[0].AsString)<>0 then
      begin
        group:=z.Fields[0].AsString;
        v := TVat.Create;
        v.VatRate:=z.Fields[0].AsFloat;
        v.TTC:=0;
        vat.AddObject(FloatToStr(v.VatRate), v);
      end;
      v.TTC:=v.TTC+z.Fields[1].AsFloat;
      z.Next;
    end;
    z.Close;

    (OutputMode as TDailyRecapOutput).Print(master,detail,vat);
  finally
    for i:=0 to master.Count-1 do TMaster(master.Objects[i]).Free;
    master.Free;
    for i:=0 to detail.Count-1 do TDetail(detail.Objects[i]).Free;
    detail.Free;
    for i:=0 to vat.Count-1 do TVat(vat.Objects[i]).Free;
    vat.Free;
  end;
end;

{ TDailyRecapOutput }

procedure TDailyRecapOutput.Print(master, detail, vat: TSQLQuery);
var
  pdf: TPDFDocument;
  font, FontBold: integer;
  page: TPDFPage;
  fs: TFileStream;
  Filename: TFilename;
  i, top: integer;
  total: double;
  y,m,d: word;
const
  MARGIN=10; RATE=85; TTC=140; // AMOUNT=160; TVA=180;
begin
  pdf := CreatePDFDocument;
  try
    fontBold := pdf.AddFont('FreeMonoBold.ttf','FreeMonoBold');
    page := pdf.Pages[0];
    page.SetFont(fontBold,18);
    page.SetColor(clBlack, False);
    top := 10;

    page.WriteText(10,top,'Celine in the Kitchen');
    Inc(top,10);
    Page.SetFont(FontBold,10);
    Page.WriteText(10,top,Format('Due date : %s',[master.ParamByName('datbill').AsString]));

    Inc(top, 20);
    Page.WriteText(10,top,'Pay mode ventilation');

    font := pdf.AddFont('FreeMono.ttf','FreeMono');
    page.SetFont(font,10);

    Inc(top,10);
    Page.WriteText(MARGIN,top,'PAYMENT');
    Page.WriteText(TTC, top, 'TTC');
    while not master.EOF do
    begin
      Inc(top, 8);

      Page.WriteText(MARGIN,top,master.FieldByName('paymentmethod').AsString);
      Page.WriteText(TTC, top, FormatFloat('0.00€',master.FieldByName('total').AsFloat));
      master.Next;
    end;

    Inc(top, 20);
    Page.SetFont(FontBold,10);
    page.WriteText(TTC-17, top, Format('TOTAL : %.2f€',[detail.FieldByName('total').AsFloat]));

    Page.SetFont(FontBold,10);
    Inc(top, 20);
    Page.WriteText(10,top,'VAT ventilation');
    page.SetFont(font,10);
    Inc(top,10);
    Page.WriteText(MARGIN,top,'VAT RATE');
    Page.WriteText(TTC, top, 'TTC');
    while not vat.EOF do
    begin
      Inc(top, 8);

      Page.WriteText(MARGIN,top,FormatFloat('0.00%', vat.FieldByName('vatrate').AsFloat));
      Page.WriteText(TTC, top, FormatFloat('0.00€', vat.FieldByName('ttc').AsFloat));
      vat.Next;
    end;

    Inc(top, 20);
    page.SetFont(fontBold,8);
    page.WriteText(10, top, 'CELINE IN THE KITCHEN, DIFFERDANGE');
    Inc(top,5);
    page.WriteText(10, top, 'R.C.S. Luxembourg XXXXXXX           RESTAURATEUR Autorisation XXXXXXXXX');

    //GenerateText(page, 'Celine in the Kitchen');
    //page.WriteText(10,top,'Celine in the Kitchen');

    DecodeDate(master.ParamByName('datbill').AsDate,y,m,d);
    i := 0;
    repeat
      Filename := Format('%s\daily_recap_%.4d%.2d%.2d_%.3d.pdf',[ExcludeTrailingPathDelimiter(OutputDirectory),y,m,d,i]);
      Inc(i);
    until not(FileExists(Filename));

    fs := TFileStream.Create(Filename,fmCreate);
    try
      pdf.SaveToStream(fs);
    finally
      fs.Free;
    end;
  finally
    pdf.Free;
  end;
end;

procedure TDailyRecapOutput.Print(master, detail, vat: TStrings);
var
  pdf: TPDFDocument;
  font, FontBold: integer;
  page: TPDFPage;
  fs: TFileStream;
  Filename: TFilename;
  i, top: integer;
  total: double;
  y,m,d: word;
  mst: TMaster;
  det: TDetail;
  tva: TVat;
const
  MARGIN=10; RATE=85; TTC=140; // AMOUNT=160; TVA=180;
begin
  pdf := CreatePDFDocument;
  try
    fontBold := pdf.AddFont('FreeMonoBold.ttf','FreeMonoBold');
    page := pdf.Pages[0];
    page.SetFont(fontBold,18);
    page.SetColor(clBlack, False);
    top := 10;

    page.WriteText(10,top,'Celine in the Kitchen');
    Inc(top,10);
    Page.SetFont(FontBold,10);
    mst := TMaster(master.Objects[0]);
    Page.WriteText(10,top,Format('Due date : %s',[DateToStr(mst.DueDate)]));

    Inc(top, 20);
    Page.WriteText(10,top,'Pay mode ventilation');

    font := pdf.AddFont('FreeMono.ttf','FreeMono');
    page.SetFont(font,10);

    Inc(top,10);
    Page.WriteText(MARGIN,top,'PAYMENT');
    Page.WriteText(TTC, top, 'TTC');
    for i := 0 to master.count-1 do
    begin
      Inc(top, 8);
      mst := TMaster(master.Objects[i]);
      Page.WriteText(MARGIN,top,mst.paymentMethod);
      Page.WriteText(TTC, top, FormatFloat('0.00€',mst.total));
    end;

    Inc(top, 20);
    Page.SetFont(FontBold,10);
    det := TDetail(detail.Objects[0]);
    page.WriteText(TTC-17, top, Format('TOTAL : %.2f€',[det.total]));

    Page.SetFont(FontBold,10);
    Inc(top, 20);
    Page.WriteText(10,top,'VAT ventilation');
    page.SetFont(font,10);
    Inc(top,10);
    Page.WriteText(MARGIN,top,'VAT RATE');
    Page.WriteText(TTC, top, 'TTC');
    for i := 0 to vat.count-1 do
    begin
      Inc(top, 8);
      tva := TVat(vat.Objects[i]);
      Page.WriteText(MARGIN,top,FormatFloat('0.00%', tva.VatRate));
      Page.WriteText(TTC, top, FormatFloat('0.00€', tva.TTC));
    end;

    Inc(top, 20);
    page.SetFont(fontBold,8);
    page.WriteText(10, top, 'CELINE IN THE KITCHEN, DIFFERDANGE');
    Inc(top,5);
    page.WriteText(10, top, 'R.C.S. Luxembourg XXXXXXX           RESTAURATEUR Autorisation XXXXXXXXX');

    DecodeDate(mst.DueDate,y,m,d);
    i := 0;
    repeat
      Filename := Format('%s\daily_recap_%.4d%.2d%.2d_%.3d.pdf',[ExcludeTrailingPathDelimiter(OutputDirectory),y,m,d,i]);
      Inc(i);
    until not(FileExists(Filename));

    fs := TFileStream.Create(Filename,fmCreate);
    try
      pdf.SaveToStream(fs);
    finally
      fs.Free;
    end;
  finally
    pdf.Free;
  end;
end;

end.

