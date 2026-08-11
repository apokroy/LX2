(*
MIT License
Copyright (c) 2025 Alexey Pokroy

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is fur-
nished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FIT-
NESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*)

/// <summary>
/// A small set of commonly used low-level types, exceptions and string/byte
/// conversion helper functions shared across the LX2 libxml2 binding layer.
/// </summary>
/// <remarks>
/// This unit sits on the hottest code path of the library: virtually every
/// node/attribute/text access in <c>LX2.Helpers.pas</c> funnels through the
/// <c>xmlCharTo*</c>/<c>SplitXMLName</c>/<c>xmlStrSame</c> functions declared
/// here. Accordingly, several functions in this unit bypass standard RTL
/// string-construction paths (<c>SetString</c>, <c>UTF8ToUnicodeString</c>)
/// in favor of hand-rolled string allocation (<see cref="NewUtf16String"/>,
/// <see cref="NewRawString"/>, <see cref="NewUtf8String"/>) and SIMD-style
/// (SWAR) byte scanning, in order to avoid redundant passes over the same
/// buffer. See individual function remarks for details and caveats.
/// </remarks>
unit LX2.Types;

interface

{$ALIGN 8}

uses
  {$IFDEF MSWINDOWS}
   Winapi.Windows,
  {$ELSE}
  Posix.Pthread,
  {$ENDIF}
  System.SysUtils,
  libxml2.API;

type
  /// <summary>Legacy MSXML compatibility mode selector (currently informational).</summary>
  TXmlCompatibility = (
    xmlDefault,
    xmlMsXml3,
    xmlMsXml6
  );

  /// <summary>
  /// One-to-one Pascal enum mirror of libxml2's <c>XML_PARSE_*</c> bit flags,
  /// intended to be combined into a <see cref="TXmlParserOptions"/> set and
  /// converted to the native integer bitmask via <see cref="XmlParserOptions"/>.
  /// </summary>
  TXmlParserOption = (
    xmlParseSubstituteEntity,
    xmlParseExternalDTD,
    xmlParseDTDAttrs,
    xmlParseDTDValidation,
    xmlParseNoErrors,
    xmlParseNoWarnings,
    xmlParsePedantic,
    xmlParseXInclude,
    xmlParseNoDict,
    xmlParseNSClean,
    xmlParseNoCDATA,
    xmlParseNoXInclude,
    xmlParseNoBasePrefix,
    xmlParseHuge,
    xmlParseIgnoreEncoding,
    xmlParseNoXXE,
    xmlParseUnzip,
    xmlParseNoSysCatalog,
    xmlParseNoCatalogPI,
    xmlParseBigLines
  );

  TXmlParserOptions = set of TXmlParserOption;

  /// <summary>
  /// One-to-one Pascal enum mirror of libxml2's <c>XML_SAVE_*</c> bit flags,
  /// converted to the native integer bitmask via <see cref="XmlSaveOptions"/>.
  /// </summary>
  TXmlSaveOption = (
   xmlSaveFormat,
   xmlSaveNoDecl,
   xmlSaveNoEmpty,
   xmlSaveNoXHTML,
   xmlSaveXHTML,
   xmlSaveAsXML,
   xmlSaveAsHTML,
   xmlSaveWSNONSIG,
   xmlSaveEmpty,
   xmlSaveNoIndent,
   xmlSaveIndent
  );

  TXmlSaveOptions = set of TXmlSaveOption;

  /// <summary>Canonicalization (C14N) algorithm variant, per the W3C XML-C14N specifications.</summary>
  TXmlC14NMode = (
    ///<summary>Original C14N 1.0 spec.</summary>
    xmlC14N,
    ///<summary>Exclusive C14N 1.0 spec.</summary>
    xmlC14NExclusive,
    ///<summary>C14N 1.1 spec.</summary>
    xmlC14N11
  );

const
  /// <summary>
  /// Reasonable default parser options for general-purpose document loading:
  /// substitutes entities, loads DTD attribute defaults, and relaxes libxml2's
  /// line-number/node-size limits (<c>xmlParseBigLines</c>, <c>xmlParseHuge</c>)
  /// to support large real-world documents without spurious errors.
  /// </summary>
  DefaultParserOptions = [xmlParseSubstituteEntity, xmlParseDTDAttrs, xmlParseBigLines, xmlParseHuge];

