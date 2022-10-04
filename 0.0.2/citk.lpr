/// citk project unit
// licensed under a MPL/GPL/LGPL tri-license; version 1.18
program citk;
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
  citk.Events, citk.EventDetail, citk.eventdetailWindow,
  citk.BillingWindow, IBConnection, citk.products, citk.vat, citk.VATWindow,
  citk.bill, citk.Output, citk.PDFOutput, citk.DataObject,
  citk.DailyrecapWindow, citk.DailyRecap, citk.Users, citk.Reports, 
citk.ReportsWindow;

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

