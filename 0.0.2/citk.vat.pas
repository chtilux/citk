unit citk.vat;
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
  Classes, SysUtils;

type

  { IVAT }

  IVAT = Interface
  ['{B0A5A0DA-3327-447A-8E87-9054D0F35ED3}']
    function GetSQL: string;
    function GetRateSQL: string;
  end;

  { TVAT }

  TVAT = class(TInterfacedObject, IVAT)
  public
    function GetSQL: string;
    function GetRateSQL: string;
  end;

  procedure DisplayVAT;

implementation

uses
  citk.DataGridForm, citk.DataObject, SQLDB, citk.global, DBGrids,
  citk.VATWindow;

type

  { TVATColumns }

  TVATColumns = class(TSetDataGridColumnsHelper)
  public
    procedure SetOnSetDataGridColumns(ADBGrid: TDBGrid); override;
  end;

procedure DisplayVAT;
var
  F: TDataGridForm;
  dao: IDataObject;
  Q: TSQLQuery;
  dbgh: TSetDataGridColumnsHelper;
  vat: IVAT;
begin
  dao := TFirebirdDataObject.Create(glCnx,glTrx);
  Q := TSQLQuery.Create(nil);     dbgh := nil;
  try
    Q.SQLConnection:=glCnx;
    Q.Transaction:=glTrx;
    vat := TVAT.Create;
    Q.SQL.Add(vat.GetSQL);
    dbgh := TVATColumns.Create;
    F := TVATW.Create(nil, dao);
    try
      F.Query := Q;
      F.Query.Open;
      F.OnSetDataGridColumns:=@dbgh.SetOnSetDataGridColumns;
      F.ShowModal;
    finally
      F.Free;
    end;
  finally
    Q.Free;
    dbgh.Free;
  end;
end;

function TVAT.GetSQL: string;
begin
  Result := 'SELECT codtva, libtva FROM tva ORDER BY 1';
end;

function TVAT.GetRateSQL: string;
begin
  Result := 'SELECT codtva,dateff,rate FROM tautva'
           +' WHERE codtva = :codtva'
           +' ORDER BY dateff DESC';
end;

{ TVATColumns }

procedure TVATColumns.SetOnSetDataGridColumns(ADBGrid: TDBGrid);
begin
  inherited SetOnSetDataGridColumns(ADBGrid);
  with ADBGrid.Columns.Add do
  begin
    FieldName:='codtva';
    Width := 150;
  end;
  with ADBGrid.Columns.Add do
  begin
    FieldName:='libtva';
    Width := 250;
  end;
end;

end.

