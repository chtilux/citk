unit citk.database;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils{, ZConnection}, SQLDB, citk.global, ZDbcIntfs, Chtilux.Logger;

type
  EDatabase = class(Exception);
  EDatabaseConnection = class(EDatabase);

//procedure InitDatabase(Connection: TZConnection; Info: TInfo);
//procedure ConnectDatabase(Connection: TZConnection; Info: TInfo);
//procedure CreateDatabase(Connection: TZConnection; Info: TInfo);
procedure InitDatabase(Connection: TSQLConnection; Info: TInfo);
procedure ConnectDatabase(Connection: TSQLConnection; Info: TInfo);
procedure CreateDatabase(Connection: TSQLConnection; Info: TInfo);
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

procedure InitDatabase(Connection: TSQLConnection; Info: TInfo);
begin
  SetLogger(Info.Logger);
  if Connection.Connected then
    Connection.Connected:=False;
  Connection.DatabaseName := Format('%s:%s', [Info.Server, Info.Alias]);
  Connection.UserName:=Info.DBA;
  Connection.Password:=Decrypt(Info.Key, Info.DBAPwd);
  //Connection.Protocol:=Info.Protocol;
  //Connection.TransactIsolationLevel:=tiReadCommitted;
  Log('InitDatabase');
end;

procedure ConnectDatabase(Connection: TSQLConnection; Info: TInfo);
begin
  try
    Connection.Connected:=True;
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

