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
    [Test]
    procedure TestSelectSingleNodeEmptyResultDoesNotLeak;
    [Test]
    procedure TestSelectSingleNodeResolvesNamespacesInScope;
    [Test]
    procedure TestGetElementsByTagNameWalksTheWholeSubtree;
    [Test]
    procedure TestXPathSeesPrefixesDeclaredOnAncestors;
  end;

implementation

uses
  libxml2.API, LX2.Helpers;

const
  XmlPreamble = '<?xml version="1.0" encoding="UTF-8"?>';

procedure TXMLHelpersTest.Setup;
begin
  LX2Lib.Initialize; // static binding through LX2.Static in the project uses
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

// Issue #5: an XPath query that is valid but selects nothing left the xmlXPathObject
// unreleased. LX2Lib.Load installs the libxml2 debug allocator, so xmlMemUsed counts
// every byte the library holds: it must not grow across a query with an empty result.
procedure TXMLHelpersTest.TestSelectSingleNodeEmptyResultDoesNotLeak;
begin
  var doc := xmlDoc.Create('<root><item id="1"/><item id="2"/></root>', []);
  Assert.AreNotEqual<Pointer>(doc, nil);
  try
    Assert.AreNotEqual<Pointer>(doc.documentElement.SelectSingleNode('//item[@id="2"]'), nil);
    var used := xmlMemUsed;
    for var I := 1 to 100 do
      Assert.AreEqual<Pointer>(doc.documentElement.SelectSingleNode('//item[@id="3"]'), nil);
    Assert.AreEqual<NativeUInt>(used, xmlMemUsed, 'libxml2 memory must not grow on empty XPath results');
  finally
    xmlFreeDoc(doc);
  end;
end;

// SelectSingleNode evaluates through XPathEval like SelectNodes, so a prefix declared in
// the document resolves in a single-node query as well.
procedure TXMLHelpersTest.TestSelectSingleNodeResolvesNamespacesInScope;
begin
  var doc := xmlDoc.Create('<p:root xmlns:p="urn:test"><p:item>x</p:item></p:root>', []);
  Assert.AreNotEqual<Pointer>(doc, nil);
  try
    var node := doc.documentElement.SelectSingleNode('//p:item[text()="x"]');
    Assert.AreNotEqual<Pointer>(node, nil);
    Assert.AreEqual<RawByteString>('item', node.LocalName);
  finally
    xmlFreeDoc(doc);
  end;
end;

// Without an explicit namespace list the XPath context carries every prefix in scope of
// the context node: declared on the node itself or on any ancestor, the nearest
// declaration winning. The context node need not be in a namespace itself.
procedure TXMLHelpersTest.TestXPathSeesPrefixesDeclaredOnAncestors;
begin
  var doc := xmlDoc.Create(
    '<a xmlns:p="urn:outer"><b xmlns:p="urn:inner"><p:x/></b><c><d><p:y/></d></c></a>', []);
  Assert.AreNotEqual<Pointer>(doc, nil);
  try
    var a := doc.documentElement;
    // a is not in a namespace, the prefix comes from its own declaration: p:y only,
    // p:x belongs to urn:inner
    Assert.AreEqual<Integer>(1, Length(a.SelectNodes('//p:*')));
    var y := a.SelectSingleNode('.//p:y');
    Assert.AreNotEqual<Pointer>(y, nil);
    Assert.AreEqual<RawByteString>('urn:outer', y.NamespaceURI);
    // from d the nearest declaration of p is on a: urn:outer, so p:x is not visible.
    // The queries carry a predicate or a "./" step so that libxml2 evaluates them, not the
    // built-in namespace-agnostic engine.
    var d := y.parent;
    Assert.AreEqual<Integer>(0, Length(d.SelectNodes('//p:x')));
    Assert.AreNotEqual<Pointer>(d.SelectSingleNode('./p:y'), nil);
    // from b its own declaration shadows the outer one
    var b := a.FirstElementChild;
    Assert.AreNotEqual<Pointer>(b.SelectSingleNode('./p:x'), nil);
    Assert.AreEqual<Integer>(0, Length(b.SelectNodes('//p:y')));
    Assert.AreEqual<Integer>(1, Length(b.SelectNodes('//p:x')));
    // an explicit list replaces the declarations in scope
    var ns: xmlNamespaces := [Default(xmlNamespace)];
    ns[0].Prefix := 'q';
    ns[0].URI := 'urn:inner';
    Assert.AreEqual<Integer>(1, Length(d.SelectNodes('//q:*', ns)));
  finally
    xmlFreeDoc(doc);
  end;
end;

// GetElementsByTagName walks the subtree in document order and stops at the end of it:
// matches at every depth are collected once, elements outside the subtree are not.
procedure TXMLHelpersTest.TestGetElementsByTagNameWalksTheWholeSubtree;
begin
  var doc := xmlDoc.Create('<root><a><x/><b><x/><c><x/></c></b></a><x/><a><x/></a></root>', []);
  Assert.AreNotEqual<Pointer>(doc, nil);
  try
    Assert.AreEqual<Integer>(5, Length(doc.documentElement.GetElementsByTagName('x')));
    Assert.AreEqual<Integer>(3, Length(doc.documentElement.FirstElementChild.GetElementsByTagName('x')));
    Assert.AreEqual<Integer>(0, Length(doc.documentElement.GetElementsByTagName('none')));
    Assert.AreEqual<Integer>(9, Length(doc.documentElement.GetElementsByTagName('*')));
  finally
    xmlFreeDoc(doc);
  end;
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
