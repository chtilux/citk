unit citk.Output;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, SQLDB;

type
  IOutput = interface
  ['{C5D33B4A-7555-4AF3-9405-51DB6EC1181E}']
    procedure Print(master, detail, vat, customer: TSQLQuery);
  end;

implementation

end.

