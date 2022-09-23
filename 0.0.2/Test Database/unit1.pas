unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SQLDB, IBConnection, Forms, Controls, Graphics, Dialogs,
  StdCtrls;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Cnx: TIBConnection;
    Charset: TEdit;
    DatabaseName: TEdit;
    HostName: TEdit;
    Password: TEdit;
    SQLTransaction1: TSQLTransaction;
    UserName: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    procedure Button1Click(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
begin
  Cnx.CharSet:=Charset.Text;
  Cnx.HostName:=HostName.Text;
  Cnx.DatabaseName:=DatabaseName.Text;
  Cnx.UserName:=UserName.Text;
  Cnx.Password:=Password.Text;
  Cnx.CreateDB;
end;

end.

