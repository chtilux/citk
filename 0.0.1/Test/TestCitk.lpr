program TestCitk;

{$mode objfpc}{$H+}

uses
  Interfaces, Forms, zcomponent, GuiTestRunner, UserTest, citk.user;

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TGuiTestRunner, TestRunner);
  Application.Run;
end.

