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
{$RANGECHECKS OFF}
{$OVERFLOWCHECKS OFF}

// The SSE2 routines are written against the Win64 calling convention
// (RCX, RDX, R8) and need the inline assembler, which the LLVM-based
// compilers do not have; every other target takes the Pascal path.
{$IF Defined(CPUX64) and Defined(MSWINDOWS) and Defined(ASSEMBLER) and not Defined(PUREPASCAL)}
  {$DEFINE LX2_ASM_WIN64}
{$ENDIF}

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
  /// <remarks>
  /// LX2 never loads external entities or the external DTD subset, and no member of the set
  /// turns loading on (see <c>xmlParseNoXXE</c>).
  /// </remarks>
  TXmlParserOption = (
    /// <summary>Replaces entity references with their text (<c>XML_PARSE_NOENT</c>).
    /// Only entities declared in the document itself are expanded; a reference to an
    /// external entity is left unexpanded.</summary>
    xmlParseSubstituteEntity,
    /// <summary><c>XML_PARSE_DTDLOAD</c>. Loads nothing: the external DTD subset named by
    /// the document type declaration is never read.</summary>
    xmlParseExternalDTD,
    xmlParseDTDAttrs,
    /// <summary>Validates against the DTD while parsing (<c>XML_PARSE_DTDVALID</c>). Only
    /// the internal subset takes part: the external one is never read.</summary>
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
    /// <summary>Always on: <see cref="XmlParserOptions"/> adds <c>XML_PARSE_NO_XXE</c>
    /// to every set, whether the set holds this member or not. The member stays so that
    /// code naming it compiles.</summary>
    xmlParseNoXXE,
    xmlParseUnzip,
    xmlParseNoSysCatalog,
    xmlParseNoCatalogPI,
    xmlParseBigLines,
    /// <summary>Short text nodes keep their content inside the node instead of a
    /// separately allocated string (<c>XML_PARSE_COMPACT</c>): fewer allocations for
    /// numbers, codes and dates. Node contents are read through libxml2 either way.</summary>
    xmlParseCompact
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
  /// substitutes the entities the document declares, applies the attribute defaults of
  /// its internal DTD subset, relaxes libxml2's
  /// line-number/node-size limits (<c>xmlParseBigLines</c>, <c>xmlParseHuge</c>)
  /// to support large real-world documents without spurious errors, and keeps
  /// short text inside the nodes (<c>xmlParseCompact</c>). External entities and the
  /// external DTD subset are not read (see <see cref="TXmlParserOption"/>).
  /// </summary>
  DefaultParserOptions = [xmlParseSubstituteEntity, xmlParseDTDAttrs, xmlParseBigLines, xmlParseHuge, xmlParseCompact];

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
  /// Raised by a reader when the document does not have the shape a method needs (text where
  /// an element is expected, another element than the one named, child elements in simple
  /// content) or a value is outside the lexical space of its type. Malformed XML raises
  /// <see cref="EXmlParserError"/> instead.
  /// </summary>
  EXmlReaderError = class(EXmlError)
  private
    FLine: Integer;
  public
    /// <summary>The line is appended to the message when it is known (above 0).</summary>
    constructor Create(const Msg: string; Line: Integer); overload;
    /// <summary>Line of the node the reader was on, 0 when unknown.</summary>
    property Line: Integer read FLine;
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
  /// Conversions between Delphi values and the lexical forms of XML Schema types, the same
  /// on every locale, as <c>System.Xml.XmlConvert</c> in .NET: the decimal separator is
  /// always a point and dates follow ISO 8601. The XML whitespace around a value is
  /// ignored; a value longer than 256 characters is not accepted.
  /// </summary>
  /// <remarks>
  /// The <c>To*</c> functions raise <c>EConvertError</c> on a value outside the lexical
  /// space of the type; the <c>TryTo*</c> functions return False instead. The overloads
  /// that take a UTF-8 pointer and a length read the text in place, which is how a reader
  /// converts the content of a node without making a string of it.
  /// </remarks>
  XmlConvert = record
  public
    /// <summary>xs:boolean: <c>true</c>, <c>false</c>, <c>1</c> or <c>0</c>.</summary>
    class function ToBoolean(const S: string): Boolean; static;
    /// <summary>xs:int: an optional sign and decimal digits, within Integer.</summary>
    class function ToInteger(const S: string): Integer; static;
    /// <summary>xs:long: an optional sign and decimal digits, within Int64.</summary>
    class function ToInt64(const S: string): Int64; static;
    /// <summary>xs:double: a point as the separator, an optional exponent, <c>INF</c>,
    /// <c>-INF</c> and <c>NaN</c>.</summary>
    class function ToDouble(const S: string): Double; static;
    /// <summary>xs:decimal (no exponent) as Currency; a value with a nonzero fifth fraction
    /// digit or out of the range of Currency is an error rather than a rounded value.</summary>
    class function ToCurrency(const S: string): Currency; static;
    /// <summary>
    /// xs:dateTime or xs:date. The value is the time as written: a time zone
    /// (<c>Z</c>, <c>+03:00</c>) is checked and dropped, the overload with
    /// <paramref name="OffsetMinutes"/> returns it. Fractions of a second beyond
    /// milliseconds are truncated; <c>24:00:00</c> is midnight of the next day.
    /// </summary>
    class function ToDateTime(const S: string): TDateTime; overload; static;
    class function ToDateTime(const S: string; out OffsetMinutes: Integer; out HasOffset: Boolean): TDateTime; overload; static;
    class function TryToBoolean(const S: string; out Value: Boolean): Boolean; overload; static;
    class function TryToInteger(const S: string; out Value: Integer): Boolean; overload; static;
    class function TryToInt64(const S: string; out Value: Int64): Boolean; overload; static;
    class function TryToDouble(const S: string; out Value: Double): Boolean; overload; static;
    class function TryToCurrency(const S: string; out Value: Currency): Boolean; overload; static;
    class function TryToDateTime(const S: string; out Value: TDateTime): Boolean; overload; static;
    class function TryToDateTime(const S: string; out Value: TDateTime; out OffsetMinutes: Integer; out HasOffset: Boolean): Boolean; overload; static;
    class function TryToBoolean(P: PUTF8Char; Len: NativeInt; out Value: Boolean): Boolean; overload; static;
    class function TryToInteger(P: PUTF8Char; Len: NativeInt; out Value: Integer): Boolean; overload; static;
    class function TryToInt64(P: PUTF8Char; Len: NativeInt; out Value: Int64): Boolean; overload; static;
    class function TryToDouble(P: PUTF8Char; Len: NativeInt; out Value: Double): Boolean; overload; static;
    class function TryToCurrency(P: PUTF8Char; Len: NativeInt; out Value: Currency): Boolean; overload; static;
    class function TryToDateTime(P: PUTF8Char; Len: NativeInt; out Value: TDateTime; out OffsetMinutes: Integer; out HasOffset: Boolean): Boolean; overload; static;
    { The lexical forms of values. The names differ by type rather than overload one
      ToString: TDateTime is a Double, and a literal or an expression would not choose. }
    /// <summary><c>true</c> or <c>false</c>.</summary>
    class function FromBoolean(Value: Boolean): string; static;
    class function FromInt64(Value: Int64): string; static;
    /// <summary>The shortest of 15 and 17 significant digits that reads back as the same
    /// value; <c>INF</c>, <c>-INF</c> and <c>NaN</c> for the special values.</summary>
    class function FromDouble(Value: Double): string; static;
    class function FromCurrency(Value: Currency): string; static;
    /// <summary>xs:dateTime without a time zone: <c>2026-10-13T09:05:00</c>, with
    /// <c>.zzz</c> when there are milliseconds.</summary>
    class function FromDateTime(Value: TDateTime): string; static;
    /// <summary>xs:date: <c>2026-10-13</c>; the time of day is not written.</summary>
    class function FromDate(Value: TDateTime): string; static;
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

/// <summary>Byte length of a null-terminated UTF-8/ANSI buffer, or 0 for <c>nil</c>.</summary>
/// <remarks>
/// Scans 16 bytes per iteration with SSE2. The first load is taken from the
/// 16-byte boundary at or below <paramref name="S"/> and the bytes preceding
/// the string are shifted out of the compare mask, so every load is aligned
/// and none can reach into a page the string does not occupy.
/// </remarks>
function  xmlStrLen(S: xmlCharPtr): NativeUInt;

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
/// <remarks>
/// Does not copy or allocate; the returned pointer is only valid as long as
/// <paramref name="S"/> is alive and not reallocated (COW). Relies on an
/// empty <c>RawByteString</c> being a nil pointer, which is why
/// <see cref="xmlEscapeString"/> must not hand out a zero-length string built
/// by <see cref="NewUtf8String"/>.
/// </remarks>
function  xmlStrPtr(const S: RawByteString): xmlCharPtr; inline;

/// <summary>Decodes a null-terminated UTF-8 <c>xmlCharPtr</c> into a Unicode <c>string</c>.</summary>
/// <remarks>
/// Takes the byte length and the UTF-16 code unit count together from
/// <see cref="Utf8toUtf16CountAndLen"/>, then converts in a second pass
/// (<c>UnicodeFromLocaleChars</c>) — a naive implementation would need a
/// separate <c>Length(xmlCharPtr)</c> (strlen) pass on top of both.
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
/// <remarks>Length comes from <see cref="xmlStrLen"/>, not from the UTF-16 counting path used by <see cref="xmlCharToStr"/>.</remarks>
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
/// Takes both byte lengths from <see cref="xmlStrLen"/>, then allocates the
/// exact combined buffer once via <see cref="NewUtf8String"/> and fills it
/// with two <c>Move</c> calls plus the colon separator — a single
/// allocation instead of string concatenation's intermediate temporaries.
/// </remarks>
/// <param name="Prefix">Namespace prefix, or <c>nil</c>/empty for no prefix.</param>
/// <param name="Name">Local element/attribute name.</param>
function  xmlQName(const Prefix, Name: xmlCharPtr): RawByteString;

type
  /// <summary>
  /// Scratch space for the UTF-8 arguments of one libxml2 call: converts
  /// <c>string</c> parameters to <c>xmlCharPtr</c> without touching the heap.
  /// </summary>
  /// <remarks>
  /// <para>
  /// Declare one as a local of the wrapping method and pass its results
  /// straight into the libxml2 call:
  /// <code>
  /// var Args: TXmlArgs;
  /// Result := xmlHasNsProp(NodePtr, Args.StrPtr(Name), Args.StrPtr(NamespaceURI));
  /// </code>
  /// Every argument of that call is packed into one stack buffer, so a call
  /// that would otherwise build and free two or three temporary
  /// <c>RawByteString</c>s allocates nothing at all.
  /// </para>
  /// <para>
  /// The pointers stay valid until the record leaves scope or
  /// <see cref="TXmlArgs.Reset"/> is called, and never longer - do not hand
  /// one to anything that outlives the call. Arguments too long for the buffer
  /// fall back to a heap string the record keeps alive, so the same rule
  /// covers them.
  /// </para>
  /// <para>
  /// An empty <c>string</c> becomes <c>nil</c>, the same rule
  /// <see cref="xmlStrPtr"/> follows: libxml2 reads <c>nil</c> as "not given",
  /// and that is what an empty Delphi string means at these boundaries - there
  /// is no separate null. Passing a pointer to an empty string instead makes
  /// libxml2 look for a namespace whose URI is literally empty, or for an
  /// encoding named "", and find nothing.
  /// </para>
  /// </remarks>
  TXmlArgs = record
  private
    FBuf: array[0..2047] of Byte;
    FUsed: NativeInt;
    FSpill: TArray<RawByteString>;
    FSpillCount: Integer;
    function Convert(const S: string): xmlCharPtr;
  public
    class operator Initialize(out Dest: TXmlArgs);
    /// <summary>Invalidates every pointer handed out so far and reuses the buffer.</summary>
    procedure Reset;
    /// <summary>UTF-8 view of <paramref name="S"/>, <c>nil</c> when it is empty.</summary>
    function StrPtr(const S: string): xmlCharPtr;
  end;

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
/// <para>
/// The count is "bytes that are not UTF-8 continuation bytes, plus bytes
/// &gt;= $F0": the first term is the number of codepoints, the second adds
/// the extra code unit every 4-byte sequence needs for its surrogate pair.
/// Both terms are per-byte classifications, so the cost per byte does not
/// depend on how multi-byte sequences are distributed through the buffer.
/// </para>
/// <para>
/// Buffers of at least <see cref="Utf8BlockThreshold"/> bytes are counted 16
/// bytes at a time with SSE2 (see Utf8toUtf16CountBlocks); shorter
/// buffers, and the trailing bytes of longer ones, go 8 bytes at a time
/// (<see cref="Utf8toUtf16CountWords"/>).
/// </para>
/// <para>
/// <b>No error checking:</b> well-formed UTF-8 is assumed. Continuation-byte
/// structure and overlong encodings are not validated; malformed input
/// yields a wrong count, never an out-of-bounds read.
/// </para>
/// </remarks>
function  Utf8toUtf16Count(Input: PUtf8Char; Size: NativeUInt): NativeUInt; overload;

/// <summary>
/// Null-terminated-buffer counterpart of
/// <see cref="Utf8toUtf16Count(PUtf8Char,NativeUInt)"/>.
/// </summary>
/// <remarks>
/// Defers to <see cref="Utf8toUtf16CountAndLen"/> and discards the byte
/// length. <paramref name="Input"/> must not be <c>nil</c>.
/// </remarks>
function  Utf8toUtf16Count(Input: PUtf8Char): NativeUInt; overload;

/// <summary>
/// Byte length and UTF-16 code unit count of a null-terminated UTF-8 buffer,
/// obtained together.
/// </summary>
/// <param name="Input">Null-terminated UTF-8 buffer. Must not be <c>nil</c>.</param>
/// <param name="ByteLen">
/// Receives the byte length of the string up to (but excluding) the
/// terminating <c>#0</c> - the same value <see cref="xmlStrLen"/> returns.
/// </param>
/// <returns>The number of UTF-16 code units the string decodes to.</returns>
/// <remarks>
/// <para>
/// <b>Why this exists:</b> it backs <c>xmlCharToStr(xmlCharPtr)</c>, one of
/// the hottest functions in the library - called for every text node and
/// attribute value materialized into a Delphi <c>string</c> - which needs
/// both numbers: the code unit count to size the result buffer and the byte
/// length to drive the conversion.
/// </para>
/// <para>
/// Short strings are walked 8 bytes at a time by a loop that looks for the
/// terminator and counts code units in the same step. Once <c>FusedWords</c>
/// words have gone by without a terminator the string is long enough for two
/// vectorised passes to win, and the remainder is handed to
/// <see cref="xmlStrLen"/> and
/// <see cref="Utf8toUtf16Count(PUtf8Char,NativeUInt)"/>. The unit count
/// itself follows the same rule as
/// <see cref="Utf8toUtf16Count(PUtf8Char,NativeUInt)"/>.
/// </para>
/// <para>
/// <b>Nothing past the terminator is read:</b> the first word is taken from
/// the 8-byte boundary at or below <paramref name="Input"/> and the bytes in
/// front of the string are replaced inside the register, so every block read
/// is aligned and cannot reach into a page the string does not occupy.
/// </para>
/// <para>
/// <b>No error checking:</b> well-formed UTF-8 is assumed. Continuation-byte
/// structure and overlong encodings are not validated; malformed input
/// yields a wrong count, never an out-of-bounds read.
/// </para>
/// </remarks>
function  Utf8toUtf16CountAndLen(Input: PUtf8Char; out ByteLen: NativeUInt): NativeUInt;

/// <summary>Converts a <see cref="TXmlParserOptions"/> set into libxml2's native <c>XML_PARSE_*</c> integer bitmask.</summary>
/// <remarks>The mask always holds <c>XML_PARSE_NO_XXE</c>: a parse that takes its options
/// from here loads neither external entities nor the external DTD subset.</remarks>
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

/// <summary>
/// Makes a string variable a new string of <paramref name="Len"/> characters,
/// building the header directly instead of going through the RTL string manager.
/// </summary>
/// <remarks>
/// <paramref name="Result"/> is a string variable passed as <c>Pointer(S)</c>, and
/// whatever it holds is released first. It is not necessarily empty: a string
/// function's result arrives holding the variable it is being assigned to, which
/// inside a loop is the previous iteration's string.
/// </remarks>
procedure NewUtf16String(var Result: Pointer; Len: NativeInt); overload; inline;
procedure NewUtf16String(var Result: Pointer; Len: NativeInt; const Data: Pointer); overload; inline;
procedure NewRawString(var Result: Pointer; Len: NativeInt); overload; inline;
procedure NewRawString(var Result: Pointer; Len: NativeInt; const Data: Pointer); overload; inline;
procedure NewUtf8String(var Result: Pointer; Len: NativeInt); overload; inline;
procedure NewUtf8String(var Result: Pointer; Len: NativeInt; const Data: Pointer); overload; inline;

resourcestring
  SXmlNsHrefNotFound     = 'Namespace with URI "%s" not found';
  SUnsupportedByAttrDecl = 'Operation unsupported by namespace declarations';
  SUnsupportedBy         = 'Operation unsupported by %s';
  SNotAChild             = 'The parameter node is not a child of this node';
  SRefNotAChild          = 'Insert position node must be a child of the node to insert under';
  SInsertUnderItself     = 'Inserting a node or its ancestor under itself is not allowed';
  SXmlConvertInvalid     = '"%s" is not a valid %s value';

implementation

uses
  System.Math;

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

procedure NewUtf16String(var Result: Pointer; Len: NativeInt); overload; inline;
var
  P: PStrRec;
begin
  if Result <> nil then
    UnicodeString(Result) := '';
  if Len = 0 then
    Exit;

  GetMem(P, SizeOf(StrRec) + (Len + 1) * SizeOf(WideChar));
  Result := Pointer(PByte(P) + SizeOf(StrRec));
  P.length := Len;
  InitStrRec(P^).Init := UTF16_STR_INIT;
  PWideChar(Result)[Len] := #0;
end;

procedure NewUtf16String(var Result: Pointer; Len: NativeInt; const Data: Pointer); overload; inline;
var
  P: PStrRec;
begin
  if Result <> nil then
    UnicodeString(Result) := '';
  if Len = 0 then
    Exit;

  GetMem(P, SizeOf(StrRec) + (Len + 1) * SizeOf(WideChar));
  Result := Pointer(PByte(P) + SizeOf(StrRec));
  P.length := Len;
  InitStrRec(P^).Init := UTF16_STR_INIT;
  PWideChar(Result)[Len] := #0;
  Move(Data^, Result^, Len * SizeOf(WideChar));
end;

procedure NewRawString(var Result: Pointer; Len: NativeInt); overload; inline;
var
  P: PStrRec;
begin
  if Result <> nil then
    RawByteString(Result) := '';
  if Len = 0 then
    Exit;

  GetMem(P, SizeOf(StrRec) + (Len + 1) * SizeOf(AnsiChar));
  Result := Pointer(PByte(P) + SizeOf(StrRec));
  P.length := Len;
  InitStrRec(P^).Init := RAW_STR_INIT;
  PAnsiChar(Result)[Len] := #0;
end;

procedure NewRawString(var Result: Pointer; Len: NativeInt; const Data: Pointer); overload; inline;
var
  P: PStrRec;
begin
  if Result <> nil then
    RawByteString(Result) := '';
  if Len = 0 then
    Exit;

  GetMem(P, SizeOf(StrRec) + (Len + 1) * SizeOf(AnsiChar));
  Result := Pointer(PByte(P) + SizeOf(StrRec));
  P.length := Len;
  InitStrRec(P^).Init := RAW_STR_INIT;
  PAnsiChar(Result)[Len] := #0;
  Move(Data^, Result^, Len);
end;

procedure NewUtf8String(var Result: Pointer; Len: NativeInt); overload; inline;
var
  P: PStrRec;
begin
  if Result <> nil then
    RawByteString(Result) := '';
  if Len = 0 then
    Exit;

  GetMem(P, SizeOf(StrRec) + (Len + 1) * SizeOf(AnsiChar));
  Result := Pointer(PByte(P) + SizeOf(StrRec));
  P.length := Len;
  InitStrRec(P^).Init := UTF8_STR_INIT;
  PAnsiChar(Result)[Len] := #0;
end;

procedure NewUtf8String(var Result: Pointer; Len: NativeInt; const Data: Pointer); overload; inline;
var
  P: PStrRec;
begin
  if Result <> nil then
    RawByteString(Result) := '';
  if Len = 0 then
    Exit;

  GetMem(P, SizeOf(StrRec) + (Len + 1) * SizeOf(AnsiChar));
  Result := Pointer(PByte(P) + SizeOf(StrRec));
  P.length := Len;
  InitStrRec(P^).Init := UTF8_STR_INIT;
  PAnsiChar(Result)[Len] := #0;
  Move(Data^, Result^, Len);
end;

const
  Utf8Ones  = UInt64($0101010101010101);
  Utf8Highs = UInt64($8080808080808080);
  Utf8C0s   = UInt64($C0C0C0C0C0C0C0C0);
  Utf8F0s   = UInt64($F0F0F0F0F0F0F0F0);
  /// <summary>
  /// Buffers below this size stay on the word-at-a-time path: the block
  /// routine only pays for its call and register setup once it gets several
  /// whole 16-byte blocks.
  /// </summary>
  Utf8BlockThreshold = 64;

/// <summary>
/// Word-at-a-time (SWAR) UTF-16 code unit count for a buffer of known length.
/// </summary>
function Utf8toUtf16CountWords(Input: PUtf8Char; Size: NativeUInt): NativeUInt;
var
  P, E: PByte;
  W, M: UInt64;
begin
  Result := 0;
  P := PByte(Input);
  E := P + (Size and not NativeUInt(7));
  while P < E do
  begin
    W := PUInt64(P)^;
    if W and Utf8Highs = 0 then
      Inc(Result, 8)                        // the whole word is ASCII
    else
    begin
      // a zero byte marks each continuation byte, i.e. each (b and $C0) = $80
      M := (W and Utf8C0s) xor Utf8Highs;
      M := (M - Utf8Ones) and not M and Utf8Highs;
      Inc(Result, 8 - (((M shr 7) * Utf8Ones) shr 56));
      // and here each 4-byte lead byte, i.e. each (b and $F0) = $F0
      M := (W and Utf8F0s) xor Utf8F0s;
      M := (M - Utf8Ones) and not M and Utf8Highs;
      Inc(Result, ((M shr 7) * Utf8Ones) shr 56);
    end;
    Inc(P, 8);
  end;

  E := PByte(Input) + Size;
  while P < E do
  begin
    if P^ and $C0 <> $80 then
      Inc(Result);
    if P^ >= $F0 then
      Inc(Result);
    Inc(P);
  end;
end;

{$IFDEF LX2_ASM_WIN64}
/// <summary>SSE2 UTF-16 code unit count over whole 16-byte blocks.</summary>
/// <remarks><paramref name="Size"/> must be a multiple of 16; the caller keeps the tail.</remarks>
function Utf8toUtf16CountBlocks(Input: PUtf8Char; Size: NativeUInt): NativeUInt;
asm
      XOR      EAX, EAX
      MOV      R8, RDX
      SHR      R8, 4
      JZ       @@Done

      MOV      R10D, $BFBFBFBF
      MOVD     XMM0, R10D
      PSHUFD   XMM0, XMM0, 0         // $BF x16 ($BF = -65 as a signed byte)
      MOV      R10D, $F0F0F0F0
      MOVD     XMM1, R10D
      PSHUFD   XMM1, XMM1, 0         // $F0 x16
      PXOR     XMM2, XMM2            // per-byte counters
      PXOR     XMM4, XMM4            // 64-bit totals

      // a lane gains at most 2 per block, so the byte counters are drained
      // into XMM4 every 127 blocks, before any lane can wrap
@@Chunk:
      MOV      R9, R8
      CMP      R9, 127
      JBE      @@ChunkSize
      MOV      R9, 127
@@ChunkSize:
      SUB      R8, R9
@@Block:
      MOVDQU   XMM3, [RCX]
      MOVDQA   XMM5, XMM3
      PCMPGTB  XMM5, XMM0            // $FF where the byte is not a continuation
      PSUBB    XMM2, XMM5
      MOVDQA   XMM5, XMM3
      PMAXUB   XMM5, XMM1
      PCMPEQB  XMM5, XMM3            // $FF where the byte is >= $F0
      PSUBB    XMM2, XMM5
      ADD      RCX, 16
      DEC      R9
      JNZ      @@Block
      PXOR     XMM5, XMM5
      PSADBW   XMM2, XMM5
      PADDQ    XMM4, XMM2
      PXOR     XMM2, XMM2
      TEST     R8, R8
      JNZ      @@Chunk

      MOVDQA   XMM5, XMM4
      PSRLDQ   XMM5, 8
      PADDQ    XMM4, XMM5
      MOVQ     RAX, XMM4
@@Done:
end;
{$ENDIF}

function Utf8toUtf16Count(Input: PUtf8Char; Size: NativeUInt): NativeUInt;
{$IFDEF LX2_ASM_WIN64}
var
  Blocks: NativeUInt;
begin
  if Size < Utf8BlockThreshold then
    Result := Utf8toUtf16CountWords(Input, Size)
  else
  begin
    Blocks := Size and not NativeUInt(15);
    Result := Utf8toUtf16CountBlocks(Input, Blocks) +
              Utf8toUtf16CountWords(Input + Blocks, Size - Blocks);
  end;
end;
{$ELSE}
begin
  Result := Utf8toUtf16CountWords(Input, Size);
end;
{$ENDIF}

function Utf8toUtf16CountAndLen(Input: PUtf8Char; out ByteLen: NativeUInt): NativeUInt;
const
  /// <summary>
  /// How far the fused loop goes before handing the rest to the routines that
  /// take the byte length and the code unit count in separate vectorised
  /// passes.
  /// </summary>
  FusedWords = 8;
var
  P: PByte;
  W, M, Lead, Ofs, Rest: UInt64;
  N: Integer;
begin
  // Start from the aligned word holding Input, with the bytes in front of
  // Input replaced by $01: they stay ASCII, so the all-ASCII shortcut below
  // still fires, they cannot be mistaken for the terminator, and an aligned
  // read never crosses a page boundary. Result starts at -Ofs to cancel the
  // Ofs extra code units they make the first word contribute.
  Ofs := UIntPtr(Input) and 7;
  P := PByte(Input) - Ofs;
  Lead := (UInt64(1) shl (Ofs * 8)) - 1;
  W := (PUInt64(P)^ and not Lead) or (Lead and Utf8Ones);
  Result := NativeUInt(0) - Ofs;

  N := FusedWords;
  while (W - Utf8Ones) and not W and Utf8Highs = 0 do
  begin
    if W and Utf8Highs = 0 then
      Inc(Result, 8)
    else
    begin
      M := (W and Utf8C0s) xor Utf8Highs;
      M := (M - Utf8Ones) and not M and Utf8Highs;
      Inc(Result, 8 - (((M shr 7) * Utf8Ones) shr 56));
      M := (W and Utf8F0s) xor Utf8F0s;
      M := (M - Utf8Ones) and not M and Utf8Highs;
      Inc(Result, ((M shr 7) * Utf8Ones) shr 56);
    end;
    Inc(P, 8);
    Dec(N);
    if N = 0 then
    begin
      Rest := xmlStrLen(PUtf8Char(P));
      ByteLen := NativeUInt(P - PByte(Input)) + Rest;
      Exit(Result + Utf8toUtf16Count(PUtf8Char(P), Rest));
    end;
    W := PUInt64(P)^;
  end;

  // the terminator is inside W; that word is finished byte by byte
  if P < PByte(Input) then
  begin
    Inc(Result, Ofs);                       // the first word was never counted
    P := PByte(Input);
  end;
  while P^ <> 0 do
  begin
    if P^ and $C0 <> $80 then
      Inc(Result);
    if P^ >= $F0 then
      Inc(Result);
    Inc(P);
  end;
  ByteLen := NativeUInt(P - PByte(Input));
end;

function Utf8toUtf16Count(Input: PUtf8Char): NativeUInt;
var
  ByteLen: NativeUInt;
begin
  Result := Utf8toUtf16CountAndLen(Input, ByteLen);
end;

{$IFDEF LX2_ASM_WIN64}
function xmlStrLen(S: xmlCharPtr): NativeUInt;
asm
      TEST     RCX, RCX
      JZ       @@Nil
      MOV      R9, RCX                 // string start
      MOV      R8, RCX
      AND      R8, -16                 // aligned address of the block holding it
      PXOR     XMM0, XMM0
      MOVDQA   XMM1, [R8]
      PCMPEQB  XMM1, XMM0
      PMOVMSKB EAX, XMM1               // one bit per zero byte of the block
      AND      ECX, 15                 // bytes of the block that precede S
      SHR      EAX, CL                 // ...drop them, the mask now starts at S
      TEST     EAX, EAX
      JNZ      @@Head
@@Body:
      ADD      R8, 16
      MOVDQA   XMM1, [R8]
      PCMPEQB  XMM1, XMM0
      PMOVMSKB EAX, XMM1
      TEST     EAX, EAX
      JZ       @@Body
      BSF      EAX, EAX
      LEA      RAX, [R8 + RAX]
      SUB      RAX, R9
      JMP      @@Done
@@Head:
      BSF      EAX, EAX                // already relative to S
      JMP      @@Done
@@Nil:
      XOR      EAX, EAX
@@Done:
end;
{$ELSE}
function xmlStrLen(S: xmlCharPtr): NativeUInt;
const
  Ones  = UInt64($0101010101010101);
  Highs = UInt64($8080808080808080);
var
  P: xmlCharPtr;
  W: UInt64;
begin
  if S = nil then
    Exit(0);

  // the aligned word holding S, with the bytes in front of S forced non-zero,
  // so the search cannot stop before the string starts and no read crosses a
  // page boundary
  P := xmlCharPtr(UIntPtr(S) and not UIntPtr(7));
  W := PUInt64(P)^ or ((UInt64(1) shl ((UIntPtr(S) and 7) * 8)) - 1);
  while (W - Ones) and not W and Highs = 0 do
  begin
    Inc(P, 8);
    W := PUInt64(P)^;
  end;

  if P < S then
    P := S;
  while P^ <> #0 do
    Inc(P);
  Result := P - S;
end;
{$ENDIF}

function xmlStrPtr(const S: RawByteString): xmlCharPtr;
begin
  // An empty RawByteString is a nil pointer, so there is nothing to test.
  // Pointer(S) and not xmlCharPtr(S): the typed PAnsiChar cast substitutes a
  // pointer to a static #0 for an empty string, and libxml2 reads that as an
  // empty value rather than as no value at all.
  Result := xmlCharPtr(Pointer(S));
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
  if Prefix = nil then
    Exit(xmlCharToRaw(Name));

  var L1 := NativeInt(xmlStrLen(Prefix));
  if L1 = 0 then
    Exit(xmlCharToRaw(Name));

  var L2 := NativeInt(xmlStrLen(Name));

  NewUtf8String(Pointer(Result), L1 + L2 + 1);
  Move(Prefix^, Pointer(Result)^, L1);
  Result[L1 + 1] := ':';
  Move(Name^, (PByte(Result) + L1 + 1)^, L2);
end;

{$IFDEF LX2_ASM_WIN64}
/// <summary>
/// Narrows leading ASCII UTF-16 units to bytes, 16 at a time, and returns how
/// many were converted; stops at the first block holding a unit above $7F.
/// </summary>
function NarrowAscii(Src: PWideChar; Dst: PByte; L: NativeInt): NativeInt;
asm
      XOR      EAX, EAX
      MOV      R9, R8
      AND      R9, -16                // whole 16-unit blocks
      JZ       @@Tail

      MOV      R10D, $FF80FF80
      MOVD     XMM0, R10D
      PSHUFD   XMM0, XMM0, 0          // $FF80 x8
      PXOR     XMM1, XMM1
@@Block:
      MOVDQU   XMM2, [RCX + RAX * 2]
      MOVDQU   XMM3, [RCX + RAX * 2 + 16]
      MOVDQA   XMM4, XMM2
      POR      XMM4, XMM3
      PAND     XMM4, XMM0             // keep only the bits above $7F
      PCMPEQW  XMM4, XMM1             // $FFFF per unit that was ASCII
      PMOVMSKB R10D, XMM4
      CMP      R10D, $FFFF
      JNE      @@Tail
      PACKUSWB XMM2, XMM3             // 16 units -> 16 bytes, exact below $80
      MOVDQU   [RDX + RAX], XMM2
      ADD      RAX, 16
      CMP      RAX, R9
      JB       @@Block

@@Tail:
      CMP      RAX, R8
      JAE      @@Done
@@Unit:
      MOVZX    R10D, WORD PTR [RCX + RAX * 2]
      CMP      R10D, $80
      JAE      @@Done
      MOV      [RDX + RAX], R10B
      INC      RAX
      CMP      RAX, R8
      JB       @@Unit
@@Done:
end;
{$ELSE}
function NarrowAscii(Src: PWideChar; Dst: PByte; L: NativeInt): NativeInt;
begin
  Result := 0;
  while (Result < L) and (Word(Src[Result]) < $80) do
  begin
    Dst[Result] := Byte(Src[Result]);
    Inc(Result);
  end;
end;
{$ENDIF}

class operator TXmlArgs.Initialize(out Dest: TXmlArgs);
begin
  Dest.FUsed := 0;
  Dest.FSpillCount := 0;
end;

procedure TXmlArgs.Reset;
begin
  FUsed := 0;
  while FSpillCount > 0 do
  begin
    Dec(FSpillCount);
    FSpill[FSpillCount] := '';
  end;
end;

function TXmlArgs.Convert(const S: string): xmlCharPtr;
var
  L, Room, N: NativeInt;
begin
  L := Length(S);
  Room := Length(FBuf) - FUsed - 1;
  if L <= Room then                   // a UTF-8 byte per unit is the floor
  begin
    // ASCII narrows straight into the buffer; anything else is finished off by
    // the same conversion the RTL uses, writing into the buffer just the same
    N := NarrowAscii(PWideChar(S), @FBuf[FUsed], L);
    if N < L then
      N := LocaleCharsFromUnicode(CP_UTF8, 0, PWideChar(S), L,
             PAnsiChar(@FBuf[FUsed]), Room, nil, nil);
    if N > 0 then
    begin
      Result := xmlCharPtr(@FBuf[FUsed]);
      FBuf[FUsed + N] := 0;
      Inc(FUsed, N + 1);
      Exit;
    end;
  end;

  // does not fit: keep a heap string alive for as long as the record lives.
  // One managed field only - every extra one is paid for on every call that
  // never spills at all, in record initialization and finalization.
  if FSpillCount = Length(FSpill) then
    SetLength(FSpill, FSpillCount + 4);
  FSpill[FSpillCount] := Utf8Encode(S);
  Result := xmlCharPtr(Pointer(FSpill[FSpillCount]));
  Inc(FSpillCount);
end;

function TXmlArgs.StrPtr(const S: string): xmlCharPtr;
begin
  if Length(S) = 0 then
    Result := nil
  else
    Result := Convert(S);
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
  var Len := xmlStrLen(Escaped);
  // An empty result is a nil string, as xmlStrPtr expects: NewUtf8String with
  // Len = 0 releases what Result held and leaves nil.
  NewUtf8String(Pointer(Result), Len, Escaped);
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

  // libxml2's xmlStrSame is NULL-safe (a default xmlns has prefix = nil);
  // the comparison simply fails when one side is absent
  if (P1 = nil) or (P2 = nil) then
    Exit(False);

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
    XML_PARSE_BIG_LINES,
    XML_PARSE_COMPACT
  );
