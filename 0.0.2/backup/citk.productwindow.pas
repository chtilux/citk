unit citk.ProductWindow;
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

{$mode ObjFPC}

interface

uses
  Classes, SysUtils, SQLDB, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, DBGrids, DateTimePicker, SpinEx, citk.DataGridForm, citk.global, DB,
  DBCtrls, ComCtrls, Buttons, ActnList;

type

  TUpdateOrInsertMode = (uiInsert, uiUpdate);

  { TProductW }

  TProductW = class(TDataGridForm)
    DeleteProductionPriceAction: TAction;
    DeleteSalePriceAction: TAction;
    DeleteProductionPriceButton: TSpeedButton;
    UpdateProductionPriceAction: TAction;
    InsertProductionPriceAction: TAction;
    UpdateSalePriceAction: TAction;
    InsertSalePriceAction: TAction;
    UpdateSalePriceButton: TSpeedButton;
    InsertProductionPriceButton: TSpeedButton;
    UpdateProductionPriceButton: TSpeedButton;
    SalePriceActions: TActionList;
    SalesGrid: TDBGrid;
    ProductionDataGrid: TDBGrid;
    DataNavPanel1: TPanel;
    DataNavPanel2: TPanel;
    Label2: TLabel;
    Label3: TLabel;
    SalesDataSource: TDataSource;
    ProductionDataSource: TDataSource;
    SalesPanel: TPanel;
    ProductionPanel: TPanel;
    ProductionQuery: TSQLQuery;
    InsertSalePriceButton: TSpeedButton;
    Splitter1: TSplitter;
    SalesQuery: TSQLQuery;
    DeleteSalePriceButton: TSpeedButton;
    Validity: TDateTimePicker;
    Label1: TLabel;
    procedure DataGridKeyPress(Sender: TObject; var Key: char);
    procedure DeleteProductionPriceActionExecute(Sender: TObject);
    procedure DeleteSalePriceActionExecute(Sender: TObject);
    procedure UpdateSalePriceActionExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure InsertProductionPriceActionExecute(Sender: TObject);
    procedure InsertSalePriceActionExecute(Sender: TObject);
    procedure SalePriceActionsUpdate(AAction: TBasicAction; var Handled: Boolean
      );
    //procedure SalesQueryBeforePost(DataSet: TDataSet);
    //procedure SalesQueryNewRecord(DataSet: TDataSet);
    procedure UpdateProductionPriceActionExecute(Sender: TObject);
  private
    {$H-}
    FSerPrd: integer;
    function CreatePriceWindow(const Pricetype: string): TForm;
    procedure DeletePrice(Dataset: TDataset);
    function GetPrimaryKey: integer;
    procedure UpdateOrInsertSaleP(Dataset: TDataset; const PType: string;
      const Mode: TUpdateOrInsertMode);
  public
    procedure QueryNewRecord(DataSet: TDataSet);
    procedure QueryBeforePost(DataSet: TDataSet);
    procedure QueryAfterPost(DataSet: TDataSet);
    procedure QueryBeforeDelete(Dataset: TDataset);
    procedure QueryAfterDelete(Dataset: TDataset);
    procedure QueryPostError(DataSet: TDataSet; E: EDatabaseError;
      var DataAction: TDataAction);
  end;

  procedure DisplayProducts();

implementation

{$R *.lfm}

uses
  DateUtils, citk.products, citk.dictionary;

type

  { TProductsColumns }

  TProductsColumns = class(TSetDataGridColumnsHelper)
  public
    procedure SetOnSetDataGridColumns(ADBGrid: TDBGrid); override;
  end;

  { TProductW }

procedure TProductW.FormCreate(Sender: TObject);
var
  prd: IProducts;
begin
  Validity.Date:=Today;

  SalesQuery.SQLConnection:=DataObject.Connector;
  SalesQuery.Transaction:=DataObject.Transaction;

  ProductionQuery.SQLConnection:=DataObject.Connector;
  ProductionQuery.Transaction:=DataObject.Transaction;

  { getting sql statments }
  prd := TProducts.Create;
  SalesQuery.SQL.Add(prd.GetPriceSQL('S'));
  SalesQuery.Open;

  ProductionQuery.SQL.Add(prd.GetPriceSQL('P'));
  ProductionQuery.Open;

  FSerPrd := -1;
