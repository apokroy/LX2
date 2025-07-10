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
/// This Unit contains a set of helpers designed to comfortable use generic libxml2 types and functions
///</summary>

unit LX2.Helpers;

interface

uses
  System.SysUtils, System.Classes,
  libxml2.API, LX2.Types;

type
  xmlNodeArray  = TArray<xmlNodePtr>;
  xmlAttrArray  = TArray<xmlAttrPtr>;

  xmlDocErrorHandler  = procedure(const error: xmlError) of object;
  xmlResourceLoader   = function(const url, publicId: xmlCharPtr; resType: xmlResourceType; Flags: Integer; var output: xmlParserInputPtr): Integer of object;
  xsltErrorHandler    = procedure(const Msg: string) of object;

  xmlNamespace = record
    Prefix: RawByteString;
    URI: RawByteString;
  end;

  xmlNamespaces = TArray<xmlNamespace>;

  xmlNamespacesHelper = record helper for xmlNamespaces
    procedure Add(const Prefix, URI: RawByteString); inline;
    function  Count: NativeInt; inline;
  end;

  xmlNodeHelper = record helper for xmlNode
  private type
    TSelf = type xmlNode;
  private
    function  GetNodeName: RawByteString; inline;
    function  GetNodeType: xmlElementType; inline;
    function  GetAttributes: xmlAttrArray;
    function  GetChildNodes: xmlNodeArray;
    function  GetFirstChild: xmlNodePtr; inline;
    function  GetLastChild: xmlNodePtr; inline;
    function  GetLocalName: RawByteString; inline;
    function  GetNamespaceURI: RawByteString; inline;
    function  GetNextSibling: xmlNodePtr; inline;
    function  GetNodeValue: RawByteString; inline;
    function  GetOwnerDocument: xmlDocPtr; inline;
    function  GetParentElement: xmlNodePtr;
    function  GetParentNode: xmlNodePtr; inline;
    function  GetPrefix: RawByteString; inline;
    function  GetPreviousSibling: xmlNodePtr; inline;
    function  GetTagName: RawByteString; inline;
    function  GetText: RawByteString; inline;
    function  GetXml: RawByteString;
    procedure SetNodeValue(const Value: RawByteString); inline;
    procedure SetText(const Value: RawByteString); inline;
    function  GetPath: RawByteString; inline;
    function  GetBaseURI: RawByteString; inline;
    procedure SetBaseURI(const Value: RawByteString); inline;
    function  GetValue: RawByteString;
    procedure SetNodeName(const Value: RawByteString); inline;
  public
    function  AddChild(const Name: RawByteString; const Content: RawByteString = ''): xmlNodePtr;
    function  AddChildNs(const Name, NamespaceURI: RawByteString; const Content: RawByteString = ''): xmlNodePtr;
    function  AppendChild(const NewChild: xmlNodePtr): xmlNodePtr; inline;
    function  ChildElementCount: NativeInt; inline;
    function  CloneNode(Deep: Boolean): xmlNodePtr; inline;
    function  Contains(const Node: xmlNodePtr): Boolean; inline;
    function  FirstElementChild: xmlNodePtr; inline;
    function  GetAttribute(const Name: RawByteString): RawByteString; inline;
    function  GetAttributeNode(const name: RawByteString): xmlAttrPtr; overload;
    function  GetAttributeNodeNs(const namespaceURI, name: RawByteString): xmlAttrPtr; overload;
    function  GetAttributeNs(const NamespaceURI, Name: RawByteString): RawByteString; inline;
    function  GetElementsByTagName(const Name: RawByteString): xmlNodeArray;
    function  GetNext(Root: xmlNodePtr): xmlNodePtr;
    function  GetRootNode: xmlNodePtr; inline;
    function  HasAttribute(const Name: RawByteString): Boolean; inline;
    function  HasAttributeNs(const NamespaceURI, Name: RawByteString): Boolean; inline;
    function  HasAttributes: Boolean; inline;
    function  HasChildNodes: Boolean; inline;
    function  InsertBefore(const NewChild, RefChild: xmlNodePtr): xmlNodePtr;
    function  IsBlank: Boolean; inline;
    function  IsDefaultNamespace(const namespaceURI: RawByteString): Boolean; inline;
    function  IsText: Boolean; inline;
    function  LastElementChild: xmlNodePtr; inline;
    function  NextElementSibling: xmlNodePtr; inline;
    property  Path: RawByteString read GetPath;
    function  PreviousElementSibling: xmlNodePtr; inline;
    procedure ReconciliateNs; inline;
    procedure RemoveAttribute(const name: RawByteString); inline;
    procedure RemoveAttributeNode(const Attr: xmlAttrPtr); inline;
    function  RemoveChild(const ChildNode: xmlNodePtr): xmlNodePtr; inline;
    function  ReplaceChild(const NewChild, OldChild: xmlNodePtr): xmlNodePtr; inline;
    function  SearchNs(const Prefix: RawByteString): xmlNsPtr; overload; inline;
    function  SearchNs(const Prefix: xmlCharPtr): xmlNsPtr; overload; inline;
    function  SearchNsByRef(const href: RawByteString): xmlNsPtr; overload; inline;
    function  SearchNsByRef(const href: xmlCharPtr): xmlNsPtr; overload; inline;
    function  SelectNodes(const QueryString: RawByteString; const Namespaces: xmlNamespaces = nil): xmlNodeArray;
    function  SelectSingleNode(const QueryString: RawByteString): xmlNodePtr;
    procedure SetAttribute(const Name: RawByteString; const Value: RawByteString);
    function  SetAttributeNs(const NamespaceURI, Name: RawByteString; const Value: RawByteString): xmlAttrPtr; inline;
    function  Transform(const stylesheet: xmlDocPtr; out doc: xmlDocPtr; errorHandler: xsltErrorHandler = nil): Boolean; overload;
    function  Transform(const stylesheet: xmlDocPtr; out S: RawByteString; errorHandler: xsltErrorHandler = nil): Boolean; overload;
    function  Transform(const stylesheet: xmlDocPtr; out S: string; errorHandler: xsltErrorHandler = nil): Boolean; overload;
    function  Transform(const stylesheet: xmlDocPtr; Stream: TStream; errorHandler: xsltErrorHandler = nil): Boolean; overload;
    property  Value: RawByteString read GetValue;
    function  XPathEval(const queryString: RawByteString; const namespaces: xmlNamespaces; ErrorHandler: xmlDocErrorHandler): xmlXPathObjectPtr;
    property  Attribute[const name: RawByteString]: RawByteString read GetAttribute write SetAttribute;
    property  Attributes: xmlAttrArray read GetAttributes;
    property  BaseURI: RawByteString read GetBaseURI write SetBaseURI;
    property  ChildNodes: xmlNodeArray read GetChildNodes;
    property  FirstChild: xmlNodePtr read GetFirstChild;
    property  LastChild: xmlNodePtr read GetLastChild;
    property  LocalName: RawByteString read GetLocalName;
    property  NamespaceURI: RawByteString read GetNamespaceURI;
    property  NextSibling: xmlNodePtr read GetNextSibling;
    property  NodeName: RawByteString read GetNodeName write SetNodeName;
    property  NodeType: XmlElementType read GetNodeType;
    property  NodeValue: RawByteString read GetNodeValue write SetNodeValue;
    property  OwnerDocument: xmlDocPtr read GetOwnerDocument;
    property  ParentElement: xmlNodePtr read GetParentElement;
    property  ParentNode: xmlNodePtr read GetParentNode;
    property  Prefix: RawByteString read GetPrefix;
    property  PreviousSibling: xmlNodePtr read GetPreviousSibling;
    property  TagName: RawByteString read GetTagName;
    property  Text: RawByteString read GetText write SetText;
    property  Xml: RawByteString read GetXml;
  end;

  xmlAttrHelper = record helper for xmlAttr
  private type
    TSelf = type xmlAttr;
  private
    function  GetName: RawByteString; inline;
    function  GetNamespaceURI: RawByteString; inline;
    function  GetNextSibling: xmlAttrPtr; inline;
    function  GetValue: RawByteString;
    function  GetOwnerDocument: xmlDocPtr; inline;
    function  GetPrefix: RawByteString; inline;
    function  GetPreviousSibling: xmlAttrPtr; inline;
    procedure SetValue(const Value: RawByteString); inline;
    function  GetBaseURI: RawByteString; inline;
    procedure SetBaseURI(const Value: RawByteString); inline;
    function  GetLocalName: RawByteString; inline;
    procedure SetLocalName(const Value: RawByteString); inline;
  public
    function  IsDefaultNamespace(const namespaceURI: RawByteString): Boolean; inline;
    property  LocalName: RawByteString read GetLocalName write SetLocalName;
    property  NamespaceURI: RawByteString read GetNamespaceURI;
    property  NextSibling: xmlAttrPtr read GetNextSibling;
    property  NodeName: RawByteString read GetName;
    property  Value: RawByteString read GetValue write SetValue;
    property  OwnerDocument: xmlDocPtr read GetOwnerDocument;
    property  Prefix: RawByteString read GetPrefix;
    property  PreviousSibling: xmlAttrPtr read GetPreviousSibling;
    property  BaseURI: RawByteString read GetBaseURI write SetBaseURI;
  end;

  xmlDocHelper = record helper for xmlDoc
  private type
    TSelf = type xmlDoc;
  private
    function  GetDocumentElement: xmlNodePtr; inline;
    function  GetUrl: RawByteString; inline;
    function  GetXml: RawByteString;
    procedure SetDocumentElement(const Value: xmlNodePtr);
  public
    class function Create(const Version: RawByteString = '1.0'): xmlDocPtr; overload; static; inline;
    class function Create(const XML: RawByteString; const Options: TXmlParserOptions; ErrorHandler: xmlDocErrorHandler = nil): xmlDocPtr; overload; static; inline;
    class function Create(const XML: string; const Options: TXmlParserOptions; ErrorHandler: xmlDocErrorHandler = nil): xmlDocPtr; overload; static; inline;
    class function Create(const Data: TBytes; const Options: TXmlParserOptions; ErrorHandler: xmlDocErrorHandler = nil): xmlDocPtr; overload; static; inline;
    class function Create(const Data: Pointer; Size: NativeUInt; const Options: TXmlParserOptions; ErrorHandler: xmlDocErrorHandler = nil): xmlDocPtr; overload; static;
    class function CreateFromFile(const FileName: string; const Options: TXmlParserOptions; ErrorHandler: xmlDocErrorHandler = nil): xmlDocPtr; overload; static; inline;
    class function Create(Stream: TStream; const Options: TXmlParserOptions; const Encoding: Utf8String; ErrorHandler: xmlDocErrorHandler = nil): xmlDocPtr; overload; static;
    function  CreateRoot(const RootName: RawByteString; const NamespaceURI: RawByteString = ''; const Content: RawByteString = ''): xmlNodePtr;
    function  CreateChild(const Parent: xmlNodePtr; const Name: RawByteString; const NamespaceURI: RawByteString = ''; ResolveNamespace: Boolean = False; Content: RawByteString = ''): xmlNodePtr;
    procedure Free; inline;
    function  CanonicalizeTo(const FileName: string; Mode: TXmlC14NMode = TXmlC14NMode.xmlC14N; Comments: Boolean = False): Boolean; overload;
    function  CanonicalizeTo(const Stream: TStream; Mode: TXmlC14NMode = TXmlC14NMode.xmlC14N; Comments: Boolean = False): Boolean; overload;
    function  Canonicalize(Mode: TXmlC14NMode = TXmlC14NMode.xmlC14N; Comments: Boolean = False): RawByteString; overload;
    function  Clone(Recursive: Boolean = True): xmlDocPtr; inline;
    function  CreateAttribute(const Name: RawByteString; const Value: RawByteString = ''): xmlAttrPtr; inline;
    function  CreateCDATASection(const Data: RawByteString): xmlNodePtr; inline;
    function  CreateComment(const Data: RawByteString): xmlNodePtr; inline;
    function  CreateDocumentFragment: xmlNodePtr; inline;
    function  CreateElement(const Name: RawByteString): xmlNodePtr; inline;
    function  CreateElementNs(const NamespaceURI, Name: RawByteString): xmlNodePtr; inline;
    function  CreateEntityReference(const Name: RawByteString): xmlNodePtr; inline;
    function  CreateProcessingInstruction(const Target: RawByteString; const Data: RawByteString): xmlNodePtr; inline;
    function  CreateTextNode(const Data: RawByteString): xmlNodePtr; inline;
    function  DocType: xmlNodePtr; inline;
    function  GetElementsByTagName(const name: RawByteString): xmlNodeArray; inline;
    procedure ReconciliateNs; inline;
    function  Save(const FileName: string; const Encoding: string = 'UTF-8'; const Options: TxmlSaveOptions = []): Boolean; overload;
    function  Save(Stream: TStream; const Encoding: string = 'UTF-8'; const Options: TxmlSaveOptions = []): Boolean; overload;
    function  ToAnsi(const Encoding: string = 'windows-1251'; const Format: Boolean = False): RawByteString; overload;
    function  ToBytes(const Encoding: string = 'UTF-8'; const Format: Boolean = False): TBytes; overload;
    function  ToString(const Encoding: string = 'UTF-8'; const Format: Boolean = False): string; overload;
    function  ToUtf8(const Format: Boolean = False): RawByteString; overload;
    function  Transform(const stylesheet: xmlDocPtr; out doc: xmlDocPtr; errorHandler: xsltErrorHandler = nil): Boolean; overload;
    function  Transform(const stylesheet: xmlDocPtr; out S: string; errorHandler: xsltErrorHandler = nil): Boolean; overload;
    function  Transform(const stylesheet: xmlDocPtr; out S: RawByteString; errorHandler: xsltErrorHandler = nil): Boolean; overload;
    function  Transform(const stylesheet: xmlDocPtr; Stream: TStream; errorHandler: xsltErrorHandler = nil): Boolean; overload;
    function  Validate(ErrorHandler: xmlDocErrorHandler = nil; ResourceLoader: xmlResourceLoader = nil): Boolean;
    function  ValidateNode(Node: xmlNodePtr; ErrorHandler: xmlDocErrorHandler = nil): Boolean;
    property  documentElement: xmlNodePtr read GetDocumentElement write SetDocumentElement;
    property  URL: RawByteString read GetURL;
    property  Xml: RawByteString read GetXml;
  end;

  PXmlErrorCallback = ^TXmlErrorCallback;
  TXmlErrorCallback = record
    Handler: xmlDocErrorHandler;
  end;

  PXsltErrorCallback = ^TXsltErrorCallback;
  TXsltErrorCallback = record
    Handler: xsltErrorHandler;
  end;

  PXmlResourceCallback = ^TXmlResourceCallback;
  TXmlResourceCallback = record
    Handler: xmlResourceLoader;
  end;