type
  TXmlParseErrors = class;

  /// <summary>Alias for libxml2's <c>xmlErrorLevel</c> enum (warning/error/fatal).</summary>
  TXmlErrorLevel = xmlErrorLevel;

  /// <summary>
  /// Immutable snapshot of a single libxml2 <c>xmlError</c> record, captured
  /// as plain Pascal types (decoded strings, not raw pointers) so it remains
  /// valid after the originating libxml2 error context is destroyed.
  /// </summary>
  TXmlParseError = record
  private
    FCode: Integer;
    FCol: Integer;
    FLine: Integer;
    FText: string;
    FUrl: string;
    FSource: string;
    FLevel: xmlErrorLevel;
  public
    /// <summary>Copies all relevant fields out of a raw libxml2 <c>xmlError</c> into this record.</summary>
    constructor Create(err: xmlError);
    /// <summary>libxml2 numeric error code (see <c>xmlParserErrors</c>).</summary>
    property Code: Integer read FCode;
    property Level: xmlErrorLevel read FLevel;
    /// <summary>Source URL/file of the document being parsed, if known.</summary>
    property Url: string read FUrl;
    /// <summary>Human-readable error message, decoded from UTF-8.</summary>
    property Text: string read FText;
    property Source: string read FSource;
    property Line: Integer read FLine;
    /// <summary>Column number (mapped from libxml2's <c>int2</c> field).</summary>
    property Col: Integer read FCol;
  end;

  /// <summary>Forward-only enumerator over a <see cref="TXmlParseErrors"/> collection, enabling <c>for..in</c> support.</summary>
  TXmlParseErrorEnumerator = class
  private
    FErrors: TXmlParseErrors;
    FIndex: NativeInt;
    function GetCurrent: TXmlParseError;
  public
    constructor Create(Errors: TXmlParseErrors);
    function MoveNext: Boolean; inline;
    property Current: TXmlParseError read GetCurrent;
  end;

  /// <summary>
  /// Accumulates <see cref="TXmlParseError"/> records collected during parsing
  /// or validation via an <c>xmlDocErrorHandler</c> callback.
  /// </summary>
  TXmlParseErrors = class
  private
    FList: TArray<TXmlParseError>;
    function  GetCount: NativeInt;
    function  GetItem(const Index: NativeInt): TXmlParseError;
  public
    constructor Create;
    function  Add(const error: xmlError): TXmlParseError;
    procedure Clear;
    function  GetEnumerator: TXmlParseErrorEnumerator;
    function  ToArray: TArray<TXmlParseError>;
    property  Count: NativeInt read GetCount;
    property  Items[const Index: NativeInt]: TXmlParseError read GetItem; default;
  end;

  /// <summary>Base class for all exceptions raised by the LX2 library.</summary>
  EXmlError = class(Exception)
  end;

  /// <summary>
  /// Raised for unexpected/internal failures in the underlying libxml2 call
  /// (e.g. negative size returned from a C14N dump) that do not correspond to
  /// a well-formed <c>xmlError</c> record. See <see cref="LX2InternalError"/>.
  /// </summary>
  EXmlInternalError = class(EXmlError)
  end;

  /// <summary>
  /// Raised (or made available for the caller to raise) when libxml2 reports
  /// a parsing/validation error; carries the same diagnostic fields as
  /// <see cref="TXmlParseError"/>.
  /// </summary>
  EXmlParserError = class(EXmlError)
  private
    FUrl: string;
    FLevel: xmlErrorLevel;
    FCode: Integer;
    FCol: Integer;
    FLine: Integer;
  public
    constructor Create(error: xmlError); overload;
    constructor Create(const Error: TXmlParseError); overload;
    property  Code: Integer read FCode;
    property  Level: xmlErrorLevel read FLevel;
    property  Url: string read FUrl;
    property  Line: Integer read FLine;
    property  Col: Integer read FCol;
  end;

  /// <summary>Raised when a requested namespace URI cannot be resolved/found on a node.</summary>
  EXmlNsHrefNotFound = class(EXmlError)
  public
    constructor Create(const URI: string);
  end;

  /// <summary>Raised when an operation is invoked on a node kind that does not support it (e.g. mutating a namespace declaration node).</summary>
  EXmlUnsupported = class(EXmlError)
  end;

  /// <summary>
  /// Immutable pair of (local) Name and Namespace URI, analogous to
  /// <c>System.Xml.XmlQualifiedName</c> in .NET — used as a value type for
  /// comparing/passing around qualified names without a live libxml2 node.
  /// </summary>
  XmlQualifiedName = record
  private
    FName: string;
    FNamespace: string;
  public
    constructor Create(const Name: string); overload;
    constructor Create(const Name, Namespace: string); overload;
    function IsEmpty: Boolean; inline;
    function ToString: string; overload; inline;
    property Name: string read FName;
    property Namespace: string read FNamespace;
  public
    class function ToString(const Name, Namespace: string): string; overload; static;
    class operator Equal(const L, R: XmlQualifiedName): Boolean; static; inline;
    class operator NotEqual(const L, R: XmlQualifiedName): Boolean; static; inline;
  end;

  /// <summary>
  /// Well-known reserved XML/XSD/XSLT/EXSLT namespace URI constants, mirroring
  /// <c>System.Xml.XmlReservedNs</c> in .NET for convenient reference when
  /// building or querying documents that use these standard namespaces.
  /// </summary>
  XmlReservedNs = class
  public const
    NsXml             = 'http://www.w3.org/XML/1998/namespace';
    NsXmlNs           = 'http://www.w3.org/2000/xmlns/';
    NsDataType        = 'urn:schemas-microsoft-com:datatypes';
    NsDataTypeAlias   = 'uuid:C2F41010-65B3-11D1-A29F-00AA00C14882';
    NsDataTypeOld     = 'urn:uuid:C2F41010-65B3-11D1-A29F-00AA00C14882/';
    NsXdrAlias        = 'uuid:BDC6E3F0-6DA3-11D1-A2A3-00AA00C14882';
    NsWdXsl           = 'http://www.w3.org/TR/WD-xsl';
    NsXs              = 'http://www.w3.org/2001/XMLSchema';
    NsXsd             = 'http://www.w3.org/2001/XMLSchema-datatypes';
    NsXsi             = 'http://www.w3.org/2001/XMLSchema-instance';
    NsXslt            = 'http://www.w3.org/1999/XSL/Transform';
    NsExsltCommon     = 'http://exslt.org/common';
    NsExsltDates      = 'http://exslt.org/dates-and-times';
    NsExsltMath       = 'http://exslt.org/math';
    NsExsltRegExps    = 'http://exslt.org/regular-expressions';
    NsExsltSets       = 'http://exslt.org/sets';
    NsExsltStrings    = 'http://exslt.org/strings';
    NsXQueryFunc      = 'http://www.w3.org/2003/11/xpath-functions';
    NsXQueryDataType  = 'http://www.w3.org/2003/11/xpath-datatypes';
    NsCollationBase   = 'http://collations.microsoft.com';
    NsCollCodePoint   = 'http://www.w3.org/2004/10/xpath-functions/collation/codepoint';
  end;

