unit LX2ReaderTests;

interface

uses
  System.SysUtils, System.Classes,
  DUnitX.TestFramework;

type
  [TestFixture]
  TXmlConvertTest = class
  public
    [SetupFixture]
    procedure Setup;
    [Test]
    procedure TestBoolean;
    [Test]
    procedure TestIntegers;
    [Test]
    procedure TestDouble;
    [Test]
    procedure TestDoubleIgnoresLocale;
    [Test]
    procedure TestCurrency;
    [Test]
    procedure TestDateTime;
    [Test]
    procedure TestUtf8;
    [Test]
    procedure TestToString;
    [Test]
    procedure TestDomSetAttributeDateTime;
  end;

  [TestFixture]
  TXmlTextReaderHelperTest = class
  public
    [SetupFixture]
    procedure Setup;
    [Test]
    procedure TestEventSequence;
    [Test]
    procedure TestEmptyElementHasNoEnd;
    [Test]
    procedure TestAttributes;
    [Test]
    procedure TestAtoms;
    [Test]
    procedure TestReadTo;
    [Test]
    procedure TestReadElementContent;
    [Test]
    procedure TestReadContent;
    [Test]
    procedure TestTextAndMarkupDoNotMove;
    [Test]
    procedure TestFatalErrorRaisesOnce;
    [Test]
    procedure TestReadPastTheEnd;
    [Test]
    procedure TestHandlerException;
    [Test]
    procedure TestStream;
    [Test]
    procedure TestStreamException;
    [Test]
    procedure TestStringIgnoresDeclaredEncoding;
    [Test]
    procedure TestLineNumbers;
    [Test]
    procedure TestReadNodeNamespaces;
    [Test]
    procedure TestWalker;
    [Test]
    procedure TestNoExternalEntities;
    [Test]
    procedure TestSchemaValidation;
    [Test]
    procedure TestNoLeaks;
  end;

  [TestFixture]
  TXmlReaderTest = class
  public
    [SetupFixture]
    procedure Setup;
    [Test]
    procedure TestWhitespaceKinds;
    [Test]
    procedure TestIgnoreSettings;
    [Test]
    procedure TestDtdProcessing;
    [Test]
    procedure TestDoubleAdvanceTrap;
    [Test]
    procedure TestElements;
    [Test]
    procedure TestElementsEmptyAndNested;
    [Test]
    procedure TestReadElements;
    [Test]
    procedure TestSubtree;
    [Test]
    procedure TestReadToNamespaces;
    [Test]
    procedure TestTypedContent;
    [Test]
    procedure TestStartEndElement;
    [Test]
    procedure TestInnerOuterXml;
    [Test]
    procedure TestReadElementCopy;
    [Test]
    procedure TestExpand;
    [Test]
    procedure TestInPlaceInput;
    [Test]
    procedure TestAttributesFromAttribute;
    [Test]
    procedure TestBase64;
    [Test]
    procedure TestErrors;
    [Test]
    procedure TestValidation;
    [Test]
    procedure TestWalker;
    [Test]
    procedure TestFileAndStream;
    [Test]
    procedure TestLateBinding;
    [Test]
    procedure TestNoLeaks;
  end;

implementation

uses
  System.Math, System.StrUtils, System.IOUtils, System.Variants, libxml2.API, LX2.Types, LX2.Helpers,
  LX2.DOM, LX2.DOM.Classes, LX2.Reader;

const
  BasicXml: UTF8String = '<?xml version="1.0"?>'#10'<!-- top -->'#10 +
    '<r xmlns="urn:d" xmlns:p="urn:p">'#10 +
    '  <a/>'#10 +
    '  <b x="1" p:y="2">t<!--c--><?pi d?><![CDATA[cd]]></b>'#10 +
    '  <c xml:space="preserve">  </c>'#10 +
    '  <p:e>&amp;</p:e>'#10 +
    '</r>'#10;

/// <summary>Depth:type:name of every node, '/' after an empty element.</summary>
function Trace(R: xmlTextReaderPtr): string;
var
  SB: TStringBuilder;
begin
  SB := TStringBuilder.Create;
  try
    while R.Read do
    begin
      if SB.Length > 0 then
        SB.Append(' ');
      SB.Append(R.Depth).Append(':').Append(Ord(R.NodeType)).Append(':').Append(UTF8ToString(R.Name));
      if R.IsEmptyElement then
        SB.Append('/');
    end;
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function Reader(const Xml: UTF8String; const Options: TXmlParserOptions = []): xmlTextReaderPtr;
begin
  Result := xmlTextReader.Create(RawByteString(Xml), Options);
  Assert.IsNotNull(Result, 'reader');
end;