end;

procedure TProductW.FormShow(Sender: TObject);
begin
  inherited;
  with SalesGrid.Columns.Add do
  begin
    FieldName:='serprc';
    Width := 150;
    Visible:=False;
    Title.Caption:='ID';
  end;
  with SalesGrid.Columns.Add do
  begin
    FieldName:='serprd';
    Width := 150;
    Visible:=False;
    ReadOnly := True;
    Title.Caption:='Product''s ID';
  end;
  with SalesGrid.Columns.Add do
  begin
    FieldName:='ptype';
    Width := 150;
    Visible:=False;
    Title.Caption:='Type';
  end;
  with SalesGrid.Columns.Add do
  begin
    FieldName:='dateff';
    Width := 150;
    Title.Caption:='Validity';
  end;
  with SalesGrid.Columns.Add do
  begin
    FieldName:='qtymin';
    Width := 150;
    Visible:=False;
    Title.Caption:='Min. Quantity';
  end;
  with SalesGrid.Columns.Add do
  begin
    FieldName:='price';
    Width := 150;
    Title.Caption:='Sale price TTC';
  end;

  with ProductionDataGrid.Columns.Add do
  begin
    FieldName:='serprc';
    Width := 150;
    Visible:=False;
    Title.Caption:='ID';
  end;
  with ProductionDataGrid.Columns.Add do
  begin
    FieldName:='serprd';
    Width := 150;
    Visible:=False;
    Title.Caption:='Product''s ID';
  end;
  with ProductionDataGrid.Columns.Add do
  begin
    FieldName:='ptype';
    Width := 150;
    Visible:=False;
    Title.Caption:='Type';
  end;
  with ProductionDataGrid.Columns.Add do
  begin
    FieldName:='dateff';
    Width := 150;
    Title.Caption:='Validity';
  end;
  with ProductionDataGrid.Columns.Add do
  begin
    FieldName:='qtymin';
    Width := 150;
    Visible:=False;
    Title.Caption:='Min. Quantity';
  end;
  with ProductionDataGrid.Columns.Add do
  begin
    FieldName:='price';
    Width := 150;
    Title.Caption:='Cost price TTC';
  end;
end;

procedure TProductW.InsertProductionPriceActionExecute(Sender: TObject);
begin
  UpdateOrInsertSaleP(ProductionQuery, 'P', uiInsert);
end;

procedure TProductW.UpdateProductionPriceActionExecute(Sender: TObject);
begin
  UpdateOrInsertSaleP(ProductionQuery, 'P', uiUpdate);
end;

procedure TProductW.InsertSalePriceActionExecute(Sender: TObject);
begin
  UpdateOrInsertSaleP(SalesQuery, 'S', uiInsert);
end;

procedure TProductW.UpdateSalePriceActionExecute(Sender: TObject);
begin
  UpdateOrInsertSaleP(SalesQuery, 'S', uiUpdate);
end;

procedure TProductW.UpdateOrInsertSaleP(Dataset: TDataset; const PType: string; const Mode: TUpdateOrInsertMode);
var
  F: TForm;
  prd: TProducts;
  log: string;
