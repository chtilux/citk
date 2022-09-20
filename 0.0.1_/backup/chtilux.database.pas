unit chtilux.database;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, ZConnection, chtilux.global, Chtilux.Crypt, ZDbcIntfs;

type
  EDatabase = class(Exception);
  EDatabaseConnection = class(EDatabase);

procedure InitDatabase(Connection: TZConnection; Info: TInfo);
procedure ConnectDatabase(Connection: TZConnection; Info: TInfo);

implementation

procedure InitDatabase(Connection: TZConnection; Info: TInfo);
begin
  if Connection.Connected then
    Connection.Disconnect;
  Connection.Database := Format('%s:%s', [Info.Server, Info.Alias]);
  Connection.User:=Info.DBA;
  Connection.Password:=Decrypt(Info.Key, Info.DBAPwd);
  Connection.Protocol:=Info.Protocol;
  Connection.TransactIsolationLevel:=tiReadCommitted;
end;

procedure ConnectDatabase(Connection: TZConnection; Info: TInfo);
begin
  try
    Connection.Connect;
    Info.Log('Database connected');
  except
    on E:Exception do
    begin
      Info.Log('ConnectDatabase : ' + E.Message);
      raise EDatabaseConnection.CreateFmt('EDatabaseConnection : %s', [E.Message]));
    end
  end;
end;

end.

