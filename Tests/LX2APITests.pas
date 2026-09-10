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
    [Test]
    procedure TestTransformWithoutParametersSucceeds;
    [Test]
    procedure TestTransformTagsResultWithOutputEncoding;
    [Test]
    procedure TestTransformReportsFormattedErrors;
    [Test]
    procedure TestToStringDecodesNonUtf8Dump;
  end;

  [TestFixture]
  TXMLDOMTest = class
  public
    [SetupFixture]
    procedure Setup;
    [Test]
    procedure TestCreateNodeWithNamespacePutsElementIntoIt;
    [Test]
    procedure TestSchemaCollectionGetDoesNotFreeTheSchema;
  end;

  // XML Schema validation over documents that live only in memory: no schema file exists
  // on disk, every link between the parts is resolved by the collection itself.
  [TestFixture]
  TXMLSchemaTest = class
  public
    [SetupFixture]
    procedure Setup;
    [Test]
    procedure TestImportByNamespaceIgnoresSchemaLocation;
    [Test]
    procedure TestDocumentsOfOneNamespaceFormOneSchema;
    [Test]
    procedure TestIncludeIsFetchedThroughTheResolver;
    [Test]
    procedure TestNoNamespaceSchema;
    [Test]
    procedure TestSchemaErrorsReachTheDocument;
    [Test]
    procedure TestUndeclaredRootIsInvalid;
    [Test]
    procedure TestCompiledSchemaFollowsAddAndRemove;
    [Test]
    procedure TestGetMergesTheDocumentsOfANamespace;
    [Test]
    procedure TestAddCollectionCopiesEverySource;
  end;

implementation

uses
  libxml2.API, RttiDispatch, LX2.Types, LX2.Helpers, LX2.DOM;

const
  XmlPreamble = '<?xml version="1.0" encoding="UTF-8"?>';
  XsltNs = 'http://www.w3.org/1999/XSL/Transform';
  CyrillicHello = #$041F#$0440#$0438#$0432#$0435#$0442;   // "Привет"

// SysUtils.Trim exists for string only: on a RawByteString it converts to UTF-16 and
// back (warnings W1057/W1058 and a round trip through the ANSI code page).
function TrimRaw(const S: RawByteString): RawByteString;
begin
  var First := 1;
  var Last := Length(S);
  while (First <= Last) and (S[First] <= ' ') do
    Inc(First);
  while (Last >= First) and (S[Last] <= ' ') do
    Dec(Last);
  Result := Copy(S, First, Last - First + 1);
end;

type
  TErrorSink = class
    Messages: TStringList;
    constructor Create;
    destructor Destroy; override;
    procedure Handler(const Msg: string);
  end;

constructor TErrorSink.Create;
begin
  inherited;
  Messages := TStringList.Create;
end;

destructor TErrorSink.Destroy;
begin
  Messages.Free;
  inherited;
end;

procedure TErrorSink.Handler(const Msg: string);
begin
  Messages.Add(Msg);
end;

function TextStylesheet(const OutputEncoding: string = ''): string;
begin
  Result := '<xsl:stylesheet version="1.0" xmlns:xsl="' + XsltNs + '"><xsl:output method="text"';
  if OutputEncoding <> '' then
    Result := Result + ' encoding="' + OutputEncoding + '"';
  Result := Result + '/><xsl:template match="/"><xsl:value-of select="root/name"/></xsl:template></xsl:stylesheet>';
end;

procedure TXMLHelpersTest.Setup;
begin
  LX2Lib.Initialize; // static binding through LX2.Static in the project uses
end;

procedure TXMLHelpersTest.TestCreateEmptyDoc;
begin
  var doc := xmlDoc.Create;
  Assert.AreNotEqual<Pointer>(doc, nil);
  if doc <> nil then
    Assert.AreEqual<RawByteString>(XmlPreamble, TrimRaw(doc.Xml));
  xmlFreeDoc(doc);
end;

