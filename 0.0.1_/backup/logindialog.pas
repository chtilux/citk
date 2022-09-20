unit logindialog;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, ExtCtrls, StdCtrls,
  EditBtn, ComCtrls, Buttons, citk.global, ZAbstractRODataset, ZDataset;

type

  { TLoginW }

  TLoginW = class(TForm)
    OkButton: TBitBtn;
    CancelButton: TBitBtn;
    ConfigButton: TBitBtn;
    DatabaseEdit: TEditButton;
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    PasswordEdit: TEditButton;
    RoleBox: TComboBox;
    StatusBar1: TStatusBar;
    UserNameEdit: TEditButton;
    procedure OkButtonClick(Sender: TObject);
    procedure ConfigButtonClick(Sender: TObject);
    procedure DatabaseEditButtonClick(Sender: TObject);
    procedure DatabaseEditKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure PasswordEditButtonClick(Sender: TObject);
    procedure PasswordEditEnter(Sender: TObject);
    procedure PasswordEditKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure UserNameEditButtonClick(Sender: TObject);
    procedure UserNameEditExit(Sender: TObject);
    procedure UserNameEditKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure UserNameEditKeyPress(Sender: TObject; var Key: char);
  private
    FInfo: TInfo;
    FLoggedIn: boolean;
    FLoginExists: boolean;
    FIsActive: boolean;
    pvSetPassword: boolean;
    procedure CheckUserName(const Login: string; var DefaultUserPassword: boolean);
    procedure SetIsActive(const Value: boolean);
    procedure SetLoginExists(const Value: boolean);
    function IsTuppleLoginPasswordValid(const Login, Password: string): boolean;
  public
    constructor Create(AOwner: TComponent; Info: TInfo); reintroduce; overload;
    property LoginExists: boolean read FLoginExists write SetLoginExists;
    property IsActive: boolean read FIsActive write SetIsActive;
    property LoggedIn: boolean read FLoggedIn default False;
    property Info: TInfo read FInfo;
  end;

implementation

{$R *.lfm}

uses
  Chtilux.Crypt, Inifiles, Windows, Dialogs;

{ TLoginW }

procedure TLoginW.DatabaseEditButtonClick(Sender: TObject);
begin
  //with TInifile.Create(FConnection.DBInfo.LocalFilename) do
  //begin
  //  try
  //    WriteString('USER','LOGIN',UserNameEdit.Text);
  //  finally
  //    Free;
  //  end;
  //end;
end;

procedure TLoginW.DatabaseEditKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
var
  entry, server: string;
  i: Integer;
begin
  if Key = VK_RETURN then
  begin
    Key := 0;
    if (TEDit(Sender).Modified) or True then
    begin
      entry := Trim(TEdit(Sender).Text);
      if CompareText(entry, Format('%s:%s',[Info.Server, Info.Alias])) <> 0 then
      begin
        if Info.Cnx.Connected then
          Info.Cnx.Disconnect;
        i := Pos(':', entry);
        if i > 0 then
        begin
          server := Copy(entry,1,Pred(i));
          Delete(entry,1,i);
          Info.Server := server;
          Info.Alias := entry;
          //Info.InitializeZConnection;
          //FConnection.Initialize(FConnection.Cnx, FConnection.DBInfo);
          UserNameEdit.Clear;
          PasswordEdit.Clear;
          UserNameEdit.SetFocus;
        end;
      end;
      TEdit(Sender).ReadOnly := True;
      TEdit(Sender).Enabled := False;
    end
    else
      //Perform(WM_NEXTDLGCTL,0,0);
      UserNameEdit.SetFocus;
  end;
end;

procedure TLoginW.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    80,112 : begin { p, P }
      if (Shift = [ssCtrl, ssShift]) then
      begin
        DatabaseEdit.ReadOnly := False;
        DatabaseEdit.Enabled := True;
        DatabaseEdit.SetFocus;
      end;
    end;
  end;
end;

procedure TLoginW.FormShow(Sender: TObject);
begin
  //if (UserNameEdit.Text <> '') and (PasswordEdit.Text <> '') and (RoleBox.Text <> '') then
  //begin
  //  OkButton.Enabled := True;
  //  OkButton.SetFocus;
  //end;
  if (DatabaseEdit.Text = '') then
     DatabaseEdit.SetFocus
  else
    UserNameEdit.SetFocus;
end;

procedure TLoginW.PasswordEditButtonClick(Sender: TObject);
begin
  if not string(PasswordEdit.Text).IsEmpty then
  begin
    with TIniFile.Create(Format('%s\%s_local.ini',[ExcludeTrailingPathDelimiter(Info.LocalPath), Info.Domain])) do
    begin
      try
        WriteString('USER','PASSWORD', EnCrypt(Info.Key, PasswordEdit.Text));
      finally
        Free;
      end;
    end;
  end;
end;

procedure TLoginW.PasswordEditEnter(Sender: TObject);
begin
  if pvSetPassword then
    MessageDlg('C''est votre première connexion. Vous devez indiquer un nouveau mot de passe.', TMsgDlgType.mtInformation, [mbOk], 0);
end;

procedure TLoginW.PasswordEditKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
var
  ConfirmPassword: string;
  z: TZReadOnlyQuery;
