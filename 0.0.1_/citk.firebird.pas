unit citk.firebird;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, ZConnection, Chtilux.Logger;

type
  EFirebird = class(Exception);
  EFirebirdConstraint = class(EFirebird);

procedure SetConnection(Connection: TZConnection);
procedure SetLogger(ALogger: ILogger);
procedure FBCreateDomain(const Domain, DataType, Decorate: string);
procedure FBCreateTableColumn(const TableName, Column, DataType, Decorate: string);
procedure FBRecreateTableColumn(const TableName, Column, DataType, Decorate: string);
procedure FBCreateIndex(const PreDecorate, IndexName, TableName, Columns: string);
procedure SQLDirect(const sql: string);
function SelectSQLDirect(const sql: string): TStrings;
procedure FBAddConstraint(const TableName, Constraint, Name, Columns: string);

function FBTableExists(const TableName: string): boolean;
function FBTableColumnExists(const TableName, Column: string): boolean;
function FBDomainExists(const Domain: string): boolean;
function FBConstraintExists(const Name: string; out relation_name: string): boolean;
function FBTableIndexExists(const Name, TableName: string): boolean;

implementation

uses
  Contnrs, ZDataset;

var
  Cnx: TZConnection;
  Objects: TFPObjectList;
  TableExists,
  TableColumnExists,
  DomainExists,
  ConstraintExists,
  TableIndexExists: TZReadOnlyQuery;
  Logger: ILogger;

procedure SetConnection(Connection: TZConnection);
begin
  Cnx := Connection;

  TableExists.Connection := Cnx;
  if TableExists.Prepared then
    TableExists.Unprepare;

  TableColumnExists.Connection := Cnx;
  if TableColumnExists.Prepared then
    TableColumnExists.Unprepare;

  DomainExists.Connection := Cnx;
  if DomainExists.Prepared then
    DomainExists.Unprepare;

  ConstraintExists.Connection := Cnx;
  if ConstraintExists.Prepared then
    ConstraintExists.Unprepare;

  TableIndexExists.Connection := Cnx;
  if TableIndexExists.Prepared then
    TableIndexExists.Unprepare;
end;

procedure SetLogger(ALogger: ILogger);
begin
  Logger := ALogger;
end;

procedure Log(const Texte: string);
begin
  if Assigned(Logger) then
    Logger.Log('citk.firebird', Texte);
end;

procedure CheckFBConnection;
begin
  Assert(Assigned(Cnx), 'Cnx is nil');
end;

function GetCursor: TZReadOnlyQuery;
begin
  Result := TZReadOnlyQuery.Create(nil);
  Result.Connection := Cnx;
  Objects.Add(Result);
end;

procedure SQLDirect(const sql: string);
var
  z: TZReadOnlyQuery;
begin
  z := GetCursor;
  try
    z.SQL.Add(sql);
    z.ExecSQL;
    Log(sql);
  finally
    Objects.Remove(z);
  end;
end;

function SelectSQLDirect(const sql: string): TStrings;
var
  z: TZReadOnlyQuery;
  i: integer;
begin
  Result := TStringList.Create;
  z := GetCursor;
  try
    z.SQL.Add(sql);
    z.Open;
    if not z.Eof then
    begin
      for i := 0 to z.FieldCount-1 do
        Result.Values[z.Fields[i].FieldName] := z.Fields[i].AsString;
    end;
    z.Close;
  finally
    Objects.Remove(z);
  end;
end;

procedure FBCreateDomain(const Domain, DataType, Decorate: string);
var
  z: TZReadOnlyQuery;
begin
  CheckFBConnection;
  z := GetCursor;
  try
    if not FBDomainExists(Domain) then
    begin
      z.SQL.Add(Format('CREATE DOMAIN %s %s %s',[Domain, DataType, Decorate]));
      z.ExecSQL;
      Log(Format('Domain %s created.',[Domain]));
    end;
  finally
    Objects.Remove(z);
  end;
end;

procedure FBCreateTableColumn(const TableName, Column, DataType, Decorate: string);
var
  z: TZReadOnlyQuery;
  sql: string;
begin
  CheckFBConnection;
  z := GetCursor;
  try
    sql := '';
    if FBTableExists(TableName) then
    begin
      if not FBTableColumnExists(TableName, Column) then
        sql := Format('ALTER TABLE %s ADD %s %s %s', [TableName, Column, DataType, decorate]);
    end
    else
      sql := Format('CREATE TABLE %s (%s %s %s)', [TableName, Column, DataType, decorate]);

    if not sql.IsEmpty then
    begin
      z.SQL.Add(sql);
      z.ExecSQL;
      Log(sql);
    end;

  finally
    Objects.Remove(z);
  end;
