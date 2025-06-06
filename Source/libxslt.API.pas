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

unit libxslt.API;

interface

{$ALIGN 8}
{$MINENUMSIZE 4}

uses
  {$IFDEF MSWINDOWS}
    Winapi.Windows,
  {$ENDIF}
  {$IFDEF POSIX}
    Posix.StdDef,
  {$ENDIF}
  System.Types, System.SysUtils, libxml2.API, LX2.Types;

const
  {$IFDEF MSWINDOWS}
  libxslt = 'libxslt.dll';
  {$ENDIF}
  {$IFDEF POSIX}
  libxslt = 'libxslt.so';
  {$ENDIF}

type
  xsltPointerListPtr = ^xsltPointerList;
  xsltPointerList = record
    items: PPointer;
    number: Integer;
    size: Integer;
  end;

  xmlHashTablePtr = ^xmlHashTable;
  xmlHashTable = record end;

  xsltStackElemPtr = ^xsltStackElem;
  xsltStackElem = record end;

  xsltCompMatchPtr = ^xsltCompMatch;
  xsltCompMatch = record end;

  xsltDecimalFormatPtr = ^xsltDecimalFormat;
  xsltDecimalFormat = record end;

  xsltElemPreCompPtr = ^xsltElemPreComp;
  xsltElemPreComp = record end;

  ///<summary>Data structure associated to a parsed document.</summary>
  xsltDocumentPtr = ^xsltDocument;

  xsltStylesheetPtr = ^xsltStylesheet;

  /// <summary>
  /// The in-memory structure corresponding to an XSLT Template.
  /// </summary>
  xsltTemplatePtr = ^xsltTemplate;
  xsltTemplate = record
    ///<summary>chained list sorted by priority</summary>
    next: xsltTemplatePtr;
    ///<summary>the containing stylesheet</summary>
    style: xsltStylesheetPtr;
    ///<summary>the matching string</summary>
    match: xmlCharPtr;
    ///<summary>as given from the stylesheet, not computed</summary>
    priority: Single;
    ///<summary>the local part of the name QName</summary>
    name: xmlCharPtr;
    ///<summary>the URI part of the name QName</summary>
    nameURI: xmlCharPtr;
    ///<summary>the local part of the mode QName</summary>
    mode: xmlCharPtr;
    ///<summary>the URI part of the mode QName</summary>
    modeURI: xmlCharPtr;
    ///<summary>the template replacement value</summary>
    content: xmlNodePtr;
    ///<summary>the source element</summary>
    elem: xmlNodePtr;
    ///<summary>number of inherited namespaces</summary>
    inheritedNsNr: Integer;
    ///<summary>inherited non-excluded namespaces</summary>
    inheritedNs: xmlNsPtr;
    ///<summary>the number of time the template was called</summary>
    nbCalls: Integer;
    ///<summary>the time spent in this template</summary>
    time: ulong;
    ///<summary>xsl:param instructions</summary>
    params: Pointer;
    ///<summary>Nb of templates in the stack</summary>
    templNr: Integer;
    ///<summary>Size of the templates stack</summary>
    templMax: Integer;
    ///<summary>templates called</summary>
    templCalledTab: xsltTemplatePtr;
    ///<summary>how often templates called</summary>
    templCountTab: PInteger;
    ///<summary>Conflict resolution</summary>
    position: Integer;
  end;

  ///<summary>Data structure associated to a parsed document.</summary>
  xsltDocument = record
    ///<summary>documents are kept in a chained list</summary>
    next: xsltDocumentPtr;
    ///<summary>is this the main document</summary>
    main: Integer;
    ///<summary>the parsed document</summary>
    doc: xmlDocPtr;
    ///<summary>key tables storage</summary>
    keys: Pointer;
    ///<summary>subsidiary includes</summary>
    includes: xsltDocumentPtr;
    ///<summary>pre-processing already done</summary>
    preproc: Integer;

    nbKeysComputed: Integer;
  end;

  xsltStylesheet = record
    ///<summary>The stylesheet import relation is kept as a tree.</summary>
    parent: xsltStylesheetPtr;
    next: xsltStylesheetPtr;
    imports: xsltStylesheetPtr;

    ///<summary>the include document list</summary>
    docList: xsltDocumentPtr;

    ///<summary>the parsed XML stylesheet</summary>
    doc: xmlDocPtr;
    ///<summary>the hash table of the strip-space and  preserve space elements</summary>
    stripSpaces: xmlHashTablePtr;
    ///<summary>strip-space * (1) preserve-space * (-1)</summary>
    stripAll: Integer;
    ///<summary>the hash table of the cdata-section</summary>
    cdataSection: xmlHashTablePtr;

    ///<summary>linked list of param and variables</summary>
    variables: xsltStackElemPtr;

    ///<summary>the ordered list of templates</summary>
    templates: xsltTemplatePtr;
    ///<summary>hash table or wherever compiled templates information is stored</summary>
    templatesHash: xmlHashTablePtr;
    ///<summary>template based on</summary>
    _rootMatch: xsltCompMatchPtr;
    ///<summary>template based on key()</summary>
    keyMatch: xsltCompMatchPtr;
    ///<summary>template based on *</summary>
    elemMatch: xsltCompMatchPtr;
    ///<summary>template based on @*</summary>
    attrMatch: xsltCompMatchPtr;
    ///<summary>template based on ..</summary>
    parentMatch: xsltCompMatchPtr;
    ///<summary>template based on text()</summary>
    textMatch: xsltCompMatchPtr;
    ///<summary>template based on processing-instruction()</summary>
    piMatch: xsltCompMatchPtr;
    ///<summary>template based on comment()</summary>
    commentMatch: xsltCompMatchPtr;
    ///<summary>the namespace alias hash tables</summary>
    nsAliases: xmlHashTablePtr;
    ///<summary>the attribute sets hash tables</summary>
    attributeSets: xmlHashTablePtr;
    ///<summary>the set of namespaces in use</summary>
    nsHash: xmlHashTablePtr;
    ///<summary>This is currently used to store</summary>
    nsDefs: Pointer;
    ///<summary>key definitions</summary>
    keys: Pointer;
    ///<summary>the output method</summary>
    method: xmlCharPtr;
    ///<summary>associated namespace if any</summary>
    methodURI: xmlCharPtr;
    ///<summary>version string</summary>
    version: xmlCharPtr;
    ///<summary>encoding string</summary>
    encoding: xmlCharPtr;
    ///<summary>omit-xml-declaration = "yes" | "no"</summary>
    omitXmlDeclaration: Integer;
    decimalFormat: xsltDecimalFormatPtr;
    ///<summary>standalone = "yes" | "no"</summary>
    standalone: Integer;
    ///<summary>doctype-public string</summary>
    doctypePublic: xmlCharPtr;
    ///<summary>doctype-system string</summary>
    doctypeSystem: xmlCharPtr;
    ///<summary>should output being indented</summary>
    indent: Integer;
    ///<summary>media-type string</summary>
    mediaType: xmlCharPtr;
    ///<summary>list of precomputed blocks</summary>
    preComps: xsltElemPreCompPtr;
    ///<summary>number of warnings found at compilation</summary>
    warnings: Integer;
    ///<summary>number of errors found at compilation</summary>
    errors: Integer;
    ///<summary>last excluded prefixes</summary>
    exclPrefix: xmlCharPtr;
    ///<summary>array of excluded prefixes</summary>
    exclPrefixTab: xmlCharPtrArrayPtr;
    ///<summary>number of excluded prefixes in scope</summary>
    exclPrefixNr: Integer;
    ///<summary>size of the array</summary>
    exclPrefixMax: Integer;
    ///<summary>user defined data</summary>
    _private: Pointer;
    ///<summary>the extension data</summary>
    extInfos: xmlHashTablePtr;
    ///<summary>the number of extras required</summary>
    extrasNr: Integer;
    ///<summary>points to last nested include</summary>
    includes: xsltDocumentPtr;
    dict: xmlDictPtr;
    attVTs: Pointer;
    defaultAlias: xmlCharPtr;
    nopreproc: Integer;
    internalized: Integer;
    literal_result: Integer;
    principal: xsltStylesheetPtr;
  end;

