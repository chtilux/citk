program citk;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, zcomponent, mainwindow, SysUtils, Dialogs, lazcontrols,
  runtimetypeinfocontrols
  { you can add units after this }
  ,citk.global, citk.Database, Chtilux.Logger, citk.firebird, citk.login,
  citk.loginDialog, citk.utils, citk.user, citk.persistence, citk.encrypt,
  citk.DataModule, citk.DataGridForm, citk.DataObject;

{$R *.res}

procedure Log(const Texte: string);
begin
  glLogger.Log('citk',Texte);
end;

var
  Message: string;

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;

  try
    glLogger := TTextFileLogger.Create;
    glGlobalInfo.Logger := glLogger;
    InitGlobalInfo(glGlobalInfo);
    InitDatabase(glCnx, glGlobalInfo);
    try
      ConnectDatabase(glCnx, glGlobalInfo);
      Application.Initialize;
      Login(glGlobalInfo);
      RunDatabaseScript(glGlobalInfo);
    except
      on E:EDatabaseConnection do
      begin
        glGlobalInfo.Log(E.Message);
        glGlobalInfo.Log('Trying to create database');
        CreateDatabase(glCnx, glGlobalInfo);
        RunDatabaseScript(glGlobalInfo);
        Message := Format('Database created : %s. Edit the Firebird Databases.conf file.', [glGlobalInfo.Values.Values['DatabaseName']]);
        MessageDlg(Message, mtInformation, [mbOk], 0);
        glGlobalInfo.Log(Message);
        Exit;
      end;

      on E:EFirebird do
      begin
        Message := E.Message;
        MessageDlg(Message, mtInformation, [mbOk], 0);
        glGlobalInfo.Log(Message);
        Exit;
      end;

      on E:Exception do
      begin
        Message := E.Message;
        MessageDlg(Message, mtInformation, [mbOk], 0);
        glGlobalInfo.Log(Message);
        Exit;
      end;
    end;

    if glGlobalInfo.LoggedIn then
    begin
      Application.CreateForm(TMainW, MainW);
      MainW.Info := glGlobalInfo;
  Application.CreateForm(TcitkDataModule, citkDataModule);
  Application.CreateForm(TDataGridForm, DataGridForm);
      Application.Run;
    end;

  except
    on E:Exception do
        Log(E.Message);
  end;
end.