/// <summary>
/// XML-escapes special characters (<c>&amp; &lt; &gt; " '</c>) in a raw byte
/// (UTF-8) string, using libxml2's own encoder.
/// </summary>
/// <remarks>
/// Uses <c>xmlEncodeSpecialChars</c> with a <c>nil</c> document context,
/// meaning the encoding rules applied are the generic/default ones rather
/// than any document-specific override.
/// </remarks>
function  xmlEscapeString(const Value: RawByteString): RawByteString;
/// <summary>
/// Collapses all XML whitespace (space, tab, LF, CR) runs to a single space
/// and trims leading/trailing whitespace, per XML attribute-value
/// normalization rules.
/// </summary>
/// <remarks>
/// Fast path: if the input contains no whitespace characters at all, the
/// original string reference is returned unchanged (no allocation, relying
/// on Delphi string copy-on-write semantics) — this is the common case for
/// most attribute/text values and avoids the cost of the full normalization
/// pass entirely.
/// </remarks>
function  xmlNormalizeString(const S: string): string;

/// <summary>
/// Compares two null-terminated UTF-8 strings for byte-exact equality.
/// </summary>
/// <remarks>
/// The initial <c>P1 = P2</c> pointer-identity check is not a defensive
/// no-op — libxml2 interns element/attribute/namespace names in a shared
/// string dictionary (<c>xmlDict</c>) per document, so two equal names
/// originating from the same document very frequently share the same
/// physical pointer. This check turns the majority of real-world calls
/// (e.g. tag-name matching during <c>GetElementsByTagName</c>/XPath) into
/// an O(1) pointer comparison, entirely skipping the byte-by-byte loop
/// below. Do not remove this check as a "simplification".
/// </remarks>
function  xmlStrSame(P1, P2: xmlCharPtr): Boolean;

/// <summary>Returns a raw <c>xmlCharPtr</c> view into a <c>RawByteString</c>'s existing buffer, or <c>nil</c> for an empty string.</summary>
/// <remarks>Does not copy or allocate; the returned pointer is only valid as long as <paramref name="S"/> is alive and not reallocated (COW).</remarks>
function  xmlStrPtr(const S: RawByteString): xmlCharPtr; inline;

/// <summary>Decodes a null-terminated UTF-8 <c>xmlCharPtr</c> into a Unicode <c>string</c>.</summary>
/// <remarks>
/// Performs a single combined pass via <see cref="Utf8toUtf16CountAndLen"/>
/// to obtain both the byte length and the UTF-16 code unit count, then a
/// second pass for the actual conversion (<c>UnicodeFromLocaleChars</c>) —
/// this avoids the separate <c>Length(xmlCharPtr)</c> (strlen) pass that a
/// naive implementation would otherwise require.
/// </remarks>
function  xmlCharToStr(const S: xmlCharPtr): string; overload; inline;

/// <summary>Decodes a null-terminated UTF-8 <c>xmlCharPtr</c> into a Unicode string, then frees the source pointer via <c>xmlFree</c>.</summary>
/// <remarks>Intended for libxml2 APIs that return caller-owned allocated strings (e.g. <c>xmlNodeGetContent</c>, <c>xmlGetProp</c>).</remarks>
function  xmlCharToStrAndFree(const S: xmlCharPtr): string; overload;inline;

/// <summary>Decodes a UTF-8 buffer of known byte length into a Unicode string (no strlen scan needed).</summary>
function  xmlCharToStr(const S: xmlCharPtr; Len: NativeUInt): string; overload;

/// <summary>
/// Wraps a null-terminated UTF-8 <c>xmlCharPtr</c> as a <c>RawByteString</c>
/// tagged with the UTF-8 code page (via <see cref="NewUtf8String"/>), copying
/// the bytes without any encoding conversion.
/// </summary>
/// <remarks>Length is computed via <see cref="xmlStrLen"/> (RTL <c>StrLen</c>), not the two-pass UTF-16 counting path used by <see cref="xmlCharToStr"/>.</remarks>
function  xmlCharToRaw(const S: xmlCharPtr): RawByteString; overload; inline;

/// <summary>Wraps a UTF-8 buffer of known byte length as a <c>RawByteString</c> (CP_UTF8), copying the bytes.</summary>
function  xmlCharToRaw(const S: xmlCharPtr; Len: NativeUInt): RawByteString; overload;

/// <summary>Wraps a UTF-8 <c>xmlCharPtr</c> as a <c>RawByteString</c>, then frees the source via <c>xmlFree</c>.</summary>
function  xmlCharToRawAndFree(const S: xmlCharPtr): RawByteString; inline;

/// <summary>
/// Builds a colon-joined qualified name ("prefix:local") as a UTF-8-tagged
/// <c>RawByteString</c>, without going through an intermediate
/// <c>xmlCharToRaw</c> concatenation.
/// </summary>
/// <remarks>
/// Manually computes byte lengths of <paramref name="Prefix"/> and
/// <paramref name="Name"/> via inline strlen loops (avoiding a redundant
/// <c>Length()</c> call on an <c>xmlCharPtr</c>), then allocates the exact
/// combined buffer once via <see cref="NewUtf8String"/> and fills it with
/// two <c>Move</c> calls plus the colon separator — a single allocation
/// instead of string concatenation's intermediate temporaries.
/// </remarks>
/// <param name="Prefix">Namespace prefix, or <c>nil</c>/empty for no prefix.</param>
/// <param name="Name">Local element/attribute name.</param>
function  xmlQName(const Prefix, Name: xmlCharPtr): RawByteString;

/// <summary>
/// Splits a possibly-qualified XML name ("prefix:local") into its prefix
/// and local-name parts (Unicode string overload).
/// </summary>
/// <param name="Name">Input name, e.g. "soap:Envelope" or "Envelope".</param>
/// <param name="Prefix">Receives the prefix, or empty string if unqualified.</param>
/// <param name="LocalName">
/// Receives the local part after the colon if a colon is found; otherwise
/// receives the ENTIRE input <paramref name="Name"/> unchanged (this is the
/// documented behavior relied upon throughout <c>LX2.Helpers.pas</c> for
/// unqualified names — callers must not assume <c>LocalName</c> is empty
/// when <c>Result = False</c>).
/// </param>
/// <returns><c>True</c> if a colon separator was found (name is qualified); <c>False</c> otherwise.</returns>
function  SplitXMLName(const Name: string; out Prefix, LocalName: string): Boolean; overload;
function  SplitXMLName(const Name: RawByteString; out Prefix, LocalName: RawByteString): Boolean; overload;

