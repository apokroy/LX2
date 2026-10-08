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
    procedure TestXPathIndexesElementsOnDemand;
    [Test]
    procedure TestXPathOrderSurvivesMovedElements;
    [Test]
    procedure TestSelectSingleNodeResolvesNamespacesInScope;
    [Test]
    procedure TestSimplePathAgreesWithXPath;
    [Test]
    procedure TestSimplePathKeepsTheQueryString;
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
    procedure TestTransformContextLayoutMatchesLibxslt;
    [Test]
    procedure TestToStringDecodesNonUtf8Dump;
    [Test]
    procedure TestNewStringReleasesPreviousValue;
    [Test]
    procedure TestEscapeOfEmptyValueIsEmpty;
    [Test]
    procedure TestSAXAttributeStringsAreReleased;
    [Test]
    procedure TestCreateRootAndChildDeclareTheirNamespaces;
    [Test]
    procedure TestCreateElementNsAndAddChildNsDeclareTheirNamespaces;
    [Test]
    procedure TestRemoveAndReplaceLeaveTheParentAlone;
  end;

  [TestFixture]
  TXMLDOMTest = class
  public
    [SetupFixture]
    procedure Setup;
    [Test]
    procedure TestCreateNodeWithNamespacePutsElementIntoIt;
    [Test]
    procedure TestCreateElementKeepsUndeclaredPrefix;
    [Test]
    procedure TestCloneNodeOfElementIsElement;
    [Test]
    procedure TestSchemaCollectionGetDoesNotFreeTheSchema;
    [Test]
    procedure TestSimplePathFromDocumentParsedFromMemory;
    [Test]
    procedure TestInsertBeforeNilAppends;
    [Test]
    procedure TestTransformNodeToObjectKeepsTheSource;
    [Test]
    procedure TestTransformElementToObjectKeepsTheSource;
    [Test]
    procedure TestDispatchNamesFollowInterfaceProperties;
    [Test]
    procedure TestLateBoundNodeListItem;
    [Test]
    procedure TestLateBoundResultsAreReleased;
    [Test]
    procedure TestLateBoundCallPicksTheOverload;
    [Test]
    procedure TestChildNodesFollowChanges;
    [Test]
    procedure TestChildNodesOutOfRange;
    [Test]
    procedure TestChildNodesFollowStripSpace;
    [Test]
    procedure TestChildNodesFollowReload;
    [Test]
    procedure TestChildNodesKeepTheNodeAlive;
    [Test]
    procedure TestChildNodesIndexedWalkIsLinear;
    [Test]
    procedure TestElementsByTagNameFollowChanges;
    [Test]
    procedure TestElementsByTagNameFollowPrefix;
    [Test]
    procedure TestElementsByTagNameFollowTheRoot;
    [Test]
    procedure TestElementsByTagNameOutOfRange;
    [Test]
    procedure TestElementsByTagNameIndexedWalkIsLinear;
    [Test]
    procedure TestElementsByTagNameAsInMSXML;
    [Test]
    procedure TestElementsByTagNameNSAsInDOM;
    [Test]
    procedure TestElementsByTagNameOfDocumentWithoutRoot;
    [Test]
    procedure TestElementsByTagNameSkipsTheDTD;
    [Test]
    procedure TestElementsByTagNameNSOfElement;
    [Test]
    procedure TestElementsByTagNameNSFollowTheRoot;
    [Test]
    procedure TestTransformElementAfterXPathQuery;
    [Test]
    procedure TestTransformElementTagsResultWithOutputEncoding;
    [Test]
    procedure TestTransformNodeStartsAtTheNodeAsInMSXML;
    [Test]
    procedure TestTransformWithKeysAsInMSXML;
    [Test]
    procedure TestRemovedRootSurvivesReload;
    [Test]
    procedure TestCreatedElementSurvivesReload;
    [Test]
    procedure TestTransformNodeToObjectKeepsDetachedNodes;
    [Test]
    procedure TestReloadedContentStaysUsable;
    [Test]
    procedure TestMovedSubtreeHoldsItsNewDocument;
    [Test]
    procedure TestSelectedNodesSurviveReload;
    [Test]
    procedure TestDocumentElementSetToItself;
    [Test]
    procedure TestReplacedDocumentElementStaysUsable;
    [Test]
    procedure TestDocumentElementFromItsOwnSubtree;
    [Test]
    procedure TestReplaceChildReturnsTheOldChild;
    [Test]
    procedure TestReplaceChildWithItself;
    [Test]
    procedure TestDescendantsOfRemovedNodeStayUsable;
    [Test]
    procedure TestDescendantsOfReplacedChildStayUsable;
    [Test]
    procedure TestDescendantsOfReplacedRootStayUsable;
    [Test]
    procedure TestDetachedSubtreeGoesWithTheLastReference;
    [Test]
    procedure TestRestOfDetachedSubtreeGoesWhenTheNodeMoves;
    [Test]
    procedure TestKeptSubtreeMovesToAnotherDocument;
    [Test]
    procedure TestNodeOfKeptSubtreeMovesToAnotherDocument;
    [Test]
    procedure TestKeptSubtreeSurvivesReload;
    [Test]
    procedure TestSelectedNodesOfRemovedNodeStayUsable;
    [Test]
    procedure TestWalkInKeptSubtreeIsLinear;
    [Test]
    procedure TestReplacedChildKeepsItsNamespaces;
    [Test]
    procedure TestRemovedChildKeepsItsNamespaces;
    [Test]
    procedure TestCreateRootDeclaresItsNamespace;
    [Test]
    procedure TestCreateRootKeepsTheReplacedRoot;
    [Test]
    procedure TestCreateChildDeclaresItsNamespace;
    [Test]
    procedure TestCreateChildUnderDefaultNamespace;
    [Test]
    procedure TestCreateChildResolveNamespace;
    [Test]
    procedure TestCreateChildWithoutParentCreatesTheRoot;
    [Test]
    procedure TestCreateElementNsDeclaresItsNamespace;
    [Test]
    procedure TestAddChildNsKeepsThePrefixItIsGiven;
    [Test]
    procedure TestRemoveChildLeavesTheParentAlone;
    [Test]
    procedure TestReplaceChildDeclaresWhatTheNewChildUses;
    [Test]
    procedure TestMovedSubtreeKeepsItsNestedDeclarations;
    [Test]
    procedure TestNodeThatIsNotAChildIsRefused;
    [Test]
    procedure TestNodeIsNotInsertedUnderItself;
    [Test]
    procedure TestRemovedAttributeKeepsItsNamespace;
    [Test]
    procedure TestAttributesKeepTheDocumentAlive;
    [Test]
    procedure TestAttributesOfDetachedElementsStayUsable;
    [Test]
    procedure TestAttributesSurviveReload;
    [Test]
    procedure TestNamespaceDeclarationKeepsItsElement;
    [Test]
    procedure TestCreatedNamespaceDeclaration;
    [Test]
    procedure TestAttributesEnumerateDeclarationsAndAttributes;
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
    [Test]
    procedure TestIncludeOfAnAddedFileIsNotReadAgain;
  end;

implementation

uses
  System.Rtti, System.Variants, System.IOUtils, System.Diagnostics,
  libxml2.API, libxslt.API, RttiDispatch, LX2.Types, LX2.Helpers, LX2.DOM, LX2.DOM.Classes, LX2.SAX;

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

type
  // Keeps references to the names and values of the first element's attributes.
  TAttributeKeeper = class(TSAXCustomParser)
  protected
    procedure DoStartElement(const LocalName, Prefix, URI: string; const Namespaces: TSAXNamespaces; const Attributes: TSAXAttributes); override;
  public
    Kept: TArray<string>;
  end;

procedure TAttributeKeeper.DoStartElement(const LocalName, Prefix, URI: string; const Namespaces: TSAXNamespaces; const Attributes: TSAXAttributes);
begin
  if Kept = nil then
    for var I := 0 to High(Attributes) do
      Kept := Kept + [Attributes[I].Name, Attributes[I].Value];
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
// unreleased. In a debug build LX2Lib.Load installs the libxml2 debug allocator, so
// xmlMemUsed counts every byte the library holds: it must not grow across a query with
// an empty result. A release build routes the library to the Delphi memory manager and
// xmlMemUsed stays 0, so the check has nothing to measure there.
procedure TXMLHelpersTest.TestSelectSingleNodeEmptyResultDoesNotLeak;
begin
{$IFNDEF DEBUG}
  Assert.Pass('xmlMemUsed accounts only for the debug allocator of a debug build');
{$ENDIF}
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

// A path made of names only is answered by the evaluator of LX2.XPATH, anything else by
// libxml2. Both must name the same node: the first one of the XPath result in document
// order, for a relative path counted from the children of the context node and for an
// absolute one from the document, whatever the context node is. The reference is the same
// query through SelectNodes, which always goes to libxml2.
procedure TXMLHelpersTest.TestSimplePathAgreesWithXPath;
const
  Xml: RawByteString =
    '<root>' +
      '<a id="1"><a id="2"><b id="3"/></a><b id="4"/></a>' +
      '<Tags><Tags id="5"/><Levels id="6"/></Tags>' +
      '<c><d><b id="7"/></d><p:e xmlns:p="urn:p"><b id="8"/></p:e></c>' +
    '</root>';
  Contexts: array[0..4] of RawByteString = ('/', '/root', '/root/a[1]', '/root/a/a', '/root/c');
  Queries: array[0..25] of RawByteString = (
    'a', 'b', 'Tags', 'Tags/Tags', 'Tags/Levels', 'a/b', 'a/a/b', 'root', 'root/Tags', 'd/b', 'missing',
    '/root', '/root/a/b', '/root/a/a/b', '/a', '/root/missing',
    '//b', '//a/b', '//a//b', '//a/a', '//root', '//c/d/b', '//d//b', '//missing/b',
    'c//b', ' a / b ');
begin
  var doc := xmlDoc.Create(Xml, []);
  Assert.AreNotEqual<Pointer>(doc, nil);
  try
    for var ContextPath in Contexts do
    begin
      var Found := xmlNodePtr(doc).SelectNodes(ContextPath);
      Assert.AreEqual<NativeInt>(1, Length(Found), string(ContextPath));
      var Context := Found[0];

      for var Query in Queries do
      begin
        var Expected: xmlNodePtr := nil;
        var Nodes := Context.SelectNodes(Query);
        if Length(Nodes) > 0 then
          Expected := Nodes[0];
        Assert.AreEqual<Pointer>(Expected, Context.SelectSingleNode(Query),
          Format('"%s" from "%s"', [string(Query), string(ContextPath)]));
      end;
    end;

    // The prefix is compared as written, and a name without one fits any namespace.
    var c := xmlNodePtr(doc).SelectSingleNode('/root/c');
    Assert.AreNotEqual<Pointer>(c.SelectSingleNode('p:e/b'), nil);
    Assert.AreEqual<Pointer>(c.SelectSingleNode('p:e'), c.SelectSingleNode('e'));
    Assert.AreEqual<Pointer>(c.SelectSingleNode('q:e'), nil);
  finally
    xmlFreeDoc(doc);
  end;
end;

procedure TXMLHelpersTest.TestSimplePathKeepsTheQueryString;
begin
  var doc := xmlDoc.Create('<root><a><b/></a></root>', []);
  Assert.AreNotEqual<Pointer>(doc, nil);
  try
    var Query: RawByteString := '/root/' + RawByteString('a') + '/b';
    var Copy := Query;
    Assert.AreNotEqual<Pointer>(xmlNodePtr(doc).SelectSingleNode(Query), nil);
    Assert.AreEqual<RawByteString>('/root/a/b', Copy);
    Assert.AreNotEqual<Pointer>(xmlNodePtr(doc).SelectSingleNode(Query), nil, 'the same string again');
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

// The Delphi record of the transform context lays its fields out as the C structure of
// libxslt does: a field written through the record at another offset lands in a neighbour.
// Every value checked here is put there by xsltNewTransformContext; the locale functions
// are the last fields of the structure.
procedure TXMLHelpersTest.TestTransformContextLayoutMatchesLibxslt;
const
  XSLT_PARSE_OPTIONS = XML_PARSE_NOENT or XML_PARSE_DTDLOAD or XML_PARSE_DTDATTR or XML_PARSE_NOCDATA;
  DefaultMaxDepth = 3000;   // xsltMaxDepth
  DefaultMaxVars = 15000;   // xsltMaxVars
begin
  XSLTLib.Initialize;
  var doc := xmlDoc.Create('<root/>', []);
  var style := xsltParseStylesheetDoc(xmlDoc.Create(TextStylesheet, []));   // takes the document
  Assert.IsTrue(style <> nil, 'stylesheet');
  var ctxt := xsltNewTransformContext(style, doc);
  try
    Assert.IsTrue(ctxt <> nil, 'context');
    Assert.IsTrue(ctxt.style = style, 'style');
    Assert.AreEqual(0, ctxt.templNr, 'templNr');
    Assert.AreEqual(5, ctxt.templMax, 'templMax');
    Assert.AreEqual(10, ctxt.varsMax, 'varsMax');
    Assert.IsTrue(ctxt.document <> nil, 'document');
    Assert.IsTrue(ctxt.document.doc = doc, 'document.doc');
    Assert.AreEqual(1, ctxt.document.main, 'document.main');
    Assert.IsTrue(ctxt.node = nil, 'node');
    Assert.IsTrue(ctxt.xpathCtxt <> nil, 'xpathCtxt');
    Assert.AreEqual(XSLT_PARSE_OPTIONS, ctxt.parserOptions, 'parserOptions');
    Assert.IsTrue(ctxt.dict <> nil, 'dict');
    Assert.AreEqual(1, ctxt.internalized, 'internalized');
    Assert.IsTrue(ctxt.initialContextNode = nil, 'initialContextNode');
    Assert.IsTrue(ctxt.cache <> nil, 'cache');
    Assert.AreEqual(DefaultMaxDepth, ctxt.maxTemplateDepth, 'maxTemplateDepth');
    Assert.AreEqual(DefaultMaxVars, ctxt.maxTemplateVars, 'maxTemplateVars');
    Assert.IsTrue(Assigned(ctxt.newLocale) and Assigned(ctxt.freeLocale) and Assigned(ctxt.genSortKey), 'locale functions');
  finally
    xsltFreeTransformContext(ctxt);
    xsltFreeStylesheet(style);
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

// A string function receives in Result whatever the variable it is assigned to holds. The
// string constructors behind xmlCharToStr and the like release that value; StringRefCount
// of a second reference shows whether they did.
procedure TXMLHelpersTest.TestNewStringReleasesPreviousValue;
var
  S, Kept: string;
  R, KeptRaw: RawByteString;
begin
  S := StringOfChar('p', 8);
  Kept := S;
  NewUtf16String(Pointer(S), 4, PChar('next'));
  Assert.AreEqual('next', S);
  Assert.AreEqual<Integer>(1, StringRefCount(Kept), 'NewUtf16String');

  Kept := S;
  NewUtf16String(Pointer(S), 0);
  Assert.AreEqual('', S);
  Assert.AreEqual<Integer>(1, StringRefCount(Kept), 'NewUtf16String of length 0');

  R := StringOfChar(AnsiChar('p'), 8);
  KeptRaw := R;
  NewRawString(Pointer(R), 4, PAnsiChar('next'));
  Assert.AreEqual<RawByteString>('next', R);
  Assert.AreEqual<Integer>(1, StringRefCount(KeptRaw), 'NewRawString');

  KeptRaw := R;
  NewUtf8String(Pointer(R), 4, PAnsiChar('utf8'));
  Assert.AreEqual<RawByteString>('utf8', R);
  Assert.AreEqual<Integer>(1, StringRefCount(KeptRaw), 'NewUtf8String');
end;

// One call site in a loop: the result arrives holding the previous value, and an empty
// value has to replace it rather than pass it through.
procedure TXMLHelpersTest.TestEscapeOfEmptyValueIsEmpty;
const
  Values: array[0..1] of RawByteString = ('a&b', '');
var
  S: RawByteString;
begin
  for var V in Values do
    S := xmlEscapeString(V);
  Assert.AreEqual<RawByteString>('', S);
  Assert.AreEqual<Pointer>(nil, Pointer(S), 'an empty escape is a nil string');
end;

// The attributes of an element are converted one after another through the same
// temporaries of StartElement; once the element is handled, only the handler's own
// references may be left.
procedure TXMLHelpersTest.TestSAXAttributeStringsAreReleased;
var
  Xml: RawByteString;
begin
  Xml := '<r><i a="1" bb="22" ccc="333"/><i a="4"/></r>';
  var Parser := TAttributeKeeper.Create;
  try
    Assert.IsTrue(Parser.Parse(Xml));
    Assert.AreEqual<NativeInt>(6, Length(Parser.Kept));
    for var I := 0 to High(Parser.Kept) do
      Assert.AreEqual<Integer>(1, StringRefCount(Parser.Kept[I]), Parser.Kept[I]);
  finally
    Parser.Free;
  end;
end;

// CreateRoot and CreateChild declare the namespace of the element on the element itself,
// unless a declaration in scope of the parent serves it, and the declaration goes with the
// document. The output is what MSXML writes for createNode followed by appendChild.
procedure TXMLHelpersTest.TestCreateRootAndChildDeclareTheirNamespaces;
begin
  LX2Lib.Initialize;
  var Used := xmlMemUsed;
  var Doc := xmlDoc.Create;
  try
    var Root := Doc.CreateRoot('p:r', 'urn:p');
    Assert.AreEqual<RawByteString>('urn:p', Root.NamespaceURI);
    Doc.CreateChild(Root, 'p:a', 'urn:p');
    Doc.CreateChild(Root, 'q:b', 'urn:q', False, 'x<y');
    Doc.CreateChild(Root, 'c', 'urn:p');
    Doc.CreateChild(Root, 'p:d');
    Doc.CreateChild(Root, 'e', 'urn:p', True);
    Assert.AreEqual<RawByteString>('<p:r xmlns:p="urn:p"><p:a/><q:b xmlns:q="urn:q">x&lt;y</q:b>' +
      '<c xmlns="urn:p"/><p:d/><p:e/></p:r>', Root.Xml);
    Assert.AreEqual<RawByteString>('urn:p', Root.LastChild.PreviousSibling.NamespaceURI, 'p:d');
  finally
    xmlFreeDoc(Doc);
  end;
  Assert.AreEqual<NativeUInt>(Used, xmlMemUsed, 'libxml2 memory');
end;

