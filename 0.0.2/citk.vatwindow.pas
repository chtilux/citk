unit citk.VATWindow;
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
  TSQLQuery(Dataset).ApplyUpdates;
  DataObject.Transaction.CommitRetaining;
end;

end.

