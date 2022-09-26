unit citk.PDFOutput;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, citk.Output, SQLDB, FPPDF;

type
  { TPdfOutput }

  TPdfOutput = class(TInterfacedObject, IOutput)
  protected
  public
    procedure Print(master, detail, vat: TSQLQuery); virtual;
    function CreatePDFDocument: TPDFDocument; virtual;
  end;

  { TBillOutput }

  TBillOutput = class(TPdfOutput)
  private
    //procedure GenerateText(page: TPDFPage; const texte: string);
  public
    procedure Print(master, detail, vat: TSQLQuery); override;
  end;

implementation

uses
  DateUtils, FPTTF;

{ TPdfOutput }

procedure TPdfOutput.Print(master, detail, vat: TSQLQuery);
begin
end;

function TPdfOutput.CreatePDFDocument: TPDFDocument;
var
  section: TPDFSection;
  page: TPDFPage;
  FontDir: TFilename;
begin
  FontDir := ExtractFilePath(ParamStr(0))+'fonts';
  Result := TPDFDocument.Create(nil);
  Result.FontDirectory:=FontDir;
  gTTFontCache.SearchPath.Add(FontDir);
  gTTFontCache.BuildFontCache;
  Result.StartDocument;
  Result.Options := [poPageOriginAtTop];
  section := Result.Sections.AddSection;
  page := Result.Pages.AddPage;
  page.PaperType:=ptA4;
  page.UnitOfMeasure:=uomMillimeters;
  section.AddPage(page);
end;

{ TBillOutput }

procedure TBillOutput.Print(master, detail, vat: TSQLQuery);
var
  pdf: TPDFDocument;
  font, FontBold: integer;
  page: TPDFPage;
  fs: TFileStream;
  Filename: TFilename;
  i, top: integer;
  montant,total: double;
const
  MARGIN=10; QTY=85; PRICE=120; AMOUNT=160; TVA=180;
begin
  pdf := CreatePDFDocument;
  try
    fontBold := pdf.AddFont('FreeMonoBold.ttf','FreeMonoBold');
    page := pdf.Pages[0];
    page.SetFont(fontBold,18);
    page.SetColor(clBlack, False);
    top := 10;

    top := 10;
    page.WriteText(10,top,'Celine in the Kitchen');
    Inc(top,10);
    Page.SetFont(FontBold,10);
    Page.WriteText(100,top,Format('BILL.%d - Due date : %s',[master.FieldByName('numbill').AsInteger,master.FieldByName('datbill').AsString]));
    Inc(top,10);
    Page.WriteText(100,top,Format('%s',[master.FieldByName('custname').AsString]));


    font := pdf.AddFont('FreeMono.ttf','FreeMono');
    page.SetFont(font,10);

    Inc(top,10);
    Page.WriteText(MARGIN,top,'PRODUCT');
    Page.WriteText(QTY, top, 'QUANTITY');
    Page.WriteText(PRICE, top, 'PRICE');
    Page.WriteText(AMOUNT, top, 'AMOUNT');
    Page.WriteText(TVA, top, 'VAT');
    total := 0;
    detail.First;
    while not detail.EOF do
    begin
      Inc(top, 8);
      montant := detail.FieldByName('quantity').AsFloat * detail.FieldByName('price').AsFloat;
      total := total + montant;

      Page.WriteText(MARGIN,top,detail.FieldByName('libprd').AsString);
      Page.WriteText(QTY, top, FormatFloat('0.00',detail.FieldByName('quantity').AsFloat));
      Page.WriteText(PRICE, top, FormatFloat('0.00',detail.FieldByName('price').AsFloat));
      Page.WriteText(AMOUNT, top, FormatFloat('0.00',montant));
      Page.WriteText(TVA, top, detail.FieldByName('codtva').AsString);
      detail.Next;
    end;

    Inc(top, 20);
    Page.SetFont(FontBold,10);
    page.WriteText(10, top, Format('TOTAL : %.2f',[total]));

    Inc(top, 20);
    page.WriteText(10,top,'VAT');
    page.SetFont(Font, 10);
    while not vat.EOF do
    begin
      Inc(top, 5);
      page.WriteText(10, top, Format('%s %.2f%% %.2f -> %.2f',[vat.FieldByName('codtva').AsString,
                                                                vat.FieldByName('vatrate').AsFloat,
                                                                vat.FieldByName('htv').AsFloat,
                                                                vat.FieldByName('vat').AsFloat]));
      vat.Next;
    end;

    Inc(top, 20);
    page.SetFont(fontBold,8);
    page.WriteText(10, top, 'CELINE IN THE KITCHEN, DIFFERDANGE');
    Inc(top,5);
    page.WriteText(10, top, 'R.C.S. Luxembourg XXXXXXX           RESTAURATEUR Autorisation XXXXXXXXX');

    //GenerateText(page, 'Celine in the Kitchen');
    //page.WriteText(10,top,'Celine in the Kitchen');

    i := 0;
    repeat
      Filename := Format('c:\temp\bill_%.4d_%.6d.pdf',[YearOf(Today),master.FieldByName('numbill').AsInteger]);
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

//procedure TBillOutput.GenerateText(page: TPDFPage; const texte: string);
//begin
//  //top := PDFTomm(page.Paper.H)-Margin;
//  //right := PDFTomm(page.Paper.W)-Margin;
//
//  //page.WriteText(2*margin,2*margin,'bottom-left');
//  //page.WriteText(2*margin,top-margin,'top-left',270);
//  //page.writeText(right-margin,top-margin,'top-right',180);
//  //page.WriteText(right-margin,2*margin,'bottom-right',90);
//end;

end.

