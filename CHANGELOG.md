# Changelog

## v1.1.0 — 2026-09-21

### Changed

- Text with non-ASCII characters stays on the fast path of the libxml2 parser
  (`Native\Patches\010-chardata-utf8-fast-path.patch`, the first local patch to the
  imported sources; `Native\Patches.ps1` applies and verifies them). Before, the first
  byte of a Cyrillic letter sent the rest of the text node to the character-by-character
  path, which took about 40 % of a SAX parse of a Russian document.
- Single-byte code pages convert through tables built at `iconv_open` instead of
  `MultiByteToWideChar`/`WideCharToMultiByte` per 1024 characters: saving a document as
  windows-1251 no longer costs twice a save as UTF-8.
- `DefaultParserOptions` includes `xmlParseCompact` (new member of `TXmlParserOption`,
  `XML_PARSE_COMPACT`): text shorter than 16 bytes is stored inside the node, one
  allocation less per number, code or date.

### Fixed

- `SelectSingleNode` with a path made of names only (`a`, `a/b`, `/a/b`, `//a/b`) did not
  follow XPath: the fast evaluator matched the first step against the context node itself,
  so `element.SelectSingleNode('child')` returned nil while `SelectNodes('child')` found the
  node; an absolute path started at the context node instead of the document; `//a/b` missed a
  match nested in another `a` and could return a node that is not the first in document
  order. The evaluator is rewritten: a relative path starts at the children of the context
  node, `/` and `//` at its document, and steps after a `//` are checked against the ancestors
  of every candidate in document order. A test compares it with libxml2 over a set of paths
  and context nodes. Parsing no longer writes into the query string, and a path ending with
  `/` goes to libxml2. The namespace rule is unchanged: a name without a prefix fits any
  namespace.
- Late-bound calls (`IDispatch`) took the first method of the name whatever the arguments:
  `setAttribute(name, 42)`, `toString(True)`, `save(path)` reached the wrong overload or
  failed with "Wrong parameter count". The overload is now chosen by the number and types of
  the arguments. `IXMLDocument.LoadXML` has forms without `Options` instead of a default
  value, which RTTI does not keep: `doc.loadXML(text)` works late-bound. Reading a plain
  property with a bare method call no longer ends in "Method not found".
- Late-bound callers (`IDispatch`, a `Variant` in a script) could not reach members that the
  implementing class declared under another name than the interface, or not at all: interface
  properties carry no RTTI, so dispatch names come from the class. `item` of every node list
  but the attribute list (the class called it `Items`), `schemas` of a document,
  `ownerElement` of an attribute, `level` of a parse error, `next` and `_newEnum` of the error
  collection failed with a member-not-found error. `IXMLErrors` and `IXSLTErrors` gained `Item`
  next to the default `Items`, the MSXML name. A test now checks that every `Get_X`/`Set_X` of
  an implemented interface resolves as `X`.
- A property of a class type (`TXMLDocument.Errors`) came back to a late-bound caller as a
  value that could not be called; objects that implement `IDispatch` are now returned as
  `IDispatch`, like interfaces.
- A simple path (`//name`, `/a/b`, no predicates) queried on a document crashed with an
  access violation when the document had been parsed from memory, and an absolute path
  (`/a/b`) found nothing on any document: the fast evaluator compared the document node
  itself with the first step, and a document parsed from memory has no name. A query on a
  document now starts at its root element, and only elements are ever compared with a step.
- `IXMLNode.InsertBefore` with a nil reference node crashed instead of appending; the usual
  source of the nil is `parent.FirstChild` of an empty parent.
- `LX2.Types` did not compile for Linux64: the SSE2 routines are inline assembler written
  against the Win64 calling convention, and they were guarded by `CPUX64` alone. They are
  now compiled only for Win64 with the inline assembler available; every other target takes
  the Pascal path. `LX2.SAX` names `Posix.Unistd` on POSIX, which removes the H2443 hint
  about `FileClose`.
- XPath queries whose results need sorting were quadratic in documents with thousands of
  sibling elements: without an index libxml2 finds the order of two elements by walking
  the tree, and `//*[not(*)]` on a 7.6 MB payment packet took 26 seconds. The first query
  now indexes the elements in document order (`xmlXPathOrderDocElems`, 9 ms on that
  document, the same query 56 ms after it); `xmlDocHelper.OrderElements`,
  `ElementsChanged` and `ElementsOrdered` expose the mechanism. The helpers and the DOM
  layer drop the index when a node that may carry one is attached elsewhere, so a moved
  element cannot leave a stale order behind; after moving elements through libxml2
  directly, call `ElementsChanged`.

### Added

- Static build for Linux64: `Native\Build.ps1 -Platforms Linux64` compiles libxml2 and
  libxslt for `x86_64-linux-gnu` into `Native\Lib\Linux64\liblx2native.a`, and
  `LX2.Static.pas` gets a Linux half that declares the entry points as
  `external 'liblx2native.a'`. With `LX2.Static` in a uses clause a Linux executable needs
  neither `libxml2.so.16` nor `libxslt.so`; the application puts `Native\Lib\Linux64` on its
  library path. The same set of entry points is bound as on Win64. `-Test` links the smoke
  test with dcclinux64 and runs it in WSL.
