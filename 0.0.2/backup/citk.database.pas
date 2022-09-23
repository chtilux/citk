unit citk.database;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, sqldb, citk.global, Chtilux.Logger, IBConnection;

type
  EDatabase = class(Exception);
  EDatabaseConnection = class(EDatabase);

procedure InitDatabase(Connection: TSQLConnector; Info: TInfo);
procedure ConnectDatabase(Connection: TSQLConnector; Info: TInfo);
function CreateDatabase(Info: TInfo): boolean;
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

procedure InitDatabase(Connection: TSQLConnector; Info: TInfo);
begin
  SetLogger(Info.Logger);
  if Connection.Connected then
    Connection.Connected:=False;
  Connection.DatabaseName := Format('%s:%s', [Info.Server, Info.Alias]);
  Connection.UserName:=Info.DBA;
  Connection.Password:=Decrypt(Info.Key, Info.DBAPwd);
  Connection.ConnectorType:=Info.ConnectorType;
  Log('InitDatabase');
end;

procedure ConnectDatabase(Connection: TSQLConnector; Info: TInfo);
begin
  try
    Connection.Connected:=True;
    Info.Cnx := Connection;
    Info.Transaction:=Connection.Transaction;
    Log('Database connected');
  except
    on E:Exception do
    begin
      Log('ConnectDatabase : ' + E.Message);
      raise EDatabaseConnection.CreateFmt('EDatabaseConnection : %s', [E.Message]);
    end
  end;
end;

function CreateDatabase(Info: TInfo): boolean;
var
  Cnx: TIBConnection;
  Trx: TSQLTransaction;
