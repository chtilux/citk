unit citk.DataGridForm;
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