begin
  Result := XML_PARSE_NO_XXE;
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

{ EXmlReaderError }

constructor EXmlReaderError.Create(const Msg: string; Line: Integer);
begin
  if Line > 0 then
    inherited CreateFmt('%s (line %d)', [Msg, Line])
  else
    inherited Create(Msg);
  FLine := Line;
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

{ XmlConvert }

const
  MaxLexical = 256;

type
  TLexicalBuffer = array[0..MaxLexical - 1] of Char;

var
  InvariantFormat: TFormatSettings;

function IsXmlBlank(C: Char): Boolean; inline;
begin
  Result := (C = ' ') or (C = #10) or (C = #13) or (C = #9);
end;

function IsXmlBlankByte(B: Byte): Boolean; inline;
begin
  Result := (B = $20) or (B = $0A) or (B = $0D) or (B = $09);
end;

/// <summary>Drops the XML whitespace around a lexical value; False when nothing remains or
/// the rest is longer than MaxLexical.</summary>
function TrimLexical(var P: PChar; var Len: Integer): Boolean;
begin
  while (Len > 0) and IsXmlBlank(P^) do
  begin
    Inc(P);
    Dec(Len);
  end;
  while (Len > 0) and IsXmlBlank(P[Len - 1]) do
    Dec(Len);
  Result := (Len > 0) and (Len <= MaxLexical);
end;

/// <summary>Widens a UTF-8 lexical value into <paramref name="Buf"/>, the whitespace around
/// it dropped. False on a byte above $7F, which no lexical form of these types holds, and on
/// a value that does not fit.</summary>
function WidenLexical(P: PByte; Len: NativeInt; var Buf: TLexicalBuffer; out Count: Integer): Boolean;
var
  I: Integer;
begin
  Count := 0;
  while (Len > 0) and IsXmlBlankByte(P^) do
  begin
    Inc(P);
    Dec(Len);
  end;
  while (Len > 0) and IsXmlBlankByte(P[Len - 1]) do
    Dec(Len);
  if (Len = 0) or (Len > MaxLexical) then
    Exit(False);
  for I := 0 to Len - 1 do
  begin
    if P[I] >= $80 then
      Exit(False);
    Buf[I] := Char(P[I]);
  end;
  Count := Len;
  Result := True;
end;

function SameLexical(P: PChar; Len: Integer; const S: string): Boolean; inline;
begin
  Result := (Len = Length(S)) and CompareMem(P, Pointer(S), Len * SizeOf(Char));
end;

function IsDigit(C: Char): Boolean; inline;
begin
  Result := (C >= '0') and (C <= '9');
end;

function ParseBoolean(P: PChar; Len: Integer; out Value: Boolean): Boolean;
begin
  Value := False;
  if not TrimLexical(P, Len) then
    Exit(False);
  if SameLexical(P, Len, 'true') or SameLexical(P, Len, '1') then
    Value := True
  else if not (SameLexical(P, Len, 'false') or SameLexical(P, Len, '0')) then
    Exit(False);
  Result := True;
end;

function ParseInt64(P: PChar; Len: Integer; out Value: Int64): Boolean;
var
  Negative: Boolean;
  Limit, Acc: UInt64;
  Digit: Cardinal;
begin
  Value := 0;
  if not TrimLexical(P, Len) then
    Exit(False);
  Negative := P^ = '-';
  if Negative or (P^ = '+') then
  begin
    Inc(P);
    Dec(Len);
    if Len = 0 then
      Exit(False);
  end;
  // The magnitude of Low(Int64) is one more than High(Int64)
  Limit := UInt64(High(Int64)) + UInt64(Ord(Negative));
  Acc := 0;
  while Len > 0 do
  begin
    Digit := Cardinal(Ord(P^) - Ord('0'));
    if (Digit > 9) or (Acc > (Limit - Digit) div 10) then
      Exit(False);
    Acc := Acc * 10 + Digit;
    Inc(P);
    Dec(Len);
  end;
  if Negative then
    Value := -Int64(Acc)
  else
    Value := Int64(Acc);
  Result := True;
end;

function ParseInteger(P: PChar; Len: Integer; out Value: Integer): Boolean;
var
  V: Int64;
begin
  Result := ParseInt64(P, Len, V) and (V >= Low(Integer)) and (V <= High(Integer));
  if Result then
    Value := Integer(V)
  else
    Value := 0;
end;

/// <summary>
/// xs:double: <c>(+|-)?([0-9]+(.[0-9]*)?|.[0-9]+)([Ee](+|-)?[0-9]+)?</c>, <c>INF</c>,
/// <c>+INF</c>, <c>-INF</c>, <c>NaN</c>. The syntax is checked here, so the RTL conversion
/// never sees a thousands separator or a locale form.
/// </summary>
function ParseDouble(P: PChar; Len: Integer; out Value: Double): Boolean;
var
  I, Digits: Integer;
  S: string;
begin
  Value := 0;
  if not TrimLexical(P, Len) then
    Exit(False);
  if SameLexical(P, Len, 'NaN') then
    Value := NaN
  else if SameLexical(P, Len, 'INF') or SameLexical(P, Len, '+INF') then
    Value := Infinity
  else if SameLexical(P, Len, '-INF') then
    Value := NegInfinity
  else
  begin
    I := 0;
    if (P[I] = '+') or (P[I] = '-') then
      Inc(I);
    Digits := 0;
    while (I < Len) and IsDigit(P[I]) do
    begin
      Inc(I);
      Inc(Digits);
    end;
    if (I < Len) and (P[I] = '.') then
    begin
      Inc(I);
      while (I < Len) and IsDigit(P[I]) do
      begin
        Inc(I);
        Inc(Digits);
      end;
    end;
    if Digits = 0 then
      Exit(False);
    if (I < Len) and ((P[I] = 'E') or (P[I] = 'e')) then
    begin
      Inc(I);
      if (I < Len) and ((P[I] = '+') or (P[I] = '-')) then
        Inc(I);
      Digits := 0;
      while (I < Len) and IsDigit(P[I]) do
      begin
        Inc(I);
        Inc(Digits);
      end;
      if Digits = 0 then
        Exit(False);
    end;
    if I <> Len then
      Exit(False);
    SetString(S, P, Len);
    Exit(TryStrToFloat(S, Value, InvariantFormat));
  end;
  Result := True;
end;

/// <summary>
/// xs:decimal, <c>(+|-)?([0-9]+(.[0-9]*)?|.[0-9]+)</c>, into Currency exactly: the value
/// is accumulated in units of 1/10000, and a nonzero digit past the fourth fraction digit
/// or a value out of range fails instead of rounding.
/// </summary>
function ParseCurrency(P: PChar; Len: Integer; out Value: Currency): Boolean;
var
  I, Digits, Scale: Integer;
  Negative: Boolean;
  Limit, IntPart, Fraction, Acc: UInt64;
begin
  Value := 0;
  if not TrimLexical(P, Len) then
    Exit(False);
  I := 0;
  Negative := P[I] = '-';
  if Negative or (P[I] = '+') then
    Inc(I);
  Limit := UInt64(High(Int64)) + UInt64(Ord(Negative));
  IntPart := 0;
  Digits := 0;
  while (I < Len) and IsDigit(P[I]) do
  begin
    if IntPart > Limit div 10000 then
      Exit(False);
    IntPart := IntPart * 10 + UInt64(Ord(P[I]) - Ord('0'));
    Inc(I);
    Inc(Digits);
  end;
  if IntPart > Limit div 10000 then
    Exit(False);
  Fraction := 0;
  if (I < Len) and (P[I] = '.') then
  begin
    Inc(I);
    Scale := 1000;
    while (I < Len) and IsDigit(P[I]) do
    begin
      if Scale > 0 then
      begin
        Inc(Fraction, UInt64(Ord(P[I]) - Ord('0')) * UInt64(Scale));
        Scale := Scale div 10;
      end
      else if P[I] <> '0' then
        Exit(False);
      Inc(I);
      Inc(Digits);
    end;
  end;
  if (Digits = 0) or (I <> Len) then
    Exit(False);
  Acc := IntPart * 10000;
  if Acc > Limit - Fraction then
    Exit(False);
  Inc(Acc, Fraction);
  if Negative then
    PInt64(@Value)^ := -Int64(Acc)
  else
    PInt64(@Value)^ := Int64(Acc);
  Result := True;
end;

/// <summary>
/// xs:dateTime <c>YYYY-MM-DDThh:mm:ss(.s+)?</c> or xs:date <c>YYYY-MM-DD</c>, each with an
/// optional zone <c>Z</c> or <c>(+|-)hh:mm</c>. Years are the four-digit ones TDateTime
/// holds.
/// </summary>
function ParseDateTime(P: PChar; Len: Integer; out Value: TDateTime; out OffsetMinutes: Integer; out HasOffset: Boolean): Boolean;
var
  I: Integer;

  function Number(Count: Integer; out N: Integer): Boolean;
  var
    K: Integer;
  begin
    N := 0;
    if I + Count > Len then
      Exit(False);
    for K := I to I + Count - 1 do
    begin
      if not IsDigit(P[K]) then
        Exit(False);
      N := N * 10 + Ord(P[K]) - Ord('0');
    end;
    Inc(I, Count);
    Result := True;
  end;

  function Expect(C: Char): Boolean;
  begin
    Result := (I < Len) and (P[I] = C);
    if Result then
      Inc(I);
  end;

var
  Year, Month, Day, Hour, Minute, Second, MSec, Scale, Sign, ZoneHour, ZoneMinute: Integer;
  DatePart, TimePart: TDateTime;
begin
  Value := 0;
  OffsetMinutes := 0;
  HasOffset := False;
  if not TrimLexical(P, Len) then
    Exit(False);
  I := 0;
  if not (Number(4, Year) and Expect('-') and Number(2, Month) and Expect('-') and Number(2, Day)) then
    Exit(False);
  if not TryEncodeDate(Year, Month, Day, DatePart) then
    Exit(False);
  TimePart := 0;
  if Expect('T') then
  begin
    if not (Number(2, Hour) and Expect(':') and Number(2, Minute) and Expect(':') and Number(2, Second)) then
      Exit(False);
    MSec := 0;
    if Expect('.') then
    begin
      if (I >= Len) or not IsDigit(P[I]) then
        Exit(False);
      Scale := 100;
      while (I < Len) and IsDigit(P[I]) do
      begin
        Inc(MSec, (Ord(P[I]) - Ord('0')) * Scale);
        Scale := Scale div 10;
        Inc(I);
      end;
    end;
    if (Hour = 24) and (Minute = 0) and (Second = 0) and (MSec = 0) then
    begin
      Hour := 0;
      DatePart := DatePart + 1;
    end;
    if not TryEncodeTime(Hour, Minute, Second, MSec, TimePart) then
      Exit(False);
  end;
  if Expect('Z') then
    HasOffset := True
  else if (I < Len) and ((P[I] = '+') or (P[I] = '-')) then
  begin
    if P[I] = '-' then
      Sign := -1
    else
      Sign := 1;
    Inc(I);
    if not (Number(2, ZoneHour) and Expect(':') and Number(2, ZoneMinute)) then
      Exit(False);
    if (ZoneMinute > 59) or (ZoneHour > 14) or ((ZoneHour = 14) and (ZoneMinute <> 0)) then
      Exit(False);
    OffsetMinutes := Sign * (ZoneHour * 60 + ZoneMinute);
    HasOffset := True;
  end;
  if I <> Len then
    Exit(False);
  // Before 1899-12-30 the date part of a TDateTime is negative and the time still counts
  // forward from it: 1899-12-29 06:00 is -1.25.
  if DatePart < 0 then
    Value := DatePart - TimePart
  else
    Value := DatePart + TimePart;
  Result := True;
end;

procedure ConvertError(const S, TypeName: string);
begin
  raise EConvertError.CreateResFmt(@SXmlConvertInvalid, [S, TypeName]);
end;

class function XmlConvert.ToBoolean(const S: string): Boolean;
begin
  if not ParseBoolean(PChar(S), Length(S), Result) then
    ConvertError(S, 'xs:boolean');
end;

class function XmlConvert.ToInteger(const S: string): Integer;
begin
  if not ParseInteger(PChar(S), Length(S), Result) then
    ConvertError(S, 'xs:int');
end;

class function XmlConvert.ToInt64(const S: string): Int64;
begin
  if not ParseInt64(PChar(S), Length(S), Result) then
    ConvertError(S, 'xs:long');
end;

class function XmlConvert.ToDouble(const S: string): Double;
begin
  if not ParseDouble(PChar(S), Length(S), Result) then
    ConvertError(S, 'xs:double');
end;

class function XmlConvert.ToCurrency(const S: string): Currency;
begin
  if not ParseCurrency(PChar(S), Length(S), Result) then
    ConvertError(S, 'xs:decimal');
end;

class function XmlConvert.ToDateTime(const S: string): TDateTime;
var
  Offset: Integer;
  HasOffset: Boolean;
begin
  Result := ToDateTime(S, Offset, HasOffset);
end;

class function XmlConvert.ToDateTime(const S: string; out OffsetMinutes: Integer; out HasOffset: Boolean): TDateTime;
begin
  if not ParseDateTime(PChar(S), Length(S), Result, OffsetMinutes, HasOffset) then
    ConvertError(S, 'xs:dateTime');
end;

class function XmlConvert.TryToBoolean(const S: string; out Value: Boolean): Boolean;
begin
  Result := ParseBoolean(PChar(S), Length(S), Value);
end;

class function XmlConvert.TryToInteger(const S: string; out Value: Integer): Boolean;
begin
  Result := ParseInteger(PChar(S), Length(S), Value);
end;

class function XmlConvert.TryToInt64(const S: string; out Value: Int64): Boolean;
begin
  Result := ParseInt64(PChar(S), Length(S), Value);
end;

class function XmlConvert.TryToDouble(const S: string; out Value: Double): Boolean;
begin
  Result := ParseDouble(PChar(S), Length(S), Value);
end;

class function XmlConvert.TryToCurrency(const S: string; out Value: Currency): Boolean;
begin
  Result := ParseCurrency(PChar(S), Length(S), Value);
end;

class function XmlConvert.TryToDateTime(const S: string; out Value: TDateTime): Boolean;
var
  Offset: Integer;
  HasOffset: Boolean;
begin
  Result := ParseDateTime(PChar(S), Length(S), Value, Offset, HasOffset);
end;

class function XmlConvert.TryToDateTime(const S: string; out Value: TDateTime; out OffsetMinutes: Integer; out HasOffset: Boolean): Boolean;
begin
  Result := ParseDateTime(PChar(S), Length(S), Value, OffsetMinutes, HasOffset);
end;

class function XmlConvert.TryToBoolean(P: PUTF8Char; Len: NativeInt; out Value: Boolean): Boolean;
var
  Buf: TLexicalBuffer;
  Count: Integer;
begin
  Value := False;
  Result := WidenLexical(PByte(P), Len, Buf, Count) and ParseBoolean(@Buf[0], Count, Value);
end;

class function XmlConvert.TryToInteger(P: PUTF8Char; Len: NativeInt; out Value: Integer): Boolean;
var
  Buf: TLexicalBuffer;
  Count: Integer;
begin
  Value := 0;
  Result := WidenLexical(PByte(P), Len, Buf, Count) and ParseInteger(@Buf[0], Count, Value);
end;

class function XmlConvert.TryToInt64(P: PUTF8Char; Len: NativeInt; out Value: Int64): Boolean;
var
  Buf: TLexicalBuffer;
  Count: Integer;
begin
  Value := 0;
  Result := WidenLexical(PByte(P), Len, Buf, Count) and ParseInt64(@Buf[0], Count, Value);
end;

class function XmlConvert.TryToDouble(P: PUTF8Char; Len: NativeInt; out Value: Double): Boolean;
var
  Buf: TLexicalBuffer;
  Count: Integer;
begin
  Value := 0;
  Result := WidenLexical(PByte(P), Len, Buf, Count) and ParseDouble(@Buf[0], Count, Value);
end;

class function XmlConvert.TryToCurrency(P: PUTF8Char; Len: NativeInt; out Value: Currency): Boolean;
var
  Buf: TLexicalBuffer;
  Count: Integer;
begin
  Value := 0;
  Result := WidenLexical(PByte(P), Len, Buf, Count) and ParseCurrency(@Buf[0], Count, Value);
end;

class function XmlConvert.TryToDateTime(P: PUTF8Char; Len: NativeInt; out Value: TDateTime; out OffsetMinutes: Integer; out HasOffset: Boolean): Boolean;
var
  Buf: TLexicalBuffer;
  Count: Integer;
begin
  Value := 0;
  OffsetMinutes := 0;
  HasOffset := False;
  Result := WidenLexical(PByte(P), Len, Buf, Count) and ParseDateTime(@Buf[0], Count, Value, OffsetMinutes, HasOffset);
end;

class function XmlConvert.FromBoolean(Value: Boolean): string;
begin
  if Value then
    Result := 'true'
  else
    Result := 'false';
end;

class function XmlConvert.FromInt64(Value: Int64): string;
begin
  Result := IntToStr(Value);
end;

class function XmlConvert.FromDouble(Value: Double): string;
var
  Back: Double;
begin
  if IsNan(Value) then
    Exit('NaN');
  if IsInfinite(Value) then
    if Value > 0 then
      Exit('INF')
    else
      Exit('-INF');
  Result := FloatToStrF(Value, ffGeneral, 15, 0, InvariantFormat);
  if not TryStrToFloat(Result, Back, InvariantFormat) or (Back <> Value) then
    Result := FloatToStrF(Value, ffGeneral, 17, 0, InvariantFormat);
end;

class function XmlConvert.FromCurrency(Value: Currency): string;
begin
  Result := CurrToStr(Value, InvariantFormat);
end;

class function XmlConvert.FromDateTime(Value: TDateTime): string;
var
  Year, Month, Day, Hour, Minute, Second, MSec: Word;
begin
  DecodeDate(Value, Year, Month, Day);
  DecodeTime(Value, Hour, Minute, Second, MSec);
  if MSec = 0 then
    Result := Format('%.4d-%.2d-%.2dT%.2d:%.2d:%.2d', [Year, Month, Day, Hour, Minute, Second])
  else
    Result := Format('%.4d-%.2d-%.2dT%.2d:%.2d:%.2d.%.3d', [Year, Month, Day, Hour, Minute, Second, MSec]);
end;

class function XmlConvert.FromDate(Value: TDateTime): string;
var
  Year, Month, Day: Word;
begin
  DecodeDate(Value, Year, Month, Day);
  Result := Format('%.4d-%.2d-%.2d', [Year, Month, Day]);
end;

initialization
  InvariantFormat := TFormatSettings.Invariant;

end.