// CreateElementNs declares the namespace on the element under the prefix of its name, as
// MSXML's createNode does, and the declaration stays with the element under a parent that
// binds the prefix to another namespace. AddChildNs keeps a prefix it is given and takes a
// declaration in scope only when it binds that prefix; a name without a prefix takes the
// prefix the namespace URI has in scope. Without a namespace URI both make what
// CreateElement and AddChild make.
procedure TXMLHelpersTest.TestCreateElementNsAndAddChildNsDeclareTheirNamespaces;
const
  NamespaceURIs: array[0..9] of RawByteString = ('urn:p', 'urn:p', '', '', 'urn:q', 'urn:q', 'urn:q',
    'urn:o', 'urn:s', 'urn:q');
begin
  LX2Lib.Initialize;
  var Used := xmlMemUsed;
  var Doc := xmlDoc.Create('<r xmlns:p="urn:q"/>', []);
  try
    var Root := Doc.documentElement;
    Root.AppendChild(Doc.CreateElementNs('urn:p', 'p:a'));
    Root.AppendChild(Doc.CreateElementNs('urn:p', 'b'));
    Root.AppendChild(Doc.CreateElementNs('', 'p:c'));
    Root.AppendChild(Doc.CreateElementNs('', 'd'));
    Root.AddChildNs('q:e', 'urn:q');
    Root.AddChildNs('p:f', 'urn:q');
    Root.AddChildNs('g', 'urn:q', 'x<y');
    Root.AddChildNs('p:h', 'urn:o');
    Root.AddChildNs('i', 'urn:s');
    Root.AddChildNs('p:j', '');
    Assert.AreEqual<RawByteString>('<r xmlns:p="urn:q"><p:a xmlns:p="urn:p"/><b xmlns="urn:p"/><p:c/><d/>' +
      '<q:e xmlns:q="urn:q"/><p:f/><p:g>x&lt;y</p:g><p:h xmlns:p="urn:o"/><i xmlns="urn:s"/><p:j/></r>', Root.Xml);
    var Child := Root.FirstChild;
    for var URI in NamespaceURIs do
    begin
      Assert.AreEqual<RawByteString>(URI, Child.NamespaceURI, UTF8ToString(Child.Xml));
      Child := Child.NextSibling;
    end;
  finally
    xmlFreeDoc(Doc);
  end;
  Assert.AreEqual<NativeUInt>(Used, xmlMemUsed, 'libxml2 memory');
end;

// RemoveChild, ReplaceChild and RemoveAttributeNode of the helpers change the node they work
// on and nothing else: no declaration lands on the parent, and what stays keeps its prefixes
// even where two prefixes are bound to one namespace. A node that is not a child is refused
// with nil, and so is a node put under itself.
procedure TXMLHelpersTest.TestRemoveAndReplaceLeaveTheParentAlone;
const
  Source = '<r xmlns:a="urn:u" xmlns:b="urn:u"><s xmlns:q="urn:q" q:at="1"><b:x/></s><t/><u/></r>';
begin
  LX2Lib.Initialize;
  var Used := xmlMemUsed;
  var Doc := xmlDoc.Create(Source, []);
  try
    var Root := Doc.documentElement;
    var S := Root.FirstElementChild;
    var T := S.NextElementSibling;
    xmlFreeNode(Root.RemoveChild(T.NextElementSibling));
    Assert.AreEqual<RawByteString>('<r xmlns:a="urn:u" xmlns:b="urn:u"><s xmlns:q="urn:q" q:at="1"><b:x/></s>' +
      '<t/></r>', Root.Xml, 'RemoveChild');
    xmlFreeNode(Root.ReplaceChild(Doc.CreateElement('n'), T));
    Assert.AreEqual<RawByteString>('<r xmlns:a="urn:u" xmlns:b="urn:u"><s xmlns:q="urn:q" q:at="1"><b:x/></s>' +
      '<n/></r>', Root.Xml, 'ReplaceChild');
    S.RemoveAttributeNode(S.properties);
    Assert.AreEqual<RawByteString>('<r xmlns:a="urn:u" xmlns:b="urn:u"><s xmlns:q="urn:q"><b:x/></s><n/></r>',
      Root.Xml, 'RemoveAttributeNode');

    var X := S.FirstElementChild;
    var M := Doc.CreateElement('m');
    try
      Assert.IsTrue(Root.RemoveChild(X) = nil, 'RemoveChild of a grandchild');
      Assert.IsTrue(Root.ReplaceChild(M, X) = nil, 'ReplaceChild of a grandchild');
      Assert.IsTrue(Root.InsertBefore(M, X) = nil, 'InsertBefore a grandchild');
      Assert.IsTrue(S.ReplaceChild(Root, X) = nil, 'ReplaceChild with an ancestor');
      Assert.IsTrue(S.AppendChild(Root) = nil, 'AppendChild of an ancestor');
      Assert.IsTrue(S.InsertBefore(S, X) = nil, 'InsertBefore of the node itself');
      Assert.AreEqual<RawByteString>('<r xmlns:a="urn:u" xmlns:b="urn:u"><s xmlns:q="urn:q"><b:x/></s><n/></r>',
        Root.Xml, 'refused');
    finally
      xmlFreeNode(M);
    end;
  finally
    xmlFreeDoc(Doc);
  end;
  Assert.AreEqual<NativeUInt>(Used, xmlMemUsed, 'libxml2 memory');
end;

{ TXMLDOMTest }

// The elements are indexed in document order by the first XPath query, once: the index
// is what keeps the sorting of results linear in documents of thousands of siblings.
procedure TXMLHelpersTest.TestXPathIndexesElementsOnDemand;
begin
  var doc := xmlDoc.Create('<r><a/><b/><c/></r>', []);
  Assert.AreNotEqual<Pointer>(doc, nil);
  try
    Assert.IsFalse(doc.ElementsOrdered, 'a fresh document is not indexed');
    Assert.AreEqual<Integer>(4, Length(doc.documentElement.SelectNodes('//*')));
    Assert.IsTrue(doc.ElementsOrdered, 'the first query indexes the document');
    Assert.IsTrue(NativeInt(doc.documentElement.content) < 0, 'the index is a negative number in content');
  finally
    xmlFreeDoc(doc);
  end;
end;

// Moving an element that carries an index drops the mark, so the next query indexes the
// document again and reports the new order; a stale index would have kept the old one.
procedure TXMLHelpersTest.TestXPathOrderSurvivesMovedElements;
begin
  var doc := xmlDoc.Create('<r><a/><b/><c/></r>', []);
  Assert.AreNotEqual<Pointer>(doc, nil);
  try
    var root := doc.documentElement;
    var a := root.children;
    var b := a.next;
    var c := b.next;
    Assert.AreEqual<Integer>(3, Length(root.SelectNodes('/r/*')));   // indexes a, b, c
    root.AppendChild(root.RemoveChild(a));                            // b, c, a
    Assert.IsFalse(doc.ElementsOrdered, 'moving an indexed element drops the mark');
    var nodes := root.SelectNodes('/r/*');
    Assert.AreEqual<Integer>(3, Length(nodes));
    Assert.AreEqual<Pointer>(b, nodes[0]);
    Assert.AreEqual<Pointer>(c, nodes[1]);
    Assert.AreEqual<Pointer>(a, nodes[2]);
    Assert.AreEqual<Pointer>(a, root.SelectSingleNode('(//*)[last()]'));
    Assert.IsTrue(doc.ElementsOrdered, 'the query after the move indexed again');
  finally
    xmlFreeDoc(doc);
  end;
end;

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

// As in MSXML, an element created with a prefix that is declared only afterwards keeps the
// prefix; written out and parsed again, it lands in the declared namespace.
procedure TXMLDOMTest.TestCreateElementKeepsUndeclaredPrefix;
begin
  var doc := CoCreateXMLDocument;
  var root := doc.CreateElement('ns1:File');
  doc.DocumentElement := root;
  root.SetAttribute('xmlns:ns1', 'urn:file');
  root.AddChild('ns1:Document');
  Assert.AreEqual('ns1:File', root.NodeName);
  Assert.AreEqual('<ns1:File xmlns:ns1="urn:file"><ns1:Document/></ns1:File>', root.Xml);

  // An attribute created before it has an owner element takes its value and binds its
  // prefix when attached.
  var attr := doc.CreateNode(NODE_ATTRIBUTE, 'ns1:Version', '') as IXMLAttribute;
  attr.Value := '1';
  Assert.AreEqual('1', attr.Value);
  root.Attributes.SetNamedItem(attr);
  Assert.AreEqual('1', root.GetAttribute('ns1:Version'));

  var copy := CoCreateXMLDocument;
  Assert.IsTrue(copy.LoadXML(root.Xml));
  Assert.AreEqual('urn:file', copy.DocumentElement.NamespaceURI);
  Assert.AreEqual('File', copy.DocumentElement.LocalName);
end;

// The copy of an element is an element: code that keeps it in an IXMLElement, or a script
// variable of the element type, must not get a bare node.
procedure TXMLDOMTest.TestCloneNodeOfElementIsElement;
begin
  var doc := CoCreateXMLDocument;
  Assert.IsTrue(doc.LoadXML('<Request><Package/><Payment><Sum>1</Sum></Payment></Request>'));
  var payment := doc.SelectSingleNode('//Payment');
  var copy := payment.CloneNode(True);
  Assert.IsTrue(Supports(copy, IXMLElement), 'clone supports IXMLElement');
  Assert.IsTrue((copy as TObject) is TXMLElement, 'clone is a TXMLElement');

  var package := doc.SelectSingleNode('//Package');
  var added := package.AppendChild(copy);
  Assert.IsTrue((added as TObject) is TXMLElement, 'appended node is a TXMLElement');
  Assert.AreEqual('<Package><Payment><Sum>1</Sum></Payment></Package>', package.Xml);
end;

// A simple path (`//name`, no predicates) takes the fast evaluator, and a query issued on the
// document starts from the document node. That node has no name when the document was
// parsed from memory, and it is not an element, so it must never be compared with a step.
procedure TXMLDOMTest.TestSimplePathFromDocumentParsedFromMemory;
begin
  var doc := CoCreateXMLDocument;
  Assert.IsTrue(doc.LoadXML('<e:Envelope xmlns:e="urn:env"><e:Header/><e:Body><item/></e:Body></e:Envelope>'));
  Assert.IsNotNull(doc.SelectSingleNode('//e:Envelope'), 'prefixed root');
  Assert.IsNotNull(doc.SelectSingleNode('//e:Header'), 'prefixed descendant');
  Assert.IsNotNull(doc.SelectSingleNode('//item'), 'plain descendant');
  Assert.IsNotNull(doc.SelectSingleNode('/e:Envelope/e:Body/item'), 'absolute path');
  Assert.IsNull(doc.SelectSingleNode('//e:Missing'), 'no such element');
end;

// DOM: insertBefore with a nil reference node appends. The usual source of the nil is
// parent.firstChild of an empty parent.
procedure TXMLDOMTest.TestInsertBeforeNilAppends;
begin
  var doc := CoCreateXMLDocument;
  Assert.IsTrue(doc.LoadXML('<root><head/></root>'));
  var head := doc.SelectSingleNode('//head');
  var first := doc.CreateElement('first');
  head.InsertBefore(first, head.FirstChild);
  Assert.AreEqual('<head><first/></head>', head.Xml);
  head.InsertBefore(doc.CreateElement('zero'), head.FirstChild);
  Assert.AreEqual('<head><zero/><first/></head>', head.Xml);
  head.InsertBefore(doc.CreateElement('last'), nil);
  Assert.AreEqual('<head><zero/><first/><last/></head>', head.Xml);
end;

// The template matches the root element as well as the document node, so the result is the
// same whether processing starts at the document or at the transformed element.
function CopyItemStylesheet: IXMLDocument;
begin
  Result := CoCreateXMLDocument;
  Assert.IsTrue(Result.LoadXML(
    '<xsl:stylesheet version="1.0" xmlns:xsl="' + XsltNs + '">' +
    '<xsl:template match="/ | root"><out><xsl:value-of select="/root/item"/></out></xsl:template>' +
    '</xsl:stylesheet>'));
end;

// transformNodeToObject, as in MSXML: the output document takes the result in place of what
// it held, the source stays as it was and can be transformed again.
procedure TXMLDOMTest.TestTransformNodeToObjectKeepsTheSource;
begin
  var Source := CoCreateXMLDocument;
  Assert.IsTrue(Source.LoadXML('<root><item>first</item></root>'));
  var Style := CopyItemStylesheet;
  var Output := CoCreateXMLDocument;
  Assert.IsTrue(Output.LoadXML('<previous/>'));

  Assert.IsTrue(Source.TransformNodeToObject(Style, Output));
  Assert.AreEqual('<out>first</out>', Output.DocumentElement.Xml);
  Assert.IsTrue(Output.DocumentElement.OwnerDocument = Output, 'the result belongs to the output wrapper');
  Assert.AreEqual('<root><item>first</item></root>', Source.DocumentElement.Xml, 'the source is intact');

  Source.SelectSingleNode('/root/item').Text := 'second';
  Assert.IsTrue(Source.TransformNodeToObject(Style, Output));
  Assert.AreEqual('<out>second</out>', Output.DocumentElement.Xml, 'the second result replaces the first');
  Assert.AreEqual('<root><item>second</item></root>', Source.DocumentElement.Xml);
end;

// The same through an element of the source: neither the element nor its document is freed.
procedure TXMLDOMTest.TestTransformElementToObjectKeepsTheSource;
begin
  var Source := CoCreateXMLDocument;
  Assert.IsTrue(Source.LoadXML('<root><item>first</item></root>'));
  var Root := Source.DocumentElement;
  var Output := CoCreateXMLDocument;

  Assert.IsTrue(Root.TransformNodeToObject(CopyItemStylesheet, Output));
  Assert.AreEqual('<out>first</out>', Output.DocumentElement.Xml);
  Assert.IsTrue(Output.DocumentElement.OwnerDocument = Output, 'the result belongs to the output wrapper');
  Assert.AreEqual('<root><item>first</item></root>', Root.Xml, 'the element is intact');
  Assert.IsTrue(Root.OwnerDocument = Source, 'the element stays in its document');
  Assert.AreEqual('first', Source.SelectSingleNode('/root/item').Text, 'the source document is intact');
end;

// Interface properties carry no RTTI, so IDispatch takes member names from the implementing
// class. Every accessor Get_X/Set_X of an implemented interface therefore has to resolve as
// X: a property the class declares under another name is invisible to late-bound callers.
procedure CollectUnresolvedAccessors(const What: string; const Obj: IDispatch; Missing: TStrings);
begin
  Assert.IsNotNull(Obj, What);
  var Context := TRttiContext.Create;
  var Cls := (Obj as TObject).ClassType;
  for var Intf in (Context.GetType(Cls) as TRttiInstanceType).GetImplementedInterfaces do
    for var Method in Intf.GetMethods do
    begin
      if not (Method.Name.StartsWith('Get_', True) or Method.Name.StartsWith('Set_', True)) then
        Continue;
      // IXMLAttributes.Get_Attr is the typed reader of Item, not a property of its own.
      if SameText(Method.Name, 'Get_Attr') then
        Continue;
      var Name: WideString := Method.Name.Substring(4);
      var DispId: Integer;
      if Obj.GetIDsOfNames(GUID_NULL, @Name, 1, 0, @DispId) <> S_OK then
      begin
        var Entry := Cls.ClassName + '.' + string(Name);
        if Missing.IndexOf(Entry) < 0 then
          Missing.Add(Entry);
      end;
    end;
end;

procedure TXMLDOMTest.TestDispatchNamesFollowInterfaceProperties;
const
  Xsd =
    '<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">' +
    '<xs:element name="e" type="xs:string"/></xs:schema>';
begin
  var doc := CoCreateXMLDocument;
  Assert.IsTrue(doc.LoadXML('<?pi data?><!DOCTYPE root [<!ENTITY ent "value">]>' +
    '<root xmlns:p="urn:p" a="1"><!--c--><child>text&ent;</child><![CDATA[raw]]></root>'));
  var root := doc.DocumentElement;

  var schemas := CoCreateSchemaCollection;
  var schema := CoCreateXMLDocument;
  Assert.IsTrue(schema.LoadXML(Xsd));
  schemas.Add('', schema);

  var broken := CoCreateXMLDocument;
  Assert.IsFalse(broken.LoadXML('<root>'));

  var Missing := TStringList.Create;
  try
    CollectUnresolvedAccessors('doc', doc, Missing);
    CollectUnresolvedAccessors('doc.CreateDocumentFragment', doc.CreateDocumentFragment, Missing);
    CollectUnresolvedAccessors('root', root, Missing);
    CollectUnresolvedAccessors('root.ChildNodes', root.ChildNodes, Missing);
    CollectUnresolvedAccessors('root.ChildNodes.GetEnumerator', root.ChildNodes.GetEnumerator, Missing);
    CollectUnresolvedAccessors('root.SelectNodes(''//child'')', root.SelectNodes('//child'), Missing);
    CollectUnresolvedAccessors('root.GetElementsByTagName(''child'')', root.GetElementsByTagName('child'), Missing);
    CollectUnresolvedAccessors('root.Attributes', root.Attributes, Missing);
    CollectUnresolvedAccessors('root.Attributes.GetEnumerator', root.Attributes.GetEnumerator, Missing);
    for var I := 0 to root.Attributes.Length - 1 do
      CollectUnresolvedAccessors('root.Attributes[I]', root.Attributes[I], Missing);
    for var Node in doc.ChildNodes do
      CollectUnresolvedAccessors('Node', Node, Missing);
    for var Node in root.ChildNodes do
      CollectUnresolvedAccessors('Node', Node, Missing);
    for var Node in doc.SelectSingleNode('//child').ChildNodes do
      CollectUnresolvedAccessors('Node', Node, Missing);
    CollectUnresolvedAccessors('schemas', schemas, Missing);
    CollectUnresolvedAccessors('broken.Errors', broken.Errors, Missing);
    CollectUnresolvedAccessors('broken.Errors.GetEnumerator', broken.Errors.GetEnumerator, Missing);
    CollectUnresolvedAccessors('broken.ParseError', broken.ParseError, Missing);

    Assert.AreEqual('', Missing.CommaText);
  finally
    Missing.Free;
  end;
end;

