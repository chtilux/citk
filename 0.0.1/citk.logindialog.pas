unit citk.loginDialog;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  StdCtrls, EditBtn, Buttons, citk.global;

type

  { TLoginW }

  TLoginW = class(TForm)
    OkButton: TBitBtn;
    CancelButton: TBitBtn;
    DatabaseEdit: TEditButton;
    UserNameEdit: TEditButton;
    PasswordEdit: TEditButton;
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    StatusBar1: TStatusBar;
  private
    FInfo: TInfo;
    procedure SetInfo(AValue: TInfo);

  public
    constructor Create(AOwner: TComponent; Info: TInfo); reintroduce; overload;
    property Info: TInfo read FInfo write SetInfo;
  end;

implementation

{$R *.lfm}

{ TLoginW }

procedure TLoginW.SetInfo(AValue: TInfo);
begin
  if FInfo=AValue then Exit;
  FInfo:=AValue;
end;

constructor TLoginW.Create(AOwner: TComponent; Info: TInfo);
begin
  inherited Create(AOwner);
  Self.Info := Info;
end;

end.

