unit citk.PDFOutput;
(*
    This file is part of citk.

    CelineInTheKitchen software suite. Copyright (C) 2022 Luc Lacroix
      chtilux software

  *** BEGIN LICENSE BLOCK *****
  Version: MPL 1.1/GPL 2.0/LGPL 2.1

  The contents of this file are subject to the Mozilla Public License Version
  1.1 (the "License"); you may not use this file except in compliance with
  the License. You may obtain a copy of the License at
  http://www.mozilla.org/MPL

  Software distributed under the License is distributed on an "AS IS" basis,
  WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
  for the specific language governing rights and limitations under the License.

  The Original Code is citk.

  The Initial Developer of the Original Code is Luc Lacroix.

  Portions created by the Initial Developer are Copyright (C) 2022
  the Initial Developer. All Rights Reserved.

  Contributor(s):
    Luc Lacroix (chtilux)

  Alternatively, the contents of this file may be used under the terms of
  either the GNU General Public License Version 2 or later (the "GPL"), or
  the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
  in which case the provisions of the GPL or the LGPL are applicable instead
  of those above. If you wish to allow use of your version of this file only
  under the terms of either the GPL or the LGPL, and not to allow others to
  use your version of this file under the terms of the MPL, indicate your
  decision by deleting the provisions above and replace them with the notice
  and other provisions required by the GPL or the LGPL. If you do not delete
  the provisions above, a recipient may use your version of this file under
  the terms of any one of the MPL, the GPL or the LGPL.

  ***** END LICENSE BLOCK *****

*)

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, citk.Output, SQLDB, FPPDF, citk.dictionary;

type
  { TPdfOutput }

  TPdfOutput = class(TInterfacedObject, IOutput)
  protected
    FOutputDirectory: TFilename;
    FDic: IDictionary;
  public
    procedure Print(master, detail, vat: TSQLQuery); virtual;
    function CreatePDFDocument: TPDFDocument; virtual;
    function GetOutputDirectory: TFilename;
    procedure SetOutputDirectory(const AValue: TFilename);
    property OutputDirectory: TFilename read GetOutputDirectory write SetOutputDirectory;
    function GetDictionary: IDictionary;
    procedure SetDictionary(const Value: IDictionary);
    property Dic: IDictionary read GetDictionary write setDictionary;
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

function TPdfOutput.GetOutputDirectory: TFilename;
begin
  Result := FOutputDirectory;
end;

procedure TPdfOutput.SetOutputDirectory(const AValue: TFilename);
begin
  if FOutputDirectory<>AValue then
    FOutputDirectory:=AValue;
end;

function TPdfOutput.GetDictionary: IDictionary;
begin
  Result := FDic;
end;

procedure TPdfOutput.SetDictionary(const Value: IDictionary);
begin
  FDic := Value;
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
    page.WriteText(10, top, Format('TOTAL : %.2f (%s)',[total, master.FieldByName('paymentmethod').AsString]));

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
    //page.WriteText(10, top, 'R.C.S. Luxembourg XXXXXXX    TVA : LU34239512       RESTAURATEUR Autorisation 10144080/0');
    page.WriteText(10, top, Format('R.C.S. Luxembourg %s      TVA : %s     RESTAURATEUR Autorisation %s',[Dic.GetRCS, Dic.GetVatNumber, Dic.GetPersonalNumber]));

    //GenerateText(page, 'Celine in the Kitchen');
    //page.WriteText(10,top,'Celine in the Kitchen');

    i := 0;
    repeat
      Filename := Format('%s\bill_%.4d_%.6d.pdf',[ExcludeTrailingPathDelimiter(OutputDirectory),YearOf(Today),master.FieldByName('numbill').AsInteger]);
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

