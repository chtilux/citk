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
  detail := nil; vat := nil;
  master := FDataObject.GetQuery;
  try
    master.SQL.Add('SELECT'
                  +'  paymentmethod, SUM(quantity * price) AS total'
                  +' FROM bill_detail bd'
                  +'   INNER JOIN bill b ON bd.serbill = b.serbill'
                  +' WHERE b.datbill = :datbill'
                  +' GROUP BY 1'
                  +' ORDER BY 1');
    master.ParamByName('datbill').AsDateTime:=datbill;
    master.Open;

    detail := FDataObject.GetQuery;
    detail.SQL.Add('SELECT'
                  +'  SUM(quantity * price) AS total'
                  +' FROM bill_detail bd'
                  +'   INNER JOIN bill b ON bd.serbill = b.serbill'
                  +' WHERE b.datbill = :datbill');
    detail.ParamByName('datbill').AsDateTime:=datbill;

    vat := FDataObject.GetQuery;
    vat.SQL.Add('SELECT vatrate,SUM(htv+vat) AS ttc'
               +' FROM bill_vat bv'
               +'   INNER JOIN bill b ON bv.serbill = b.serbill'
               +' WHERE b.datbill = :datbill'
               +' GROUP BY 1'
               +' ORDER BY 1');
    vat.ParamByName('datbill').AsDateTime:=datbill;

    detail.Open;
    vat.Open;

    OutputMode.Print(master, detail, vat);
  finally
    master.Free;
    detail.Free;
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
      Filename := Format('c:\temp\daily_recap_%.4d%.2d%.2d_%.3d.pdf',[y,m,d,i]);
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
begin

end;

end.

