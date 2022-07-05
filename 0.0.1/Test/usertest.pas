unit UserTest;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry, citk.user, citk.encrypter;

type

  { TUserTest }

  TUserTest= class(TTestCase)
  published
    procedure TestEncryptValueEncrypterDoesNothing;
    procedure TestDecryptValueEncrypterDoesNothing;
    procedure TestEncryptValueEncrypterIsDCP;
    procedure TestDecryptValueEncrypterIsDCP;
  end;

implementation

const
  ValueToEncrypt = 'scraps';
  PublicKey = 'toto';

{ TUserTest }

procedure TUserTest.TestEncryptValueEncrypterDoesNothing;
var
  EncryptedValue: string;
  Encrypter: IEncrypter;
begin
  Encrypter := TEncrypter.Create;
  EncryptedValue:=Encrypter.Encrypt(ValueToEncrypt);
  AssertEquals(ValueToEncrypt, EncryptedValue);
end;

procedure TUserTest.TestDecryptValueEncrypterDoesNothing;
var
  EncryptedValue,
  DecryptedValue: string;
  Encrypter: IEncrypter;
begin
  Encrypter := TEncrypter.Create;
  EncryptedValue:=Encrypter.Encrypt(ValueToEncrypt);
  DecryptedValue:=Encrypter.Decrypt(EncryptedValue);
  AssertEquals(ValueToEncrypt, DecryptedValue);
end;

procedure TUserTest.TestEncryptValueEncrypterIsDCP;
var
  EncryptedValue: string;
  Encrypter: IEncrypter;
begin
  Encrypter := TEncrypter.Create(PublicKey);
  EncryptedValue:=Encrypter.Encrypt(ValueToEncrypt);
  AssertFalse(ValueToEncrypt=EncryptedValue);
end;

procedure TUserTest.TestDecryptValueEncrypterIsDCP;
var
  EncryptedValue: string;
  DecryptedValue: string;
  Encrypter: IEncrypter;
begin
  Encrypter := TEncrypter.Create(PublicKey);
  EncryptedValue:=Encrypter.Encrypt(ValueToEncrypt);
  DecryptedValue:=Encrypter.Decrypt(EncryptedValue);
  AssertEquals(ValueToEncrypt,DecryptedValue);
end;

initialization
  RegisterTest(TUserTest);
end.

