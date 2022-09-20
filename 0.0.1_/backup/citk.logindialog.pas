unit citk.loginDialog;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  StdCtrls, EditBtn, Buttons, citk.global, citk.user;

type

  { TLoginW }

  TLoginW = class(TForm)
    OkButton: TBitBtn;
    CancelButton: TBitBtn;
    DatabaseEdit: TEditButton;
    UserActiveLabel: TLabel;
    PasswordMustBeSetLabel: TLabel;
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
    procedure FormShow(Sender: TObject);
    procedure UserNameEditKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure OkButtonClick(Sender: TObject);
    procedure PasswordEditButtonClick(Sender: TObject);
    procedure PasswordEditEnter(Sender: TObject);
    procedure PasswordEditKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure UserNameEditButtonClick(Sender: TObject);
  private
    FInfo: TInfo;
    FLoggedIn: boolean;
    FLoginExists: boolean;
    FIsActive: boolean;
    FPasswordMustBeSet: boolean;
    //pvSetPassword: boolean;

    procedure SetInfo(AValue: TInfo);
    //procedure CheckUserName(const Login: string; var DefaultUserPassword: boolean); overload;
    procedure CheckUserName(const Login: string; var LoginExists, UserIsActive: boolean; out UserMustSetPassword: boolean);
    function GetUsersHelper: TUsers;
    procedure SetIsActive(const Value: boolean);
    procedure SetLoginExists(const Value: boolean);
    procedure SetPasswordMustBeSet(AValue: boolean);
  public
    constructor Create(AOwner: TComponent; Info: TInfo); reintroduce; overload;
    property Info: TInfo read FInfo write SetInfo;
    property LoginExists: boolean read FLoginExists write SetLoginExists;
    property IsActive: boolean read FIsActive write SetIsActive;
    property PasswordMustBeSet: boolean read FPasswordMustBeSet write SetPasswordMustBeSet;
    property LoggedIn: boolean read FLoggedIn default False;
  end;

implementation

{$R *.lfm}

uses
  Inifiles, Chtilux.Crypt, ZDataset, Windows, citk.persistence;

{ TLoginW }

constructor TLoginW.Create(AOwner: TComponent; Info: TInfo);
begin
  inherited Create(AOwner);
  Self.Info := Info;
  Self.PasswordEdit.PasswordChar:=Info.PasswordChar;
end;

procedure TLoginW.SetInfo(AValue: TInfo);
begin
  if FInfo=AValue then Exit;
  FInfo:=AValue;
  DatabaseEdit.Text:=FInfo.Database;
  UserNameEdit.Text:=FInfo.User.Login;
  PasswordEdit.Text:=FInfo.User.Password;
  UserActiveLabel.Caption := '';
  PasswordMustBeSetLabel.Caption := '';
end;

procedure TLoginW.FormShow(Sender: TObject);
begin
  UserNameEdit.SetFocus;
end;

procedure TLoginW.UserNameEditButtonClick(Sender: TObject);
begin
  if not string(UserNameEdit.Text).IsEmpty then
  begin
    with TIniFile.Create(Format('%s\%s_local.ini',[ExcludeTrailingPathDelimiter(Info.LocalPath),Info.Domain])) do
    begin
      try
        WriteString('USER','LOGIN',UserNameEdit.Text);
      finally
        Free;
      end;
    end;
  end;
end;

procedure TLoginW.UserNameEditKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  UserLoginExists,
  UserIsActive,
  UserMustSetPassword: boolean;
begin
  if Key = VK_RETURN then
  begin
    Key := 0;
    if (Trim(TEdit(Sender).Text) <> '')  then
    begin
      UserLoginExists:=False;
      UserIsActive:=False;
      UserMustSetPassword:=False;
      CheckUserName(Trim(TEdit(Sender).Text), UserLoginExists, UserIsActive, UserMustSetPassword);
      if UserLoginExists then
      begin
        IsActive:=UserIsActive;
        PasswordMustBeSet:=UserMustSetPassword;
        PasswordEdit.SetFocus;
      end;
    end;
  end;
end;

procedure TLoginW.CheckUserName(const Login: string; var LoginExists, UserIsActive: boolean; out UserMustSetPassword: boolean);
var
  user: IUserInfo;
begin
  user := TUserInfo.Create(Login,'');
  LoginExists := GetUsersHelper.LoginExists(user);
  if LoginExists then
  begin;
    UserIsActive := user.Active;
    UserMustSetPassword := user.UserMustSetPassword;
  end;
end;

function TLoginW.GetUsersHelper: TUsers;
begin
  Result := TUsers.Create(TFirebirdPersistence.Create(Info.Cnx, Info.Crypter));
