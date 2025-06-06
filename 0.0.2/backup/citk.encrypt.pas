unit citk.encrypt;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

type
  IEncrypter = interface
    ['{C994BB10-C9A4-4584-8EF1-6B2B2D8F654D}']
    function Encrypt(const Value: string): string;
    function Decrypt(const Value: string): string;
    function GetPublicKey: string;
    procedure SetPublicKey(AValue: string);
    property PublicKey: string read GetPublicKey write SetPublicKey;
  end;

  { TEncrypter }

  TEncrypter = class(TInterfacedObject, IEncrypter)
  private
    FPublicKey: string;
    function GetPublicKey: string;
    procedure SetPublicKey(AValue: string);
  public
    constructor Create; virtual; overload;
    constructor Create(const PublicKey: string); virtual; overload;
    function Encrypt(const Value: string): string;
    function Decrypt(const Value: string): string;
    property PublicKey: string read GetPublicKey write SetPublicKey;
  end;

implementation

uses
  Chtilux.Crypt;

{ TEncrypter }

procedure TEncrypter.SetPublicKey(AValue: string);
begin
  if FPublicKey=AValue then Exit;
  FPublicKey:=AValue;
end;

function TEncrypter.GetPublicKey: string;
begin
  Result := FPublicKey;
end;

constructor TEncrypter.Create;
begin
  FPublicKey:='';
end;

constructor TEncrypter.Create(const PublicKey: string);
begin
  FPublicKey:=PublicKey;
end;

function TEncrypter.Encrypt(const Value: string): string;
begin
  if FPublicKey.IsEmpty then
    Result := Value
  else
    Result := Chtilux.Crypt.EnCrypt(FPublicKey, Value);
end;

function TEncrypter.Decrypt(const Value: string): string;
begin
  if FPublicKey.IsEmpty then
    Result := Value
  else
    Result := Chtilux.Crypt.DeCrypt(FPublicKey, Value);
end;

end.

