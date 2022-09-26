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
  citk.DataModule, citk.DataGridForm, sqldb, db, citk.dictionary,
  citk.ProductWindow, citk.customersWindow, citk.customers, citk.EventsWindow,
  citk.Events, citk.EventDetail, citk.eventdetailWindow, citk.Billing,
  citk.BillingWindow, IBConnection, citk.products, citk.vat, citk.VATWindow,
  citk.bill, citk.Output, citk.PDFOutput, citk.DataObject,
  citk.DailyrecapWindow, citk.DailyRecap;

{$R *.res}

procedure Log(const Texte: string);
begin
  glLogger.Log('citk',Texte);
end;

function IsDebuggerPresent () : integer stdcall; external 'kernel32.dll';

//var
//  dao: IDataObject;
//  bill: IBills;

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;

  glLogger := TTextFileLogger.Create;
  glGlobalInfo.Logger := glLogger;
  InitGlobalInfo(glGlobalInfo);
  InitDatabase(glCnx, glGlobalInfo);
  try
    { essai de connexion à la base de données }
    ConnectDatabase(glCnx, glGlobalInfo);
  except
    on E:EIBDatabaseError do
    begin
      { la base n'existe pas }
      if Pos('Error while trying to open file',E.Message)>0 then
      begin
        Log(E.Message);
        Log('Trying to create database.');
        CreateDatabase(glGlobalInfo);
        Log('Database created.');
        ConnectDatabase(glCnx, glGlobalInfo);
      end
      else
      begin
        raise;
      end;
    end;
  end;

  if GlCnx.Connected then
  begin
    try
      Application.Initialize;
      if IsDebuggerPresent = 1 then
      begin
        //dao := TFirebirdDataObject.Create(glGlobalInfo.Cnx, glGlobalInfo.Transaction);
        //bill := TBills.Create(dao);
        //bill.Print(104, TBillOutput.Create);
        Login(glGlobalInfo);
      end
      else
        Login(glGlobalInfo);
    except
      on E:EIBDatabaseError do
      begin
      end
      else
        raise;
    end;
  end;

  if glGlobalInfo.LoggedIn then
  begin
    glGlobalInfo.Log(Format('User %s has LoggedIn', [glGlobalInfo.User.Login]));
    RunDatabaseScript(glGlobalInfo);
    Application.CreateForm(TMainW, MainW);
    Application.CreateForm(TcitkDataModule, citkDataModule);
    MainW.Info := glGlobalInfo;
    Application.Run;
  end;
end.