begin
  Cnx := TIBConnection.Create(nil);
  try
    Trx := TSQLTransaction.Create(nil);
    try
      Cnx.Transaction:=Trx;
      Trx.SQLConnection:=Cnx;
      Cnx.CharSet:='WIN1252';
      Cnx.HostName:=Info.Server;
      Cnx.DatabaseName:=Info.Alias;
      Cnx.UserName:='SYSDBA';
      Cnx.Password:='scraps';
      Cnx.CreateDB;
      Result := True;
    finally
      Trx.free;
    end;
  finally
    Cnx.Free;
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
  citk.Firebird.SetConnection(Info.Cnx, Info.Transaction);
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
      Info.Transaction.Commit;
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
  end;
  //else
  //begin
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
  //end;

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

    Info.Transaction.Commit;
    if not Info.User.Login.IsEmpty then
        SQLDirect(Format('UPDATE OR INSERT INTO users (login,active,password) VALUES (%s,%s,%s)',[Info.User.Login.QuotedString,'TRUE',QuotedStr(Info.Crypter.Encrypt(Info.Domain))]));
    SQLDirect(Format('UPDATE OR INSERT INTO users (login,active,password) VALUES (%s,%s,%s)',['Céline'.QuotedString,'TRUE',QuotedStr('tQLE9bJ8')]));

    IncRelease(Release);
    Log('Release='+Release);
    UpdateDatabaseRelease(Info.DatabaseRelease, Release);
    Info.Transaction.Commit;
  end;

  if Release = '0.01' then
  begin
    IncRelease(Release);
    Log('Release='+Release);
    //Info.Cnx.StartTransaction;
    try
      SQLDirect(Format('UPDATE OR INSERT INTO dictionnaire(cledic,coddic,libdic,pardc1) VALUES (%s,%s,%s,%s)',
                       ['security'.QuotedString,'public key'.QuotedString,'clé publique'.QuotedString,DOMAIN.QuotedString]));
      SQLDirect('UPDATE users SET password = ' + DOMAIN.QuotedString);
      UpdateDatabaseRelease(Info.DatabaseRelease, Release);
      Info.Transaction.Commit;
    except
      on E:Exception do
      begin
        Info.Transaction.Rollback;
        Log(E.Message);
      end;
    end;
  end;

  if Release = '0.02' then
  begin
    IncRelease(Release);
    Log('Release='+Release);
    //Info.Cnx.StartTransaction;
    try
      FBCreateDomain('d_codtva_nn','VARCHAR(3)','NOT NULL');
      Info.Transaction.Commit;
      FBCreateTableColumn('tva','codtva','d_codtva_nn','');
      FBCreateTableColumn('tva','libtva','d_libelle_nn','');
      FBAddConstraint('tva','pk_tva','primary key','(codtva)');
      Info.Transaction.Commit;
      SQLDirect('UPDATE OR INSERT INTO tva(codtva,libtva) VALUES (''S1'',''Taux normal'')');
      SQLDirect('UPDATE OR INSERT INTO tva(codtva,libtva) VALUES (''S2'',''Taux super réduit'')');

      FBCreateTableColumn('tautva','codtva','d_codtva_nn','');
      FBCreateTableColumn('tautva','dateff','date','not null');
      FBCreateTableColumn('tautva','rate','decimal(6,3)','not null');
      FBAddConstraint('tautva','pk_tautva','primary key', '(codtva,dateff)');
      FBAddConstraint('tautva','fk_tautva_codtva','foreign key','(codtva) references tva');
      Info.Transaction.Commit;
      SQLDirect('UPDATE OR INSERT INTO tautva(codtva,dateff,rate) VALUES (''S1'',''2022/01/01'',''17'')');
      SQLDirect('UPDATE OR INSERT INTO tautva(codtva,dateff,rate) VALUES (''S2'',''2022/01/01'',''3'')');

      FBCreateTableColumn('products','serprd','d_serial_nn','');
      FBCreateDomain('d_libelle_nn','varchar(100)','');
      FBCreateTableColumn('products','libprd','d_libelle_nn','');
      FBCreateDomain('d_boolean_nn','boolean', 'not null');
      FBCreateTableColumn('products','active', 'd_boolean_nn','default TRUE');
      FBCreateTableColumn('products','codtva','d_codtva_nn','');
      FBAddConstraint('products','pk_products', 'primary key', '(serprd)');
      FBCreateDomain('d_code','varchar(16)','');
      FBCreateTableColumn('products','codprd','d_code','');
      FBCreateIndex('','i01_products_lib','products','libprd');
      FBCreateIndex('','i02_products_code','products','codprd');
      FBCreateIndex('','i03_products_codtva','products','codtva');
      FBAddConstraint('products','fk_products_codtva','foreign key','(codtva) references tva');
      UpdateDatabaseRelease(Info.DatabaseRelease, Release);
      Info.Transaction.Commit;
      Log(Format('Release %s commited.',[Release]));
    except
      on E:Exception do
      begin
        Info.Transaction.Rollback;
        Log(Format('Release %s rolledback : %s', [Release, E.Message]));
      end;
    end;
  end;

  if Release = '0.03' then
  begin
    IncRelease(Release);
    Log('Release='+Release);
    //Info.Cnx.StartTransaction;
    try
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
      Info.Transaction.Commit;
    except
      on E:Exception do
      begin
        Info.Transaction.Rollback;
        Log(E.Message);
      end;
    end;
  end;

  if Release = '0.04' then
  begin
    IncRelease(Release);
    Log('Release='+Release);
    //Info.Cnx.StartTransaction;
    try
      FBCreateTableColumn('prices','ptype','char(1)','default ''V'' not null');
      SQLDirect('drop index i01_prices');
      FBCreateIndex('unique','i01_prices','prices','serprd,ptype,dateff,qtymin');
      UpdateDatabaseRelease(Info.DatabaseRelease, Release);
      Info.Transaction.Commit;
    except
      on E:Exception do
      begin
        Info.Transaction.Rollback;
        Log(E.Message);
      end;
    end;
  end;

  if Release = '0.05' then
  begin
    IncRelease(Release);
    Log('Release='+Release);
    try
      if not FBSequenceExists('SEQ_PRODUCTS') then
            SQLDirect('CREATE SEQUENCE seq_products');
      UpdateDatabaseRelease(Info.DatabaseRelease, Release);
      Info.Transaction.Commit;
    except
      on E:Exception do
      begin
        Info.Transaction.Rollback;
        Log(E.Message);
      end;
    end;
  end;

  if Release = '0.06' then
  begin
    IncRelease(Release);
    Log('Release='+Release);
    try
      FBCreateDomain('d_code_nn','varchar(16)','not null');
      FBCreateTableColumn('products','codprd','d_code_nn','');
      UpdateDatabaseRelease(Info.DatabaseRelease, Release);
      Info.Transaction.Commit;
    except
      on E:Exception do
      begin
        Info.Transaction.Rollback;
        Log(E.Message);
      end;
    end;
  end;

  if Release = '0.07' then
  begin
    IncRelease(Release);
    Log('Release='+Release);
    try
      //SQLDirect('DROP INDEX i02_products_code');
      //SQLDirect('ALTER TABLE products DROP code');
      //FBCreateIndex('','i02_products_codprd','products','codprd');
      UpdateDatabaseRelease(Info.DatabaseRelease, Release);
      Info.Transaction.Commit;
    except
      on E:Exception do
      begin
        Info.Transaction.Rollback;
        Log(E.Message);
      end;
    end;
  end;

  if Release = '0.08' then
  begin
    IncRelease(Release);
    Log('Release='+Release);
    try
      if not FBSequenceExists('SEQ_EVENTS') then
            SQLDirect('CREATE SEQUENCE SEQ_EVENTS');
      FBCreateTableColumn('event','serevt','integer','not null');
      FBCreateTableColumn('event','begevt','d_date_nn','');
      FBCreateTableColumn('event','endevt','d_date_nn','');
      FBCreateTableColumn('event','libevt','d_libelle_nn','');
      FBCreateTableColumn('event','active','d_boolean_nn','');
      UpdateDatabaseRelease(Info.DatabaseRelease, Release);
      Info.Transaction.Commit;
    except
      on E:Exception do
      begin
        Info.Transaction.Rollback;
        Log(E.Message);
      end;
    end;
  end;

  if Release = '0.09' then
  begin
    try
      FBAddConstraint('event','pk_event','primary key','(serevt)');
      if not FBSequenceExists('SEQ_CUSTOMERS') then
            SQLDirect('CREATE SEQUENCE SEQ_CUSTOMERS');
      FBCreateTableColumn('customers','sercust','integer','not null');
      FBCreateTableColumn('customers','custname','d_libelle_nn','');
      FBAddConstraint('customers','pk_customers','primary key','(sercust)');
      IncRelease(Release);
      Log('Release='+Release);
      UpdateDatabaseRelease(Info.DatabaseRelease, Release);
      Info.Transaction.Commit;
    except
      on E:Exception do
      begin
        Info.Transaction.Rollback;
        Log(E.Message);
      end;
    end;
  end;

  if Release = '0.1' then
  begin
    IncRelease(Release);
    Log('Release='+Release);
    try
      UpdateDatabaseRelease(Info.DatabaseRelease, Release);
      Info.Transaction.Commit;
    except
      on E:Exception do
      begin
        Info.Transaction.Rollback;
        Log(E.Message);
      end;
    end;
  end;

  if Release = '0.11' then
  begin
    IncRelease(Release);
    Log('Release='+Release);
    try
      //FBCreateIndex('','i01_event','event','begevt DESC, endevt DESC');
      //SQLDirect('CREATE DESCENDING INDEX i01_event ON event (begevt,endevt)');
      FBCreateTableColumn('event_detail','serdet','d_serial_nn','');
      FBCreateTableColumn('event_detail','serevt','d_serial_nn','');
      FBCreateTableColumn('event_detail','numseq','smallint','not null');
      FBCreateTableColumn('event_detail','serprd','d_serial_nn','');
      FBCreateTableColumn('event_detail','libprd','d_libelle_nn','');
      FBCreateTableColumn('event_detail','price','d_price_nn','');
      FBAddConstraint('event_detail','pk_event_detail','primary key','(serdet)');
      FBCreateIndex('','i01_event_detail_serevt','event_detail','serevt');
      FBCreateIndex('','i02_event_detail_numseq','event_detail','numseq,serevt');
      FBCreateIndex('','i03_event_detail_serprd','event_detail','serprd');
      FBAddConstraint('event_detail','fk_event_detail_event','foreign key','(serevt) REFERENCES event');
      FBAddConstraint('event_detail','fk_event_detail_product','foreign key','(serprd) REFERENCES products');
      UpdateDatabaseRelease(Info.DatabaseRelease, Release);
      Info.Transaction.Commit;
    except
      on E:Exception do
      begin
        Info.Transaction.Rollback;
        Log(E.Message);
      end;
    end;
  end;
  //if Info.DatabaseRelease = 'x.xx' then
  //begin
  //  IncRelease(Release);
  //  Log('Release='+Release);
  //  try
  //FBAddConstraint('prices','pk_prices','primary key','(serprc)');
  //FBCreateIndex('unique','i01_prices','prices','serprd,dateff,qtymin');
  //FBAddConstraint('prices','fk_prices_product','foreign key','(serprd) references products');
  //    UpdateDatabaseRelease(Info.DatabaseRelease, Release);
  //    Info.Transaction.Commit;
  //  except
  //    on E:Exception do
  //    begin
  //      Info.Transaction.Rollback;
  //      Log(E.Message);
  //    end;
  //  end;
  //end;

  Info.DatabaseRelease:=Release;
end;

end.