// The way a script reads a document: every step is a late-bound call on a Variant.
procedure TXMLDOMTest.TestLateBoundNodeListItem;
begin
  var doc := CoCreateXMLDocument;
  Assert.IsTrue(doc.LoadXML('<root><first name="a"/><second name="b"/></root>'));

  var List: Variant := doc.DocumentElement.ChildNodes as IDispatch;
  Assert.AreEqual(2, Integer(List.length));
  Assert.AreEqual('second', string(List.item[1].nodeName));
  Assert.AreEqual('b', string(List.item[1].attributes.item[0].nodeValue));

  var Found: Variant := doc.SelectNodes('//first') as IDispatch;
  Assert.AreEqual('first', string(Found.item[0].nodeName));

  var brokenDoc := CoCreateXMLDocument;
  Assert.IsFalse(brokenDoc.LoadXML('<root>'));
  var Broken: Variant := brokenDoc as IDispatch;
  Assert.IsTrue(Integer(Broken.errors.count) > 0);
  Assert.AreEqual(string(Broken.parseError.reason), string(Broken.errors.item[0].reason));
end;

// A late-bound call names a method and brings arguments; which overload it means follows
// from their number and types.
procedure TXMLDOMTest.TestLateBoundCallPicksTheOverload;
begin
  var Doc: Variant := CoCreateXMLDocument as IDispatch;
  Assert.IsTrue(Boolean(Doc.loadXML('<root><item/></root>')));
  Assert.IsFalse(Boolean(Doc.loadXML('<root>')));
  Assert.IsTrue(Boolean(Doc.loadXML('<root><item/></root>')));

  var Item: Variant := Doc.documentElement.firstChild;
  Item.setAttribute('text', 'value');
  Item.setAttribute('number', 42);
  Item.setAttribute('flag', True);
  Assert.AreEqual('value', string(Item.getAttribute('text')));
  Assert.AreEqual('42', string(Item.getAttribute('number')));
  Assert.AreEqual('1', string(Item.getAttribute('flag')));

  Assert.IsTrue(string(Doc.toString(True)).Contains('<item'));
  Assert.IsTrue(string(Doc.toString('windows-1251', False)).Contains('windows-1251'));
end;

// An object handed to a late-bound caller carries exactly the caller's reference: once the
// caller's variants are gone, so are the node wrappers. Wrappers are counted in debug
// builds only.
procedure TXMLDOMTest.TestLateBoundResultsAreReleased;

  procedure Walk(const Doc: IXMLDocument);
  begin
    var Root: Variant := Doc.DocumentElement as IDispatch;
    for var I := 1 to 10 do
    begin
      Assert.AreEqual('first', string(Root.childNodes.item[0].nodeName));
      Assert.AreEqual('first', string(Root.firstChild.nodeName));
      Assert.AreEqual('a', string(Root.selectSingleNode('//first').getAttribute('name')));
    end;
  end;

begin
{$IFNDEF DEBUG}
  Assert.Pass('node wrappers are counted in a debug build only');
{$ENDIF}
  var doc := CoCreateXMLDocument;
  Assert.IsTrue(doc.LoadXML('<root><first name="a"/></root>'));
  var Before := DebugObjectCount;
  Walk(doc);
  Assert.AreEqual<NativeInt>(Before, DebugObjectCount);
end;

// Names of the list's items by index, last to first and then first to last, so that a
// remembered position is used in both directions.
function NamesByIndex(const List: IXMLNodeList): string;
begin
  var Count := List.Length;
  var Backward := '';
  for var I := Count - 1 downto 0 do
    Backward := List[I].NodeName + ' ' + Backward;
  Result := '';
  for var I := 0 to Count - 1 do
    Result := Result + List[I].NodeName + ' ';
  Assert.AreEqual(Result, Backward, 'forward and backward');
  Result := Result.TrimRight;
end;

function NamesBySiblings(const Node: IXMLNode): string;
begin
  Result := '';
  var Child := Node.FirstChild;
  while Child <> nil do
  begin
    Result := Result + Child.NodeName + ' ';
    Child := Child.NextSibling;
  end;
  Result := Result.TrimRight;
end;

// ChildNodes is live: after every change of the tree a list taken before the change shows
// the current children. Each change comes right after a read near the changed place, when
// the list remembers a position there.
procedure TXMLDOMTest.TestChildNodesFollowChanges;
begin
  var Doc := CoCreateXMLDocument;
  Assert.IsTrue(Doc.LoadXML('<r><a/><b/><c/><d/></r>'));
  var Root := Doc.DocumentElement;
  var List := Root.ChildNodes;
  Assert.AreEqual('a b c d', NamesByIndex(List));

  Assert.AreEqual('c', List[2].NodeName);
  Root.InsertBefore(Doc.CreateElement('x'), Root.FirstChild);
  Assert.AreEqual('b', List[2].NodeName, 'insert in front');
  Assert.AreEqual<NativeInt>(5, List.Length);
  Assert.AreEqual(NamesBySiblings(Root), NamesByIndex(List));

  Assert.AreEqual('c', List[3].NodeName);
  Root.RemoveChild(List[1]);
  Assert.AreEqual('d', List[3].NodeName, 'remove before the position');
  Assert.AreEqual('x b c d', NamesByIndex(List));

  Root.AppendChild(Doc.CreateElement('y'));
  Assert.AreEqual<NativeInt>(5, List.Length, 'append after the count was taken');
  Assert.AreEqual('y', List[4].NodeName);

  Assert.AreEqual('b', List[1].NodeName);
  Root.ReplaceChild(Doc.CreateElement('z'), List[1]);
  Assert.AreEqual('x z c d y', NamesByIndex(List));

  // Moving inside the document: the child leaves this list for another one
  List[2].AppendChild(List[0]);
  Assert.AreEqual('z c d y', NamesByIndex(List));
  Assert.AreEqual('x', List[1].ChildNodes[0].NodeName);

  // Moving between documents, in and out
  var Other := CoCreateXMLDocument;
  Assert.IsTrue(Other.LoadXML('<o><w/></o>'));
  Root.AppendChild(Other.DocumentElement.FirstChild);
  Assert.AreEqual('z c d y w', NamesByIndex(List));
  Other.DocumentElement.AppendChild(List[0]);
  Assert.AreEqual('c d y w', NamesByIndex(List));
  Assert.AreEqual('z', Other.DocumentElement.ChildNodes[0].NodeName);

  Root.Text := 'plain';
  Assert.AreEqual<NativeInt>(1, List.Length, 'text replaces the children');
  Assert.AreEqual('#text', List[0].NodeName);
  Assert.IsNull(List[1]);
end;

procedure TXMLDOMTest.TestChildNodesOutOfRange;
begin
  var Doc := CoCreateXMLDocument;
  Assert.IsTrue(Doc.LoadXML('<r><a/><b/></r>'));
  var List := Doc.DocumentElement.ChildNodes;
  Assert.IsNull(List[-1]);
  Assert.IsNull(List[2], 'past the end before the count is known');
  Assert.AreEqual<NativeInt>(2, List.Length);
  Assert.IsNull(List[2], 'past the end after the count is known');
  Assert.AreEqual('b', List[1].NodeName);

  var Empty := Doc.CreateElement('e').ChildNodes;
  Assert.AreEqual<NativeInt>(0, Empty.Length);
  Assert.IsNull(Empty[0]);
end;

// xsl:strip-space removes the whitespace text nodes from the source document itself, inside
// libxslt; a list read before the transformation must not keep showing them.
procedure TXMLDOMTest.TestChildNodesFollowStripSpace;
begin
  // Loading drops whitespace-only text (XML_PARSE_NOBLANKS), so it is added by hand
  var Doc := CoCreateXMLDocument;
  Assert.IsTrue(Doc.LoadXML('<r/>'));
  var Root := Doc.DocumentElement;
  Root.AppendChild(Doc.CreateTextNode(' '));
  Root.AppendChild(Doc.CreateElement('a'));
  Root.AppendChild(Doc.CreateTextNode(' '));
  Root.AppendChild(Doc.CreateElement('b'));
  Root.AppendChild(Doc.CreateTextNode(' '));
  var List := Root.ChildNodes;
  Assert.AreEqual<NativeInt>(5, List.Length);
  Assert.AreEqual('b', List[3].NodeName);

  var Style := CoCreateXMLDocument;
  Assert.IsTrue(Style.LoadXML(
    '<xsl:stylesheet version="1.0" xmlns:xsl="' + XsltNs + '">' +
    '<xsl:strip-space elements="*"/><xsl:output method="text"/>' +
    '<xsl:template match="/">done</xsl:template></xsl:stylesheet>'));
  Assert.AreEqual('done', Doc.TransformNode(Style));

  Assert.AreEqual(NamesBySiblings(Root), NamesByIndex(List));
  Assert.AreEqual('a b', NamesByIndex(List));
end;

// The document's own list follows a reload: the wrapper stays, the libxml2 document under
// it is replaced.
procedure TXMLDOMTest.TestChildNodesFollowReload;
begin
  var Doc := CoCreateXMLDocument;
  Assert.IsTrue(Doc.LoadXML('<!--c--><r/>'));
  var List := Doc.ChildNodes;
  Assert.AreEqual('#comment r', NamesByIndex(List));
  Assert.IsTrue(Doc.LoadXML('<s/>'));
  Assert.AreEqual('s', NamesByIndex(List));
end;

// A list keeps its node, and through it the document, for as long as the list lives.
procedure TXMLDOMTest.TestChildNodesKeepTheNodeAlive;

  function ChildrenOfFreshDocument: IXMLNodeList;
  begin
    var Doc := CoCreateXMLDocument;
    Assert.IsTrue(Doc.LoadXML('<r><a/><b/></r>'));
    Result := Doc.DocumentElement.ChildNodes;
  end;

begin
  var List := ChildrenOfFreshDocument;
  Assert.AreEqual('a b', NamesByIndex(List));
end;

// Walking a list by index steps from the position of the previous call, also through a new
// list of the same node on every step, and building another document meanwhile does not
// make it start over. A walk from the first child on every step would take seconds here.
procedure TXMLDOMTest.TestChildNodesIndexedWalkIsLinear;
const
  Count = 40000;
begin
  var Source := CoCreateXMLDocument;
  Assert.IsTrue(Source.LoadXML('<r/>'));
  var Root := Source.DocumentElement;
  for var I := 1 to Count do
    Root.AddChild('i');

  var Target := CoCreateXMLDocument;
  Assert.IsTrue(Target.LoadXML('<t/>'));
  var Watch := TStopwatch.StartNew;
  for var I := 0 to Count - 1 do
  begin
    Assert.AreEqual('i', Root.ChildNodes[I].NodeName);
    Target.DocumentElement.AddChild('copy');
  end;
  var List := Root.ChildNodes;
  for var I := List.Length - 1 downto 0 do
    Assert.AreEqual('i', List[I].NodeName);
  Watch.Stop;

  Assert.AreEqual<NativeInt>(Count, Target.DocumentElement.ChildNodes.Length);
  Assert.IsTrue(Watch.ElapsedMilliseconds < 2000, Format('%d ms', [Watch.ElapsedMilliseconds]));
end;

// The id attributes of the list's elements by index, last to first and then first to last
function IdsByIndex(const List: IXMLNodeList): string;
begin
  var Count := List.Length;
  var Backward := '';
  for var I := Count - 1 downto 0 do
    Backward := (List[I] as IXMLElement).GetAttribute('id') + ' ' + Backward;
  Result := '';
  for var I := 0 to Count - 1 do
    Result := Result + (List[I] as IXMLElement).GetAttribute('id') + ' ';
  Assert.AreEqual(Result, Backward, 'forward and backward');
  Result := Result.TrimRight;
end;

// The list by tag name is live: after every change a list taken before it shows the
// matching elements of the current tree, nested ones included.
procedure TXMLDOMTest.TestElementsByTagNameFollowChanges;
begin
  var Doc := CoCreateXMLDocument;
  Assert.IsTrue(Doc.LoadXML('<r><a id="1"/><b><a id="2"/><c/></b><a id="3"/></r>'));
  var Root := Doc.DocumentElement;
  var List := Doc.GetElementsByTagName('a');
  Assert.AreEqual('1 2 3', IdsByIndex(List));

  Assert.AreEqual('2', (List[1] as IXMLElement).GetAttribute('id'));
  var New := Doc.CreateElement('a');
  New.SetAttribute('id', '0');
  Root.InsertBefore(New, Root.FirstChild);
  Assert.AreEqual('1', (List[1] as IXMLElement).GetAttribute('id'), 'insert in front');
  Assert.AreEqual('0 1 2 3', IdsByIndex(List));

  // An element added deep inside, after the count was taken
  Assert.AreEqual<NativeInt>(4, List.Length);
  New := Doc.CreateElement('a');
  New.SetAttribute('id', '4');
  Root.ChildNodes[2].ChildNodes[1].AppendChild(New);
  Assert.AreEqual('0 1 2 4 3', IdsByIndex(List));

  Assert.AreEqual('2', (List[2] as IXMLElement).GetAttribute('id'));
  Root.RemoveChild(Root.ChildNodes[2]);
  Assert.AreEqual('0 1 3', IdsByIndex(List), 'a subtree removed');

  Root.Text := 'plain';
  Assert.AreEqual<NativeInt>(0, List.Length);
  Assert.IsNull(List[0]);
end;

// The list selects by the qualified name, so it follows the prefix of an element: here
// the declaration of the prefix is removed and the element is left without it.
procedure TXMLDOMTest.TestElementsByTagNameFollowPrefix;
begin
  var Doc := CoCreateXMLDocument;
  Assert.IsTrue(Doc.LoadXML('<r><p:a xmlns:p="urn:p" id="1"/><a id="2"/></r>'));
  var Prefixed := Doc.GetElementsByTagName('p:a');
  var Plain := Doc.GetElementsByTagName('a');
  Assert.AreEqual('1', IdsByIndex(Prefixed));
  Assert.AreEqual('2', IdsByIndex(Plain));

  (Doc.DocumentElement.FirstChild as IXMLElement).Attributes.RemoveNamedItem('xmlns:p');
  Assert.AreEqual('', IdsByIndex(Prefixed));
  Assert.AreEqual('1 2', IdsByIndex(Plain));
end;

// The list of a document reads the current root element: it follows a reload and a new
// root, and it keeps the document alive.
procedure TXMLDOMTest.TestElementsByTagNameFollowTheRoot;

  function ElementsOfFreshDocument: IXMLNodeList;
  begin
    var Doc := CoCreateXMLDocument;
    Assert.IsTrue(Doc.LoadXML('<r><a id="1"/><a id="2"/></r>'));
    Result := Doc.GetElementsByTagName('a');
  end;

begin
  Assert.AreEqual('1 2', IdsByIndex(ElementsOfFreshDocument));

  var Doc := CoCreateXMLDocument;
  Assert.IsTrue(Doc.LoadXML('<r><a id="1"/></r>'));
  var List := Doc.GetElementsByTagName('a');
  Assert.AreEqual('1', IdsByIndex(List));
  Assert.IsTrue(Doc.LoadXML('<s><a id="7"/><a id="8"/></s>'));
  Assert.AreEqual('7 8', IdsByIndex(List), 'reload');

  var Root := Doc.CreateElement('t');
  var A := Doc.CreateElement('a');
  A.SetAttribute('id', '9');
  Root.AppendChild(A);
  Doc.DocumentElement := Root;
  Assert.AreEqual('9', IdsByIndex(List), 'new root');
end;

procedure TXMLDOMTest.TestElementsByTagNameOutOfRange;
begin
  var Doc := CoCreateXMLDocument;
  Assert.IsTrue(Doc.LoadXML('<r><a/><b/><a/></r>'));
  var List := Doc.GetElementsByTagName('a');
  Assert.IsNull(List[-1]);
  Assert.IsNull(List[2], 'past the end before the count is known');
  Assert.AreEqual<NativeInt>(2, List.Length);
  Assert.IsNull(List[2], 'past the end after the count is known');
  Assert.IsNotNull(List[1]);

  var None := Doc.GetElementsByTagName('z');
  Assert.AreEqual<NativeInt>(0, None.Length);
  Assert.IsNull(None[0]);
end;

// Walking a list by tag name by index steps from the previous position in both directions,
// in the whole document and among the children of an element; a walk from the start on
// every step would take seconds here.
procedure TXMLDOMTest.TestElementsByTagNameIndexedWalkIsLinear;
const
  Groups = 200;
  PerGroup = 100;
begin
  var Doc := CoCreateXMLDocument;
  Assert.IsTrue(Doc.LoadXML('<r/>'));
  for var G := 1 to Groups do
  begin
    var Group := Doc.DocumentElement.AddChild('g');
    for var I := 1 to PerGroup do
    begin
      Group.AddChild('i');
      Group.AddChild('skip');
    end;
  end;

  var Watch := TStopwatch.StartNew;
  var List := Doc.GetElementsByTagName('i');
  Assert.AreEqual<NativeInt>(Groups * PerGroup, List.Length);
  for var I := List.Length - 1 downto 0 do
    Assert.AreEqual('i', List[I].NodeName);
  for var I := 0 to List.Length - 1 do
    Assert.AreEqual('i', List[I].NodeName);

  var Children := (Doc.DocumentElement as IXMLElement).GetElementsByTagName('g');
  for var I := 0 to Children.Length - 1 do
    Assert.AreEqual('g', Children[I].NodeName);
  Watch.Stop;

  Assert.IsTrue(Watch.ElapsedMilliseconds < 2000, Format('%d ms', [Watch.ElapsedMilliseconds]));
end;

// As in MSXML: the list of an element holds its descendants at any depth but not the
// element itself, the list of a document holds the root element too; '*' is every
// element and an empty name is none.
procedure TXMLDOMTest.TestElementsByTagNameAsInMSXML;
begin
  var Doc := CoCreateXMLDocument;
  Assert.IsTrue(Doc.LoadXML('<a id="0"><a id="1"><a id="2"/></a><b><a id="3"/></b></a>'));
  var Root := Doc.DocumentElement;
  Assert.AreEqual('0 1 2 3', IdsByIndex(Doc.GetElementsByTagName('a')));
  Assert.AreEqual('1 2 3', IdsByIndex(Root.GetElementsByTagName('a')));
  Assert.AreEqual('2', IdsByIndex((Root.FirstChild as IXMLElement).GetElementsByTagName('a')));
  Assert.AreEqual('a a a b a', NamesByIndex(Doc.GetElementsByTagName('*')));
  Assert.AreEqual('a a b a', NamesByIndex(Root.GetElementsByTagName('*')));
  Assert.AreEqual<NativeInt>(0, Doc.GetElementsByTagName('').Length);
end;

