unit citk.DataGridForm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, DB, SQLDB, IBConnection, Forms, Controls, Graphics,
  Dialogs, ExtCtrls, ComCtrls, DBCtrls, DBGrids, citk.DataObject;

type

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
  private
    FDataObject: IDataObject;
  public
    constructor Create(AOwner: TComponent; DataObject: IDataObject); reintroduce; overload;
    property DataObject: IDataObject read FDataObject;
  end;

var
  DataGridForm: TDataGridForm;

implementation

{$R *.lfm}

{ TDataGridForm }

constructor TDataGridForm.Create(AOwner: TComponent; DataObject: IDataObject);
begin
  FDataObject:=DataObject;
  inherited Create(AOwner);
end;

end.