/// <summary>Returns the human-readable name of an <c>xmlElementType</c> value (e.g. "element", "attribute", "comment"), or "unknown" for out-of-range values.</summary>
function  NodeTypeName(nodeType: xmlElementType): string;

/// <summary>
/// Counts the number of UTF-16 code units required to represent a UTF-8
/// buffer of known byte length <paramref name="Size"/>.
/// </summary>
/// <remarks>
/// Uses an 8-byte-at-a-time fast path: while a 64-bit word read from the
/// buffer has no byte with its high bit set (i.e. all 8 bytes are plain
/// ASCII, <c>$8080808080808080</c> mask test), 8 UTF-16 code units are
/// counted in one step. This is a classic SWAR (SIMD Within A Register)
/// technique and is safe here because <paramref name="Size"/> is known in
/// advance, so the loop bound <c>I + 8 &lt;= Size</c> guarantees no
/// out-of-bounds read. Falls back to the byte-by-byte
/// <see cref="Utf8L"/>-table lookup for the remaining tail and for any
/// non-ASCII run.
/// </remarks>
function  Utf8toUtf16Count(Input: PUtf8Char; Size: NativeUInt): NativeUInt; overload;

/// <summary>
/// Null-terminated-buffer counterpart of <see cref="Utf8toUtf16Count(PUtf8Char,NativeUInt)"/>;
/// scans until a <c>#0</c> byte is found instead of a known length.
/// </summary>
/// <remarks>
/// Currently uses only the byte-by-byte <see cref="Utf8L"/> table lookup
/// (no 8-byte SWAR fast path), because a naive high-bit-only block test
/// cannot distinguish "8 ASCII bytes" from "a shorter ASCII run followed by
/// the terminator and out-of-bounds memory" — a safe block fast path here
/// would additionally require a zero-byte-detection test
/// (<c>(w - $0101010101010101) and not w and $8080808080808080</c>) before
/// it could be applied to null-terminated input.
/// </remarks>
function  Utf8toUtf16Count(Input: PUtf8Char): NativeUInt; overload;

/// <summary>
/// Combined single-pass equivalent of "<c>strlen</c> + UTF-8→UTF-16 code-unit
/// counting" for a null-terminated UTF-8 buffer, using an 8-byte-at-a-time
/// SWAR (SIMD Within A Register) fast path for runs of plain ASCII.
/// </summary>
/// <param name="Input">Null-terminated UTF-8 buffer.</param>
/// <param name="ByteLen">
/// Receives the byte length of the string up to (but excluding) the
/// terminating <c>#0</c> — equivalent to what <c>StrLen(PAnsiChar(Input))</c>
/// would return.
/// </param>
/// <returns>
/// The number of UTF-16 code units required to represent the string
/// (equivalent to what <c>Utf8toUtf16Count(Input)</c> would return, but
/// computed together with <paramref name="ByteLen"/> in one combined scan).
/// </returns>
/// <remarks>
/// <para>
/// <b>Why this exists:</b> the straightforward way to get both values is to
/// call <c>Length(xmlCharPtr)</c> (which performs a full <c>strlen</c> scan)
/// and then <c>Utf8toUtf16Count(S, Len)</c> (a second full scan) — two
/// complete passes over the same bytes. This function performs both in a
/// single pass, which matters because it backs <c>xmlCharToStr(xmlCharPtr)</c>,
/// one of the hottest functions in the library (called for every text node
/// and attribute value materialized into a Delphi <c>string</c>).
/// </para>
/// <para>
/// <b>Fast path algorithm (block of 8 bytes at a time):</b>
/// <list type="number">
/// <item><description>
/// Load 8 bytes as a single <c>UInt64</c> and test
/// <c>W and $8080808080808080</c>. If non-zero, at least one byte in the
/// block has its high bit set (i.e. is part of a multi-byte UTF-8 sequence)
/// — fall through to the byte-by-byte slow path for this and all
/// subsequent bytes.
/// </description></item>
/// <item><description>
/// Otherwise all 8 bytes are candidate ASCII (0..127), including possibly
/// the NUL terminator (which is also &lt;= 127). Apply the classic SWAR
/// "has a zero byte in this word" test:
/// <c>(W - $0101010101010101) and (not W) and $8080808080808080</c>.
/// A non-zero result means at least one of the 8 bytes is <c>#0</c> —
/// fall through to the slow path so the exact terminator position is
/// found precisely.
/// </description></item>
/// <item><description>
/// If neither condition triggered, all 8 bytes are non-zero ASCII: count
/// 8 UTF-16 code units (1 UTF-16 unit per ASCII byte) and advance 8 bytes,
/// then repeat.
/// </description></item>
/// </list>
/// This is the same class of technique used by other optimized Pascal
/// UTF-8 conversion routines that deliberately bypass the standard RTL
/// conversion path for speed, e.g. <c>Neslib.Utf8</c>
/// (<see href="https://github.com/neslib/Neslib/blob/master/Neslib.Utf8.pas">github.com</see>,
/// whose header explicitly notes these routines "are optimized for speed
/// and don't perform any error checking") and mORMot 2's
/// <c>mormot.core.unicode.pas</c>
/// (<see href="https://github.com/synopse/mORMot2/blob/master/src/core/mormot.core.unicode.pas">github.com</see>),
/// both of which hand-roll UTF-8/UTF-16 conversion instead of relying on
/// the OS/RTL conversion API for the same reason: avoiding redundant
/// full-buffer passes and generic-path overhead.
/// </para>
/// <para>
/// <b>Correctness note — why the ASCII-only fast path is safe for code-unit
/// counting:</b> a codepoint requires 1 UTF-16 code unit for every leading
/// UTF-8 byte that is NOT a continuation byte, which for pure ASCII
/// (bytes 0..127) is simply "1 code unit per byte" — this matches the
/// classic byte-counting relationship between UTF-8 and UTF-16 lengths for
/// the Basic Multilingual Plane, as discussed in general treatments of
/// UTF-8↔UTF-16 length/counting algorithms
/// (<see href="https://stackoverflow.com/questions/5728045/c-most-efficient-way-to-determine-how-many-bytes-will-be-needed-for-a-utf-16-st">stackoverflow.com</see>,
/// <see href="https://stackoverflow.com/questions/73758747/looking-for-the-description-of-the-algorithm-to-convert-utf8-to-utf16">stackoverflow.com</see>).
/// For any block containing a non-ASCII (multi-byte) leading or
/// continuation byte, this function deliberately gives up the fast path
/// and defers to the exact per-byte <c>Utf8L</c> table lookup below, which
/// correctly accounts for 2/3/4-byte sequences collapsing to 1 (or, for
/// astral/surrogate-pair codepoints via 4-byte UTF-8 sequences, 2) UTF-16
/// code units — see also reference UTF-8→UTF-16 counting/conversion
/// implementations such as Google's Protobuf
/// <c>utf8_to_utf16/naive.c</c>
/// (<see href="https://fossies.org/linux/protobuf/third_party/utf8_range/utf8_to_utf16/naive.c">fossies.org</see>)
/// for the general (non-SWAR) per-codepoint algorithm this fast path
/// short-circuits for the common ASCII case.
/// </para>
/// <para>
/// <b>No error checking:</b> like the fast Pascal implementations cited
/// above, this function assumes well-formed UTF-8 input and performs no
/// validation of continuation-byte structure or overlong encodings —
/// malformed input will silently produce an incorrect (but not
/// out-of-bounds, within the slow path) result rather than raise an error.
/// </para>
/// <para>
/// <b>⚠ Potential over-read caveat:</b> the fast-path block read
/// (<c>PUInt64(@Input[I])^</c>) always reads a full 8 bytes starting at
/// <c>I</c>, even when fewer than 8 valid bytes remain before the string's
/// terminator. This is safe with respect to the STRING'S logical content
/// (the zero-detection test above guarantees the loop stops at or before
/// the block containing the terminator), but it does read up to 7 bytes
/// PAST the terminator's position into whatever memory follows it in the
/// underlying allocation. For strings whose backing buffer is not padded
/// with at least 7 extra bytes past the terminator, this is technically an
/// out-of-bounds read of the allocation (though in practice harmless for
/// heap allocations with page/granule-sized rounding, as libxml2 buffers
/// typically are). Libraries taking this same trade-off, such as
/// <c>Neslib.Utf8</c>
/// (<see href="https://github.com/neslib/Neslib/blob/master/Neslib.Utf8.pas">github.com</see>),
/// accept it in exchange for speed; if this function is ever applied to
/// buffers from an untrusted or tightly-bounded source (e.g. a memory-mapped
/// file with no trailing slack), this fast path should be disabled or
/// bounded by a known buffer end pointer.
/// </para>
/// </remarks>
function  Utf8toUtf16CountAndLen(Input: PUtf8Char; out ByteLen: NativeUInt): NativeUInt;

