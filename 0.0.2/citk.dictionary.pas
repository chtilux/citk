unit citk.dictionary;
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
  Classes, SysUtils, citk.DataObject;

type
{ IDictionary }

  IDictionary = interface
  ['{DEB022DB-0701-42AC-A626-CBD3C002F47D}']
    function GetSQL: string;
    function GetPasswordChar: string;
    function GetDefaultSalesVatCode: string;
    function GetDefaultCustomerID: integer;
    function GetPaymentMethod: TStrings;
    function GetNextBillNumber: integer;
    function GetOutputDirectory: TFilename;
  end;

  { TDictionary }

  TDictionary = class(TInterfacedObject, IDictionary)
  private
    FDataObject: IDataObject;
  public
    constructor Create(DataObject: IDataObject); virtual; overload;
    constructor Create; overload;
    function GetSQL: string;
    function GetPasswordChar: string;
    function GetDefaultSalesVatCode: string;
    function GetDefaultCustomerID: integer;
    function GetPaymentMethod: TStrings;
    function GetNextBillNumber: integer;
    function GetOutputDirectory: TFilename;
  end;

  procedure DisplayDictionary;

implementation

uses
  citk.DataGridForm, SQLDB, citk.global, DBGrids, citk.persistence, DateUtils;

type
  { TDictionaryColumns }

  TDictionaryColumns = class(TSetDataGridColumnsHelper)
  public
    procedure SetOnSetDataGridColumns(ADBGrid: TDBGrid); override;
  end;

{ TDictionaryColumns }

procedure TDictionaryColumns.SetOnSetDataGridColumns(ADBGrid: TDBGrid);
var
  i: integer;
begin
  inherited SetOnSetDataGridColumns(ADBGrid);
  with ADBGrid.Columns.Add do
  begin
    FieldName:='cledic';
    Width := 150;
  end;
  with ADBGrid.Columns.Add do
  begin
    FieldName:='coddic';
    Width := 150;
  end;
  with ADBGrid.Columns.Add do
  begin
    FieldName:='libdic';
    Width := 250;
  end;
  for i := 1 to 9 do
    with ADBGrid.Columns.Add do
    begin
      FieldName:='pardc'+IntToStr(i);
      Width := 150;
    end;
end;

procedure DisplayDictionary;
var
  F: TDataGridForm;
  dao: IDataObject;
  Q: TSQLQuery;
  dbgh: TSetDataGridColumnsHelper;
  dic: IDictionary;
begin
  dao := TFirebirdDataObject.Create(glCnx,glTrx);
  Q := TSQLQuery.Create(nil);     dbgh := nil;
  try
    Q.SQLConnection:=glCnx;
    Q.Transaction:=glTrx;
    dic := TDictionary.Create;
    Q.SQL.Add(dic.GetSQL);
    Q.ReadOnly:=True;
    dbgh := TDictionaryColumns.Create;
    F := TDataGridForm.Create(nil, dao);
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

{ TDictionary }

constructor TDictionary.Create(DataObject: IDataObject);
begin
  FDataObject:=DataObject;
  Create;
end;

constructor TDictionary.Create;
begin

end;

function TDictionary.GetSQL: string;
begin
  Result := 'SELECT * FROM dictionnaire ORDER BY cledic, coddic';
end;

function TDictionary.GetPasswordChar: string;
begin
  Result := 'SELECT pardc1 as PasswordChar FROM dictionnaire'
           +' WHERE cledic = ' + 'security'.QuotedString
           +'   AND coddic = ' + 'password char'.QuotedString;
end;

function TDictionary.GetDefaultSalesVatCode: string;
begin
  Result := 'SELECT pardc1 AS DefaultVATCD'
           +' FROM dictionnaire'
           +' WHERE cledic = ' + 'sales'.QuotedString
           +'   AND coddic = ' + 'vatcode'.QuotedString;
end;

function TDictionary.GetDefaultCustomerID: integer;
begin
  Result := -1;
  with FDataObject.GetQuery do
  begin
    try
      SQL.Add('SELECT pardc1 FROM dictionnaire'
             +' WHERE cledic = ''sales'''
             +'   AND coddic = ''defaultCustomerID''');
      Open;
      if not Eof then
        Result := Fields[0].AsInteger;
    finally
      Free;
    end;
  end;
end;

function TDictionary.GetPaymentMethod: TStrings;
begin
  Result := TStringList.Create;
  with FDataObject.GetQuery do
  begin
    try
      SQL.Add('SELECT pardc1 FROM dictionnaire'
             +' WHERE cledic = ''sales'''
             +'   AND coddic = ''PaymentMethod''');
      Open;
      if not Eof then
        Result.CommaText := Fields[0].AsString;
    finally
      Free;
    end;
  end;
end;

function TDictionary.GetNextBillNumber: integer;
var
  yot: word;
begin
  Result := 0;
  yot := YearOf(Today);
  with FDataObject.GetQuery do
  begin
    try
      SQL.Add(Format('SELECT pardc1 FROM dictionnaire'
                    +' WHERE cledic = ''BillNumber'''
                    +'   AND coddic = ''%.4d''',[yot]));
      Open;
      if not Eof then
      begin
        Result := Fields[0].AsInteger;
        Close;
        SQL.Clear;
        SQL.Add(Format('UPDATE dictionnaire SET pardc1 = :NextBillNumber'
                      +' WHERE cledic = ''BillNumber'''
                      +'   AND coddic = ''%.4d''',[yot]));
        Params[0].AsInteger:=Succ(Result);
        ExecSQL;
        FDataObject.Transaction.CommitRetaining;
      end
      else
      begin
        { nouvel exercice }
        Close;
        SQL.Clear;
        SQL.Add(Format('INSERT INTO dictionnaire (cledic,coddic,libdic,pardc1) VALUES (''BillNumber'',''%.4d'',''Next bill number'',''1'')',[yot]));
        ExecSQL;
        FDataObject.Transaction.CommitRetaining;
        Result := GetNextBillNumber;
      end;
    finally
      Free;
    end;
  end;
end;

function TDictionary.GetOutputDirectory: TFilename;
begin
  with FDataObject.GetQuery do
  begin
    try
      SQL.Add('SELECT pardc1 FROM dictionnaire'
             +' WHERE cledic = ''output'''
             +'   AND coddic = ''directory''');
      Open;
      if not Eof then
        Result := Fields[0].AsString
      else
        Result := 'c:\temp';
      if not DirectoryExists(Result) then
         ForceDirectories(Result);
    finally
      Free;
    end;
  end;  end;

end.

