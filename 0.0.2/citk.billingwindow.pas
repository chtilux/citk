unit citk.BillingWindow;
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
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Grids, Buttons, citk.Global;

type

  { TBillingW }

  TBillingW = class(TForm)
    PrintBillCheckbox: TCheckBox;
    CustomerName: TEdit;
    IDEdit: TEdit;
    Label1: TLabel;
    BillHist: TListBox;
    Shape1: TShape;
    TotalLabel: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    Splitter1: TSplitter;
    Products: TStringGrid;
    VatLabel: TLabel;
    HTVLabel: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure IDEditExit(Sender: TObject);
    procedure IDEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ProductsKeyPress(Sender: TObject; var Key: char);
    procedure ProductsSetEditText(Sender: TObject; ACol, ARow: Integer;
      const Value: string);
    procedure ProductsValidateEntry(sender: TObject; aCol, aRow: Integer;
      const OldValue: string; var NewValue: String);
  private
    FCustomerID: integer;
    FDefaultCustomer: boolean;
    FDefaultCustomerID: integer;
    FEvent: integer;
    Finfo: TInfo;
    procedure CleanForm;
    procedure CloseOrder;
    procedure ConfirmBill;
    function CreateBill(const PaymentMethod: string; var serbill: integer): integer;
    procedure FillProducts;
    procedure SetCustomerID(AValue: integer);
    procedure SetEvent(AValue: integer);
    procedure SetInfo(AValue: TInfo);
    procedure SousTotal;
    procedure TerminateOrder;

  public
    constructor Create(AOwner: TComponent; Info: TInfo; const serevt: integer); reintroduce; overload;
    property info: TInfo read Finfo write Setinfo;
    property Event: integer read FEvent write SetEvent;
    property DefaultCustomer: boolean read FDefaultCustomer;
    property CustomerID: integer read FCustomerID write SetCustomerID;
  end;

  procedure Billing(Info: TInfo; const serevt: integer);

implementation

{$R *.lfm}

uses
  citk.dictionary, citk.DataObject, citk.customers, Windows, citk.Output,
  citk.events, citk.products, citk.bill, SQLDB, DateUtils, citk.PDFOutput,
  ShellApi;

procedure Billing(Info: TInfo; const serevt: integer);
var
  BillingW: TBillingW;
begin
  BillingW := TBillingW.Create(nil, Info, serevt);
  try
    BillingW.ShowModal;
  finally
    BillingW.Free;
  end;
end;

{ TBillingW }

procedure TBillingW.IDEditExit(Sender: TObject);
var
  cust: ICustomers;
  id: integer;
begin
  FDefaultCustomer := string(TEdit(Sender).Text).Trim.IsEmpty;
  if not DefaultCustomer then
  begin
    cust := TCustomers.Create(TFirebirdDataObject.Create(glGlobalInfo.Cnx, glGlobalInfo.Transaction));
    { id }
    if TryStrToInt(IDEdit.Text, id) then
      CustomerName.Text:=cust.GetCustomerName(id)
    else
    begin
      CustomerName.Text:=cust.GetCustomerName(IDEdit.Text);
    end;
  end
  else
  begin
    cust := TCustomers.Create(TFirebirdDataObject.Create(glGlobalInfo.Cnx, glGlobalInfo.Transaction));
    CustomerName.Text:=cust.GetCustomerName(FDefaultCustomerID);
  end;
end;

procedure TBillingW.IDEditKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Products.SetFocus;
    Products.Row:=1;
    Products.Col:=3;
    Key := 0;
  end;
end;

procedure TBillingW.ProductsKeyPress(Sender: TObject; var Key: char);
begin

end;

procedure TBillingW.ProductsSetEditText(Sender: TObject; ACol, ARow: Integer;
  const Value: string);
begin

end;

procedure TBillingW.ProductsValidateEntry(sender: TObject; aCol, aRow: Integer;
  const OldValue: string; var NewValue: String);
var
  qty: double;
begin
  if ACol <> 3 then
  begin
    NewValue := OldValue;
    MessageBeep(0);
  end
  else
  begin
    if not TryStrToFloat(NewValue, qty) then
    begin
      NewValue := OldValue;
      MessageBeep(0);
    end
    else
      SousTotal;
  end;
end;

procedure TBillingW.SousTotal;
var
  i: integer;
  value: double;
  subt: double;
  vattot, htv: double;
  id: integer;
  px: IProducts;
  prd: TProduct;
begin
  subt := 0; vattot := 0;
  px := TProducts.Create(TFirebirdDataObject.Create(glGlobalInfo.Cnx, glGlobalInfo.Transaction));
  for i := 1 to Products.RowCount-1 do
  begin
    if TryStrToFloat(Products.Cells[3,i],value) then
    begin
      Value := StrToFloat(Products.Cells[2,i]) * Value;
      Products.Cells[4,i] := FloatToStr(Value);
      subt := subt + Value;

      { montant de la tva }
      id := Products.Cells[0,i].ToInteger;
      prd := px.GetProduct(id);
      htv := Value / (1+prd.VATRate/100);
      prd.Free;
      vattot := vattot + (Value - htv);
    end;
  end;
  HTVLabel.Caption := FormatFloat('0.00',subt-vattot);
  VatLabel.Caption := FormatFloat('0.00',vattot);
  TotalLabel.Caption := FormatFloat('0.00', subt);
