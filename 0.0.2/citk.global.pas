unit citk.global;
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

{$mode Delphi}{$H+}

interface

uses
  citk.user, Classes, SysUtils, Chtilux.Logger, citk.dbconfig{, ZConnection}
  ,sqldb // general db unit
  ,db    // for EDatabaseError
  ,ibconnection // firebird
  ,pqconnection // posgresql
  ,sqlite3conn  // sqlite
  ,citk.encrypt;

type

  EInfo = class(Exception);

  { TInfo }

  TInfo = class(TObject)
  private
    FAlias: string;
    FApplicationDescription: string;
    //FCnx: TZConnection;
    FCnx: TSQLConnector;
    FConnectionType: string;
    FCrypter: IEncrypter;
    FDatabaseRelease: string;
    FDBA: string;
    FDBAPwd: string;
    FDefaultUserPassword: string;
    FDomain: string;
    FGlobalPath: TFilename;
    FKey: string;
    FLocalPath: TFilename;
    FLoggedIn: boolean;
    FLogger: ILogger;
    FPasswordChar: Char;
    FProtocol: string;
    FServer: string;
    FTransaction: TSQLTransaction;
    FUser: IUserInfo;
    FValues: TStrings;
    procedure SetAlias(AValue: string);
    procedure SetApplicationDescription(AValue: string);
    //procedure SetCnx(AValue: TZConnection);
    procedure SetCnx(AValue: TSQLConnector);
    procedure SetConnectionType(AValue: string);
    procedure SetCrypter(AValue: IEncrypter);
    procedure SetDatabaseRelease(AValue: string);
    procedure SetDBA(AValue: string);
    procedure SetDBAPwd(AValue: string);
    procedure SetDefaultUserPassword(AValue: string);
    procedure SetDomain(AValue: string);
    procedure SetGlobalPath(AValue: TFilename);
    procedure SetKey(AValue: string);
    procedure SetLocalPath(AValue: TFilename);
    procedure SetLoggedIn(AValue: boolean);
    procedure SetLogger(AValue: ILogger);
    procedure SetPasswordChar(AValue: Char);
    procedure SetProtocol(AValue: string);
    procedure SetServer(AValue: string);
    procedure SetTransaction(AValue: TSQLTransaction);
    procedure SetValue(const Name, Value: string);
  public
    constructor Create(const Domain: string);
    destructor Destroy; override;
    procedure Log(const Texte: string);
    property Domain: string read FDomain write SetDomain;
    property LocalPath: TFilename read FLocalPath write SetLocalPath;
    property GlobalPath: TFilename read FGlobalPath write SetGlobalPath;
    property Logger: ILogger read FLogger write SetLogger;
    property User: IUserInfo read FUser;
    property Key: string read FKey write SetKey;
    property Server: string read FServer write SetServer;
    property Alias: string read FAlias write SetAlias;
    property DBA: string read FDBA write SetDBA;
    property DBAPwd: string read FDBAPwd write SetDBAPwd;
    property Protocol: string read FProtocol write SetProtocol;
    property Values: TStrings read FValues;
    //property Cnx: TZConnection read FCnx write SetCnx;
    property Cnx: TSQLConnector read FCnx write SetCnx;
    property DatabaseRelease: string read FDatabaseRelease write SetDatabaseRelease;
    procedure LogGlobalInfos;
    function Database: string;
    property ApplicationDescription: string read FApplicationDescription write SetApplicationDescription;
    property DefaultUserPassword: string read FDefaultUserPassword write SetDefaultUserPassword;
    property LoggedIn: boolean read FLoggedIn write SetLoggedIn;
    property Crypter: IEncrypter read FCrypter write SetCrypter;
    property PasswordChar: Char read FPasswordChar write SetPasswordChar;
    property Transaction: TSQLTransaction read FTransaction write SetTransaction;
    property ConnectorType: string read FConnectionType write SetConnectionType;
  end;

procedure InitGlobalInfo(var Info: TInfo);

