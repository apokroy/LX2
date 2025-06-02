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

  TxmlSaveOption = (
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

function  xmlCharToStr(const S: xmlCharPtr): string; overload; inline;
function  xmlCharToStr(const S: xmlCharPtr; Len: NativeUInt): string; overload;
function  xmlCharToStrAndFree(const S: xmlCharPtr): string; inline;
function  SplitXMLName(const Name: string; out Prefix, LocalName: string): Boolean; overload;
function  SplitXMLName(const Name: string; out Prefix, LocalName: xmlCharPtr): Boolean; overload;

/// <summary>
/// Reuses the TLS buffer. Be carefully, only for use in functions that copy the values of their arguments.
/// </summary>
function  LocalXmlStr(const S: string): xmlCharPtr; overload;
function  LocalXmlStr(const P: PChar; var Len: NativeUInt): xmlCharPtr; overload;

function Utf8toUtf16Count(Input: PUtf8Char; Size: NativeUInt): NativeUInt; overload;
function Utf8toUtf16Count(Input: PUtf8Char): NativeUInt; overload;

/// <summary>
/// Call before functions that uses LocalXmlStr, marks all buffers as unsed
/// </summary>
procedure ResetLocalBuffers;

/// <summary>
/// Call before the end of the thread to clear all TLS memory buffers. It can also be called to free up unused memory.
/// </summary>
procedure ClearLocalBuffers;

function  XmlParserOptions(Options: TXmlParserOptions): Integer;
function  XmlSaveOptions(Options: TxmlSaveOptions): Integer;

function  LX2CheckNodeExists(const node: xmlNodePtr): xmlNodePtr; inline;
procedure LX2InternalError;
procedure LX2LocalAllocError;
procedure LX2NodeTypeError(nodeType: xmlElementType);
procedure LX2NsPrefixNotFoundError(prefix: xmlCharPtr);

implementation

{$region 'Using thread local storage for temporary buffers'}
const
  TLSBufferCount = 128;

type
  TTLSBuffer = record
    Data: Pointer;
    Size: NativeUInt;
  end;

  PTLSData = ^TTLSData;
  TTLSData = record
    Buffers: array[0..TLSBufferCount - 1] of TTLSBuffer;
    IsUsed: array[0..TLSBufferCount - 1] of Boolean;
    LastSlot: NativeUInt;
  end;

threadvar
  TLSData: PTLSData;            // One & only TLS var, that stores data on the heap, because TLS  is slow and limited
var
  TLSBuffers: TList<PTLSData>;  // List of buffers to clean up on program exit

function GetLocalBuffer(const Size: NativeUInt): Pointer;
var
  TLS: PTLSData;
begin
  TLS := TLSData; // Access to thread local storage too slow, use local pointer

  for var I := TLS.LastSlot + 1 to TLSBufferCount - 1 do
  begin
    if not TLS.IsUsed[I] then
    begin
      if TLS.Buffers[I].Size < Size then
        ReallocMem(TLS.Buffers[I].Data, Size);
      TLS.Buffers[I].Size := Size;
      TLS.IsUsed[I] := True;
      TLS.LastSlot := I;
      Exit(TLS.Buffers[I].Data);
    end;
  end;

  for var I := 0 to TLS.LastSlot do
  begin
    if not TLS.IsUsed[I] then
    begin
      if TLS.Buffers[I].Size < Size then
        ReallocMem(TLS.Buffers[I].Data, Size);
      TLS.Buffers[I].Size := Size;
      TLS.IsUsed[I] := True;
      TLS.LastSlot := I;
      Exit(TLS.Buffers[I].Data);
    end;
  end;
  Result := nil;
end;

procedure ResetLocalBuffers;
var
  TLS: PTLSData;
begin
  TLS := TLSData; // Access to thread local storage too slow, use local pointer
  if TLS = nil then
  begin
    GetMem(TLS, SizeOf(TTLSData));
    FillChar(TLS^, SizeOf(TTLSData), 0);

    TLSData := TLS;

    TLSBuffers.Add(TLS);
  end
  else if TLS.IsUsed[TLSBufferCount shr 1] then
    FillChar(TLS.IsUsed, SizeOf(TLS.IsUsed), 0);
end;

procedure ClearLocalBuffers;
var
  TLS: PTLSData;
begin
  TLS := TLSData;
  if TLS <> nil then
  begin
    TLSBuffers.Remove(TLS);

    for var I := Low(TLS.Buffers) to High(TLS.Buffers) do
    begin
      FreeMem(TLS.Buffers[I].Data);
      TLS.Buffers[I].Size := 0;
    end;
    FreeMem(TLS);
    TLSData := nil;
  end
  else
    FillChar(TLS.IsUsed, SizeOf(TLS.IsUsed), 0);
end;

{$endregion}

function LocalXmlStr(const P: PChar; var Len: NativeUInt): xmlCharPtr; overload;
var
  Buffer: Pointer;
begin
  if Len = 0 then
    Exit(nil);

  var DstLen := Len * 3 + 1;

  Buffer := GetLocalBuffer(DstLen);
  if Buffer = nil then
    LX2LocalAllocError;

  Len := LocaleCharsFromUnicode(CP_UTF8, 0, P, Len, Buffer, DstLen, nil, nil);
  if Len > 0 then
  begin
    PAnsiChar(Buffer)[Len] := #0;
    Result := Buffer;
  end
  else
    Result := nil;
end;

function LocalXmlStr(const S: string): xmlCharPtr;
var
  Buffer: Pointer;
begin
  var SrcLen := PInteger(UIntPtr(S) - 4)^; //Length(S);
  if SrcLen = 0 then
    Exit(nil);

  var DstLen := SrcLen * 3 + 1;

  Buffer := GetLocalBuffer(DstLen);
  if Buffer = nil then
    LX2LocalAllocError;

  var L := LocaleCharsFromUnicode(CP_UTF8, 0, Pointer(S), SrcLen, Buffer, DstLen, nil, nil);
  if L > 0 then
  begin
    PAnsiChar(Buffer)[L] := #0;
    Result := Buffer;
  end
  else
    Result := nil;
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
begin
  Result := 0;
  var I := 0;
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

function xmlCharToStr(const S: xmlCharPtr; Len: NativeUInt): string;
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

begin
  if (S = nil) or (S = '') or (Len = 0) then Exit('');

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

function xmlCharToStr(const S: xmlCharPtr): string;
begin
  if (S = nil) or (S = '') then Exit('');
  Result := xmlCharToStr(S, Length(S));
end;

function xmlCharToStrAndFree(const S: xmlCharPtr): string;
begin
  Result := xmlCharToStr(S);
  xmlFree(S);
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

function SplitXMLName(const Name: string; out Prefix, LocalName: xmlCharPtr): Boolean;
var
  Len: NativeUInt;
begin
  var P := PChar(Pointer(Name));
  var L := Length(Name);
  for var I := 0 to L - 1 do
    if P[I] = ':' then
    begin
      Len := I;
      Prefix := LocalXmlStr(P, Len);
      Len := L - I - 1;
      LocalName := LocalXmlStr(PChar(@P[I + 1]), Len);
      Exit(True);
    end;
  Prefix := nil;
  Len := L;
  LocalName := LocalXmlStr(P, Len);
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

initialization
  TLSBuffers := TList<PTLSData>.Create;

finalization
  for var I := 0 to TLSBuffers.Count - 1 do
  begin
    var TLS := TLSBuffers[I];
    for var J := Low(TLS.Buffers) to High(TLS.Buffers) do
    begin
      FreeMem(TLS.Buffers[J].Data);
      TLS.Buffers[J].Size := 0;
    end;
    FreeMem(TLS);
  end;
  FreeAndNil(TLSBuffers);

end.