end;

procedure TBillingW.FormCreate(Sender: TObject);
var
  dic: IDictionary;
  cust: ICustomers;
begin
  dic := TDictionary.Create(TFirebirdDataObject.Create(Info.Cnx, Info.Transaction));
  FDefaultCustomerID:=dic.GetDefaultCustomerID;
  FCustomerID:=FDefaultCustomerID;
  IDEdit.Text:=FCustomerID.ToString;
  cust := TCustomers.Create(TFirebirdDataObject.Create(Info.Cnx, Info.Transaction));
  CustomerName.Text:=cust.GetCustomerName(FCustomerID);
  FillProducts;
end;

procedure TBillingW.CleanForm;
begin
  IDEdit.SetFocus;
  FillProducts;
end;

procedure TBillingW.FillProducts;
var
  evt: IEvents;
  oda: IDataObject;
  row: integer;
begin
  Products.Clear;
  Products.ColCount:=5;
  evt := TEvents.Create;
  oda := TFirebirdDataObject.Create(Info.Cnx, Info.Transaction);
  with oda.GetQuery do
  begin
    try
      SQL.Add(evt.GetDetailSQL);
      Params[0].AsInteger:=Event;
      Open;
      First;
      Last;
      First;
      Products.RowCount:=RecordCount+1;
      Products.Cells[0,0]:='ID';
      Products.Cells[1,0]:='PRODUCT';
      Products.Cells[2,0]:='PRICE';
      Products.Cells[3,0]:='QUANTITY';
      Products.Cells[4,0]:='TOTAL';
      row:=0;
      while not Eof do
      begin
        Inc(Row);
        Products.Cells[0,row]:=FieldByName('serprd').AsString;
        Products.Cells[1,row]:=FieldByName('libprd').AsString;
        Products.Cells[2,row]:=FieldByName('price').AsString;
        Products.Cells[3,row]:='0';
        Products.Cells[4,row]:='0';
        Next;
      end;
      Close;
    finally
      Free;
    end;
  end;
end;

procedure TBillingW.SetEvent(AValue: integer);
begin
  if FEvent=AValue then Exit;
  FEvent:=AValue;
end;

procedure TBillingW.SetCustomerID(AValue: integer);
begin
  if FCustomerID=AValue then Exit;
  FCustomerID:=AValue;
end;

procedure TBillingW.Setinfo(AValue: TInfo);
begin
  if Finfo=AValue then Exit;
  Finfo:=AValue;
end;

constructor TBillingW.Create(AOwner: TComponent; Info: TInfo;
  const serevt: integer);
begin
  Finfo:=Info;
  FEvent:=serevt;
  inherited Create(AOwner);
  Caption := Event.ToString;
end;

procedure TBillingW.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ADD then
  begin
    Key := 0;
    ConfirmBill;
  end;
end;

procedure TBillingW.FormShow(Sender: TObject);
begin
  IDEdit.SetFocus;
end;

procedure TBillingW.ConfirmBill;
begin
  if MessageDlg('Close and account the order ?', mtConfirmation, [mbYes, mbNo], 0, mbYes) = mrYes then
    CloseOrder
  else
  begin
    Products.SetFocus;
  end;
end;

procedure TBillingW.CloseOrder;
begin
  TerminateOrder;
  CleanForm;
end;

procedure TBillingW.TerminateOrder;
var
  dao: IDataObject;
  dic: IDictionary;
  pm: TStrings;
  F: TForm;
  ctl: TRadioGroup;
  btn: TBitBtn;
  PaymentMethod: string;
  SerBill, BillNumber: integer;
  Bill: IBills;
  bo: IOutput;
begin
  if StrToFloat(TotalLabel.Caption) = 0 then Exit;
  dao := TFirebirdDataObject.Create(Info.Cnx, Info.Transaction);
  dic := TDictionary.Create(dao);
  pm := dic.GetPaymentMethod;
  try
    F := TForm.Create(nil);
    try
      F.Position:=poScreenCenter;
      ctl := TRadioGroup.Create(F);
      ctl.Name := 'pm';
      ctl.Parent := F;
      ctl.Items.AddStrings(pm);
      ctl.ItemIndex:=0;
      F.AutoSize:=True;
      btn := TBitBtn.Create(F);
      btn.Parent:=F;
      btn.Top := 300;
      btn.Left := 50;
      btn.Kind:=bkOk;
      F.ShowModal;
      Paymentmethod := ctl.Items[ctl.ItemIndex];
    finally
      F.Free;
    end;
  finally
    pm.Free;
  end;
  Serbill := 0;  // ne sert à rien mais évite le warning
  BillNumber := CreateBill(PaymentMethod, SerBill);
  BillHist.Items.Insert(0, Format('N°%d -> %s (%s)', [BillNumber, TotalLabel.Caption, PaymentMethod]));
  if PrintBillCheckbox.Checked then
  begin
    bill := TBills.Create(dao);
    bo:=TBillOutput.Create;
    bo.OutputDirectory:=dic.GetOutputDirectory;
    bill.Print(SerBill, bo);
    ShellExecute(0,'open',PChar(bo.OutputDirectory),nil,nil,1);
  end;
