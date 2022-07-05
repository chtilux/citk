unit citk.DataModule;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Controls;

type

  { TcitkDataModule }

  TcitkDataModule = class(TDataModule)
    citk16ImageList: TImageList;
  private

  public

  end;

var
  citkDataModule: TcitkDataModule;

implementation

{$R *.lfm}

end.