/// <summary>Converts a <see cref="TXmlParserOptions"/> set into libxml2's native <c>XML_PARSE_*</c> integer bitmask.</summary>
function  XmlParserOptions(Options: TXmlParserOptions): Integer;

/// <summary>Converts a <see cref="TXmlSaveOptions"/> set into libxml2's native <c>XML_SAVE_*</c> integer bitmask.</summary>
function  XmlSaveOptions(Options: TxmlSaveOptions): Integer;

/// <summary>
/// Raises <see cref="EXmlInternalError"/> to signal an unexpected failure
/// from a libxml2 call that does not itself produce a structured
/// <c>xmlError</c> (e.g. a negative return size from a C14N dump).
/// </summary>
/// <remarks>Uses <c>at ReturnAddress</c> so the raised exception's call stack points at the actual failing call site rather than at this helper.</remarks>
procedure LX2InternalError;

const
  UTF16_STR_INIT: UInt64 = (UInt64(1) shl 32) or (UInt64(SizeOf(WideChar)) shl 16) or 1200;
  RAW_STR_INIT:   UInt64 = (UInt64(1) shl 32) or (UInt64(SizeOf(AnsiChar)) shl 16) or $FFFF;
  UTF8_STR_INIT:  UInt64 = (UInt64(1) shl 32) or (UInt64(SizeOf(AnsiChar)) shl 16) or 65001;

procedure NewUtf16String(out Result: Pointer; Len: NativeInt); overload; inline;
procedure NewUtf16String(out Result: Pointer; Len: NativeInt; const Data: Pointer); overload; inline;
procedure NewRawString(out Result: Pointer; Len: NativeInt); overload; inline;
procedure NewRawString(out Result: Pointer; Len: NativeInt; const Data: Pointer); overload; inline;
procedure NewUtf8String(out Result: Pointer; Len: NativeInt); overload; inline;
procedure NewUtf8String(out Result: Pointer; Len: NativeInt; const Data: Pointer); overload; inline;

resourcestring
  SXmlNsHrefNotFound     = 'Namespace with URI "%s" not found';
  SUnsupportedByAttrDecl = 'Operation unsupported by namespace declarations';
  SUnsupportedBy         = 'Operation unsupported by %s';

implementation

type
  PStrRec = ^StrRec;
  StrRec = packed record
  {$IF defined(CPU64BITS)}
    _Padding: Integer; // Make 16 byte align for payload..
  {$ENDIF}
    codePage: Word;
    elemSize: Word;
    refCnt: Integer;
    length: Integer;
  end;
  PInitStrRec = ^InitStrRec;
  InitStrRec = packed record
  {$IF defined(CPU64BITS)}
    _Padding: Integer;
  {$ENDIF}
    Init: UInt64;
    length: Integer;
  end;

