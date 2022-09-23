unit citk.BillingWindow;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, citk.Global;

type

  { TBillingW }

  TBillingW = class(TForm)
  private
    FEvent: integer;
    Finfo: TInfo;
    procedure SetEvent(AValue: integer);
    procedure Setinfo(AValue: TInfo);

  public
    constructor Create(AOwner: TComponent; Info: TInfo; const serevt: integer); reintroduce; overload;
    property info: TInfo read Finfo write Setinfo;
    property Event: integer read FEvent write SetEvent;
  end;

  procedure Billing(Info: TInfo; const serevt: integer);

var
  BillingW: TBillingW;

implementation

{$R *.lfm}

procedure Billing(Info: TInfo; const serevt: integer);
begin
  BillingW := TBillingW.Create(nil, Info, serevt);
  try
    BillingW.ShowModal;
  finally
    BillingW.Free;
  end;
end;

{ TBillingW }

procedure TBillingW.SetEvent(AValue: integer);
begin
  if FEvent=AValue then Exit;
  FEvent:=AValue;
end;

procedure TBillingW.Setinfo(AValue: TInfo);
begin
  if Finfo=AValue then Exit;
  Finfo:=AValue;
end;

constructor TBillingW.Create(AOwner: TComponent; Info: TInfo;
  const serevt: integer);
begin
  Finfo:=Info;
  FEvent:=serevt;
  inherited Create(AOwner);
  Caption := Event.ToString;
end;

end.