end;

function FBTableExists(const TableName: string): boolean;
begin
  CheckFBConnection;
  if not TableExists.Prepared then
    TableExists.Prepare;
  TableExists.Params[0].AsString:=TableName.ToUpper;
  TableExists.Open;
  try
    Result := TableExists.Fields[0].AsString = '1';
  finally
    TableExists.Close;
  end;
end;

function FBTableColumnExists(const TableName, Column: string): boolean;
begin
  CheckFBConnection;
  if not TableColumnExists.Prepared then
    TableColumnExists.Prepare;
  TableColumnExists.Params[0].AsString:=TableName.ToUpper;
  TableColumnExists.Params[1].AsString:=Column.ToUpper;
  TableColumnExists.Open;
  try
    Result := TableColumnExists.Fields[0].AsString = '1';
  finally
    TableColumnExists.Close;
  end;
end;

procedure FBRecreateTableColumn(const TableName, Column, DataType, Decorate: string);
begin
  CheckFBConnection;
  if FBTableColumnExists(TableName, Column) then
    SQLDirect(Format('ALTER TABLE %s DROP %s', [TableName, Column]));
  FBCreateTableColumn(TableName, Column, DataType, Decorate);
end;

procedure FBCreateIndex(const PreDecorate, IndexName, TableName, Columns: string);
begin
  CheckFBConnection;
  { #todo : Check index exists }
  if not FBTableIndexExists(IndexName, TableName) then
    SQLDirect(Format('CREATE %s INDEX %s ON %s (%s)',[PreDecorate, IndexName, TableName, Columns]));
end;

procedure FBAddConstraint(const TableName, Constraint, Name, Columns: string);
var
  relation_name: string;
begin
  if not FBConstraintExists(Constraint, relation_name) then
    SQLDirect(Format('ALTER TABLE %s ADD CONSTRAINT %s %s %s',[TableName, Constraint, Name, Columns]))
end;

function FBDomainExists(const Domain: string): boolean;
begin
  CheckFBConnection;
  if not DomainExists.Prepared then
    DomainExists.Prepare;
  DomainExists.Params[0].AsString:=Domain.ToUpper;
  DomainExists.Open;
  try
    Result := DomainExists.Fields[0].AsString = '1';
  finally
    DomainExists.Close;
  end;
end;

function FBConstraintExists(const Name: string; out relation_name: string): boolean;
begin
  relation_name:='';
  CheckFBConnection;
  if not ConstraintExists.Prepared then
    ConstraintExists.Prepare;
  ConstraintExists.Params[0].AsString:=Name.ToUpper;
  ConstraintExists.Open;
  try
    Result := not ConstraintExists.EOF;
    if not Result then
      relation_name:=ConstraintExists.Fields[0].AsString;
  finally
    ConstraintExists.Close;
  end;
end;

function FBTableIndexExists(const Name, TableName: string): boolean;
begin
  TableIndexExists.ParamByName('IndexName').AsString:=Name.ToUpper;
  TableIndexExists.ParamByName('TableName').AsString:=TableName.ToUpper;
  TableIndexExists.Open;
  try
    Result := TableIndexExists.Fields[0].AsString = '1';
  finally
    TableIndexExists.Close;
  end;
end;

initialization
  Cnx := nil;
  Objects := TFPObjectList.Create(True);

  TableExists := GetCursor;
  TableExists.SQL.Add('SELECT 1 FROM rdb$relations WHERE UPPER(rdb$relation_name) = :TableName');

  TableColumnExists := GetCursor;
  TableColumnExists.SQL.Add('SELECT 1 from rdb$relation_fields'
                           +' WHERE UPPER(rdb$relation_name) = :TableName'
                           +'   AND UPPER(rdb$field_name) = :Column');

  DomainExists := GetCursor;
  DomainExists.SQL.Add('SELECT 1 FROM rdb$fields'
                      +' WHERE UPPER(rdb$field_name) = :domain'
                      +'   AND rdb$system_flag = 0');

  ConstraintExists := getCursor;
  ConstraintExists.SQL.Add('SELECT UPPER(rdb$relation_name)'
                          +' FROM rdb$indices'
                          +' WHERE UPPER(rdb$index_name) = :Name'
                          +'   AND rdb$system_flag = 0'
                          +'   AND rdb$index_type IS NULL');

  TableIndexExists := getCursor;
  TableIndexExists.SQL.Add('SELECT 1 FROM rdb$indices'
                          +' WHERE UPPER(rdb$relation_name) = :TableName'
                          +'   AND UPPER(rdb$index_name) = :IndexName'
                          +'   AND rdb$system_flag = 0'
                          +'   AND rdb$index_type = 0');
finalization
  Objects.Free;

end.