// By tag name the qualified name counts, prefix included; by namespace (DOM Level 2) the
// namespace URI and the local name count, whatever the prefix, with '*' for any and an
// empty URI for no namespace.
procedure TXMLDOMTest.TestElementsByTagNameNSAsInDOM;
begin
  var Doc := CoCreateXMLDocument;
  Assert.IsTrue(Doc.LoadXML(
    '<r xmlns:p="urn:p"><p:a id="1"/><a id="2"/><x:a xmlns:x="urn:p" id="3"/>' +
    '<d xmlns="urn:d"><a id="4"/></d></r>'));
  Assert.AreEqual('1', IdsByIndex(Doc.GetElementsByTagName('p:a')));
  Assert.AreEqual('2 4', IdsByIndex(Doc.GetElementsByTagName('a')));

  Assert.AreEqual('1 3', IdsByIndex(Doc.GetElementsByTagNameNS('urn:p', 'a')));
  Assert.AreEqual('2', IdsByIndex(Doc.GetElementsByTagNameNS('', 'a')));
  Assert.AreEqual('4', IdsByIndex(Doc.GetElementsByTagNameNS('urn:d', 'a')));
  Assert.AreEqual('1 2 3 4', IdsByIndex(Doc.GetElementsByTagNameNS('*', 'a')));
  Assert.AreEqual('d a', NamesByIndex(Doc.GetElementsByTagNameNS('urn:d', '*')));
end;

// A document without a root element gives an empty list, which shows the root once it
// appears.
procedure TXMLDOMTest.TestElementsByTagNameOfDocumentWithoutRoot;
begin
  var Doc := CoCreateXMLDocument;
  var List := Doc.GetElementsByTagName('*');
  Assert.IsNotNull(List);
  Assert.AreEqual<NativeInt>(0, List.Length);
  Doc.DocumentElement := Doc.CreateElement('r');
  Assert.AreEqual('r', NamesByIndex(List));
end;

// The DTD is not walked: libxml2 keeps the parsed text of an entity under its
// declaration, and those elements are not part of the document.
procedure TXMLDOMTest.TestElementsByTagNameSkipsTheDTD;
begin
  var Doc := CoCreateXMLDocument;
  Assert.IsTrue(Doc.LoadXML('<!DOCTYPE r [<!ENTITY e "<x/>">]><r>&e;</r>'));
  Assert.AreEqual('r x', NamesByIndex(Doc.GetElementsByTagName('*')));
end;

// GetElementsByTagNameNS of an element, as in DOM Level 2: the descendants by namespace and
// local name, whatever the prefix; the element itself is not in the list even when it
// matches, and the list follows changes like the other lists by name.
procedure TXMLDOMTest.TestElementsByTagNameNSOfElement;
begin
  var Doc := CoCreateXMLDocument;
  Assert.IsTrue(Doc.LoadXML(
    '<p:a xmlns:p="urn:p" id="0"><p:a id="1"><x:a xmlns:x="urn:p" id="2"/></p:a>' +
    '<a id="3"/><d xmlns="urn:d"><a id="4"/></d></p:a>'));
  var Root := Doc.DocumentElement;
  Assert.AreEqual('1 2', IdsByIndex(Root.GetElementsByTagNameNS('urn:p', 'a')));
  Assert.AreEqual('3', IdsByIndex(Root.GetElementsByTagNameNS('', 'a')));
  Assert.AreEqual('1 2 3 4', IdsByIndex(Root.GetElementsByTagNameNS('*', 'a')));
  Assert.AreEqual('d a', NamesByIndex(Root.GetElementsByTagNameNS('urn:d', '*')));
  Assert.AreEqual('2', IdsByIndex((Root.FirstChild as IXMLElement).GetElementsByTagNameNS('urn:p', '*')));

  var List := Root.GetElementsByTagNameNS('urn:d', 'a');
  Assert.AreEqual('4', IdsByIndex(List));
  var New := Doc.CreateElementNs('urn:d', 'a');
  New.SetAttribute('id', '5');
  Root.AppendChild(New);
  Assert.AreEqual('4 5', IdsByIndex(List));
end;

// The list of a document by namespace walks the document itself, so it follows every change
// of the root: a new root element, a root replaced or removed through the document's own
// children, a reload, a root set on a document that had none.
procedure TXMLDOMTest.TestElementsByTagNameNSFollowTheRoot;
var
  Doc: IXMLDocument;

  function NewRoot(const Id: string): IXMLElement;
  begin
    Result := Doc.CreateElementNs('urn:p', 'a');
    Result.SetAttribute('id', Id);
    var Child := Doc.CreateElementNs('urn:p', 'a');
    Child.SetAttribute('id', Id + '.1');
    Result.AppendChild(Child);
  end;

  procedure SetRoot(const Id: string);
  begin
    Doc.DocumentElement := NewRoot(Id);
  end;

  procedure ReplaceRoot(const Id: string);
  begin
    Doc.ReplaceChild(NewRoot(Id), Doc.DocumentElement);
  end;

  procedure RemoveRoot;
  begin
    Doc.RemoveChild(Doc.DocumentElement);
  end;

  procedure AppendRoot(const Id: string);
  begin
    Doc.AppendChild(NewRoot(Id));
  end;

  function IdAt(const List: IXMLNodeList; Index: NativeInt): string;
  begin
    Result := (List[Index] as IXMLElement).GetAttribute('id');
  end;

begin
  Doc := CoCreateXMLDocument;
  var List := Doc.GetElementsByTagNameNS('urn:p', 'a');
  Assert.AreEqual<NativeInt>(0, List.Length, 'no root yet');

  SetRoot('1');
  Assert.AreEqual('1 1.1', IdsByIndex(List), 'root set');
  Assert.AreEqual('1.1', IdAt(List, 1));

  SetRoot('2');
  Assert.AreEqual('2 2.1', IdsByIndex(List), 'root replaced');

  ReplaceRoot('3');
  Assert.AreEqual('3 3.1', IdsByIndex(List), 'root replaced as a child of the document');

  RemoveRoot;
  Assert.AreEqual<NativeInt>(0, List.Length, 'root removed');
  Assert.IsNull(List[0]);

  AppendRoot('4');
  Assert.AreEqual('4 4.1', IdsByIndex(List), 'root appended to the document');

  Assert.IsTrue(Doc.LoadXML('<x:a xmlns:x="urn:p" id="5"><b><x:a id="5.1"/></b></x:a>'));
  Assert.AreEqual('5 5.1', IdsByIndex(List), 'reload');
end;

type
  // Reaches the libxml2 node under a DOM wrapper
  TXMLNodeAccess = class(TXMLNode);

// An XPath query leaves the element order index in the content field of every element (see
// TestXPathIndexesElementsOnDemand); SelectNodes always runs one, SelectSingleNode answers a
// simple path without XPath. TransformNode of an indexed element, the root as well as a
// nested one, gives the result and leaves the source as it was. The stylesheet has only the
// built-in rules, which put out the text of the subtree, so the result is the same whether
// processing starts at the document or at the element.
procedure TXMLDOMTest.TestTransformElementAfterXPathQuery;
begin
  var Source := CoCreateXMLDocument;
  Assert.IsTrue(Source.LoadXML('<root><item>first</item></root>'));
  var Root := Source.DocumentElement;
  var Item := Source.SelectNodes('//item')[0];
  Assert.IsTrue(NativeInt(TXMLNodeAccess(Root as TObject).NodePtr.content) < 0, 'the query indexed the root');
  Assert.IsTrue(NativeInt(TXMLNodeAccess(Item as TObject).NodePtr.content) < 0, 'the query indexed the item');
  var Style := CoCreateXMLDocument;
  Assert.IsTrue(Style.LoadXML(
    '<xsl:stylesheet version="1.0" xmlns:xsl="' + XsltNs + '"><xsl:output method="text"/></xsl:stylesheet>'));

  Assert.AreEqual('first', Root.TransformNode(Style));
  Assert.AreEqual('first', Item.TransformNode(Style));
  Assert.AreEqual('<root><item>first</item></root>', Source.DocumentElement.Xml, 'the source is intact');
  Assert.AreEqual('first', Source.SelectSingleNode('/root/item').Text, 'the next query still works');
end;

// Through an element as through the document, the result is in the xsl:output encoding:
// TransformNode and the string overload decode it from that encoding, the RawByteString
// carries its code page.
procedure TXMLDOMTest.TestTransformElementTagsResultWithOutputEncoding;
var
  S: RawByteString;
  U: string;
begin
  var Source := CoCreateXMLDocument;
  Assert.IsTrue(Source.LoadXML('<root><name>' + CyrillicHello + '</name></root>'));
  var Root := Source.DocumentElement;
  var Style := CoCreateXMLDocument;
  Assert.IsTrue(Style.LoadXML(TextStylesheet('windows-1251')));

  Assert.AreEqual(CyrillicHello, Root.TransformNode(Style));

  Assert.IsTrue(Root.Transform(Style, U));
  Assert.AreEqual(CyrillicHello, U);

  Assert.IsTrue(Root.Transform(Style, S));
  Assert.AreEqual<Word>(1251, StringCodePage(S));
  Assert.AreEqual<NativeInt>(Length(CyrillicHello), Length(S), 'single-byte encoding');
  Assert.AreEqual(CyrillicHello, string(S));
end;

// Every template writes what XSLT sees at its node: the position and size of the current node
// list, an absolute path, a global parameter, a global variable with select and one with a
// body, each counting the ancestors of its context node.
function StartNodeStylesheet: IXMLDocument;
begin
  Result := CoCreateXMLDocument;
  Assert.IsTrue(Result.LoadXML(
    '<xsl:stylesheet version="1.0" xmlns:xsl="' + XsltNs + '"><xsl:output method="text"/>' +
    '<xsl:param name="p" select="count(ancestor-or-self::node())"/>' +
    '<xsl:variable name="v" select="count(ancestor-or-self::node())"/>' +
    '<xsl:variable name="t"><xsl:value-of select="count(ancestor-or-self::node())"/></xsl:variable>' +
    '<xsl:template match="/">/[<xsl:apply-templates/>]</xsl:template>' +
    '<xsl:template match="*"><xsl:value-of select="name()"/>:<xsl:value-of select="position()"/>' +
    '/<xsl:value-of select="last()"/> abs=<xsl:value-of select="count(/root/item)"/>' +
    ' p=<xsl:value-of select="$p"/> v=<xsl:value-of select="$v"/> t=<xsl:value-of select="$t"/>' +
    '[<xsl:apply-templates/>]</xsl:template>' +
    '<xsl:template match="@*">@<xsl:value-of select="name()"/>=<xsl:value-of select="."/>' +
    ' t=<xsl:value-of select="$t"/></xsl:template>' +
    '<xsl:template match="text()">(<xsl:value-of select="."/>)</xsl:template>' +
    '</xsl:stylesheet>'));
end;

// A transform of a node starts at that node, as transformNode of MSXML does: the first
// template is chosen for the node itself, with position() and last() equal to 1, and the
// template for "/" fires for the document only. Global parameters and variables are evaluated
// at the document node, absolute paths address the whole document. The expected strings are
// what MSXML 6 gives for the same calls.
procedure TXMLDOMTest.TestTransformNodeStartsAtTheNodeAsInMSXML;
begin
  var Source := CoCreateXMLDocument;
  Assert.IsTrue(Source.LoadXML('<root a="1"><item>first</item><item>second<sub>x</sub></item></root>'));
  var Style := StartNodeStylesheet;

  Assert.AreEqual(
    '/[root:1/1 abs=2 p=1 v=1 t=1[item:1/2 abs=2 p=1 v=1 t=1[(first)]' +
    'item:2/2 abs=2 p=1 v=1 t=1[(second)sub:2/2 abs=2 p=1 v=1 t=1[(x)]]]]',
    Source.TransformNode(Style), 'document');
  Assert.AreEqual(
    'root:1/1 abs=2 p=1 v=1 t=1[item:1/2 abs=2 p=1 v=1 t=1[(first)]' +
    'item:2/2 abs=2 p=1 v=1 t=1[(second)sub:2/2 abs=2 p=1 v=1 t=1[(x)]]]',
    Source.DocumentElement.TransformNode(Style), 'root element');
  var Second := Source.SelectSingleNode('/root/item[2]');
  Assert.AreEqual(
    'item:1/1 abs=2 p=1 v=1 t=1[(second)sub:2/2 abs=2 p=1 v=1 t=1[(x)]]',
    Second.TransformNode(Style), 'nested element');
  Assert.AreEqual('@a=1 t=1', Source.SelectSingleNode('/root/@a').TransformNode(Style), 'attribute');
  Assert.AreEqual('(first)', Source.SelectSingleNode('/root/item[1]/text()').TransformNode(Style), 'text');

  var CopyStyle := CoCreateXMLDocument;
  Assert.IsTrue(CopyStyle.LoadXML(
    '<xsl:stylesheet version="1.0" xmlns:xsl="' + XsltNs + '">' +
    '<xsl:template match="/"><doc/></xsl:template>' +
    '<xsl:template match="item"><out n="{position()}"><xsl:value-of select="."/></out></xsl:template>' +
    '</xsl:stylesheet>'));
  var Output := CoCreateXMLDocument;
  Assert.IsTrue(Second.TransformNodeToObject(CopyStyle, Output));
  Assert.AreEqual('<out n="1">secondx</out>', Output.DocumentElement.Xml, 'TransformNodeToObject');
end;

// xsl:key builds its tables on the source document that libxslt keeps in the transform
// context, both for key() in expressions and for key() in match patterns. The expected
// strings are what MSXML 6 gives for the same calls; the source stays as it was.
procedure TXMLDOMTest.TestTransformWithKeysAsInMSXML;
const
  SourceXml = '<root><item cat="a">1</item><item cat="b">2</item><item cat="a">3</item></root>';
begin
  var Source := CoCreateXMLDocument;
  Assert.IsTrue(Source.LoadXML(SourceXml));
  var Style := CoCreateXMLDocument;
  Assert.IsTrue(Style.LoadXML(
    '<xsl:stylesheet version="1.0" xmlns:xsl="' + XsltNs + '"><xsl:output method="text"/>' +
    '<xsl:key name="k" match="item" use="@cat"/>' +
    '<xsl:template match="/ | root">[<xsl:for-each select="key(''k'', ''a'')"><xsl:value-of select="."/>' +
    '</xsl:for-each>|<xsl:apply-templates/>]</xsl:template>' +
    '<xsl:template match="item">(<xsl:value-of select="count(key(''k'', @cat))"/>)</xsl:template>' +
    '<xsl:template match="key(''k'', ''b'')">B</xsl:template>' +
    '</xsl:stylesheet>'));

  Assert.AreEqual('[13|[13|(2)B(2)]]', Source.TransformNode(Style), 'document');
  Assert.AreEqual('[13|(2)B(2)]', Source.DocumentElement.TransformNode(Style), 'root element');
  Assert.AreEqual('(2)', Source.SelectSingleNode('/root/item[1]').TransformNode(Style), 'first item');
  Assert.AreEqual('B', Source.SelectSingleNode('/root/item[2]').TransformNode(Style), 'second item');
  Assert.AreEqual(SourceXml, Source.DocumentElement.Xml, 'the source is intact');
  Assert.AreEqual('[13|[13|(2)B(2)]]', Source.TransformNode(Style), 'document again');
end;

// libxml2 memory in use. The debug allocator of a debug build accounts every byte the
// library holds; with the allocators of a release build the count stays 0.
function LibraryMemoryInUse: NativeUInt;
begin
  LX2Lib.Initialize;
  Result := xmlMemUsed;
end;

// The tests below make their changes in routines of their own: the results of calls are
// temporaries that live until their routine returns, and would hold the nodes and the
// documents the tests watch go.

// A root removed from the document and still referenced survives a reload of the document,
// as in MSXML: the node keeps its content, has no parent and is owned by the reloaded
// document. The libxml2 document it came from stays alive for it and goes with the last
// reference, as does everything else.
procedure TXMLDOMTest.TestRemovedRootSurvivesReload;
var
  [Weak] Released: IXMLDocument;
  Doc: IXMLDocument;
  Kept: IXMLElement;

  procedure RemoveRootAndReload;
  begin
    Doc := CoCreateXMLDocument;
    Released := Doc;
    Kept := Doc.CreateElementNs('urn:p', 'a');
    Kept.AppendChild(Doc.CreateElementNs('urn:p', 'b'));
    Doc.DocumentElement := Kept;
    Doc.RemoveChild(Kept);
    Assert.IsTrue(Doc.LoadXML('<r/>'));
  end;

  procedure UseTheRemovedRoot;
  begin
    Assert.AreEqual('<a xmlns="urn:p"><b xmlns="urn:p"/></a>', Kept.Xml);
    Assert.IsNull(Kept.ParentNode);
    Assert.IsTrue(Kept.OwnerDocument = Doc, 'the reloaded document owns the node, as in MSXML');
    Assert.AreEqual('<r/>', Doc.DocumentElement.Xml, 'the document holds the new content');
  end;

begin
  var Used := LibraryMemoryInUse;
  RemoveRootAndReload;
  UseTheRemovedRoot;
  Kept := nil;
  Assert.IsTrue(Released <> nil, 'the document lives as long as it is referenced');
  Doc := nil;
  Assert.IsTrue(Released = nil, 'the document goes with the last reference');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// An element created by the document and never inserted survives a reload as well. Here the
// document is let go first: the node keeps it alive, and it goes with the node.
procedure TXMLDOMTest.TestCreatedElementSurvivesReload;
var
  [Weak] Released: IXMLDocument;
  Doc: IXMLDocument;
  Kept: IXMLElement;

  procedure CreateAndReload;
  begin
    Doc := CoCreateXMLDocument;
    Released := Doc;
    Kept := Doc.CreateElement('o');
    Assert.IsTrue(Doc.LoadXML('<r/>'));
  end;

  procedure UseTheCreatedElement;
  begin
    Kept.SetAttribute('x', '1');
    Assert.AreEqual('<o x="1"/>', Kept.Xml);
    Assert.IsTrue(Kept.OwnerDocument = Doc, 'the reloaded document owns the node, as in MSXML');
  end;

begin
  var Used := LibraryMemoryInUse;
  CreateAndReload;
  UseTheCreatedElement;
  Doc := nil;
  Assert.IsTrue(Released <> nil, 'the node keeps the document alive');
  Assert.AreEqual('o', Kept.NodeName);
  Kept := nil;
  Assert.IsTrue(Released = nil, 'the document goes with the node');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// TransformNodeToObject puts the result into the output document in place of its content,