var
  glLogger: ILogger;
  glGlobalInfo: TInfo;
  //glCnx: TZConnection;
  glCnx: TSQLConnector;
  glTrx: TSQLTransaction;

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
  Info.Log('Looking for local ini into : ' + Filename);
  Info.Log(Format('FileExists ? : %s', [BoolToStr(FileExists(Filename),True)]));
  { sinon répertoire de l'utilisateur }
  if not FileExists(Filename) then
  begin
    FileName := Format('%s\%s_local.ini',[ExcludeTrailingPathDelimiter(ExtractFilePath(GetEnvironmentVariable('USERPROFILE')+'\chtilux\')), Info.Domain]);
    Info.Log('Looking for local ini into : ' + Filename);
    Info.Log(Format('FileExists ? : %s', [BoolToStr(FileExists(Filename),True)]));
  end;

  Info.LocalPath:=ExcludeTrailingPathDelimiter(ExtractFilePath(Filename));
  ini := TIniFile.Create(Filename);
  try
     Info.GlobalPath := ini.ReadString('global','ini path',ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))));
     Info.User.Login:=ini.ReadString('user','login','');
     Info.User.Password:=ini.ReadString('user','password',Info.DefaultUserPassword);
     if not ini.ValueExists('global','ini path') then
       ini.WriteString('global','ini path', Info.GlobalPath);
  finally
    ini.Free;
  end;

  Filename := Format('%s\%s_global.ini',[ExcludeTrailingPathDelimiter(Info.GlobalPath), Info.Domain]);
  Info.Log('Looking for global ini into : ' + Filename);
  Info.Log(Format('FileExists ? : %s', [BoolToStr(FileExists(Filename),True)]));
  ini := TInifile.Create(Filename);
  try
    if not ini.ValueExists('security','public key') then
      ini.WriteString('security','public key', Info.Domain);
    Info.Key:=ini.ReadString('security','public key', Info.Domain);

    if not(Info.User.Password.IsEmpty) and (CompareText(Info.User.Password, Info.DefaultUserPassword) <> 0) then
      //Info.User.Password := Decrypt(Info.Key, Info.User.Password);
      Info.User.Password := Info.Crypter.Decrypt(Info.User.Password);

    Info.ApplicationDescription:=ini.ReadString('application','description','Céline in the Kitchen');
    if Info.ApplicationDescription = '' then
      Info.ApplicationDescription:=Info.Key;

    params := GetCommandLineParameters;
    try
      if params.Values['server'] <> '' then
        Info.Server:=params.Values['server']
      else
        Info.Server:=ini.ReadString('database','server','localhost');

      if params.Values['alias'] <> '' then
        Info.Alias:=params.Values['alias']
      else
        Info.Alias:=ini.ReadString('database','alias','citk');

      if params.Values['ConnectorType'] <> '' then
        Info.ConnectorType:=params.Values['ConnectorType']
      else
        Info.ConnectorType:=ini.ReadString('database','connector type','Firebird');
    finally
      params.Free;
    end;

    if not ini.ValueExists('database','dba') then
      ini.WriteString('database','dba','SYSDBA');
    Info.DBA:=ini.ReadString('database','dba','SYSDBA');

    if not ini.ValueExists('database','dbapwd') then
      ini.WriteString('database','dbapwd',Encrypt(Info.Key, 'masterkey'));
    Info.DBAPwd:=ini.ReadString('database','dbapwd', Info.Crypter.Encrypt('masterkey'));

    if not ini.ValueExists('database','connector type') then
      ini.WriteString('database','connector type','Firebird');
    Info.ConnectorType:=ini.ReadString('database','connector type','Firebird');

    if not ini.ValueExists('database','server') then
      ini.WriteString('database','server',Info.Server);

    if not ini.ValueExists('database','Alias') then
      ini.WriteString('database','Alias',Info.Alias);

  finally
    ini.Free;
  end;

  Info.LogGlobalInfos;
end;

{ TInfo }

procedure TInfo.SetLogger(AValue: ILogger);
begin
  FLogger := AValue;
end;

procedure TInfo.SetPasswordChar(AValue: Char);
begin
  if FPasswordChar=AValue then Exit;
  FPasswordChar:=AValue;
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

procedure TInfo.SetLoggedIn(AValue: boolean);
begin
  if FLoggedIn=AValue then Exit;
  FLoggedIn:=AValue;
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

procedure TInfo.SetCnx(AValue: TSQLConnector);
begin
  if FCnx=AValue then Exit;
  FCnx:=AValue;
end;

procedure TInfo.SetConnectionType(AValue: string);
begin
  if FConnectionType=AValue then Exit;
  FConnectionType:=AValue;
end;

procedure TInfo.SetCrypter(AValue: IEncrypter);
begin
  if FCrypter=AValue then Exit;
  FCrypter:=AValue;
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

procedure TInfo.SetDefaultUserPassword(AValue: string);
begin
  if FDefaultUserPassword=AValue then Exit;
  FDefaultUserPassword:=AValue;
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
  FDefaultUserPassword:=Domain;
  FLoggedIn := False;
  FCrypter:=TEncrypter.Create(Domain);
  FPasswordChar:=#0;
end;

destructor TInfo.Destroy;
begin
  FValues.Free;
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

procedure TInfo.SetTransaction(AValue: TSQLTransaction);
begin
  if FTransaction=AValue then Exit;
  FTransaction:=AValue;
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
  glCnx := TSQLConnector.Create(nil);
  glTrx := TSQLTransaction.Create(nil);
  glCnx.Transaction := glTrx;

finalization
  glGlobalInfo.Free;
  if glCnx.Connected then
    glCnx.Connected:=False;
  glTrx.Free;
  glCnx.Free;

end.