begin
  F := CreatePriceWindow(PType);
  try

    if not Dataset.Eof then
    begin
      TFloatSpinEditEx(F.FindComponent('qtymin')).Value := Dataset.FieldByName('qtymin').AsFloat;
      TFloatSpinEditEx(F.FindComponent('price')).Value := Dataset.FieldByName('price').AsFloat;
      if Mode = uiUpdate then
        TDateTimePicker(F.FindComponent('dateff')).Date := Dataset.FieldByName('dateff').AsDateTime;
    end;

    if F.ShowModal = mrOk then
    begin
      with TSQLQuery.Create(nil) do
      begin
        try
          SQLConnection:=Self.DataObject.Connector;
          Transaction:= Self.DataObject.Transaction;
          prd := TProducts.Create;
          case Mode of
            uiUpdate : begin
              SQL.Add(prd.GetUpdatePriceSQL);
              ParamByName('serprc').Value := Dataset.FieldByName('serprc').Value;
              log := Format('Update of Price serprc=%d, serprd=%d, dateff=%s, qtymin=%f, price=%f, type=%s', [Dataset.FieldByname('serprc').AsInteger,
                                                                                                              Dataset.FieldByname('serprd').AsInteger,
                                                                                                              Dataset.FieldByname('dateff').AsString,
                                                                                                              Dataset.FieldByname('qtymin').AsFloat,
                                                                                                              Dataset.FieldByname('price').AsFloat,
                                                                                                              Dataset.FieldByname('ptype').AsString]);
            end;
            uiInsert : begin
              SQL.Add(prd.GetInsertPriceSQL);
              ParamByName('serprc').AsInteger := GetPrimaryKey;
              ParamByName('serprd').AsInteger := Query.FieldByName('serprd').AsInteger;
              ParamByName('ptype').AsString := PType;
            end;
          end;
          ParamByName('dateff').AsDate := TDateTimePicker(F.FindComponent('dateff')).Date;
          ParamByName('qtymin').AsFloat := TFloatSpinEditEx(F.FindComponent('qtymin')).Value;
          ParamByName('price').AsFloat := TFloatSpinEditEx(F.FindComponent('price')).Value;
          try
            ExecSQL;
            Self.DataObject.Transaction.CommitRetaining;
            case Mode of
              uiInsert : log := Format('Price serprc=%d, serprd=%d, dateff=%s, qtymin=%f, price=%f, type=%s inserted', [ParamByName('serprc').AsInteger,
                                                                                                                        ParamByName('serprd').AsInteger,
                                                                                                                        ParamByName('dateff').AsString,
                                                                                                                        ParamByName('qtymin').AsFloat,
                                                                                                                        ParamByName('price').AsFloat,
                                                                                                                        ParamByName('ptype').AsString]);
              uiUpdate : begin
                Info.Log(log);
                log := Format('NEW Value serprc=%d, dateff=%s, qtymin=%f, price=%f', [ParamByName('serprc').AsInteger,
                                                                                      ParamByName('dateff').AsString,
                                                                                      ParamByName('qtymin').AsFloat,
                                                                                      ParamByName('price').AsFloat]);
              end;
            end;
            Info.Log(log);
            Dataset.Refresh;
          except
            on E:EDatabaseError do
            begin
              if Pos('I01_PRICES', E.Message) > 0 then
              begin
                log := Format('A price already exists for validity date %s',[ParamByName('dateff').AsString]);
                MessageDlg(log, mtError, [mbOk], 0);
                Info.Log(Format('ERROR : %s',[log]));
              end
              else
                raise;
            end;
          end;
        finally
          Free;
        end;
      end;
    end;
  finally
    F.Free;
  end;
end;

function TProductW.CreatePriceWindow(const Pricetype: string): TForm;
var
  F: TForm;
  dateff: TDateTimePicker;
  qtymin: TFloatSpinEditEx;
  price: TFloatSpinEditEx;
  OkButton: TBitBtn;

  function CreateLabel(const Caption: string; const X,Y: integer):TLabel;
  begin
    Result := TLabel.Create(F);
    Result.Parent := F;
    Result.Caption := Caption;
    Result.Left := X;
    Result.Top := Y;
  end;

begin
  F := TForm.Create(nil);
  F.Caption := Pricetype;
  F.Position:=poScreenCenter;

  CreateLabel('Validity date :', 20, 22);
  dateff := TDateTimePicker.Create(F);
  dateff.Name := 'dateff';
  dateff.Parent := F;
  dateff.Top := 20;
  dateff.Left := 150;

  CreateLabel('Minimum Quantity :', 20, 52);
  qtymin := TFloatSpinEditEx.Create(F);
  qtymin.Name := 'qtymin';
  qtymin.Parent := F;
  qtymin.Value := 0.10;
  qtymin.Top:=50;
  qtymin.Left:=150;
  qtymin.Increment:=0.10;
  qtymin.MinValue:=0.10;

  CreateLabel('Price :', 20, 82);
  price := TFloatSpinEditEx.Create(F);
  price.Name := 'price';
  price.Parent := F;
  price.Value := 0.00;
  price.Top:=80;
  price.Left:=150;
  price.Increment:=0.10;

  OkButton := TBitBtn.Create(F);
  OkButton.Parent := F;
  OkButton.Kind:=bkOK;
  OkButton.Top:=110;
  OkButton.Left:=150;
  OkButton.Caption := 'Validate';

  Result := F;
