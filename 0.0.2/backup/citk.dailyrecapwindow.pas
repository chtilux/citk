unit citk.DailyRecapWindow;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ActnList, StdCtrls,
  Menus, citk.DataGridForm, citk.Global;

type

  { TDailyRecapW }

  TDailyRecapW = class(TDataGridForm)
    Button1: TButton;
    GetDailyRecapAction: TAction;
    ActionList1: TActionList;
    MenuItem1: TMenuItem;
    PopupMenu1: TPopupMenu;
    procedure ActionList1Update(AAction: TBasicAction; var Handled: Boolean);
    procedure GetDailyRecapActionExecute(Sender: TObject);
  private
    procedure GetDailyRecap(const datbill: TDate);
  public

  end;

  procedure DisplayDailyRecap(Info: TInfo);

implementation

uses
  citk.DailyRecap, SQLDB, citk.DataObject, citk.Output, citk.dictionary;

procedure DisplayDailyRecap(Info: TInfo);
var
  F: TDailyRecapW;
  Q: TSQLQuery;
  dao: IDataObject;
  dlr: IDailyRecap;
begin
  Q := nil;
  F := TDailyRecapW.Create(nil, Info);
  try
    dao := TFirebirdDataObject.Create(Info.Cnx, Info.Transaction);
    Q := dao.GetQuery;
    dlr := TDailyRecap.Create;
    Q.SQL.Add(dlr.GetSQL);
    Q.Open;
    F.Query:=Q;
    F.ShowModal;
  finally
    F.Free;
    Q.Free;
  end;
end;

{$R *.lfm}

uses
  ShellApi;

{ TDailyRecapW }

procedure TDailyRecapW.GetDailyRecapActionExecute(Sender: TObject);
begin
  GetDailyRecap(Query.Fields[0].AsDateTime);
end;

procedure TDailyRecapW.ActionList1Update(AAction: TBasicAction;
  var Handled: Boolean);
begin
  GetDailyRecapAction.Enabled:=not Query.EOF;
  Handled := True;
end;

procedure TDailyRecapW.GetDailyRecap(const datbill: TDate);
var
  dao: IDataObject;
  dlr: IDailyRecap;
  otp: IOutput;
  dic: IDictionary;
begin
  dao := TFirebirdDataObject.Create(Info.Cnx, Info.Transaction);
  dlr := TDailyRecap.Create(dao);
  otp := TDailyRecapOutput.Create;
  dic := TDictionary.Create(dao);
  otp.OutputDirectory:=dic.GetOutputDirectory;
  dlr.Print(datbill, otp);
  Info.Log(Format('Daily recap due date %s generated to %s',[DateToStr(datbill),otp.OutputDirectory]));
  ShellExecute(0,'open',PChar(otp.OutputDirectory),nil,nil,1);
end;

end.

