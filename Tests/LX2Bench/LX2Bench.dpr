// Throughput benchmark of the statically linked libxml2 (LX2.Static): parsing, push
// parsing, serialization in UTF-8 and windows-1251, C14N, XPath and schema validation,
// on a synthetic document or on a file. Built and run by Bench.ps1 next to it.
//
//   LX2Bench [--file=<xml>] [--xsd=<schema>] [--items=N] [--runs=N] [--opts=N]
//            [--longtext] [--hostmm] [--threads=N] [--verify]
//
//   --file      benchmark this document instead of the synthetic one
//   --xsd       validate the document against this schema (the synthetic document
//               carries its own)
//   --items     records in the synthetic document (default 120000, about 31 MB)
//   --runs      repetitions per workload, the best one is reported (default 3)
//   --opts      raw XML_PARSE_* options for the DOM parse (default 0)
//   --longtext  synthetic document with 1.4 KB text nodes instead of short ones
//   --hostmm    LX2Lib.UseHostMemoryManager before Initialize: libxml2 on the Delphi
//               memory manager instead of the C runtime heap (no effect in a DEBUG
//               build, which keeps the debug allocator of libxml2)
//   --orderdoc  xmlXPathOrderDocElems on the document before the XPath workloads: the
//               element order index that turns node-set sorting in wide documents from
//               quadratic into linear
//   --threads   N threads each parsing the document --runs times; aggregate throughput
//   --verify    instead of timing, print sizes and hashes of every serialized form,
//               a push parse fed in 7-byte pieces and the diagnostics of malformed
//               inputs: two builds of the library must print the same
program LX2Bench;

{$APPTYPE CONSOLE}
{$O+}

uses
  System.SysUtils, System.Classes, System.Diagnostics, System.SyncObjs, System.Math,
  System.IOUtils, libxml2.API, LX2.Static;

// --- SAX handlers ---------------------------------------------------------------------

var
  Elems, Chars: Int64;
  PushHash: UInt64;

function Fnv(P: PByte; N: NativeInt): UInt64;
begin
  Result := UInt64(14695981039346656037);
  while N > 0 do
  begin
    Result := (Result xor P^) * UInt64(1099511628211);
    Inc(P);
    Dec(N);
  end;
end;

procedure OnStart(ctx: Pointer; const localname, prefix, URI: xmlCharPtr; nb_namespaces: Integer;
  namespaces: xmlSAX2NsPtr; nb_attributes, nb_defaulted: Integer; attributes: xmlSAX2AttrPtr); cdecl;
begin
  Inc(Elems);
end;

procedure OnEnd(ctx: Pointer; const localname, prefix, URI: xmlCharPtr); cdecl;
begin
end;

procedure OnChars(ctx: Pointer; const ch: xmlCharPtr; len: Integer); cdecl;
begin
  Inc(Chars, len);
end;

procedure OnCharsHash(ctx: Pointer; const ch: xmlCharPtr; len: Integer); cdecl;
begin
  PushHash := PushHash xor (Fnv(PByte(ch), len) + UInt64(len));
  Inc(Chars, len);
end;

// --- documents ------------------------------------------------------------------------

var
  LongText: Boolean = False;

function BuildDoc(Items: Integer): string;
var
  SB: TStringBuilder;
  i: Integer;
  Note: string;
