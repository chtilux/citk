unit citk.Events;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

type
  IEvents = interface
  ['{911722B3-BE0F-4314-9B27-952D4013CF20}']
    function GetSQL: string;
    function GetPKSQL: string;
    function GetEventSQL: string;
    function GetDetailSQL: string;
  end;

  { TEvents }

  TEvents = class(TInterfacedObject, IEvents)
  public
    function GetSQL: string;
    function GetPKSQL: string;
    function GetEventSQL: string;
    function GetDetailSQL: string;
  end;

implementation

{ TEvents }

function TEvents.GetSQL: string;
begin
  Result := 'SELECT serevt, begevt, endevt, libevt, active'
           +' FROM event'
           +' ORDER BY begevt DESC, endevt DESC';
end;

function TEvents.GetPKSQL: string;
begin
  Result := 'SELECT GEN_ID(SEQ_EVENTS,1) FROM rdb$database';
end;

function TEvents.GetEventSQL: string;
begin
  Result := 'SELECT serevt, begevt, endevt, libevt, active'
           +' FROM event'
           +' WHERE serevt = :serevt';
end;

function TEvents.GetDetailSQL: string;
begin
  Result := 'SELECT libprd, price'
           +' FROM event_detail d'
           +' WHERE serevt = :serevt'
           +' ORDER BY numseq';
end;

end.

