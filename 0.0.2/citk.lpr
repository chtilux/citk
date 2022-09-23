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
  Forms, mainwindow, SysUtils, Dialogs, lazcontrols,
  runtimetypeinfocontrols, datetimectrls,Controls,
  { you can add units after this }
  citk.global, citk.Database, Chtilux.Logger, citk.firebird, citk.login,
  citk.loginDialog, citk.utils, citk.user, citk.persistence, citk.encrypt,
  citk.DataModule, citk.DataGridForm,
  //citk.dbconfiggui, citk.dbconfig,
  {General db unit}sqldb,
  {For EDataBaseError}db,
  {Now we add all databases we want to support, otherwise their drivers won't be loaded}
  IBConnection, pqconnection, sqlite3conn, citk.dictionary, citk.ProductWindow,
  citk.customersWindow, citk.customers, citk.EventsWindow, citk.Events, 
citk.EventDetail, citk.eventdetailWindow, citk.Billing, citk.BillingWindow;

{$R *.res}

//type

  //{ TFoo }
  //
  //TFoo = class(TObject)
  //private
  //  FConnectionTestFunction: TConnectionTestFunction;
  //  function ConnectionTest(ChosenConfig: TDBConnectionConfig): boolean;
  //public
  //  constructor Create;
  //published
  //  property ConnectionTestCallback: TConnectionTestFunction write FConnectionTestFunction;
  //end;

procedure Log(const Texte: string);
begin
  glLogger.Log('citk',Texte);
end;

var
  Message: string;
  //LoginForm: TDBConfigForm;

//function TFoo.ConnectionTest(ChosenConfig: TDBConnectionConfig): boolean;
//begin
//
//end;

//constructor TFoo.Create;
//begin
//  ConnectionTestCallback:=@ConnectionTest;
//end;

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
      if Login(glGlobalInfo) then
      begin
        glGlobalInfo.Log(Format('User %s has LoggedIn', [glGlobalInfo.User.Login]));
        RunDatabaseScript(glGlobalInfo);
      end;
    except
      on E:EDatabaseConnection do
      begin
        glGlobalInfo.Log(E.Message);
        Message := Format('Database connection fails : %s. Trying to create the database or edit the Firebird Databases.conf file.', [glGlobalInfo.Values.Values['DatabaseName']]);
        MessageDlg(Message, mtInformation, [mbOk], 0);
        glGlobalInfo.Log(Message);
        try
          CreateDatabase(glGlobalInfo);
          Application.Terminate;
          Exit;
        except
          Application.Terminate;
          Exit;
        end;
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
      glGlobalInfo.Log(Format('User %s has LoggedIn', [glGlobalInfo.User.Login]));
      Application.CreateForm(TMainW, MainW);
      Application.CreateForm(TcitkDataModule, citkDataModule);
      MainW.Info := glGlobalInfo;
      Application.Run;
    end;

  except
    on E:Exception do
        Log(E.Message);
  end;
end.

