unit citk.bill;
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
  Classes, SysUtils, citk.DataObject, citk.Output;

type
  IBills = interface
  ['{FFC4985C-BA10-4984-BF8A-4C3F99576DC5}']
    function GetPK: integer;
    function GetBillNumber: integer;
    function GetInsertBillSQL: string;
    function GetInsertBillDetailSQL: string;
    function GetInsertBillVatSQL: string;
    procedure Print(const serbill: integer);
    procedure Print(const serbill: integer; OutputMode: IOutput);
  end;

  { TBills }

  TBills = class(TInterfacedObject, IBills)
  private
    FDataObject: IDataObject;
    function GetPKSQL: string;
  public
    constructor Create(DataObject: IDataObject);
    function GetPK: integer;
    function GetBillNumber: integer;
    function GetInsertBillSQL: string;
    function GetInsertBillDetailSQL: string;
    function GetInsertBillVatSQL: string;
    procedure Print(const serbill: integer);                      overload;
    procedure Print(const serbill: integer; OutputMode: IOutput); overload;
  end;

  { TVatValue }

  TVatValue = class
  private
    FCodTva: string;
    FHTV: double;
    FRate: double;
    FVAT: double;
    procedure SetCodTva(AValue: string);
    procedure SetHTV(AValue: double);
    procedure SetRate(AValue: double);
    procedure SetVAT(AValue: double);
  public
    constructor Create(const codtva: string; const Rate, HTV, VAT: double);
    property CodTva: string read FCodTva write SetCodTva;
    property Rate: double read FRate write SetRate;
    property HTV: double read FHTV write SetHTV;
    property VAT: double read FVAT write SetVAT;
    procedure AddValue(const htvValue, Value: double);
  end;

implementation

uses
  citk.dictionary, SQLDB, citk.PDFOutput;

{ TVatValue }

procedure TVatValue.SetCodTva(AValue: string);
begin
  if FCodTva=AValue then Exit;
  FCodTva:=AValue;
end;

procedure TVatValue.SetHTV(AValue: double);
begin
  if FHTV=AValue then Exit;
  FHTV:=AValue;
end;

procedure TVatValue.SetRate(AValue: double);
begin
  if FRate=AValue then Exit;
  FRate:=AValue;
end;

procedure TVatValue.SetVAT(AValue: double);
begin
  if FVAT=AValue then Exit;
  FVAT:=AValue;
end;

constructor TVatValue.Create(const codtva: string; const Rate, HTV, VAT: double
  );
begin
  FCodTva:=codtva;
  FRate:=Rate;
  FHTV:=HTV;
  FVAT:=VAT;
end;

procedure TVatValue.AddValue(const htvValue, Value: double);
begin
  FHTV:=FHTV+htvValue;
  FVAT:=FVAT+Value;
end;

{ TBills }

function TBills.GetPKSQL: string;
begin
  Result := 'SELECT GEN_ID(seq_bill,1) FROM rdb$database';
end;

constructor TBills.Create(DataObject: IDataObject);
begin
  FDataObject := DataObject;
end;

function TBills.GetPK: integer;
begin
  with FDataObject.GetQuery do
  begin
    try
      SQL.Add(GetPKSQL);
      Open;
      Result := Fields[0].AsInteger;
      Close;
    finally
      Free;
    end;
  end;
end;

function TBills.GetBillNumber: integer;
var
  dic: IDictionary;
begin
  dic := TDictionary.Create(FDataObject);
  Result := dic.GetNextBillNumber;
end;

function TBills.GetInsertBillSQL: string;
begin
  Result := 'INSERT INTO bill'
           +' (serbill,datbill,numbill,paymentmethod,totttc,customerid)'
           +' VALUES'
           +' (:serbill,:datbill,:numbill,:paymentmethod,:totttc,:customerid)';
end;

function TBills.GetInsertBillDetailSQL: string;
begin
  Result := 'INSERT INTO bill_detail'
           +' (serdet,serbill,serprd,libprd,quantity,price,codtva,vatrate)'
           +' VALUES'
           +' (:serdet,:serbill,:serprd,:libprd,:quantity,:price,:codtva,:vatrate)';
end;

function TBills.GetInsertBillVatSQL: string;
begin
  Result := 'UPDATE OR INSERT INTO BILL_VAT (serbill,codtva,vatrate,htv,vat)'
           +' VALUES (:serbill,:codtva,:vatrate,:htv,:vat)';
end;

procedure TBills.Print(const serbill: integer);
var
  master,
  detail,
  vat: TSQLQuery;
  output: IOutput;
begin
  detail := nil; vat := nil;
  master := FDataObject.GetQuery;
  try
    master.SQL.Add('SELECT'
                  +'  b.serbill,b.datbill,b.numbill,b.paymentmethod,b.totttc'
                  +' ,c.custname'
                  +' FROM bill b LEFT JOIN customers c ON b.customerid = c.sercust'
                  +' WHERE b.serbill = :serbill');
    master.ParamByName('serbill').AsInteger:=serbill;

    detail := FDataObject.GetQuery;
    detail.SQL.Add('SELECT libprd,quantity,price,codtva'
                  +' FROM bill_detail'
                  +' WHERE serbill = :serbill'
                  +' ORDER BY libprd');
    detail.ParamByName('serbill').AsInteger:=master.ParamByName('serbill').AsInteger;

    vat := FDataObject.GetQuery;
    vat.SQL.Add('SELECT codtva,vatrate,htv,vat'
               +' FROM bill_vat'
               +' WHERE serbill = :serbill');
    vat.ParamByName('serbill').AsInteger:=master.ParamByName('serbill').AsInteger;

    master.Open;
    detail.Open;
    vat.Open;

    output := TPdfOutput.Create;
    output.Print(master, detail, vat);
  finally
    master.Free;
    detail.Free;
    vat.Free;
  end;
end;

procedure TBills.Print(const serbill: integer; OutputMode: IOutput);
var
  master,
  detail,
  vat: TSQLQuery;
begin
  detail := nil; vat := nil;
  master := FDataObject.GetQuery;
  try
    master.SQL.Add('SELECT'
                  +'  b.serbill,b.datbill,b.numbill,b.paymentmethod,b.totttc'
                  +' ,c.custname'
                  +' FROM bill b LEFT JOIN customers c ON b.customerid = c.sercust'
                  +' WHERE b.serbill = :serbill');
    master.ParamByName('serbill').AsInteger:=serbill;

    detail := FDataObject.GetQuery;
    detail.SQL.Add('SELECT libprd,quantity,price,codtva'
                  +' FROM bill_detail'
                  +' WHERE serbill = :serbill'
                  +' ORDER BY libprd');
    detail.ParamByName('serbill').AsInteger:=master.ParamByName('serbill').AsInteger;

    vat := FDataObject.GetQuery;
    vat.SQL.Add('SELECT codtva,vatrate,htv,vat'
               +' FROM bill_vat'
               +' WHERE serbill = :serbill');
    vat.ParamByName('serbill').AsInteger:=master.ParamByName('serbill').AsInteger;

    master.Open;
    detail.Open;
    vat.Open;

    OutputMode.Print(master, detail, vat);
  finally
    master.Free;
    detail.Free;
    vat.Free;
  end;
end;

end.