type
  TFailingStream = class(TStream)
  public
    function Read(var Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
  end;

  THandlerProbe = class
  public
    Calls: Integer;
    procedure Raising(const error: xmlError);
    procedure Counting(const error: xmlError);
  end;

function TFailingStream.Read(var Buffer; Count: Longint): Longint;
begin
  raise EReadError.Create('the stream broke');
end;

function TFailingStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  Result := 0;
end;

procedure THandlerProbe.Raising(const error: xmlError);
begin
  Inc(Calls);
  raise EAbort.Create('handler');
end;

procedure THandlerProbe.Counting(const error: xmlError);
begin
  Inc(Calls);
end;

{ TXmlConvertTest }

procedure TXmlConvertTest.Setup;
begin
  LX2Lib.Initialize;
end;

procedure TXmlConvertTest.TestBoolean;
var
  B: Boolean;
begin
  Assert.IsTrue(XmlConvert.ToBoolean('true'));
  Assert.IsTrue(XmlConvert.ToBoolean('1'));
  Assert.IsFalse(XmlConvert.ToBoolean('false'));
  Assert.IsFalse(XmlConvert.ToBoolean('0'));
  Assert.IsTrue(XmlConvert.ToBoolean(' '#10'true'#9), 'whitespace around the value');
  Assert.IsFalse(XmlConvert.TryToBoolean('True', B), 'the lexical space is case-sensitive');
  Assert.IsFalse(XmlConvert.TryToBoolean('yes', B));
  Assert.IsFalse(XmlConvert.TryToBoolean('', B));
  Assert.WillRaise(procedure begin XmlConvert.ToBoolean('t') end, EConvertError);
end;

procedure TXmlConvertTest.TestIntegers;
var
  I: Integer;
  L: Int64;
begin
  Assert.AreEqual<Int64>(42, XmlConvert.ToInt64('42'));
  Assert.AreEqual<Int64>(42, XmlConvert.ToInt64('+42'));
  Assert.AreEqual<Int64>(0, XmlConvert.ToInt64('-0'));
  Assert.AreEqual<Int64>(7, XmlConvert.ToInt64('0007'));
  Assert.AreEqual<Int64>(High(Int64), XmlConvert.ToInt64('9223372036854775807'));
  Assert.AreEqual<Int64>(Low(Int64), XmlConvert.ToInt64('-9223372036854775808'));
  Assert.IsFalse(XmlConvert.TryToInt64('9223372036854775808', L), 'past High(Int64)');
  Assert.IsFalse(XmlConvert.TryToInt64('-9223372036854775809', L), 'past Low(Int64)');
  Assert.IsFalse(XmlConvert.TryToInt64('1 2', L));
  Assert.IsFalse(XmlConvert.TryToInt64('1.0', L));
  Assert.IsFalse(XmlConvert.TryToInt64('-', L));
  Assert.IsFalse(XmlConvert.TryToInt64('', L));
  Assert.AreEqual(High(Integer), XmlConvert.ToInteger('2147483647'));
  Assert.AreEqual(Low(Integer), XmlConvert.ToInteger('-2147483648'));
  Assert.IsFalse(XmlConvert.TryToInteger('2147483648', I), 'past High(Integer)');
end;

procedure TXmlConvertTest.TestDouble;
var
  D: Double;
begin
  Assert.AreEqual(1.5, XmlConvert.ToDouble('1.5'), 0);
  Assert.AreEqual(-1500.0, XmlConvert.ToDouble('-1.5E3'), 0);
  Assert.AreEqual(0.5, XmlConvert.ToDouble('.5'), 0);
  Assert.AreEqual(5.0, XmlConvert.ToDouble('5.'), 0);
  Assert.AreEqual(0.001, XmlConvert.ToDouble('1e-3'), 0);
  Assert.IsTrue(IsInfinite(XmlConvert.ToDouble('INF')) and (XmlConvert.ToDouble('INF') > 0));
  Assert.IsTrue(IsInfinite(XmlConvert.ToDouble('+INF')) and (XmlConvert.ToDouble('+INF') > 0));
  Assert.IsTrue(IsInfinite(XmlConvert.ToDouble('-INF')) and (XmlConvert.ToDouble('-INF') < 0));
  Assert.IsTrue(IsNan(XmlConvert.ToDouble('NaN')));
  Assert.IsFalse(XmlConvert.TryToDouble('1,5', D), 'a comma is not a separator');
  Assert.IsFalse(XmlConvert.TryToDouble('1.5.2', D));
  Assert.IsFalse(XmlConvert.TryToDouble('e5', D));
  Assert.IsFalse(XmlConvert.TryToDouble('1e', D));
  Assert.IsFalse(XmlConvert.TryToDouble('1 000', D));
  Assert.IsFalse(XmlConvert.TryToDouble('inf', D));
  Assert.IsFalse(XmlConvert.TryToDouble('', D));
end;

procedure TXmlConvertTest.TestDoubleIgnoresLocale;
var
  Saved: TFormatSettings;
  C: Currency;
begin
  Saved := FormatSettings;
  try
    FormatSettings.DecimalSeparator := ',';
    FormatSettings.ThousandSeparator := ' ';
    Assert.AreEqual(12.5, XmlConvert.ToDouble('12.5'), 0);
    Assert.AreEqual('12.5', XmlConvert.FromDouble(12.5));
    Assert.IsTrue(XmlConvert.TryToCurrency('12.50', C));
    Assert.AreEqual('12.5', XmlConvert.FromCurrency(C));
  finally
    FormatSettings := Saved;
  end;
end;

procedure TXmlConvertTest.TestCurrency;
var
  C: Currency;
begin
  Assert.AreEqual<Currency>(12.5, XmlConvert.ToCurrency('12.50'));
  Assert.AreEqual<Currency>(-0.5, XmlConvert.ToCurrency('-.5'));
  Assert.AreEqual<Currency>(5, XmlConvert.ToCurrency('5.'));
  Assert.AreEqual<Currency>(0.1234, XmlConvert.ToCurrency('0.12340000'), 'zeros past the fourth digit');
  Assert.AreEqual<Currency>(922337203685477.5807, XmlConvert.ToCurrency('922337203685477.5807'));
  Assert.IsTrue(XmlConvert.TryToCurrency('-922337203685477.5808', C));
  Assert.AreEqual<Int64>(Low(Int64), PInt64(@C)^, 'the lowest Currency');
  Assert.IsFalse(XmlConvert.TryToCurrency('922337203685477.5808', C), 'past the range');
  Assert.IsFalse(XmlConvert.TryToCurrency('1000000000000000', C), 'past the range');
  Assert.IsFalse(XmlConvert.TryToCurrency('0.12345', C), 'a fifth significant fraction digit');
  Assert.IsFalse(XmlConvert.TryToCurrency('1E3', C), 'xs:decimal has no exponent');
  Assert.IsFalse(XmlConvert.TryToCurrency('.', C));
  Assert.IsFalse(XmlConvert.TryToCurrency('1,5', C));
end;

procedure TXmlConvertTest.TestDateTime;
var
  D: TDateTime;
  Offset: Integer;
  HasOffset: Boolean;
begin
  Assert.AreEqual(EncodeDate(2026, 10, 13) + EncodeTime(9, 5, 7, 0), XmlConvert.ToDateTime('2026-10-13T09:05:07'), 0);
  Assert.AreEqual(EncodeDate(2026, 10, 13), XmlConvert.ToDateTime('2026-10-13'), 0);
  D := XmlConvert.ToDateTime('2026-10-13T09:05:07.123456Z', Offset, HasOffset);
  Assert.AreEqual(EncodeDate(2026, 10, 13) + EncodeTime(9, 5, 7, 123), D, 1 / MSecsPerDay / 10, 'digits past milliseconds are truncated');
  Assert.IsTrue(HasOffset);
  Assert.AreEqual(0, Offset);
  D := XmlConvert.ToDateTime('2026-10-13T09:05:07-03:30', Offset, HasOffset);
  Assert.AreEqual(EncodeDate(2026, 10, 13) + EncodeTime(9, 5, 7, 0), D, 0, 'the time as written');
  Assert.AreEqual(-210, Offset);
  XmlConvert.ToDateTime('2026-10-13', Offset, HasOffset);
  Assert.IsFalse(HasOffset);
  Assert.AreEqual(EncodeDate(2026, 10, 14), XmlConvert.ToDateTime('2026-10-13T24:00:00'), 0, '24:00:00 is the next midnight');
  Assert.AreEqual(Double(-1.25), Double(XmlConvert.ToDateTime('1899-12-29T06:00:00')), 0, 'before the TDateTime epoch');
  Assert.IsFalse(XmlConvert.TryToDateTime('2026-02-30', D));
  Assert.IsFalse(XmlConvert.TryToDateTime('2026-10-13T25:00:00', D));
  Assert.IsFalse(XmlConvert.TryToDateTime('2026-10-13T24:00:01', D));
  Assert.IsFalse(XmlConvert.TryToDateTime('2026-10-13T09:05', D));
  Assert.IsFalse(XmlConvert.TryToDateTime('2026-10-13T09:05:07.', D));
  Assert.IsFalse(XmlConvert.TryToDateTime('2026-10-13T09:05:07+15:00', D));
  Assert.IsFalse(XmlConvert.TryToDateTime('13.10.2026', D));
  Assert.IsFalse(XmlConvert.TryToDateTime('2026-10-13 09:05:07', D));
end;

procedure TXmlConvertTest.TestUtf8;
const
  Number: UTF8String = '  -42'#10;
  Cyrillic: UTF8String = '4' + #$D0#$B0;
var
  L: Int64;
  D: TDateTime;
  Offset: Integer;
  HasOffset: Boolean;
begin
  Assert.IsTrue(XmlConvert.TryToInt64(PUTF8Char(Number), Length(Number), L));
  Assert.AreEqual<Int64>(-42, L);
  Assert.IsTrue(XmlConvert.TryToInt64(PUTF8Char(Number), 4, L), 'only Len bytes are read');
  Assert.AreEqual<Int64>(-4, L);
  Assert.IsFalse(XmlConvert.TryToInt64(PUTF8Char(Cyrillic), Length(Cyrillic), L), 'a byte above $7F');
  Assert.IsTrue(XmlConvert.TryToDateTime(PUTF8Char(UTF8String('2026-10-13T09:05:07Z')), 20, D, Offset, HasOffset));
  Assert.IsTrue(HasOffset);
end;

procedure TXmlConvertTest.TestToString;
var
  D: Double;
begin
  Assert.AreEqual('true', XmlConvert.FromBoolean(True));
  Assert.AreEqual('false', XmlConvert.FromBoolean(False));
  Assert.AreEqual('-9223372036854775808', XmlConvert.FromInt64(Low(Int64)));
  Assert.AreEqual('0.1', XmlConvert.FromDouble(0.1));
  Assert.AreEqual('INF', XmlConvert.FromDouble(Infinity));
  Assert.AreEqual('-INF', XmlConvert.FromDouble(NegInfinity));
  Assert.AreEqual('NaN', XmlConvert.FromDouble(NaN));
  D := 1 / 3;
  Assert.AreEqual(D, XmlConvert.ToDouble(XmlConvert.FromDouble(D)), 0, 'round trip');
  D := 1E20;
  Assert.AreEqual(D, XmlConvert.ToDouble(XmlConvert.FromDouble(D)), 0, 'round trip with an exponent');
  Assert.AreEqual('12.5', XmlConvert.FromCurrency(12.5));
  Assert.AreEqual('2026-01-05T09:03:07', XmlConvert.FromDateTime(EncodeDate(2026, 1, 5) + EncodeTime(9, 3, 7, 0)));
  Assert.AreEqual('2026-01-05T09:03:07.040', XmlConvert.FromDateTime(EncodeDate(2026, 1, 5) + EncodeTime(9, 3, 7, 40)));
  Assert.AreEqual('2026-01-05', XmlConvert.FromDate(EncodeDate(2026, 1, 5) + EncodeTime(9, 3, 7, 0)));
end;

procedure TXmlConvertTest.TestDomSetAttributeDateTime;
begin
  var Doc := CoCreateXMLDocument;
  var Root := Doc.CreateRoot('r');
  Root.SetAttribute('d', EncodeDate(2026, 1, 5));
  Root.SetAttribute('t', EncodeDate(2026, 1, 5) + EncodeTime(9, 3, 7, 0));
  Assert.AreEqual('2026-01-05', Root.GetAttribute('d'));
  Assert.AreEqual('2026-01-05T09:03:07', Root.GetAttribute('t'));
  Assert.AreEqual(EncodeDate(2026, 1, 5) + EncodeTime(9, 3, 7, 0), XmlConvert.ToDateTime(Root.GetAttribute('t')), 0);
end;

{ TXmlTextReaderHelperTest }

procedure TXmlTextReaderHelperTest.Setup;
begin
  LX2Lib.Initialize;
end;

procedure TXmlTextReaderHelperTest.TestEventSequence;
begin
  var R := Reader(BasicXml);
  try
    // Whitespace-only text is significant whitespace (14) everywhere, never 13
    Assert.AreEqual('0:8:#comment 0:1:r 1:14:#text 1:1:a/ 1:14:#text 1:1:b 2:3:#text 2:8:#comment ' +
      '2:7:pi 2:4:#cdata-section 1:15:b 1:14:#text 1:1:c 2:14:#text 1:15:c 1:14:#text 1:1:p:e ' +
      '2:3:#text 1:15:p:e 1:14:#text 0:15:r', Trace(R));
    Assert.AreEqual(Ord(XML_TEXTREADER_MODE_EOF), Ord(R.ReadState));
  finally
    R.Free;
  end;
end;

procedure TXmlTextReaderHelperTest.TestEmptyElementHasNoEnd;
begin
  var R := Reader('<r><a/><b></b></r>');
  try
    Assert.AreEqual('0:1:r 1:1:a/ 1:1:b 1:15:b 0:15:r', Trace(R));
  finally
    R.Free;
  end;
end;

procedure TXmlTextReaderHelperTest.TestAttributes;
var
  V: RawByteString;
begin
  var R := Reader('<r xmlns:p="urn:p" xmlns="urn:d" p:y="2" z="3" xml:lang="ru"/>');
  try
    Assert.IsTrue(R.Read);
    Assert.AreEqual(5, R.AttributeCount);
    var Names := '';
    Assert.IsTrue(R.MoveToFirstAttribute);
    repeat
      Names := Names + UTF8ToString(R.Name) + IfThen(R.IsNamespaceDecl, '*', '') + ' ';
      Assert.AreEqual(1, R.Depth, 'an attribute is one level below its element');
    until not R.MoveToNextAttribute;
    Assert.AreEqual('xmlns:p* xmlns* p:y z xml:lang ', Names, 'declarations first, each group in document order');
    Assert.AreEqual(0, R.AttributeCount, 'libxml2 counts nothing while on an attribute');
    Assert.IsTrue(R.MoveToElement);
    Assert.AreEqual('2', string(R.GetAttribute('p:y')));
    Assert.AreEqual('', string(R.GetAttribute('y')), 'a local name alone does not find a prefixed attribute');
    Assert.AreEqual('2', string(R.GetAttribute('y', 'urn:p')));
    Assert.AreEqual('3', string(R.GetAttribute('z', '')), 'an empty namespace is no namespace');
    Assert.AreEqual('urn:p', string(R.GetAttribute('xmlns:p')));
    Assert.AreEqual('ru', string(R.GetAttribute('lang', XmlReservedNs.NsXml)));
    Assert.IsFalse(R.TryGetAttribute('missing', V));
    Assert.IsTrue(R.TryGetAttribute('z', V));
    Assert.AreEqual('3', string(V));
    Assert.AreEqual('urn:d', string(R.LookupNamespace('')));
    Assert.AreEqual('urn:p', string(R.LookupNamespace('p')));
    Assert.IsTrue(R.MoveToAttribute('z', ''));
    Assert.AreEqual('3', string(R.Value));
    Assert.IsTrue(R.MoveToAttribute('y', 'urn:p'));
    Assert.AreEqual('2', string(R.Value));
    Assert.IsTrue(R.ReadAttributeValue);
    Assert.AreEqual(Ord(XML_READER_TYPE_TEXT), Ord(R.NodeType));
    Assert.AreEqual('2', string(R.Value));
  finally
    R.Free;
  end;
end;

procedure TXmlTextReaderHelperTest.TestAtoms;
begin
  var R := Reader('<r xmlns:p="urn:p"><item/><p:item/><other/></r>');
  try
    var AItem := R.Atom('item');
    var ANs := R.Atom('urn:p');
    Assert.IsTrue(R.ReadToFollowing(AItem));
    Assert.IsTrue(R.LocalNamePtr = AItem, 'names come from the dictionary of the reader');
    Assert.IsTrue(R.IsElement(AItem));
    Assert.IsFalse(R.IsElement(AItem, ANs), 'the first item has no namespace');
    Assert.IsTrue(R.IsElement(AItem, nil));
    Assert.IsTrue(R.ReadToFollowing(AItem, ANs));
    Assert.AreEqual('p:item', string(R.Name));
    Assert.IsFalse(R.ReadToFollowing(AItem));
    Assert.IsNull(R.Atom(''));
  finally
    R.Free;
  end;
end;

procedure TXmlTextReaderHelperTest.TestReadTo;
const
  X: UTF8String = '<r><a><x/><b>1</b></a><b>2</b><c/><b>3</b></r>';
begin
  var R := Reader(X);
  try
    Assert.IsTrue(R.ReadToFollowing(R.Atom('b')));
    Assert.AreEqual(2, R.Depth, 'the first b in document order is inside a');
    R.Free;

    R := Reader(X);
    Assert.IsTrue(R.ReadToFollowing(R.Atom('a')));
    Assert.IsTrue(R.ReadToDescendant(R.Atom('b')));
    Assert.AreEqual(2, R.Depth);
    R.Free;

    R := Reader(X);
    Assert.IsTrue(R.ReadToFollowing(R.Atom('a')));
    Assert.IsFalse(R.ReadToDescendant(R.Atom('q')));
    Assert.AreEqual(Ord(XML_READER_TYPE_END_ELEMENT), Ord(R.NodeType), 'on the end tag of a');
    Assert.AreEqual('a', string(R.Name));
    R.Free;

    R := Reader(X);
    var AB := R.Atom('b');
    Assert.IsTrue(R.ReadToFollowing(R.Atom('a')));
    Assert.IsTrue(R.ReadToNextSibling(AB));
    Assert.AreEqual('2', string(R.Text));
    Assert.IsTrue(R.ReadToNextSibling(AB), 'past c');
    Assert.AreEqual('3', string(R.Text));
    Assert.IsFalse(R.ReadToNextSibling(AB));
    Assert.AreEqual(Ord(XML_READER_TYPE_END_ELEMENT), Ord(R.NodeType), 'on the end tag of the parent');
    Assert.AreEqual('r', string(R.Name));
    R.Free;

    R := Reader('<r><x/></r>');
    Assert.IsTrue(R.ReadToDescendant(R.Atom('x')), 'not started: the whole document is the scope');
    Assert.IsFalse(R.ReadToDescendant(R.Atom('x')), 'an empty element has no descendants');
  finally
    R.Free;
  end;
end;

procedure TXmlTextReaderHelperTest.TestReadElementContent;
begin
  var R := Reader('<r><a>x<!--c-->y</a><b/><c><d/></c><e></e><f>1<![CDATA[2]]>3</f><g>z</g></r>');
  try
    Assert.IsTrue(R.ReadToFollowing(R.Atom('a')));
    Assert.AreEqual('xy', string(R.ReadElementContent), 'comments are passed over');
    Assert.AreEqual('b', string(R.Name), 'on the node after the end tag');
    Assert.AreEqual('', string(R.ReadElementContent), 'an empty element');
    Assert.AreEqual('c', string(R.Name));
    Assert.WillRaise(procedure begin R.ReadElementContent end, EXmlReaderError, 'a child element');
    Assert.IsTrue(R.ReadToFollowing(R.Atom('e')));
    Assert.AreEqual('', string(R.ReadElementContent));
    Assert.AreEqual('f', string(R.Name));
    Assert.AreEqual('123', string(R.ReadElementContent), 'text and CDATA together');
    Assert.AreEqual('g', string(R.Name));
    Assert.IsTrue(R.Read);
    Assert.WillRaise(procedure begin R.ReadElementContent end, EXmlReaderError, 'not on an element');
  finally
    R.Free;
  end;
end;

procedure TXmlTextReaderHelperTest.TestReadContent;
begin
  var R := Reader('<r k="v">a<!--c-->b<x/></r>');
  try
    Assert.IsTrue(R.Read);
    Assert.WillRaise(procedure begin R.ReadContent end, EXmlReaderError, 'on an element');
    Assert.IsTrue(R.MoveToFirstAttribute);
    Assert.AreEqual('v', string(R.ReadContent), 'the value of an attribute');
    Assert.AreEqual(Ord(XML_READER_TYPE_ATTRIBUTE), Ord(R.NodeType), 'the reader stays on the attribute');
    Assert.IsTrue(R.Read);
    Assert.AreEqual('ab', string(R.ReadContent));
    Assert.AreEqual('x', string(R.Name), 'stops on the element');
  finally
    R.Free;
  end;
end;

procedure TXmlTextReaderHelperTest.TestTextAndMarkupDoNotMove;
begin
  var R := Reader('<r><a k="v">x<b>y</b>z</a><n/></r>');
  try
    Assert.IsTrue(R.ReadToFollowing(R.Atom('a')));
    Assert.AreEqual('xyz', string(R.Text), 'the text of child elements included');
    Assert.AreEqual('x<b>y</b>z', string(R.InnerXml));
    Assert.AreEqual('<a k="v">x<b>y</b>z</a>', string(R.OuterXml));
    Assert.AreEqual('a', string(R.Name), 'still on a');
    Assert.IsTrue(R.Skip);
    Assert.AreEqual('n', string(R.Name));
  finally
    R.Free;
  end;
end;

procedure TXmlTextReaderHelperTest.TestFatalErrorRaisesOnce;
begin
  var R := Reader('<r><a>1</a><b>2</b><c>3</d></r>');
  try
    try
      R.Read;
      Assert.Fail('a mismatched end tag must raise');
    except
      on E: EXmlParserError do
      begin
        Assert.AreEqual(1, E.Line);
        Assert.AreEqual(76, E.Code, 'XML_ERR_TAG_NAME_MISMATCH');
      end;
    end;
    Assert.IsFalse(R.Read, 'after the error Read returns False');
    Assert.IsFalse(R.Skip);
  finally
    R.Free;
  end;

  // The nodes of the chunk before the error come first
  R := Reader('<r><a>1</a><b>2');
  try
    var Seen := '';
    Assert.WillRaise(procedure begin
      while R.Read do
        Seen := Seen + string(R.Name) + ' ';
    end, EXmlParserError);
    Assert.AreEqual('r a #text a b ', Seen);
    Assert.IsFalse(R.Read);
  finally
    R.Free;
  end;
end;

procedure TXmlTextReaderHelperTest.TestReadPastTheEnd;
var
  Spaces: UTF8String;
begin
  Spaces := UTF8String(StringOfChar(' ', 20000));
  var R := Reader('<r><a/></r>' + Spaces);
  try
    while R.Read do
      ;
    Assert.IsFalse(R.Read, 'past the end');
    Assert.IsFalse(R.Skip);
    Assert.AreEqual(Ord(XML_TEXTREADER_MODE_EOF), Ord(R.ReadState));
  finally
    R.Free;
  end;
  // The input is parsed to its end before the root is closed: content after it is an error
  R := Reader('<r><a/></r>' + Spaces + '<x>');
  try
    Assert.WillRaise(procedure begin
      while R.Read do
        ;
    end, EXmlParserError);
  finally
    R.Free;
  end;
end;

procedure TXmlTextReaderHelperTest.TestHandlerException;
begin
  var Probe := THandlerProbe.Create;
  try
    // An undeclared prefix is a namespace error: reported, and the reading goes on
    var R := xmlTextReader.Create(RawByteString(UTF8String('<r><p:a/><b/></r>')), [], Probe.Raising);
    try
      Assert.WillRaise(procedure begin R.Read end, EAbort, 'the exception of the handler');
      var Found := False;
      while R.Read do
        if R.Name = 'b' then
          Found := True;
      Assert.IsTrue(Found, 'the reader goes on after the handler raised');
      Assert.AreEqual(1, Probe.Calls);
    finally
      R.Free;
    end;
  finally
    Probe.Free;
  end;
end;

procedure TXmlTextReaderHelperTest.TestStream;
begin
  var S := TStringStream.Create('<r><a>текст</a></r>', TEncoding.UTF8);
  try
    var R := xmlTextReader.Create(S, []);
    try
      Assert.IsTrue(R.ReadToFollowing(R.Atom('a')));
      Assert.AreEqual('текст', UTF8ToString(R.ReadElementContent));
    finally
      R.Free;
    end;
    Assert.AreEqual(S.Size, S.Position, 'the stream is read to its end and left open');
  finally
    S.Free;
  end;
end;

procedure TXmlTextReaderHelperTest.TestStreamException;
begin
  var S := TFailingStream.Create;
  try
    Assert.WillRaise(procedure
      begin
        var R := xmlTextReader.Create(S, []);
        try
          while R.Read do
            ;
        finally
          R.Free;
        end;
      end, EReadError, 'the exception of the stream comes out of the reader');
  finally
    S.Free;
  end;
end;

procedure TXmlTextReaderHelperTest.TestStringIgnoresDeclaredEncoding;
begin
  var R := xmlTextReader.Create('<?xml version="1.0" encoding="windows-1251"?><r>Привет</r>', []);
  try
    Assert.IsTrue(R.ReadToFollowing(R.Atom('r')));
    Assert.AreEqual('Привет', UTF8ToString(R.ReadElementContent), 'a Delphi string is UTF-16 whatever it declares');
  finally
    R.Free;
  end;
end;

procedure TXmlTextReaderHelperTest.TestLineNumbers;
begin
  var R := Reader('<r>'#10'  <a k="1"/>'#10'  <b>'#10'    text'#10'  </b>'#10'</r>', [xmlParseBigLines]);
  try
    Assert.IsTrue(R.ReadToFollowing(R.Atom('a')));
    Assert.AreEqual(2, R.LineNumber);
    Assert.IsTrue(R.MoveToFirstAttribute);
    Assert.AreEqual(2, R.LineNumber, 'an attribute is on the line of its element');
    Assert.IsTrue(R.ReadToFollowing(R.Atom('b')));
    Assert.AreEqual(3, R.LineNumber);
    R.Read;
    R.Read;
    Assert.AreEqual(Ord(XML_READER_TYPE_END_ELEMENT), Ord(R.NodeType));
    Assert.AreEqual(3, R.LineNumber, 'an end tag reports the line of its start tag');
  finally
    R.Free;
  end;
end;

procedure TXmlTextReaderHelperTest.TestReadNodeNamespaces;
begin
  var R := Reader('<r xmlns:p="urn:p" xmlns:q="urn:q" xmlns:z="urn:unused" xmlns:t="urn:t">' +
    '<p:a q:attr="1" type="t:Code"><p:b>text</p:b></p:a><after/></r>');
  var Doc := xmlDoc.Create;
  try
    Assert.IsTrue(R.ReadToFollowing(R.Atom('a')));
    var Copy := R.ReadNode(Doc);
    Doc.documentElement := Copy;
    var Xml := string(Copy.Xml);
    Assert.Contains(Xml, 'xmlns:p="urn:p"');
    Assert.Contains(Xml, 'xmlns:q="urn:q"');
    Assert.Contains(Xml, 'xmlns:t="urn:t"', 'a prefix used in a value');
    Assert.Contains(Xml, 'xmlns:z="urn:unused"', 'every namespace in scope');
    var Ns := xmlSearchNs(Doc, Copy, 't');
    Assert.IsNotNull(Ns);
    Assert.AreEqual('urn:t', UTF8ToString(Ns.href));
    Assert.AreEqual('after', string(R.Name), 'the reader is past the element');
    Assert.IsTrue(R.Read);
    Assert.WillRaise(procedure begin R.ReadNode(Doc) end, EXmlReaderError, 'not on an element');
  finally
    Doc.Free;
    R.Free;
  end;
end;

procedure TXmlTextReaderHelperTest.TestWalker;
begin
  var Doc := xmlDoc.Create('<r a="1"><b>t</b><c/></r>', []);
  try
    var R := xmlTextReader.CreateWalker(Doc);
    try
      Assert.IsTrue(R.IsWalker);
      Assert.IsFalse(R.SetSchema(nil), 'a walker cannot validate');
      Assert.AreEqual('0:1:r 1:1:b 2:3:#text 1:15:b 1:1:c/ 0:15:r', Trace(R));
      Assert.IsFalse(R.Read, 'past the end');
    finally
      R.Free;
    end;
  finally
    Doc.Free;
  end;
  var R := Reader('<r/>');
  try
    Assert.IsFalse(R.IsWalker);
  finally
    R.Free;
  end;
end;

procedure TXmlTextReaderHelperTest.TestNoExternalEntities;
begin
  var FileName := TPath.Combine(TPath.GetTempPath, 'lx2-reader-xxe.txt');
  TFile.WriteAllText(FileName, 'SECRET');
  try
    var Xml := UTF8String('<!DOCTYPE r [<!ENTITY x SYSTEM "file:///' + FileName.Replace('\', '/') + '">]><r>[&x;]</r>');
    var R := Reader(Xml, [xmlParseSubstituteEntity, xmlParseExternalDTD, xmlParseDTDAttrs]);
    try
      var Text := '';
      while R.Read do
        if R.NodeType = XML_READER_TYPE_TEXT then
          Text := Text + UTF8ToString(R.Value);
      Assert.IsFalse(Text.Contains('SECRET'), 'an external entity is never loaded');
    finally
      R.Free;
    end;
  finally
    TFile.Delete(FileName);
  end;
end;

procedure TXmlTextReaderHelperTest.TestSchemaValidation;
const
  Xsd: UTF8String = '<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema"><xs:element name="r"><xs:complexType>' +
    '<xs:sequence><xs:element name="n" type="xs:int" maxOccurs="unbounded"/></xs:sequence></xs:complexType>' +
    '</xs:element></xs:schema>';
begin
  var Ctxt := xmlSchemaNewMemParserCtxt(Pointer(Xsd), Length(Xsd));
  var Schema := xmlSchemaParse(Ctxt);
  xmlSchemaFreeParserCtxt(Ctxt);
  Assert.IsNotNull(Schema);
  var Probe := THandlerProbe.Create;
  try
    var R := Reader('<r><n>1</n><n>2</n></r>');
    try
      Assert.IsTrue(R.SetSchema(Schema));
      while R.Read do
        ;
      Assert.IsTrue(R.IsValid);
    finally
      R.Free;
    end;

    R := xmlTextReader.Create(RawByteString(UTF8String('<r><n>x</n><n>2</n></r>')), [], Probe.Counting);
    try
      Assert.IsTrue(R.SetSchema(Schema));
      var Count := 0;
      while R.Read do
        Inc(Count);
      Assert.IsFalse(R.IsValid);
      Assert.IsTrue(Probe.Calls > 0, 'the error went to the handler');
      Assert.AreEqual(8, Count, 'a validation error does not stop the reading');
      Assert.IsFalse(R.SetSchema(Schema), 'only before the first Read');
    finally
      R.Free;
    end;
  finally
    Probe.Free;
    xmlSchemaFree(Schema);
  end;
end;

procedure TXmlTextReaderHelperTest.TestNoLeaks;
begin
  {$IFNDEF DEBUG}
  Assert.Pass('xmlMemUsed accounts only for the debug allocator of a debug build');
  {$ENDIF}
  // The last error of the thread keeps its message, of a size of its own
  xmlResetLastError;
  var Used := xmlMemUsed;
  for var I := 1 to 3 do
  begin
    var Doc := xmlDoc.Create;
    var R := Reader(BasicXml);
    try
      R.ReadToFollowing(R.Atom('b'));
      xmlFreeNode(R.ReadNode(Doc));
      R.ReadToFollowing(R.Atom('e'));
      R.ReadElementContent;
      R.Text;
      R.OuterXml;
    finally
      R.Free;
      Doc.Free;
    end;
    R := Reader('<r><a>1</a><b>2</b><c>3</d></r>');
    try
      try
        while R.Read do
          ;
      except
        on EXmlParserError do
          ;
      end;
    finally
      R.Free;
    end;
  end;
  xmlResetLastError;
  Assert.AreEqual<NativeUInt>(Used, xmlMemUsed, 'libxml2 memory');
end;

{ TXmlReaderTest }

/// <summary>Depth:type:name of every node, '/' after an empty element.</summary>
function TraceReader(const R: IXmlReader): string;
var
  SB: TStringBuilder;
begin
  SB := TStringBuilder.Create;
  try
    while R.Read do
    begin
      if SB.Length > 0 then
        SB.Append(' ');
      SB.Append(R.Depth).Append(':').Append(Ord(R.NodeType)).Append(':').Append(R.Name);
      if R.IsEmptyElement then
        SB.Append('/');
    end;
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

const
  DtdXml = '<!DOCTYPE r [<!ENTITY e "ent"><!ATTLIST r d CDATA "dflt">]><r>&e;</r>';
  Minified = '<r><i>1</i><i>2</i><i>3</i><i>4</i></r>';

type
  TFlagStream = class(TStringStream)
  public
    Freed: PBoolean;
    destructor Destroy; override;
  end;

destructor TFlagStream.Destroy;
begin
  Freed^ := True;
  inherited;
end;

procedure TXmlReaderTest.Setup;
begin
  LX2Lib.Initialize;
end;

procedure TXmlReaderTest.TestWhitespaceKinds;
begin
  var R := XmlReader.CreateFromString(RawByteString(BasicXml));
  // Whitespace (13) outside xml:space="preserve", significant whitespace (14) inside it
  Assert.AreEqual('0:8:#comment 0:1:r 1:13:#text 1:1:a/ 1:13:#text 1:1:b 2:3:#text 2:8:#comment ' +
    '2:7:pi 2:4:#cdata-section 1:15:b 1:13:#text 1:1:c 2:14:#text 1:15:c 1:13:#text 1:1:p:e ' +
    '2:3:#text 1:15:p:e 1:13:#text 0:15:r', TraceReader(R));
  Assert.IsTrue(R.EOF);
  Assert.AreEqual(Ord(TXmlReadState.EndOfFile), Ord(R.ReadState));
  Assert.IsFalse(R.Read, 'past the end');
end;

procedure TXmlReaderTest.TestIgnoreSettings;
var
  Settings: TXmlReaderSettings;
begin
  Settings.IgnoreWhitespace := True;
  Settings.IgnoreComments := True;
  Settings.IgnoreProcessingInstructions := True;
  var R := XmlReader.CreateFromString(RawByteString(BasicXml), Settings);
  Assert.AreEqual('0:1:r 1:1:a/ 1:1:b 2:3:#text 2:4:#cdata-section 1:15:b 1:1:c 2:14:#text 1:15:c ' +
    '1:1:p:e 2:3:#text 1:15:p:e 0:15:r', TraceReader(R), 'preserved whitespace stays');
end;

procedure TXmlReaderTest.TestDtdProcessing;
var
  Settings: TXmlReaderSettings;
begin
  var R := XmlReader.CreateFromString(DtdXml);
  Assert.WillRaise(procedure begin R.Read end, EXmlReaderError, 'a DOCTYPE is prohibited by default');
  Assert.AreEqual(Ord(TXmlReadState.Error), Ord(R.ReadState));
  Assert.IsFalse(R.Read);

  Settings.DtdProcessing := TXmlDtdProcessing.Ignore;
  R := XmlReader.CreateFromString(DtdXml, Settings);
  Assert.AreEqual('0:1:r 1:5:e 0:15:r', TraceReader(R), 'no DOCTYPE node, the reference unexpanded');
  R := XmlReader.CreateFromString(DtdXml, Settings);
  Assert.IsTrue(R.ReadToFollowing('r'));
  Assert.AreEqual('', R.GetAttribute('d'), 'no attribute defaults');

  Settings.DtdProcessing := TXmlDtdProcessing.Parse;
  R := XmlReader.CreateFromString(DtdXml, Settings);
  Assert.AreEqual('0:10:r 0:1:r 1:3:#text 0:15:r', TraceReader(R));
  R := XmlReader.CreateFromString(DtdXml, Settings);
  Assert.IsTrue(R.ReadToFollowing('r'));
  Assert.AreEqual('dflt', R.GetAttribute('d'));
  Assert.AreEqual('ent', R.ReadElementContentAsString);
end;

procedure TXmlReaderTest.TestDoubleAdvanceTrap;
var
  Sum: Integer;
begin
  // The trap: ReadElementContentAs* is past the record already, and the Read of the loop
  // passes over the next one
  var R := XmlReader.CreateFromString(Minified);
  Sum := 0;
  while R.Read do
    if (R.NodeType = TXmlNodeType.Element) and (R.LocalName = 'i') then
      Inc(Sum, R.ReadElementContentAsInteger);
  Assert.AreEqual(1 + 3, Sum, 'every second record is lost on minified XML');

  // The loop that moves only when nothing else did
  R := XmlReader.CreateFromString(Minified);
  Sum := 0;
  R.MoveToContent;
  while not R.EOF do
    if R.IsStartElement('i') then
      Inc(Sum, R.ReadElementContentAsInteger)
    else
      R.Read;
  Assert.AreEqual(10, Sum);
end;

procedure TXmlReaderTest.TestElements;
var
  Sum, Count: Integer;
  Settings: TXmlReaderSettings;
begin
  var R := XmlReader.CreateFromString(Minified);
  Sum := 0;
  for var Rec in R.Elements('i') do
  begin
    Assert.AreEqual(0, Rec.Depth, 'a record reader counts from its element');
    Inc(Sum, Rec.ReadElementContentAsInteger);
  end;
  Assert.AreEqual(10, Sum, 'the body reads the record');

  R := XmlReader.CreateFromString(Minified);
  Count := 0;
  for var Rec in R.Elements('i') do
    Inc(Count);
  Assert.AreEqual(4, Count, 'the body leaves the record alone');

  R := XmlReader.CreateFromString(Minified);
  Count := 0;
  for var Rec in R.Elements('i') do
  begin
    Rec.Read;
    Inc(Count);
  end;
  Assert.AreEqual(4, Count, 'the body reads part of the record');

  Settings.IgnoreWhitespace := True;
  R := XmlReader.CreateFromString('<r>'#10'  <i>1</i>'#10'  <i>2</i>'#10'</r>', Settings);
  Sum := 0;
  for var Rec in R.Elements('i') do
    Inc(Sum, Rec.ReadElementContentAsInteger);
  Assert.AreEqual(3, Sum, 'without the whitespace between the records');
  Assert.IsFalse(R.Read, 'the outer reader is at the end');
end;

procedure TXmlReaderTest.TestElementsEmptyAndNested;
var
  Names: string;
begin
  var R := XmlReader.CreateFromString('<r><i a="1"/><i a="2"/><i a="3">x</i></r>');
  Names := '';
  for var Rec in R.Elements('i') do
    Names := Names + Rec.GetAttribute('a');
  Assert.AreEqual('123', Names, 'empty records too');

  R := XmlReader.CreateFromString('<r><i a="1"><i a="inner"/></i><i a="2"/></r>');
  Names := '';
  for var Rec in R.Elements('i') do
    Names := Names + Rec.GetAttribute('a') + ' ';
  Assert.AreEqual('1 2 ', Names, 'an element of the same name inside a record is not a record');

  R := XmlReader.CreateFromString('<r xmlns:p="urn:p"><i/><p:i/><q:i xmlns:q="urn:p"/></r>');
  var Count := 0;
  for var Rec in R.Elements('i', 'urn:p') do
    Inc(Count);
  Assert.AreEqual(2, Count, 'by namespace, whatever the prefix');
end;

procedure TXmlReaderTest.TestReadElements;
var
  Texts: string;
begin
  var R := XmlReader.CreateFromString(Minified);
  Texts := '';
  for var El in R.ReadElements('i') do
  begin
    Assert.AreEqual('i', El.NodeName);
    Assert.IsNotNull(El.OwnerDocument, 'a copy lives in a document of its own');
    Texts := Texts + El.Text;
  end;
  Assert.AreEqual('1234', Texts, 'every record of minified XML');
end;

procedure TXmlReaderTest.TestSubtree;
begin
  var R := XmlReader.CreateFromString('<r><a x="1"><b>t</b><c/></a><d/></r>');
  Assert.IsTrue(R.ReadToFollowing('a'));
  var S := R.ReadSubtree;
  Assert.AreEqual(Ord(TXmlReadState.Initial), Ord(S.ReadState));
  Assert.AreEqual(Ord(TXmlNodeType.None), Ord(S.NodeType));
  Assert.AreEqual('0:1:a 1:1:b 2:3:#text 1:15:b 1:1:c/ 0:15:a', TraceReader(S));
  Assert.IsTrue(S.EOF);
  Assert.AreEqual(Ord(TXmlNodeType.EndElement), Ord(R.NodeType), 'the outer reader is on the end tag');
  S.Close;
  Assert.AreEqual('a', R.Name);
  Assert.IsTrue(R.Read);
  Assert.AreEqual('d', R.Name);

  // Closed without reading: the outer reader goes to the end tag, not past it
  R := XmlReader.CreateFromString('<r><a><b/></a><d/></r>');
  R.ReadToFollowing('a');
  R.ReadSubtree.Close;
  Assert.AreEqual(Ord(TXmlNodeType.EndElement), Ord(R.NodeType));
  Assert.AreEqual('a', R.Name);

  // An empty element: the outer reader stays on it
  R := XmlReader.CreateFromString('<r><d/><e/></r>');
  R.ReadToFollowing('d');
  S := R.ReadSubtree;
  Assert.IsTrue(S.Read);
  Assert.IsTrue(S.IsEmptyElement);
  Assert.IsFalse(S.Read);
  Assert.AreEqual('d', R.Name);

  // Skip on the element of the subtree ends it without moving the outer reader past it
  R := XmlReader.CreateFromString('<r><a><b/></a><d/></r>');
  R.ReadToFollowing('a');
  S := R.ReadSubtree;
  S.Read;
  S.Skip;
  Assert.IsTrue(S.EOF);
  Assert.AreEqual(Ord(TXmlNodeType.EndElement), Ord(R.NodeType));

  Assert.IsTrue(R.Read);
  Assert.AreEqual('d', R.Name);
  Assert.IsTrue(R.Read);
  Assert.AreEqual(Ord(TXmlNodeType.EndElement), Ord(R.NodeType));
  Assert.WillRaise(procedure begin R.ReadSubtree end, EXmlReaderError, 'only on an element');
end;

procedure TXmlReaderTest.TestReadToNamespaces;
begin
  var R := XmlReader.CreateFromString('<r xmlns:p="urn:p"><p:a n="1"/><a n="2"/><x:a xmlns:x="urn:p" n="3"/></r>');
  Assert.IsTrue(R.ReadToFollowing('a', ''));
  Assert.AreEqual('2', R.GetAttribute('n'), 'an empty namespace is no namespace');
  R := XmlReader.CreateFromString('<r xmlns:p="urn:p"><p:a n="1"/><a n="2"/><x:a xmlns:x="urn:p" n="3"/></r>');
  Assert.IsTrue(R.ReadToFollowing('a', 'urn:p'));
  Assert.AreEqual('1', R.GetAttribute('n'));
  Assert.IsTrue(R.ReadToFollowing('a', 'urn:p'));
  Assert.AreEqual('3', R.GetAttribute('n'), 'another prefix, the same namespace');
  R := XmlReader.CreateFromString('<r xmlns:p="urn:p"><p:a n="1"/><a n="2"/></r>');
  Assert.IsTrue(R.ReadToFollowing('a'));
  Assert.AreEqual('1', R.GetAttribute('n'), 'a name alone in any namespace');
  Assert.IsTrue(R.ReadToFollowing('a'));
  Assert.AreEqual('2', R.GetAttribute('n'));
  R := XmlReader.CreateFromString('<r><a><x/><b/></a><b/></r>');
  R.ReadToFollowing('a');
  Assert.IsTrue(R.ReadToDescendant('b'));
  Assert.AreEqual(2, R.Depth);
  Assert.IsFalse(R.ReadToNextSibling('q'));
  Assert.AreEqual(Ord(TXmlNodeType.EndElement), Ord(R.NodeType));
  Assert.AreEqual('a', R.Name, 'on the end tag of the parent');
  Assert.IsTrue(R.ReadToNextSibling('b'));
  Assert.AreEqual(1, R.Depth);
end;

procedure TXmlReaderTest.TestTypedContent;
var
  Saved: TFormatSettings;
begin
  var R := XmlReader.CreateFromString('<r><i> 42 </i><d>1.5</d><c>12.50</c><b>true</b>' +
    '<t>2026-10-13T09:05:07+03:00</t><s>a<!--c-->b</s><bad>x</bad></r>');
  Assert.IsTrue(R.ReadToFollowing('i'));
  Assert.AreEqual(42, R.ReadElementContentAsInteger);
  Assert.AreEqual('d', R.Name, 'on the next element at once');
  Saved := FormatSettings;
  try
    FormatSettings.DecimalSeparator := ',';
    Assert.AreEqual(1.5, R.ReadElementContentAsDouble, 0, 'the locale does not matter');
  finally
    FormatSettings := Saved;
  end;
  Assert.AreEqual<Currency>(12.5, R.ReadElementContentAsCurrency);
  Assert.IsTrue(R.ReadElementContentAsBoolean);
  Assert.AreEqual(EncodeDate(2026, 10, 13) + EncodeTime(9, 5, 7, 0), R.ReadElementContentAsDateTime, 0);
  Assert.AreEqual('ab', R.ReadElementContentAsString, 'comments are passed over');
  try
    R.ReadElementContentAsInteger;
    Assert.Fail('x is no integer');
  except
    on E: EXmlReaderError do
    begin
      Assert.Contains(E.Message, '"x"');
      Assert.Contains(E.Message, 'bad');
      Assert.AreEqual(1, E.Line);
    end;
  end;
  R := XmlReader.CreateFromString('<r><m>a<x/></m></r>');
  R.ReadToFollowing('m');
  Assert.WillRaise(procedure begin R.ReadElementContentAsString end, EXmlReaderError, 'a child element');
  R := XmlReader.CreateFromString('<r><m><x/></m></r>');
  R.ReadToFollowing('m');
  Assert.WillRaise(procedure begin R.ReadElementContentAsString end, EXmlReaderError, 'a child element first');
  R := XmlReader.CreateFromString('<r><e/><f></f><g/></r>');
  R.ReadToFollowing('e');
  Assert.AreEqual('', R.ReadElementContentAsString);
  Assert.AreEqual('', R.ReadElementContentAsString);
  Assert.AreEqual('g', R.Name);
end;

procedure TXmlReaderTest.TestStartEndElement;
begin
  var R := XmlReader.CreateFromString('<r>'#10'  <a>t</a>'#10'</r>');
  R.ReadStartElement('r');
  R.ReadStartElement('a');
  Assert.AreEqual('t', R.ReadContentAsString);
  R.ReadEndElement;
  R.ReadEndElement;
  Assert.IsTrue(R.EOF);
  R := XmlReader.CreateFromString('<r><a/></r>');
  Assert.WillRaise(procedure begin R.ReadStartElement('x') end, EXmlReaderError);
  R := XmlReader.CreateFromString('<r><a/></r>');
  R.ReadStartElement;
  Assert.WillRaise(procedure begin R.ReadEndElement end, EXmlReaderError, 'on <a/>, not on an end tag');
end;

procedure TXmlReaderTest.TestInnerOuterXml;
begin
  var R := XmlReader.CreateFromString('<r><a k="v&amp;w">x<b>y</b></a><n/><m>q</m></r>');
  R.ReadToFollowing('a');
  Assert.IsTrue(R.MoveToFirstAttribute);
  Assert.AreEqual('k="v&amp;w"', R.ReadOuterXml);
  Assert.AreEqual('v&w', R.ReadInnerXml);
  Assert.AreEqual(Ord(TXmlNodeType.Attribute), Ord(R.NodeType), 'still on the attribute');
  R.MoveToElement;
  Assert.AreEqual('<a k="v&amp;w">x<b>y</b></a>', R.ReadOuterXml);
  Assert.AreEqual('n', R.Name, 'past the element');
  R.ReadToFollowing('m');
  Assert.AreEqual('q', R.ReadInnerXml);
  Assert.AreEqual(Ord(TXmlNodeType.EndElement), Ord(R.NodeType));
  Assert.AreEqual('r', R.Name);
end;

procedure TXmlReaderTest.TestReadElementCopy;
begin
  var R := XmlReader.CreateFromString('<r xmlns:p="urn:p" xmlns:t="urn:t">' +
    '<p:a type="t:Code"><p:b>text</p:b></p:a><after/><p:a>2</p:a></r>');
  R.ReadToFollowing('a');
  var El := R.ReadElement;
  Assert.AreEqual('after', R.Name, 'past the element');
  Assert.AreEqual('urn:p', El.NamespaceURI);
  Assert.Contains(El.Xml, 'xmlns:t="urn:t"', 'a prefix used in a value');
  Assert.AreEqual('text', El.Text);
  Assert.IsTrue(El.OwnerDocument.DocumentElement = El, 'the root of a document of its own');

  var Doc := CoCreateXMLDocument;
  Doc.CreateRoot('list');
  R.ReadToFollowing('a');
  var Item := R.ReadElement(Doc);
  Assert.IsNull(Item.ParentNode, 'out of the tree');
  Doc.DocumentElement.AppendChild(Item);
  Assert.AreEqual('<list><p:a xmlns:p="urn:p" xmlns:t="urn:t">2</p:a></list>', Doc.DocumentElement.Xml);
end;

type
  TNodeAccess = class(TXMLNode);

procedure TXmlReaderTest.TestExpand;
var
  Kept: IXMLElement;
begin
  var R := XmlReader.CreateFromString('<r xmlns:p="urn:p"><p:i n="1"><v>a</v></p:i><p:i n="2"><v>b</v></p:i></r>');
  var Values := '';
  for var Rec in R.Elements('i', 'urn:p') do
  begin
    var El := Rec.Expand;
    Assert.AreEqual('p:i', El.NodeName);
    Assert.AreEqual(0, Rec.Depth, 'Expand does not move the reader');
    Values := Values + El.GetAttribute('n') + El.SelectSingleNode('v').Text;
    Assert.IsNull(El.OwnerDocument, 'the tree of a reader has no document object');
    Assert.AreEqual('r', El.ParentNode.NodeName, 'the elements the reader has open');
    Assert.IsNull(El.ParentNode.ParentNode, 'the document of the reader is not wrapped');
    Kept := El;
  end;
  Assert.AreEqual('1a2b', Values);
  // The reader has freed the nodes of the record: the wrapper lost its node instead of
  // reading another one
  Assert.IsNull(TNodeAccess(TObject(Kept)).NodePtr);
  Kept := nil;

  R := XmlReader.CreateFromString('<r><a/>text</r>');
  R.Read;
  R.Read;
  R.Read;
  Assert.WillRaise(procedure begin R.Expand end, EXmlReaderError, 'only on an element');
end;

procedure TXmlReaderTest.TestInPlaceInput;
var
  Text: RawByteString;
  Bytes: TBytes;
begin
  // A string on the heap, not a literal that lives as long as the program
  SetString(Text, PAnsiChar('<r><a>1</a></r>'), 15);
  var R := XmlReader.CreateFromString(Text);
  Text := '';
  Assert.IsTrue(R.ReadToFollowing('a'), 'the reader keeps the text it parses in place');
  Assert.AreEqual('1', R.ReadElementContentAsString);

  Bytes := TEncoding.UTF8.GetBytes('<r><a>2</a></r>');
  R := XmlReader.Create(Bytes);
  Bytes := nil;
  Assert.IsTrue(R.ReadToFollowing('a'));
  Assert.AreEqual('2', R.ReadElementContentAsString);
end;

procedure TXmlReaderTest.TestAttributesFromAttribute;
var
  V: string;
begin
  var R := XmlReader.CreateFromString('<r xmlns:p="urn:p" a="1" p:b="2"/>');
  Assert.IsTrue(R.Read);
  Assert.AreEqual(3, R.AttributeCount);
  Assert.IsTrue(R.MoveToAttribute('a'));
  Assert.AreEqual(3, R.AttributeCount, 'counted on the element, as in .NET');
  Assert.AreEqual('2', R.GetAttribute('p:b'), 'read from the element');
  Assert.AreEqual('2', R.GetAttribute('b', 'urn:p'));
  Assert.AreEqual('a', R.Name, 'and the reader is back on the attribute');
  Assert.AreEqual('urn:p', R.GetAttribute(0), 'declarations first');
  Assert.AreEqual('a', R.Name);
  Assert.IsTrue(R.MoveToNextAttribute);
  Assert.AreEqual('p:b', R.Name);
  Assert.IsFalse(R.MoveToNextAttribute);
  R.MoveToAttribute(0);
  Assert.IsTrue(R.IsNamespaceDeclaration);
  Assert.AreEqual('p', R.LocalName);
  Assert.AreEqual('xmlns', R.Prefix);
  Assert.IsTrue(R.MoveToElement);
  Assert.AreEqual('r', R.Name);
  Assert.IsFalse(R.TryGetAttribute('zz', V));
  Assert.IsTrue(R.TryGetAttribute('a', V));
  Assert.AreEqual('1', V);
  Assert.AreEqual('urn:p', R.LookupNamespace('p'));
  Assert.WillRaise(procedure begin R.GetAttribute(3) end, EArgumentOutOfRangeException);
  Assert.WillRaise(procedure begin R.MoveToAttribute(-1) end, EArgumentOutOfRangeException);
  Assert.IsTrue(R.MoveToAttribute('b', 'urn:p'));
  Assert.IsTrue(R.ReadAttributeValue);
  Assert.AreEqual(Ord(TXmlNodeType.Text), Ord(R.NodeType));
  Assert.AreEqual('2', R.Value);
end;

procedure TXmlReaderTest.TestBase64;
begin
  var Data := TBytesStream.Create;
  try
    var R := XmlReader.CreateFromString('<r><bin>SGVs'#10'bG8s<!--c-->IHdv<![CDATA[cmxk]]>IQ==</bin><x/><e/><bad>S!</bad></r>');
    R.ReadToFollowing('bin');
    Assert.AreEqual<Int64>(13, R.ReadElementContentAsBase64(Data));
    Assert.AreEqual('Hello, world!', TEncoding.ASCII.GetString(Data.Bytes, 0, Data.Size));
    Assert.AreEqual('x', R.Name, 'past the element');
    R.ReadToFollowing('e');
    Assert.AreEqual<Int64>(0, R.ReadElementContentAsBase64(Data));
    Assert.WillRaise(procedure begin R.ReadElementContentAsBase64(Data) end, EXmlReaderError);
    for var Bad in ['<r>QQ===</r>', '<r>QQ==QQ==</r>', '<r>QQ</r>', '<r>Q===</r>'] do
    begin
      R := XmlReader.CreateFromString(Bad);
      R.Read;
      Assert.WillRaise(procedure begin R.ReadElementContentAsBase64(Data) end, EXmlReaderError, Bad);
    end;
    Data.Clear;
    R := XmlReader.CreateFromString('<r>QUJD QQ==</r>');
    R.Read;
    Assert.AreEqual<Int64>(4, R.ReadElementContentAsBase64(Data));
    Assert.AreEqual('ABCA', TEncoding.ASCII.GetString(Data.Bytes, 0, Data.Size));
  finally
    Data.Free;
  end;
end;

procedure TXmlReaderTest.TestErrors;
begin
  var R := XmlReader.CreateFromString('<r><a>1</a><b>2</b><c>3</d></r>');
  Assert.WillRaise(procedure begin
    while R.Read do
      ;
  end, EXmlParserError);
  Assert.AreEqual(Ord(TXmlReadState.Error), Ord(R.ReadState));
  Assert.IsFalse(R.Read);

  // An undeclared prefix is reported and the reading goes on
  R := XmlReader.CreateFromString('<r><p:a/><b/></r>');
  Assert.IsTrue(R.ReadToFollowing('b'));
  Assert.IsTrue(R.Errors.Count > 0);
  Assert.IsTrue(R.IsValid, 'no validation, nothing invalid');

  Assert.WillRaise(procedure begin XmlReader.CreateFromFile(TPath.Combine(TPath.GetTempPath, 'no-such-lx2.xml')) end,
    EFOpenError);
end;

procedure TXmlReaderTest.TestValidation;
const
  Xsd = '<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema"><xs:element name="r"><xs:complexType>' +
    '<xs:sequence><xs:element name="n" type="xs:int" maxOccurs="unbounded"/></xs:sequence></xs:complexType>' +
    '</xs:element></xs:schema>';
var
  Settings: TXmlReaderSettings;
  Reported: Integer;
begin
  var SchemaDoc := CoCreateXMLDocument;
  Assert.IsTrue(SchemaDoc.LoadXML(Xsd));
  Settings.Schemas := CoCreateSchemaCollection;
  Settings.Schemas.Add('', SchemaDoc);

  var R := XmlReader.CreateFromString('<r><n>1</n><n>2</n></r>', Settings);
  TraceReader(R);
  Assert.IsTrue(R.IsValid);

  R := XmlReader.CreateFromString('<r><n>x</n><n>2</n></r>', Settings);
  Assert.WillRaise(procedure begin
    while R.Read do
      ;
  end, EXmlParserError, 'the first validation error raises without a handler');
  Assert.IsFalse(R.IsValid);
  Assert.AreNotEqual(Ord(TXmlReadState.Error), Ord(R.ReadState), 'the reader goes on');
  while R.Read do
    ;
  Assert.IsTrue(R.EOF);

  Reported := 0;
  Settings.OnValidationError := procedure(const Error: TXmlParseError)
    begin
      Inc(Reported);
    end;
  R := XmlReader.CreateFromString('<r><n>x</n><n>y</n></r>', Settings);
  TraceReader(R);
  Assert.IsTrue(R.EOF);
  Assert.IsFalse(R.IsValid);
  Assert.IsTrue(Reported >= 2, 'every error goes to the handler');
end;

procedure TXmlReaderTest.TestWalker;
var
  Settings: TXmlReaderSettings;
begin
  var Doc := CoCreateXMLDocument;
  Assert.IsTrue(Doc.LoadXML('<r xmlns:p="urn:p"><p:i>1</p:i><p:i>2</p:i></r>'));
  var R := XmlReader.Create(Doc);
  var Sum := 0;
  for var Rec in R.Elements('i', 'urn:p') do
    Inc(Sum, Rec.ReadElementContentAsInteger);
  Assert.AreEqual(3, Sum, 'names of a loaded document are compared by text');
  Assert.IsFalse(R.Read);

  // Skip and ReadToNextSibling stop where the streaming reader stops: on the end tag of the
  // parent, not on an element one level up (xmlTextReaderNext over a tree would go there)
  Assert.IsTrue(Doc.LoadXML('<r><a><x/><b/></a><b/></r>'));
  R := XmlReader.Create(Doc);
  R.ReadToFollowing('a');
  Assert.IsTrue(R.ReadToDescendant('b'));
  Assert.AreEqual(2, R.Depth);
  Assert.IsFalse(R.ReadToNextSibling('q'), 'no sibling of the last child');
  Assert.AreEqual(Ord(TXmlNodeType.EndElement), Ord(R.NodeType));
  Assert.AreEqual('a', R.Name, 'on the end tag of the parent');
  Assert.IsTrue(R.ReadToNextSibling('b'));
  Assert.AreEqual(1, R.Depth);
  R := XmlReader.Create(Doc);
  R.ReadToFollowing('a');
  Assert.IsTrue(R.ReadToDescendant('b'));
  R.Skip;
  Assert.AreEqual(Ord(TXmlNodeType.EndElement), Ord(R.NodeType), 'Skip on the last child');
  Assert.AreEqual('a', R.Name);
  R := XmlReader.Create(Doc);
  R.ReadToFollowing('a');
  R.Skip;
  Assert.AreEqual('b', R.Name, 'Skip over a subtree lands on the next sibling');
  Assert.AreEqual(1, R.Depth);

  Settings.Schemas := CoCreateSchemaCollection;
  Assert.WillRaise(procedure begin XmlReader.Create(Doc, Settings) end, EXmlReaderError, 'no validation over a document');
end;

procedure TXmlReaderTest.TestFileAndStream;
var
  Settings: TXmlReaderSettings;
  Freed: Boolean;
begin
  var Dir := TPath.Combine(TPath.GetTempPath, 'lx2-ридер');
  TDirectory.CreateDirectory(Dir);
  var FileName := TPath.Combine(Dir, 'данные.xml');
  TFile.WriteAllText(FileName, '<?xml version="1.0" encoding="windows-1251"?><r>Привет</r>', TEncoding.GetEncoding(1251));
  try
    var R := XmlReader.CreateFromFile(FileName);
    Assert.IsTrue(R.ReadToFollowing('r'));
    Assert.AreEqual('Привет', R.ReadElementContentAsString, 'a Cyrillic path and windows-1251 content');
  finally
    TDirectory.Delete(Dir, True);
  end;

  Freed := False;
  var S := TFlagStream.Create('<r>1</r>', TEncoding.UTF8);
  S.Freed := @Freed;
  Settings.CloseInput := True;
  var R := XmlReader.Create(S, Settings);
  Assert.IsTrue(R.ReadToFollowing('r'));
  R.Close;
  Assert.IsTrue(Freed, 'CloseInput frees the stream');

  Freed := False;
  S := TFlagStream.Create('<r>1</r>', TEncoding.UTF8);
  S.Freed := @Freed;
  try
    R := XmlReader.Create(S);
    R.ReadToFollowing('r');
    R := nil;
    Assert.IsFalse(Freed, 'without CloseInput the stream is the caller''s');
  finally
    S.Free;
  end;
end;

procedure TXmlReaderTest.TestLateBinding;
begin
  var R: Variant := XmlReader.CreateFromString('<r><a k="v">7</a></r>') as IDispatch;
  Assert.IsTrue(Boolean(R.ReadToFollowing('a')));
  Assert.AreEqual('v', string(R.GetAttribute('k')));
  Assert.AreEqual(7, Integer(R.ReadElementContentAsInteger));
  Assert.AreEqual('r', string(R.Name));
end;

// The interfaces a routine gets as results live in hidden locals until it returns: the work
// is a routine of its own, so that nothing of it is left when the memory is measured.
procedure ReaderWork;
begin
  var R := XmlReader.CreateFromString(RawByteString(BasicXml));
  for var Rec in R.Elements('b') do
    Rec.ReadElement;
  R := XmlReader.CreateFromString(Minified);
  for var El in R.ReadElements('i') do
    El.Text;
  R := XmlReader.CreateFromString('<r><a>1</a><b>2</b><c>3</d></r>');
  try
    while R.Read do
      ;
  except
    on EXmlParserError do
      ;
  end;
  var Doc := CoCreateXMLDocument;
  Doc.LoadXML('<r><i>1</i><i>2</i></r>');
  R := XmlReader.Create(Doc);
  for var Rec in R.Elements('i') do
    Rec.ReadOuterXml;
end;

procedure TXmlReaderTest.TestNoLeaks;
begin
  {$IFNDEF DEBUG}
  Assert.Pass('xmlMemUsed and DebugObjectCount count only in a debug build');
  {$ENDIF}
  xmlResetLastError;
  var Used := xmlMemUsed;
  var Objects := DebugObjectCount;
  for var I := 1 to 3 do
    ReaderWork;
  xmlResetLastError;
  Assert.AreEqual<NativeUInt>(Used, xmlMemUsed, 'libxml2 memory');
  Assert.AreEqual<NativeInt>(Objects, DebugObjectCount, 'DOM wrappers');
end;

initialization
  TDUnitX.RegisterTestFixture(TXmlConvertTest);
  TDUnitX.RegisterTestFixture(TXmlTextReaderHelperTest);
  TDUnitX.RegisterTestFixture(TXmlReaderTest);

end.
