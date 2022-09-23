unit citk.EventDetail;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

type
  IEventDetail = interface
  ['{62893291-B092-442F-B3E4-103A60F08FA9}']
    function GetSQL: string;
    function GetPKSQL: string;
    function GetProductsSQL: string;
    function GetNotSelectedProductsSQL: string;
  end;

  { TEventDetail }

  TEventDetail = class(TInterfacedObject, IEventDetail)
  public
    function GetSQL: string;
    function GetPKSQL: string;
    function GetProductsSQL: string;
    function GetNotSelectedProductsSQL: string;
  end;

implementation

{ TEventDetail }

function TEventDetail.GetSQL: string;
begin
  Result := 'SELECT serdet,serevt,numseq,serprd,libprd,price'
           +' FROM event_detail'
           +' WHERE serevt = :serevt'
           +' ORDER BY numseq';
end;

function TEventDetail.GetPKSQL: string;
begin
  Result := 'SELECT GEN_ID(seq_events,1) FROM rdb$database';
end;

function TEventDetail.GetProductsSQL: string;
begin
  Result := 'SELECT p.serprd,p.libprd,px.price'
           +' FROM products p LEFT JOIN prices px ON p.serprd = px.serprd'
           +' WHERE px.ptype = ''S'''
           +'   AND p.active = True'
           +'   AND px.dateff = '
           +'       (SELECT MAX(x.dateff) FROM prices x'
           +'          WHERE x.serprd = px.serprd'
           +'            AND x.dateff <= :dateff)'
           +' ORDER BY p.libprd';
end;

function TEventDetail.GetNotSelectedProductsSQL: string;
begin
  Result := 'SELECT p.serprd,p.libprd,px.price'
           +' FROM products p LEFT JOIN prices px ON p.serprd = px.serprd'
           +' WHERE px.ptype = ''S'''
           +'   AND p.active = True'
           +'   AND px.dateff = '
           +'       (SELECT MAX(x.dateff) FROM prices x'
           +'          WHERE x.serprd = px.serprd'
           +'            AND x.dateff <= :dateff)'
           +'   AND p.serprd NOT IN (SELECT z.serprd FROM event_detail z'
           +'                          WHERE z.serevt = :serevt)'
           +' ORDER BY p.libprd';
end;

end.