// as a reload does: nodes of the replaced content, removed or created and never inserted,
// stay usable and owned by the output document.
procedure TXMLDOMTest.TestTransformNodeToObjectKeepsDetachedNodes;
var
  [Weak] Released: IXMLDocument;
  Output: IXMLDocument;
  Removed, Created: IXMLNode;

  // The first transform of the process sets libxslt up for good
  procedure WarmUp;
  begin
    var Source := CoCreateXMLDocument;
    Assert.IsTrue(Source.LoadXML('<root/>'));
    Source.TransformNode(CopyItemStylesheet);
  end;

  procedure TransformIntoOutput;
  begin
    var Source := CoCreateXMLDocument;
    Assert.IsTrue(Source.LoadXML('<root><item>first</item></root>'));
    Output := CoCreateXMLDocument;
    Released := Output;
    Assert.IsTrue(Output.LoadXML('<previous><x/></previous>'));
    Removed := Output.DocumentElement.RemoveChild(Output.DocumentElement.FirstChild);
    Created := Output.CreateElement('o');
    Assert.IsTrue(Source.TransformNodeToObject(CopyItemStylesheet, Output));
  end;

  procedure UseTheDetachedNodes;
  begin
    Assert.AreEqual('<out>first</out>', Output.DocumentElement.Xml);
    Assert.AreEqual('<x/>', Removed.Xml);
    Assert.IsNull(Removed.ParentNode);
    Assert.IsTrue(Created.OwnerDocument = Output, 'the output document owns the node, as in MSXML');
    Created.AppendChild(Removed);
    Assert.AreEqual('<o><x/></o>', Created.Xml, 'the nodes of the replaced content work together');
  end;

begin
  WarmUp;
  var Used := LibraryMemoryInUse;
  TransformIntoOutput;
  UseTheDetachedNodes;
  Output := nil;
  Assert.IsTrue(Released <> nil, 'the nodes keep the output document alive');
  Removed := nil;
  Created := nil;
  Assert.IsTrue(Released = nil, 'the output document goes with the last node');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// Nodes of the content a reload replaces stay usable even if they were never detached, as
// in MSXML: the old root keeps its subtree and shows neither parent nor siblings, its
// descendants keep their parents, the reloaded document owns them all, and a node of the
// old content can be moved into the new one.
procedure TXMLDOMTest.TestReloadedContentStaysUsable;
var
  [Weak] Released: IXMLDocument;
  Doc: IXMLDocument;
  OldRoot, Item: IXMLNode;

  procedure LoadTwice;
  begin
    Doc := CoCreateXMLDocument;
    Released := Doc;
    Assert.IsTrue(Doc.LoadXML('<!--c--><root><item a="1"><sub/></item><last/></root>'));
    OldRoot := Doc.DocumentElement;
    Item := OldRoot.FirstChild;
    Assert.IsTrue(Doc.LoadXML('<new/>'));
  end;

  procedure UseTheOldContent;
  begin
    Assert.AreEqual('<root><item a="1"><sub/></item><last/></root>', OldRoot.Xml);
    Assert.IsNull(OldRoot.ParentNode, 'the old root is detached, as in MSXML');
    Assert.IsNull(OldRoot.PreviousSibling, 'the comment before it is no sibling of it any more');
    Assert.IsTrue((Item.ParentNode as TObject) = (OldRoot as TObject), 'the subtree stays');
    Assert.IsTrue(OldRoot.OwnerDocument = Doc, 'the reloaded document owns the old content');
    Assert.AreEqual('last', OldRoot.SelectSingleNode('last').NodeName, 'XPath over the old content');

    Doc.DocumentElement.AppendChild(Item);
    Assert.AreEqual('<new><item a="1"><sub/></item></new>', Doc.DocumentElement.Xml);
    Assert.AreEqual('<root><last/></root>', OldRoot.Xml);
  end;

begin
  var Used := LibraryMemoryInUse;
  LoadTwice;
  UseTheOldContent;
  Doc := nil;
  OldRoot := nil;
  Assert.IsTrue(Released <> nil, 'the moved item keeps the document alive');
  Item := nil;
  Assert.IsTrue(Released = nil, 'the document goes with the last node');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// A node moved to another document takes along the references of its whole subtree: a
// wrapper of a descendant keeps the target document alive, not the source.
procedure TXMLDOMTest.TestMovedSubtreeHoldsItsNewDocument;
var
  [Weak] Source: IXMLDocument;
  [Weak] Target: IXMLDocument;
  Inner: IXMLNode;

  procedure MoveSubtree;
  begin
    var FromDoc := CoCreateXMLDocument;
    Source := FromDoc;
    Assert.IsTrue(FromDoc.LoadXML('<r><a><b/></a></r>'));
    var ToDoc := CoCreateXMLDocument;
    Target := ToDoc;
    Assert.IsTrue(ToDoc.LoadXML('<s/>'));
    var Moved := FromDoc.DocumentElement.FirstChild;
    Inner := Moved.FirstChild;
    ToDoc.DocumentElement.AppendChild(Moved);
    Assert.AreEqual('<s><a><b/></a></s>', ToDoc.DocumentElement.Xml);
  end;

begin
  var Used := LibraryMemoryInUse;
  MoveSubtree;
  Assert.IsTrue(Source = nil, 'nothing holds the source document');
  Assert.IsTrue(Target <> nil, 'the inner node holds the target document');
  Inner := nil;
  Assert.IsTrue(Target = nil, 'the target document goes with the inner node');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// The list SelectNodes returns holds its document as a node does: its nodes stay usable
// after a reload of the document, as in MSXML, and the document goes with the list.
procedure TXMLDOMTest.TestSelectedNodesSurviveReload;
var
  [Weak] Released: IXMLDocument;
  Doc: IXMLDocument;
  List: IXMLNodeList;

  procedure SelectAndReload;
  begin
    Doc := CoCreateXMLDocument;
    Released := Doc;
    Assert.IsTrue(Doc.LoadXML('<r><a n="1"/><a n="2"/></r>'));
    List := Doc.SelectNodes('//a');
    Assert.IsTrue(Doc.LoadXML('<s/>'));
  end;

  procedure UseTheList;
  begin
    Assert.AreEqual<NativeInt>(2, List.Length);
    Assert.AreEqual('2', (List[1] as IXMLElement).GetAttribute('n'));
    Assert.IsTrue(List[0].OwnerDocument = Doc, 'the reloaded document owns the selected nodes');
  end;

begin
  var Used := LibraryMemoryInUse;
  SelectAndReload;
  UseTheList;
  Doc := nil;
  Assert.IsTrue(Released <> nil, 'the list keeps the document alive');
  List := nil;
  Assert.IsTrue(Released = nil, 'the document goes with the list');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// Setting the document element to the element already there changes nothing, as in MSXML:
// the root stays in the document with its content.
procedure TXMLDOMTest.TestDocumentElementSetToItself;
var
  [Weak] Released: IXMLDocument;
  Doc: IXMLDocument;
  Root: IXMLElement;

  procedure SetTheSameRoot;
  begin
    Doc := CoCreateXMLDocument;
    Released := Doc;
    Assert.IsTrue(Doc.LoadXML('<r><a/></r>'));
    Root := Doc.DocumentElement;
    Doc.DocumentElement := Doc.DocumentElement;
  end;

  procedure UseTheRoot;
  begin
    Assert.AreEqual('<r><a/></r>', Doc.DocumentElement.Xml);
    Assert.IsTrue((Doc.DocumentElement as TObject) = (Root as TObject), 'the same element');
    Assert.IsTrue((Root.ParentNode as TObject) = (Doc as TObject), 'still under the document');
    Assert.AreEqual('a', Root.FirstChild.NodeName);
  end;

begin
  var Used := LibraryMemoryInUse;
  SetTheSameRoot;
  UseTheRoot;
  Root := nil;
  Doc := nil;
  Assert.IsTrue(Released = nil, 'the document goes with the last reference');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// The root replaced by another document element stays usable, as in MSXML: detached, with
// its subtree, owned by the document, and it can be inserted again. A replaced root nothing
// refers to goes with the replacement.
procedure TXMLDOMTest.TestReplacedDocumentElementStaysUsable;
var
  [Weak] Released: IXMLDocument;
  Doc: IXMLDocument;
  OldRoot, Item: IXMLNode;

  procedure ReplaceTheRoot;
  begin
    Doc := CoCreateXMLDocument;
    Released := Doc;
    Assert.IsTrue(Doc.LoadXML('<!--c--><r><a/></r>'));
    OldRoot := Doc.DocumentElement;
    Item := OldRoot.FirstChild;
    Doc.DocumentElement := Doc.CreateElement('n');
  end;

  procedure UseTheOldRoot;
  begin
    Assert.AreEqual('<n/>', Doc.DocumentElement.Xml);
    Assert.AreEqual('#comment', Doc.DocumentElement.PreviousSibling.NodeName, 'the new root takes the place of the old one');
    Assert.AreEqual('<r><a/></r>', OldRoot.Xml);
    Assert.IsNull(OldRoot.ParentNode, 'the replaced root is detached');
    Assert.IsNull(OldRoot.PreviousSibling, 'the comment is no sibling of it any more');
    Assert.IsTrue(OldRoot.OwnerDocument = Doc, 'the document still owns it');
    Assert.IsTrue((Item.ParentNode as TObject) = (OldRoot as TObject), 'the subtree stays');
    Doc.DocumentElement.AppendChild(OldRoot);
    Assert.AreEqual('<n><r><a/></r></n>', Doc.DocumentElement.Xml, 'inserted again');
  end;

  procedure ReplaceAgain;
  begin
    Doc.DocumentElement := Doc.CreateElement('m');
    Assert.AreEqual('<m/>', Doc.DocumentElement.Xml);
  end;

begin
  var Used := LibraryMemoryInUse;
  ReplaceTheRoot;
  UseTheOldRoot;
  OldRoot := nil;
  Item := nil;
  ReplaceAgain;
  Doc := nil;
  Assert.IsTrue(Released = nil, 'the document goes with the last reference');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// An element of the root's own subtree may become the document element, as in MSXML: it
// leaves the old root, which keeps the rest. The new root keeps the namespaces it used from
// the old one, also once the old root is gone.
procedure TXMLDOMTest.TestDocumentElementFromItsOwnSubtree;
var
  [Weak] Released: IXMLDocument;
  Doc: IXMLDocument;
  OldRoot: IXMLNode;

  procedure PromoteTheChild;
  begin
    Doc := CoCreateXMLDocument;
    Released := Doc;
    Assert.IsTrue(Doc.LoadXML('<r xmlns:p="urn:p"><p:a p:at="1"><b/></p:a><c/></r>'));
    OldRoot := Doc.DocumentElement;
    Doc.DocumentElement := OldRoot.FirstChild as IXMLElement;
  end;

  procedure UseBoth;
  begin
    Assert.AreEqual('<p:a xmlns:p="urn:p" p:at="1"><b/></p:a>', Doc.DocumentElement.Xml);
    Assert.AreEqual('<r xmlns:p="urn:p"><c/></r>', OldRoot.Xml);
    Assert.IsNull(OldRoot.ParentNode, 'the old root is detached');
  end;

  procedure UseTheNewRoot;
  begin
    var Root := Doc.DocumentElement;
    Assert.AreEqual('urn:p', Root.NamespaceURI);
    Assert.AreEqual('urn:p', Root.GetAttributeNode('p:at').NamespaceURI);
    Assert.AreEqual('<p:a xmlns:p="urn:p" p:at="1"><b/></p:a>', Root.Xml);
  end;

begin
  var Used := LibraryMemoryInUse;
  PromoteTheChild;
  UseBoth;
  OldRoot := nil;   // the old root goes, and the namespace declaration on it
  UseTheNewRoot;
  Doc := nil;
  Assert.IsTrue(Released = nil, 'the document goes with the last reference');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// ReplaceChild returns the replaced child usable, as in MSXML: detached, with its subtree,
// owned by the document, and it can be inserted again. A sibling of the replaced child may
// take its place.
procedure TXMLDOMTest.TestReplaceChildReturnsTheOldChild;
var
  [Weak] Released: IXMLDocument;
  Doc: IXMLDocument;
  Old, Inner, Returned: IXMLNode;

  procedure Replace;
  begin
    Doc := CoCreateXMLDocument;
    Released := Doc;
    Assert.IsTrue(Doc.LoadXML('<r><a><b/></a><c/></r>'));
    Old := Doc.DocumentElement.FirstChild;
    Inner := Old.FirstChild;
    Returned := Doc.DocumentElement.ReplaceChild(Doc.CreateElement('n'), Old);
  end;

  procedure UseTheOldChild;
  begin
    Assert.AreEqual('<r><n/><c/></r>', Doc.DocumentElement.Xml);
    Assert.IsTrue((Returned as TObject) = (Old as TObject), 'the old child is returned');
    Assert.AreEqual('<a><b/></a>', Old.Xml);
    Assert.IsNull(Old.ParentNode, 'the old child is detached');
    Assert.IsNull(Old.NextSibling);
    Assert.IsTrue(Old.OwnerDocument = Doc, 'the document still owns it');
    Assert.IsTrue((Inner.ParentNode as TObject) = (Old as TObject), 'the subtree stays');
    Doc.DocumentElement.InsertBefore(Old, Doc.DocumentElement.LastChild);
    Assert.AreEqual('<r><n/><a><b/></a><c/></r>', Doc.DocumentElement.Xml, 'inserted again');
  end;

  procedure ReplaceWithASibling;
  begin
    var Root := Doc.DocumentElement;
    Assert.AreEqual('n', Root.ReplaceChild(Root.LastChild, Root.FirstChild).NodeName);
    Assert.AreEqual('<r><c/><a><b/></a></r>', Root.Xml);
  end;

begin
  var Used := LibraryMemoryInUse;
  Replace;
  UseTheOldChild;
  ReplaceWithASibling;
  Returned := nil;
  Old := nil;
  Inner := nil;
  Doc := nil;
  Assert.IsTrue(Released = nil, 'the document goes with the last reference');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// Replacing a child with itself changes nothing, as in MSXML, and returns the child.
procedure TXMLDOMTest.TestReplaceChildWithItself;
var
  [Weak] Released: IXMLDocument;
  Doc: IXMLDocument;
  Child: IXMLNode;

  procedure ReplaceWithItself;
  begin
    Doc := CoCreateXMLDocument;
    Released := Doc;
    Assert.IsTrue(Doc.LoadXML('<r><a/><c/></r>'));
    Child := Doc.DocumentElement.FirstChild;
    Assert.IsTrue((Doc.DocumentElement.ReplaceChild(Child, Child) as TObject) = (Child as TObject),
      'the child is returned');
  end;

  procedure UseTheChild;
  begin
    Assert.AreEqual('<r><a/><c/></r>', Doc.DocumentElement.Xml);
    Assert.IsTrue((Child.ParentNode as TObject) = (Doc.DocumentElement as TObject), 'the child stays in place');
  end;

begin
  var Used := LibraryMemoryInUse;
  ReplaceWithItself;
  UseTheChild;
  Child := nil;
  Doc := nil;
  Assert.IsTrue(Released = nil, 'the document goes with the last reference');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// A descendant of a removed node stays usable once nothing refers to the removed node, as
// in MSXML: its parent chain leads to the removed node, which has no parent, the document
// owns them, and the text of an attribute in the subtree stays as well. The subtree goes
// with the last reference into it.
procedure TXMLDOMTest.TestDescendantsOfRemovedNodeStayUsable;
var
  [Weak] Released: IXMLDocument;
  Doc: IXMLDocument;
  Inner, Text: IXMLNode;

  procedure RemoveAndLetGo;
  begin
    Doc := CoCreateXMLDocument;
    Released := Doc;
    Assert.IsTrue(Doc.LoadXML('<r xmlns:p="urn:p"><p:a x="1"><b><c/></b>t</p:a><z/></r>'));
    var Removed := Doc.DocumentElement.FirstChild;
    Inner := Removed.FirstChild;
    Text := (Removed as IXMLElement).GetAttributeNode('x').FirstChild;
    Doc.DocumentElement.RemoveChild(Removed);
  end;

  procedure UseTheDescendants;
  begin
    Assert.AreEqual('<b><c/></b>', Inner.Xml);
    var Top := Inner.ParentNode;
    Assert.AreEqual('p:a', Top.NodeName, 'the removed node is the parent still');
    Assert.IsNull(Top.ParentNode, 'the removed node is detached');
    Assert.AreEqual('<p:a xmlns:p="urn:p" x="1"><b><c/></b>t</p:a>', Top.Xml, 'as MSXML writes it');
    Assert.IsTrue(Inner.OwnerDocument = Doc, 'the document owns the subtree');
    Assert.AreEqual('1', Text.NodeValue, 'the text of an attribute in the subtree');
    Assert.AreEqual('z', Doc.DocumentElement.FirstChild.NodeName);
  end;

  procedure UseWithoutTheDocument;
  begin
    Assert.AreEqual('c', Inner.FirstChild.NodeName);
  end;

begin
  var Used := LibraryMemoryInUse;
  var Wrappers := DebugObjectCount;
  RemoveAndLetGo;
  UseTheDescendants;
  Text := nil;
  Doc := nil;
  Assert.IsTrue(Released <> nil, 'the descendant keeps the document alive');
  UseWithoutTheDocument;
  Inner := nil;
  Assert.IsTrue(Released = nil, 'the document goes with the last reference');
  Assert.AreEqual<NativeInt>(Wrappers, DebugObjectCount, 'wrappers');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// A descendant of the child ReplaceChild has replaced stays usable in the same way once
// nothing refers to the replaced child, and can be put back into the document.
procedure TXMLDOMTest.TestDescendantsOfReplacedChildStayUsable;
var
  [Weak] Released: IXMLDocument;
  Doc: IXMLDocument;
  Inner: IXMLNode;

  procedure ReplaceAndLetGo;
  begin
    Doc := CoCreateXMLDocument;
    Released := Doc;
    Assert.IsTrue(Doc.LoadXML('<r><a><b><c/></b><x/></a><z/></r>'));
    Inner := Doc.DocumentElement.FirstChild.FirstChild;
    Doc.DocumentElement.ReplaceChild(Doc.CreateElement('n'), Doc.DocumentElement.FirstChild);
  end;

  procedure UseTheDescendant;
  begin
    Assert.AreEqual('<r><n/><z/></r>', Doc.DocumentElement.Xml);
    Assert.AreEqual('<b><c/></b>', Inner.Xml);
    Assert.AreEqual('<a><b><c/></b><x/></a>', Inner.ParentNode.Xml, 'the replaced child is the parent still');
    Assert.IsNull(Inner.ParentNode.ParentNode, 'the replaced child is detached');
    Doc.DocumentElement.AppendChild(Inner);
    Assert.AreEqual('<r><n/><z/><b><c/></b></r>', Doc.DocumentElement.Xml, 'put back');
    Assert.AreEqual('c', Inner.FirstChild.NodeName);
  end;

