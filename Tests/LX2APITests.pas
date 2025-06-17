unit LX2APITests;

interface

uses
  System.SysUtils, System.Classes,
  DUnitX.TestFramework;

type
  [TestFixture]
  TXMLHelpersTest = class
  public
    [SetupFixture]
    procedure Setup;
    [Test]
    procedure TestCreateEmptyDoc;
    [Test]
    procedure TestCreateDocFromStr;
    [Test]
    procedure TestCreateDocFromBytes;
    [Test]
    procedure TestCreateDocFromMem;
    [Test]
    procedure TestCreateDocFromFile;
    [Test]
    procedure TestCreateDocFromStream;
  end;

implementation

uses
  libxml2.API, LX2.Helpers;

const
  XmlPreamble = '<?xml version="1.0" encoding="UTF-8"?>';

procedure TXMLHelpersTest.Setup;
begin
  if not LX2Lib.IsLoaded then
    LX2Lib.Load('..\..\..\Binaries\Win64\libxml2.dll');
end;

procedure TXMLHelpersTest.TestCreateEmptyDoc;
begin
  var doc := xmlDoc.Create;
  Assert.AreNotEqual<Pointer>(doc, nil);
  if doc <> nil then
    Assert.AreEqual<RawByteString>(XmlPreamble, Trim(doc.Xml));
  xmlFreeDoc(doc);
end;

procedure TXMLHelpersTest.TestCreateDocFromStr;
begin
  var doc := xmlDoc.Create('<root/>', []);
  Assert.AreNotEqual<Pointer>(doc, nil);
  if doc <> nil then
    Assert.AreEqual<RawByteString>(XmlPreamble + #10 + '<root/>', Trim(doc.Xml));
  xmlFreeDoc(doc);
end;

procedure TXMLHelpersTest.TestCreateDocFromBytes;
begin
  var doc := xmlDoc.Create(BytesOf('<root/>'), []);
  Assert.AreNotEqual<Pointer>(doc, nil);
  if doc <> nil then
    Assert.AreEqual<RawByteString>(XmlPreamble + #10 + '<root/>', Trim(doc.Xml));
  xmlFreeDoc(doc);
end;

procedure TXMLHelpersTest.TestCreateDocFromMem;
var
  S: RawByteString;
begin
  S := '<root/>';
  var doc := xmlDoc.Create(Pointer(S), Length(S), []);
  Assert.AreNotEqual<Pointer>(doc, nil);
  if doc <> nil then
    Assert.AreEqual<RawByteString>(XmlPreamble + #10 + '<root/>', Trim(doc.Xml));
  xmlFreeDoc(doc);
end;

procedure TXMLHelpersTest.TestCreateDocFromStream;
var
  Stream: TStream;
var
  S: RawByteString;
begin
  S := '<root/>';
  Stream := TMemoryStream.Create;
  try
    Stream.Write(Pointer(S)^, Length(S));
    Stream.Position := 0;

    var doc := xmlDoc.Create(Stream, [], 'UTF-8');
    Assert.AreNotEqual<Pointer>(doc, nil);
    if doc <> nil then
      Assert.AreEqual<RawByteString>(XmlPreamble + #10 + '<root/>', Trim(doc.Xml));
    xmlFreeDoc(doc);
  finally
    Stream.Free;
  end;
end;

procedure TXMLHelpersTest.TestCreateDocFromFile;
begin
  var doc := xmlDoc.CreateFromFile(ExpandFileName('..\..\root.xml'), []);
  if doc <> nil then
    Assert.AreEqual<RawByteString>(XmlPreamble + #10 + '<root/>', Trim(doc.Xml));
  xmlFreeDoc(doc);
end;

initialization
  TDUnitX.RegisterTestFixture(TXMLHelpersTest);

end.