begin
  Note := 'Заметка &amp; текст "в кавычках" &lt;тег&gt; ещё немного русского текста для объёма';
  if LongText then
    Note := StringOfChar('x', 700) + ' ' + StringOfChar('ж', 700) +
      ' 0123456789 the quick brown fox jumps over the lazy dog ' + Note;
  SB := TStringBuilder.Create(Items * 200);
  try
    SB.Append('<root xmlns:x="urn:x">'#10);
    for i := 1 to Items do
    begin
      SB.Append('<item id="').Append(i).Append('" code="AB-').Append(i).Append('" x:kind="товар">');
      SB.Append('<name>Товар номер ').Append(i).Append('</name>');
      SB.Append('<price>').Append(i mod 1000).Append('.').Append((i mod 100) div 10).Append(i mod 10).Append('</price>');
      SB.Append('<note>').Append(Note).Append('</note>');
      SB.Append('</item>'#10);
    end;
    SB.Append('</root>'#10);
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

const
  Schema: UTF8String =
    '<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:x="urn:x">' +
    '<xs:import namespace="urn:x"/>' +
    '<xs:element name="root"><xs:complexType><xs:sequence>' +
    '<xs:element name="item" maxOccurs="unbounded"><xs:complexType><xs:sequence>' +
    '<xs:element name="name" type="xs:string"/><xs:element name="price" type="xs:decimal"/><xs:element name="note" type="xs:string"/>' +
    '</xs:sequence><xs:attribute name="id" type="xs:integer" use="required"/><xs:attribute name="code" type="xs:string"/>' +
    '<xs:anyAttribute namespace="urn:x" processContents="skip"/>' +
    '</xs:complexType></xs:element></xs:sequence></xs:complexType>' +
    '<xs:key name="k"><xs:selector xpath="item"/><xs:field xpath="@id"/></xs:key>' +
    '</xs:element></xs:schema>';

var
  Utf8Doc, Cp1251Doc: TBytes;   // Utf8Doc carries a terminating zero for xmlReadDoc
  Runs: Integer = 3;
  Opts: Integer = 0;
  XPath1: UTF8String = '//item[@id="77777"]/name';
  XPath2: UTF8String = 'count(//note[contains(., "кавычках")])';
  SrcFile: string = '';
  SchemaFile: string = '';
  SchemaU8: UTF8String;
  OrderDoc: Boolean = False;

function Best(const Name: string; Bytes: Int64; Proc: TProc): Double;
var
  r: Integer;
  SW: TStopwatch;
  ms: Double;
begin
  Result := 1e9;
  for r := 1 to Runs do
  begin
    SW := TStopwatch.StartNew;
    Proc;
    ms := SW.Elapsed.TotalMilliseconds;
    if ms < Result then
      Result := ms;
  end;
  Writeln(Format('%-28s %8.1f ms  %7.1f MB/s', [Name, Result, Bytes / 1048576 / (Result / 1000)]));
end;

// --- timing ---------------------------------------------------------------------------

procedure Run;
var
  Doc: xmlDocPtr;
  Mem: Pointer;
  Size: Integer;
  Out: xmlCharPtr;
  XCtx: xmlXPathContextPtr;
  XObj: xmlXPathObjectPtr;
  SAX: xmlSAXHandler;
  PCtx: xmlParserCtxtPtr;
  SchemaP: xmlSchemaParserCtxtPtr;
  Sch: xmlSchemaPtr;
  V: xmlSchemaValidCtxtPtr;
begin
  Best('DOM parse UTF-8', Length(Utf8Doc), procedure begin
    Doc := xmlReadMemory(@Utf8Doc[0], Length(Utf8Doc) - 1, 'a.xml', nil, Opts);
    if Doc = nil then raise Exception.Create('parse failed');
    xmlFreeDoc(Doc);
  end);
  Best('DOM parse UTF-8 (xmlReadDoc)', Length(Utf8Doc), procedure begin
    Doc := xmlReadDoc(@Utf8Doc[0], 'a.xml', nil, Opts);
    if Doc = nil then raise Exception.Create('parse failed');
    xmlFreeDoc(Doc);
  end);
  Best('DOM parse windows-1251', Length(Cp1251Doc), procedure begin
    Doc := xmlReadMemory(@Cp1251Doc[0], Length(Cp1251Doc), 'a.xml', nil, Opts);
    if Doc = nil then raise Exception.Create('parse cp1251 failed');
    xmlFreeDoc(Doc);
  end);
  Best('SAX push parse UTF-8', Length(Utf8Doc), procedure begin
    FillChar(SAX, SizeOf(SAX), 0);
    SAX.initialized := XML_SAX2_MAGIC;
    SAX.startElementNs := OnStart;
    SAX.endElementNs := OnEnd;
    SAX.characters := OnChars;
    PCtx := xmlCreatePushParserCtxt(@SAX, nil, nil, 0, nil);
    xmlParseChunk(PCtx, @Utf8Doc[0], Length(Utf8Doc) - 1, 1);
    xmlFreeParserCtxt(PCtx);
  end);

  Doc := xmlReadMemory(@Utf8Doc[0], Length(Utf8Doc) - 1, 'a.xml', nil, Opts);
  if OrderDoc then
    Best('xmlXPathOrderDocElems', Length(Utf8Doc), procedure begin
      xmlXPathOrderDocElems(Doc);
    end);
  Best('Serialize UTF-8', Length(Utf8Doc), procedure begin
    xmlDocDumpMemoryEnc(Doc, Mem, Size, 'UTF-8');
    xmlFree(Mem);
  end);
  Best('Serialize windows-1251', Length(Utf8Doc), procedure begin
    xmlDocDumpMemoryEnc(Doc, Mem, Size, 'windows-1251');
    xmlFree(Mem);
  end);
  Best('C14N', Length(Utf8Doc), procedure begin
    Out := nil;
    if xmlC14NDocDumpMemory(Doc, nil, XML_C14N_1_0, nil, 0, Out) < 0 then raise Exception.Create('c14n');
    xmlFree(Out);
  end);
  Best('XPath, node set', Length(Utf8Doc), procedure begin
    XCtx := xmlXPathNewContext(Doc);
    XObj := xmlXPathEvalExpression(Pointer(XPath1), XCtx);
    if XObj = nil then raise Exception.Create('xpath');
    xmlXPathFreeObject(XObj);
    xmlXPathFreeContext(XCtx);
  end);
  Best('XPath, count(contains)', Length(Utf8Doc), procedure begin
    XCtx := xmlXPathNewContext(Doc);
    XObj := xmlXPathEvalExpression(Pointer(XPath2), XCtx);
    if XObj = nil then raise Exception.Create('xpath');
    xmlXPathFreeObject(XObj);
    xmlXPathFreeContext(XCtx);
  end);
  if (SrcFile = '') or (SchemaFile <> '') then
  begin
    if SchemaFile <> '' then
      SchemaP := xmlSchemaNewParserCtxt(Pointer(SchemaU8))
    else
      SchemaP := xmlSchemaNewMemParserCtxt(Pointer(Schema), Length(Schema));
    Sch := xmlSchemaParse(SchemaP);
    if Sch = nil then raise Exception.Create('schema parse');
    Best('XSD validate', Length(Utf8Doc), procedure begin
      V := xmlSchemaNewValidCtxt(Sch);
      if xmlSchemaValidateDoc(V, Doc) <> 0 then raise Exception.Create('invalid');
      xmlSchemaFreeValidCtxt(V);
    end);
    xmlSchemaFree(Sch);
    xmlSchemaFreeParserCtxt(SchemaP);
  end;
  xmlFreeDoc(Doc);
end;

procedure RunThreads(N: Integer);
var
  Done: TCountdownEvent;
  t: Integer;
  SW: TStopwatch;
begin
  Done := TCountdownEvent.Create(N);
  SW := TStopwatch.StartNew;
  for t := 1 to N do
    TThread.CreateAnonymousThread(procedure
    var
      r: Integer;
      D: xmlDocPtr;
    begin
      for r := 1 to Runs do
      begin
        D := xmlReadMemory(@Utf8Doc[0], Length(Utf8Doc) - 1, 'a.xml', nil, Opts);
        xmlFreeDoc(D);
      end;
      Done.Signal;
    end).Start;
  Done.WaitFor;
  Writeln(Format('%d threads x %d DOM parses: %8.1f ms wall, %7.1f MB/s aggregate',
    [N, Runs, SW.Elapsed.TotalMilliseconds,
     Int64(Length(Utf8Doc)) * N * Runs / 1048576 / (SW.Elapsed.TotalMilliseconds / 1000)]));
  Done.Free;
end;

// --- verification ---------------------------------------------------------------------

function B(const S: string): TBytes;
begin
  Result := TEncoding.UTF8.GetBytes(S);
end;

function B1251(const S: string): TBytes;
begin
  Result := TEncoding.GetEncoding(1251).GetBytes(S);
end;

procedure VerifyDump(const Name: string; Doc: xmlDocPtr; const Enc: UTF8String);
var
  Mem: Pointer;
  Size: Integer;
begin
  Mem := nil;
  Size := 0;
  if Enc = '' then
    xmlDocDumpMemory(Doc, Mem, Size)
  else
    xmlDocDumpMemoryEnc(Doc, Mem, Size, PUTF8Char(Enc));
  if Mem = nil then
    Writeln(Name, ': nil')
  else
    Writeln(Name, ': ', Size, ' ', IntToHex(Fnv(Mem, Size)));
  if Mem <> nil then
    xmlFree(Mem);
end;

procedure VerifyCase(const Name: string; const Bytes: TBytes);
var
  Doc: xmlDocPtr;
  E: xmlErrorPtr;
begin
  xmlResetLastError;
  Doc := xmlReadMemory(@Bytes[0], Length(Bytes), 'c.xml', nil, 0);
  E := xmlGetLastError;
  Write(Name, ': doc=', Ord(Doc <> nil));
  if E <> nil then
    Write(' code=', E.code, ' line=', E.line, ' col=', E.int2, ' msg=',
      string(UTF8String(E.message)).Trim.Replace(#10, ' '));
  Writeln;
  if Doc <> nil then
  begin
    VerifyDump('  ' + Name + ' dump', Doc, '');
    xmlFreeDoc(Doc);
  end;
end;

procedure Verify;
var
  Doc: xmlDocPtr;
  SAX: xmlSAXHandler;
  PCtx: xmlParserCtxtPtr;
  i, Res: Integer;
  U: UTF8String;
begin
  Doc := xmlReadMemory(@Utf8Doc[0], Length(Utf8Doc) - 1, 'a.xml', nil, 0);
  VerifyDump('big utf8', Doc, 'UTF-8');
  VerifyDump('big cp1251', Doc, 'windows-1251');
  VerifyDump('big koi8-r', Doc, 'KOI8-R');
  VerifyDump('big cp866', Doc, 'cp866');
  VerifyDump('big iso-8859-5', Doc, 'ISO-8859-5');
  VerifyDump('big utf-16', Doc, 'UTF-16');
  xmlFreeDoc(Doc);
  Doc := xmlReadMemory(@Cp1251Doc[0], Length(Cp1251Doc), 'a.xml', nil, 0);
  VerifyDump('big from cp1251 -> utf8', Doc, 'UTF-8');
  xmlFreeDoc(Doc);

  // push parser fed in 7-byte pieces: multi-byte sequences are split at every boundary
  FillChar(SAX, SizeOf(SAX), 0);
  SAX.initialized := XML_SAX2_MAGIC;
  SAX.startElementNs := OnStart;
  SAX.endElementNs := OnEnd;
  SAX.characters := OnCharsHash;
  Elems := 0;
  Chars := 0;
  PushHash := 0;
  PCtx := xmlCreatePushParserCtxt(@SAX, nil, nil, 0, nil);
  i := 0;
  Res := 0;
  while i < Length(Utf8Doc) - 1 do
  begin
    Res := xmlParseChunk(PCtx, @Utf8Doc[i], Min(7, Length(Utf8Doc) - 1 - i), 0);
    if Res <> 0 then
      Break;
    Inc(i, 7);
  end;
  if Res = 0 then
    Res := xmlParseChunk(PCtx, nil, 0, 1);
  Writeln('push7: res=', Res, ' elems=', Elems, ' chars=', Chars, ' hash=', IntToHex(PushHash));
  xmlFreeParserCtxt(PCtx);

  VerifyCase('overlong C0 80', B('<r>ab') + [$C0, $80] + B('cd</r>'));
  VerifyCase('surrogate ED A0 80', B('<r>ab') + [$ED, $A0, $80] + B('</r>'));
  VerifyCase('U+FFFE', B('<r>ab') + [$EF, $BF, $BE] + B('</r>'));
  VerifyCase('U+FFFF', B('<r>ab') + [$EF, $BF, $BF] + B('</r>'));
  VerifyCase('U+FFFD ok', B('<r>ab') + [$EF, $BF, $BD] + B('</r>'));
  VerifyCase('F5 lead', B('<r>ab') + [$F5, $80, $80, $80] + B('</r>'));
  VerifyCase('overlong E0 9F BF', B('<r>ab') + [$E0, $9F, $BF] + B('</r>'));
  VerifyCase('overlong F0 8F BF BF', B('<r>ab') + [$F0, $8F, $BF, $BF] + B('</r>'));
  VerifyCase('above U+10FFFF', B('<r>ab') + [$F4, $90, $80, $80] + B('</r>'));
  VerifyCase('U+10FFFF ok', B('<r>ab') + [$F4, $8F, $BF, $BF] + B('</r>'));
  VerifyCase('emoji 4-byte', B('<r>ab') + [$F0, $9F, $98, $80] + B('x</r>'));
  VerifyCase('truncated at EOF', B('<r>ab') + [$D0]);
  VerifyCase('truncated before tag', B('<r>ab') + [$D0] + B('<x/></r>'));
  VerifyCase('bad continuation', B('<r>ab') + [$D0, $41] + B('</r>'));
  VerifyCase('line 3 col', B('<r>'#10'ab'#10'xyабв') + [$C0] + B('</r>'));
  VerifyCase('cdata end in text', B('<r>aб]]>c</r>'));
  VerifyCase('cr lf mix', B('<r>а'#13#10'б'#13'в'#10'г</r>'));
  VerifyCase('long cyrillic', B('<r>' + StringOfChar('ж', 5000) + '</r>'));
  VerifyCase('attr cyrillic', B('<r a="ключ  значение" b="&amp;'#10'x">т</r>'));
  VerifyCase('control char', B('<r>a') + [$01] + B('b</r>'));
  VerifyCase('cp1251 undefined 98', B1251('<?xml version="1.0" encoding="windows-1251"?><r>a') + [$98] + B1251('b</r>'));
  VerifyCase('cp1251 all', B1251('<?xml version="1.0" encoding="windows-1251"?><r>АБВабвёЁ€№™—«»</r>'));
  VerifyCase('koi8-r', TEncoding.GetEncoding(20866).GetBytes('<?xml version="1.0" encoding="KOI8-R"?><r>АБВабвёЁ</r>'));
  U := UTF8String('<r>€№™ĉ АБВ</r>');
  Doc := xmlReadMemory(Pointer(U), Length(U), 'u.xml', nil, 0);
  VerifyDump('unmappable -> cp1251', Doc, 'windows-1251');
  VerifyDump('unmappable -> koi8-r', Doc, 'KOI8-R');
  VerifyDump('unmappable -> cp866', Doc, 'cp866');
  VerifyDump('unmappable -> ascii', Doc, 'us-ascii');
  xmlFreeDoc(Doc);
end;

// --- main -----------------------------------------------------------------------------

var
  Items: Integer = 120000;
  Threads: Integer = 0;
  DoVerify: Boolean = False;
  HostMM: Boolean = False;
  i: Integer;
  U: string;
begin
  for i := 1 to ParamCount do
    if ParamStr(i).StartsWith('--items=') then Items := StrToInt(ParamStr(i).Substring(8))
    else if ParamStr(i).StartsWith('--runs=') then Runs := StrToInt(ParamStr(i).Substring(7))
    else if ParamStr(i).StartsWith('--opts=') then Opts := StrToInt(ParamStr(i).Substring(7))
    else if ParamStr(i).StartsWith('--threads=') then Threads := StrToInt(ParamStr(i).Substring(10))
    else if ParamStr(i).StartsWith('--file=') then SrcFile := ParamStr(i).Substring(7)
    else if ParamStr(i).StartsWith('--xsd=') then SchemaFile := ParamStr(i).Substring(6)
    else if ParamStr(i) = '--verify' then DoVerify := True
    else if ParamStr(i) = '--longtext' then LongText := True
    else if ParamStr(i) = '--hostmm' then HostMM := True
    else if ParamStr(i) = '--orderdoc' then OrderDoc := True
    else
    begin
      Writeln('unknown option: ', ParamStr(i));
      Halt(2);
    end;

{$IFNDEF LX2_WITHOUT_HOSTMM}   // defined only to build against an LX2 that predates the flag
  LX2Lib.UseHostMemoryManager := HostMM;
{$ENDIF}
  LX2Lib.Initialize;
  SchemaU8 := UTF8String(SchemaFile);

  if SrcFile <> '' then
  begin
    Utf8Doc := TFile.ReadAllBytes(SrcFile);
    U := TEncoding.UTF8.GetString(Utf8Doc);
    if U.StartsWith('<?xml') then
      U := U.Substring(U.IndexOf('?>') + 2);
    XPath1 := '//*[not(*)]';
    XPath2 := 'count(//*[contains(., "1")])';
  end
  else
  begin
    U := BuildDoc(Items);
    Utf8Doc := TEncoding.UTF8.GetBytes('<?xml version="1.0" encoding="UTF-8"?>'#10 + U);
  end;
  SetLength(Utf8Doc, Length(Utf8Doc) + 1);
  Utf8Doc[High(Utf8Doc)] := 0;
  Cp1251Doc := TEncoding.GetEncoding(1251).GetBytes('<?xml version="1.0" encoding="windows-1251"?>' + U);
  Writeln(Format('source=%s utf8=%.1f MB cp1251=%.1f MB runs=%d hostmm=%d',
    [string(SrcFile), (Length(Utf8Doc) - 1) / 1048576, Length(Cp1251Doc) / 1048576, Runs, Ord(HostMM)]));
  if DoVerify then
    Verify
  else if Threads > 0 then
    RunThreads(Threads)
  else
    Run;
end.