procedure xmlDocErrorCallback(userData: Pointer; const error: xmlErrorPtr); cdecl;
function  xmlResourceLoaderCallback(ctxt: Pointer; const url, publicId: xmlCharPtr; &type: xmlResourceType; flags: Integer; var output: xmlParserInputPtr): Integer; cdecl;

implementation

uses
  libxslt.API;

function IOReadStream(context: Pointer; buffer: PUTF8Char; len: Integer): Integer; cdecl;
begin
  Result := TStream(context).Read(buffer^, len);
end;

function IOWriteStream(context: Pointer; Buffer: PAnsiChar; Len: Integer): Integer; cdecl;
begin
  Result := TStream(context).Write(Buffer^, Len);
end;

procedure IOCloseStream(context: Pointer); cdecl;
begin
end;

function xmlResourceLoaderCallback(ctxt: Pointer; const url, publicId: xmlCharPtr; &type: xmlResourceType; flags: Integer; var output: xmlParserInputPtr): Integer; cdecl;
begin
  try
    Result := PXmlResourceCallback(ctxt).Handler(url, publicId, &type, flags, output);
  except
    Result := Ord(XML_ERR_INTERNAL_ERROR);
  end;
end;

procedure xsltErrorCallback(ctx: Pointer; const msg: xmlCharPtr); cdecl varargs;
begin
  if ctx <> nil then
  begin
    PXsltErrorCallback(ctx).Handler(msg);
  end;
