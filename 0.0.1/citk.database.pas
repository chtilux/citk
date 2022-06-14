unit citk.database;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, ZConnection, citk.global, ZDbcIntfs, Chtilux.Logger;

type
  EDatabase = class(Exception);
  EDatabaseConnection = class(EDatabase);

procedure InitDatabase(Connection: TZConnection; Info: TInfo);
procedure ConnectDatabase(Connection: TZConnection; Info: TInfo);
procedure CreateDatabase(Connection: TZConnection; Info: TInfo);
procedure RunDatabaseScript(Info: TInfo);

implementation

uses
  Chtilux.Crypt, citk.Firebird;

var
  Logger: ILogger;

procedure SetLogger(ALogger: ILogger);
begin
  Logger := ALogger;
end;

procedure Log(const Texte: string);
begin
  if Assigned(Logger) then
    Logger.Log('citk.database', Texte);
end;

procedure InitDatabase(Connection: TZConnection; Info: TInfo);
begin
  SetLogger(Info.Logger);
  if Connection.Connected then
    Connection.Disconnect;
  Connection.Database := Format('%s:%s', [Info.Server, Info.Alias]);
  Connection.User:=Info.DBA;
  Connection.Password:=Decrypt(Info.Key, Info.DBAPwd);
  Connection.Protocol:=Info.Protocol;
  Connection.TransactIsolationLevel:=tiReadCommitted;
  Log('InitDatabase');
end;

procedure ConnectDatabase(Connection: TZConnection; Info: TInfo);
begin
  try
    Connection.Connect;
    Info.Cnx := Connection;
    Log('Database connected');
  except
    on E:Exception do
    begin
      Log('ConnectDatabase : ' + E.Message);
      raise EDatabaseConnection.CreateFmt('EDatabaseConnection : %s', [E.Message]);
    end
  end;
end;

procedure CreateDatabase(Connection: TZConnection; Info: TInfo);
begin
  if Connection.Connected then
    Connection.Disconnect;
  Connection.Database:=Format('%s\%s.fdb',[ExcludeTrailingPathDelimiter(Info.GlobalPath), Info.Alias]);
  Connection.Properties.BeginUpDate;
  try
     Connection.Properties.Values['dialect'] := '3';
     Connection.Properties.Values['CreateNewDatabase'] := Format('CREATE DATABASE %s'
                                                               +' USER %s'
                                                               +' PASSWORD %s'
                                                               +' PAGE_SIZE 2048'
                                                               +' DEFAULT CHARACTER_SET WIN1252',[Connection.Database
                                                                                                 ,Info.DBA
                                                                                                 ,'scraps']);
    Connection.LoginPrompt := False;
    Connection.Connect;
    Connection.Disconnect;
    Connection.Properties.Clear;
    Info.Values.Values['DatabaseName'] := Connection.Database;
    Info.Cnx := Connection;
    Log('Database created : ' + Connection.Database);
  finally
    Connection.Properties.EndUpdate;
  end;
end;

procedure IncRelease(var Release: string);
var
  Value: Extended;
begin
  TryStrToFloat(Release, Value);
  Value := Value + 0.01;
  Release := FloatToStr(Value);
end;

procedure UpdateDatabaseRelease(const CurrentRelease, NewRelease: string);
begin
  SQLDirect(Format('UPDATE dictionnaire'
               +' SET pardc1 = %s'
               +'    ,pardc4 = CAST(CURRENT_TIMESTAMP AS VARCHAR(50))'
               +' WHERE UPPER(cledic) = %s'
               +'   AND UPPER(coddic) = %s'
               +'   AND pardc1 = %s',[NewRelease.QuotedString,
                                      'DATABASE'.QuotedString,
                                      'RELEASE'.QuotedString,
                                      CurrentRelease.QuotedString]));
  Log(Format('Database release updated from %s to %s', [CurrentRelease.QuotedString, NewRelease.QuotedString]));
end;

procedure RunDatabaseScript(Info: TInfo);
var
  i: integer;
  Select: TStrings;
  Release: string;
begin
  citk.Firebird.SetConnection(Info.Cnx);
  citk.Firebird.SetLogger(Info.Logger);
  Release := Info.DatabaseRelease;
  if not FBTableExists('dictionnaire') then
  begin
    Release:='0.00';
    FBCreateDomain('d_cledic_nn','varchar(30)','not null');
    FBCreateTableColumn('dictionnaire', 'cledic', 'd_cledic_nn', '');
    FBCreateDomain('d_coddic_nn','varchar(30)','not null');
    FBCreateTableColumn('dictionnaire', 'coddic', 'd_cledic_nn', '');
    FBCreateTableColumn('dictionnaire','libdic','varchar(100)','');
    FBCreateDomain('d_pardc','varchar(50)','');
    for i := 1 to 9 do
      FBCreateTableColumn('dictionnaire',Format('pardc%d',[i]),'d_pardc','');
    FBAddConstraint('dictionnaire','pk_dictionnaire','PRIMARY KEY','cledic,coddic');
    Select := SelectSQLDirect('SELECT RDB$GET_CONTEXT(''SYSTEM'', ''ENGINE_VERSION'') AS engine_version'
                             +' FROM rdb$database');
    try
      SQLDirect(Format('UPDATE OR INSERT INTO dictionnaire (cledic,coddic,libdic,pardc1,pardc2,pardc3,pardc4)'
                      +' VALUES (%s,%s,%s,%s,%s,%s,%s)',['database'.QuotedString,
                                                         'release'.QuotedString,
                                                         'Version,Firebird,Replica,Date'.QuotedString,
                                                         '0.00'.QuotedString,
                                                         Select.Values['engine_version'].QuotedString,
                                                         ''.QuotedString,
                                                         DateTimeToStr(Now).QuotedString]));
      Log('Dictionnaire created');
    finally
      Select.Free;
    end;
  end
  else
  begin
    { read current database release number }
    Select := SelectSQLDirect('SELECT pardc1 FROM dictionnaire'
                             +' WHERE UPPER(cledic) = ''DATABASE'''
                             +'   AND UPPER(coddic) = ''RELEASE''');
    try
      Release := Select.Values['pardc1'];
      Log(Format('RunDatabaseScript(release=%s)',[Release]));
    finally
      Select.Free;
    end;
  end;

  if Release = '0.00' then
  begin
    FBCreateDomain('d_serial_nn','integer','not null');
    FBCreateDomain('d_login_nn','varchar(30)','not null');
    FBCreateTableColumn('users','login','d_login_nn','');
    FBCreateTableColumn('users','active','boolean','default TRUE not null');
    FBCreateTableColumn('users','user_name','varchar(100)','');
    FBCreateDomain('d_password_nn','varchar(30)','not null');
    FBCreateTableColumn('users','password','d_password_nn','');
    FBAddConstraint('users','pk_users','primary key','login');
    Log('Table users created');

    if not Info.User.Login.IsEmpty then
        SQLDirect(Format('UPDATE OR INSERT INTO users (login,active,password) VALUES (%s,%s,%s)',[Info.User.Login.QuotedString,'TRUE',QuotedStr(Encrypt(Info.Key,Info.Domain))]));

    IncRelease(Release);
    Log('Release='+Release);
    UpdateDatabaseRelease(Info.DatabaseRelease, Release);
  end;

  //if Release = '0.01' then
  //begin
  //  IncRelease(Release);
  //  Log('Release='+Release);
  //  UpdateDatabaseRelease(Info.DatabaseRelease, Release);
  //end;

  Info.DatabaseRelease:=Release;
end;

end.

