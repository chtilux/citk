unit citk.EventsWindow;
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
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, citk.DataGridForm,
  DBGrids, DB, DBCtrls, ExtCtrls, ComCtrls, Buttons, ActnList, Menus,
  citk.eventdetailWindow;

type

  { TEventsColumns }

  TEventsColumns = class(TSetDataGridColumnsHelper)
  public
    procedure SetOnSetDataGridColumns(ADBGrid: TDBGrid); override;
  end;

  { TEventsW }

  TEventsW = class(TDataGridForm)
    BillingAction: TAction;
    EditSelectionAction: TAction;
    ActionList1: TActionList;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    DetailPanel: TPanel;
    DetailView: TListView;
    MenuItem1: TMenuItem;
    PopupMenu1: TPopupMenu;
    procedure ActionList1Update(AAction: TBasicAction; var Handled: Boolean);
    procedure BillingActionExecute(Sender: TObject);
    procedure DataGridKeyPress(Sender: TObject; var Key: char);
    procedure DataNavClick(Sender: TObject; Button: TDBNavButtonType);
    procedure DataSourceDataChange(Sender: TObject; Field: TField);
    procedure EditSelectionActionExecute(Sender: TObject);
  private
    procedure Billing(const serevt: integer);
    procedure DisplayDetail(const serevt: integer);
    procedure EditDetail(const serevt: integer);
    procedure SaveDetail(W: TEventDetailW);
    function GetPrimaryKey: integer;
  public
    procedure QueryNewRecord(DataSet: TDataSet);
    procedure QueryBeforePost(DataSet: TDataSet);
    procedure QueryAfterPost(Dataset: TDataset);
  end;

  procedure DisplayEvents;

implementation

uses
  citk.Events, citk.Global, SQLDB, DateUtils, citk.BillingWindow;

procedure DisplayEvents;
var
  F: TEventsW;
  Q: TSQLQuery;
  evt: IEvents;
  dgh: TSetDataGridColumnsHelper;
begin
  F := TEventsW.Create(nil, glGlobalInfo);
  try
    Q := TSQLQuery.Create(F);
    Q.SQLConnection:=F.DataObject.Connector;
    Q.Transaction:=F.DataObject.Transaction;
    evt := TEvents.Create;
    Q.SQL.Add(evt.GetSQL);
    ////Q.Params[0].AsString := '%';
    Q.OnNewRecord:=@F.QueryNewRecord;
    Q.BeforePost:=@F.QueryBeforePost;
    Q.AfterPost:=@F.QueryAfterPost;
    dgh := TEventsColumns.Create;
    F.OnSetDataGridColumns:=@dgh.SetOnSetDataGridColumns;
    F.Query := Q;
    Q.Open;
    TDateTimeField(Q.FieldByName('begevt')).DisplayFormat:='ddd dd/mm/yy';
    TDateTimeField(Q.FieldByName('begevt')).EditMask:='99/99/99;_;1';
    TDateTimeField(Q.FieldByName('endevt')).DisplayFormat:='ddd dd/mm/yy';
    TDateTimeField(Q.FieldByName('endevt')).EditMask:='99/99/99;_;1';
    F.ShowModal;
  finally
    F.Free;
    dgh.Free;
  end;
end;

{$R *.lfm}

{ TEventsW }

procedure TEventsW.DataGridKeyPress(Sender: TObject; var Key: char);
begin
  Key:=UpCase(Key);
end;

procedure TEventsW.BillingActionExecute(Sender: TObject);
begin
  Billing(Query.FieldByName('serevt').AsInteger);
end;

procedure TEventsW.ActionList1Update(AAction: TBasicAction; var Handled: Boolean
  );
begin
  EditSelectionAction.Enabled := not Query.Eof;
  BillingAction.Enabled:=Query.Eof or (DetailView.Items.Count > 0);
end;

procedure TEventsW.Billing(const serevt: integer);
begin
  citk.BillingWindow.Billing(Info, serevt);
end;

procedure TEventsW.DataNavClick(Sender: TObject; Button: TDBNavButtonType);
begin
  if Button = nbInsert then
  begin
    DataGrid.SetFocus;
    DataGrid.SelectedField := Query.FieldByName('begevt');
  end;
end;

procedure TEventsW.DataSourceDataChange(Sender: TObject; Field: TField);
begin
  if Field = nil then
  begin
    DisplayDetail(Query.FieldByName('serevt').AsInteger);
  end;
end;

procedure TEventsW.DisplayDetail(const serevt: integer);
  procedure ToListView(lv: TListView; AData: TDataset);
  begin
    lv.Items.BeginUpdate;
    try
      lv.Items.Clear;
      AData.First;
      while not AData.Eof do
      begin
        with lv.Items.Add do
        begin
          Caption := AData.FieldByName('libprd').AsString;
          SubItems.Add(AData.FieldByName('price').AsString);
        end;
        AData.Next;
      end;
    finally
      lv.Items.EndUpdate;
    end;
  end;

var
  Q: TSQLQuery;
  evt: IEvents;