procedure NewUtf16String(out Result: Pointer; Len: NativeInt); overload; inline;
var
  P: PStrRec;
begin
  GetMem(P, SizeOf(StrRec) + (Len + 1) * SizeOf(WideChar));
  Result := Pointer(PByte(P) + SizeOf(StrRec));
  P.length := Len;
  InitStrRec(P^).Init := UTF16_STR_INIT;
  PWideChar(Result)[Len] := #0;
end;

procedure NewUtf16String(out Result: Pointer; Len: NativeInt; const Data: Pointer); overload; inline;
var
  P: PStrRec;
begin
  GetMem(P, SizeOf(StrRec) + (Len + 1) * SizeOf(WideChar));
  Result := Pointer(PByte(P) + SizeOf(StrRec));
  P.length := Len;
  InitStrRec(P^).Init := UTF16_STR_INIT;
  PWideChar(Result)[Len] := #0;
  Move(Data^, Result^, Len * SizeOf(WideChar));
end;

procedure NewRawString(out Result: Pointer; Len: NativeInt); overload; inline;
var
  P: PStrRec;
begin
  GetMem(P, SizeOf(StrRec) + (Len + 1) * SizeOf(AnsiChar));
  Result := Pointer(PByte(P) + SizeOf(StrRec));
  P.length := Len;
  InitStrRec(P^).Init := RAW_STR_INIT;
  PAnsiChar(Result)[Len] := #0;
end;

procedure NewRawString(out Result: Pointer; Len: NativeInt; const Data: Pointer); overload; inline;
var
  P: PStrRec;
begin
  GetMem(P, SizeOf(StrRec) + (Len + 1) * SizeOf(AnsiChar));
  Result := Pointer(PByte(P) + SizeOf(StrRec));
  P.length := Len;
  InitStrRec(P^).Init := RAW_STR_INIT;
  PAnsiChar(Result)[Len] := #0;
  Move(Data^, Result^, Len);
end;

procedure NewUtf8String(out Result: Pointer; Len: NativeInt); overload; inline;
var
  P: PStrRec;
begin
  GetMem(P, SizeOf(StrRec) + (Len + 1) * SizeOf(AnsiChar));
  Result := Pointer(PByte(P) + SizeOf(StrRec));
  P.length := Len;
  InitStrRec(P^).Init := UTF8_STR_INIT;
  PAnsiChar(Result)[Len] := #0;
end;

procedure NewUtf8String(out Result: Pointer; Len: NativeInt; const Data: Pointer); overload; inline;
var
  P: PStrRec;
begin
  GetMem(P, SizeOf(StrRec) + (Len + 1) * SizeOf(AnsiChar));
  Result := Pointer(PByte(P) + SizeOf(StrRec));
  P.length := Len;
  InitStrRec(P^).Init := UTF8_STR_INIT;
  PAnsiChar(Result)[Len] := #0;
  Move(Data^, Result^, Len);
end;

const
  /// <summary>
  /// UTF-8 leading-byte length table: number of bytes in a UTF-8 sequence
  /// starting with a given byte value (1 for ASCII/continuation bytes,
  /// 2/3/4 for multi-byte sequence leaders per RFC 3629).
  /// </summary>
  Utf8L: array[AnsiChar] of NativeUInt = (
{         0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F }
{   0 }   1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
{   1 }   1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
{   2 }   1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
{   3 }   1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
{   4 }   1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
{   5 }   1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
{   6 }   1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
{   7 }   1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2,
{   8 }   1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
{   9 }   1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
{   A }   1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
{   B }   1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
{   C }   2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
{   D }   2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
{   E }   3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
{   F }   4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4);

function Utf8toUtf16Count(Input: PUtf8Char; Size: NativeUInt): NativeUInt;
var
  I: NativeUInt;
begin
  Result := 0;
  I := 0;

  while (I + 8 <= Size) and (PUInt64(@Input[I])^ and $8080808080808080 = 0) do
  begin
    Inc(Result, 8);
    Inc(I, 8);
  end;

  while I < Size do
  begin
    Inc(I, Utf8L[Input[I]]);
    Inc(Result);
  end;
end;

function Utf8toUtf16Count(Input: PUtf8Char): NativeUInt;
begin
  Result := 0;
  var I: NativeUInt := 0;

  while Input[I] <> #0 do
  begin
    Inc(I, Utf8L[Input[I]]);
    Inc(Result);
  end;
end;

function Utf8toUtf16CountAndLen(Input: PUtf8Char; out ByteLen: NativeUInt): NativeUInt;
begin
  Result := 0;
  var I: NativeUInt := 0;

  while True do
  begin
    var W := PUInt64(@Input[I])^;
    if (W and $8080808080808080 <> 0) then
      Break;

    var HasZero := (W - UInt64($0101010101010101)) and (not W) and UInt64($8080808080808080);
    if HasZero <> 0 then
      Break;

    Inc(Result, 8);
    Inc(I, 8);
  end;

  while Input[I] <> #0 do
  begin
    Inc(I, Utf8L[Input[I]]);
    Inc(Result);
  end;
  ByteLen := I;
end;

/// <summary>
/// Fast byte-length (strlen) computation for a null-terminated UTF-8/ANSI
/// buffer, used instead of relying on the compiler-generated <c>Length()</c>
/// intrinsic for <c>PAnsiChar</c>-compatible pointers.
/// </summary>
function xmlStrLen(S: xmlCharPtr): NativeUInt; inline;
begin
  Result := System.SysUtils.StrLen(PAnsiChar(S));
end;

function xmlStrPtr(const S: RawByteString): xmlCharPtr;
begin
  if Length(S) = 0 then
    Result := nil
  else
    Result := Pointer(S);
end;

