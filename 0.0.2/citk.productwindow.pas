unit citk.ProductWindow;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, SQLDB, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, DBGrids, DateTimePicker, SpinEx, citk.DataGridForm, citk.global, DB,
  DBCtrls, ComCtrls, Buttons, ActnList;

type

  TUpdateOrInsertMode = (uiInsert, uiUpdate);

  { TProductW }

  TProductW = class(TDataGridForm)
    EditSalePriceAction: TAction;
    InsertSalePriceAction: TAction;
    InsertSalePriceButton1: TSpeedButton;
    SalePriceActions: TActionList;
    SalesGrid: TDBGrid;
    ProductionDataGrid: TDBGrid;
    ProductionDataNav: TDBNavigator;
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
    Validity: TDateTimePicker;
    Label1: TLabel;
    procedure DataGridKeyPress(Sender: TObject; var Key: char);
    procedure EditSalePriceActionExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure InsertSalePriceActionExecute(Sender: TObject);
    procedure SalePriceActionsUpdate(AAction: TBasicAction; var Handled: Boolean
      );
    procedure SalesQueryBeforePost(DataSet: TDataSet);
    procedure SalesQueryNewRecord(DataSet: TDataSet);
  private
    function CreatePriceWindow(Dataset: TDataset; const Pricetype: string
      ): TForm;
    function GetPrimaryKey(Dataset: TDataset; const Fieldname: string): integer; overload;
    function GetPrimaryKey: integer; overload;
    procedure UpdateOrInsertSaleP(Dataset: TDataset; const PType: string;
      const Mode: TUpdateOrInsertMode);

  protected
    procedure saveContent; override;
  public
    procedure QueryNewRecord(DataSet: TDataSet);
    procedure QueryBeforePost(DataSet: TDataSet);
    procedure QueryPostError(DataSet: TDataSet; E: EDatabaseError;
      var DataAction: TDataAction);
  end;

  procedure DisplayProducts();

implementation

{$R *.lfm}

uses
  citk.persistence, DateUtils;

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

procedure TProductW.InsertSalePriceActionExecute(Sender: TObject);
//var
//  F: TForm;
//  prd: TProducts;
begin
  UpdateOrInsertSaleP(SalesQuery, 'S', uiInsert);
//
//  F := CreatePriceWindow(SalesQuery, 'S');
//  try
//
//    if not SalesQuery.Eof then
//    begin
//      TFloatSpinEditEx(F.FindComponent('qtymin')).Value := SalesQuery.FieldByName('qtymin').Value;
//      TFloatSpinEditEx(F.FindComponent('price')).Value := SalesQuery.FieldByName('price').Value;
//    end;
//
//    if F.ShowModal = mrOk then
//    begin
//      with TSQLQuery.Create(nil) do
//      begin
//        try
//          SQLConnection:=Self.DataObject.Connector;
//          Transaction:= Self.DataObject.Transaction;
//          prd := TProducts.Create;
//          SQL.Add(prd.GetInsertPriceSQL);
//          ParamByname('serprc').Value := GetPrimaryKey;
//          ParamByname('serprd').Value := Query.FieldByName('serprd').AsInteger;
//          ParamByname('dateff').Value := TDateTimePicker(F.FindComponent('dateff')).Date;
//          ParamByName('qtymin').Value := TFloatSpinEditEx(F.FindComponent('qtymin')).Value;
//          ParamByName('price').Value := TFloatSpinEditEx(F.FindComponent('price')).Value;
//          ParamByName('ptype').Value := 'S';
//          ExecSQL;
//          Self.DataObject.Transaction.CommitRetaining;
//          Self.SalesQuery.Refresh;
//        finally
//          Free;
//        end;
//      end;
//    end;
//  finally
//    F.Free;
//  end;
end;

procedure TProductW.UpdateOrInsertSaleP(Dataset: TDataset; const PType: string; const Mode: TUpdateOrInsertMode);
var
  F: TForm;
  prd: TProducts;
begin
  F := CreatePriceWindow(Dataset, PType);
  try

    if not SalesQuery.Eof then
    begin
      TFloatSpinEditEx(F.FindComponent('qtymin')).Value := SalesQuery.FieldByName('qtymin').Value;
      TFloatSpinEditEx(F.FindComponent('price')).Value := SalesQuery.FieldByName('price').Value;
      if Mode = uiUpdate then
        TDateTimePicker(F.FindComponent('dateff')).Date := SalesQuery.FieldByName('dateff').AsDateTime;
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
              ParamByname('serprc').Value := SalesQuery.FieldByName('serprc').Value;
            end;
            uiInsert : begin
              SQL.Add(prd.GetInsertPriceSQL);
              ParamByname('serprc').Value := GetPrimaryKey;
              ParamByname('serprd').Value := Query.FieldByName('serprd').AsInteger;
              ParamByName('ptype').Value := PType;
            end;
          end;
          ParamByname('dateff').Value := TDateTimePicker(F.FindComponent('dateff')).Date;
          ParamByName('qtymin').Value := TFloatSpinEditEx(F.FindComponent('qtymin')).Value;
          ParamByName('price').Value := TFloatSpinEditEx(F.FindComponent('price')).Value;
          ExecSQL;
          Self.DataObject.Transaction.CommitRetaining;
          Dataset.Refresh;
        finally
          Free;
        end;
      end;
    end;
  finally
    F.Free;
  end;
end;

function TProductW.CreatePriceWindow(Dataset: TDataset; const Pricetype: string): TForm;
var
  F: TForm;
  alabel: TLabel;
  dateff: TDateTimePicker;
  qtymin: TFloatSpinEditEx;
  price: TFloatSpinEditEx;
  ptype: string;
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