end;

function ParseStylesheet(const stylesheet: xmlDocPtr): xsltStylesheetPtr;
begin
  XSLTLib.Initialize;

  // Workaround xsltFreeStylesheet frees stylesheet document
  var clone := xmlCopyDoc(stylesheet, 1);
  if clone = nil then
    Exit(nil);

  Result := xsltParseStylesheetDoc(clone);

  if Result = nil then
    xmlFreeDoc(clone);
end;

function XsltTransform(const stylesheet: xmlDocPtr; doc: xmlDocPtr; node: xmlNodePtr; var style: xsltStylesheetPtr; var output: xmlDocPtr; errorHandler: xsltErrorHandler): Boolean;
var
  params: PAnsiChar;
  ecb: TXsltErrorCallback;
begin
  Result := False;

  style := ParseStylesheet(stylesheet);
  if style = nil then
    Exit;

  var ctxt := xsltNewTransformContext(style, doc);
  if ctxt <> nil then
  begin
    ctxt.initialContextDoc := doc;
    ctxt.initialContextNode := node;
    if Assigned(errorHandler) then
    begin
      ecb.Handler := errorHandler;
      xsltSetTransformErrorFunc(ctxt, @ecb, xsltErrorCallback);
    end;
    output := xsltApplyStylesheetUser(style, doc, params, nil, nil, ctxt);
    Result := output <> nil;
  end;
  xsltFreeTransformContext(ctxt);

  if not Result then
    xsltFreeStylesheet(style);
end;

{ xmlNamespacesHelper }

procedure xmlNamespacesHelper.Add(const Prefix, URI: RawByteString);
begin
  var L := Length(Self);
  SetLength(Self, L + 1);
  Self[L].Prefix := Prefix;
  Self[L].URI := URI;
end;

function xmlNamespacesHelper.Count: NativeInt;
begin
  Result := Length(Self);
end;

{ xmlNodeHelper }

function xmlNodeHelper.AddChild(const Name, Content: RawByteString): xmlNodePtr;
var
  Prefix, LocalName: RawByteString;
  Ns: xmlNsPtr;
begin
  if SplitXMLName(Name, Prefix, LocalName) then
    Ns := xmlSearchNs(Doc, @Self, xmlCharPtr(Prefix))
  else
    Ns := nil;
  Result := xmlNewDocRawNode(doc, Ns, xmlCharPtr(LocalName), xmlCharPtr(Content));
  if Result <> nil then
    AppendChild(Result);
end;

function xmlNodeHelper.AddChildNs(const Name, NamespaceURI, Content: RawByteString): xmlNodePtr;
begin
  var Ns := xmlSearchNsByHRef(doc, @Self, xmlCharPtr(NamespaceURI));
  Result := xmlNewDocRawNode(doc, Ns, xmlCharPtr(Name), xmlCharPtr(Content));
  if Result <> nil then
    AppendChild(Result);
end;

function xmlNodeHelper.AppendChild(const NewChild: xmlNodePtr): xmlNodePtr;
begin
  Result := xmlAddChild(@Self, newChild);
  if Result <> nil then
    xmlReconciliateNs(doc, Result);
end;

function xmlNodeHelper.ChildElementCount: NativeInt;
begin
  Result := xmlChildElementCount(@Self);
end;

function xmlNodeHelper.CloneNode(Deep: Boolean): xmlNodePtr;
begin
  if xmlDOMWrapCloneNode(nil, nil, @Self, Result, nil, nil, Ord(deep), 0) <> 0 then
    Result := nil;
end;

function xmlNodeHelper.Contains(const Node: xmlNodePtr): Boolean;
begin
  var Run := Node;
  while Run <> nil do
  begin
    if Run = @Self then
      Exit(True);
    Run := Run.parent;
  end;
  Result := False;
end;

function xmlNodeHelper.GetAttributeNode(const Name: RawByteString): xmlAttrPtr;
var
  prefix, localName: RawByteString;
begin
  SplitXMLName(Name, Prefix, LocalName);

  var prop := properties;
  while prop <> nil do
  begin
    if xmlStrSame(xmlNodeHeaderPtr(prop).name, xmlStrPtr(LocalName)) then
    begin
      if (Prefix = '') and (prop.ns = nil) then
        Exit(prop)
      else if (prop.ns <> nil) and xmlStrSame(xmlStrPtr(prefix), prop.ns.prefix) then
        Exit(prop);
    end;
    prop := prop.next;
  end;
  Result := nil;
end;

function xmlNodeHelper.GetAttributeNodeNs(const NamespaceURI, Name: RawByteString): xmlAttrPtr;
begin
  var prop := properties;
  while prop <> nil do
  begin
    if xmlStrSame(xmlNodeHeaderPtr(prop).name, xmlStrPtr(Name)) then
    begin
      if (NamespaceURI = '') and (prop.ns = nil) then
        Exit(prop)
      else if (prop.ns <> nil) and xmlStrSame(prop.ns.href, xmlStrPtr(NamespaceURI)) then
        Exit(prop);
    end;
    prop := prop.next;
  end;
  Result := nil;
end;

function xmlNodeHelper.SearchNs(const Prefix: RawByteString): xmlNsPtr;
begin
  Result := xmlSearchNs(doc, @Self, xmlStrPtr(Prefix));
end;

function xmlNodeHelper.SearchNs(const prefix: xmlCharPtr): xmlNsPtr;
begin
  Result := xmlSearchNs(doc, @Self, prefix);
end;

function xmlNodeHelper.SearchNsByRef(const href: RawByteString): xmlNsPtr;
begin
  Result := xmlSearchNsByHref(doc, @Self, xmlStrPtr(href));
end;

function xmlNodeHelper.SearchNsByRef(const href: xmlCharPtr): xmlNsPtr;
begin
  Result := xmlSearchNsByHref(doc, @Self, href);
end;

function xmlNodeHelper.FirstElementChild: xmlNodePtr;
begin
  Result := xmlFirstElementChild(@Self);
end;

function xmlNodeHelper.GetAttribute(const Name: RawByteString): RawByteString;
var
  Prefix, LocalName: RawByteString;