begin
  if Key = VK_RETURN then
  begin
    Key := 0;

    if pvSetPassword then
    begin
      ConfirmPassword := InputBox('Première connexion', 'Confirmez votre mot de passe', '').Trim.Substring(0,100);
      if (AnsiCompareStr(TEdit(Sender).Text, ConfirmPassword) <> 0) then
      begin
        MessageDlg('Mot de passe incorrect !', TMsgDlgType.mtError, [mbOk], 0);
        TEdit(Sender).Clear;
        Abort;
      end
      else
      begin
        z := TZReadOnlyQuery.Create(nil);
        try
          z.Connection := Info.Cnx;
          z.SQL.Add('UPDATE utilisateurs'
                   +' SET password = :password'
                   +' WHERE login = :login');
          z.Params[0].AsString := Encrypt(Info.Key, ConfirmPassword);
          z.Params[1].AsString := UserNameEdit.Text;
          z.ExecSQL;
        finally
          z.Free;
        end;
      end;
    end;

    if IsTuppleLoginPasswordValid(UserNameEdit.Text, PasswordEdit.Text) then
    begin
      OkButton.Enabled := True;

      OkButton.SetFocus;
    end;
  end;
end;

procedure TLoginW.UserNameEditButtonClick(Sender: TObject);
begin
  if not string(UserNameEdit.Text).IsEmpty then
  begin
    with TIniFile.Create(Format('%s\%s_local.ini',[ExcludeTrailingPathDelimiter(Info.LocalPath), Info.Domain])) do
    begin
      try
        WriteString('USER','LOGIN',UserNameEdit.Text);
      finally
        Free;
      end;
    end;
  end;
end;

procedure TLoginW.UserNameEditExit(Sender: TObject);
begin
  //if UserNameEdit.Modified then
    CheckUserName(Trim(TEdit(Sender).Text).ToUpper, pvSetPassword);
end;

procedure TLoginW.UserNameEditKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Key := 0;
    if (Trim(TEdit(Sender).Text) <> '')  then
      CheckUserName(Trim(TEdit(Sender).Text).ToUpper, pvSetPassword);
    //Perform(WM_NEXTDLGCTL,0,0);
    PasswordEdit.SetFocus;
  end;
end;

procedure TLoginW.UserNameEditKeyPress(Sender: TObject;
  var Key: char);
begin
  Key := UpCase(Key);
end;

procedure TLoginW.OkButtonClick(Sender: TObject);
begin
  if IsTuppleLoginPasswordValid(UserNameEdit.Text, PasswordEdit.Text) then
  begin
    Info.User.Login := UserNameEdit.Text;
    Info.User.Password := PasswordEdit.Text;
    ModalResult := mrOk;
  end;
end;

procedure TLoginW.ConfigButtonClick(Sender: TObject);
//var
//  F: TChtiluxDatabaseConfigW;
begin
  //F := TChtiluxDatabaseConfigW.Create(Self, FConnection);
  //try
  //  F.ShowModal;
  //finally
  //  F.Free;
  //end;
end;

procedure TLoginW.CheckUserName(const Login: string;
  var DefaultUserPassword: boolean);
var
  z: TZReadOnlyQuery;
const
  ORANGE = $000080FF;
  ExistActiveColor: array[Boolean,Boolean] of TColor = ((clRed, clGreen),(ORANGE, clGreen));
begin
  z := TZReadOnlyQuery.Create(Self);
  try
    z.Connection := Info.Cnx;
    z.SQL.Add('SELECT COUNT(*), active, password'
             +' FROM users'
             +' WHERE UPPER(login) = :login'
             +' GROUP BY active, password');
    z.Params[0].AsString := Copy(UserNameEdit.Text,1,8);
    z.Open;
    FLoginExists := z.Fields[0].AsInteger = 1;
    FIsActive := z.Fields[1].AsBoolean;
    //DefaultUserPassword := Decrypt(Info.Key, z.Fields[2].AsString) = Info.DefaultUserPassword;
    z.Close;
  finally
    z.Free;
  end;

  if FLoginExists then
  begin
    if not(FIsActive) then
      UserNameEdit.Text := Format('%s -> INACTIVE', [UserNameEdit.Text]);
  end;

  UserNameEdit.Color := ExistActiveColor[FLoginExists, FIsActive];
end;

procedure TLoginW.SetIsActive(const Value: boolean);
begin
  FIsActive:=Value;
end;

procedure TLoginW.SetLoginExists(const Value: boolean);
begin
  FLoginExists:=Value;
end;

function TLoginW.IsTuppleLoginPasswordValid(const Login,
  Password: string): boolean;
var
  z: TZReadOnlyQuery;
begin
  Result := False;
  z := TZReadOnlyQuery.Create(Self);
  try
    z.Connection := Info.Cnx;
    z.SQL.Add('SELECT COUNT(*), active FROM users'
             +' WHERE UPPER(login) = :login'
             +'   AND active = :active'
             +'   AND password = :password'
             +' GROUP BY active');
    z.Params[0].AsString := Copy(Login.Trim.ToUpper,1,8);
    z.Params[1].AsBoolean := True;
    z.Params[2].AsString := Copy(Encrypt(Info.Key, Password.Trim),1,100);
    z.Open;
    if z.Fields[0].AsInteger = 1 then
      Result := z.Fields[1].AsBoolean;
    z.Close;
  finally
    z.Free;
  end;
end;

constructor TLoginW.Create(AOwner: TComponent; Info: TInfo);
begin
  inherited Create(AOwner);
  FInfo := Info;;
  DatabaseEdit.Text := Format('%s:%s',[Info.Server, Info.Alias]);
  UserNameEdit.Text := Info.User.Login;
  PasswordEdit.Text := Info.User.Password;
end;

end.