procedure TProductW.EditSalePriceActionExecute(Sender: TObject);
//var
//  F: TForm;
//  prd: TProducts;
begin
  UpdateOrInsertSaleP(SalesQuery, 'S', uiUpdate);
  //F := CreatePriceWindow(SalesQuery, 'S');
  //try
  //
  //  if not SalesQuery.Eof then
  //  begin
  //    TDateTimePicker(F.FindComponent('dateff')).Date := SalesQuery.FieldByName('dateff').AsDateTime;
  //    TFloatSpinEditEx(F.FindComponent('qtymin')).Value := SalesQuery.FieldByName('qtymin').Value;
  //    TFloatSpinEditEx(F.FindComponent('price')).Value := SalesQuery.FieldByName('price').Value;
  //  end;
  //
  //  if F.ShowModal = mrOk then
  //  begin
  //    with TSQLQuery.Create(nil) do
  //    begin
  //      try
  //        SQLConnection:=Self.DataObject.Connector;
  //        Transaction:= Self.DataObject.Transaction;
  //        prd := TProducts.Create;
  //        SQL.Add(prd.GetUpdatePriceSQL);
  //        ParamByname('serprc').Value := SalesQuery.FieldByName('serprc').Value;
  //        ParamByname('dateff').Value := TDateTimePicker(F.FindComponent('dateff')).Date;
  //        ParamByName('qtymin').Value := TFloatSpinEditEx(F.FindComponent('qtymin')).Value;
  //        ParamByName('price').Value := TFloatSpinEditEx(F.FindComponent('price')).Value;
  //        ExecSQL;
  //        Self.DataObject.Transaction.CommitRetaining;
  //        Self.SalesQuery.Refresh;
  //      finally
  //        Free;
  //      end;
  //    end;
  //  end;
  //finally
  //  F.Free;
  //end;
end;

procedure TProductW.SalePriceActionsUpdate(AAction: TBasicAction;
  var Handled: Boolean);
begin
  InsertSalePriceAction.Enabled:=not(Query.EOF) and (Query.State = dsBrowse);
  EditSalePriceAction.Enabled:=not(SalesQuery.Eof) and (SalesQuery.State = dsBrowse);
  Handled := True;
end;

procedure TProductW.DataGridKeyPress(Sender: TObject; var Key: char);
begin
  if CompareText(TDBGrid(Sender).SelectedField.FieldName,'libprd')<>0 then
    Key := UpCase(Key);
end;

procedure TProductW.SalesQueryBeforePost(DataSet: TDataSet);
begin
  { primary key }
  Dataset.FieldByName('serprc').AsInteger:=GetPrimaryKey(Dataset, 'serprc');
end;

function TProductW.GetPrimaryKey(Dataset: TDataset; const Fieldname: string): integer;
var
  prd: IProducts;
begin
  Result := -1;
  { primary key }
  if dataset.FieldByName(Fieldname).IsNull then
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
end;

procedure TProductW.SalesQueryNewRecord(DataSet: TDataSet);
begin
  Dataset.FieldByName('serprd').Value:=Query.FieldByName('serprd').AsInteger;
  Dataset.FieldByName('dateff').Value:= Validity.Date;
  Dataset.FieldByName('qtymin').Value:=1;
  if Dataset = SalesQuery then
     Dataset.FieldByName('ptype').Value:='S';
  if Dataset = ProductionQuery then
     Dataset.FieldByName('ptype').Value:='P';
end;

procedure TProductW.QueryPostError(DataSet: TDataSet; E: EDatabaseError;
  var DataAction: TDataAction);
begin
  if Pos('is required, but not supplied',E.Message) > 0 then
  begin
    if Pos('CODPRD',E.Message) > 0 then
      MessageDlg('Code product must have a value (or Cancel the record).', mtError, [mbOk], 0);

    if Pos('LIBPRD',E.Message) > 0 then
      MessageDlg('Description product must have a value (or Cancel the record).', mtError, [mbOk], 0);

    if Pos('ACTIVE',E.Message) > 0 then
      MessageDlg('Product must be active or inactive. Check or uncheck the box (or Cancel the record).', mtError, [mbOk], 0);

    DataAction := daAbort;
  end
  else
    DataAction := daFail;
end;

procedure TProductW.saveContent;
begin
  try
    if DataObject.Transaction.Active then
    begin
      Query.ApplyUpdates;
      SalesQuery.DataSource:=nil;
      SalesQuery.First;
      while not SalesQuery.EOF do
      begin;
        if SalesQuery.UpdateStatus <> usUnmodified then
            SalesQuery.ApplyUpdates;
        SalesQuery.Next;
      end;

      ProductionQuery.ApplyUpdates;
      DataObject.Transaction.Commit;
    end;
  except
    on E:EDatabaseError do
    begin
      DataObject.Transaction.Rollback;
      MessageDlg(E.Message, mtError, [mbOk], 0);
    end;
  end;
end;

procedure TProductW.QueryNewRecord(DataSet: TDataSet);
begin
  Dataset.FieldByName('active').AsBoolean:=True;
end;

procedure TProductW.QueryBeforePost(DataSet: TDataSet);
begin
  { primary key }
  Dataset.FieldByName('serprd').AsInteger:=GetPrimaryKey(Dataset, 'serprd');
end;

{ TProductsColumns }

procedure TProductsColumns.SetOnSetDataGridColumns(ADBGrid: TDBGrid);
begin
  inherited SetOnSetDataGridColumns(ADBGrid);
  with ADBGrid.Columns.Add do
  begin
    FieldName:='serprd';
    Width := 150;
    Visible:=False;
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
    Q.AfterInsert:=@F.QueryBeforePost;
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

