unit mainwindow;
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

interface

uses
  Classes, SysUtils, SQLDB, Forms, Controls, Graphics, Dialogs, ComCtrls,
  ExtCtrls,  Buttons, Menus, ActnList, RTTICtrls, citk.global;

type
  { TMainW }

  TMainW = class(TForm)
    MenuItem4: TMenuItem;
    ReportsAction: TAction;
    DailyRecapAction: TAction;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton10: TToolButton;
    ToolButton11: TToolButton;
    ToolButton12: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    ToolButton8: TToolButton;
    ToolButton9: TToolButton;
    VATAction: TAction;
    EventsAction: TAction;
    MenuItem1: TMenuItem;
    UsersAction: TAction;
    Separator2: TMenuItem;
    UsersMenuItem: TMenuItem;
    QuitApplicationAction: TAction;
    ProductsAction: TAction;
    CustomersAction: TAction;
    ApplicationDictionaryAction: TAction;
    citkActionList: TActionList;
    Logo: TImage;
    citkMainMenu: TMainMenu;
    FileMenuItem: TMenuItem;
    DictionaryMenuItem: TMenuItem;
    CustomersMenuItem: TMenuItem;
    Separator1: TMenuItem;
    ProductsMenuItem: TMenuItem;
    QuitMenuItem: TMenuItem;
    SB: TStatusBar;
    procedure ApplicationDictionaryActionExecute(Sender: TObject);
    procedure CustomersActionExecute(Sender: TObject);
    procedure DailyRecapActionExecute(Sender: TObject);
    procedure EventsActionExecute(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ProductsActionExecute(Sender: TObject);
    procedure QuitApplicationActionExecute(Sender: TObject);
    procedure ReportsActionExecute(Sender: TObject);
    procedure UsersActionExecute(Sender: TObject);
    procedure VATActionExecute(Sender: TObject);
  private
    FInfo: TInfo;
    procedure DisplayDictionary;
    procedure DisplayProducts;
    procedure DisplayCustomers;
    procedure DisplayEvents;
    procedure DisplayVAT;
    procedure DisplayDailyRecap;
    procedure DisplayUsers;
    procedure DisplayReports;
    procedure SetInfo(AValue: TInfo);
  public
    property Info: TInfo read FInfo write SetInfo;
  end;

var
  MainW: TMainW;

implementation

{$R *.lfm}

uses
  citk.utils, citk.dictionary, citk.ProductWindow, citk.customersWindow,
  citk.EventsWindow, citk.vat, citk.DailyRecapWindow, Chtilux.Utils,
  citk.Users, citk.Reports;

{ TMainW }

procedure TMainW.FormShow(Sender: TObject);
begin
  ReadLastSizeAndPosition(Sender as TForm);
end;

procedure TMainW.ProductsActionExecute(Sender: TObject);
begin
  DisplayProducts;
end;

procedure TMainW.QuitApplicationActionExecute(Sender: TObject);
begin
  Close;
end;

procedure TMainW.ReportsActionExecute(Sender: TObject);
begin
  DisplayReports;
end;

procedure TMainW.UsersActionExecute(Sender: TObject);
begin
  DisplayUsers;
end;

procedure TMainW.VATActionExecute(Sender: TObject);
begin
  DisplayVAT;
end;

procedure TMainW.FormDestroy(Sender: TObject);
begin
  WriteCurrentSizeAndPosition(Sender as TForm);
  Info.Log('Application terminated');
end;

procedure TMainW.SetInfo(AValue: TInfo);
begin
  if FInfo=AValue then Exit;
  FInfo:=AValue;
  Caption := Info.ApplicationDescription;
  SB.panels[1].Text := Info.User.Login;
  SB.Panels[2].Text := Info.Database;
  SB.Panels[3].Text :=Format('Release=%s',[Info.DatabaseRelease]);
  SB.Panels[4].Text := Format('AppVersion=%s',[GetAppVersion]);
end;

procedure TMainW.ApplicationDictionaryActionExecute(Sender: TObject);
begin
  DisplayDictionary;
end;

procedure TMainW.CustomersActionExecute(Sender: TObject);
begin
  DisplayCustomers;
end;

procedure TMainW.DailyRecapActionExecute(Sender: TObject);
begin
  DisplayDailyRecap;
end;

procedure TMainW.EventsActionExecute(Sender: TObject);
begin
  DisplayEvents;
end;

procedure TMainW.DisplayDictionary;
begin
  glGlobalInfo.Log('DisplayDictionary');
  citk.dictionary.DisplayDictionary;
end;

procedure TMainW.DisplayProducts;
begin
  glGlobalInfo.Log('DisplayProducts');
  citk.ProductWindow.DisplayProducts;
end;

procedure TMainW.DisplayCustomers;
begin
  glGlobalInfo.Log('DisplayCustomers');
  citk.CustomersWindow.DisplayCustomers;
end;

procedure TMainW.DisplayEvents;
begin
  glGlobalInfo.Log('DisplayEvents');
  citk.EventsWindow.DisplayEvents;
end;

procedure TMainW.DisplayVAT;
begin
  glGlobalInfo.Log('DisplayVAT');
  citk.vat.DisplayVAT;
end;

procedure TMainW.DisplayDailyRecap;
begin
  glGlobalInfo.Log('DisplayDailyRecap');
  citk.DailyRecapWindow.DisplayDailyRecap(glGlobalInfo);
end;

procedure TMainW.DisplayUsers;
begin
  glGlobalInfo.Log('DisplayUsers');
  citk.Users.DisplayUsers;
end;

procedure TMainW.DisplayReports;
begin
  glGlobalInfo.Log('DisplayReports');
  citk.Reports.DisplayReports;
end;

end.