end;

procedure TLoginW.PasswordEditEnter(Sender: TObject);
begin
  if PasswordMustBeSet then
    MessageDlg('You connect for the first time or you reset your password. Input your password.', TMsgDlgType.mtInformation, [mbOk], 0);
end;

procedure TLoginW.PasswordEditButtonClick(Sender: TObject);
begin
  if not string(PasswordEdit.Text).IsEmpty then
  begin
    with TIniFile.Create(Format('%s\%s_local.ini',[ExcludeTrailingPathDelimiter(Info.LocalPath),Info.Domain])) do
    begin
      try
        WriteString('USER','PASSWORD', Info.Crypter.Encrypt(PasswordEdit.Text));
      finally
        Free;
      end;
    end;
  end;
end;

procedure TLoginW.PasswordEditKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  ConfirmPassword: string;
  user: IUserInfo;
  helper: IUsers;
begin
  if Key = VK_RETURN then
  begin
    Key := 0;
    helper := nil;
    if PasswordMustBeSet then
    begin
      ConfirmPassword := InputBox('Setting password.', 'Confirm your password.', '').Trim.Substring(0,100);
      { confirmation du mot de passe incorrecte ou mot de passe identique à la clé publique }
      if (AnsiCompareStr(TEdit(Sender).Text, ConfirmPassword) <> 0) or (AnsiCompareStr(TEdit(Sender).Text, Info.Key)=0) then
      begin
        MessageDlg('Wrong password !', TMsgDlgType.mtError, [mbOk], 0);
        TEdit(Sender).Clear;
        Abort;
      end
      else
      begin
        helper := GetUsersHelper;
        user := TUserInfo.Create(UserNameEdit.Text, PasswordEdit.Text);
        LoginExists := helper.LoginExists(user);
        if LoginExists then
          helper.SetUserPassword(user, Info.Crypter);
      end;
    end;

    { Lecture du mot de passe }
    if not Assigned(helper) then
      helper := GetUsersHelper;
    user := TUserInfo.Create(UserNameEdit.Text, PasswordEdit.Text);
    if helper.LoginPasswordIsValid(User) then
    begin
      if User.Active then
      begin
        OkButton.Enabled := True;
        OKButton.SetFocus;
      end;
    end;
  end;
end;

procedure TLoginW.OkButtonClick(Sender: TObject);
begin
  Info.User.Login := UserNameEdit.Text;
  Info.User.Password := PasswordEdit.Text;
  ModalResult := mrOk;
end;

//procedure TLoginW.CheckUserName(const Login: string;
//  var DefaultUserPassword: boolean);
//var
//  z: TZReadOnlyQuery;
//const
//  ORANGE = $000080FF;
//  ExistActiveColor: array[Boolean,Boolean] of TColor = ((clRed, clGreen),(ORANGE, clGreen));
//begin
//  z := TZReadOnlyQuery.Create(Self);
//  try
//    z.Connection := Info.Cnx;
//    z.SQL.Add('SELECT COUNT(*), active, password'
//             +' FROM users'
//             +' WHERE UPPER(login) = :login'
//             +' GROUP BY active, password');
//    z.Params[0].AsString := Copy(Login,1,8);
//    z.Open;
//    FLoginExists := z.Fields[0].AsInteger = 1;
//    FIsActive := z.Fields[1].AsBoolean;
//    DefaultUserPassword := Decrypt(Info.Key, z.Fields[2].AsString) = Info.DefaultUserPassword;
//    z.Close;
//  finally
//    z.Free;
//  end;
//
//  if FLoginExists then
//  begin
//    if not(FIsActive) then
//      UserNameEdit.Text := Format('%s -> INACTIVE', [UserNameEdit.Text]);
//  end;
//
//  UserNameEdit.Color := ExistActiveColor[FLoginExists, FIsActive];
//end;

procedure TLoginW.SetIsActive(const Value: boolean);
const
  UserActive: array[Boolean] of string = ('in','');
begin
  FIsActive:=Value;
  UserActiveLabel.Caption := Format('User is %sactive', [UserActive[FIsActive]]);;
end;

procedure TLoginW.SetLoginExists(const Value: boolean);
begin
  FLoginExists:=Value;
end;

procedure TLoginW.SetPasswordMustBeSet(AValue: boolean);
const
  UserPassword: array[Boolean] of string = ('','Password must be set.');
begin
  PasswordMustBeSetLabel.Caption := UserPassword[AValue];
  if FPasswordMustBeSet=AValue then Exit;
  FPasswordMustBeSet:=AValue;
end;

end.