begin
  Q := TSQLQuery.Create(nil);
  try
    Q.SQLConnection:=DataObject.Connector;
    Q.Transaction:=DataObject.Transaction;
    evt := TEvents.Create;
    Q.SQL.Add(evt.GetDetailSQL);
    Q.ParamByName('serevt').AsInteger:=serevt;
    Q.Open;
    ToListView(DetailView, Q);
  finally
    Q.Free;
  end;
end;

function TEventsW.GetPrimaryKey: integer;
var
  evt: IEvents;
begin
  with TSQLQuery.Create(nil) do
  begin
    try
      SQLConnection:=Self.DataObject.Connector;
      Transaction:=Self.DataObject.Transaction;
      evt := TEvents.Create;
      SQL.Add(evt.GetPKSQL);
      Open;
      Result:=Fields[0].AsInteger;
      Close;
    finally
      Free;
    end;
  end;
end;

procedure TEventsW.QueryNewRecord(DataSet: TDataSet);
begin
  Dataset.FieldByName('begevt').AsDateTime:=Today;
  Dataset.FieldByName('endevt').asDateTime:=IncWeek(Today);
  Dataset.FieldByName('active').AsBoolean:=True;
  Info.Log('Inserting new product');
end;

procedure TEventsW.QueryBeforePost(DataSet: TDataSet);
begin
  { primary key }
  if (Dataset.State = dsInsert) and (Dataset.FieldByName('serevt').IsNull) then
    Dataset.FieldByName('serevt').AsInteger:=GetPrimaryKey;
end;

procedure TEventsW.QueryAfterPost(Dataset: TDataset);
begin
  Query.ApplyUpdates;
  DataObject.Transaction.CommitRetaining;
  Query.Refresh;
end;

{ TEventsColumns }

procedure TEventsColumns.SetOnSetDataGridColumns(ADBGrid: TDBGrid);
begin
  inherited SetOnSetDataGridColumns(ADBGrid);
  with ADBGrid.Columns.Add do
  begin
    FieldName:='serevt';
    Width := 60;
    Alignment:=taCenter;
    Visible:=True;
    ReadOnly := True;
    Title.Caption:='ID';
  end;
  with ADBGrid.Columns.Add do
  begin
    FieldName:='begevt';
    Width := 120;
    Title.Caption:='Event start';
  end;
  with ADBGrid.Columns.Add do
  begin
    FieldName:='endevt';
    Width := 120;
    Title.Caption:='Event end';
  end;
  with ADBGrid.Columns.Add do
  begin
    FieldName:='libevt';
    Width := 200;
    Title.Caption:='Event description';
  end;
  with ADBGrid.Columns.Add do
  begin
    FieldName:='active';
    Width := 80;
    Title.Caption:='Active';
  end;
end;

procedure TEventsW.EditSelectionActionExecute(Sender: TObject);
begin
  EditDetail(Query.FieldByName('serevt').AsInteger);
end;

procedure TEventsW.EditDetail(const serevt: integer);
var
  F: TEventDetailW;
begin
  F := TEventDetailW.Create(nil, Info);
  try
    F.Event := serevt;
    if F.ShowModal = mrOk then
      SaveDetail(F);
  finally
    F.Free;
  end;
end;

procedure TEventsW.SaveDetail(W: TEventDetailW);
var
  lv: TListView;
  x,z: TSQLQuery;
  i: integer;
  itm: TListItem;
  evt: IEvents;
begin
  z := DataObject.GetQuery;
  try
    lv := W.SelectionView;
    z.SQL.Add('DELETE FROM event_detail WHERE serevt = :serevt');
    z.Params[0].AsInteger:=W.Event;
    z.ExecSQL;
    if lv.Items.Count > 0 then
    begin
      z.SQL.Clear;
      z.SQL.Add('UPDATE OR INSERT INTO event_detail'
               +' (serdet,serevt,numseq,serprd,libprd,price)'
               +' VALUES (:serdet,:serevt,:numseq,:serprd,:libprd,:price)');
      z.ParamByName('serevt').AsInteger:=W.Event;
      x := DataObject.GetQuery;
      try
        evt := TEvents.Create;
        x.SQL.Add(evt.GetPKSQL);
        for i := 0 to lv.Items.Count-1 do
        begin
          itm := lv.Items[i];
          if not Assigned(itm.Data) then
          begin
            x.Open;
            z.ParamByName('serdet').AsInteger:=x.Fields[0].AsInteger;
            x.Close;
          end
          else
            z.ParamByName('serdet').AsInteger:=integer(itm.Data);

          z.ParamByName('numseq').AsInteger:=Succ(i);
          z.ParamByName('serprd').AsString:=itm.SubItems[1];
          z.ParamByName('libprd').AsString:=itm.Caption;
          z.ParamByName('price').AsString:=itm.SubItems[0];
          z.ExecSQL;;
        end;
      finally
        x.Free;
      end;
    end;
    DataObject.Transaction.CommitRetaining;
    DisplayDetail(W.Event);
  finally
    z.Free;
  end;
end;

end.