- The Linux archive runs on glibc 2.33 and later (`stat64` is a function only since then);
  the oldest system it is meant for is Ubuntu 22.04 with glibc 2.35. The objects are built
  with `-std=gnu11` and without `_GNU_SOURCE`: with it the headers of glibc 2.38 redirect
  `sscanf` and `strtoul` to `__isoc23_*`, and the executable stops loading on older
  distributions. `Build.ps1` keeps a closed list of the glibc names the objects may
  reference. An application still has to be linked against the SDK of the oldest system it
  runs on: the symbol versions of the RTL calls come from there.
- `LX2StaticSmoke` loads a document by file name and checks that a directory and a missing
  file are refused; the file path of the C runtime was not covered before.
- `Native\Pgo.ps1`: profile-guided build of the objects with another LLVM (upstream or
  the one of Visual Studio) over a corpus of documents; `Build.ps1 -Clang`/`-Profile`
  underneath it. Measured on real documents: DOM parse −10 %, push parse −30 %, C14N −20 %.
- `Tests\LX2Bench`: the throughput benchmark (`Bench.ps1`), with a `--verify` mode that
  two builds of the objects must agree on.

- `LX2Lib.Load` no longer installs the libxml2 debug allocator in release builds: the
  library keeps the C runtime heap, and `LX2Lib.UseHostMemoryManager := True` before
  `Initialize` hands it to the Delphi memory manager instead (`xmlMemSetup` with wrappers
  over `GetMem`/`ReallocMem`/`FreeMem`). The debug allocator, with its per-block header
  and a global mutex on every call, stays only in builds with `DEBUG` defined, where
  `xmlMemUsed` feeds the leak tests. On a 31 MB document the release build parses 1.2×
  faster on the C heap and 1.5× on FastMM5, evaluates XPath and validates against a
  schema up to 2× faster; with four threads parsing at once the debug allocator had
  serialized them to an eighth of the single-thread throughput, and the Delphi manager
  scales worse than the C heap there, which is why the C heap is the default.

- The static Win64 build of libxml2 no longer includes RelaxNG, Schematron, XPointer,
  XInclude and the debug dumps: the binding exposes none of them, and dcc links every
  object whole, so `xmlreader` and `xmlschemas` dragged them into each executable. The
  code linked from `LX2.Static` shrinks by about a tenth. `xmlTextReaderRelaxNGSetSchema`,
  `xmlTextReaderRelaxNGValidate`, `xmlTextReaderRelaxNGValidateCtxt` and `xmlSchemaDump`
  stay `nil` in the static build; `XML_PARSE_XINCLUDE` and `xsltSetXIncludeDefault` are
  accepted and do nothing. A DLL built with these features still works through
  `LX2Lib.Load`.

## v1.0.3 — 2026-09-09

### Fixed

- Validation through `IXMLSchemaCollection` with a schema split over several documents
  held in memory. The collection wrote merged copies to temporary files, reloaded the last
  one and treated "no matching global declaration available for the validation root" as
  success, so a document checked against a multi-file schema passed whether it was valid
  or not. The set is now compiled the way `XmlSchemaSet` does in .NET: an `xs:import` of
  a namespace present in the collection is served from the collection regardless of its
  `schemaLocation`; other `xs:include`/`xs:import`/`xs:redefine` locations go through the
  `IXMLResolver` passed to `Add` (which was accepted and ignored before) or, for a document
  loaded from a file, to the file next to it; a location that resolves nowhere is skipped
  with a warning instead of an error, so the documents of one namespace added one by one
  form a single schema even when they include each other by file names. Every document of
  a namespace keeps its own `elementFormDefault` and prefixes: they are joined by an
  `xs:include` wrapper, not by copying nodes. All parts reach libxml2 from memory through
  the global external entity loader, because the resource loader set on the schema parser
  context is not passed to the nested contexts libxml2 creates for imported documents.
  A document whose root element no schema declares is now reported as invalid.
- The compiled schema is cached until the next `Add` or `Remove` instead of being rebuilt
  on every `Validate`.

### Added

- `IXMLSchemaCollection.Errors`: the diagnostics of the last compilation, warnings included.
  When the schema does not compile, `Validate` returns `False` and copies them into the
  document's `Errors` as well.

## v1.0.2 — 2026-09-06

### Fixed

- XPath queries without an explicit namespace list (`SelectNodes`, `SelectSingleNode`,
  `XPathEval`) saw only the namespace of the context node itself. Every prefix declared on
  the context node or on any of its ancestors is now registered, the nearest declaration
  winning, so `//p:item` works from an unprefixed root that carries `xmlns:p`.
- `xmlNodeHelper.GetElementsByTagName` never returned when called on an element with
  children: the walk restarted from the first child on every step instead of advancing
  from the current node. The DOM layer (`IXMLElement.GetElementsByTagName`) uses its own
  list and was not affected.
