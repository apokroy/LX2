# LX2

Delphi bindings for [libxml2](https://gitlab.gnome.org/GNOME/libxml2) and
[libxslt](https://gitlab.gnome.org/GNOME/libxslt/), from the raw C API up to an MSXML-style
DOM. The goal of the project is a cross-platform replacement for MSXML 6.0: where possible
the library follows the W3C DOM model, and where the two disagree, MSXML compatibility wins.

MIT licensed. libxml2 and libxslt keep their own MIT-style licences (`LIBXML2.COPYRIGHT`,
`LIBXSLT.COPYRIGHT`).

> The libraries ship with the repository already compiled: COFF objects for Windows x64
> (`Native\Lib\Win64`) and static archives for Linux64 and Windows on ARM
> (`Native\Lib\Linux64`, `Native\Lib\WinARM64EC`). The `LX2.Static` unit links them into your
> executable, so `libxml2.dll`, `libxslt.dll` and their `.so` counterparts are not required
> and not deployed. You need nothing but Delphi to build: the C compiler is used only to
> update the libraries. See [Static linking](#static-linking).
>
> Late binding to a shared library is still available: leave `LX2.Static` out of the uses
> clause and `LX2Lib.Load` loads `libxml2.dll` / `libxml2.so.16`.

Bundled versions (sources and static builds): libxml2 2.15.4, libxslt 1.1.45.

## Contents

- [Layers](#layers)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Static linking](#static-linking)
- [Loading a shared library](#loading-a-shared-library)
- [Strings and encodings](#strings-and-encodings)
- [External entities and DTDs](#external-entities-and-dtds)
- [LX2.Types](#lx2types)
- [LX2.Helpers](#lx2helpers)
- [LX2.DOM](#lx2dom)
- [LX2.SAX](#lx2sax)
- [LX2.Reader](#lx2reader)
- [XPath](#xpath)
- [Error handling](#error-handling)
- [Updating libxml2 and libxslt](#updating-libxml2-and-libxslt)
- [Status](#status)

## Layers

The library is a stack; pick the level that fits the task.

| Unit | Layer | What it gives you |
|---|---|---|
| `libxml2.API`, `libxslt.API` | Raw C API | One-to-one declarations of the libxml2/libxslt types and functions. Function pointers, filled either from a shared library (`LX2Lib.Load`) or from the statically linked objects. |
| `LX2.Static` | Linking | Generated unit: `{$L}` of the objects, the C runtime imports and the binding of the API pointers. Add it to uses and no DLL is needed. On Linux64 and WinARM64EC it binds to the archive in `Native\Lib\<platform>` instead; empty on Win32. |
| `LX2.Types` | Common types | Delphi-style option sets (`TXmlParserOptions`, `TXmlSaveOptions`, `TXmlC14NMode`), parse error records and lists, exception classes, `XmlConvert` (the lexical forms of XML Schema types), fast UTF-8/UTF-16 conversion helpers used by every layer above. |
| `LX2.Helpers` | Record helpers | `xmlDoc`, `xmlNode`, `xmlAttr`, `xmlNamespaces` gain methods and properties: parse from string/file/stream, navigate, edit, XPath, XSLT, save with any encoding, canonicalize; `xmlTextReader` gains the pull reader. Zero overhead over the C API: the helpers work on the native pointers. |
| `LX2.SAX` | SAX | A thin wrapper over the libxml2 SAX2 parser (`TLX2SAXParserWrapper`), a Delphi-style parser with virtual `Do*` methods (`TSAXCustomParser`) and a handler-interface variant close to the MSXML SAX interfaces (`TSAXParser` + `ISAXContentHandler`). |
| `LX2.Reader` | Pull reader | `IXmlReader` after `System.Xml.XmlReader`: a forward-only cursor over the nodes, constant memory, records taken one at a time as readers of their subtrees or as small DOM documents. |
| `LX2.DOM`, `LX2.DOM.Classes` | DOM | Reference-counted interfaces `IXMLDocument`, `IXMLElement`, `IXMLNode`, `IXMLNodeList`, `IXMLAttributes`, `IXMLSchemaCollection` and the rest of the MSXML/W3C set, implemented over the libxml2 tree. |
| `LX2.XPATH` | XPath | A small engine for simple location paths that ignores namespaces the way MSXML does; everything else goes to the libxml2 XPath evaluator. |
| `RttiDispatch` | Late binding | `IDispatchInvokable`/`TDispatchInvokable`: the DOM and SAX interfaces can be invoked by name through RTTI, which keeps scripting scenarios of MSXML available without COM. |

## Requirements

- Delphi 10.3 Rio or later (the library relies on inline variables and record helpers with
  class methods); developed and tested with Delphi 13.2.
- Static linking: Windows x64, Linux64 and Windows on ARM (WinARM64EC, Delphi 13.1 or later;
  linked, not yet run on ARM hardware). A shared library: Windows x64 and Linux64.
- Win32 compiles but has not been tested.

## Installation

Either add `Source` to the library path, or open `Packages\LX2.dpk` and install it. The
package contains every unit including `LX2.Static`; on Win32 that unit is empty.

```delphi
uses
  LX2.Types, LX2.Helpers,   // record helpers over the C API
  LX2.DOM,                  // MSXML-style interfaces
  LX2.SAX,                  // SAX parser
  LX2.Reader,               // pull reader
  LX2.Static;               // static linking; omit it to load a shared library instead
```

Initialisation is implicit: the DOM, SAX and reader layers initialise `LX2Lib` (and `XSLTLib`
on the first transformation) themselves. Code that calls `libxml2.API` or the helpers directly
calls `LX2Lib.Initialize` once; it may be called from several threads at once.

## Quick start

Parse, query, edit and save with the record helpers:

```delphi
uses
  System.SysUtils, libxml2.API, LX2.Types, LX2.Helpers, LX2.Static;

begin
  LX2Lib.Initialize;

  var Doc := xmlDoc.Create('<catalog><book id="1"><title>Delphi</title></book></catalog>', DefaultParserOptions);
  if Doc = nil then
    raise Exception.Create('not well-formed');
  try
    var Title := Doc.documentElement.SelectSingleNode('/catalog/book/title');
    Writeln(UTF8ToString(Title.Text));                       // Delphi

    var Book := Doc.documentElement.FirstElementChild;
    Book.Attribute['year'] := '2026';
    Book.AddChild('note', 'first edition');

    Writeln(Doc.ToString('UTF-8', True));                     // formatted, as string
    Doc.Save('catalog.xml', 'windows-1251');                  // any encoding libxml2 knows
  finally
    Doc.Free;
  end;
end.
```

The same with the DOM interfaces:

```delphi
uses
  System.SysUtils, LX2.DOM, LX2.Static;

begin
  var Doc := CoCreateXMLDocument;
  if not Doc.LoadXML('<root><item id="1">first</item><item id="2">second</item></root>') then
  begin
    Writeln(Doc.ParseError.Reason, ' at line ', Doc.ParseError.Line);
    Exit;
  end;

  for var Node in Doc.SelectNodes('//item') do
    Writeln(Node.Attributes.GetNamedItem('id').NodeValue, ': ', Node.Text);

  var Item := Doc.CreateElement('item');
  Item.SetAttribute('id', 3);
  Item.Text := 'third';
  Doc.DocumentElement.AppendChild(Item);

  Writeln(Doc.ToString(True));
end.
```

A SAX handler that counts elements:

```delphi
uses
  System.SysUtils, LX2.Types, LX2.SAX, LX2.Static;

type
  TElementCounter = class(TSAXCustomContentHandler)
  public
    Count: Integer;
    procedure StartElement(const LocalName, Prefix, URI: string;
      const Namespaces: TSAXNamespaces; const Attributes: TSAXAttributes); override;
  end;

procedure TElementCounter.StartElement(const LocalName, Prefix, URI: string;
  const Namespaces: TSAXNamespaces; const Attributes: TSAXAttributes);
begin
  Inc(Count);
end;

begin
  var Counter := TElementCounter.Create;
  var Parser := TSAXParser.Create;
  try
    Parser.Handler := Counter;                      // the handler is reference counted
    if Parser.ParseFile('big.xml') then
      Writeln(Counter.Count, ' elements')
    else
      for var E in Parser.Errors do
        Writeln(E.Line, ':', E.Col, ' ', E.Text);
  finally
    Parser.Free;
  end;
end.
```

## Static linking

`Native\` holds the sources of libxml2 and libxslt (the library parts of the releases), the
objects built from them and the scripts that maintain both:

```
Native\Source\libxml2   libxml2 sources of the release, Copyright, VERSION
Native\Source\libxslt   libxslt sources of the release, Copyright, VERSION
Native\Source\shim      Win32 declarations, iconv, the printf family for the C runtime
Native\Lib\Win64        xml_*.o, xslt_*.o, shim_*.o — committed, consumers never compile C
Native\Lib\Linux64      liblx2native.a — the same for Linux64 (on the library path of the project)
Native\Lib\WinARM64EC   liblx2native.a — the same for Arm64EC (on the unit search path of the project)
Native\Import.ps1       downloads a release and refreshes Native\Source
Native\Build.ps1        compiles the objects, checks them, generates Source\LX2.Static.pas
Source\LX2.Static.pas   generated: {$L} per object, runtime imports, API binding
```

How it works on Windows x64: `bcc64x` (the clang shipped with RAD Studio) compiles the C sources into COFF
objects, `LX2.Static` links them with `{$L}`, and the C runtime the libraries need comes
from `ucrtbase.dll`, which is part of Windows 10 and later. Names that ucrtbase does not
export (the `printf` family) are provided by a small C shim, the Win32 API is declared by
hand, iconv is implemented on top of `MultiByteToWideChar`, so every Windows code page
libxml2 asks for is available. The unit is generated from the declarations in
`libxml2.API.pas` and `libxslt.API.pas`: when the API unit changes, `Build.ps1` regenerates
the binding. `Native\README.md` explains the mechanics, the feature set and the invariants
the build script enforces.

The compilers for Linux64 and WinARM64EC know no `{$L}`, so there the same sources are
compiled into one archive per platform, `liblx2native.a`, and `LX2.Static` declares the entry
points as `external 'liblx2native.a'`. On Linux64 the C runtime is glibc; the archive needs
glibc 2.33 or later (Ubuntu 22.04 has 2.35), and an application is linked against the SDK of
the oldest system it has to run on, because the symbol versions it asks for come from that SDK.
On WinARM64EC the C runtime is the `librtlhelper.a` that the Delphi compiler links into every
executable anyway.

What it means for an application:

- add `LX2.Static` to the uses clause of the project (or install the package, which
  contains it); `LX2Lib.Load` and `XSLTLib.Load` then bind to the objects and
  `LX2Lib.LibraryFileName` is empty;
- on Linux64 put `Native\Lib\Linux64` on the library path of the platform (`--libpath`); on
  WinARM64EC put `Native\Lib\WinARM64EC` on the unit search path, which is where the linker
  of that platform takes its library folders from;
- nothing to deploy next to the executable;
- the executable grows by about 2 MB;
- the Windows x64 objects are built for x86-64 with SSE2 as the baseline and `-O3`; they run
  on any 64-bit Windows 10 or later. The WinARM64EC build is linked and its smoke test
  compiled, but it has not yet run on ARM hardware.

Without `LX2.Static` in uses the behaviour is unchanged: the API unit loads a shared
library. Both modes can coexist in one code base, the choice is made per executable.

## Loading a shared library

Only for builds without `LX2.Static`. The default names are `libxml2.dll` / `libxslt.dll`
on Windows and `libxml2.so.16` / `libxslt.so` on Linux; LX2 requires libxml2 2.14 or
later, which is what the `.so.16` suffix stands for.

```delphi
LX2Lib.Initialize;                       // default name, once
LX2Lib.Load('C:\libs\libxml2.dll');      // or a specific file
XSLTLib.Initialize;                      // libxslt, on demand
LX2Lib.Unload;
```

`LX2Lib.IsLoaded` and `LX2Lib.LibraryFileName` report the state. Most Linux distributions
ship an older libxml2 with the `.so.2` soname, which LX2 cannot use, so a shared library has
to be deployed with the application. `Binaries\Linux64` holds an older build: development
snapshots of libxml2 2.15 and libxslt 1.1.44 made before those releases, built on Ubuntu 24.04,
so they need glibc 2.38, and without the local patches of `Native\Patches`. On Linux64 prefer
static linking, which takes the bundled versions.

## Strings and encodings

- The record helpers (`LX2.Helpers`) speak UTF-8: names, values and XML text are
  `RawByteString` with the UTF-8 code page, exactly what libxml2 stores. Convert with
  `UTF8ToString`/`UTF8Encode` at the boundary, or use the `string` overloads where they
  exist (`ToString`, `Transform`).
- The DOM interfaces (`LX2.DOM`) speak `string`; conversion happens inside.
- Output encoding is a parameter of `ToString`, `ToBytes`, `ToAnsi`, `Save`,
  `LoadFromStream`; any encoding known to libxml2 and to the Windows code page table works
  (`UTF-8`, `UTF-16`, `windows-1251`, `KOI8-R`, `ISO-8859-x`, ...).
- `TXmlParserOptions` mirrors `XML_PARSE_*` one to one; `DefaultParserOptions` enables
  entity substitution (of the entities the document declares, see below), DTD attribute
  defaults, big lines and huge documents.

## External entities and DTDs

LX2 never loads external entities or the external DTD subset, and no option turns loading
on. `XmlParserOptions` adds `XML_PARSE_NO_XXE` to every set, so `xmlParseNoXXE` is always
on and `xmlParseExternalDTD` reads nothing. Entities the document declares itself are still
expanded with `xmlParseSubstituteEntity`. Attribute defaults and validation
(`xmlParseDTDAttrs`, `xmlParseDTDValidation`) use the internal subset only. The same holds for
the DOM document (`ResolveExternals` is kept for MSXML compatibility and changes nothing),
the SAX parser, schema compilation, the documents XSLT loads (`xsl:import`, `xsl:include`,
`document()`) and DTD validation, which takes the external subset only from a
`ResourceLoader` the caller passes.

## LX2.Types

Everything the upper layers share:

- `TXmlParserOptions`, `TXmlSaveOptions`, `TXmlC14NMode`: Delphi sets and enums over the
  libxml2 flags, with `XmlParserOptions(...)` converting a set to the native bitmask;
- `TXmlParseError` (text, source, line, column, level) and `TXmlParseErrors`, a list with an
  enumerator, filled by the SAX parser and the DOM document;
- exceptions: `EXmlError` (base), `EXmlParserError`, `EXmlInternalError`,
  `EXmlNsHrefNotFound`, `EXmlUnsupported`, `EXmlReaderError`;
- `XmlConvert`: `ToBoolean`, `ToInteger`, `ToInt64`, `ToDouble`, `ToCurrency` (xs:decimal,
  exact), `ToDateTime` (xs:dateTime and xs:date, with the time zone on request), their `TryTo*`
  forms, and `From*` for the other direction. The lexical forms of XML Schema are the same on
  every locale: `XmlConvert.ToDouble('12.5')` works on a system whose decimal separator is a
  comma, and `StrToFloat` there does not;
- `NewUtf16String`, `NewUtf8String`, `NewRawString` and friends: the string builders the
  helpers use to avoid double passes over libxml2 buffers on the hot path.

## LX2.Helpers

Record helpers for `xmlDoc`, `xmlNode`, `xmlAttr` and `xmlNamespaces`. A helper adds no
state: `xmlDocPtr` stays a plain pointer, memory is owned by libxml2 and released with
`Doc.Free` (`xmlFreeDoc`). This is the layer to use when performance matters or when the
code already thinks in libxml2 terms. The first XPath query on a document indexes its
elements in document order (`xmlXPathOrderDocElems`; `OrderElements`, `ElementsChanged`
and `ElementsOrdered` on `xmlDoc`): without the index libxml2 sorts results by walking
the tree, which is quadratic among thousands of sibling elements. The helpers and the DOM
layer drop the index when an indexed element is moved; after moving elements through
libxml2 directly, call `ElementsChanged`. In the same way the live lists of the DOM layer
(`ChildNodes`, `GetElementsByTagName`) answer `Item[I]` by stepping from the position of
the previous call, so a walk by index is linear; the position holds while
`xmlTreeGeneration` stays the same, and the helpers and the DOM layer call `TreeChanged` (on
`xmlDoc` or `xmlNode`) before they link, unlink, replace or free nodes, rename an element or
change its namespace. After changing such a document through libxml2 directly, call
`TreeChanged` as well. The blocks themselves come from the C runtime heap
by default; `LX2Lib.UseHostMemoryManager := True` before `Initialize` points libxml2 at
`GetMem`/`ReallocMem`/`FreeMem` instead, so a document lives in the same heap as the
strings around it and a faster manager installed by the host (FastMM5 and the like)
serves the parser: 20–35 % faster in a single thread, but the C heap scales better when
several threads parse at once, so a server is better off with the default. Builds with
`DEBUG` defined use the library's own debug allocator either way, so that `xmlMemUsed`
reports what the library holds.

Creating and loading:

```delphi
var Doc := xmlDoc.Create;                                            // empty document
var Doc := xmlDoc.Create(Xml, DefaultParserOptions);                 // string, RawByteString, TBytes, Pointer+Size
var Doc := xmlDoc.CreateFromFile('data.xml', DefaultParserOptions);
var Doc := xmlDoc.Create(Stream, DefaultParserOptions, 'windows-1251');
```

Every `Create` takes an optional `ErrorHandler`: a callback that receives each parser error
as a `TXmlParseError`. Without it a failed parse returns `nil` and the error is available
through `xmlGetLastError`.

Building a tree:

```delphi
var Doc := xmlDoc.Create;
var Root := Doc.CreateRoot('order', 'urn:shop:orders');              // element with a default namespace
Root.SetAttribute('xmlns:p', 'urn:shop:payment');
Root.Attribute['id'] := '42';
Root.AddChild('customer', 'ACME');
Root.AddChildNs('total', 'urn:shop:payment', '99.90');               // resolved to the p: prefix
Doc.CreateChild(Root, 'note', '', False, 'ships today');
Writeln(UTF8ToString(Doc.Xml));
Doc.Free;
```

Navigation and editing follow the DOM names: `FirstChild`, `NextSibling`,
`FirstElementChild`, `NextElementSibling`, `ChildNodes`, `ParentElement`, `Attributes`,
`Attribute[Name]`, `GetAttributeNs`, `HasAttribute`, `AppendChild`, `InsertBefore`,
`RemoveChild`, `ReplaceChild`, `CloneNode`, `Text`, `NodeValue`, `Xml`, `Path`.

XPath, XSLT and serialisation:

```delphi
var Nodes := Root.SelectNodes('//total');                            // xmlNodeArray
var Node := Root.SelectSingleNode('customer');
// prefixes that the document does not declare: pass an xmlNamespaces list
var Ns: xmlNamespaces;
Ns.Add('p', 'urn:shop:payment');
var Totals := Root.SelectNodes('//p:total', Ns);

var Style := xmlDoc.CreateFromFile('report.xsl', DefaultParserOptions);
var Html: string;
if Doc.Transform(Style, Html) then                                  // also: out xmlDocPtr, out RawByteString, TStream
  Writeln(Html);

Doc.Save('order.xml', 'UTF-8', [xmlSaveFormat]);                    // file or TStream
var Bytes := Doc.ToBytes('UTF-16');
var Canonical := Doc.Canonicalize(TXmlC14NMode.xmlC14NExclusive);   // also CanonicalizeTo(file/stream)
```

Validation against the DTD uses `Doc.Validate(ErrorHandler, ResourceLoader)` and
`Doc.ValidateNode(Node)`. The external DTD subset comes only from `ResourceLoader`; without
one it is not read. XML Schema validation goes through `IXMLSchemaCollection` (LX2.DOM).

The pull reader on this level is `xmlTextReader` (see [LX2.Reader](#lx2reader) for the
interface above it). Names and values are UTF-8, and names come from the dictionary of the
reader: an atom made once by `Atom` compares with them by pointer, so scanning for records
allocates nothing per node.

```delphi
var R := xmlTextReader.CreateFromFile('objects.xml', [xmlParseHuge, xmlParseBigLines]);
try
  var AObject := R.Atom('Object');
  while R.ReadToFollowing(AObject) do
    Index.Add(R.GetAttribute('GUID'));               // RawByteString, UTF-8
finally
  R.Free;
end;
```

`Read` raises `EXmlParserError` on malformed XML and returns `False` after it, so a loop never
ends early in silence. `ValuePtr`, `CurrentNode` and `Expand` are valid until the reader moves:
libxml2 reuses the nodes it frees, and a pointer kept longer reads another node rather than
failing. `Text`, `InnerXml` and `OuterXml` are libxml2's own and do not move the reader;
`ReadElementContent`, `ReadNode` and the `ReadTo*` methods move it as in .NET.

## LX2.DOM

Interfaces modelled on MSXML 6 and the W3C DOM, implemented in `LX2.DOM.Classes` over the
libxml2 tree. Objects are reference counted; a node keeps its document alive.

```delphi
var Doc := CoCreateXMLDocument;
Doc.PreserveWhiteSpace := False;
Doc.ValidateOnParse := False;

if Doc.Load('order.xml') then ...                                    // file or URL
if Doc.LoadXML(Xml, DefaultParserOptions) then ...                  // RawByteString / string / TBytes / stream overloads
if Doc.LoadFromStream(Stream, 'UTF-8') then ...
```

The interface set: `IXMLDocument`, `IXMLDocumentType`, `IXMLDocumentFragment`,
`IXMLElement`, `IXMLAttribute`, `IXMLNode`, `IXMLNodeList`, `IXMLNamedNodeMap`,
`IXMLAttributes`, `IXMLCharacterData`, `IXMLText`, `IXMLCDATASection`, `IXMLComment`,
`IXMLProcessingInstruction`, `IXMLEntityReference`, `IXMLParseError`, `IXMLErrors`,
`IXSLTErrors`, `IXMLSchemaCollection`, `IXMLResolver`, plus enumerators so that `for ... in`
works over node lists and attribute maps.

Beyond MSXML the element interface has the conveniences of the helpers: `AddChild`,
`AddChildNs`, `SetAttribute` overloads for `Int64`, `Boolean` and `TDateTime`, and the
document has `CreateRoot`, `CreateChild`, `CreateElementNs`, `Clone`, `ToString`, `ToBytes`,
`ToUtf8`, `Canonicalize`.

Prefixed names behave as in MSXML. `CreateElement('ns1:File')`, or `CreateNode` with a prefixed
name and an empty namespace URI, keeps the prefix even when nothing declares it yet, so the
usual sequence of creating the root and then declaring the prefix on it puts the element into
that namespace in the document written out:

```delphi
var Root := Doc.CreateElement('ns1:File');
Doc.DocumentElement := Root;
Root.SetAttribute('xmlns:ns1', 'urn:example');   // <ns1:File xmlns:ns1="urn:example"/>
```

An attribute created with a prefix and no namespace URI (`CreateAttribute('ns1:Version')`)
can be given a value before it has an owner element; the prefix is bound when the attribute
is attached.

XSLT and schemas:

```delphi
var Style := CoCreateXMLDocument;
Style.Load('report.xsl');
var Html: string;
if Doc.Transform(Style, Html) then                                   // out IXMLDocument, RawByteString, string or TStream
  Writeln(Html)
else
  for var E in Doc.XSLTErrors do
    Writeln(E.Reason);
```

A transformation of a node other than the document (`Node.TransformNode(Style)`, any
`Transform` or `TransformNodeTo...` of an element, attribute or text node) starts at that
node, as `transformNode` of MSXML does: the first template is chosen for the node itself, with
`position()` and `last()` equal to 1, and a template matching `/` does not fire. Global
variables and parameters are evaluated at the document node, and absolute paths address the
whole document. libxslt cannot do this on its own; the bundled build carries a local patch
(`Native\Patches\020-xslt-user-start-node.patch`). With a libxslt loaded from elsewhere
(`XSLTLib.Load`) the processing of a node starts at its document.

```delphi
var Schemas := CoCreateSchemaCollection;
var Xsd := CoCreateXMLDocument;
Xsd.Load('order.xsd');
Schemas.Add('urn:shop:orders', Xsd);
Doc.Schemas := Schemas;
var Err := Doc.Validate;
if (Err <> nil) and (Err.ErrorCode <> 0) then
  Writeln(Err.Reason, ' at ', Err.Line, ':', Err.LinePos);
```

`IXMLSchemaCollection` compiles everything added to it into one schema set, the way
`XmlSchemaSet` does in .NET, and the documents never have to exist on disk. An `xs:import`
of a namespace that is in the collection is served from the collection whatever its
`schemaLocation` says. Other locations are fetched through the `IXMLResolver` passed to
`Add` (or read next to the file when the document was loaded from one), and what comes
back is processed by the same rules. A location that resolves nowhere is skipped with a
warning in `Schemas.Errors`, so the parts of one namespace added one by one form a single
schema even when they include each other by file names; components that are really
missing surface as unresolved references. The compiled schema is cached until the next
`Add` or `Remove`.

## LX2.SAX

Three levels, pick one:

- `TLX2SAXParserWrapper`: the libxml2 SAX2 callbacks as virtual methods with the raw
  `xmlCharPtr` arguments, for code that wants the bare speed;
- `TSAXCustomParser`: the same events as `Do*` virtual methods with Delphi strings,
  `TSAXNamespaces` and `TSAXAttributes` records, an error list in `Errors`, a locator with
  line and column, `PreserveWhitespaces`;
- `TSAXParser` + `ISAXContentHandler`: the handler lives in a separate reference-counted
  object; `TSAXCustomContentHandler` is a base class with empty implementations of every
  event, override what you need (see the quick start).

Input comes through `ParseFile`, `Parse(RawByteString)`, `Parse(TBytes)`,
`Parse(Pointer, Size)` or `Parse(TStream)`; the result is `True` when the document is
well-formed, the errors are collected in `Errors` and also reported through
`Warning`/`Error`/`FatalError`.

## LX2.Reader

A pull reader after `System.Xml.XmlReader`, over the libxml2 xmlTextReader. The caller moves a
cursor through the nodes in document order, so the code that reads a document is a plain loop
rather than a state machine in SAX callbacks, and memory stays constant whatever the size of
the document. On a 33 MB document of 120 000 records the bare loop takes about half the time of
a DOM parse, which needs 150 MB more memory, and two and a half times that of SAX
(`Tests\LX2Bench`).

```delphi
var R := XmlReader.CreateFromFile('packet.xml');
for var Doc in R.Elements('Document') do          // Doc: IXmlReader of one record
begin
  var Id := Doc.GetAttribute('Id');
  if Doc.ReadToDescendant('Amount') then
    Total := Total + Doc.ReadElementContentAsCurrency;
end;                                               // what the body left unread is passed over

for var Obj in R.ReadElements('Object') do       // Obj: IXMLElement, a copy of the record
  Index.Add(Obj.GetAttribute('GUID'), Obj);
```

`XmlReader.CreateFromString`, `CreateFromFile`, `Create(TStream)`, `Create(TBytes)` and
`Create(IXMLDocument)` (a reader over a loaded document) make readers; each takes an optional
`TXmlReaderSettings`. The interface is late-bindable like the DOM, so scripts can use it.

The rules a reader follows are those of .NET:

- `Read` moves one node. `ReadElementContentAs*`, `ReadInnerXml`, `ReadOuterXml`, `ReadElement`,
  `Skip` and a successful `ReadTo*` leave the reader on the node after the element. Called
  inside `while R.Read do`, the `Read` of the loop then passes over the following node: on
  indented XML that is the whitespace between records and nothing seems wrong, on minified XML
  or with `IgnoreWhitespace` every second record is lost. `Elements` and `ReadElements` find
  every record whatever the body does; a loop of your own moves only in its else branch:

  ```delphi
  R.MoveToContent;
  while not R.EOF do
    if R.IsStartElement('Price') then
      Total := Total + R.ReadElementContentAsCurrency    // already past the element
    else
      R.Read;
  ```
- `IsStartElement` and `MoveToContent` move too: past whitespace, comments and processing
  instructions.
- An empty element (`<a/>`, `IsEmptyElement`) has no `EndElement`.
- A name given alone matches the local name in any namespace; with a namespace URI both must
  match, and an empty URI means no namespace. Compare names that way rather than by `Name`:
  prefixes differ between senders.
- Typed reads follow the lexical forms of XML Schema (`XmlConvert`), not the locale.
  `ReadElementContentAs*` raises `EXmlReaderError` on a child element and on a value outside
  the type, with the line of the element.
- `ReadSubtree` gives a reader of the current element; closing it leaves the outer reader on
  the end tag of the element, never past it.
- `ReadElement` copies the element into a document of its own (`XNode.ReadFrom`) and declares
  there every namespace in scope, used or not, so prefixes in values such as `xsi:type="t:Code"`
  keep their meaning. Attributes `xml:lang` and `xml:space` of the ancestors are not copied.
- `Expand` gives the current element as DOM nodes of the reader's own tree, without a copy:
  a loop over the records takes less than half the time of one with `ReadElement`. The nodes
  live until the reader moves, for a record of `Elements` while the loop body runs; a wrapper
  kept longer is left without its node (`NodePtr` is nil): reads such as `GetAttribute` return
  empty values and raise nothing. Copy what has to outlive the record.
- `ReadElementContentAsBase64(Stream)` decodes as it reads, without a string for the text.

`TXmlReaderSettings` starts with safe defaults: a DOCTYPE raises `EXmlReaderError`
(`DtdProcessing := Ignore` passes over it, `Parse` applies its internal subset), external
entities and DTDs are never loaded, the network is never used, `xmlParseHuge` allows text
nodes up to 1 GB and `xmlParseBigLines` keeps line numbers exact past 65535.
`IgnoreWhitespace`, `IgnoreComments` and `IgnoreProcessingInstructions` pass over such nodes;
whitespace-only text is `Whitespace`, or `SignificantWhitespace` under `xml:space="preserve"`.
`Schemas` validates while reading: without `OnValidationError` the first validation error
raises `EXmlParserError`, with it every error goes to the handler and the reading goes on.

Where the time goes, measured with Intel VTune on that document: the libxml2 reader builds a
part of a tree and frees it as it goes, so a bare `Read` loop costs about half a DOM parse, and
the allocator of the C runtime takes a large share of every DOM: about 60% of a DOM parse is
`malloc`, `free` and `realloc`. `LX2Lib.UseHostMemoryManager := True` before `Initialize` makes
a DOM parse about 30% faster and a DOM copy per record about 20% in a single thread (see the
memory notes of LX2.Helpers about several threads).

| 120 000 records, 33 MB, one thread, C heap | ms |
|---|---:|
| DOM parse | 260 |
| SAX, nothing done | 50 |
| helper: `Read` loop | 125 |
| helper: `ReadToFollowing` by atom, `@id` | 140 |
| `Elements`: `@id`, `ReadToDescendant`, `ReadElementContentAsString` | 210 |
| `Expand` per record, `@id` | 175 |
| `ReadElements` (a copy per record), `@id` | 380 |

What libxml2 does not give: the column of a node (`LineNumber` is the line of the start tag,
the column is known only for parse errors), `IsDefault` (it is always false), entity
references to expand later (`ResolveEntity`) and fragments with several roots. Malformed XML
raises `EXmlParserError`, and the reader stays in the `Error` state; libxml2 parses ahead in
pieces of 512 bytes, so the records before the error in the same piece never come, and
processing that cannot be undone wants the document checked first.

## XPath

`SelectNodes` and `SelectSingleNode` exist on both the helpers and the DOM. A query that is a
plain location path without predicates, functions or axes (`/order/customer`, `//total`,
`items/item`) is evaluated by the built-in engine in `LX2.XPATH`, which compares local names
and ignores namespaces, the way MSXML does with the default selection language. Anything
else is passed to the libxml2 XPath evaluator with full XPath 1.0 semantics; prefixes are
resolved through the namespaces in scope, and the helper overload takes an explicit
`xmlNamespaces` list for prefixes that are not declared in the document.

## Error handling

- Parsing through the helpers returns `nil` on failure; pass an `ErrorHandler` to get every
  error with line, column and text, or read `xmlGetLastError`.
- The DOM document collects errors in `ParseError` (the last one, MSXML style) and `Errors`
  (all of them); `LoadXML` and friends return `False`. XSLT errors go to `XSLTErrors`.
- The SAX parser collects `Errors` and calls the `Warning`/`Error`/`FatalError` events.
- The reader raises `EXmlParserError` on malformed XML and `EXmlReaderError` when the document
  does not have the shape a method needs; warnings and validation errors go to `Errors`.
- Programming errors (an unsupported node type, a namespace that cannot be resolved, a
  broken invariant inside the binding) raise `EXmlError` descendants.

## Updating libxml2 and libxslt

```
cd Native
.\Import.ps1                                  # latest releases of the 2.15 and 1.1 series
.\Import.ps1 -LibXml2 2.15.4 -LibXslt 1.1.45  # a specific pair
.\Build.ps1 -Test                             # objects, LX2.Static.pas, smoke test
```

`Import.ps1` fetches the release archives from the GNOME mirrors on GitHub and copies the
library sources; the module list comes from the release's own `CMakeLists.txt`. `Build.ps1`
needs RAD Studio (it uses `bcc64x`, `llvm-nm`, `llvm-objdump` and `dcc64` from the
installation) and verifies after compiling that every unresolved symbol of the objects is
covered, so a new dependency introduced by an upstream release fails the script rather
than the link in an application. The version series is pinned in `Import.ps1` because
every minor libxml2 release changes the API; upstream maintains only the newest branch.

## Status

- The binding has been exercised by synthetic tests and the DUnitX suite in `Tests`, and
  the static build on Windows x64 is what the author's own applications use.
- The Linux64 archive passes the smoke tests under WSL; the WinARM64EC build is linked, not
  run.
- Win32 has not been tested.