begin
  //TODO: Test
  if Name = 'xmlns' then
  begin
    var Ns := nsDef;
    while Ns <> nil do
    begin
      if Ns.prefix = nil then
      begin
        Result := xmlCharToRaw(ns.href);
        Exit;
      end;
      Ns := Ns.next;
    end;
    Result := '';
  end
  else if SplitXMLName(Name, Prefix, LocalName) then
  begin
    if Prefix = 'xmlns' then
    begin
      var Ns := nsDef;
      while Ns <> nil do
      begin
        if xmlStrSame(Ns.prefix, Pointer(LocalName)) then
        begin
          Result := xmlCharToRaw(ns.href);
          Exit;
        end;
        Ns := Ns.next;
      end;
      Result := '';
    end
    else
    begin
      var Attr := properties;
      while Attr <> nil do
      begin
        if (Attr.ns <> nil) and xmlStrSame(Attr.ns.prefix, Pointer(Prefix)) then
          Exit(xmlCharToRaw(Attr.ns.href));
        Attr := Attr.next;
      end;
      Result := '';
    end;
  end
  else
    Result := xmlCharToRawAndFree(xmlGetProp(@Self, xmlStrPtr(name)));
end;

function xmlNodeHelper.GetAttributeNs(const NamespaceURI, Name: RawByteString): RawByteString;
begin
  Result := xmlCharToRawAndFree(xmlGetNsProp(@Self, xmlStrPtr(Name), xmlStrPtr(NamespaceURI)));
end;

function xmlNodeHelper.SetAttributeNs(const NamespaceURI, name, value: RawByteString): xmlAttrPtr;
begin
  var ns := xmlSearchNsByHref(doc, @Self, xmlStrPtr(namespaceURI));
  Result := xmlSetNsProp(@Self, ns, xmlStrPtr(name), xmlStrPtr(value));
end;

function xmlNodeHelper.GetAttributes: xmlAttrArray;
begin
  var Count := 0;
  var Attr := properties;
  while Attr <> nil do
  begin
    Inc(Count);
    Attr := Attr.next;
  end;

  SetLength(Result, Count);

  var I := 0;
  Attr := properties;
  while Attr <> nil do
  begin
    Result[I] := Attr;
    Inc(I);
  end;
end;

function xmlNodeHelper.GetBaseURI: RawByteString;
begin
  var S := xmlNodeGetBase(doc, @Self);
  Result := xmlCharToRawAndFree(S);
end;

function xmlNodeHelper.GetChildNodes: xmlNodeArray;
begin
  var count := 0;
  var node := children;
  while node <> nil do
  begin
    Inc(count);
    node := node.next;
  end;

  SetLength(Result, count);

  var I := 0;
  node := children;
  while node <> nil do
  begin
    Result[I] := node;
    Inc(I);
    node := node.next;
  end;
end;

function xmlNodeHelper.GetValue: RawByteString;
begin
  Result := '';
  if content = nil then
    Exit;
  Result := xmlCharToRaw(content);
end;

function xmlNodeHelper.GetNext(Root: xmlNodePtr): xmlNodePtr;
begin
  if children <> nil then
    Exit(children)
  else if next <> nil then
    Exit(next)
  else
  begin
    Result := parent;
    while True do
    begin
      if result = root then
        Exit(nil)
      else if Result.next <> nil then
        Exit(Result.next)
      else
        Result := Result.parent;
    end;
  end;
end;

function xmlNodeHelper.GetElementsByTagName(const name: RawByteString): xmlNodeArray;
begin
  if name = '' then
    Exit(nil);

  var all := name = '*';

  var Capacity := 16;
  SetLength(Result, capacity);

  var count := 0;
  var node := GetNext(@Self);
  while node <> nil do
  begin
    if node.&type = XML_ELEMENT_NODE then
    begin
      if all or xmlStrSame(node.name, xmlStrPtr(name)) then
      begin
        if count = capacity then
        begin
          Inc(capacity, 16);
          SetLength(Result, capacity);
        end;
        Result[count] := node;
        Inc(count);
      end;
    end;
    node := GetNext(node);
  end;
  SetLength(Result, count);
end;

function xmlNodeHelper.GetFirstChild: xmlNodePtr;
begin
  Result := children;
end;

function xmlNodeHelper.GetLastChild: xmlNodePtr;
begin
  Result := last;
end;

function xmlNodeHelper.GetLocalName: RawByteString;
begin
  if &type in [XML_ELEMENT_NODE, XML_ATTRIBUTE_NODE] then
    Result := xmlCharToRaw(name)
  else
    Result := '';
end;

function xmlNodeHelper.GetNamespaceURI: RawByteString;
begin
  if ns = nil then
    Result := ''
  else
    Result := xmlCharToRaw(ns.href);
end;

function xmlNodeHelper.GetNextSibling: xmlNodePtr;
begin
  Result := next;
end;

function xmlNodeHelper.GetNodeName: RawByteString;
begin
  case &type of
    XML_ELEMENT_NODE       : Result := GetTagName;
    XML_ATTRIBUTE_NODE     : Result := xmlAttrPtr(@Self).GetName;
    XML_TEXT_NODE          : Result := '#text';
    XML_CDATA_SECTION_NODE : Result := '#cdata-section';
    XML_COMMENT_NODE       : Result := '#comment';
    XML_DOCUMENT_NODE      : Result := '#document';
    XML_DOCUMENT_FRAG_NODE : Result := '#document-fragment';
  else
    Result := xmlCharToRaw(name);
  end;
end;

function xmlNodeHelper.GetNodeType: xmlElementType;
begin
  Result := &type;
end;

function xmlNodeHelper.GetNodeValue: RawByteString;
begin
  case &type of
    XML_ATTRIBUTE_NODE,
    XML_TEXT_NODE,
    XML_CDATA_SECTION_NODE,
    XML_COMMENT_NODE:   Result := xmlCharToRawAndFree(xmlNodeGetContent(@Self));
    XML_ATTRIBUTE_DECL: Result := xmlCharToRaw(xmlAttributePtr(@Self).defaultValue);
    XML_PI_NODE:        Result := xmlCharToRawAndFree(xmlNodeGetContent(@Self));
  else
    Result := '';
  end;
end;

function xmlNodeHelper.GetOwnerDocument: xmlDocPtr;
begin
  Result := doc;
end;

function xmlNodeHelper.GetParentElement: xmlNodePtr;
begin
  Result := TSelf(Self).parent;
  while Result <> nil do
  begin
    if Result.&type = XML_ELEMENT_NODE then
      Exit;

    Result := Result.parent;
  end;
  Result := nil;
end;

function xmlNodeHelper.GetParentNode: xmlNodePtr;
begin
  Result := TSelf(Self).parent;
end;

function xmlNodeHelper.GetPath: RawByteString;
begin
  Result := xmlCharToRawAndFree(xmlGetNodePath(@Self));
end;

function xmlNodeHelper.GetPrefix: RawByteString;
begin
  Result := xmlCharToRaw(ns.prefix);
end;

function xmlNodeHelper.GetPreviousSibling: xmlNodePtr;
begin
  Result := prev;
end;

function xmlNodeHelper.GetTagName: RawByteString;
begin
  if ns = nil then
    Result := xmlCharToRaw(name)
  else
    Result := xmlQName(ns.prefix, name);
end;

function xmlNodeHelper.GetRootNode: xmlNodePtr;
begin
  Result := xmlDocGetRootElement(doc);
end;

function xmlNodeHelper.GetText: RawByteString;
begin
  Result := xmlCharToRawAndFree(xmlNodeGetContent(@Self));
end;

