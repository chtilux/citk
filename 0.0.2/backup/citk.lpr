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
  runtimetypeinfocontrols, datetimectrls,Controls,
  { you can add units after this }
  citk.global, citk.Database, Chtilux.Logger, citk.firebird, citk.login,
  citk.loginDialog, citk.utils, citk.user, citk.persistence, citk.encrypt,
  citk.DataModule, citk.DataGridForm,
  //citk.dbconfiggui, citk.dbconfig,
  {General db unit}sqldb,
  {For EDataBaseError}db,
  {Now we add all databases we want to support, otherwise their drivers won't be loaded}
  IBConnection,pqconnection,sqlite3conn, citk.dictionary, citk.ProductWindow;

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
        Message := Format('Database fails : %s. Create the database or edit the Firebird Databases.conf file.', [glGlobalInfo.Values.Values['DatabaseName']]);
        MessageDlg(Message, mtInformation, [mbOk], 0);
        glGlobalInfo.Log(Message);
        Application.Terminate;
        //{ affiche la fenêtre de connexion standard }
        //LoginForm := TDBConfigForm.Create(nil);
        //try
        //  LoginForm.ConnectionTestCallback:=nil;
        //  LoginForm.ConnectorType.Clear; //remove any default connectors
        //  // Now add the dbs that you support - use the name of the *ConnectionDef.TypeName property
        //  LoginForm.ConnectorType.AddItem('Firebird', nil);
        //  LoginForm.ConnectorType.AddItem('PostGreSQL', nil);
        //  LoginForm.ConnectorType.AddItem('SQLite3', nil); //No connectiondef object yet in FPC2.6.0
        //  case LoginForm.ShowModal of
        //  mrOK:
        //    begin
        //      //user wants to connect, so copy over db info
        //      glCnx.ConnectorType:=LoginForm.Config.DBType;
        //      glCnx.HostName:=LoginForm.Config.DBHost;
        //      glCnx.DatabaseName:=LoginForm.Config.DBPath;
        //      glCnx.UserName:=LoginForm.Config.DBUser;
        //      glCnx.Password:=LoginForm.Config.DBPassword;
        //      glCnx.Transaction:=glTrx;
        //    end;
        //  mrCancel:
        //    begin
        //      ShowMessage('You canceled the database login. Application will terminate.');
        //      Application.Terminate;
        //    end;
        //  end;
        //finally
        //  LoginForm.Free;
        //end;
        //glGlobalInfo.Log('Trying to create database');
        //CreateDatabase(glCnx, glGlobalInfo);
        //RunDatabaseScript(glGlobalInfo);
        //Message := Format('Database created : %s. Edit the Firebird Databases.conf file.', [glGlobalInfo.Values.Values['DatabaseName']]);
        //MessageDlg(Message, mtInformation, [mbOk], 0);
        //glGlobalInfo.Log(Message);
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
      Application.Run;
    end;

  except
    on E:Exception do
        Log(E.Message);
  end;
end.

