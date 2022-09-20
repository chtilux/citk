unit citk.Globals;

{$mode ObjFPC}{$H+}

interface


uses
  Classes, SysUtils, Chtilux.Logger, citk.globals, ZConnection;

var
  glLogger: ILogger;
  glGlobalInfo: TInfo;
  glCnx: TZConnection;

const
  DOMAIN = 'CelineInTheKitchen';

implementation

initialization
  glGlobalInfo := TInfo.Create(DOMAIN);
  glCnx := TZConnection.Create(nil);

finalization
  glGlobalInfo.Free;
  if glCnx.Connected then
    glCnx.Disconnect;
  glCnx.Free;

end.