function xmlNodeHelper.GetXml: RawByteString;
begin
  var Buf := xmlAllocOutputBuffer(nil);
  xmlNodeDumpOutput(Buf, doc, @Self, 0, 0, nil);
  Result := xmlCharToRaw(xmlOutputBufferGetContent(Buf), xmlOutputBufferGetSize(Buf));
  xmlOutputBufferClose(Buf);
end;

function xmlNodeHelper.HasAttribute(const Name: RawByteString): Boolean;
begin
  Result := xmlHasProp(@Self, xmlStrPtr(Name)) <> nil;
end;

function xmlNodeHelper.HasAttributeNs(const NamespaceURI, Name: RawByteString): Boolean;
begin
  Result := xmlHasNsProp(@Self, xmlCharPtr(Name), xmlCharPtr(NamespaceURI)) <> nil;
end;

function xmlNodeHelper.HasAttributes: Boolean;
begin
  Result := (&type = XML_ELEMENT_NODE) and ((properties <> nil) or (nsDef <> nil));
end;

function xmlNodeHelper.HasChildNodes: Boolean;
begin
  Result := children <> nil;
end;

function xmlNodeHelper.InsertBefore(const NewChild, RefChild: xmlNodePtr): xmlNodePtr;
begin
  if RefChild = nil then
    Result := xmlAddChild(@Self, NewChild)
  else
    Result := xmlAddPrevSibling(RefChild, children);
  if Result <> nil then
    xmlReconciliateNs(doc, Result);
end;

function xmlNodeHelper.IsBlank: Boolean;
begin
  Result := xmlIsBlankNode(@Self) = 1;
end;

function xmlNodeHelper.IsDefaultNamespace(const namespaceURI: RawByteString): Boolean;
begin
  if nsDef = nil then
    Result := namespaceURI = ''
  else
    Result := xmlStrSame(nsDef.href, Pointer(namespaceURI));
end;

function xmlNodeHelper.IsText: Boolean;
begin
  Result := xmlNodeIsText(@Self) = 1;
end;

function xmlNodeHelper.LastElementChild: xmlNodePtr;
begin
  Result := xmlLastElementChild(@Self);
end;

function xmlNodeHelper.NextElementSibling: xmlNodePtr;
begin
  Result := xmlNextElementSibling(@Self);
end;

function xmlNodeHelper.PreviousElementSibling: xmlNodePtr;
begin
  Result := xmlPreviousElementSibling(@Self);
end;

procedure xmlNodeHelper.ReconciliateNs;
begin
  xmlReconciliateNs(doc, @Self);
end;

procedure xmlNodeHelper.RemoveAttribute(const name: RawByteString);
begin
  var prop := xmlHasProp(@Self, xmlStrPtr(name));
  if prop <> nil then
    xmlRemoveProp(prop);
end;

procedure xmlNodeHelper.RemoveAttributeNode(const Attr: xmlAttrPtr);
begin
  xmlRemoveProp(Attr);
  xmlReconciliateNs(doc, @Self);
end;

function xmlNodeHelper.RemoveChild(const ChildNode: xmlNodePtr): xmlNodePtr;
begin
  xmlUnlinkNode(ChildNode);
  Result := ChildNode;
  xmlReconciliateNs(doc, @Self);
end;

function xmlNodeHelper.ReplaceChild(const NewChild, OldChild: xmlNodePtr): xmlNodePtr;
begin
  Result := xmlReplaceNode(OldChild, NewChild);
  xmlReconciliateNs(doc, @Self);
end;

function xmlNodeHelper.XPathEval(const queryString: RawByteString; const namespaces: xmlNamespaces; ErrorHandler: xmlDocErrorHandler): xmlXPathObjectPtr;
var
  ecb: TXmlErrorCallback;
begin
  var ctx := xmlXPathNewContext(doc);
  try
    xmlXPathSetContextNode(@Self, ctx);

    if Assigned(ErrorHandler) then
    begin
      ecb.Handler := ErrorHandler;
      xmlXPathSetErrorHandler(ctx, xmlDocErrorCallback, @ecb);
    end;

    if Length(namespaces) > 0 then
    begin
      for var I := Low(namespaces) to High(namespaces) do
      begin
        xmlXPathRegisterNs(ctx, XmlStrPtr(namespaces[I].Prefix), XmlStrPtr(namespaces[I].URI));
      end;
    end
    else
    begin
      var ns := Self.ns;
      while ns <> nil do
      begin
        xmlXPathRegisterNs(ctx, ns.prefix, ns.href);
        ns := ns.next;
      end;
    end;

    Result := xmlXPathEvalExpression(xmlStrPtr(queryString), ctx);
  finally
    xmlXPathFreeContext(ctx);
  end;
end;

function xmlNodeHelper.SelectNodes(const QueryString: RawByteString; const Namespaces: xmlNamespaces): xmlNodeArray;
begin
  var xpathObj := XPathEval(queryString, Namespaces, nil);
  if xpathObj = nil then
    Exit(nil);

  if (xpathObj.nodesetval = nil) or (xpathObj.nodesetval.nodeNr = 0) then
  begin
    var nodes := xpathObj.nodesetval;
    SetLength(Result, nodes.nodeNr);
    for var I := 0 to nodes.nodeNr - 1 do
      Result[I] := nodes.nodeTab[I];
  end
  else
    Result := nil;

  xmlXPathFreeObject(xpathObj);
end;

function xmlNodeHelper.SelectSingleNode(const queryString: RawByteString): xmlNodePtr;
begin
  var ctx := xmlXPathNewContext(doc);
  try
    xmlXPathSetContextNode(@Self, ctx);

    var xpathObj := xmlXPathEvalExpression(xmlStrPtr(queryString), ctx);
    if (xpathObj = nil) or (xpathObj.nodesetval = nil) or (xpathObj.nodesetval.nodeNr = 0) then
      Exit(nil);

    Result := xpathObj.nodesetval.nodeTab[0];
    xmlXPathFreeObject(xpathObj);
  finally
    xmlXPathFreeContext(ctx);
  end;
end;

procedure xmlNodeHelper.SetAttribute(const Name, Value: RawByteString);
var
  Prefix, LocalName: RawByteString;
begin
  if Name = 'xmlns' then
    xmlSetNs(@Self, xmlNewNs(@Self, xmlCharPtr(Value), nil))
  else
  begin
    if SplitXMLName(Name, Prefix, LocalName) then
    begin
      if Prefix = 'xmlns' then
        xmlNewNs(@Self, xmlCharPtr(Value), xmlCharPtr(LocalName))
      else
      begin
        var Ns := xmlSearchNs(doc, @Self, xmlCharPtr(Prefix));
        xmlSetNsProp(@Self, Ns, xmlStrPtr(LocalName), xmlStrPtr(Value));
      end;
    end
    else
      xmlSetProp(@Self, xmlStrPtr(Name), xmlStrPtr(Value));
  end;
end;

procedure xmlNodeHelper.SetBaseURI(const Value: RawByteString);
begin
  xmlNodeSetBase(@Self, xmlStrPtr(Value));
end;

procedure xmlNodeHelper.SetNodeName(const Value: RawByteString);
begin
  xmlNodeSetName(@Self, xmlStrPtr(Value));
end;

procedure xmlNodeHelper.SetNodeValue(const Value: RawByteString);
begin
  case &type of
    XML_ELEMENT_NODE,
    XML_ATTRIBUTE_NODE,
    XML_TEXT_NODE,
    XML_CDATA_SECTION_NODE,
    XML_COMMENT_NODE:
      SetText(Value);
  end;