end;

function TBillingW.CreateBill(const PaymentMethod: string; var serbill: integer): integer;
var
  dao: IDataObject;
  bill: IBills;
  master, detail, vat: TSQLQuery;
  row: integer;
  rowqty, rowprice, rowtotal, htv: double;
  ttc: double;
  px: IProducts;
  prd: TProduct;
  serprd: integer;
  tva: TVatValue;
  VatValues: TStrings;
  VatIndex: integer;
const
  ID=0; LIBPRD=1; PRICE=2; QTY=3;// TOTAL=4;
begin
  dao := TFirebirdDataObject.Create(glGlobalInfo.Cnx, glGlobalInfo.Transaction);
  bill := TBills.Create(dao);
  Result := bill.GetBillNumber;
  serbill := bill.GetPK;
  detail := nil; vat := nil; VatValues := nil;
  master := dao.GetQuery;
  try
    master.SQL.Add(bill.GetInsertBillSQL);
    detail := dao.GetQuery;
    detail.SQL.Add(bill.GetInsertBillDetailSQL);
    detail.Prepare;
    detail.ParamByName('serbill').AsInteger := serbill;
    vat := dao.GetQuery;
    vat.SQL.Add(bill.GetInsertBillVatSQL);
    vat.ParamByName('serbill').AsInteger:=serbill;
    VatValues := TStringList.Create;

    px := TProducts.Create(dao);
    ttc := 0;
    try
      master.ParamByName('serbill').AsInteger:=serbill;
      master.ParamByName('datbill').AsDate:=Today;
      master.ParamByName('numbill').AsInteger:=Result;
      master.ParamByName('PaymentMethod').AsString:=PaymentMethod;
      master.ParamByName('totttc').AsFloat:=StrToFloat(TotalLabel.Caption);
      master.ParamByName('customerid').AsInteger:=string(IDEdit.Text).ToInteger;
      master.ExecSQL;
      { pour chaque ligne de produit }
      for row := 1 to Products.RowCount-1 do
      begin
        { si la quantité <> 0 }
        if TryStrToFloat(Products.Cells[QTY,row], rowqty) then
        begin
          if rowqty <> 0 then
          begin
            rowprice:=StrToFloatDef(Products.Cells[PRICE,row],0);
            rowtotal := rowqty * rowprice;
            ttc := ttc + rowtotal;
            serprd := StrToInt(Products.Cells[ID,row]);
            detail.ParamByName('serdet').AsInteger := bill.GetPK;
            detail.ParamByName('serprd').AsInteger := serprd;
            detail.ParamByName('libprd').AsString := Products.Cells[LIBPRD,row];
            detail.ParamByName('quantity').AsFloat := rowqty;
            detail.ParamByName('price').AsFloat := rowprice;
            prd := px.GetProduct(serprd);
            detail.ParamByName('codtva').AsString := prd.VATCode;
            detail.ParamByName('vatrate').AsFloat:=prd.VATRate;
            htv := rowTotal/(1+prd.VATRate/100);
            VatIndex := VatValues.IndexOf(prd.VATCode);
            if VatIndex > -1 then
            begin
              tva := TVatValue(VatValues.Objects[vatIndex]);
              tva.AddValue(htv,rowtotal-htv);
            end
            else
            begin
              tva := TVatValue.Create(prd.VATCode,prd.VATRate,htv,rowtotal-htv);
              VatValues.AddObject(tva.CodTva,tva);
            end;
            prd.Free;
            detail.ExecSQL;
          end;
        end;
      end;

      for VatIndex:=0 to VatValues.Count-1 do
      begin
        tva := TVatValue(VatValues.Objects[vatIndex]);
        vat.ParamByName('codtva').AsString:=tva.CodTva;
        vat.ParamByName('vatrate').AsFloat:=tva.Rate;
        vat.ParamByName('htv').AsFloat:=tva.HTV;
        vat.ParamByName('vat').AsFloat:=tva.VAT;
        vat.ExecSQL;
        tva.Free;
      end;
      dao.Transaction.CommitRetaining;

      Info.Log(Format('BILL %d created for customer %d', [Result, master.ParamByName('customerid').AsInteger]));

    except
      on E:Exception do
      begin
        dao.Transaction.RollbackRetaining;
        Info.Log(E.Message);
        raise;
      end;
    end;
  finally
    master.free;
    detail.Free;
    vat.Free;
    VatValues.Free;
  end;
end;

end.

