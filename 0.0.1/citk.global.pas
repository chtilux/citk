unit citk.global;

{$mode Delphi}{$H+}

interface

uses
  Classes, SysUtils, Chtilux.Logger, ZConnection;

type
  { TInfo }

  EUserInfo = class(Exception);

  { TUserInfo }

  TUserInfo = class(TObject)
  private
    FLogin: string;
    FPassword: string;
    procedure SetLogin(AValue: string);
    procedure SetPassword(AValue: string);
  public
    property Login: string read FLogin write SetLogin;
    property Password: string read FPassword write SetPassword;
  end;

  EInfo = class(Exception);
  TInfo = class(TObject)
  private
    FAlias: string;
    FApplicationDescription: string;
    FCnx: TZConnection;
    FDatabaseRelease: string;
    FDBA: string;
    FDBAPwd: string;
    FDomain: string;
    FGlobalPath: TFilename;
    FKey: string;
    FLocalPath: TFilename;
    FLogger: ILogger;
    FProtocol: string;
    FServer: string;
    FUser: TUserInfo;
    FValues: TStrings;
    procedure SetAlias(AValue: string);
    procedure SetApplicationDescription(AValue: string);
    procedure SetCnx(AValue: TZConnection);
    procedure SetDatabaseRelease(AValue: string);
    procedure SetDBA(AValue: string);
    procedure SetDBAPwd(AValue: string);
    procedure SetDomain(AValue: string);
    procedure SetGlobalPath(AValue: TFilename);
    procedure SetKey(AValue: string);
    procedure SetLocalPath(AValue: TFilename);
    procedure SetLogger(AValue: ILogger);
    procedure SetProtocol(AValue: string);
    procedure SetServer(AValue: string);
    procedure SetValue(const Name, Value: string);
  public
    constructor Create(const Domain: string);
    destructor Destroy; override;
    procedure Log(const Texte: string);
    property Domain: string read FDomain write SetDomain;
    property LocalPath: TFilename read FLocalPath write SetLocalPath;
    property GlobalPath: TFilename read FGlobalPath write SetGlobalPath;
    property Logger: ILogger read FLogger write SetLogger;
    property User: TUserInfo read FUser;
    property Key: string read FKey write SetKey;
    property Server: string read FServer write SetServer;
    property Alias: string read FAlias write SetAlias;
    property DBA: string read FDBA write SetDBA;
    property DBAPwd: string read FDBAPwd write SetDBAPwd;
    property Protocol: string read FProtocol write SetProtocol;
    property Values: TStrings read FValues;
    property Cnx: TZConnection read FCnx write SetCnx;
    property DatabaseRelease: string read FDatabaseRelease write SetDatabaseRelease;
    procedure LogGlobalInfos;
    function Database: string;
    property ApplicationDescription: string read FApplicationDescription write SetApplicationDescription;
  end;

procedure InitGlobalInfo(var Info: TInfo);

var
  glLogger: ILogger;
  glGlobalInfo: TInfo;
  glCnx: TZConnection;

const
  DOMAIN = 'CelineInTheKitchen';

implementation

uses
  Inifiles, Chtilux.CommandLineParameters, Chtilux.Crypt;

procedure InitGlobalInfo(var Info: TInfo);
var
  Filename: TFilename;
  ini: TInifile;
  params: TStrings;
