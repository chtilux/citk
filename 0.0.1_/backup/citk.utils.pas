unit citk.utils;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms;

procedure ReadLastSizeAndPosition(Form: TForm);
procedure WriteCurrentSizeAndPosition(Form: TForm);

implementation

uses
  Chtilux.Utils;

procedure ReadLastSizeAndPosition(Form: TForm);
begin
  readFormPos(Form, nil);
end;

procedure WriteCurrentSizeAndPosition(Form: TForm);
begin
  writeFormPos(Form, nil);
end;

end.

