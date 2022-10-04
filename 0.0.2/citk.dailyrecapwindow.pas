unit citk.DailyRecapWindow;
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
  citk.DailyRecap, SQLDB, citk.DataObject, citk.Output, citk.dictionary,
  ShellApi;

{$R *.lfm}

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
  otp.Dic:=dic;
  otp.OutputDirectory:=dic.GetOutputDirectory;
  dlr.Print(datbill, otp);
  Info.Log(Format('Daily recap due date %s generated to %s',[DateToStr(datbill),otp.OutputDirectory]));
  ShellExecute(0,'open',PChar(otp.OutputDirectory),nil,nil,1);
end;

end.

