unit mainwindow;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SQLDB, IBConnection, Forms, Controls, Graphics, Dialogs,
  ComCtrls, ExtCtrls, StdCtrls, Buttons, Menus, ActnList, RTTICtrls,
  citk.global, citk.DataModule;

type
  { TMainW }

  TMainW = class(TForm)
    SQLConnector1: TSQLConnector;
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
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure QuitApplicationActionExecute(Sender: TObject);
    procedure SQLConnector1AfterConnect(Sender: TObject);
  private
    FInfo: TInfo;
    procedure SetInfo(AValue: TInfo);
  public
    property Info: TInfo read FInfo write SetInfo;
  end;

var
  MainW: TMainW;

implementation

{$R *.lfm}

uses
  citk.utils;

{ TMainW }

procedure TMainW.FormShow(Sender: TObject);
begin
  ReadLastSizeAndPosition(Sender as TForm);
end;

procedure TMainW.QuitApplicationActionExecute(Sender: TObject);
begin
  Close;
end;

procedure TMainW.SQLConnector1AfterConnect(Sender: TObject);
begin

end;

procedure TMainW.FormDestroy(Sender: TObject);
begin
  WriteCurrentSizeAndPosition(Sender as TForm);
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

end.