begin
  var Used := LibraryMemoryInUse;
  ReplaceAndLetGo;
  UseTheDescendant;
  Inner := nil;
  Doc := nil;
  Assert.IsTrue(Released = nil, 'the document goes with the last reference');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// A descendant of the document element stays usable after another element has taken its
// place and nothing refers to the replaced root, as in MSXML: its parent chain leads to the
// replaced root, which has no parent.
procedure TXMLDOMTest.TestDescendantsOfReplacedRootStayUsable;
var
  [Weak] Released: IXMLDocument;
  Doc: IXMLDocument;
  Inner: IXMLNode;

  procedure Load;
  begin
    Doc := CoCreateXMLDocument;
    Released := Doc;
    Assert.IsTrue(Doc.LoadXML('<!--c--><r><a><b/></a></r>'));
    Inner := Doc.DocumentElement.FirstChild.FirstChild;
  end;

  // Nothing refers to the root while it is replaced
  procedure ReplaceTheRoot;
  begin
    Doc.DocumentElement := Doc.CreateElement('n');
  end;

  procedure UseTheDescendant;
  begin
    Assert.AreEqual('<n/>', Doc.DocumentElement.Xml);
    Assert.AreEqual('a', Inner.ParentNode.NodeName);
    Assert.AreEqual('<r><a><b/></a></r>', Inner.ParentNode.ParentNode.Xml, 'the replaced root');
    Assert.IsNull(Inner.ParentNode.ParentNode.ParentNode, 'the replaced root is detached');
    Assert.IsTrue(Inner.OwnerDocument = Doc, 'the document owns it');
  end;

begin
  var Used := LibraryMemoryInUse;
  Load;
  ReplaceTheRoot;
  UseTheDescendant;
  Inner := nil;
  Doc := nil;
  Assert.IsTrue(Released = nil, 'the document goes with the last reference');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// A kept detached subtree goes with the last reference into it, while its document lives
// on. A node of the subtree reached later keeps it too. The checks of memory need a debug
// build, where libxml2 counts what it holds.
procedure TXMLDOMTest.TestDetachedSubtreeGoesWithTheLastReference;
var
  Doc: IXMLDocument;
  First, Second: IXMLNode;
  Kept: NativeUInt;

  procedure RemoveAndLetGo;
  begin
    Assert.IsTrue(Doc.LoadXML('<r><a><b/><c><d/></c><e>text</e></a><z/></r>'));
    var Removed := Doc.DocumentElement.FirstChild;
    First := Removed.FirstChild;
    Second := Removed.FirstChild.NextSibling.FirstChild;
    Doc.DocumentElement.RemoveChild(Removed);
  end;

  procedure WalkFromTheSecond;
  begin
    var Parent := Second.ParentNode;
    Second := nil;
    Assert.AreEqual<NativeUInt>(Kept, LibraryMemoryInUse, 'kept for the node reached from the second');
    Assert.AreEqual('<a><b/><c><d/></c><e>text</e></a>', Parent.ParentNode.Xml);
  end;

begin
  var Used := LibraryMemoryInUse;
  Doc := CoCreateXMLDocument;
  RemoveAndLetGo;
  Kept := LibraryMemoryInUse;
  First := nil;
  Assert.AreEqual<NativeUInt>(Kept, LibraryMemoryInUse, 'kept for the second reference');
  WalkFromTheSecond;
  if Kept > 0 then
    Assert.IsTrue(LibraryMemoryInUse < Kept, 'the subtree goes with the last reference');
  Doc := nil;
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// Once the only node referred to has moved out of a kept detached subtree, the rest of the
// subtree goes at once; the moved node keeps its own subtree.
procedure TXMLDOMTest.TestRestOfDetachedSubtreeGoesWhenTheNodeMoves;
var
  Doc: IXMLDocument;
  Inner: IXMLNode;

  procedure RemoveAndLetGo;
  begin
    var Xml := '<r><a><b><c/></b>';
    for var I := 1 to 20 do
      Xml := Xml + '<x>' + I.ToString + '</x>';
    Assert.IsTrue(Doc.LoadXML(Xml + '</a></r>'));
    Inner := Doc.DocumentElement.FirstChild.FirstChild;
    Doc.DocumentElement.RemoveChild(Doc.DocumentElement.FirstChild);
  end;

  procedure PutBack;
  begin
    Doc.DocumentElement.AppendChild(Inner);
  end;

  procedure UseThePutBackNode;
  begin
    Assert.AreEqual('<r><b><c/></b></r>', Doc.DocumentElement.Xml);
    Assert.AreEqual('c', Inner.FirstChild.NodeName);
  end;

begin
  var Used := LibraryMemoryInUse;
  Doc := CoCreateXMLDocument;
  RemoveAndLetGo;
  var Kept := LibraryMemoryInUse;
  PutBack;
  if Kept > 0 then
    Assert.IsTrue(LibraryMemoryInUse < Kept, 'the rest of the subtree goes with the move');
  UseThePutBackNode;
  Inner := nil;
  Doc := nil;
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// A kept detached subtree moved into another document leaves its document, which goes once
// nothing else refers to it; the other document owns the nodes of the subtree.
procedure TXMLDOMTest.TestKeptSubtreeMovesToAnotherDocument;
var
  [Weak] Source: IXMLDocument;
  [Weak] Target: IXMLDocument;
  ToDoc: IXMLDocument;
  Inner: IXMLNode;

  procedure RemoveAndLetGo;
  begin
    var FromDoc := CoCreateXMLDocument;
    Source := FromDoc;
    Assert.IsTrue(FromDoc.LoadXML('<r><a><b><c/></b><x/></a></r>'));
    Inner := FromDoc.DocumentElement.FirstChild.FirstChild;
    FromDoc.DocumentElement.RemoveChild(FromDoc.DocumentElement.FirstChild);
  end;

  procedure MoveTheSubtree;
  begin
    ToDoc := CoCreateXMLDocument;
    Target := ToDoc;
    Assert.IsTrue(ToDoc.LoadXML('<s/>'));
    ToDoc.DocumentElement.AppendChild(Inner.ParentNode);
    Assert.AreEqual('<s><a><b><c/></b><x/></a></s>', ToDoc.DocumentElement.Xml);
  end;

  procedure UseTheMovedNode;
  begin
    Assert.IsTrue(Inner.OwnerDocument = ToDoc, 'the other document owns it');
    Assert.AreEqual('s', Inner.ParentNode.ParentNode.NodeName);
  end;

begin
  var Used := LibraryMemoryInUse;
  RemoveAndLetGo;
  Assert.IsTrue(Source <> nil, 'the kept subtree keeps its document alive');
  MoveTheSubtree;
  Assert.IsTrue(Source = nil, 'the document goes once the subtree has left it');
  UseTheMovedNode;
  ToDoc := nil;
  Assert.IsTrue(Target <> nil, 'the moved node keeps the other document alive');
  Inner := nil;
  Assert.IsTrue(Target = nil, 'the other document goes with the last reference');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// A node moved out of a kept detached subtree into another document takes nothing of the
// rest along: the rest goes, and its document with it.
procedure TXMLDOMTest.TestNodeOfKeptSubtreeMovesToAnotherDocument;
var
  [Weak] Source: IXMLDocument;
  [Weak] Target: IXMLDocument;
  ToDoc: IXMLDocument;
  Inner: IXMLNode;

  procedure RemoveAndLetGo;
  begin
    var FromDoc := CoCreateXMLDocument;
    Source := FromDoc;
    Assert.IsTrue(FromDoc.LoadXML('<r><a><b><c/></b><x/></a></r>'));
    Inner := FromDoc.DocumentElement.FirstChild.FirstChild;
    FromDoc.DocumentElement.RemoveChild(FromDoc.DocumentElement.FirstChild);
  end;

  procedure MoveTheNode;
  begin
    ToDoc := CoCreateXMLDocument;
    Target := ToDoc;
    Assert.IsTrue(ToDoc.LoadXML('<s/>'));
    ToDoc.DocumentElement.AppendChild(Inner);
    Assert.AreEqual('<s><b><c/></b></s>', ToDoc.DocumentElement.Xml);
  end;

begin
  var Used := LibraryMemoryInUse;
  RemoveAndLetGo;
  MoveTheNode;
  Assert.IsTrue(Source = nil, 'the rest of the subtree goes, and its document with it');
  ToDoc := nil;
  Assert.IsTrue(Target <> nil, 'the moved node keeps the other document alive');
  Inner := nil;
  Assert.IsTrue(Target = nil, 'the other document goes with the last reference');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// A kept detached subtree survives a reload of its document, as the detached nodes of the
// replaced content do (see TestRemovedRootSurvivesReload).
procedure TXMLDOMTest.TestKeptSubtreeSurvivesReload;
var
  [Weak] Released: IXMLDocument;
  Doc: IXMLDocument;
  Inner: IXMLNode;

  procedure RemoveAndLetGo;
  begin
    Doc := CoCreateXMLDocument;
    Released := Doc;
    Assert.IsTrue(Doc.LoadXML('<r><a><b><c/></b><x/></a></r>'));
    Inner := Doc.DocumentElement.FirstChild.FirstChild;
    Doc.DocumentElement.RemoveChild(Doc.DocumentElement.FirstChild);
  end;

  procedure Reload;
  begin
    Assert.IsTrue(Doc.LoadXML('<new/>'));
  end;

  procedure UseTheDescendant;
  begin
    Assert.AreEqual('<a><b><c/></b><x/></a>', Inner.ParentNode.Xml);
    Assert.IsNull(Inner.ParentNode.ParentNode, 'the removed node is detached');
    Assert.IsTrue(Inner.OwnerDocument = Doc, 'the reloaded document owns it, as in MSXML');
    Assert.AreEqual('<new/>', Doc.DocumentElement.Xml);
  end;

begin
  var Used := LibraryMemoryInUse;
  RemoveAndLetGo;
  Reload;
  UseTheDescendant;
  Doc := nil;
  Assert.IsTrue(Released <> nil, 'the descendant keeps the document alive');
  Inner := nil;
  Assert.IsTrue(Released = nil, 'the document goes with the last reference');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// The list SelectNodes returns holds the node the nodes were selected from: the nodes
// selected from a removed node stay usable once nothing else refers to the removed node.
procedure TXMLDOMTest.TestSelectedNodesOfRemovedNodeStayUsable;
var
  [Weak] Released: IXMLDocument;
  Doc: IXMLDocument;
  List: IXMLNodeList;

  procedure SelectAndLetGo;
  begin
    Doc := CoCreateXMLDocument;
    Released := Doc;
    Assert.IsTrue(Doc.LoadXML('<r><a><i n="1"/><i n="2"/></a></r>'));
    List := Doc.DocumentElement.RemoveChild(Doc.DocumentElement.FirstChild).SelectNodes('i');
  end;

  procedure UseTheList;
  begin
    Assert.AreEqual<NativeInt>(2, List.Length);
    Assert.AreEqual('2', (List[1] as IXMLElement).GetAttribute('n'));
    Assert.AreEqual('a', List[0].ParentNode.NodeName);
  end;

begin
  var Used := LibraryMemoryInUse;
  SelectAndLetGo;
  UseTheList;
  Doc := nil;
  Assert.IsTrue(Released <> nil, 'the list keeps the document alive');
  List := nil;
  Assert.IsTrue(Released = nil, 'the document goes with the last reference');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// Walking a kept detached subtree with one reference at a time costs a step per node: the
// node reached keeps the subtree before the previous one lets it go, so the subtree is not
// searched for references on the way.
procedure TXMLDOMTest.TestWalkInKeptSubtreeIsLinear;
const
  Count = 50000;
var
  Doc: IXMLDocument;
  Node: IXMLNode;

  procedure BuildAndRemove;
  begin
    Assert.IsTrue(Doc.LoadXML('<r><a/></r>'));
    var Removed := Doc.DocumentElement.FirstChild as IXMLElement;
    for var I := 1 to Count do
      Removed.AddChild('i');
    Node := Removed.FirstChild;
    Doc.DocumentElement.RemoveChild(Removed);
  end;

begin
  Doc := CoCreateXMLDocument;
  BuildAndRemove;
  var Steps := 0;
  var Watch := TStopwatch.StartNew;
  while Node <> nil do
  begin
    Node := Node.NextSibling;
    Inc(Steps);
  end;
  Watch.Stop;
  Assert.AreEqual(Count, Steps);
  Assert.IsTrue(Watch.ElapsedMilliseconds < 2000, Format('%d ms', [Watch.ElapsedMilliseconds]));
end;

// The replaced child keeps the namespaces it used from its parent, as in MSXML: they are
// declared on it, and stay with it when the former parent is gone.
procedure TXMLDOMTest.TestReplacedChildKeepsItsNamespaces;
var
  [Weak] Released: IXMLDocument;
  Doc: IXMLDocument;
  Old: IXMLNode;

  procedure Replace;
  begin
    Doc := CoCreateXMLDocument;
    Released := Doc;
    Assert.IsTrue(Doc.LoadXML('<r xmlns:p="urn:p"><p:a><p:b p:at="1"/></p:a></r>'));
    Old := Doc.DocumentElement.ReplaceChild(Doc.CreateElement('n'), Doc.DocumentElement.FirstChild);
    Assert.AreEqual('<p:a xmlns:p="urn:p"><p:b p:at="1"/></p:a>', Old.Xml, 'as MSXML writes it');
  end;

  // Nothing refers to the former parent, and it goes
  procedure ReplaceTheParent;
  begin
    Doc.DocumentElement := Doc.CreateElement('s');
  end;

  procedure UseTheOldChild;
  begin
    Assert.AreEqual('urn:p', Old.NamespaceURI);
    var Inner := Old.FirstChild as IXMLElement;
    Assert.AreEqual('urn:p', Inner.NamespaceURI);
    Assert.AreEqual('urn:p', Inner.GetAttributeNode('p:at').NamespaceURI);
    Doc.DocumentElement.AppendChild(Old);
    Assert.AreEqual('<s><p:a xmlns:p="urn:p"><p:b p:at="1"/></p:a></s>', Doc.DocumentElement.Xml);
  end;

begin
  var Used := LibraryMemoryInUse;
  Replace;
  ReplaceTheParent;
  UseTheOldChild;
  Old := nil;
  Doc := nil;
  Assert.IsTrue(Released = nil, 'the document goes with the last reference');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// A removed child keeps the namespaces it used from its parent in the same way.
procedure TXMLDOMTest.TestRemovedChildKeepsItsNamespaces;
var
  [Weak] Released: IXMLDocument;
  Doc: IXMLDocument;
  Old: IXMLNode;

  procedure Remove;
  begin
    Doc := CoCreateXMLDocument;
    Released := Doc;
    Assert.IsTrue(Doc.LoadXML('<r xmlns:p="urn:p"><p:a><p:b p:at="1"/></p:a></r>'));
    Old := Doc.DocumentElement.RemoveChild(Doc.DocumentElement.FirstChild);
    Assert.AreEqual('<p:a xmlns:p="urn:p"><p:b p:at="1"/></p:a>', Old.Xml, 'as MSXML writes it');
  end;

  // Nothing refers to the former parent, and it goes
  procedure ReplaceTheParent;
  begin
    Doc.DocumentElement := Doc.CreateElement('s');
  end;

  procedure UseTheOldChild;
  begin
    Assert.AreEqual('urn:p', Old.NamespaceURI);
    var Inner := Old.FirstChild as IXMLElement;
    Assert.AreEqual('urn:p', Inner.NamespaceURI);
    Assert.AreEqual('urn:p', Inner.GetAttributeNode('p:at').NamespaceURI);
  end;

begin
  var Used := LibraryMemoryInUse;
  Remove;
  ReplaceTheParent;
  UseTheOldChild;
  Old := nil;
  Doc := nil;
  Assert.IsTrue(Released = nil, 'the document goes with the last reference');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// CreateRoot makes the root as MSXML's createNode does and sets it as the document element:
// the namespace is declared on the root, under the prefix of a qualified name or as the
// default namespace of a local name. A prefix without a namespace URI stays in the name, as
// in CreateElement. The declaration goes with the document.
procedure TXMLDOMTest.TestCreateRootDeclaresItsNamespace;
var
  [Weak] Released: IXMLDocument;

  function RootXml(const Name, NamespaceURI: string; const Content: string = ''): string;
  begin
    var Doc := CoCreateXMLDocument;
    Released := Doc;
    var Root := Doc.CreateRoot(Name, NamespaceURI, Content);
    Assert.IsTrue((Doc.DocumentElement as TObject) = (Root as TObject), 'the root is the document element');
    Assert.AreEqual(Name, Root.NodeName);
    Assert.AreEqual(NamespaceURI, Root.NamespaceURI, Name);
    Result := Root.Xml;
  end;

begin
  var Used := LibraryMemoryInUse;
  Assert.AreEqual('<p:r xmlns:p="urn:p"/>', RootXml('p:r', 'urn:p'));
  Assert.AreEqual('<r xmlns="urn:p"/>', RootXml('r', 'urn:p'));
  Assert.AreEqual('<p:r xmlns:p="urn:p">a&lt;b</p:r>', RootXml('p:r', 'urn:p', 'a<b'));
  Assert.AreEqual('<p:r/>', RootXml('p:r', ''));
  Assert.AreEqual('<r/>', RootXml('r', ''));
  Assert.IsTrue(Released = nil, 'the document goes with the last reference');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// CreateRoot on a document that has a root puts the new root in its place as setting
// DocumentElement does, as in MSXML: the replaced root stays usable for as long as it is
// referenced.
procedure TXMLDOMTest.TestCreateRootKeepsTheReplacedRoot;
var
  [Weak] Released: IXMLDocument;
  Doc: IXMLDocument;
  OldRoot: IXMLNode;

  procedure CreateAnotherRoot;
  begin
    Doc := CoCreateXMLDocument;
    Released := Doc;
    Assert.IsTrue(Doc.LoadXML('<old><a/></old>'));
    OldRoot := Doc.DocumentElement;
    Doc.CreateRoot('p:r', 'urn:p');
  end;

  procedure UseBoth;
  begin
    Assert.AreEqual('<p:r xmlns:p="urn:p"/>', Doc.DocumentElement.Xml);
    Assert.AreEqual('<old><a/></old>', OldRoot.Xml);
    Assert.IsNull(OldRoot.ParentNode, 'the replaced root is detached');
  end;

begin
  var Used := LibraryMemoryInUse;
  CreateAnotherRoot;
  UseBoth;
  OldRoot := nil;
  Doc := nil;
  Assert.IsTrue(Released = nil, 'the document goes with the last reference');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// CreateChild makes the child as MSXML's createNode followed by appendChild does: a