var
  xsltInit                 : procedure; cdecl;
  xsltInitGlobals          : procedure; cdecl;
  xsltCleanupGlobals       : procedure; cdecl;
  xsltNewStylesheet        : function: xsltStylesheetPtr; cdecl;
  xsltParseStylesheetFile  : function (const filename: xmlCharPtr): xsltStylesheetPtr; cdecl;
  xsltParseStylesheetDoc   : function (doc: xmlDocPtr): xsltStylesheetPtr; cdecl;
  xsltParseStylesheetUser  : function (style: xsltStylesheetPtr; doc: xmlDocPtr): Integer; cdecl;
  xsltFreeStylesheet       : procedure(style: xsltStylesheetPtr); cdecl;
  xsltApplyStylesheet      : function (style: xsltStylesheetPtr; doc: xmlDocPtr; params: xmlCharPtrArrayPtr): xmlDocPtr; cdecl;
  xsltSetGenericErrorFunc  : procedure(ctx: Pointer; handler: xmlGenericErrorFunc); cdecl;
  xsltSaveResultTo         : function (buf: xmlOutputBufferPtr; result: xmlDocPtr; style: xsltStylesheetPtr): Integer; cdecl;
  xsltSaveResultToFilename : function (URI: PUTF8Char; result: xmlDocPtr; style: xsltStylesheetPtr; compression: Integer): Integer; cdecl;
  xsltSaveResultToFd       : function (fd: Integer; result: xmlDocPtr; style: xsltStylesheetPtr): Integer; cdecl;
  xsltSaveResultToString   : function (var doc_txt_ptr: xmlCharPtr; var doc_txt_len: Integer; result: xmlDocPtr; style: xsltStylesheetPtr): Integer; cdecl;
  xsltSetXIncludeDefault   : procedure(xinclude: Integer); cdecl;
  xsltGetXIncludeDefault   : function: Integer; cdecl;