function xmlCharToStr(const S: xmlCharPtr): string;
begin
  if S = nil then
    Exit('');
  var ByteLen: NativeUInt;
  var L := Utf8toUtf16CountAndLen(S, ByteLen);
  if L = 0 then
    Exit('');
  NewUtf16String(Pointer(Result), L);
  UnicodeFromLocaleChars(CP_UTF8, 0, S, ByteLen, Pointer(Result), L);
end;

function xmlCharToStr(const S: xmlCharPtr; Len: NativeUInt): string;
begin
  var L := Utf8toUtf16Count(S, Len);
  if L = 0 then
    Exit('');

  NewUtf16String(Pointer(Result), L);
  UnicodeFromLocaleChars(CP_UTF8, 0, S, Len, Pointer(Result), L);
 end;

function xmlCharToRaw(const S: xmlCharPtr; Len: NativeUInt): RawByteString;
begin
  if Len = 0 then
    Exit('');

  NewUtf8String(Pointer(Result), Len, S);
end;

function xmlCharToRaw(const S: xmlCharPtr): RawByteString;
begin
  if S = nil then
    Exit('');
  Result := xmlCharToRaw(S, xmlStrLen(S));
end;

function xmlCharToRawAndFree(const S: xmlCharPtr): RawByteString;
begin
  if S = nil then
    Exit('');
  Result := xmlCharToRaw(S);
  xmlFree(S);
end;

function xmlCharToStrAndFree(const S: xmlCharPtr): string;
begin
  if S = nil then
    Exit('');
  Result := xmlCharToStr(S);
  xmlFree(S);
end;

function xmlQName(const Prefix, Name: xmlCharPtr): RawByteString;
begin
  if prefix = nil then
    Exit(xmlCharToRaw(Name));

  var L1 := 0;
  while Prefix[L1] <> #0 do
    Inc(L1);

  if L1 = 0 then
    Exit(xmlCharToRaw(Name));

  var L2 := 0;
  while Name[L2] <> #0 do
    Inc(L2);

  NewUtf8String(Pointer(Result), L1 + L2 + 1);
  Move(Prefix^, Pointer(Result)^, L1);
  Result[L1 + 1] := ':';
  Move(Name^, (PByte(Result) + L1 + 1)^, L2);
end;

function SplitXMLName(const Name: string; out Prefix, LocalName: string): Boolean;
begin
  var P := PChar(Pointer(Name));
  var L := Length(Name);
  for var I := 0 to L - 1 do
    if P[I] = ':' then
    begin
      NewUtf16String(Pointer(Prefix), I, P);
      NewUtf16String(Pointer(LocalName), L - I - 1, PChar(@P[I + 1]));
      Exit(True);
    end;
  LocalName := Name;
  Result := False;
end;

function SplitXMLName(const Name: RawByteString; out Prefix, LocalName: RawByteString): Boolean;
begin
  var P := PAnsiChar(Pointer(Name));
  var L := Length(Name);
  for var I := 0 to L - 1 do
    if P[I] = ':' then
    begin
      NewRawString(Pointer(Prefix), I, P);
      NewRawString(Pointer(LocalName), L - I - 1, PAnsiChar(@P[I + 1]));
      Exit(True);
    end;
  LocalName := Name;
  Result := False;
end;

function xmlEscapeString(const Value: RawByteString): RawByteString;
begin
  var Escaped := xmlEncodeSpecialChars(nil, Pointer(Value));
  NewUtf8String(Pointer(Result), Length(Escaped), Escaped);
  XmlFree(Escaped);
end;

function xmlNormalizeString(const S: string): string;
label
  HasSpaces;
begin
  // Most cases
  if S = '' then
    Exit('');
  var Src := PWord(Pointer(S));
  while Src^ <> 0 do
  begin
    if (Src^ = 32) or (Src^ = 9) or (Src^ = 10) or (Src^ = 13)  then
      goto HasSpaces;
    Inc(Src);
  end;
  Exit(S);

 HasSpaces:
  NewUtf16String(Pointer(Result), Length(S));
  Src := PWord(Pointer(S));
  var Dst := PWord(Pointer(Result));
  while (Src^ = 32) or (Src^ = 9) or (Src^ = 10) or (Src^ = 13)  do
    Inc(Src);

  var L := 0;
  while Src^ <> 0 do
  begin
    if (Src^ = 32) or (Src^ = 9) or (Src^ = 10) or (Src^ = 13) then
    begin
      Dst^ := 32;
      Inc(Src);
      Inc(Dst);
      Inc(L);
      while (Src^ = 32) or (Src^ = 9) or (Src^ = 10) or (Src^ = 13) do
        Inc(Src);
      if Src^ = 0 then
        Break;
    end;
    Dst^ := Src^;
    Inc(Src);
    Inc(Dst);
    Inc(L);
  end;
  Dec(Dst);
  while (Dst^ = 32) and (L > 0) do
  begin
    Dec(Dst);
    Dec(L);
  end;
  SetLength(Result, L);
end;

function NodeTypeName(nodeType: xmlElementType): string;
const
  NodeTypeNames: array[xmlElementType] of string = ('Unknown',
    'element', 'attribute', 'text', 'cdatasection', 'entityreference', 'entity', 'processinginstruction',
    'comment', 'document', 'documenttype', 'documentfragment', 'notation', 'html', 'dtd', 'elementdeclaration',
    'attributedeclaration', 'entitydeclaration', 'namespacedeclaration', 'xincludestart', 'xincludeend');
begin
  if (NodeType >= Low(xmlElementType)) and (NodeType <= High(xmlElementType)) then
    Result := NodeTypeNames[nodeType]
  else
    Result := 'unknown';
end;

procedure LX2InternalError;
begin
  raise EXmlInternalError.Create('libxml2 internal error') at ReturnAddress;
end;