// declaration of the parent that binds the prefix of the name to the namespace URI serves
// the child, any other namespace is declared on the child. Without a namespace URI a prefix
// means what it means at the parent, and stays in the name when nothing declares it.
procedure TXMLDOMTest.TestCreateChildDeclaresItsNamespace;
const
  NamespaceURIs: array[0..6] of string = ('urn:p', 'urn:q', 'urn:p', 'urn:other', '', 'urn:p', '');
var
  [Weak] Released: IXMLDocument;
  Doc: IXMLDocument;

  procedure CreateChildren;
  begin
    Doc := CoCreateXMLDocument;
    Released := Doc;
    var Root := Doc.CreateRoot('p:r', 'urn:p');
    Doc.CreateChild(Root, 'p:a', 'urn:p');
    Doc.CreateChild(Root, 'q:b', 'urn:q');
    Doc.CreateChild(Root, 'c', 'urn:p');
    Doc.CreateChild(Root, 'p:d', 'urn:other');
    Doc.CreateChild(Root, 'e');
    Doc.CreateChild(Root, 'p:f');
    Doc.CreateChild(Root, 'q:g');
  end;

  procedure UseTheChildren;
  begin
    var Root := Doc.DocumentElement;
    Assert.AreEqual('<p:r xmlns:p="urn:p"><p:a/><q:b xmlns:q="urn:q"/><c xmlns="urn:p"/>' +
      '<p:d xmlns:p="urn:other"/><e/><p:f/><q:g/></p:r>', Root.Xml, 'as MSXML writes it');
    var Child := Root.FirstChild;
    for var URI in NamespaceURIs do
    begin
      Assert.AreEqual(URI, Child.NamespaceURI, Child.NodeName);
      Child := Child.NextSibling;
    end;
  end;

begin
  var Used := LibraryMemoryInUse;
  CreateChildren;
  UseTheChildren;
  Doc := nil;
  Assert.IsTrue(Released = nil, 'the document goes with the last reference');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// Under a default namespace the same rule holds: the default namespace of the parent serves
// a local name in it, another namespace URI is declared on the child.
procedure TXMLDOMTest.TestCreateChildUnderDefaultNamespace;
var
  [Weak] Released: IXMLDocument;
  Doc: IXMLDocument;

  procedure CreateChildren;
  begin
    Doc := CoCreateXMLDocument;
    Released := Doc;
    var Root := Doc.CreateRoot('r', 'urn:p');
    Doc.CreateChild(Root, 'a', 'urn:p', False, 'x&y');
    Doc.CreateChild(Root, 'b', 'urn:q');
    Doc.CreateChild(Root, 'p:c', 'urn:p');
  end;

  procedure UseTheChildren;
  begin
    Assert.AreEqual('<r xmlns="urn:p"><a>x&amp;y</a><b xmlns="urn:q"/><p:c xmlns:p="urn:p"/></r>',
      Doc.DocumentElement.Xml, 'as MSXML writes it');
    Assert.AreEqual('urn:p', Doc.DocumentElement.FirstChild.NamespaceURI);
  end;

begin
  var Used := LibraryMemoryInUse;
  CreateChildren;
  UseTheChildren;
  Doc := nil;
  Assert.IsTrue(Released = nil, 'the document goes with the last reference');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// A child in a namespace the parent binds to another prefix keeps the name it was given, as
// in MSXML; with ResolveNamespace it takes the prefix bound to the namespace URI in scope
// instead, and only a namespace URI bound to none is declared on the child.
procedure TXMLDOMTest.TestCreateChildResolveNamespace;
var
  [Weak] Released: IXMLDocument;
  Doc: IXMLDocument;

  procedure CreateChildren;
  begin
    Doc := CoCreateXMLDocument;
    Released := Doc;
    Assert.IsTrue(Doc.LoadXML('<r xmlns:q="urn:p"/>'));
    var Root := Doc.DocumentElement;
    Doc.CreateChild(Root, 'a', 'urn:p');
    Doc.CreateChild(Root, 'p:b', 'urn:p');
    Doc.CreateChild(Root, 'c', 'urn:p', True);
    Doc.CreateChild(Root, 'p:d', 'urn:p', True);
    Doc.CreateChild(Root, 'e', 'urn:x', True);
    Doc.CreateChild(Root, 'p:f', 'urn:x', True);
  end;

  procedure UseTheChildren;
  begin
    Assert.AreEqual('<r xmlns:q="urn:p"><a xmlns="urn:p"/><p:b xmlns:p="urn:p"/><q:c/><q:d/>' +
      '<e xmlns="urn:x"/><p:f xmlns:p="urn:x"/></r>', Doc.DocumentElement.Xml);
  end;

begin
  var Used := LibraryMemoryInUse;
  CreateChildren;
  UseTheChildren;
  Doc := nil;
  Assert.IsTrue(Released = nil, 'the document goes with the last reference');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// Without a parent CreateChild creates the root, as CreateRoot does.
procedure TXMLDOMTest.TestCreateChildWithoutParentCreatesTheRoot;
var
  [Weak] Released: IXMLDocument;
  Doc: IXMLDocument;

  procedure CreateTheRoot;
  begin
    Doc := CoCreateXMLDocument;
    Released := Doc;
    var Root := Doc.CreateChild(nil, 'p:r', 'urn:p', False, 'text');
    Assert.IsTrue((Doc.DocumentElement as TObject) = (Root as TObject), 'the child is the document element');
    Assert.AreEqual('<p:r xmlns:p="urn:p">text</p:r>', Root.Xml);
  end;

begin
  var Used := LibraryMemoryInUse;
  CreateTheRoot;
  Doc := nil;
  Assert.IsTrue(Released = nil, 'the document goes with the last reference');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// CreateElementNs makes the element as MSXML's createNode does: the namespace is declared on
// the element, under the prefix of a qualified name or as the default namespace of a local
// name. Without a namespace URI it is CreateElement, and a prefix stays in the name.
procedure TXMLDOMTest.TestCreateElementNsDeclaresItsNamespace;
var
  [Weak] Released: IXMLDocument;

  function ElementXml(const NamespaceURI, Name: string): string;
  begin
    var Doc := CoCreateXMLDocument;
    Released := Doc;
    var Element := Doc.CreateElementNs(NamespaceURI, Name);
    Assert.AreEqual(Name, Element.NodeName);
    Assert.AreEqual(NamespaceURI, Element.NamespaceURI, Name);
    if NamespaceURI <> '' then
      Assert.AreEqual(Copy(Name, 1, Pos(':', Name) - 1), Element.Prefix, Name);
    Result := Element.Xml;
  end;

begin
  var Used := LibraryMemoryInUse;
  Assert.AreEqual('<p:a xmlns:p="urn:p"/>', ElementXml('urn:p', 'p:a'));
  Assert.AreEqual('<a xmlns="urn:p"/>', ElementXml('urn:p', 'a'));
  Assert.AreEqual('<p:a/>', ElementXml('', 'p:a'));
  Assert.AreEqual('<a/>', ElementXml('', 'a'));
  Assert.IsTrue(Released = nil, 'the document goes with the last reference');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// AddChildNs makes a child with a prefixed name as MSXML's createNode followed by appendChild
// does: a declaration in scope that binds the prefix to the namespace URI serves the child,
// otherwise the namespace is declared on the child under that prefix. A name without a prefix
// takes the prefix the namespace URI has in scope, the default namespace included (where MSXML
// would declare it on the child once more), and a namespace URI bound to none is declared on
// the child as its default namespace. Without a namespace URI the call is AddChild.
procedure TXMLDOMTest.TestAddChildNsKeepsThePrefixItIsGiven;
const
  NamespaceURIs: array[0..7] of string = ('urn:q', 'urn:q', 'urn:q', 'urn:o', 'urn:d', 'urn:s', 'urn:s', 'urn:q');
var
  [Weak] Released: IXMLDocument;
  Doc: IXMLDocument;

  procedure AddChildren;
  begin
    Doc := CoCreateXMLDocument;
    Released := Doc;
    Assert.IsTrue(Doc.LoadXML('<r xmlns="urn:d" xmlns:p="urn:q"/>'));
    var Root := Doc.DocumentElement;
    Root.AddChildNs('q:a', 'urn:q');
    Root.AddChildNs('p:b', 'urn:q');
    Root.AddChildNs('c', 'urn:q', 'x<y');
    Root.AddChildNs('p:d', 'urn:o');
    Root.AddChildNs('e', 'urn:d');
    Root.AddChildNs('f', 'urn:s');
    Root.AddChildNs('s:g', 'urn:s');
    Root.AddChildNs('p:h', '');
  end;

  procedure UseTheChildren;
  begin
    var Root := Doc.DocumentElement;
    Assert.AreEqual('<r xmlns="urn:d" xmlns:p="urn:q"><q:a xmlns:q="urn:q"/><p:b/><p:c>x&lt;y</p:c>' +
      '<p:d xmlns:p="urn:o"/><e/><f xmlns="urn:s"/><s:g xmlns:s="urn:s"/><p:h/></r>', Root.Xml);
    var Child := Root.FirstChild;
    for var URI in NamespaceURIs do
    begin
      Assert.AreEqual(URI, Child.NamespaceURI, Child.NodeName);
      Child := Child.NextSibling;
    end;
  end;

begin
  var Used := LibraryMemoryInUse;
  AddChildren;
  UseTheChildren;
  Doc := nil;
  Assert.IsTrue(Released = nil, 'the document goes with the last reference');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
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

// RemoveChild takes the child out and changes nothing else, as in MSXML: no declaration
// lands on the parent, and what stays keeps its prefixes even where two prefixes are bound
// to one namespace. The removed child declares what it uses.
procedure TXMLDOMTest.TestRemoveChildLeavesTheParentAlone;
var
  [Weak] Released: IXMLDocument;

  function RemoveLast(const Xml: string; out Removed: string): string;
  begin
    var Doc := CoCreateXMLDocument;
    Released := Doc;
    Assert.IsTrue(Doc.LoadXML(Xml));
    var Root := Doc.DocumentElement;
    Removed := Root.RemoveChild(Root.LastChild).Xml;
    Result := Root.Xml;
  end;

begin
  var Used := LibraryMemoryInUse;
  var Removed: string;
  Assert.AreEqual('<r><a xmlns:q="urn:q"><q:x/></a></r>',
    RemoveLast('<r><a xmlns:q="urn:q"><q:x/></a><b/></r>', Removed));
  Assert.AreEqual('<r xmlns:a="urn:u" xmlns:b="urn:u"><b:x b:y="1"/></r>',
    RemoveLast('<r xmlns:a="urn:u" xmlns:b="urn:u"><b:x b:y="1"/><c/></r>', Removed));
  Assert.AreEqual('<r xmlns:p="urn:p"><p:a/></r>',
    RemoveLast('<r xmlns:p="urn:p"><p:a/><p:b><c xmlns:q="urn:q"><q:d/></c></p:b></r>', Removed));
  Assert.AreEqual('<p:b xmlns:p="urn:p"><c xmlns:q="urn:q"><q:d/></c></p:b>', Removed, 'as MSXML writes it');
  Assert.IsTrue(Released = nil, 'the document goes with the last reference');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// ReplaceChild makes the new child hold at its place and changes nothing else, as in MSXML.
// A namespace the new child brings from elsewhere in the document is declared on it, under
// its own prefix even where the parent binds the URI to another one, unless the same prefix
// is bound to the same URI in scope. The parent gets no declaration, and a reference that
// holds keeps its prefix.
procedure TXMLDOMTest.TestReplaceChildDeclaresWhatTheNewChildUses;
var
  [Weak] Released: IXMLDocument;

  // Puts the element named NewName (a new element n when empty) in place of the element
  // named OldName
  function Replace(const Xml, NewName, OldName: string): string;
  begin
    var Doc := CoCreateXMLDocument;
    Released := Doc;
    Assert.IsTrue(Doc.LoadXML(Xml));
    var NewNode: IXMLNode;
    if NewName = '' then
      NewNode := Doc.CreateElement('n')
    else
      NewNode := Doc.SelectSingleNode('//*[local-name()="' + NewName + '"]');
    var OldNode := Doc.SelectSingleNode('//*[local-name()="' + OldName + '"]');
    OldNode.ParentNode.ReplaceChild(NewNode, OldNode);
    Result := Doc.DocumentElement.Xml;
  end;

begin
  var Used := LibraryMemoryInUse;
  Assert.AreEqual('<r><a xmlns:q="urn:q"><q:x/></a><n/></r>',
    Replace('<r><a xmlns:q="urn:q"><q:x/></a><b/></r>', '', 'b'));
  Assert.AreEqual('<r><s xmlns:p="urn:p"/><p:m xmlns:p="urn:p" p:at="1"/></r>',
    Replace('<r><s xmlns:p="urn:p"><p:m p:at="1"/></s><t/></r>', 'm', 't'));
  Assert.AreEqual('<r xmlns:z="urn:p"><s xmlns:p="urn:p"/><p:m xmlns:p="urn:p" p:at="1"/></r>',
    Replace('<r xmlns:z="urn:p"><s xmlns:p="urn:p"><p:m p:at="1"/></s><t/></r>', 'm', 't'));
  Assert.AreEqual('<r xmlns:p="urn:p"><s xmlns:p="urn:p"/><p:m/></r>',
    Replace('<r xmlns:p="urn:p"><s xmlns:p="urn:p"><p:m/></s><t/></r>', 'm', 't'));
  Assert.AreEqual('<r><s xmlns:p="urn:p"/><t xmlns:p="urn:other"><p:m xmlns:p="urn:p"/></t></r>',
    Replace('<r><s xmlns:p="urn:p"><p:m/></s><t xmlns:p="urn:other"><u/></t></r>', 'm', 'u'));
  Assert.AreEqual('<r xmlns:a="urn:u"><s xmlns:b="urn:u"><b:x/></s></r>',
    Replace('<r xmlns:a="urn:u"><s xmlns:b="urn:u"><b:x/><t/></s></r>', 'x', 't'));
  Assert.AreEqual('<r xmlns:p="urn:p"><p:a/><p:b/></r>',
    Replace('<r xmlns:p="urn:p"><p:a><p:b/></p:a><p:c/></r>', 'b', 'c'));
  Assert.IsTrue(Released = nil, 'the document goes with the last reference');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// AppendChild and InsertBefore leave a moved subtree its own declarations, as MSXML does:
// a namespace declared within the subtree is not declared once more on its top, and a
// reference that holds at the new place keeps its prefix.
procedure TXMLDOMTest.TestMovedSubtreeKeepsItsNestedDeclarations;
var
  [Weak] Released: IXMLDocument;

  // Moves the element named Name under the element named ParentName, before its first
  // child when Before is set
  function Move(const Xml, Name, ParentName: string; Before: Boolean = False): string;
  begin
    var Doc := CoCreateXMLDocument;
    Released := Doc;
    Assert.IsTrue(Doc.LoadXML(Xml));
    var Node := Doc.SelectSingleNode('//*[local-name()="' + Name + '"]');
    var Parent := Doc.SelectSingleNode('//*[local-name()="' + ParentName + '"]');
    if Before then
      Parent.InsertBefore(Node, Parent.FirstChild)
    else
      Parent.AppendChild(Node);
    Result := Doc.DocumentElement.Xml;
  end;

  function AppendCreated: string;
  begin
    var Doc := CoCreateXMLDocument;
    Released := Doc;
    Assert.IsTrue(Doc.LoadXML('<r/>'));
    var W := Doc.CreateElement('w');
    W.AppendChild(Doc.CreateNode(NODE_ELEMENT, 'p:e', 'urn:p'));
    Doc.DocumentElement.AppendChild(W);
    Result := Doc.DocumentElement.Xml;
  end;

begin
  var Used := LibraryMemoryInUse;
  Assert.AreEqual('<r><z><w><a xmlns:q="urn:q"><q:x/></a></w></z></r>',
    Move('<r><w><a xmlns:q="urn:q"><q:x/></a></w><z/></r>', 'w', 'z'));
  Assert.AreEqual('<r><z><w><a xmlns:q="urn:q"><q:x/></a></w><y/></z></r>',
    Move('<r><w><a xmlns:q="urn:q"><q:x/></a></w><z><y/></z></r>', 'w', 'z', True));
  Assert.AreEqual('<r xmlns:a="urn:u"><s xmlns:b="urn:u"><t/><b:x/></s></r>',
    Move('<r xmlns:a="urn:u"><s xmlns:b="urn:u"><b:x/><t/></s></r>', 'x', 's'));
  Assert.AreEqual('<r><w><p:e xmlns:p="urn:p"/></w></r>', AppendCreated);
  Assert.IsTrue(Released = nil, 'the document goes with the last reference');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// RemoveChild, ReplaceChild and InsertBefore refuse a node that is not a child with
// EXmlError, as MSXML does, and the tree stays as it was: libxml2 would act on the node
// wherever it is.
procedure TXMLDOMTest.TestNodeThatIsNotAChildIsRefused;
var
  [Weak] Released: IXMLDocument;
  Doc: IXMLDocument;

  procedure Refuse;
  begin
    Doc := CoCreateXMLDocument;
    Released := Doc;
    Assert.IsTrue(Doc.LoadXML('<r><a><b/></a><c/></r>'));
    var Root := Doc.DocumentElement;
    var Grandchild := Root.FirstChild.FirstChild;
    var Detached := Doc.CreateElement('x');
    Assert.WillRaise(procedure begin Root.RemoveChild(Grandchild) end, EXmlError, 'RemoveChild of a grandchild');
    Assert.WillRaise(procedure begin Root.RemoveChild(Detached) end, EXmlError, 'RemoveChild of a detached node');
    Assert.WillRaise(procedure begin Root.ReplaceChild(Doc.CreateElement('n'), Grandchild) end, EXmlError,
      'ReplaceChild of a grandchild');
    Assert.WillRaise(procedure begin Root.ReplaceChild(Doc.CreateElement('n'), Detached) end, EXmlError,
      'ReplaceChild of a detached node');
    Assert.WillRaise(procedure begin Root.ReplaceChild(Doc.CreateElement('n'), Root) end, EXmlError,
      'ReplaceChild of the node itself');
    Assert.WillRaise(procedure begin Root.InsertBefore(Doc.CreateElement('n'), Grandchild) end, EXmlError,
      'InsertBefore a grandchild');
    Assert.AreEqual('<r><a><b/></a><c/></r>', Root.Xml);
  end;

begin
  var Used := LibraryMemoryInUse;
  Refuse;
  Doc := nil;
  Assert.IsTrue(Released = nil, 'the document goes with the last reference');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// A node put under itself or one of its descendants is refused with EXmlError, as in MSXML:
