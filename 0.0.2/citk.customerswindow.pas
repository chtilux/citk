unit citk.customersWindow;
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
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls,
  citk.DataGridForm, SQLDB, DB, DBGrids, DBCtrls;

type

  { TCustomersColumns }

  TCustomersColumns = class(TSetDataGridColumnsHelper)
  public
    procedure SetOnSetDataGridColumns(ADBGrid: TDBGrid); override;
  end;

{ TCustomersW }

  TCustomersW = class(TDataGridForm)
    CustomersTab: TTabControl;
    SearchEdit: TEdit;
    Label1: TLabel;
    procedure CustomersTabChange(Sender: TObject);
    procedure DataGridKeyPress(Sender: TObject; var Key: char);
    procedure DataNavClick(Sender: TObject; Button: TDBNavButtonType);
    procedure FormCreate(Sender: TObject);
    procedure SearchEditChange(Sender: TObject);
  private
    function GetPrimaryKey: integer;
  public
    procedure QueryBeforePost(DataSet: TDataSet);
    procedure QueryAfterPost(Dataset: TDataset);
  end;

  procedure DisplayCustomers;

implementation

{$R *.lfm}

uses
  citk.customers, citk.Global;

procedure DisplayCustomers;
var
  F: TCustomersW;
  Q: TSQLQuery;
  cust: ICustomers;
  dgh: TSetDataGridColumnsHelper;
begin
  F := TCustomersW.Create(nil, glGlobalInfo);
  try
    Q := TSQLQuery.Create(F);
    Q.SQLConnection:=F.DataObject.Connector;
    Q.Transaction:=F.DataObject.Transaction;
    cust := TCustomers.Create;
    Q.SQL.Add(cust.GetSQL);
    Q.Params[0].AsString := '%';
    Q.BeforePost:=@F.QueryBeforePost;
    Q.AfterPost:=@F.QueryAfterPost;
    dgh := TCustomersColumns.Create;
    F.OnSetDataGridColumns:=@dgh.SetOnSetDataGridColumns;
    F.Query := Q;
    Q.Open;
    F.ShowModal;
  finally
    F.Free;
    dgh.Free;
  end;
end;

{ TCustomersColumns }

procedure TCustomersColumns.SetOnSetDataGridColumns(ADBGrid: TDBGrid);
begin
  inherited SetOnSetDataGridColumns(ADBGrid);
  with ADBGrid.Columns.Add do
  begin
    FieldName:='sercust';
    Width := 80;
    Alignment:=taCenter;
    Visible:=True;
    ReadOnly := True;
    Title.Caption:='ID';
  end;
  with ADBGrid.Columns.Add do
  begin
    FieldName:='custname';
    Width := 250;
    Title.Caption:='Customer Name';
  end;
end;

{ TCustomersW }

procedure TCustomersW.FormCreate(Sender: TObject);
var
  a: Char;
begin
  CustomersTab.Tabs.BeginUpdate;
  for a := 'A' to 'Z' do
    CustomersTab.Tabs.Add(string(a));
  CustomersTab.Tabs.Insert(0,'ALL');
  CustomersTab.Tabs.EndUpdate;
end;

procedure TCustomersW.SearchEditChange(Sender: TObject);
begin
  CustomersTab.TabIndex := 0;
  CustomersTabChange(CustomersTab);
  Query.DisableControls;
  try
    Query.Close;
    Query.Params[0].AsString := Query.Params[0].AsString + TEdit(Sender).Text + '%';
  finally
    Query.Open;
    Query.EnableControls;
  end;
end;

procedure TCustomersW.QueryBeforePost(DataSet: TDataSet);
begin
  { primary key }
  if (Dataset.State = dsInsert) and (Dataset.FieldByName('sercust').IsNull) then
    Dataset.FieldByName('sercust').AsInteger:=GetPrimaryKey;
end;

procedure TCustomersW.QueryAfterPost(Dataset: TDataset);
begin
  Query.ApplyUpdates;
  DataObject.Transaction.CommitRetaining;
  Info.Log('Customer ' + Dataset.FieldByname('custname').AsString + ' : Post.');
  Query.Refresh;
end;

function TCustomersW.GetPrimaryKey: integer;
var
  cust: ICustomers;
begin
  with TSQLQuery.Create(nil) do
  begin
    try
      SQLConnection:=Self.DataObject.Connector;
      Transaction:=Self.DataObject.Transaction;
      cust := TCustomers.Create;
      SQL.Add(cust.GetPKSQL);
      Open;
      Result:=Fields[0].AsInteger;
      Close;
    finally
      Free;
    end;
  end;
end;

procedure TCustomersW.CustomersTabChange(Sender: TObject);
begin
  Query.DisableControls;
  try
    Query.Close;
    Query.Params[0].AsString := '%';
    if TTabControl(Sender).TabIndex > 0 then
      Query.Params[0].AsString := Query.Params[0].AsString +
                                  TTabControl(Sender).Tabs[TTabControl(Sender).TabIndex] +
                                  '%';
  finally
    Query.Open;
    Query.EnableControls;
  end;
end;

procedure TCustomersW.DataGridKeyPress(Sender: TObject; var Key: char);
begin
  Key := UpCase(Key);
end;

procedure TCustomersW.DataNavClick(Sender: TObject; Button: TDBNavButtonType);
begin
  if Button = nbInsert then
  begin
    DataGrid.SetFocus;
    DataGrid.SelectedField := Query.FieldByName('custname');
  end;
end;

end.

