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
/// A small set of commonly used types and functions
///</summary>
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
  TXmlCompatibility = (
    xmlDefault,
    xmlMsXml3,
    xmlMsXml6
  );

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

  TXmlC14NMode = (
    ///<summary>Original C14N 1.0 spec.</summary>
    xmlC14N,
    ///<summary>Exclusive C14N 1.0 spec.</summary>
    xmlC14NExclusive,
    ///<summary>C14N 1.1 spec.</summary>
    xmlC14N11
  );

const
  DefaultParserOptions = [xmlParseSubstituteEntity, xmlParseDTDAttrs, xmlParseBigLines, xmlParseHuge];

type
  TXmlParseErrors = class;

  TXmlErrorLevel = xmlErrorLevel;

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
    constructor Create(err: xmlError);
    property Code: Integer read FCode;
    property Level: xmlErrorLevel read FLevel;
    property Url: string read FUrl;
    property Text: string read FText;
    property Source: string read FSource;
    property Line: Integer read FLine;
    property Col: Integer read FCol;
  end;

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

  EXmlError = class(Exception)
  end;

  EXmlInternalError = class(EXmlError)
  end;

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

  EXmlNsHrefNotFound = class(EXmlError)
  public
    constructor Create(const URI: string);
  end;

  EXmlUnsupported = class(EXmlError)
  end;

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

function  xmlEscapeString(const Value: RawByteString): RawByteString;
function  xmlNormalizeString(const S: string): string;
function  xmlStrSame(P1, P2: xmlCharPtr): Boolean;
function  xmlStrPtr(const S: RawByteString): xmlCharPtr; inline;

function  xmlCharToStr(const S: xmlCharPtr): string; overload; inline;
function  xmlCharToStrAndFree(const S: xmlCharPtr): string; overload;inline;
function  xmlCharToStr(const S: xmlCharPtr; Len: NativeUInt): string; overload;
function  xmlCharToRaw(const S: xmlCharPtr): RawByteString; overload; inline;
function  xmlCharToRaw(const S: xmlCharPtr; Len: NativeUInt): RawByteString; overload;
function  xmlCharToRawAndFree(const S: xmlCharPtr): RawByteString; inline;
function  xmlQName(const Prefix, Name: xmlCharPtr): RawByteString;
function  SplitXMLName(const Name: string; out Prefix, LocalName: string): Boolean; overload;
function  SplitXMLName(const Name: RawByteString; out Prefix, LocalName: RawByteString): Boolean; overload;

function  NodeTypeName(nodeType: xmlElementType): string;

function  Utf8toUtf16Count(Input: PUtf8Char; Size: NativeUInt): NativeUInt; overload;
function  Utf8toUtf16Count(Input: PUtf8Char): NativeUInt; overload;

function  XmlParserOptions(Options: TXmlParserOptions): Integer;
function  XmlSaveOptions(Options: TxmlSaveOptions): Integer;

procedure LX2InternalError;

resourcestring
  SXmlNsHrefNotFound     = 'Namespace with URI "%s" not found';
  SUnsupportedByAttrDecl = 'Operation unsupported by namespace declarations';
  SUnsupportedBy         = 'Operation unsupported by %s';

implementation

function xmlStrPtr(const S: RawByteString): xmlCharPtr;
begin
  if Length(S) = 0 then
    Result := nil
  else
    Result := Pointer(S);
end;

function Utf8toUtf16Count(Input: PUtf8Char; Size: NativeUInt): NativeUInt;
const
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
var
  I: NativeUInt;
begin
  Result := 0;
  I := 0;
  while I < Size  do
  begin
    Inc(I, Utf8L[Input[I]]);
    Inc(Result);
  end;
end;

function Utf8toUtf16Count(Input: PUtf8Char): NativeUInt;
const
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
begin
  Result := 0;
  var I := 0;
  while Input[I] <> #0 do
  begin
    Inc(I, Utf8L[Input[I]]);
    Inc(Result);
  end;
end;

function xmlCharToStr(const S: xmlCharPtr): string;
begin
  Result := xmlCharToStr(S, Length(S));
end;

function xmlCharToStr(const S: xmlCharPtr; Len: NativeUInt): string;
begin
  Result := UTF8ToUnicodeString(S);
  if Len = 0 then
    Exit('');

  var L := Utf8toUtf16Count(S, Len);
  SetString(Result, nil, L);
  UnicodeFromLocaleChars(CP_UTF8, 0, S, Len, Pointer(Result), L);
 end;

function xmlCharToRaw(const S: xmlCharPtr; Len: NativeUInt): RawByteString;
begin
  if Len = 0 then
    Exit('');

  SetString(Result, S, Len);
  SetCodePage(Result, CP_UTF8, False);
end;

function xmlCharToRaw(const S: xmlCharPtr): RawByteString;
begin
  Result := xmlCharToRaw(S, Length(S));
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

  SetString(Result, nil, L1 + L2 + 1);
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
      SetString(Prefix, P, I);
      SetString(LocalName, PChar(@P[I + 1]), L - I - 1);
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
      SetString(Prefix, P, I);
      SetString(LocalName, PAnsiChar(@P[I + 1]), L - I - 1);
      Exit(True);
    end;
  LocalName := Name;
  Result := False;
end;

function xmlEscapeString(const Value: RawByteString): RawByteString;
begin
  var Escaped := xmlEncodeSpecialChars(nil, Pointer(Value));
  SetString(Result, Escaped, Length(Escaped));
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
    if (Src^ <= 32) and (Src^ in [32, 9, 10, 13]) then
      goto HasSpaces;
    Inc(Src);
  end;
  Result := S;

 HasSpaces:
  SetString(Result, nil, Length(S));
  Src := PWord(Pointer(S));
  var Dst := PWord(Pointer(Result));
  while (Src^ <= 32) and (Src^ in [32, 9, 10, 13]) do
    Inc(Src);

  var L := 0;
  while Src^ <> 0 do
  begin
    if (Src^ <= 32) and (Src^ in [32, 9, 10, 13]) then
    begin
      Dst^ := 32;
      Inc(Src);
      Inc(Dst);
      Inc(L);
      while (Src^ <= 32) and (Src^ in [32, 9, 10, 13]) do
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
  if (NodeType >= Low(xmlElementType)) and (NodeType <= Low(xmlElementType)) then
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
  if P1 = P2 then
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