begin
  { on recherche le fichier ini local dans le répertoire de l'exécutable }
  Filename := Format('%s\%s_local.ini',[ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))), Info.Domain]);
  { sinon répertoire de l'utilisateur }
  if not FileExists(Filename) then
    FileName := Format('%s\%s_local.ini',[ExcludeTrailingPathDelimiter(ExtractFilePath(GetEnvironmentVariable('USERPROFILE')+'\chtilux\')), Info.Domain]);

  Info.LocalPath:=Filename;
  ini := TIniFile.Create(Filename);
  try
     Info.GlobalPath := ini.ReadString('global','ini path',ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))));
     Info.User.Login:=ini.ReadString('user','login','');
  finally
    ini.Free;
  end;

  Filename := Format('%s\%s_global.ini',[ExcludeTrailingPathDelimiter(Info.GlobalPath), Info.Domain]);
  ini := TInifile.Create(Filename);
  try
    if not ini.ValueExists('security','public key') then
      ini.WriteString('security','public key', Info.Domain);
    Info.Key:=ini.ReadString('security','public key', Info.Domain);
    Info.ApplicationDescription:=ini.ReadString('application','description','Céline in the Kitchen');
    if Info.ApplicationDescription = '' then
      Info.ApplicationDescription:=Info.Key;

    params := GetCommandLineParameters;
    try
      if params.Values['server'] <> '' then
        Info.Server:=params.Values['server']
      else
        Info.Server:=ini.ReadString('database','server','');

      if params.Values['alias'] <> '' then
        Info.Alias:=params.Values['alias']
      else
        Info.Alias:=ini.ReadString('database','alias','');
    finally
      params.Free;
    end;

    if not ini.ValueExists('database','dba') then
      ini.WriteString('database','dba','SYSDBA');
    Info.DBA:=ini.ReadString('database','dba','SYSDBA');

    if not ini.ValueExists('database','dbapwd') then
      ini.WriteString('database','dbapwd',Encrypt(Info.Key, 'scraps'));
    Info.DBAPwd:=ini.ReadString('database','dbapwd',Encrypt(Info.Key, 'masterkey'));

    if not ini.ValueExists('database','protocol') then
      ini.WriteString('database','protocol','firebird-3.0');
    Info.Protocol:=ini.ReadString('database','protocol','firebird-3.0');

  finally
    ini.Free;
  end;

  Info.LogGlobalInfos;
end;

{ TUserInfo }

procedure TUserInfo.SetLogin(AValue: string);
begin
  if FLogin=AValue then Exit;
  FLogin:=AValue.ToUpper;
end;

procedure TUserInfo.SetPassword(AValue: string);
begin
  if FPassword=AValue then Exit;
  FPassword:=AValue;
end;

{ TInfo }

procedure TInfo.SetLogger(AValue: ILogger);
begin
  FLogger := AValue;
end;

procedure TInfo.SetKey(AValue: string);
begin
  if FKey=AValue then Exit;
  FKey:=AValue;
end;

procedure TInfo.SetLocalPath(AValue: TFilename);
begin
  if FLocalPath=AValue then Exit;
  FLocalPath:=AValue;
  SetValue('LocalPath', AValue);
end;

procedure TInfo.SetAlias(AValue: string);
begin
  if FAlias=AValue then Exit;
  FAlias:=AValue;
  SetValue('alias', FAlias);
end;

procedure TInfo.SetApplicationDescription(AValue: string);
begin
  if FApplicationDescription=AValue then Exit;
  FApplicationDescription:=AValue;
end;

procedure TInfo.SetCnx(AValue: TZConnection);
begin
  if FCnx=AValue then Exit;
  FCnx:=AValue;
end;

procedure TInfo.SetDatabaseRelease(AValue: string);
begin
  if FDatabaseRelease=AValue then Exit;
  FDatabaseRelease:=AValue;
end;

procedure TInfo.SetDBA(AValue: string);
begin
  if FDBA=AValue then Exit;
  FDBA:=AValue;
  SetValue('DBA', AValue);
end;

procedure TInfo.SetDBAPwd(AValue: string);
begin
  if FDBAPwd=AValue then Exit;
  FDBAPwd:=AValue;
  SetValue('DBAPwd', AValue);
end;

procedure TInfo.SetDomain(AValue: string);
begin
  if FDomain=AValue then Exit;
  FDomain:=AValue;
  SetValue('Domain', AValue);
end;

procedure TInfo.SetGlobalPath(AValue: TFilename);
begin
  if FGlobalPath=AValue then Exit;
  FGlobalPath:=AValue;
  SetValue('GlobalPath', AValue);
end;

constructor TInfo.Create(const Domain: string);
begin
  FLogger := nil;
  FUser := TUserInfo.Create;
  FValues := TStringList.Create;
  Self.Domain := Domain;
  FDatabaseRelease:='0.00';
end;

destructor TInfo.Destroy;
begin
  FValues.Free;
  FUser.Free;
  inherited Destroy;
end;

procedure TInfo.Log(const Texte: string);
begin
  if Assigned(FLogger) then
    FLogger.Log(Classname, Texte);
end;

procedure TInfo.SetProtocol(AValue: string);
begin
  if FProtocol=AValue then Exit;
  FProtocol:=AValue;
  SetValue('Protocol', AValue);
end;

procedure TInfo.SetServer(AValue: string);
begin
  if FServer=AValue then Exit;
  FServer:=AValue;
  SetValue('Server', AValue);
end;

procedure TInfo.SetValue(const Name, Value: string);
begin
  FValues.Values[Name] := Value;
end;

procedure TInfo.LogGlobalInfos;
var
  i: integer;
begin
  for i := 0 to FValues.Count-1 do
    Log(Format('%s=%s',[FValues.Names[i], FValues.Values[FValues.Names[i]]]));
end;

function TInfo.Database: string;
begin
  Result := Format('%s:%s',[Server, Alias]);
end;

initialization
  glGlobalInfo := TInfo.Create(DOMAIN);
  glCnx := TZConnection.Create(nil);

finalization
  glGlobalInfo.Free;
  if glCnx.Connected then
    glCnx.Disconnect;
  glCnx.Free;

end.