end;

function TProductW.GetPrimaryKey: integer;
var
  prd: IProducts;
begin
  with TSQLQuery.Create(nil) do
  begin
    try
      SQLConnection:=Self.DataObject.Connector;
      Transaction:=Self.DataObject.Transaction;
      prd := TProducts.Create;
      SQL.Add(prd.GetPKSQL);
      Open;
      Result:=Fields[0].AsInteger;
      Close;
    finally
      Free;
    end;
  end;
end;

procedure TProductW.SalePriceActionsUpdate(AAction: TBasicAction;
  var Handled: Boolean);
begin
  InsertSalePriceAction.Enabled:=not(Query.EOF);
  UpdateSalePriceAction.Enabled:=not(SalesQuery.Eof);
  InsertProductionPriceAction.Enabled:=not(Query.EOF);
  UpdateProductionPriceAction.Enabled:=not(ProductionQuery.Eof);
  DeleteSalePriceAction.Enabled:=not(SalesQuery.Eof);
  Handled := True;
end;

procedure TProductW.DataGridKeyPress(Sender: TObject; var Key: char);
begin
  Key := UpCase(Key);
end;

procedure TProductW.DeleteProductionPriceActionExecute(Sender: TObject);
begin
  DeletePrice(ProductionQuery);
end;

procedure TProductW.DeleteSalePriceActionExecute(Sender: TObject);
begin
  DeletePrice(SalesQuery);
end;

procedure TProductW.DeletePrice(Dataset: TDataset);
var
  prd: IProducts;
  log: string;
begin
  if MessageDlg('Confirm price delete ?', mtConfirmation, [mbYes, mbNo], 0, mbNo) = mrYes then
  begin
    with TSQLQuery.Create(nil) do
    begin
      try
        SQLConnection:=Self.DataObject.Connector;
        Transaction:=Self.DataObject.Transaction;
        prd := TProducts.Create;
        SQL.Add(prd.GetDeletePriceSQL);
        Params[0].AsInteger:=Dataset.FieldByname('serprc').AsInteger;
        log := Format('Price serprc=%d, serprd=%d, dateff=%s, qtymin=%f, price=%f, type=%s deleted', [Dataset.FieldByname('serprc').AsInteger,
                                                                                                      Dataset.FieldByname('serprd').AsInteger,
                                                                                                      Dataset.FieldByname('dateff').AsString,
                                                                                                      Dataset.FieldByname('qtymin').AsFloat,
                                                                                                      Dataset.FieldByname('price').AsFloat,
                                                                                                      Dataset.FieldByname('ptype').AsString]);
        ExecSQL;
        Self.DataObject.Transaction.CommitRetaining;
        Self.Info.Log(log);
        Dataset.Refresh;
      finally
        Free;
      end;
    end;
  end;
end;

procedure TProductW.QueryPostError(DataSet: TDataSet; E: EDatabaseError;
  var DataAction: TDataAction);
var
  log: string;
begin
  log := E.Message;
  if Pos('is required, but not supplied',E.Message) > 0 then
  begin
    if Pos('CODPRD',E.Message) > 0 then
      log := 'Code product must have a value (or Cancel the record).';

    if Pos('LIBPRD',E.Message) > 0 then
      log := 'Description product must have a value (or Cancel the record).';

    if Pos('ACTIVE',E.Message) > 0 then
      log := 'Product must be active or inactive. Check or uncheck the box (or Cancel the record).';

    MessageDlg(log, mtError, [mbOk], 0);
    DataAction := daAbort;
    Info.Log(log);
  end
  else
  begin
    DataAction := daFail;
    Info.Log(log);
  end;
end;

procedure TProductW.QueryNewRecord(DataSet: TDataSet);
var
 q: TSQLQuery;
 dic: IDictionary;
begin
  Dataset.FieldByName('active').AsBoolean:=True;
  q := DataObject.GetQuery;
  try
    dic := TDictionary.Create;
    q.SQL.Add(dic.GetDefaultSalesVatCode);
    q.Open;
    Dataset.FieldByName('codtva').AsString:=q.FieldByName('DefaultVATCD').AsString;
  finally
    q.Free;
  end;
  Info.Log('Inserting new product');