end;

procedure xmlNodeHelper.SetText(const Value: RawByteString);
begin
  var Escaped := xmlEncodeSpecialChars(doc, Pointer(Value));
  xmlNodeSetContent(@Self, Escaped);
  XmlFree(Escaped);
end;

function xmlNodeHelper.Transform(const stylesheet: xmlDocPtr; out doc: xmlDocPtr; errorHandler: xsltErrorHandler): Boolean;
var
  style: xsltStylesheetPtr;
begin
  Result := XsltTransform(stylesheet, Self.doc, @Self, style, doc, errorHandler);
  xsltFreeStylesheet(style);
end;

function xmlNodeHelper.Transform(const stylesheet: xmlDocPtr; out S: RawByteString; errorHandler: xsltErrorHandler): Boolean;
var
  style: xsltStylesheetPtr;
  output: xmlDocPtr;
  text: xmlCharPtr;
  len: Integer;
begin
  Result := XsltTransform(stylesheet, Self.doc, @Self, style, output, errorHandler);
  if Result then
  begin
    if xsltSaveResultToString(text, len, output, style) = 0 then
    begin
      SetString(S, text, len);
      Result := True;
      xmlFree(text);
    end;
    xmlFreeDoc(output);
  end;
  xsltFreeStylesheet(style);
end;

function xmlNodeHelper.Transform(const stylesheet: xmlDocPtr; out S: string; errorHandler: xsltErrorHandler): Boolean;
var
  Text: RawByteString;
begin
  Result := Transform(stylesheet, Text, errorHandler);
  if Result then
    S := UTF8ToUnicodeString(Text);
end;

function xmlNodeHelper.Transform(const stylesheet: xmlDocPtr; Stream: TStream; errorHandler: xsltErrorHandler): Boolean;
var
  style: xsltStylesheetPtr;
  output: xmlDocPtr;
  buf: xmlOutputBufferPtr;
begin
  Result := XsltTransform(stylesheet, Self.doc, @Self, style, output, errorHandler);
  if Result then
  begin
    var Buffer := xmlOutputBufferCreateIO(@IOWriteStream, @IOCloseStream, Pointer(Stream), nil);
    if Buffer <> nil then
      xsltSaveResultTo(buf, output, style)
    else
      Result := False;
    xmlFreeDoc(output);
  end;
  xsltFreeStylesheet(style);
end;

{ xmlAttrHelper }

function xmlAttrHelper.GetBaseURI: RawByteString;
begin
  Result := xmlCharToRawAndFree(xmlNodeGetBase(doc, @Self));
end;

function xmlAttrHelper.GetLocalName: RawByteString;
begin
  Result := xmlCharToRaw(TSelf(Self).name);
end;

function xmlAttrHelper.GetName: RawByteString;
begin
  Result := xmlQName(ns.prefix, TSelf(Self).name)
end;

function xmlAttrHelper.GetNamespaceURI: RawByteString;
begin
  if ns = nil then
    Result := ''
  else
    Result := xmlCharToRaw(ns.href);
end;

function xmlAttrHelper.GetNextSibling: xmlAttrPtr;
begin
  Result := next;
end;

function xmlAttrHelper.GetOwnerDocument: xmlDocPtr;
begin
  Result := doc;
end;

function xmlAttrHelper.GetPrefix: RawByteString;
begin
  if ns = nil then
    Result := ''
  else
    Result := xmlCharToRaw(ns.prefix);
end;

function xmlAttrHelper.GetPreviousSibling: xmlAttrPtr;
begin
  Result := prev;
end;

function xmlAttrHelper.GetValue: RawByteString;
begin
  var child := children;
  if child = nil then
    Exit('');

  if ((child.&type = XML_TEXT_NODE) or (child.&type = XML_CDATA_SECTION_NODE)) and (child.next = nil) then
    if child.content = nil then
      Exit('')
    else
      Exit(xmlCharToRaw(child.content));
end;

function xmlAttrHelper.IsDefaultNamespace(const namespaceURI: RawByteString): Boolean;
begin
  if ns = nil then
    Result := namespaceURI = ''
  else
    Result := xmlStrSame(ns.href, xmlStrPtr(namespaceURI));
end;

procedure xmlAttrHelper.SetBaseURI(const Value: RawByteString);
begin
  xmlNodeSetBase(@Self, xmlStrPtr(Value));
end;

procedure xmlAttrHelper.SetLocalName(const Value: RawByteString);
begin
  xmlNodeSetName(@Self, xmlStrPtr(Value));
end;

procedure xmlAttrHelper.SetValue(const Value: RawByteString);
begin
  if atype = XML_ATTRIBUTE_ID then
  begin
    xmlRemoveID(doc, @self);
    atype := XML_ATTRIBUTE_ID;
  end;

  if children <> nil then
    xmlFreeNodeList(children);
  children := nil;
  last := nil;
  ns := parent.ns;
  if Value <> '' then
  begin
    var newChild := xmlNewDocText(doc, xmlStrPtr(Value));
    children := newChild;
    var tmp := children;
    while tmp <> nil do
    begin
      tmp.parent := @Self;
      if tmp.next = nil then
        last := tmp;
      tmp := tmp.next;
    end;
  end;
  if atype = XML_ATTRIBUTE_ID then
    xmlAddIDSafe(@Self, xmlStrPtr(Value));
end;

{ xmlDocHelper }

procedure xmlDocErrorCallback(userData: Pointer; const error: xmlErrorPtr); cdecl;
begin
  if userData <> nil then
    if Assigned(PXmlErrorCallback(userData).Handler) then
      PXmlErrorCallback(userData).Handler(error^);
end;

class function xmlDocHelper.Create(const Version: RawByteString): xmlDocPtr;
begin
  Result := xmlNewDoc(xmlCharPtr(Version));
end;

class function xmlDocHelper.Create(const XML: RawByteString; const Options: TXmlParserOptions; ErrorHandler: xmlDocErrorHandler): xmlDocPtr;
begin
  Result := Create(Pointer(XML), Length(XML), Options, ErrorHandler);
end;

class function xmlDocHelper.Create(const XML: string; const Options: TXmlParserOptions; ErrorHandler: xmlDocErrorHandler): xmlDocPtr;
begin
  Result := Create(UTF8Encode(XML), Options, ErrorHandler);
end;

class function xmlDocHelper.Create(const Data: TBytes; const Options: TXmlParserOptions; ErrorHandler: xmlDocErrorHandler): xmlDocPtr;
begin
  Result := Create(Pointer(Data), Length(Data), Options, ErrorHandler);
end;

class function xmlDocHelper.Create(const Data: Pointer; Size: NativeUInt; const Options: TXmlParserOptions; ErrorHandler: xmlDocErrorHandler): xmlDocPtr;
var
  ecb: TXmlErrorCallback;
begin
  var ctx := xmlNewParserCtxt();
  if ctx = nil then
    Exit(nil);

  if Assigned(ErrorHandler) then
  begin
    ecb.Handler := ErrorHandler;
    xmlCtxtSetErrorHandler(ctx, xmlDocErrorCallback, @ecb);
  end;
  xmlCtxtUseOptions(ctx, XmlParserOptions(Options) or XML_PARSE_NOBLANKS);

  var input := xmlNewInputFromMemory(nil, Data, Size, XML_INPUT_BUF_STATIC);
  if input <> nil then
    Result := xmlCtxtParseDocument(ctx, input)
  else
    Result := nil;

  xmlFreeParserCtxt(ctx);
end;