- Parsing single-byte encodings (`windows-1251`, ISO 8859, KOI8) through the static build
  was about 20 % slower than the DLL: the iconv shim probed every input byte for a DBCS
  lead byte. Single-byte code pages are recognised once per descriptor (`GetCPInfo`) and
  converted in 1024-character chunks; the same document now parses about 9 % faster than
  with the DLL.

## v1.0.1 — 2026-09-06

### Fixed

- `xmlNodeHelper.SelectSingleNode` (and therefore `IXMLNode.SelectSingleNode`) leaked the
  libxml2 `xmlXPathObject` when a valid XPath expression selected nothing: the early exit
  skipped `xmlXPathFreeObject`. Reported in
  [#5](https://github.com/apokroy/LX2/issues/5). The single-node query now evaluates
  through `XPathEval` like `SelectNodes`, which also registers the namespaces in scope, so
  a prefixed query such as `//p:item` works in `SelectSingleNode` too.
- Regression tests in `Tests\LX2APITests.pas` check `xmlMemUsed` across empty results and
  the namespace resolution.

## v1.0.0 — 2026-09-06

### Static linking of libxml2 and libxslt (Windows x64)

libxml2 and libxslt are now compiled into COFF objects that ship with the repository
(`Native\Lib\Win64`) and are linked into the executable by the new `LX2.Static` unit.
`libxml2.dll` and `libxslt.dll` are no longer required, no longer deployed and no longer
part of the repository. Building an application needs nothing but Delphi; the C compiler
(`bcc64x` from RAD Studio) is used only to update the libraries.

- New unit `Source\LX2.Static.pas`, generated by `Native\Build.ps1` from the declarations
  in `libxml2.API.pas` and `libxslt.API.pas`. Add it to the uses clause of the project or
  install the package, which contains it; `LX2Lib.Load`/`XSLTLib.Load` then bind to the
  objects and `LX2Lib.LibraryFileName` is empty. On platforms other than Win64 the unit is
  empty and late binding stays as it was.
- The C runtime comes from `ucrtbase.dll` (Windows 10 and later); the `printf` family,
  the POSIX file aliases, iconv (on top of `MultiByteToWideChar`, every Windows code page)
  and the Win32 declarations are provided by the small shims in `Native\Source\shim`.
- `Native\Import.ps1` fetches a libxml2/libxslt release from the GNOME mirrors on GitHub,
  `Native\Build.ps1` builds the objects with `-O3` for the x86-64 baseline (SSE2, no
  `-march`), checks that every unresolved symbol is covered, regenerates `LX2.Static.pas`
  and runs a smoke test. See `Native\README.md`.
- `LX2Lib` and `XSLTLib` gained a `StaticBinder` hook; `IsLoaded` now reflects the state
  (it was never set before); `Unload` works in both modes.

### Bundled libraries

- libxml2 2.15.4 (was 2.14.4), libxslt 1.1.45 (was 1.1.43). The bindings target the
  libxml2 2.15 API; the version series is pinned in `Native\Import.ps1`.
- Linux64 keeps the shared libraries in `Binaries\Linux64` (`libxml2.so.16`,
  `libxslt.so`); most distributions ship an older libxml2 with the `.so.2` soname that LX2
  cannot use, so deploy the bundled files with the application.

### Library changes since v0.9-beta.1

- Own XPath engine for simple location paths that ignores namespaces, the way MSXML does;
  everything else still goes to the libxml2 evaluator.
- Validation over several schema files (`IXMLSchemaCollection`), and a check against
  adding a schema collection to itself.
- Transformation results are converted to the default encoding when the stylesheet output
  is not UTF-8.
- SAX parser error handling; callbacks return defaults when an error occurs.
- Memory leak on `RemoveChild` fixed; an unneeded namespace release removed.
- `xsltSetGenericErrorFunc` was looked up under a misspelt name and stayed unassigned in
  DLL mode; fixed.
- Assorted bug and performance fixes in the helpers and the DOM classes.

### Repository

- `README.md` rewritten: layers, examples for the helpers, the DOM and SAX, static
  linking, encodings, error handling, updating the libraries.
- `Samples` removed; the README examples and the DUnitX suite in `Tests` cover the same
  ground.
- `Binaries\Win64` removed (see above).

### Upgrading

1. Add `LX2.Static` to the uses clause of every executable (or install the package).
2. Stop deploying `libxml2.dll` and `libxslt.dll`.
3. To keep loading a DLL instead, leave `LX2.Static` out and call `LX2Lib.Load` as before;
   the DLL must be libxml2 2.14 or later.

### Requirements

Delphi 10.3 Rio or later (developed with Delphi 13.1); Windows x64 with static linking,
Windows x64 or Linux64 with a shared library. Win32 compiles but is not tested.

## v0.9-beta.1 — 2025-07-18

First public release: raw API bindings with late binding, record helpers, SAX and DOM
layers, prebuilt libxml2/libxslt for Win64 and Linux64.