end;

procedure TProductW.QueryBeforePost(DataSet: TDataSet);
begin
  { primary key }
  if (Dataset.State = dsInsert) and (Dataset.FieldByName('serprd').IsNull) then
    Dataset.FieldByName('serprd').AsInteger:=GetPrimaryKey;
end;

procedure TProductW.QueryAfterPost(DataSet: TDataSet);
var
  log: string;
begin
  log := Format('POST : serprd=%d, codprd=%s, libprd=%s, active=%s', [Dataset.FieldByName('serprd').AsInteger,
                                                                      Dataset.FieldByName('codprd').AsString,
                                                                      Dataset.FieldByName('libprd').AsString,
                                                                      BoolToStr(Dataset.FieldByName('active').AsBoolean,True)]);
  Info.Log(log);
  Query.ApplyUpdates;
  DataObject.Transaction.CommitRetaining;
end;

procedure TProductW.QueryBeforeDelete(Dataset: TDataset);
begin
  FSerPrd:=Dataset.FieldByName('serprd').AsInteger;
end;

procedure TProductW.QueryAfterDelete(Dataset: TDataset);
var
  prd: IProducts;
begin
  if FSerprd > -1 then
  begin
    prd := TProducts.Create;
    with TSQLQuery.Create(nil) do
    begin
      try
        SQLConnection:=DataObject.Connector;
        Transaction:=DataObject.Transaction;
        SQL.Add(prd.GetDeleteProductPricesSQL);
        ParamByName('serprd').AsInteger:=FSerprd;
        ExecSQL;
        DataObject.Transaction.CommitRetaining;
        Info.Log(Format('Product %d and prices are deleted.',[FSerPrd]));
        FSerprd:=-1;
      finally
        Free;
      end;
    end;
  end;
end;

{ TProductsColumns }

procedure TProductsColumns.SetOnSetDataGridColumns(ADBGrid: TDBGrid);
begin
  inherited SetOnSetDataGridColumns(ADBGrid);
  with ADBGrid.Columns.Add do
  begin
    FieldName:='serprd';
    Width := 80;
    Alignment:=taCenter;
    Visible:=True;
    ReadOnly := True;
    Title.Caption:='ID';
  end;
  with ADBGrid.Columns.Add do
  begin
    FieldName:='codprd';
    Width := 150;
    Title.Caption:='Code';
  end;
  with ADBGrid.Columns.Add do
  begin
    FieldName:='libprd';
    Width := 250;
    Title.Caption:='Description';
  end;
  with ADBGrid.Columns.Add do
  begin
    FieldName:='active';
    Width := 80;
    Title.Caption:='Active';
  end;
  with ADBGrid.Columns.Add do
  begin
    FieldName:='codtva';
    Width := 80;
    Title.Caption:='TVA';
  end;
end;

procedure DisplayProducts;
var
  F: TProductW;
  Q: TSQLQuery;
  prd: IProducts;
  dbgh: TSetDataGridColumnsHelper;
begin
  dbgh := nil;
  F := TProductW.Create(nil, glGlobalInfo);
  try
    Q := TSQLQuery.Create(F);
    Q.SQLConnection:=F.DataObject.Connector;
    Q.Transaction:=F.DataObject.Transaction;
    prd := TProducts.Create;
    Q.SQL.Add(prd.GetSQL);
    Q.OnNewRecord:=@F.QueryNewRecord;
    Q.BeforePost:=@F.QueryBeforePost;
    Q.AfterPost:=@F.QueryAfterPost;
    Q.AfterInsert:=@F.QueryBeforePost;
    Q.BeforeDelete:=@F.QueryBeforeDelete;
    Q.AfterDelete:=@F.QueryAfterDelete;
    Q.OnPostError:=@F.QueryPostError;
    F.Query:=Q;
    Q.Open;
    dbgh := TProductsColumns.Create;
    F.OnSetDataGridColumns:=@dbgh.SetOnSetDataGridColumns;
    F.ShowModal;
  finally
    F.Free;
    dbgh.Free;
  end;
end;

end.

