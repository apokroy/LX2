# LX2

Delphi bindings for [libxml2](https://gitlab.gnome.org/GNOME/libxml2) and
[libxslt](https://gitlab.gnome.org/GNOME/libxslt/), from the raw C API up to an MSXML-style
DOM. The goal of the project is a cross-platform replacement for MSXML 6.0: where possible
the library follows the W3C DOM model, and where the two disagree, MSXML compatibility wins.

MIT licensed. libxml2 and libxslt keep their own MIT-style licences (`LIBXML2.COPYRIGHT`,
`LIBXSLT.COPYRIGHT`).

> [!IMPORTANT]
> **Starting with this release libxml2 and libxslt are linked statically on Windows x64.**
> The libraries are compiled into COFF objects that ship with the repository
> (`Native\Lib\Win64`) and are linked into your executable by the `LX2.Static` unit.
> `libxml2.dll` and `libxslt.dll` are no longer required and no longer have to be
> deployed. You need nothing but Delphi to build: the C compiler is used only to update
> the libraries. See [Static linking](#static-linking-windows-x64).
>
> Late binding to a shared library is still available: leave `LX2.Static` out of the uses
> clause and `LX2Lib.Load` loads `libxml2.dll` / `libxml2.so.16` as before. Linux64 keeps
> working this way with the binaries in `Binaries\Linux64`.

Bundled versions: libxml2 2.15.4, libxslt 1.1.45.

## Contents

- [Layers](#layers)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Static linking (Windows x64)](#static-linking-windows-x64)
- [Loading a shared library](#loading-a-shared-library)
- [Strings and encodings](#strings-and-encodings)
- [LX2.Types](#lx2types)
- [LX2.Helpers](#lx2helpers)
- [LX2.DOM](#lx2dom)
- [LX2.SAX](#lx2sax)
- [XPath](#xpath)
- [Error handling](#error-handling)
- [Updating libxml2 and libxslt](#updating-libxml2-and-libxslt)
- [Status](#status)

## Layers

The library is a stack; pick the level that fits the task.

| Unit | Layer | What it gives you |
|---|---|---|
| `libxml2.API`, `libxslt.API` | Raw C API | One-to-one declarations of the libxml2/libxslt types and functions. Function pointers, filled either from a shared library (`LX2Lib.Load`) or from the statically linked objects. |
| `LX2.Static` | Linking | Generated unit: `{$L}` of the objects, the C runtime imports and the binding of the API pointers. Add it to uses and no DLL is needed. Empty on platforms other than Win64. |
| `LX2.Types` | Common types | Delphi-style option sets (`TXmlParserOptions`, `TXmlSaveOptions`, `TXmlC14NMode`), parse error records and lists, exception classes, fast UTF-8/UTF-16 conversion helpers used by every layer above. |
| `LX2.Helpers` | Record helpers | `xmlDoc`, `xmlNode`, `xmlAttr`, `xmlNamespaces` gain methods and properties: parse from string/file/stream, navigate, edit, XPath, XSLT, save with any encoding, canonicalize. Zero overhead over the C API: the helpers work on the native pointers. |
| `LX2.SAX` | SAX | A thin wrapper over the libxml2 SAX2 parser (`TLX2SAXParserWrapper`), a Delphi-style parser with virtual `Do*` methods (`TSAXCustomParser`) and a handler-interface variant close to the MSXML SAX interfaces (`TSAXParser` + `ISAXContentHandler`). |
| `LX2.DOM`, `LX2.DOM.Classes` | DOM | Reference-counted interfaces `IXMLDocument`, `IXMLElement`, `IXMLNode`, `IXMLNodeList`, `IXMLAttributes`, `IXMLSchemaCollection` and the rest of the MSXML/W3C set, implemented over the libxml2 tree. |
| `LX2.XPATH` | XPath | A small engine for simple location paths that ignores namespaces the way MSXML does; everything else goes to the libxml2 XPath evaluator. |
| `RttiDispatch` | Late binding | `IDispatchInvokable`/`TDispatchInvokable`: the DOM and SAX interfaces can be invoked by name through RTTI, which keeps scripting scenarios of MSXML available without COM. |

## Requirements

- Delphi 10.3 Rio or later (the library relies on inline variables and record helpers with
  class methods); developed and tested with Delphi 13.1.
- Windows x64 with static linking, or Windows x64 / Linux64 with a shared library.
- Win32 compiles but has not been tested.

## Installation

Either add `Source` to the library path, or open `Packages\LX2.dpk` and install it. The
package contains every unit including `LX2.Static`; on Win32 that unit is empty.

```delphi
uses
  LX2.Types, LX2.Helpers,   // record helpers over the C API
  LX2.DOM,                  // MSXML-style interfaces
  LX2.SAX,                  // SAX parser
  LX2.Static;               // static linking on Win64; omit it to load a DLL instead
```

Initialisation is implicit: the DOM and SAX layers initialise `LX2Lib` (and `XSLTLib` on
the first transformation) themselves. Code that calls `libxml2.API` or the helpers directly
calls `LX2Lib.Initialize` once.

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

## Static linking (Windows x64)

`Native\` holds the sources of libxml2 and libxslt (the library parts of the releases), the
objects built from them and the scripts that maintain both:

```
Native\Source\libxml2   libxml2 sources of the release, Copyright, VERSION
Native\Source\libxslt   libxslt sources of the release, Copyright, VERSION
Native\Source\shim      Win32 declarations, iconv, the printf family for the C runtime
Native\Lib\Win64        xml_*.o, xslt_*.o, shim_*.o — committed, consumers never compile C
Native\Import.ps1       downloads a release and refreshes Native\Source
Native\Build.ps1        compiles the objects, checks them, generates Source\LX2.Static.pas
Source\LX2.Static.pas   generated: {$L} per object, runtime imports, API binding
```

How it works: `bcc64x` (the clang shipped with RAD Studio) compiles the C sources into COFF
objects, `LX2.Static` links them with `{$L}`, and the C runtime the libraries need comes
from `ucrtbase.dll`, which is part of Windows 10 and later. Names that ucrtbase does not
export (the `printf` family) are provided by a small C shim, the Win32 API is declared by
hand, iconv is implemented on top of `MultiByteToWideChar`, so every Windows code page
libxml2 asks for is available. The unit is generated from the declarations in
`libxml2.API.pas` and `libxslt.API.pas`: when the API unit changes, `Build.ps1` regenerates
the binding. `Native\README.md` explains the mechanics, the feature set and the invariants
the build script enforces.

What it means for an application:

- add `LX2.Static` to the uses clause of the project (or install the package, which
  contains it); `LX2Lib.Load` and `XSLTLib.Load` then bind to the objects and
  `LX2Lib.LibraryFileName` is empty;
- nothing to deploy next to the executable;
- the executable grows by about 2 MB;
- the objects are built for x86-64 with SSE2 as the baseline and `-O3`; they run on any
  64-bit Windows 10 or later.

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

`LX2Lib.IsLoaded` and `LX2Lib.LibraryFileName` report the state. Binaries for Linux64 are in
`Binaries\Linux64`; most distributions ship an older libxml2 with the `.so.2` soname, which
LX2 cannot use, so deploy the bundled `.so` files with the application.

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
  entity substitution, DTD attribute defaults, big lines and huge documents.

## LX2.Types

Everything the upper layers share:

- `TXmlParserOptions`, `TXmlSaveOptions`, `TXmlC14NMode`: Delphi sets and enums over the
  libxml2 flags, with `XmlParserOptions(...)` converting a set to the native bitmask;
- `TXmlParseError` (text, source, line, column, level) and `TXmlParseErrors`, a list with an
  enumerator, filled by the SAX parser and the DOM document;
- exceptions: `EXmlError` (base), `EXmlParserError`, `EXmlInternalError`,
  `EXmlNsHrefNotFound`, `EXmlUnsupported`;
- `NewUtf16String`, `NewUtf8String`, `NewRawString` and friends: the string builders the
  helpers use to avoid double passes over libxml2 buffers on the hot path.

## LX2.Helpers

Record helpers for `xmlDoc`, `xmlNode`, `xmlAttr` and `xmlNamespaces`. A helper adds no
state: `xmlDocPtr` stays a plain pointer, memory is owned by libxml2 and released with
`Doc.Free` (`xmlFreeDoc`). This is the layer to use when performance matters or when the
code already thinks in libxml2 terms.

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

Validation against XML Schema uses `Doc.Validate(ErrorHandler, ResourceLoader)` and
`Doc.ValidateNode(Node)`.

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
- Win32 has not been tested.
- Planned: XML documentation for all significant sources; wrappers for the reader API.
