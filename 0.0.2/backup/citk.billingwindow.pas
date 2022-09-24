unit citk.BillingWindow;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Grids, Buttons, citk.Global;

type

  { TBillingW }

  TBillingW = class(TForm)
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
    function CreateBill: integer;
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
  citk.dictionary, citk.DataObject, citk.customers, Windows,
  citk.events, citk.products;

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

procedure TBillingW.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ADD then
  begin
    Key := 0;
    ConfirmBill;
  end;
end;

procedure TBillingW.ConfirmBill;
begin
  if MessageDlg('Close the order ?', mtConfirmation, [mbYes, mbNo], 0, mbYes) = mrYes then
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
  dic: IDictionary;
  pm: TStrings;
  F: TForm;
  ctl: TRadioGroup;
  btn: TBitBtn;
  PaymentMethod: string;
  BillNumber: integer;
begin
  dic := TDictionary.Create(TFirebirdDataObject.Create(glGlobalInfo.Cnx, glGlobalInfo.Transaction));
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
  BillNumber := CreateBill;
  BillHist.Items.Insert(0, Format('N°%d -> %s', [BillNumber, TotalLabel.Caption]));
end;

function TBillingW.CreateBill: integer;
var
  dic: IDictionary;
begin
  dic := TDictionary.Create(TFirebirdDataObject.Create(glGlobalInfo.Cnx, glGlobalInfo.Transaction));
  Result := dic.GetNextBillNumber;
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

end.

