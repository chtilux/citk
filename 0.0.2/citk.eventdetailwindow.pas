unit citk.eventdetailWindow;
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
  ComCtrls, Buttons, ActnList, citk.global, citk.DataObject, SQLDB;

type

  { TEventDetailW }

  TEventDetailW = class(TForm)
    BitBtn3: TBitBtn;
    RemoveFromSelectionAction: TAction;
    AddToSelectionAction: TAction;
    ActionList1: TActionList;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Label1: TLabel;
    Label2: TLabel;
    ProductsView: TListView;
    SelectionView: TListView;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    procedure ActionList1Update(AAction: TBasicAction; var Handled: Boolean);
    procedure AddToSelectionActionExecute(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure RemoveFromSelectionActionExecute(Sender: TObject);
    procedure SelectionViewDblClick(Sender: TObject);
  private
    FDataObject: IDataObject;
    FEvent: integer;
    FEventStartDate: TDateTime;
    FInfo: TInfo;
    FQuery: TSQLQuery;
    procedure DisplaySelection;
    procedure SetEvent(AValue: integer);
    procedure SetEventStartDate(AValue: TDateTime);
    procedure SetInfo(AValue: TInfo);
    procedure SetQuery(AValue: TSQLQuery);

  public
    constructor Create(AOwner: TComponent; DataObject: IDataObject); reintroduce; overload;
    constructor Create(AOwner: TComponent; Info: TInfo); reintroduce; overload;
    property DataObject: IDataObject read FDataObject;
    property Query: TSQLQuery read FQuery write SetQuery;
    property Info: TInfo read FInfo write SetInfo;
    property Event: integer read FEvent write SetEvent;
    property EventStartDate: TDateTime read FEventStartDate write SetEventStartDate;
  end;

implementation

{$R *.lfm}

uses
  citk.Events, citk.EventDetail, DB;

{ TEventDetailW }

procedure TEventDetailW.SetInfo(AValue: TInfo);
begin
  if FInfo=AValue then Exit;
  FInfo:=AValue;
end;

procedure TEventDetailW.FormShow(Sender: TObject);
var
  evt: IEvents;
begin
  with TSQLQuery.Create(nil) do
  begin
    try
      SQLConnection:=DataObject.Connector;
      Transaction:=DataObject.Transaction;
      evt := TEvents.Create;
      SQL.Add(evt.GetEventSQL);
      ParamByName('serevt').AsInteger:=Self.Event;
      Open;
      Caption := Format('%s from %s to %s [%d]',[FieldByName('libevt').AsString,
                                                 FieldByName('begevt').AsString,
                                                 FieldByName('endevt').AsString,
                                                 Event]);
      EventStartDate:=FieldByName('begevt').AsDateTime;
    finally
      Free;
    end;
  end;
  DisplaySelection;
end;

procedure TEventDetailW.RemoveFromSelectionActionExecute(Sender: TObject);
var
  itm: TListItem;
begin
  itm := SelectionView.Selected;
  with ProductsView.Items.Add do
  begin
    Caption := itm.Caption;
    SubItems.Add(itm.SubItems[0]);
    SubItems.Add(itm.SubItems[1]);
  end;
  SelectionView.Items.Delete(itm.Index);
end;

procedure TEventDetailW.SelectionViewDblClick(Sender: TObject);
var
  itm: TListItem;
  price: Currency;
  ret: string;
begin
  itm := SelectionView.Selected;
  ret := InputBox('Product', 'type product''s price', itm.SubItems[0]);
  if CompareText(ret, itm.SubItems[0]) <> 0 then
  begin
    if TryStrToCurr(ret, price) then
      itm.SubItems[0] := ret
    else
      MessageDlg('Input price failed !', mtError, [mbOk], 0);
  end;
end;

procedure TEventDetailW.ActionList1Update(AAction: TBasicAction;
  var Handled: Boolean);
begin
  AddToSelectionAction.Enabled:=(ProductsView.Items.Count>0) and Assigned(ProductsView.Selected);
  RemoveFromSelectionAction.Enabled:=(SelectionView.Items.Count>0) and Assigned(SelectionView.Selected);
  Handled := True
end;

procedure TEventDetailW.AddToSelectionActionExecute(Sender: TObject);
var
  itm: TListItem;
begin
  itm := ProductsView.Selected;
  with SelectionView.Items.Add do
  begin
    Caption := itm.Caption;
    SubItems.Add(itm.SubItems[0]);
    SubItems.Add(itm.SubItems[1]);
  end;
  ProductsView.Items.Delete(itm.Index);
end;

procedure TEventDetailW.DisplaySelection;
  procedure ToListView(lv: TListView; AData: TDataset);
  begin
    lv.Items.BeginUpdate;
    try
      lv.Items.Clear;
      //AData.First;
      while not AData.Eof do
      begin
        with lv.Items.Add do
        begin
          if Assigned(AData.FindField('serdet')) then
            Data := pointer(AData.FieldByName('serdet').AsInteger);
          Caption := AData.FieldByName('libprd').AsString;
          SubItems.Add(AData.FieldByName('price').AsString);
          SubItems.Add(AData.FieldByName('serprd').AsString);
        end;
        AData.Next;
      end;
    finally
      lv.Items.EndUpdate;
    end;
  end;
var
  det: IEventDetail;
  sel: TSQLQuery;
begin
  det := TEventDetail.Create;
  sel:=DataObject.GetQuery;
  try
    sel.SQL.Add(det.GetSQL);
    sel.ParamByName('serevt').AsInteger:=Event;
    sel.Open;
    ToListView(SelectionView, sel);
    sel.Close;
    sel.SQL.Clear;
    sel.SQL.Add(det.GetNotSelectedProductsSQL);
    sel.ParamByName('serevt').AsInteger:=Event;
    sel.ParamByName('dateff').AsDateTime:=Self.EventStartDate;
    sel.Open;
    ToListView(ProductsView, sel);
    sel.Close;
  finally
    sel.Free;
  end;
end;

procedure TEventDetailW.SetEvent(AValue: integer);
begin
  if FEvent=AValue then Exit;
  FEvent:=AValue;
end;

procedure TEventDetailW.SetEventStartDate(AValue: TDateTime);
begin
  if FEventStartDate=AValue then Exit;
  FEventStartDate:=AValue;
end;

procedure TEventDetailW.SetQuery(AValue: TSQLQuery);
begin
  if FQuery=AValue then Exit;
  FQuery:=AValue;
end;

constructor TEventDetailW.Create(AOwner: TComponent; DataObject: IDataObject);
begin
  if FDataObject<>DataObject then;
    FDataObject:=DataObject;
  inherited Create(AOwner);
end;

constructor TEventDetailW.Create(AOwner: TComponent; Info: TInfo);
begin
  FDataObject := TFirebirdDataObject.Create(Info.Cnx, Info.Transaction);
  FInfo := Info;
  Create(AOwner, FDataObject);
end;

end.

