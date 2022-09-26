unit citk.DataGridForm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, DB, SQLDB, Forms, Controls, Graphics,
  Dialogs, ExtCtrls, ComCtrls, DBCtrls, DBGrids, citk.DataObject,
  citk.global;

type

  TSetDataGridColumnsProc = procedure(DataGrid: TDBGrid) of object;

  { TDataGridForm }

  TDataGridForm = class(TForm)
    DataSource: TDataSource;
    DataStatusBar: TStatusBar;
    DataNavPanel: TPanel;
    DataGrid: TDBGrid;
    DataNav: TDBNavigator;
    TopPanel: TPanel;
    BottomPanel: TPanel;
    WorkingSpacePanel: TPanel;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
  private
    FDataObject: IDataObject;
    FInfo: TInfo;
    FOnSetDataGridColumns: TSetDataGridColumnsProc;
    FQuery: TSQLQuery;
    procedure SetInfo(AValue: TInfo);
    procedure SetOnSetDataGridColumns(AValue: TSetDataGridColumnsProc);
    procedure SetQuery(AValue: TSQLQuery);
  protected
    procedure SaveContent; virtual;
  public
    constructor Create(AOwner: TComponent; DataObject: IDataObject); reintroduce; overload;
    constructor Create(AOwner: TComponent; Info: TInfo); reintroduce; overload;
    property DataObject: IDataObject read FDataObject;
    property Query: TSQLQuery read FQuery write SetQuery;
    property OnSetDataGridColumns: TSetDataGridColumnsProc read FOnSetDataGridColumns write SetOnSetDataGridColumns;
    property Info: TInfo read FInfo write SetInfo;
  end;

  { TSetDataGridColumnsHelper }

  TSetDataGridColumnsHelper = class
  public
    procedure SetOnSetDataGridColumns(ADBGrid: TDBGrid); virtual;
  end;

var
  DataGridForm: TDataGridForm;

implementation

{$R *.lfm}

{ TSetDataGridColumnsHelper }

procedure TSetDataGridColumnsHelper.SetOnSetDataGridColumns(
  ADBGrid: TDBGrid);
begin

end;

{ TDataGridForm }

constructor TDataGridForm.Create(AOwner: TComponent; DataObject: IDataObject);
begin
  if FDataObject<>DataObject then;
    FDataObject:=DataObject;
  inherited Create(AOwner);
end;

constructor TDataGridForm.Create(AOwner: TComponent; Info: TInfo);
begin
  FDataObject := TFirebirdDataObject.Create(Info.Cnx, Info.Transaction);
  FInfo := Info;
  Create(AOwner, FDataObject);
end;

procedure TDataGridForm.FormClose(Sender: TObject; var CloseAction: TCloseAction
  );
begin
  SaveContent;
end;

procedure TDataGridForm.FormShow(Sender: TObject);
begin
  if Assigned(FOnSetDataGridColumns) then
    FOnSetDataGridColumns(DataGrid);
end;

procedure TDataGridForm.SaveContent;
begin
  try
    if DataObject.Transaction.Active then
    begin
      if Assigned(Query) then
        Query.ApplyUpdates;
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

procedure TDataGridForm.SetQuery(AValue: TSQLQuery);
begin
  if FQuery=AValue then Exit;
  FQuery:=AValue;
  DataSource.DataSet := FQuery;
end;

procedure TDataGridForm.SetOnSetDataGridColumns(AValue: TSetDataGridColumnsProc
  );
begin
  if FOnSetDataGridColumns=AValue then Exit;
  FOnSetDataGridColumns:=AValue;
end;

procedure TDataGridForm.SetInfo(AValue: TInfo);
begin
  if FInfo=AValue then Exit;
  FInfo:=AValue;
end;

end.

