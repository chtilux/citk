unit citk.firebird;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, sqldb, Chtilux.Logger;

type
  EFirebird = class(Exception);
  EFirebirdConstraint = class(EFirebird);

procedure SetConnection(Connection: TSQLConnector; Transaction: TSQLTransaction);
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
function FBSequenceExists(const SequenceName: string): boolean;

implementation

var
  Cnx: TSQLConnector;
  Trx: TSQLTransaction;
  TableExists,
  TableColumnExists,
  DomainExists,
  ConstraintExists,
  TableIndexExists: TSQLQuery;
  Logger: ILogger;

procedure SetConnection(Connection: TSQLConnector; Transaction: TSQLTransaction);
begin
  Cnx := Connection;
  Trx := Transaction;
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
  Assert(Assigned(Trx), 'Trx is nil');
end;

procedure SQLDirect(const sql: string);
var
  z: TSQLQuery;
begin
  z := TSQLQuery.Create(nil);
  try
    z.SQLConnection:=Cnx;
    z.Transaction:=Trx;
    z.SQL.Add(sql);
    z.ExecSQL;
    Log(sql);
  finally
    z.Free;
  end;
end;

function SelectSQLDirect(const sql: string): TStrings;
var
  z: TSQLQuery;
  i: integer;
begin
  Result := TStringList.Create;
  z := TSQLQuery.Create(nil);
  try
    z.SQLConnection:=Cnx;
    z.Transaction:=Trx;
    z.SQL.Add(sql);
    z.Open;
    if not z.Eof then
    begin
      for i := 0 to z.FieldCount-1 do
        Result.Values[z.Fields[i].FieldName] := z.Fields[i].AsString;
    end;
    z.Close;
  finally
    z.Free;
  end;
end;

procedure FBCreateDomain(const Domain, DataType, Decorate: string);
var
  z: TSQLQuery;
begin
  CheckFBConnection;
  z := TSQLQuery.Create(nil);
  try
    z.SQLConnection:=Cnx;
    z.Transaction:=Trx;
    if not FBDomainExists(Domain) then
    begin
      z.SQL.Add(Format('CREATE DOMAIN %s %s %s',[Domain, DataType, Decorate]));
      z.ExecSQL;
      Log(Format('Domain %s created.',[Domain]));
    end;
  finally
    z.Free;
  end;
end;

procedure FBCreateTableColumn(const TableName, Column, DataType, Decorate: string);
var
  z: TSQLQuery;
  sql: string;
begin
  CheckFBConnection;
  z := TSQLQuery.Create(nil);
  try
    z.SQLConnection:=Cnx;
    z.Transaction:=Trx;
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
    z.Free;
  end;
end;

function FBTableExists(const TableName: string): boolean;
begin
  CheckFBConnection;
  TableExists := TSQLQuery.Create(nil);
  try
    TableExists.SQLConnection:=Cnx;
    TableExists.Transaction:=Trx;
    TableExists.SQL.Add('SELECT 1 FROM rdb$relations WHERE UPPER(rdb$relation_name) = :TableName');
    TableExists.Params[0].AsString:=TableName.ToUpper;
    TableExists.Open;
    Result := TableExists.Fields[0].AsString = '1';
    TableExists.Close;
  finally
    FreeAndNil(TableExists);
  end;
end;

function FBTableColumnExists(const TableName, Column: string): boolean;
begin
  CheckFBConnection;
  TableColumnExists := TSQLQuery.Create(nil);
  try
    TableColumnExists.SQLConnection:=Cnx;
    TableColumnExists.Transaction:=Trx;
    TableColumnExists.SQL.Add('SELECT 1 from rdb$relation_fields'
                             +' WHERE UPPER(rdb$relation_name) = :TableName'
                             +'   AND UPPER(rdb$field_name) = :Column');

    TableColumnExists.ParamByName('TableName').AsString:=TableName.ToUpper;
    TableColumnExists.ParamByName('Column').AsString:=Column.ToUpper;
    TableColumnExists.Open;
    try
      Result := TableColumnExists.Fields[0].AsString = '1';
    finally
      TableColumnExists.Close;
    end;

  finally
    FreeAndNil(TableColumnExists);
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
  DomainExists := TSQLQuery.Create(nil);
  try
    DomainExists.SQLConnection:=Cnx;
    DomainExists.Transaction:=Trx;
    DomainExists.SQL.Add('SELECT 1 FROM rdb$fields'
                        +' WHERE UPPER(rdb$field_name) = :domain'
                        +'   AND rdb$system_flag = 0');
    if not DomainExists.Prepared then
      DomainExists.Prepare;
    DomainExists.Params[0].AsString:=Domain.ToUpper;
    DomainExists.Open;
    Result := DomainExists.Fields[0].AsString = '1';
    DomainExists.Close;
  finally
    FreeAndNil(DomainExists);
  end;
end;

function FBConstraintExists(const Name: string; out relation_name: string): boolean;
begin
  relation_name:='';
  CheckFBConnection;
  ConstraintExists := TSQLQuery.Create(nil);
  try
    ConstraintExists.SQLConnection:=Cnx;
    ConstraintExists.Transaction:=Trx;
    ConstraintExists.SQL.Add('SELECT UPPER(rdb$relation_name)'
                            +' FROM rdb$indices'
                            +' WHERE UPPER(rdb$index_name) = :Name'
                            +'   AND rdb$system_flag = 0'
                            +'   AND rdb$index_type IS NULL');
    if not ConstraintExists.Prepared then
      ConstraintExists.Prepare;
    ConstraintExists.Params[0].AsString:=Name.ToUpper;
    ConstraintExists.Open;
    Result := not ConstraintExists.EOF;
    if not Result then
      relation_name:=ConstraintExists.Fields[0].AsString;
  finally
    FreeAndNil(ConstraintExists);
  end;
end;

function FBTableIndexExists(const Name, TableName: string): boolean;
begin
  TableIndexExists := TSQLQuery.Create(nil);
  try
    TableIndexExists.SQLConnection:=Cnx;
    TableIndexExists.Transaction:=Trx;
    TableIndexExists.SQL.Add('SELECT 1 FROM rdb$indices'
                            +' WHERE UPPER(rdb$relation_name) = :TableName'
                            +'   AND UPPER(rdb$index_name) = :IndexName'
                            +'   AND rdb$system_flag = 0'
                            +'   AND rdb$index_type = 0');
    TableIndexExists.ParamByName('IndexName').AsString:=Name.ToUpper;
    TableIndexExists.ParamByName('TableName').AsString:=TableName.ToUpper;
    TableIndexExists.Open;
    Result := TableIndexExists.Fields[0].AsString = '1';
  finally
    FreeAndNil(TableIndexExists);
  end;
end;

function FBSequenceExists(const SequenceName: string): boolean;
begin
  with TSQLQuery.Create(nil) do
  begin
    try
      SQLConnection:=Cnx;
      Transaction:=Trx;
      SQL.Add('SELECT COUNT(*) FROM rdb$generators'
             +' WHERE UPPER(rdb$generator_name)= '+SequenceName.ToUpper.QuotedString);
      Log(SQL.Text);
      Open;
      Result:=Fields[0].AsInteger=1;
      Close;
    finally
      Free;
    end;
  end;
end;

initialization
  Cnx := nil;
  Trx := nil;

end.

