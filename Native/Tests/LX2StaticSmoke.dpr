// Checks the static linking of libxml2 and libxslt (the LX2.Static unit); run by
// Native\Build.ps1 -Test. Covers parsing a windows-1251 document (iconv on top of WinAPI),
// dumping it back to windows-1251, XPath, an XSLT transformation and a parse error report,
// that is every path that needs the C runtime and Win32 from LX2.Static.

program LX2StaticSmoke;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  libxml2.API,
  libxslt.API,
  LX2.Static;

const
  Cp1251Privet: AnsiString = #$CF#$F0#$E8#$E2#$E5#$F2; // 'Привет' (hello) in windows-1251

var
  Failed: Integer = 0;
  Passed: Integer = 0;

procedure Check(Cond: Boolean; const Name: string);
begin
  if Cond then
    Inc(Passed)
  else
  begin
    Inc(Failed);
    Writeln('FAILED: ', Name);
  end;
end;

function Utf8Privet: UTF8String;
begin
  Result := UTF8Encode('Привет');
end;

procedure TestLoad;
begin
  LX2Lib.Initialize;
  Check(LX2Lib.IsLoaded, 'LX2Lib.IsLoaded');
  Check(LX2Lib.LibraryFileName = '', 'LX2Lib bound statically, no library file');
  XSLTLib.Initialize;
  Check(XSLTLib.IsLoaded, 'XSLTLib.IsLoaded');
end;

procedure TestParseAndEncodings;
var
  Src: AnsiString;
  Doc: xmlDocPtr;
  Root: xmlNodePtr;
  Content: xmlCharPtr;
  Mem: Pointer;
  Size: Integer;
  Dump: AnsiString;
begin
  Src := '<?xml version="1.0" encoding="windows-1251"?><root a="1">' + Cp1251Privet + '</root>';
  Doc := xmlReadMemory(Pointer(Src), Length(Src), 'smoke.xml', nil, 0);
  Check(Doc <> nil, 'xmlReadMemory windows-1251');
  if Doc = nil then
    Exit;
  Root := xmlDocGetRootElement(Doc);
  Check(Root <> nil, 'xmlDocGetRootElement');
  Content := xmlNodeGetContent(Root);
  Check((Content <> nil) and (UTF8String(Content) = Utf8Privet), 'content decoded from windows-1251 to UTF-8');
  xmlFree(Content);

  Mem := nil;
  Size := 0;
  xmlDocDumpMemoryEnc(Doc, Mem, Size, 'windows-1251');
  Check((Mem <> nil) and (Size > 0), 'xmlDocDumpMemoryEnc');
  if Mem <> nil then
  begin
    SetString(Dump, PAnsiChar(Mem), Size);
    Check(Pos(Cp1251Privet, Dump) > 0, 'content encoded back to windows-1251');
    Check(Pos(AnsiString('encoding="windows-1251"'), Dump) > 0, 'declaration names the encoding');
    xmlFree(Mem);
  end;
  xmlFreeDoc(Doc);
end;

procedure TestXPath;
var
  Doc: xmlDocPtr;
  Ctx: xmlXPathContextPtr;
  Obj: xmlXPathObjectPtr;
  Src: UTF8String;
begin
  Src := '<r><i v="1"/><i v="2"/><i v="3"/></r>';
  Doc := xmlReadMemory(Pointer(Src), Length(Src), nil, nil, 0);
  Check(Doc <> nil, 'xmlReadMemory for XPath');
  if Doc = nil then
    Exit;
  Ctx := xmlXPathNewContext(Doc);
  Obj := xmlXPathEvalExpression('sum(//i/@v) div count(//i)', Ctx);
  Check((Obj <> nil) and (Abs(Obj.floatval - 2.0) < 1E-9), 'XPath sum/div/count = 2 (floating point through ucrtbase)');
  if Obj <> nil then
    xmlXPathFreeObject(Obj);
  xmlXPathFreeContext(Ctx);
  xmlFreeDoc(Doc);
end;

procedure TestXslt;
var
  Src, Xsl: UTF8String;
  Doc, StyleDoc, Res: xmlDocPtr;
  Style: xsltStylesheetPtr;
  Txt: xmlCharPtr;
  Len: Integer;
begin
  Src := '<root>' + Utf8Privet + '</root>';
  Xsl := '<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">' +
         '<xsl:output method="text"/>' +
         '<xsl:template match="/"><xsl:value-of select="concat(''ok:'', /root)"/></xsl:template>' +
         '</xsl:stylesheet>';
  Doc := xmlReadMemory(Pointer(Src), Length(Src), nil, nil, 0);
  StyleDoc := xmlReadMemory(Pointer(Xsl), Length(Xsl), 'smoke.xsl', nil, 0);
  Check((Doc <> nil) and (StyleDoc <> nil), 'documents for XSLT');
  if (Doc = nil) or (StyleDoc = nil) then
    Exit;
  Style := xsltParseStylesheetDoc(StyleDoc);
  Check(Style <> nil, 'xsltParseStylesheetDoc');
  if Style <> nil then
  begin
    Res := xsltApplyStylesheet(Style, Doc, nil);
    Check(Res <> nil, 'xsltApplyStylesheet');
    if Res <> nil then
    begin
      Txt := nil;
      Len := 0;
      Check(xsltSaveResultToString(Txt, Len, Res, Style) = 0, 'xsltSaveResultToString');
      Check((Txt <> nil) and (UTF8String(Txt) = 'ok:' + Utf8Privet), 'XSLT result text');
      xmlFree(Txt);
      xmlFreeDoc(Res);
    end;
    xsltFreeStylesheet(Style); // owns StyleDoc
  end;
  xmlFreeDoc(Doc);
end;

procedure TestParseError;
var
  Src: UTF8String;
  Doc: xmlDocPtr;
  Err: xmlErrorPtr;
begin
  Src := '<root><unclosed></root>';
  Doc := xmlReadMemory(Pointer(Src), Length(Src), 'bad.xml', nil, 0);
  Check(Doc = nil, 'malformed document is rejected');
  Err := xmlGetLastError;
  Check((Err <> nil) and (Err.message <> nil) and (Err.line = 1), 'xmlGetLastError reports the error (snprintf path)');
  if Doc <> nil then
    xmlFreeDoc(Doc);
end;

begin
  try
    TestLoad;
    TestParseAndEncodings;
    TestXPath;
    TestXslt;
    TestParseError;
    LX2Lib.Unload;
    Writeln(Format('passed %d, failed %d', [Passed, Failed]));
    if Failed > 0 then
      ExitCode := 1;
  except
    on E: Exception do
    begin
      Writeln('EXCEPTION: ', E.ClassName, ': ', E.Message);
      ExitCode := 2;
    end;
  end;
end.
