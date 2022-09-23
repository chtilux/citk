unit mainwindow;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SQLDB, Forms, Controls, Graphics, Dialogs, ComCtrls,
  ExtCtrls,  Buttons, Menus, ActnList, RTTICtrls, citk.global;

type
  { TMainW }

  TMainW = class(TForm)
    EventsAction: TAction;
    MenuItem1: TMenuItem;
    SQLQuery1: TSQLQuery;
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
    procedure EventsActionExecute(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ProductsActionExecute(Sender: TObject);
    procedure QuitApplicationActionExecute(Sender: TObject);
  private
    FInfo: TInfo;
    procedure DisplayDictionary;
    procedure DisplayProducts;
    procedure DisplayCustomers;
    procedure DisplayEvents;
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
  citk.EventsWindow;

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

procedure TMainW.FormDestroy(Sender: TObject);
begin
  WriteCurrentSizeAndPosition(Sender as TForm);
  Info.Log('Application terminated');
end;

procedure TMainW.FormResize(Sender: TObject);
begin
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

end.

