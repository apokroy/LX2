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
  System.SysUtils, System.Generics.Collections,
  libxml2.API;

type
  EXmlError = class(Exception)
  end;

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
    xmlParseNoCatalogPI
  );

  TXmlParserOptions = set of TXmlParserOption;

  TXmlSaveOption = (
   xmlSaveFormat,
   xmlSaveNoDecl,
   xmlSaveNoEmpty,
   xmlSaveNoXHTML,
   xmlSaveXHTML,
   xmlSaveAaXML,
   xmlSaveAsHTML,
   xmlSaveWSNONSIG,
   xmlSaveEmpty,
   xmlSaveNoIndent,
   xmlSaveIndent
  );

  TXmlC14NMode = (
    ///<summary>Original C14N 1.0 spec.</summary>
    xmlC14N,
    ///<summary>Exclusive C14N 1.0 spec.</summary>
    xmlC14NExclusive,
    ///<summary>C14N 1.1 spec.</summary>
    xmlC14N11
  );

  TxmlSaveOptions = set of TxmlSaveOption;

const
  DefaultParserOptions = [xmlParseSubstituteEntity, xmlParseDTDAttrs];

type
  IXmlList<T> = interface
    function  GetCount: NativeInt;
    function  GetItem(const Index: NativeInt): T;
    function  GetEnumerator: TEnumerator<T>;
    function  ToArray: TArray<T>;
    property  Count: NativeInt read GetCount;
    property  Items[const Index: NativeInt]: T read GetItem; default;
  end;

  TXmlListBase<T> = class(TNoRefCountObject, IXmlList<T>)
  private
    FList: TList<T>;
    function  GetCount: NativeInt;
    function  GetItem(const Index: NativeInt): T;
  protected
    property  List: TList<T> read FList;
  public
    constructor Create;
    destructor Destroy; override;
    function  GetEnumerator: TEnumerator<T>;
    function  ToArray: TArray<T>;
    property  Count: NativeInt read GetCount;
    property  Items[const Index: NativeInt]: T read GetItem; default;
  end;

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

  TXmlParseErrors = class(TXmlListBase<TXmlParseError>)
  public
    procedure Add(const error: xmlError);
    procedure Clear;
  end;

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

function  Utf8toUtf16Count(Input: PUtf8Char; Size: NativeUInt): NativeUInt; overload;
function  Utf8toUtf16Count(Input: PUtf8Char): NativeUInt; overload;

function  XmlParserOptions(Options: TXmlParserOptions): Integer;
function  XmlSaveOptions(Options: TxmlSaveOptions): Integer;

function  LX2CheckNodeExists(const node: xmlNodePtr): xmlNodePtr; inline;
procedure LX2InternalError;
procedure LX2LocalAllocError;
procedure LX2NodeTypeError(nodeType: xmlElementType);
procedure LX2NsPrefixNotFoundError(prefix: xmlCharPtr);

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

const
  CP_UTF16 = 1200;

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
  if Len = 0 then
    Exit('');

  var L := Utf8toUtf16Count(S, Len);
  var Size := SizeOf(StrRec) + (L + 1) shl 1;
  var P: PStrRec;
  GetMem(P, Size);
  P.length := L;
  P.refCnt := 1;
  P.elemSize := SizeOf(WideChar);
  P.codePage := CP_UTF16;

  Pointer(Result) := Pointer(PByte(P) + SizeOf(StrRec));
  UnicodeFromLocaleChars(CP_UTF8, 0, S, Len, Pointer(Result), L);
end;

function xmlCharToRaw(const S: xmlCharPtr; Len: NativeUInt): RawByteString;
var
  P: PStrRec;
begin
  if Len = 0 then
    Exit('');

  var L := NativeUInt(Len) + SizeOf(StrRec) + 1 + ((NativeUInt(Len) + 1) and 1);
  GetMem(P, L);
  Pointer(Result) := Pointer(PByte(P) + SizeOf(StrRec));
  P.length := Len;
  P.refcnt := 1;
  P.codePage := CP_UTF8;
  P.elemSize := 1;
  PWideChar(Pointer(Result))[Len shr 1] := #0;
  Move(S^, Pointer(Result)^, Len);
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

function LX2CheckNodeExists(const node: xmlNodePtr): xmlNodePtr;
begin
  if node = nil then
    LX2InternalError;
  Result := node;
end;

procedure LX2LocalAllocError;
begin
   raise EXmlError.Create('Could''t allocate local buffer') at ReturnAddress;
end;

procedure LX2InternalError;
begin
  raise EXmlError.Create('libxml2 internal error') at ReturnAddress;
end;

procedure LX2NodeTypeError(nodeType: xmlElementType);
begin
  raise EXmlError.Create('operation with node with type "' + NodeTypeName(nodeType) + '" unsupported') at ReturnAddress;
end;

procedure LX2NsPrefixNotFoundError(prefix: xmlCharPtr);
begin
  raise EXmlError.Create('Namespace with prefix "' + xmlCharToStr(prefix) + '" not found');
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
    XML_PARSE_NO_CATALOG_PI
  );
begin
  Result := 0;
  for var Opt := Low(TXmlParserOption) to High(TXmlParserOption) do
    if Opt in Options then
      Result := Result or Values[Opt];
end;

function xmlSaveOptions(Options: TxmlSaveOptions): Integer;
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

{ TXmlListBase<T> }

constructor TXmlListBase<T>.Create;
begin
  FList := TList<T>.Create;
end;

destructor TXmlListBase<T>.Destroy;
begin
  FreeAndNil(FList);
  inherited;
end;

function TXmlListBase<T>.GetCount: NativeInt;
begin
  Result := List.Count;
end;

function TXmlListBase<T>.GetEnumerator: TEnumerator<T>;
begin
  Result := List.GetEnumerator;
end;

function TXmlListBase<T>.GetItem(const Index: NativeInt): T;
begin
  Result := List.List[Index];
end;

function TXmlListBase<T>.ToArray: TArray<T>;
begin
  Result := List.ToArray;
end;

{ TXmlParseErrors }

procedure TXmlParseErrors.Add(const error: xmlError);
var
  Item: TXmlParseError;
begin
  Item := TXmlParseError.Create(error);

  List.Add(Item);
end;

procedure TXmlParseErrors.Clear;
begin
  List.Clear;
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

end.