procedure TXMLHelpersTest.TestCreateDocFromStr;
begin
  var doc := xmlDoc.Create('<root/>', []);
  Assert.AreNotEqual<Pointer>(doc, nil);
  if doc <> nil then
    Assert.AreEqual<RawByteString>(XmlPreamble + #10 + '<root/>', TrimRaw(doc.Xml));
  xmlFreeDoc(doc);
end;

procedure TXMLHelpersTest.TestCreateDocFromBytes;
begin
  var doc := xmlDoc.Create(BytesOf('<root/>'), []);
  Assert.AreNotEqual<Pointer>(doc, nil);
  if doc <> nil then
    Assert.AreEqual<RawByteString>(XmlPreamble + #10 + '<root/>', TrimRaw(doc.Xml));
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
    Assert.AreEqual<RawByteString>(XmlPreamble + #10 + '<root/>', TrimRaw(doc.Xml));
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
      Assert.AreEqual<RawByteString>(XmlPreamble + #10 + '<root/>', TrimRaw(doc.Xml));
    xmlFreeDoc(doc);
  finally
    Stream.Free;
  end;
end;

procedure TXMLHelpersTest.TestCreateDocFromFile;
begin
  // Tests\root.xml: the exe lives in Tests\<Platform>\<Config>, so resolve the path from
  // the exe rather than from the working directory.
  var doc := xmlDoc.CreateFromFile(ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\root.xml'), []);
  if doc <> nil then
    Assert.AreEqual<RawByteString>(XmlPreamble + #10 + '<root/>', TrimRaw(doc.Xml));
  xmlFreeDoc(doc);
end;

// xsltApplyStylesheetUser receives the address of a params variable as a
// NULL-terminated name/value array; an uninitialised variable made libxslt read
// stack garbage as parameter names, which failed or crashed depending on luck.
procedure TXMLHelpersTest.TestTransformWithoutParametersSucceeds;
var
  S: RawByteString;
begin
  var doc := xmlDoc.Create('<root><name>hello</name></root>', []);
  var style := xmlDoc.Create(TextStylesheet, []);
  try
    for var I := 1 to 20 do
    begin
      Assert.IsTrue(doc.Transform(style, S), 'transform must succeed on every call');
      Assert.AreEqual<RawByteString>('hello', S);
    end;
  finally
    xmlFreeDoc(style);
    xmlFreeDoc(doc);
  end;
end;

// The bytes of a transform result are in the xsl:output encoding, UTF-8 when it
// names none. The RawByteString carries that code page so string(S) converts right.
procedure TXMLHelpersTest.TestTransformTagsResultWithOutputEncoding;
var
  S: RawByteString;
  U: string;
begin
  var doc := xmlDoc.Create('<root><name>' + CyrillicHello + '</name></root>', []);
  var utf8 := xmlDoc.Create(TextStylesheet, []);
  var cp1251 := xmlDoc.Create(TextStylesheet('windows-1251'), []);
  try
    Assert.IsTrue(doc.Transform(utf8, S));
    Assert.AreEqual<Word>(65001, StringCodePage(S));
    Assert.AreEqual(CyrillicHello, string(S));
    Assert.IsTrue(doc.Transform(utf8, U));
    Assert.AreEqual(CyrillicHello, U);

    Assert.IsTrue(doc.Transform(cp1251, S));
    Assert.AreEqual<Word>(1251, StringCodePage(S));
    Assert.AreEqual<NativeInt>(Length(CyrillicHello), Length(S), 'single-byte encoding');
    Assert.AreEqual(CyrillicHello, string(S));
    Assert.IsTrue(doc.Transform(cp1251, U));
    Assert.AreEqual(CyrillicHello, U);
  finally
    xmlFreeDoc(cp1251);
    xmlFreeDoc(utf8);
    xmlFreeDoc(doc);
  end;
end;

// libxslt reports runtime errors printf-style through the transform context's
// handler (xsl:message uses the format "%s"); the handler must see the expanded
// text, not the raw format string. Stylesheet compile errors go to the global
// generic handler instead and are not covered here.
procedure TXMLHelpersTest.TestTransformReportsFormattedErrors;
var
  S: RawByteString;
begin
  var doc := xmlDoc.Create('<root/>', []);
  var style := xmlDoc.Create(
    '<xsl:stylesheet version="1.0" xmlns:xsl="' + XsltNs + '">' +
    '<xsl:template match="/"><xsl:message terminate="yes">Boom <xsl:value-of select="name(/*)"/></xsl:message></xsl:template>' +
    '</xsl:stylesheet>', []);
  var sink := TErrorSink.Create;
  try
    Assert.IsFalse(doc.Transform(style, S, sink.Handler), 'terminate="yes" must fail the transform');
    Assert.IsTrue(sink.Messages.Count > 0, 'error handler must be called');
    var all := sink.Messages.Text;
    Assert.IsFalse(all.Contains('%s'), 'format not expanded: ' + all);
    Assert.IsTrue(all.Contains('Boom root'), all);
  finally
    sink.Free;
    xmlFreeDoc(style);
    xmlFreeDoc(doc);
  end;
end;

// ToString dumps in the requested encoding; reading that dump back as UTF-8 turned
// every non-ASCII character into U+FFFD.
procedure TXMLHelpersTest.TestToStringDecodesNonUtf8Dump;
begin
  var doc := xmlDoc.Create('<root>' + CyrillicHello + '</root>', []);
  try
    var S := doc.ToString('windows-1251');
    Assert.IsTrue(S.Contains('encoding="windows-1251"'), S);
    Assert.IsTrue(S.Contains('<root>' + CyrillicHello + '</root>'), S);
    Assert.IsTrue(doc.ToString('UTF-8').Contains('<root>' + CyrillicHello + '</root>'));
  finally
    xmlFreeDoc(doc);
  end;
end;

{ TXMLDOMTest }

procedure TXMLDOMTest.Setup;
begin
  LX2Lib.Initialize;
end;

procedure TXMLDOMTest.TestCreateNodeWithNamespacePutsElementIntoIt;
begin
  var doc := CoCreateXMLDocument;
  var root := doc.CreateNode(NODE_ELEMENT, 'root', 'urn:test') as IXMLElement;
  doc.DocumentElement := root;
  Assert.AreEqual('urn:test', root.NamespaceURI);
  Assert.AreEqual('<root xmlns="urn:test"/>', root.Xml);

  var prefixed := doc.CreateNode(NODE_ELEMENT, 'p:item', 'urn:p') as IXMLElement;
  root.AppendChild(prefixed);
  Assert.AreEqual('urn:p', prefixed.NamespaceURI);
  Assert.AreEqual('item', prefixed.LocalName);
end;

// The compiled schema document belongs to the collection; the wrapper returned by
// Get must not free it, and a later Get must not find a dead wrapper via _private.
procedure TXMLDOMTest.TestSchemaCollectionGetDoesNotFreeTheSchema;
const
  Xsd =
    '<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" targetNamespace="urn:t" xmlns="urn:t">' +
    '<xs:element name="e" type="xs:string"/></xs:schema>';
begin
  var schemas := CoCreateSchemaCollection;
  var source := CoCreateXMLDocument;
  Assert.IsTrue(source.LoadXML(Xsd));
  schemas.Add('urn:t', source);

  Assert.IsTrue(schemas.Get('urn:t').ToString.Contains('targetNamespace="urn:t"'));
  Assert.IsTrue(schemas.Get('urn:t').ToString.Contains('targetNamespace="urn:t"'), 'second Get after the first wrapper died');

  var instance := CoCreateXMLDocument;
  Assert.IsTrue(instance.LoadXML('<e xmlns="urn:t">x</e>'));
  Assert.IsTrue(schemas.Validate(instance));

  schemas.Remove('urn:t');
  Assert.AreEqual<NativeInt>(0, schemas.Length);
end;

{ TXMLSchemaTest }

const
  XsdNs = 'http://www.w3.org/2001/XMLSchema';

type
  // Hands out schema parts by name, the way an application reads them from a database.
  TMemoryResolver = class(TDispatchInvokable, IXMLResolver)
  private
    FParts: TStringList;
  public
    Requested: TStringList;
    constructor Create;
    destructor Destroy; override;
    procedure AddPart(const Url, Xsd: string);
    function  Resolve(const Url: string): TBytes;
  end;

constructor TMemoryResolver.Create;
begin
  inherited Create;
  FParts := TStringList.Create;
  Requested := TStringList.Create;
end;

destructor TMemoryResolver.Destroy;
begin
  FParts.Free;
  Requested.Free;
  inherited;
end;

procedure TMemoryResolver.AddPart(const Url, Xsd: string);
begin
  FParts.Values[Url] := Xsd;
end;

function TMemoryResolver.Resolve(const Url: string): TBytes;
begin
  Requested.Add(Url);
  var Xsd := FParts.Values[Url];
  if Xsd = '' then
    Exit(nil);
  Result := TEncoding.UTF8.GetBytes(Xsd);
end;

function SchemaDoc(const TargetNamespace, Body: string; const Extra: string = ''): IXMLDocument;
begin
  var Xsd := '<xs:schema xmlns:xs="' + XsdNs + '"';
  if TargetNamespace <> '' then
    Xsd := Xsd + ' targetNamespace="' + TargetNamespace + '" xmlns="' + TargetNamespace + '"';
  Xsd := Xsd + ' ' + Extra + '>' + Body + '</xs:schema>';
  Result := CoCreateXMLDocument;
  Assert.IsTrue(Result.LoadXML(Xsd), 'schema document must be well-formed');
end;

function InstanceDoc(const Xml: string): IXMLDocument;
begin
  Result := CoCreateXMLDocument;
  Assert.IsTrue(Result.LoadXML(Xml), 'instance document must be well-formed');
end;

// Everything the collection and the document have to say, for assertion messages.
function Diagnostics(const Schemas: IXMLSchemaCollection; const Doc: IXMLDocument): string;
begin
  Result := '';
  for var E in Schemas.Errors do
    Result := Result + 'schema: ' + E.Reason.Trim + sLineBreak;
  for var E in Doc.Errors do
    Result := Result + 'document: ' + E.Reason.Trim + sLineBreak;
end;

function HasErrorCode(const Errors: IXMLErrors; Code: xmlParserErrors): Boolean;
begin
  for var E in Errors do
    if E.ErrorCode = Ord(Code) then
      Exit(True);
  Result := False;
end;

procedure TXMLSchemaTest.Setup;
begin
  LX2Lib.Initialize;
end;

// urn:a imports urn:b with a schemaLocation that exists nowhere; the collection holds urn:b
// itself, so the import is served from the collection whatever the order of Add.
procedure TXMLSchemaTest.TestImportByNamespaceIgnoresSchemaLocation;
begin
  var schemas := CoCreateSchemaCollection;
  schemas.Add('urn:a', SchemaDoc('urn:a',
    '<xs:import namespace="urn:b" schemaLocation="nowhere/b.xsd"/>' +
    '<xs:element name="order"><xs:complexType><xs:sequence>' +
    '<xs:element ref="b:item" maxOccurs="unbounded"/>' +
    '</xs:sequence></xs:complexType></xs:element>', 'xmlns:b="urn:b"'));
  schemas.Add('urn:b', SchemaDoc('urn:b', '<xs:element name="item" type="xs:int"/>'));

  var valid := InstanceDoc('<a:order xmlns:a="urn:a" xmlns:b="urn:b"><b:item>1</b:item><b:item>2</b:item></a:order>');
  Assert.IsTrue(schemas.Validate(valid), Diagnostics(schemas, valid));
  Assert.AreEqual<NativeInt>(0, schemas.Errors.Count, 'an import served by the collection leaves no diagnostics');

  var invalid := InstanceDoc('<a:order xmlns:a="urn:a" xmlns:b="urn:b"><b:item>x</b:item></a:order>');
  Assert.IsFalse(schemas.Validate(invalid));
  Assert.IsTrue(invalid.Errors.Count > 0);
  Assert.IsTrue(invalid.ParseError.Reason.Contains('item'), invalid.ParseError.Reason);
end;

// The parts of one namespace are added one by one, as the files of a large schema set
// stored in a database; they include each other by file names that resolve nowhere.
procedure TXMLSchemaTest.TestDocumentsOfOneNamespaceFormOneSchema;
begin
  var schemas := CoCreateSchemaCollection;
  schemas.Add('urn:m', SchemaDoc('urn:m',
    '<xs:include schemaLocation="types.xsd"/>' +
    '<xs:element name="root" type="T"/>'));
  schemas.Add('urn:m', SchemaDoc('urn:m',
    '<xs:include schemaLocation="root.xsd"/>' +
    '<xs:include schemaLocation="types.xsd"/>' +
    '<xs:complexType name="T"><xs:attribute name="n" type="xs:int" use="required"/></xs:complexType>'));

  var valid := InstanceDoc('<root xmlns="urn:m" n="1"/>');
  Assert.IsTrue(schemas.Validate(valid), Diagnostics(schemas, valid));
  var invalid := InstanceDoc('<root xmlns="urn:m"/>');
  Assert.IsFalse(schemas.Validate(invalid));
  Assert.IsTrue(invalid.ParseError.Reason.Contains('n'), invalid.ParseError.Reason);

  // One warning per distinct unresolved location, none of them an error.
  Assert.AreEqual<NativeInt>(2, schemas.Errors.Count);
  for var E in schemas.Errors do
  begin
    Assert.AreEqual(Ord(XML_ERR_WARNING), Ord(E.Level));
    Assert.AreEqual(Ord(XML_SCHEMAP_WARN_UNLOCATED_SCHEMA), E.ErrorCode);
  end;
  Assert.IsTrue(schemas.Errors[0].Reason.Contains('types.xsd'), schemas.Errors[0].Reason);
end;

// A resolver supplies included parts; the part it returns may include further parts,
// whose locations are resolved relative to the part that named them.
procedure TXMLSchemaTest.TestIncludeIsFetchedThroughTheResolver;
begin
  var resolver := TMemoryResolver.Create;
  var keep: IXMLResolver := resolver;
  resolver.AddPart('parts/types.xsd',
    '<xs:schema xmlns:xs="' + XsdNs + '" targetNamespace="urn:r" xmlns="urn:r" elementFormDefault="qualified">' +
    '<xs:include schemaLocation="more.xsd"/>' +
    '<xs:complexType name="T"><xs:sequence><xs:element name="v" type="V"/></xs:sequence></xs:complexType>' +
    '</xs:schema>');
  resolver.AddPart('parts/more.xsd',
    '<xs:schema xmlns:xs="' + XsdNs + '" targetNamespace="urn:r" xmlns="urn:r">' +
    '<xs:simpleType name="V"><xs:restriction base="xs:int"><xs:maxInclusive value="9"/></xs:restriction></xs:simpleType>' +
    '</xs:schema>');

  var schemas := CoCreateSchemaCollection;
  schemas.Add('urn:r', SchemaDoc('urn:r',
    '<xs:include schemaLocation="parts/types.xsd"/>' +
    '<xs:element name="root" type="T"/>'), keep);

  var valid := InstanceDoc('<root xmlns="urn:r"><v>9</v></root>');
  Assert.IsTrue(schemas.Validate(valid), Diagnostics(schemas, valid) + 'requested: ' + resolver.Requested.CommaText);
  var invalid := InstanceDoc('<root xmlns="urn:r"><v>10</v></root>');
  Assert.IsFalse(schemas.Validate(invalid));
  Assert.AreEqual<NativeInt>(0, schemas.Errors.Count, Diagnostics(schemas, invalid));
  Assert.AreEqual(2, resolver.Requested.Count, 'every part is fetched once: ' + resolver.Requested.CommaText);
  Assert.AreEqual('parts/types.xsd', resolver.Requested[0]);
  Assert.AreEqual('parts/more.xsd', resolver.Requested[1]);
end;

procedure TXMLSchemaTest.TestNoNamespaceSchema;
begin
  var schemas := CoCreateSchemaCollection;
  schemas.Add('', SchemaDoc('', '<xs:element name="e" type="xs:int"/>'));
  schemas.Add('urn:n', SchemaDoc('urn:n', '<xs:element name="e" type="xs:date"/>'));

  Assert.IsTrue(schemas.Validate(InstanceDoc('<e>5</e>')));
  Assert.IsFalse(schemas.Validate(InstanceDoc('<e>x</e>')));
  Assert.IsTrue(schemas.Validate(InstanceDoc('<e xmlns="urn:n">2026-09-09</e>')));
  Assert.IsFalse(schemas.Validate(InstanceDoc('<e xmlns="urn:n">5</e>')));
end;

// A schema that does not compile fails every validation, and the reason is visible both
// on the collection and on the document that was being validated.
procedure TXMLSchemaTest.TestSchemaErrorsReachTheDocument;
begin
  var schemas := CoCreateSchemaCollection;
  schemas.Add('urn:bad', SchemaDoc('urn:bad', '<xs:element name="e" type="Missing"/>'));

  var doc := InstanceDoc('<e xmlns="urn:bad">1</e>');
  Assert.IsFalse(schemas.Validate(doc));
  Assert.IsTrue(schemas.Errors.Count > 0);
  Assert.AreEqual(Ord(XML_ERR_ERROR), Ord(schemas.Errors.Items[0].Level));
  Assert.IsTrue(doc.Errors.Count > 0);
  Assert.IsTrue(doc.ParseError.Reason.Contains('Missing'), doc.ParseError.Reason);
end;

procedure TXMLSchemaTest.TestUndeclaredRootIsInvalid;
begin
  var schemas := CoCreateSchemaCollection;
  schemas.Add('urn:t', SchemaDoc('urn:t', '<xs:element name="e" type="xs:string"/>'));

  var doc := InstanceDoc('<other xmlns="urn:t"/>');
  Assert.IsFalse(schemas.Validate(doc));
  Assert.IsTrue(HasErrorCode(doc.Errors, XML_SCHEMAV_CVC_ELT_1), doc.ParseError.Reason);
end;

procedure TXMLSchemaTest.TestCompiledSchemaFollowsAddAndRemove;
begin
  var schemas := CoCreateSchemaCollection;
  var xsd := SchemaDoc('urn:t', '<xs:element name="e" type="xs:int"/>');
  schemas.Add('urn:t', xsd);
  var doc := InstanceDoc('<e xmlns="urn:t">1</e>');

  Assert.IsTrue(schemas.Validate(doc));
  Assert.IsTrue(schemas.Validate(doc), 'the compiled schema is reused');

  schemas.Remove('urn:t');
  Assert.IsFalse(schemas.Validate(doc), 'nothing declares the root any more');
  Assert.IsTrue(HasErrorCode(doc.Errors, XML_SCHEMAV_CVC_ELT_1));

  schemas.Add('urn:t', xsd);
  Assert.IsTrue(schemas.Validate(doc));
end;

procedure TXMLSchemaTest.TestGetMergesTheDocumentsOfANamespace;
begin
  var schemas := CoCreateSchemaCollection;
  schemas.Add('urn:m', SchemaDoc('urn:m', '<xs:include schemaLocation="types.xsd"/><xs:element name="root" type="T"/>'));
  schemas.Add('urn:m', SchemaDoc('urn:m', '<xs:import namespace="urn:x"/><xs:complexType name="T"/>'));

  var merged := schemas.Get('urn:m').ToString;
  Assert.IsTrue(merged.Contains('name="root"'), merged);
  Assert.IsTrue(merged.Contains('name="T"'), merged);
  Assert.IsTrue(merged.Contains('namespace="urn:x"'), merged);
  Assert.IsFalse(merged.Contains('include'), merged);
  Assert.IsNull(schemas.Get('urn:none'));
end;

procedure TXMLSchemaTest.TestAddCollectionCopiesEverySource;
begin
  var first := CoCreateSchemaCollection;
  first.Add('urn:m', SchemaDoc('urn:m', '<xs:element name="root" type="T"/>'));
  first.Add('urn:m', SchemaDoc('urn:m', '<xs:complexType name="T"/>'));

  var second := CoCreateSchemaCollection;
  second.AddCollection(first);
  second.AddCollection(second);
  Assert.AreEqual<NativeInt>(1, second.Length);
  Assert.IsTrue(second.Validate(InstanceDoc('<root xmlns="urn:m"/>')));
end;

initialization
  TDUnitX.RegisterTestFixture(TXMLHelpersTest);
  TDUnitX.RegisterTestFixture(TXMLDOMTest);
  TDUnitX.RegisterTestFixture(TXMLSchemaTest);

end.