function xmlStrSame(P1, P2: xmlCharPtr): Boolean;
begin
  if P1 = P2 then   // <-- critical, libxml2 inetrens string in dict
    Exit(True);

  while True do
  begin
    Result := P1^ = P2^;
    if not Result or (P1^ = #0) then
      Exit;
    Inc(P1);
    Inc(P2);
  end;
end;

function XmlParserOptions(Options: TXmlParserOptions): Integer;
const
  Values: array[TXmlParserOption] of Integer = (
    XML_PARSE_NOENT,
    XML_PARSE_DTDLOAD,
    XML_PARSE_DTDATTR,
    XML_PARSE_DTDVALID,
    XML_PARSE_NOERROR,
    XML_PARSE_NOWARNING,
    XML_PARSE_PEDANTIC,
    XML_PARSE_XINCLUDE,
    XML_PARSE_NODICT,
    XML_PARSE_NSCLEAN,
    XML_PARSE_NOCDATA,
    XML_PARSE_NOXINCNODE,
    XML_PARSE_NOBASEFIX,
    XML_PARSE_HUGE,
    XML_PARSE_IGNORE_ENC,
    XML_PARSE_NO_XXE,
    XML_PARSE_UNZIP,
    XML_PARSE_NO_SYS_CATALOG,
    XML_PARSE_NO_CATALOG_PI,
    XML_PARSE_BIG_LINES
  );
begin
  Result := 0;
  for var Opt := Low(TXmlParserOption) to High(TXmlParserOption) do
    if Opt in Options then
      Result := Result or Values[Opt];
end;

function xmlSaveOptions(Options: TXmlSaveOptions): Integer;
const
  Values: array[TXmlSaveOption] of Integer = (
    XML_SAVE_FORMAT,
    XML_SAVE_NO_DECL,
    XML_SAVE_NO_EMPTY,
    XML_SAVE_NO_XHTML,
    XML_SAVE_XHTML,
    XML_SAVE_AS_XML,
    XML_SAVE_AS_HTML,
    XML_SAVE_WSNONSIG,
    XML_SAVE_EMPTY,
    XML_SAVE_NO_INDENT,
    XML_SAVE_INDENT
  );
begin
  Result := 0;
  for var Opt := Low(TXmlSaveOption) to High(TXmlSaveOption) do
    if Opt in Options then
      Result := Result or Values[Opt];
end;

{ TXmlParseErrorEnumerator }

constructor TXmlParseErrorEnumerator.Create(Errors: TXmlParseErrors);
begin
  FErrors := Errors;
  FIndex := -1;
end;

function TXmlParseErrorEnumerator.GetCurrent: TXmlParseError;
begin
  Result := FErrors.FList[FIndex];
end;

function TXmlParseErrorEnumerator.MoveNext: Boolean;
begin
  Inc(FIndex);
  Result := FIndex < Length(FErrors.FList);
end;

{ TXmlParseErrors }

constructor TXmlParseErrors.Create;
begin
  inherited Create;
end;

function TXmlParseErrors.Add(const error: xmlError): TXmlParseError;
begin
  Result := TXmlParseError.Create(error);

  FList := FList + [Result];
end;

procedure TXmlParseErrors.Clear;
begin
  SetLength(FList, 0);
end;

function TXmlParseErrors.GetCount: NativeInt;
begin
  Result := Length(FList);
end;

function TXmlParseErrors.GetEnumerator: TXmlParseErrorEnumerator;
begin
  Result := TXmlParseErrorEnumerator.Create(Self);
end;

function TXmlParseErrors.GetItem(const Index: NativeInt): TXmlParseError;
begin
  Result := FList[Index];
end;

function TXmlParseErrors.ToArray: TArray<TXmlParseError>;
begin
  Result := FList;
end;

{ TXmlParseError }

constructor TXmlParseError.Create(err: xmlError);
begin
  FCode   := err.code;
  FText   := UTF8ToUnicodeString(err.message);
  FLevel  := err.level;
  FUrl    := UTF8ToUnicodeString(err.&file);
  FLine   := err.line;
  FCol    := err.int2;
end;

{ EXmlParserError }

constructor EXmlParserError.Create(error: xmlError);
begin
  inherited Create(UTF8ToUnicodeString(error.message));
  FCode   := error.code;
  FLevel  := error.level;
  FUrl    := UTF8ToUnicodeString(error.&file);
  FLine   := error.line;
  FCol    := error.int2;
end;

constructor EXmlParserError.Create(const Error: TXmlParseError);
begin
  inherited Create(Error.Text);
  FCode   := Error.code;
  FLevel  := Error.level;
  FUrl    := Error.Url;
  FLine   := Error.Line;
  FCol    := Error.Col;
end;

{ EXmlNsHrefNotFound }

constructor EXmlNsHrefNotFound.Create(const URI: string);
begin
  inherited CreateResFmt(@SXmlNsHrefNotFound, [URI]);
end;

{ XmlQualifiedName }

constructor XmlQualifiedName.Create(const Name: string);
begin
  FName := Name;
end;

constructor XmlQualifiedName.Create(const Name, Namespace: string);
begin
  FName := Name;
  FNamespace := Namespace;
end;

function XmlQualifiedName.IsEmpty: Boolean;
begin
  Result := (FName = '') and (FNamespace = '');
end;

class operator XmlQualifiedName.Equal(const L, R: XmlQualifiedName): Boolean;
begin
  Result := (L.FName = R.FName) and (L.FNamespace = R.FNamespace);
end;

class operator XmlQualifiedName.NotEqual(const L, R: XmlQualifiedName): Boolean;
begin
  Result := (L.FName <> R.FName) or (L.FNamespace <> R.FNamespace);
end;

class function XmlQualifiedName.ToString(const Name, Namespace: string): string;
begin
  if Namespace = '' then
    Result := Name
  else
    Result := Namespace + ':' + Name;
end;

function XmlQualifiedName.ToString: string;
begin
  if Namespace = '' then
    Result := Name
  else
    Result := Namespace + ':' + Name;
end;

end.