procedure CreateDatabase(Connection: TSQLConnection; Info: TInfo);
begin
  if Connection.Connected then
    Connection.Connected:=False;
  Connection.DatabaseName:=Format('%s\%s.fdb',[ExcludeTrailingPathDelimiter(Info.GlobalPath), Info.Alias]);
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
                  +' WHERE cledic = %s'
                  +'   AND coddic = %s'
                  +'   AND pardc1 = %s',[NewRelease.QuotedString,
                                         'database'.QuotedString,
                                         'release'.QuotedString,
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
    FBAddConstraint('dictionnaire','pk_dictionnaire','PRIMARY KEY','(cledic,coddic)');
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
      Info.DatabaseRelease:=Release;
      Log(Format('RunDatabaseScript(release=%s)',[Release]));
    finally
      Select.Free;
    end;

    Select := SelectSQLDirect('SELECT RDB$GET_CONTEXT(''SYSTEM'', ''ENGINE_VERSION'') AS engine_version'
                             +' FROM rdb$database');
    try
      SQLDirect(Format('UPDATE OR INSERT INTO dictionnaire (cledic,coddic,pardc2,pardc4)'
                      +' VALUES (%s,%s,%s,%s)',['database'.QuotedString,
                                                'release'.QuotedString,
                                                Select.Values['engine_version'].QuotedString,
                                                DateTimeToStr(Now).QuotedString]));
      Log('engine version='+Select.Values['engine_version']);
    finally
      Select.Free;
    end;
  end;

  if Info.DatabaseRelease = '0.00' then
  begin
    FBCreateDomain('d_serial_nn','integer','not null');
    FBCreateDomain('d_login_nn','varchar(30)','not null');
    FBCreateTableColumn('users','login','d_login_nn','');
    FBCreateTableColumn('users','active','boolean','default TRUE not null');
    FBCreateTableColumn('users','user_name','varchar(100)','');
    FBCreateDomain('d_password_nn','varchar(30)','not null');
    FBCreateTableColumn('users','password','d_password_nn','');
    FBAddConstraint('users','pk_users','primary key','(login)');
    Log('Table users created');

    if not Info.User.Login.IsEmpty then
        SQLDirect(Format('UPDATE OR INSERT INTO users (login,active,password) VALUES (%s,%s,%s)',[Info.User.Login.QuotedString,'TRUE',QuotedStr(Info.Crypter.Encrypt(Info.Domain))]));

    IncRelease(Release);
    Log('Release='+Release);
    UpdateDatabaseRelease(Info.DatabaseRelease, Release);
  end;

  if Info.DatabaseRelease = '0.01' then
  begin
    IncRelease(Release);
    Log('Release='+Release);
    Info.Cnx.StartTransaction;
    try
      SQLDirect(Format('UPDATE OR INSERT INTO dictionnaire(cledic,coddic,libdic,pardc1) VALUES (%s,%s,%s,%s)',
                       ['security'.QuotedString,'public key'.QuotedString,'clé publique'.QuotedString,DOMAIN.QuotedString]));
      SQLDirect('UPDATE users SET password = ' + DOMAIN.QuotedString);
      UpdateDatabaseRelease(Info.DatabaseRelease, Release);
      Info.Cnx.Commit;
    except
      on E:Exception do
      begin
        Info.Cnx.Rollback;
        Log(E.Message);
      end;
    end;
  end;

  if Info.DatabaseRelease = '0.02' then
  begin
    IncRelease(Release);
    Log('Release='+Release);
    Info.Cnx.StartTransaction;
    try
      FBCreateTableColumn('products','serprd','d_serial_nn','');
      FBCreateDomain('d_libelle_nn','varchar(100)','');
      FBCreateTableColumn('products','libprd','d_libelle_nn','');
      FBCreateDomain('d_boolean_nn','boolean', 'not null');
      FBCreateTableColumn('products','active', 'd_boolean_nn','default TRUE');
      UpdateDatabaseRelease(Info.DatabaseRelease, Release);
      Info.Cnx.Commit;
      Log(Format('Release %s commited.',[Release]));
    except
      on E:Exception do
      begin
        Info.Cnx.Rollback;
        Log(Format('Release %s rolledback : %s', [Release, E.Message]));
      end;
    end;
  end;

  if Info.DatabaseRelease = '0.03' then
  begin
    IncRelease(Release);
    Log('Release='+Release);
    Info.Cnx.StartTransaction;
    try
      FBAddConstraint('products','pk_products', 'primary key', '(serprd)');
      FBCreateDomain('d_code','varchar(16)','');
      FBCreateTableColumn('products','code','d_code','');
      FBCreateIndex('','i01_products_lib','products','libprd');
      FBCreateIndex('','i02_products_code','products','code');
      FBCreateTableColumn('prices','serprc','d_serial_nn','');
      FBCreateTableColumn('prices','serprd','d_serial_nn','');
      FBCreateDomain('d_date_nn','date','not null');
      FBCreateTableColumn('prices','dateff','d_date_nn','');
      FBCreateTableColumn('prices','qtymin','decimal(7,3)','default 0.001 not null');
      FBCreateDomain('d_price_nn','decimal(9,2)','not null');
      FBCreateTableColumn('prices','price','d_price_nn','');
      FBAddConstraint('prices','pk_prices','primary key','(serprc)');
      FBCreateIndex('unique','i01_prices','prices','serprd,dateff,qtymin');
      FBAddConstraint('prices','fk_prices_product','foreign key','(serprd) references products');
      UpdateDatabaseRelease(Info.DatabaseRelease, Release);
      Info.Cnx.Commit;
    except
      on E:Exception do
      begin
        Info.Cnx.Rollback;
        Log(E.Message);
      end;
    end;
  end;

  //if Info.DatabaseRelease = 'x.xx' then
  //begin
  //  IncRelease(Release);
  //  Log('Release='+Release);
  //  Info.Cnx.StartTransaction;
  //  try
  //    UpdateDatabaseRelease(Info.DatabaseRelease, Release);
  //    Info.Cnx.Commit;
  //  except
  //    on E:Exception do
  //    begin
  //      Info.Cnx.Rollback;
  //      Log(E.Message);
  //    end;
  //  end;
  //end;

  Info.DatabaseRelease:=Release;
end;

end.