class function xmlDocHelper.CreateFromFile(const FileName: string; const Options: TXmlParserOptions; ErrorHandler: xmlDocErrorHandler): xmlDocPtr;
var
  input: xmlParserInputPtr;
  ecb: TXmlErrorCallback;
begin
  var ctx := xmlNewParserCtxt();
  if ctx = nil then
    Exit(nil);

  if Assigned(ErrorHandler) then
  begin
    ecb.Handler := ErrorHandler;
    xmlCtxtSetErrorHandler(ctx, xmlDocErrorCallback, @ecb);
  end;

  xmlCtxtUseOptions(ctx, XmlParserOptions(Options) or XML_PARSE_UNZIP or XML_PARSE_NONET);

  if xmlNewInputFromUrl(xmlCharPtr(Utf8Encode(filename)), 0, input) = XML_ERR_OK then
    Result := xmlCtxtParseDocument(ctx, input)
  else
    Result := nil;

  xmlFreeParserCtxt(ctx);
end;

class function xmlDocHelper.Create(Stream: TStream; const Options: TXmlParserOptions; const Encoding: Utf8String; ErrorHandler: xmlDocErrorHandler): xmlDocPtr;
var
  ecb: TXmlErrorCallback;
begin
  var ctx := xmlNewParserCtxt();
  if ctx = nil then
    Exit(nil);

  if Assigned(ErrorHandler) then
  begin
    ecb.Handler := ErrorHandler;
    xmlCtxtSetErrorHandler(ctx, xmlDocErrorCallback, @ecb);
  end;
  xmlCtxtUseOptions(ctx, XmlParserOptions(Options) or XML_PARSE_UNZIP);

  Result := xmlCtxtReadIO(ctx, IOReadStream, nil, Stream, nil, Pointer(Encoding), XmlParserOptions(Options));

  xmlFreeParserCtxt(ctx);
end;

function xmlDocHelper.CreateRoot(const RootName: RawByteString; const NamespaceURI: RawByteString; const Content: RawByteString): xmlNodePtr;
var
  ns: xmlNsPtr;
  Prefix, LocalName: RawByteString;
begin
  if SplitXMLName(RootName, Prefix, LocalName) then
    ns := xmlNewNs(nil, xmlCharPtr(NamespaceURI), xmlCharPtr(Prefix))
  else if NamespaceURI <> '' then
    ns := xmlNewNs(nil, xmlCharPtr(NamespaceURI), nil)
  else
    ns := nil;

  Result := xmlNewDocRawNode(@Self, ns, xmlCharPtr(RootName), xmlCharPtr(content));

  Doc.documentElement := Result;
end;

function xmlDocHelper.CreateChild(const Parent: xmlNodePtr; const Name: RawByteString; const NamespaceURI: RawByteString; ResolveNamespace: Boolean; Content: RawByteString): xmlNodePtr;
var
  ns: xmlNsPtr;
  Prefix, LocalName: RawByteString;
begin
  if Parent = nil then
    Exit(CreateRoot(Name, NamespaceURI, Content));

  if SplitXMLName(Name, Prefix, LocalName) then
  begin
    if NamespaceURI = '' then
      ns := xmlSearchNsByHref(Parent.doc, Parent, Pointer(Prefix))
    else
      ns := xmlNewNs(nil, xmlCharPtr(NamespaceURI), xmlCharPtr(Prefix))
  end
  else if NamespaceURI <> '' then
    ns := xmlNewNs(nil, xmlCharPtr(NamespaceURI), nil)
  else
    ns := nil;

  Result := xmlNewDocRawNode(Parent.doc, ns, xmlCharPtr(LocalName), xmlCharPtr(Content));
  Parent.AppendChild(Result);
end;

function xmlDocHelper.CanonicalizeTo(const Stream: TStream; Mode: TXmlC14NMode; Comments: Boolean): Boolean;
var
  Buffer: xmlOutputBufferPtr;
begin
  Buffer := xmlOutputBufferCreateIO(@IOWriteStream, @IOCloseStream, Pointer(Stream), nil);
  if Buffer = nil then
    Exit(False);

  try
    Result := xmlC14NDocSaveTo(Doc, nil, xmlC14NMode(Ord(Mode)), nil, Ord(Comments), Buffer) = 0;
  finally
   xmlOutputBufferClose(Buffer);
  end;
end;

function xmlDocHelper.CanonicalizeTo(const FileName: string; Mode: TXmlC14NMode; Comments: Boolean): Boolean;
begin
  Result := xmlC14NDocSave(Doc, nil, xmlC14NMode(Ord(Mode)), nil, Ord(Comments), xmlCharPtr(Utf8Encode(FileName)), 0) = 0;
end;

function xmlDocHelper.Canonicalize(Mode: TXmlC14NMode; Comments: Boolean): RawByteString;
var
  Data: Pointer;
begin
  var Size := xmlC14NDocDumpMemory(Doc, nil, xmlC14NMode(Mode), nil, Ord(Comments), xmlCharPtr(Data));
  if Size < 0 then
    LX2InternalError;

  SetString(Result, PAnsiChar(Data), Size);

  xmlFree(Data);
end;

function xmlDocHelper.Clone(Recursive: Boolean): xmlDocPtr;
begin
  Result := xmlCopyDoc(@Self, Ord(Recursive));
end;

function xmlDocHelper.CreateAttribute(const Name, Value: RawByteString): xmlAttrPtr;
begin
  Result := xmlNewDocProp(@Self, xmlCharPtr(Name), xmlCharPtr(Value));
end;

function xmlDocHelper.CreateCDATASection(const Data: RawByteString): xmlNodePtr;
begin
  Result := xmlNewCDataBlock(@Self, xmlCharPtr(Data), Length(Data));
end;

function xmlDocHelper.CreateComment(const Data: RawByteString): xmlNodePtr;
begin
  Result := xmlNewDocComment(@Self, xmlCharPtr(Data));
end;

function xmlDocHelper.CreateDocumentFragment: xmlNodePtr;
begin
  Result := xmlNewDocFragment(@Self);
end;

function xmlDocHelper.CreateElement(const Name: RawByteString): xmlNodePtr;
begin
  Result := xmlNewDocRawNode(@Self, nil, xmlCharPtr(Name), nil);
end;

function xmlDocHelper.CreateElementNs(const NamespaceURI, Name: RawByteString): xmlNodePtr;
begin
  Result := xmlNewDocRawNode(@Self, nil, xmlCharPtr(Name), nil);
  xmlSetNs(Result, xmlNewNs(Result, xmlCharPtr(NamespaceURI), nil));
end;

function xmlDocHelper.CreateEntityReference(const Name: RawByteString): xmlNodePtr;
begin
  Result := xmlNewReference(@Self, xmlCharPtr(Name));
end;

function xmlDocHelper.CreateProcessingInstruction(const Target, Data: RawByteString): xmlNodePtr;
begin
  Result := xmlNewDocPI(@Self, xmlCharPtr(Target), xmlCharPtr(Data));
end;

function xmlDocHelper.CreateTextNode(const Data: RawByteString): xmlNodePtr;
begin
  Result := xmlNewDocText(@Self,  xmlCharPtr(data));
end;

function xmlDocHelper.DocType: xmlNodePtr;
begin
  if (children <> nil) and (children.&type = XML_DTD_NODE) then
    Result := children
  else
    Result := nil;
end;

procedure xmlDocHelper.Free;
begin
  xmlFreeDoc(@Self);
end;

function xmlDocHelper.GetDocumentElement: xmlNodePtr;
begin
  Result := xmlDocGetRootElement(@Self)
end;