// libxml2 would link it and make the tree a loop.
procedure TXMLDOMTest.TestNodeIsNotInsertedUnderItself;
var
  [Weak] Released: IXMLDocument;
  Doc: IXMLDocument;

  procedure Refuse;
  begin
    Doc := CoCreateXMLDocument;
    Released := Doc;
    Assert.IsTrue(Doc.LoadXML('<r><a><b/></a></r>'));
    var Root := Doc.DocumentElement;
    var A := Root.FirstChild;
    Assert.WillRaise(procedure begin A.AppendChild(Root) end, EXmlError, 'AppendChild of an ancestor');
    Assert.WillRaise(procedure begin A.AppendChild(A) end, EXmlError, 'AppendChild of the node itself');
    Assert.WillRaise(procedure begin A.InsertBefore(Root, A.FirstChild) end, EXmlError, 'InsertBefore of an ancestor');
    Assert.WillRaise(procedure begin A.ReplaceChild(A, A.FirstChild) end, EXmlError, 'ReplaceChild with the node itself');
    Assert.WillRaise(procedure begin A.ReplaceChild(Root, A.FirstChild) end, EXmlError, 'ReplaceChild with an ancestor');
    Assert.AreEqual('<r><a><b/></a></r>', Doc.DocumentElement.Xml);
  end;

begin
  var Used := LibraryMemoryInUse;
  Refuse;
  Doc := nil;
  Assert.IsTrue(Released = nil, 'the document goes with the last reference');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// An attribute taken from its element (RemoveAttributeNode, RemoveNamedItem) keeps its name
// and namespace after the element and the declaration on it are gone, as in MSXML, and set
// on another element brings the declaration along.
procedure TXMLDOMTest.TestRemovedAttributeKeepsItsNamespace;
var
  [Weak] Released: IXMLDocument;
  Doc: IXMLDocument;
  A, B: IXMLAttribute;

  procedure RemoveAndDropTheElement;
  begin
    Doc := CoCreateXMLDocument;
    Released := Doc;
    Assert.IsTrue(Doc.LoadXML('<r><e xmlns:p="urn:p" p:a="1" p:b="2"/><f/><g/></r>'));
    var E := Doc.DocumentElement.FirstChild as IXMLElement;
    A := E.RemoveAttributeNode(E.GetAttributeNode('p:a'));
    B := E.Attributes.RemoveNamedItem('p:b') as IXMLAttribute;
    Assert.AreEqual('<e xmlns:p="urn:p"/>', E.Xml);
    Doc.DocumentElement.RemoveChild(E);
  end;

  procedure UseTheAttributes;
  begin
    Assert.AreEqual('p:a', A.Name);
    Assert.AreEqual('urn:p', A.NamespaceURI);
    Assert.AreEqual('p:b', B.Name);
    Assert.AreEqual('urn:p', B.NamespaceURI);
    Doc.DocumentElement.FirstChild.Attributes.SetNamedItem(A);
    Doc.DocumentElement.LastChild.Attributes.SetNamedItem(B);
    Assert.AreEqual('<r><f xmlns:p="urn:p" p:a="1"/><g xmlns:p="urn:p" p:b="2"/></r>', Doc.DocumentElement.Xml);
  end;

begin
  var Used := LibraryMemoryInUse;
  RemoveAndDropTheElement;
  UseTheAttributes;
  A := nil;
  B := nil;
  Doc := nil;
  Assert.IsTrue(Released = nil, 'the document goes with the last reference');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// The attributes of an element hold the element, as in MSXML: the list, and an enumerator
// taken from such a list, stay usable once nothing else refers to the element or to its
// document. The enumerator goes through the namespace declarations and then the ordinary
// attributes. The document goes with the last of them.
procedure TXMLDOMTest.TestAttributesKeepTheDocumentAlive;
var
  [Weak] Released: IXMLDocument;
  Doc: IXMLDocument;
  Attrs: IXMLAttributes;
  Enum: IXMLAttributesEnumerator;

  procedure TakeTheAttributes;
  begin
    Doc := CoCreateXMLDocument;
    Released := Doc;
    Assert.IsTrue(Doc.LoadXML('<r xmlns:p="urn:p" a="1" p:b="2"/>'));
    Attrs := Doc.DocumentElement.Attributes;
    Enum := Doc.DocumentElement.Attributes.GetEnumerator;
  end;

  procedure UseTheAttributes;
  begin
    Assert.AreEqual<NativeInt>(3, Attrs.Length);
    Assert.AreEqual('xmlns:p', Attrs[0].Name);
    Assert.AreEqual('urn:p', Attrs[0].Value);
    Assert.AreEqual('a', Attrs[1].Name);
    Assert.AreEqual('2', Attrs.GetNamedItem('p:b').NodeValue);
    Assert.AreEqual('r', Attrs[2].OwnerElement.NodeName);
    var Names := '';
    while Enum.MoveNext do
      Names := Names + ' ' + Enum.Current.Name;
    Assert.AreEqual(' xmlns:p a p:b', Names, 'the enumerator');
  end;

begin
  var Used := LibraryMemoryInUse;
  TakeTheAttributes;
  Doc := nil;
  Assert.IsTrue(Released <> nil, 'the attributes keep the document alive');
  UseTheAttributes;
  Attrs := nil;
  Assert.IsTrue(Released <> nil, 'the enumerator keeps the document alive');
  Enum := nil;
  Assert.IsTrue(Released = nil, 'the document goes with the last reference');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// The attributes of an element outside the tree, created and never inserted or removed from
// it, hold the element as well: they stay usable once nothing else refers to the element, as
// in MSXML, and the element goes with them.
procedure TXMLDOMTest.TestAttributesOfDetachedElementsStayUsable;
var
  [Weak] Released: IXMLDocument;
  Doc: IXMLDocument;
  Created, Removed: IXMLAttributes;

  procedure TakeTheAttributes;
  begin
    Doc := CoCreateXMLDocument;
    Released := Doc;
    Assert.IsTrue(Doc.LoadXML('<r><e xmlns:q="urn:q" y="2"><c/></e></r>'));
    var E := Doc.CreateElement('n');
    E.SetAttribute('x', '1');
    Created := E.Attributes;
    Removed := Doc.DocumentElement.RemoveChild(Doc.DocumentElement.FirstChild).Attributes;
  end;

  procedure UseTheAttributes;
  begin
    Assert.AreEqual<NativeInt>(1, Created.Length);
    Assert.AreEqual('1', Created[0].Value);
    Assert.AreEqual('<n x="1"/>', Created[0].OwnerElement.Xml);
    Assert.AreEqual<NativeInt>(2, Removed.Length);
    Assert.AreEqual('urn:q', Removed[0].Value);
    Assert.AreEqual('2', Removed.GetNamedItem('y').NodeValue);
    Assert.AreEqual('<e xmlns:q="urn:q" y="2"><c/></e>', Removed[1].OwnerElement.Xml);
    Assert.AreEqual('<r/>', Doc.DocumentElement.Xml);
  end;

begin
  var Used := LibraryMemoryInUse;
  var Wrappers := DebugObjectCount;
  TakeTheAttributes;
  UseTheAttributes;
  Doc := nil;
  Assert.IsTrue(Released <> nil, 'the attributes keep the document alive');
  Created := nil;
  Removed := nil;
  Assert.IsTrue(Released = nil, 'the document goes with the last reference');
  Assert.AreEqual<NativeInt>(Wrappers, DebugObjectCount, 'wrappers');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// The attributes of the root survive a reload of the document, as in MSXML: they stay the
// attributes of the old root, which the reloaded document owns.
procedure TXMLDOMTest.TestAttributesSurviveReload;
var
  [Weak] Released: IXMLDocument;
  Doc: IXMLDocument;
  Attrs: IXMLAttributes;

  procedure TakeAndReload;
  begin
    Doc := CoCreateXMLDocument;
    Released := Doc;
    Assert.IsTrue(Doc.LoadXML('<r xmlns:p="urn:p" a="1"/>'));
    Attrs := Doc.DocumentElement.Attributes;
  end;

  procedure Reload;
  begin
    Assert.IsTrue(Doc.LoadXML('<s b="2"/>'));
  end;

  procedure UseTheAttributes;
  begin
    Assert.AreEqual<NativeInt>(2, Attrs.Length);
    Assert.AreEqual('xmlns:p', Attrs[0].Name);
    Assert.AreEqual('1', Attrs.GetNamedItem('a').NodeValue);
    Assert.IsTrue(Attrs[1].OwnerDocument = Doc, 'the reloaded document owns them, as in MSXML');
    Assert.IsTrue(Attrs[0].OwnerDocument = Doc, 'the declaration as well');
    Assert.AreEqual('<s b="2"/>', Doc.DocumentElement.Xml);
  end;

begin
  var Used := LibraryMemoryInUse;
  TakeAndReload;
  Reload;
  UseTheAttributes;
  Doc := nil;
  Assert.IsTrue(Released <> nil, 'the attributes keep the document alive');
  Attrs := nil;
  Assert.IsTrue(Released = nil, 'the document goes with the last reference');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// A namespace declaration taken as an attribute (xmlns:p) holds its element as an attribute
// does, as in MSXML: it stays usable once nothing else refers to the element or to its
// document, the declaration of a removed element as well, and reports its element and its
// document.
procedure TXMLDOMTest.TestNamespaceDeclarationKeepsItsElement;
var
  [Weak] Released: IXMLDocument;
  Doc: IXMLDocument;
  OfRoot, OfRemoved: IXMLAttribute;

  procedure TakeTheDeclarations;
  begin
    Doc := CoCreateXMLDocument;
    Released := Doc;
    Assert.IsTrue(Doc.LoadXML('<r xmlns:p="urn:p" a="1"><e xmlns:q="urn:q" y="2"/></r>'));
    OfRoot := Doc.DocumentElement.Attributes.GetNamedItem('xmlns:p') as IXMLAttribute;
    OfRemoved := Doc.DocumentElement.RemoveChild(Doc.DocumentElement.FirstChild).Attributes[0];
  end;

  procedure UseTheDeclarations;
  begin
    Assert.AreEqual('xmlns:q', OfRemoved.Name);
    Assert.AreEqual('urn:q', OfRemoved.Value);
    Assert.AreEqual('<e xmlns:q="urn:q" y="2"/>', OfRemoved.OwnerElement.Xml);
    Assert.IsTrue(OfRemoved.OwnerDocument = Doc, 'the document owns the declaration');
    Assert.IsTrue(OfRoot.OwnerDocument = Doc, 'the document of the root declaration');
  end;

  procedure UseWithoutTheDocument;
  begin
    Assert.AreEqual('xmlns:p', OfRoot.NodeName);
    Assert.AreEqual('urn:p', OfRoot.Value);
    Assert.AreEqual('r', OfRoot.OwnerElement.NodeName);
    Assert.AreEqual('<r xmlns:p="urn:p" a="1"/>', OfRoot.OwnerDocument.DocumentElement.Xml);
  end;

begin
  var Used := LibraryMemoryInUse;
  var Wrappers := DebugObjectCount;
  TakeTheDeclarations;
  UseTheDeclarations;
  OfRemoved := nil;
  Doc := nil;
  Assert.IsTrue(Released <> nil, 'the declaration keeps the document alive');
  UseWithoutTheDocument;
  OfRoot := nil;
  Assert.IsTrue(Released = nil, 'the document goes with the last reference');
  Assert.AreEqual<NativeInt>(Wrappers, DebugObjectCount, 'wrappers');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// A namespace declaration created on its own (CreateAttribute('xmlns:p')) belongs to no
// element: it has no parent, owner element or siblings. Set on an element it belongs to the
// element; removed from the element it is the same node, as in MSXML, and belongs to none
// again until it is set on another one.
procedure TXMLDOMTest.TestCreatedNamespaceDeclaration;
var
  [Weak] Released: IXMLDocument;
  Doc: IXMLDocument;

  procedure CreateSetAndRemove;
  begin
    Doc := CoCreateXMLDocument;
    Released := Doc;
    Assert.IsTrue(Doc.LoadXML('<r><a/><b/></r>'));
    var Decl := Doc.CreateAttribute('xmlns:p');
    Decl.Value := 'urn:p';
    Assert.AreEqual('xmlns:p', Decl.Name);
    Assert.AreEqual('urn:p', Decl.Value);
    Assert.IsNull(Decl.ParentNode);
    Assert.IsNull(Decl.OwnerElement);
    Assert.IsNull(Decl.NextSibling);
    Assert.IsNull(Decl.PreviousSibling);

    var A := Doc.DocumentElement.FirstChild;
    A.Attributes.SetNamedItem(Decl);
    Assert.AreEqual('<a xmlns:p="urn:p"/>', A.Xml);
    Assert.AreEqual('a', Decl.OwnerElement.NodeName);
    Assert.IsTrue(Decl.OwnerDocument = Doc, 'the document of the element');

    var Removed := A.Attributes.RemoveNamedItem('xmlns:p');
    Assert.IsTrue((Removed as TObject) = (Decl as TObject), 'the declaration itself, as in MSXML');
    Assert.AreEqual('<a/>', A.Xml);
    Assert.IsNull(Decl.ParentNode, 'removed, it belongs to no element');
    Assert.IsNull(Decl.OwnerElement);
    Assert.IsNull(Decl.NextSibling);
    Assert.AreEqual('urn:p', Decl.Value);

    Doc.DocumentElement.LastChild.Attributes.SetNamedItem(Decl);
    Assert.AreEqual('<r><a/><b xmlns:p="urn:p"/></r>', Doc.DocumentElement.Xml);
    Assert.AreEqual('b', Decl.OwnerElement.NodeName);
  end;

begin
  var Used := LibraryMemoryInUse;
  CreateSetAndRemove;
  Doc := nil;
  Assert.IsTrue(Released = nil, 'the document goes with the last reference');
  Assert.AreEqual<NativeUInt>(Used, LibraryMemoryInUse, 'libxml2 memory');
end;

// The enumerator of the attributes and NextNode go through the namespace declarations and
// then the ordinary attributes, in the order of Item, as nextNode of MSXML does.
procedure TXMLDOMTest.TestAttributesEnumerateDeclarationsAndAttributes;

  function Enumerated(const Xml: string): string;
  begin
    var Doc := CoCreateXMLDocument;
    Assert.IsTrue(Doc.LoadXML(Xml));
    var Attrs := Doc.DocumentElement.Attributes;
    Result := '';
    for var Attr in Attrs do
      Result := Result + ' ' + Attr.Name;

    var Next := '';
    for var Pass := 1 to 2 do
    begin
      var Node := Attrs.NextNode;
      while Node <> nil do
      begin
        Next := Next + ' ' + Node.NodeName;
        Node := Attrs.NextNode;
      end;
      Attrs.Reset;
    end;
    Assert.AreEqual(Result + Result, Next, 'NextNode, twice with Reset');
  end;

begin
  Assert.AreEqual(' xmlns:p xmlns:q a p:b', Enumerated('<r xmlns:p="urn:p" xmlns:q="urn:q" a="1" p:b="2"/>'));
  Assert.AreEqual(' a b', Enumerated('<r a="1" b="2"/>'));
  Assert.AreEqual(' xmlns:p', Enumerated('<r xmlns:p="urn:p"/>'));
  Assert.AreEqual('', Enumerated('<r/>'));
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

// Both files of a no-namespace schema are loaded from disk and added, and the main one
// includes the other by its file name: the include and the added document are one schema
// document, compiled once, whatever the order of Add and the spelling of the path.
procedure TXMLSchemaTest.TestIncludeOfAnAddedFileIsNotReadAgain;
begin
  // The paths of the first set are ASCII (so is the directory of the test where Tests.ps1
  // runs it), and xmlBuildURI accepts them as URIs; those of the second set it refuses:
  // letters beyond ASCII, braces.
  var guid := TGUID.NewGuid.ToString.Trim(['{', '}']);
  var dirs: TArray<string> := [
    TPath.Combine(TPath.GetDirectoryName(TPath.GetFullPath(ParamStr(0))), 'LX2-schemas-' + guid),
    TPath.Combine(TPath.GetTempPath, 'LX2 Схемы {' + guid + '}')];
  var names: TArray<string> := ['types', 'типы'];
  for var I := 0 to High(dirs) do
  begin
    var dir := dirs[I];
    TDirectory.CreateDirectory(TPath.Combine(dir, 'common'));
    try
      var types := TPath.Combine(TPath.Combine(dir, 'common'), names[I] + '.xsd');
      var main := TPath.Combine(dir, 'main.xsd');
      TFile.WriteAllText(types,
        '<xs:schema xmlns:xs="' + XsdNs + '">' +
        '<xs:complexType name="ЧастьТип"><xs:attribute name="n" type="xs:int" use="required"/></xs:complexType>' +
        '</xs:schema>', TEncoding.UTF8);
      TFile.WriteAllText(main,
        '<xs:schema xmlns:xs="' + XsdNs + '">' +
        '<xs:include schemaLocation="common/' + names[I] + '.xsd"/>' +
        '<xs:element name="Сообщение" type="ЧастьТип"/>' +
        '</xs:schema>', TEncoding.UTF8);

      // Another spelling of the same path: "." and "..", and under Windows the letter case.
{$IFDEF MSWINDOWS}
      var spelled: TArray<string> := [dir, '.', 'common', '..', 'COMMON', names[I].ToUpper + '.xsd'];
{$ELSE}
      var spelled: TArray<string> := [dir, '.', 'common', '..', 'common', names[I] + '.xsd'];
{$ENDIF}
      var orders: TArray<TArray<string>> := [
        [types, main],
        [main, types],
        [string.Join(string(PathDelim), spelled), main],
        [types, main.Replace(PathDelim, '/')],
        // The included file alone, and one file added twice.
        [main],
        [types, main, types]];
      for var order in orders do
      begin
        var schemas := CoCreateSchemaCollection;
        for var path in order do
        begin
          var xsd := CoCreateXMLDocument;
          Assert.IsTrue(xsd.Load(path), path);
          schemas.Add('', xsd);
        end;

        var valid := InstanceDoc('<Сообщение n="1"/>');
        var isValid := schemas.Validate(valid);
        var context := string.Join(', ', order) + sLineBreak + Diagnostics(schemas, valid);
        Assert.IsTrue(isValid, context);
        Assert.AreEqual<NativeInt>(0, schemas.Errors.Count, context);
        Assert.IsFalse(schemas.Validate(InstanceDoc('<Сообщение/>')), context);
      end;
    finally
      TDirectory.Delete(dir, True);
    end;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TXMLHelpersTest);
  TDUnitX.RegisterTestFixture(TXMLDOMTest);
  TDUnitX.RegisterTestFixture(TXMLSchemaTest);

end.
