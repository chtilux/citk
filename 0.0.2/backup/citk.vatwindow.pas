unit citk.VATWindow;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, DB, Forms, Controls, Graphics, Dialogs, ExtCtrls, DBGrids,
  citk.DataGridForm, SQLDB, DBCtrls, Buttons;

type

  { TVATW }

  TVATW = class(TDataGridForm)
    DataGrid1: TDBGrid;
    DataNav1: TDBNavigator;
    DataNavPanel1: TPanel;
    RateSource: TDataSource;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FRate: TSQLQuery;
    procedure RateNewRecord(Dataset: TDataset);
    procedure RateAfterPost(Dataset: TDataset);
  public
    property Rate: TSQLQuery read FRate;
  end;

implementation

{$R *.lfm}

uses
  citk.vat, DateUtils;

{ TVATW }

procedure TVATW.FormCreate(Sender: TObject);
var
  tva: IVAT;
begin
  FRate := DataObject.GetQuery;
  tva := TVAT.Create;
  FRate.SQL.Add(tva.GetRateSQL);
  FRate.DataSource:=DataSource;
  FRate.OnNewRecord := @RateNewRecord;
  FRate.AfterPost := @RateAfterPost;
  FRate.AfterDelete := @RateAfterPost;
  RateSource.DataSet:=FRate;
  FRate.Open;
end;

procedure TVATW.FormDestroy(Sender: TObject);
begin
  FRate.Free;
end;

procedure TVATW.RateNewRecord(Dataset: TDataset);
begin
  Dataset.FieldByName('codtva').AsString := Query.FieldByName('codtva').AsString;
  Dataset.FieldByName('dateff').AsDateTime := Today;
end;

procedure TVATW.RateAfterPost(Dataset: TDataset);
begin
  DataObject.Transaction.CommitRetaining;
end;

end.