type
  XSLTLib = record
  private class var
    FIsLoaded: Boolean;
    FLibraryFileName: string;
    Handle: THandle;
  public
    class procedure Initialize; static;
    class procedure Load(const LibraryFileName: string = libxslt); static;
    class procedure Unload; static;
    class property IsLoaded: Boolean read FIsLoaded;
    class property LibraryFileName: string read FLibraryFileName;
  end;

  TXLSErrorHandler = procedure(Context: Pointer; const Msg: string);

  TXSLTThreadErrorContext = record
  public
    class procedure Start(Context: Pointer; const Handler: TXLSErrorHandler); static;
    class procedure Stop; static;
  end;

implementation

threadvar
  ThreadErrorHandler: TXLSErrorHandler;
  ThreadErrorContext: Pointer;

procedure XSLTErrorCallback(ctx: Pointer; const msg: xmlCharPtr); cdecl;
begin
  if Assigned(ThreadErrorHandler) then
    ThreadErrorHandler(ThreadErrorContext, xmlCharToStr(msg));
end;

{ TXSLTThreadErrorContext }

class procedure TXSLTThreadErrorContext.Start(Context: Pointer; const Handler: TXLSErrorHandler);
begin
  ThreadErrorHandler := Handler;
  ThreadErrorContext := Context;
end;

class procedure TXSLTThreadErrorContext.Stop;
begin
  ThreadErrorHandler := nil;
  ThreadErrorContext := nil;
end;

{ XSLTLib }

class procedure XSLTLib.Initialize;
begin
  if Handle = 0 then
    Load;
  xsltSetGenericErrorFunc(nil, XSLTErrorCallback);
end;

class procedure XSLTLib.Unload;
begin
  if Handle <> 0 then
  begin
    xsltCleanupGlobals;

    FreeLibrary(Handle);
    Handle := 0;
  end;
end;

class procedure XSLTLib.Load(const LibraryFileName: string);
begin
  if Handle <> 0 then
    Unload;

  Handle := SafeLoadLibrary(LibraryFileName);

  if Handle = 0 then
    RaiseLastOSError;

{$region 'load procs'}
  xsltInit                 := GetProcAddress(Handle, 'xsltInit');
  xsltInitGlobals          := GetProcAddress(Handle, 'xsltInitGlobals');
  xsltCleanupGlobals       := GetProcAddress(Handle, 'xsltCleanupGlobals');
  xsltNewStylesheet        := GetProcAddress(Handle, 'xsltNewStylesheet');
  xsltParseStylesheetFile  := GetProcAddress(Handle, 'xsltParseStylesheetFile');
  xsltParseStylesheetDoc   := GetProcAddress(Handle, 'xsltParseStylesheetDoc');
  xsltParseStylesheetUser  := GetProcAddress(Handle, 'xsltParseStylesheetUser');
  xsltFreeStylesheet       := GetProcAddress(Handle, 'xsltFreeStylesheet');
  xsltApplyStylesheet      := GetProcAddress(Handle, 'xsltApplyStylesheet');
  xsltSetGenericErrorFunc  := GetProcAddress(Handle, 'xsltSetGenericErrorFunc');
  xsltSaveResultTo         := GetProcAddress(Handle, 'xsltSaveResultTo');
  xsltSaveResultToFilename := GetProcAddress(Handle, 'xsltSaveResultToFilename');
  xsltSaveResultToFd       := GetProcAddress(Handle, 'xsltSaveResultToFd');
  xsltSaveResultToString   := GetProcAddress(Handle, 'xsltSaveResultToString');
  xsltSetXIncludeDefault   := GetProcAddress(Handle, 'xsltSetXIncludeDefault');
  xsltGetXIncludeDefault   := GetProcAddress(Handle, 'xsltGetXIncludeDefault');

{$endregion}

  xsltInit;
  xsltInitGlobals;
end;


initialization

finalization
  XSLTLib.Unload;

end.