function xmlDocHelper.GetElementsByTagName(const name: RawByteString): xmlNodeArray;
begin
  if children = nil then
    Exit(nil);

  Result := children.getElementsByTagName(name);
end;

function xmlDocHelper.GetUrl: RawBytestring;
begin
  Result := xmlCharToRaw(TSelf(Self).URL);
end;

function xmlDocHelper.GetXml: RawByteString;
var
  Data: Pointer;
  Size: Integer;
begin
  xmlDocDumpMemoryEnc(doc, Data, Size, 'UTF-8');

  if (Data = nil) or (Size = 0) then
    Exit('');
  Result := xmlCharToRaw(xmlCharPtr(Data), Size);

  xmlFree(Data);
end;

procedure xmlDocHelper.ReconciliateNs;
begin
  if documentElement <> nil then
    xmlReconciliateNs(@Self, documentElement);
end;

function xmlDocHelper.Save(Stream: TStream; const Encoding: string; const Options: TxmlSaveOptions): Boolean;
begin
  var ctx := xmlSaveToIO(IOWriteStream, nil, Stream, xmlStrPtr(Utf8Encode(Encoding)), XmlSaveOptions(Options));
  xmlSaveDoc(ctx, @Self);
  Result := xmlSaveFinish(ctx) = XML_ERR_OK;
end;

procedure xmlDocHelper.SetDocumentElement(const Value: xmlNodePtr);
begin
  var Old := xmlDocSetRootElement(@Self, Value);
  if Old <> nil then
    xmlFreeNode(Old);
end;

function xmlDocHelper.ToAnsi(const Encoding: string; const Format: Boolean): RawByteString;
var
  Data: Pointer;
  Size: Integer;
begin
  xmlDocDumpFormatMemoryEnc(doc, Data, Size, xmlCharPtr(Utf8Encode(Encoding)), Ord(Format));

  if (Data = nil) or (Size = 0) then
  begin
    xmlFree(Data);
    Exit('');
  end;
  SetString(Result, PAnsiChar(Data), Size);

  xmlFree(Data);
end;

function xmlDocHelper.ToString(const Encoding: string; const Format: Boolean): string;
var
  Data: Pointer;
  Size: Integer;
begin
  if Encoding = '' then
    xmlDocDumpFormatMemoryEnc(doc, Data, Size, nil, Ord(Format))
  else
    xmlDocDumpFormatMemoryEnc(doc, Data, Size, xmlCharPtr(Utf8Encode(Encoding)), Ord(Format));

  if (Data = nil) or (Size = 0) then
    Exit('');
  Result := xmlCharToStr(PAnsiChar(Data), Size);

  XmlFree(Data);
end;

function xmlDocHelper.ToUtf8(const Format: Boolean): RawByteString;
var
  Data: Pointer;
  Size: Integer;
begin
  xmlDocDumpFormatMemoryEnc(doc, Data, Size, 'UTF-8', Ord(Format));

  if (Data = nil) or (Size = 0) then
    Exit('');
  SetString(Result, PAnsiChar(Data), Size);

  XmlFree(Data);
end;

function xmlDocHelper.Transform(const stylesheet: xmlDocPtr; out doc: xmlDocPtr; errorHandler: xsltErrorHandler): Boolean;
var
  style: xsltStylesheetPtr;
begin
  Result := XsltTransform(stylesheet, @Self, @Self, style, doc, errorHandler);
  if Result then
    xsltFreeStylesheet(style);
end;

function xmlDocHelper.Transform(const stylesheet: xmlDocPtr; out S: RawByteString; errorHandler: xsltErrorHandler): Boolean;
var
  style: xsltStylesheetPtr;
  output: xmlDocPtr;
  text: xmlCharPtr;
  len: Integer;
begin
  Result := XsltTransform(stylesheet, @Self, @Self, style, output, errorHandler);
  if Result then
  begin
    if xsltSaveResultToString(text, len, output, style) = 0 then
    begin
      SetString(S, text, len);
      Result := True;
      xmlFree(text);
    end;
    xmlFreeDoc(output);
  end;
  xsltFreeStylesheet(style);
end;

function xmlDocHelper.Transform(const stylesheet: xmlDocPtr; out S: string; errorHandler: xsltErrorHandler): Boolean;
var
  Text: RawByteString;
begin
  Result := Transform(stylesheet, Text, errorHandler);
  if Result then
    S := UTF8ToUnicodeString(Text);
end;

function xmlDocHelper.Transform(const stylesheet: xmlDocPtr; Stream: TStream; errorHandler: xsltErrorHandler): Boolean;
var
  style: xsltStylesheetPtr;
  output: xmlDocPtr;
  buf: xmlOutputBufferPtr;
begin
  Result := XsltTransform(stylesheet, @Self, @Self, style, output, errorHandler);
  if Result then
  begin
    var Buffer := xmlOutputBufferCreateIO(@IOWriteStream, @IOCloseStream, Pointer(Stream), nil);
    if Buffer <> nil then
      xsltSaveResultTo(buf, output, style)
    else
      Result := False;
    xmlFreeDoc(output);
  end;
  xsltFreeStylesheet(style);
end;

function xmlDocHelper.ToBytes(const Encoding: string; const Format: Boolean): TBytes;
var
  Data: Pointer;
  Size: Integer;
begin
  xmlDocDumpFormatMemoryEnc(doc, Data, Size, xmlCharPtr(Utf8Encode(Encoding)), Ord(Format));

  if (Data = nil) or (Size = 0) then
    Exit(nil);
  SetLength(Result, Size);
  Move(Data^, Pointer(Result)^, Size);

  XmlFree(Data);
end;

function xmlDocHelper.Save(const FileName: string; const Encoding: string; const Options: TxmlSaveOptions): Boolean;
begin
  var ctx := xmlSaveToFilename(xmlCharPtr(Utf8Encode(FileName)), xmlCharPtr(Utf8Encode(Encoding)), XmlSaveOptions(Options));
  xmlSaveDoc(ctx, @Self);
  Result := xmlSaveFinish(ctx) = XML_ERR_OK;
end;

function xmlDocHelper.Validate(ErrorHandler: xmlDocErrorHandler; ResourceLoader: xmlResourceLoader): Boolean;
var
  ecb: TXmlErrorCallback;
  rcb: TXmlResourceCallback;
begin
  var ctx := xmlNewParserCtxt;

  if Assigned(ErrorHandler) then
  begin
    ecb.Handler := ErrorHandler;
    xmlCtxtSetErrorHandler(ctx, xmlDocErrorCallback, @ecb);
  end;

  if Assigned(ResourceLoader) then
  begin
    rcb.Handler := ResourceLoader;
    xmlCtxtSetResourceLoader(ctx, xmlResourceLoaderCallback, @rcb);
  end;

  Result := xmlCtxtValidateDocument(ctx, @Self) = 1;
  xmlFreeParserCtxt(ctx);
end;

function xmlDocHelper.ValidateNode(Node: xmlNodePtr; ErrorHandler: xmlDocErrorHandler): Boolean;
var
  ecb: TXmlErrorCallback;
begin
  var ctx := xmlNewParserCtxt;
  if Assigned(ErrorHandler) then
  begin
    ecb.Handler := ErrorHandler;
    xmlCtxtSetErrorHandler(ctx, xmlDocErrorCallback, @ecb);
  end;
  var vctxt := xmlCtxtGetValidCtxt(ctx);
  Result := xmlValidateElement(vctxt, @Self, Node) = 1;
  xmlFreeParserCtxt(ctx);
end;

end.
