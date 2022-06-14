unit mainwindow;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  citk.global;

type

  { TMainW }

  TMainW = class(TForm)
    Logo: TImage;
    SB: TStatusBar;
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
  Chtilux.Utils;

{ TMainW }

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

