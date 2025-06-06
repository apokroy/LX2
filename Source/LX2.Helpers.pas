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

  xmlNamespace = record
    Prefix: string;
    URI: string;
  end;

  xmlNamespaces = TArray<xmlNamespace>;

  xmlNamespacesHelper = record helper for xmlNamespaces
    procedure Add(const Prefix, URI: string);
    function  Count: NativeInt; inline;
  end;

  xmlNodeHelper = record helper for xmlNode
  private type
    TSelf = type xmlNode;
  private
    function  GetNodeName: string; inline;
    function  GetNodeType: xmlElementType; inline;
    function  GetAttributes: xmlAttrArray;
    function  GetChildNodes: xmlNodeArray;
    function  GetFirstChild: xmlNodePtr; inline;
    function  GetLastChild: xmlNodePtr; inline;
    function  GetLocalName: string; inline;
    function  GetNamespaceURI: string;
    function  GetNextSibling: xmlNodePtr; inline;
    function  GetNodeValue: string;
    function  GetOwnerDocument: xmlDocPtr; inline;
    function  GetParentElement: xmlNodePtr;
    function  GetParentNode: xmlNodePtr; inline;
    function  GetPrefix: string;
    function  GetPreviousSibling: xmlNodePtr; inline;
    function  GetText: string;
    function  GetXml: string;
    procedure SetNodeValue(const Value: string);
    procedure SetText(const Value: string);
    function  GetPath: string;
    procedure SetNodeName(const Value: string);
    function  GetBaseURI: string; inline;
    procedure SetBaseURI(const Value: string); inline;
    function  GetValue: string;
  public
    function  GetNext(Node: xmlNodePtr): xmlNodePtr;
    function  ChildElementCount: LongWord;
    function  NextElementSibling: xmlNodePtr;
    function  FirstElementChild: xmlNodePtr;
    function  LastElementChild: xmlNodePtr;
    function  PreviousElementSibling: xmlNodePtr;
    function  HasAttribute(const Name: string): Boolean;
    function  GetNsAttribute(const name, namespaceURI: string): string; inline;
    function  SetNsAttribute(const name, namespaceURI: string; const value: string): xmlAttrPtr;
    function  IsBlank: Boolean;
    function  IsText: Boolean;
    function  SearchNs(const prefix: string): xmlNsPtr; overload;
    function  SearchNs(const prefix: xmlCharPtr): xmlNsPtr; overload;
    function  SearchNsByRef(const href: string): xmlNsPtr; overload;
    function  SearchNsByRef(const href: xmlCharPtr): xmlNsPtr; overload;
    function  FindAttribute(const name: string): xmlAttrPtr; overload;
    function  FindAttribute(const name, namespaceURI: string): xmlAttrPtr; overload;
    procedure ReconciliateNs;
    property  Path: string read GetPath;
    property  Value: string read GetValue;
  public
    function  AppendChild(const NewChild: xmlNodePtr): xmlNodePtr; inline;
    function  CloneNode(Deep: Boolean): xmlNodePtr; inline;
    function  GetRootNode: xmlNodePtr;
    function  HasChildNodes: Boolean;
    function  InsertBefore(const NewChild, RefChild: xmlNodePtr): xmlNodePtr;
    function  RemoveChild(const ChildNode: xmlNodePtr): xmlNodePtr;
    function  ReplaceChild(const NewChild, OldChild: xmlNodePtr): xmlNodePtr;
    function  SelectNodes(const queryString: string; const namespaces: xmlNamespaces = nil): xmlNodeArray;
    function  SelectSingleNode(const queryString: string): xmlNodePtr;
    function  GetElementsByTagName(const name: string): xmlNodeArray;
    function  GetAttribute(const name: string): string; inline;
    procedure SetAttribute(const name: string; const value: string); inline;
    procedure RemoveAttribute(const name: string); inline;
    procedure RemoveAttributeNode(const Attr: xmlAttrPtr);

    property  Attribute[const name: string]: string read GetAttribute write SetAttribute;
    property  Attributes: xmlAttrArray read GetAttributes;
    property  BaseName: string read GetLocalName;
    property  ChildNodes: xmlNodeArray read GetChildNodes;
    property  FirstChild: xmlNodePtr read GetFirstChild;
    property  LastChild: xmlNodePtr read GetLastChild;
    property  NamespaceURI: string read GetNamespaceURI;
    property  NextSibling: xmlNodePtr read GetNextSibling;
    property  NodeName: string read GetNodeName write SetNodeName;
    property  NodeType: XmlElementType read GetNodeType;
    property  NodeValue: string read GetNodeValue write SetNodeValue;
    property  OwnerDocument: xmlDocPtr read GetOwnerDocument;
    property  ParentNode: xmlNodePtr read GetParentNode;
    property  Prefix: string read GetPrefix;
    property  PreviousSibling: xmlNodePtr read GetPreviousSibling;
    property  Text: string read GetText write SetText;
    property  Xml: string read GetXml;
  public
    { DOM & Browsers compatible additions }
    function  Contains(const Node: xmlNodePtr): Boolean;
    function  HasAttributes: Boolean;
    function  IsDefaultNamespace(const namespaceURI: string): Boolean;
    //TODO: procedure Normalize;
    property  BaseURI: string read GetBaseURI write SetBaseURI;
    property  LocalName: string read GetLocalName;
    property  ParentElement: xmlNodePtr read GetParentElement;
    property  TextContent: string read GetText write SetText;
  end;

  xmlAttrHelper = record helper for xmlAttr
  private type
    TSelf = type xmlAttr;
  private
    function  GetName: string; inline;
    function  GetNamespaceURI: string;
    function  GetNextSibling: xmlAttrPtr; inline;
    function  GetValue: string;
    function  GetOwnerDocument: xmlDocPtr; inline;
    function  GetParent: xmlNodePtr; inline;
    function  GetPrefix: string; inline;
    function  GetPreviousSibling: xmlAttrPtr; inline;
    procedure SetValue(const Value: string); inline;
    procedure SetName(const Value: string); inline;
    function  GetBaseURI: string; inline;
    procedure SetBaseURI(const Value: string); inline;
  public
    function  IsDefaultNamespace(const namespaceURI: string): Boolean; inline;
    property  NamespaceURI: string read GetNamespaceURI;
    property  NextSibling: xmlAttrPtr read GetNextSibling;
    property  Name: string read GetName write SetName;
    property  Value: string read GetValue write SetValue;
    property  OwnerDocument: xmlDocPtr read GetOwnerDocument;
    property  Prefix: string read GetPrefix;
    property  PreviousSibling: xmlAttrPtr read GetPreviousSibling;
    property  BaseURI: string read GetBaseURI write SetBaseURI;
    property  Parent: xmlNodePtr read GetParent;
  end;

  xmlDocHelper = record helper for xmlDoc
  private type
    TSelf = type xmlDoc;
  private
    function  GetDocumentElement: xmlNodePtr; inline;
    function  GetUrl: string; inline;
    function  GetXml: string;
    procedure SetDocumentElement(const Value: xmlNodePtr);
  public
    class function Create(const XML: RawByteString; const Options: TXmlParserOptions; ErrorHandler: xmlDocErrorHandler = nil): xmlDocPtr; overload; static; inline;
    class function Create(const XML: string; const Options: TXmlParserOptions; ErrorHandler: xmlDocErrorHandler = nil): xmlDocPtr; overload; static; inline;
    class function Create(const Data: TBytes; const Options: TXmlParserOptions; ErrorHandler: xmlDocErrorHandler = nil): xmlDocPtr; overload; static; inline;
    class function Create(const Data: Pointer; Size: NativeUInt; const Options: TXmlParserOptions; ErrorHandler: xmlDocErrorHandler = nil): xmlDocPtr; overload; static;
    class function CreateFromFile(const FileName: string; const Options: TXmlParserOptions; ErrorHandler: xmlDocErrorHandler = nil): xmlDocPtr; overload; static; inline;
    class function Create(Stream: TStream; const Options: TXmlParserOptions; const Encoding: Utf8String; ErrorHandler: xmlDocErrorHandler = nil): xmlDocPtr; overload; static;
    procedure Free;
    function  Canonicalize(const FileName: string; Mode: TXmlC14NMode = TXmlC14NMode.xmlC14N; Comments: Boolean = False): Boolean; overload;
    function  Canonicalize(const Stream: TStream; Mode: TXmlC14NMode = TXmlC14NMode.xmlC14N; Comments: Boolean = False): Boolean; overload;
    function  Canonicalize(Mode: TXmlC14NMode = TXmlC14NMode.xmlC14N; Comments: Boolean = False): xmlDocPtr; overload;
    function  CreateAttribute(const name: string; const value: string = ''): xmlAttrPtr; overload;
    function  CreateCDATASection(const data: string): xmlNodePtr;
    function  CreateComment(const data: string): xmlNodePtr;
    function  CreateDocumentFragment: xmlNodePtr;
    function  CreateElement(const Name: string): xmlNodePtr;
    function  CreateEntityReference(const name: string): xmlNodePtr;
    function  CreateProcessingInstruction(const target: string; const data: string): xmlNodePtr;
    function  CreateTextNode(const data: string): xmlNodePtr;
    function  DocType: xmlNodePtr;
    function  GetElementsByTagName(const name: string): xmlNodeArray;
    procedure ReconciliateNs;
    function  Save(const FileName: string; const Encoding: string = 'UTF-8'; const Options: TxmlSaveOptions = []): Boolean; overload;
    function  Save(Stream: TStream; const Encoding: string = 'UTF-8'; const Options: TxmlSaveOptions = []): Boolean; overload;
    function  ToAnsi(const Encoding: string = 'windows-1251'; const Format: Boolean = False): RawByteString; overload;
    function  ToBytes(const Encoding: string = 'UTF-8'; const Format: Boolean = False): TBytes; overload;
    function  ToString(const Format: Boolean = False): string; overload;
    function  ToUtf8(const Format: Boolean = False): RawByteString; overload;
    function  Transform(const stylesheet: xmlDocPtr; out doc: xmlDocPtr): Boolean; overload;
    function  Transform(const stylesheet: xmlDocPtr; out S: string): Boolean; overload;
    function  Validate(ErrorHandler: xmlDocErrorHandler = nil): Boolean;
    function  ValidateNode(Node: xmlNodePtr; ErrorHandler: xmlDocErrorHandler = nil): Boolean;
    property  documentElement: xmlNodePtr read GetDocumentElement write SetDocumentElement;
    property  URL: string read GetURL;
    property  Xml: string read GetXml;
  end;

procedure xmlDocErrorCallback(userData: Pointer; const error: xmlErrorPtr); cdecl;

implementation

uses
  libxslt.API;

function xmlStrPtr(const S: RawByteString): xmlCharPtr;
begin
  if S = '' then
    Result := nil
  else
    Result := Pointer(S);
end;

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

{ xmlNamespacesHelper }

procedure xmlNamespacesHelper.Add(const Prefix, URI: string);
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

function xmlNodeHelper.AppendChild(const NewChild: xmlNodePtr): xmlNodePtr;
begin
  Result := xmlAddChild(@Self, newChild);
end;

function xmlNodeHelper.ChildElementCount: LongWord;
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

function xmlNodeHelper.FindAttribute(const name: string): xmlAttrPtr;
var
  prefix, localName: xmlCharPtr;
begin
  xmlResetLocalBuffers;
  SplitXMLName(Name, prefix, localName);

  var prop := properties;
  while prop <> nil do
  begin
    if xmlStrSame(xmlNodeHeaderPtr(prop).name, localName) then
    begin
      if (prefix = nil) and (prop.ns = nil) then
        Exit(prop)
      else if (prop.ns <> nil) and xmlStrSame(prefix, prop.ns.prefix) then
        Exit(prop);
    end;
    prop := prop.next;
  end;
  Result := nil;
end;

function xmlNodeHelper.FindAttribute(const name, namespaceURI: string): xmlAttrPtr;
begin
  xmlResetLocalBuffers;
  var localName := LocalXmlStr(name);
  var href := LocalXmlStr(namespaceURI);

  var prop := properties;
  while prop <> nil do
  begin
    if xmlStrSame(xmlNodeHeaderPtr(prop).name, localName) then
    begin
      if (href = nil) and (prop.ns = nil) then
        Exit(prop)
      else if (prop.ns <> nil) and xmlStrSame(prop.ns.href, href) then
        Exit(prop);
    end;
    prop := prop.next;
  end;
  Result := nil;
end;

function xmlNodeHelper.SearchNs(const prefix: string): xmlNsPtr;
begin
  xmlResetLocalBuffers;
  Result := xmlSearchNs(doc, @Self, LocalXmlStr(prefix));
end;

function xmlNodeHelper.SearchNs(const prefix: xmlCharPtr): xmlNsPtr;
begin
  Result := xmlSearchNs(doc, @Self, prefix);
end;

function xmlNodeHelper.SearchNsByRef(const href: string): xmlNsPtr;
begin
  xmlResetLocalBuffers;
  Result := xmlSearchNsByHref(doc, @Self, LocalXmlStr(href));
end;

function xmlNodeHelper.SearchNsByRef(const href: xmlCharPtr): xmlNsPtr;
begin
  Result := xmlSearchNsByHref(doc, @Self, href);
end;

function xmlNodeHelper.FirstElementChild: xmlNodePtr;
begin
  Result := xmlFirstElementChild(@Self);
end;

function xmlNodeHelper.GetAttribute(const name: string): string;
begin
  xmlResetLocalBuffers;
  Result := xmlCharToStrAndFree(xmlGetProp(@Self, LocalXmlStr(name)));
end;

function xmlNodeHelper.GetNsAttribute(const name, namespaceURI: string): string;
begin
  xmlResetLocalBuffers;
  Result := xmlCharToStrAndFree(xmlGetNsProp(@Self, LocalXmlStr(name), LocalXmlStr(namespaceURI)));
end;

function xmlNodeHelper.SetNsAttribute(const name, namespaceURI, value: string): xmlAttrPtr;
begin
  xmlResetLocalBuffers;
  var ns := xmlSearchNsByHref(doc, @Self, LocalXmlStr(namespaceURI));
  Result := xmlSetNsProp(@Self, ns, LocalXmlStr(name), LocalXmlStr(value));
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

function xmlNodeHelper.GetBaseURI: string;
begin
  var S := xmlNodeGetBase(doc, @Self);
  Result := xmlCharToStrAndFree(S);
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

function xmlNodeHelper.GetValue: string;
begin
  Result := '';
  if &type in [XML_TEXT_NODE, XML_CDATA_SECTION_NODE] then
  begin
    if content = nil then
      Exit;
    Result := xmlCharToStr(content);
  end
  else
  begin
    var node := children;
    while node <> nil do
    begin
      if node.&type in [XML_TEXT_NODE, XML_CDATA_SECTION_NODE] then
        Result := Result + xmlCharToStr(node.content).Trim;

      node := node.next;
    end;
  end;
end;

function xmlNodeHelper.GetNext(Node: xmlNodePtr): xmlNodePtr;
begin
  Result := Node;
  if Assigned(Result) then
  begin
    if Result.children <> nil then
      Exit(Result.children);

    repeat
      if Result.next <> nil then
      begin
        Result := Result.next;
        Break;
      end
      else
      begin
        if Result.parent <> @Self then
          Result := Result.parent
        else
        begin
          Result := nil;
          Break;
        end;
      end;
    until False;
  end;
end;

function xmlNodeHelper.GetElementsByTagName(const name: string): xmlNodeArray;
begin
  if name = '' then
    Exit(nil);

  var all := name = '*';

  var Capacity := 16;
  SetLength(Result, capacity);

  var mask := Utf8Encode(name);

  var count := 0;
  var node := GetNext(@Self);
  while node <> nil do
  begin
    if node.&type = XML_ELEMENT_NODE then
    begin
      if all or xmlStrSame(node.name, Pointer(mask)) then
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

function xmlNodeHelper.GetLocalName: string;
begin
  Result := xmlCharToStr(name);
end;

function xmlNodeHelper.GetNamespaceURI: string;
begin
  if ns = nil then
    Result := ''
  else
    Result := xmlCharToStr(ns.href);
end;

function xmlNodeHelper.GetNextSibling: xmlNodePtr;
begin
  Result := next;
end;

function xmlNodeHelper.GetNodeName: string;
begin
  if (ns = nil) or (ns.prefix = nil) then
    Result := xmlCharToStr(TSelf(Self).name)
  else
    Result := Utf8ToString(ns.prefix) + ':' + Utf8ToString(TSelf(Self).name);
end;

function xmlNodeHelper.GetNodeType: xmlElementType;
begin
  Result := &type;
end;

function xmlNodeHelper.GetNodeValue: string;
begin
  case &type of
    XML_ATTRIBUTE_NODE,
    XML_TEXT_NODE,
    XML_CDATA_SECTION_NODE,
    XML_COMMENT_NODE: Result := xmlCharToStrAndFree(xmlNodeGetContent(@Self));
    XML_ATTRIBUTE_DECL: Result := xmlCharToStrAndFree(xmlAttributePtr(@Self).defaultValue);
    XML_PI_NODE:
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

function xmlNodeHelper.GetPath: string;
begin
  Result := xmlCharToStrAndFree(xmlGetNodePath(@Self));
end;

function xmlNodeHelper.GetPrefix: string;
begin
  if ns = nil then
    Result := ''
  else
    Result := xmlCharToStr(ns.prefix);
end;

function xmlNodeHelper.GetPreviousSibling: xmlNodePtr;
begin
  Result := prev;
end;

function xmlNodeHelper.GetRootNode: xmlNodePtr;
begin
  Result := xmlDocGetRootElement(doc);
end;

function xmlNodeHelper.GetText: string;
begin
  Result := xmlCharToStrAndFree(xmlNodeGetContent(@Self));
end;

function xmlNodeHelper.GetXml: string;
begin
  var Buf := xmlAllocOutputBuffer(nil);
  xmlNodeDumpOutput(Buf, doc, @Self, 0, 0, nil);
  Result := xmlCharToStr(xmlOutputBufferGetContent(Buf), xmlOutputBufferGetSize(Buf));
  xmlOutputBufferClose(Buf);
end;

function xmlNodeHelper.HasAttribute(const Name: string): Boolean;
begin
  xmlResetLocalBuffers;
  Result := xmlHasProp(@Self, LocalXmlStr(Name)) <> nil;
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
  xmlReconciliateNs(doc, @Self);
end;

function xmlNodeHelper.IsBlank: Boolean;
begin
  Result := xmlIsBlankNode(@Self) = 1;
end;

function xmlNodeHelper.IsDefaultNamespace(const namespaceURI: string): Boolean;
begin
  if nsDef = nil then
    Result := namespaceURI = ''
  else
    Result := AnsiSameText(xmlCharToStr(nsDef.href), namespaceURI);
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

procedure xmlNodeHelper.RemoveAttribute(const name: string);
begin
  xmlResetLocalBuffers;

  var prop := xmlHasProp(@Self, LocalXmlStr(name));
  if prop <> nil then
    xmlRemoveProp(prop);
end;

procedure xmlNodeHelper.RemoveAttributeNode(const Attr: xmlAttrPtr);
begin
  xmlRemoveProp(Attr);
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

function xmlNodeHelper.SelectNodes(const queryString: string; const namespaces: xmlNamespaces): xmlNodeArray;
begin
  var ctx := xmlXPathNewContext(doc);
  try
    xmlXPathSetContextNode(@Self, ctx);

    if Length(namespaces) > 0 then
    begin
      for var I := Low(namespaces) to High(namespaces) do
      begin
        xmlResetLocalBuffers;
        xmlXPathRegisterNs(ctx, LocalXmlStr(namespaces[I].Prefix), LocalXmlStr(namespaces[I].URI));
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

    xmlResetLocalBuffers;
    var xpathObj := xmlXPathEvalExpression(LocalXmlStr(queryString), ctx);
    if (xpathObj = nil) or (xpathObj.nodesetval = nil) or (xpathObj.nodesetval.nodeNr = 0) then
      Exit(nil);

    var nodes := xpathObj.nodesetval;
    SetLength(Result, nodes.nodeNr);
    for var I := 0 to nodes.nodeNr - 1 do
      Result[I] := nodes.nodeTab[I];

    xmlXPathFreeObject(xpathObj);
  finally
    xmlXPathFreeContext(ctx);
  end;
end;

function xmlNodeHelper.SelectSingleNode(const queryString: string): xmlNodePtr;
begin
  var ctx := xmlXPathNewContext(doc);
  try
    xmlXPathSetContextNode(@Self, ctx);

    xmlResetLocalBuffers;

    var xpathObj := xmlXPathEvalExpression(LocalXmlStr(queryString), ctx);
    if (xpathObj = nil) or (xpathObj.nodesetval = nil) or (xpathObj.nodesetval.nodeNr = 0) then
      Exit(nil);

    Result := xpathObj.nodesetval.nodeTab[0];
    xmlXPathFreeObject(xpathObj);
  finally
    xmlXPathFreeContext(ctx);
  end;
end;

procedure xmlNodeHelper.SetAttribute(const name, value: string);
begin
  xmlResetLocalBuffers;
  xmlSetProp(@Self, LocalXmlStr(name), LocalXmlStr(value));
end;

procedure xmlNodeHelper.SetBaseURI(const Value: string);
begin
  xmlResetLocalBuffers;
  xmlNodeSetBase(@Self, LocalXmlStr(Value));
end;

procedure xmlNodeHelper.SetNodeName(const Value: string);
begin
  xmlResetLocalBuffers;
  xmlNodeSetName(@Self, LocalXmlStr(Value));
end;

procedure xmlNodeHelper.SetNodeValue(const Value: string);
begin
  case &type of
    XML_ELEMENT_NODE,
    XML_ATTRIBUTE_NODE,
    XML_TEXT_NODE,
    XML_CDATA_SECTION_NODE,
    XML_COMMENT_NODE: xmlNodeSetContent(@Self, XmlCharPtr(UTF8Encode(Value)));
  end;
end;

procedure xmlNodeHelper.SetText(const Value: string);
begin
  xmlResetLocalBuffers;
  xmlNodeSetContent(@Self, LocalXmlStr(Value));
end;

{ xmlAttrHelper }

function xmlAttrHelper.GetBaseURI: string;
begin
  var S := xmlNodeGetBase(doc, @Self);
  Result := xmlCharToStrAndFree(S);
end;

function xmlAttrHelper.GetName: string;
begin
  Result := xmlCharToStr(TSelf(Self).name);
end;

function xmlAttrHelper.GetNamespaceURI: string;
begin
  if ns = nil then
    Result := ''
  else
    Result := xmlCharToStr(ns.href);
end;

function xmlAttrHelper.GetNextSibling: xmlAttrPtr;
begin
  Result := next;
end;

function xmlAttrHelper.GetOwnerDocument: xmlDocPtr;
begin
  Result := doc;
end;

function xmlAttrHelper.GetParent: xmlNodePtr;
begin
  Result := parent;
end;

function xmlAttrHelper.GetPrefix: string;
begin
  if ns = nil then
    Result := ''
  else
    Result := xmlCharToStr(ns.prefix);
end;

function xmlAttrHelper.GetPreviousSibling: xmlAttrPtr;
begin
  Result := prev;
end;

function xmlAttrHelper.GetValue: string;
begin
  var child := children;
  if child = nil then
    Exit('');

  if ((child.&type = XML_TEXT_NODE) or (child.&type = XML_CDATA_SECTION_NODE)) and (child.next = nil) then
    if child.content = nil then
      Exit('')
    else
      Exit(xmlCharToStr(child.content));
end;

function xmlAttrHelper.IsDefaultNamespace(const namespaceURI: string): Boolean;
begin
  if ns = nil then
    Result := namespaceURI = ''
  else
    Result := AnsiSameText(xmlCharToStr(ns.href), namespaceURI);
end;

procedure xmlAttrHelper.SetBaseURI(const Value: string);
begin
  xmlResetLocalBuffers;
  xmlNodeSetBase(@Self, LocalXmlStr(Value));
end;

procedure xmlAttrHelper.SetName(const Value: string);
begin
  xmlResetLocalBuffers;
  xmlNodeSetName(@Self, LocalXmlStr(Value));
end;

procedure xmlAttrHelper.SetValue(const Value: string);
begin
  xmlResetLocalBuffers;

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
    var newChild := xmlNewDocText(doc, LocalXmlStr(Value));
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
    xmlAddIDSafe(@Self, LocalXmlStr(Value));
end;

{ xmlDocHelper }

type
  PXmlCallback = ^TXmlCallback;
  TXmlCallback = record
    Handler: xmlDocErrorHandler;
  end;

procedure xmlDocErrorCallback(userData: Pointer; const error: xmlErrorPtr); cdecl;
begin
  if userData <> nil then
    if Assigned(PXmlCallback(userData).Handler) then
      PXmlCallback(userData).Handler(error^);
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
  ecb: TXmlCallback;
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
  ecb: TXmlCallback;
begin
  xmlResetLocalBuffers;

  var ctx := xmlNewParserCtxt();
  if ctx = nil then
    Exit(nil);

  if Assigned(ErrorHandler) then
  begin
    ecb.Handler := ErrorHandler;
    xmlCtxtSetErrorHandler(ctx, xmlDocErrorCallback, @ecb);
  end;

  xmlCtxtUseOptions(ctx, XmlParserOptions(Options) or XML_PARSE_UNZIP or XML_PARSE_NONET);

  if xmlNewInputFromUrl(LocalXmlStr(filename), XML_INPUT_BUF_STATIC, input) = XML_ERR_OK then
    Result := xmlCtxtParseDocument(ctx, input)
  else
    Result := nil;

  xmlFreeParserCtxt(ctx);
end;

class function xmlDocHelper.Create(Stream: TStream; const Options: TXmlParserOptions; const Encoding: Utf8String; ErrorHandler: xmlDocErrorHandler): xmlDocPtr;
var
  ecb: TXmlCallback;
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

function xmlDocHelper.Canonicalize(const Stream: TStream; Mode: TXmlC14NMode; Comments: Boolean): Boolean;
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

function xmlDocHelper.Canonicalize(const FileName: string; Mode: TXmlC14NMode; Comments: Boolean): Boolean;
begin
  xmlResetLocalBuffers;
  Result := xmlC14NDocSave(Doc, nil, xmlC14NMode(Ord(Mode)), nil, Ord(Comments), LocalXmlStr(FileName), 0) = 0;
end;

function xmlDocHelper.Canonicalize(Mode: TXmlC14NMode; Comments: Boolean): xmlDocPtr;
var
  Data: Pointer;
begin
  var Size := xmlC14NDocDumpMemory(Doc, nil, xmlC14NMode(Mode), nil, Ord(Comments), xmlCharPtr(Data));
  if Size < 0 then
    LX2InternalError;

  Result := xmlDoc.Create(Data, Size, DefaultParserOptions, nil);

  xmlFree(Data);
end;

function xmlDocHelper.CreateAttribute(const name, value: string): xmlAttrPtr;
begin
  xmlResetLocalBuffers;
  Result := xmlNewDocProp(@Self, LocalXmlStr(name), LocalXmlStr(value));
end;

function xmlDocHelper.CreateCDATASection(const data: string): xmlNodePtr;
begin
  var S := Utf8Encode(data);
  Result := xmlNewCDataBlock(@Self, xmlCharPtr(S), Length(S));
end;

function xmlDocHelper.CreateComment(const data: string): xmlNodePtr;
begin
  xmlResetLocalBuffers;
  Result := xmlNewDocComment(@Self, LocalXmlStr(data));
end;

function xmlDocHelper.CreateDocumentFragment: xmlNodePtr;
begin
  Result := xmlNewDocFragment(@Self);
end;

function xmlDocHelper.CreateElement(const Name: string): xmlNodePtr;
begin
  xmlResetLocalBuffers;
  Result := xmlNewDocRawNode(@Self, nil, LocalXmlStr(Name), nil);
end;

function xmlDocHelper.CreateEntityReference(const name: string): xmlNodePtr;
begin
  xmlResetLocalBuffers;
  Result := xmlNewReference(@Self, LocalXmlStr(Name));
end;

function xmlDocHelper.CreateProcessingInstruction(const target, data: string): xmlNodePtr;
begin
  xmlResetLocalBuffers;
  Result := xmlNewDocPI(@Self, LocalXmlStr(target), LocalXmlStr(data));
end;

function xmlDocHelper.CreateTextNode(const data: string): xmlNodePtr;
begin
  xmlResetLocalBuffers;
  Result := xmlNewDocText(@Self, LocalXmlStr(data));
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

function xmlDocHelper.GetElementsByTagName(const name: string): xmlNodeArray;
begin
  if children = nil then
    Exit(nil);

  Result := children.getElementsByTagName(name);
end;

function xmlDocHelper.GetUrl: string;
begin
  Result := xmlCharToStr(TSelf(Self).URL);
end;

function xmlDocHelper.GetXml: string;
var
  Data: Pointer;
  Size: Integer;
begin
  xmlDocDumpMemoryEnc(doc, Data, Size, 'UTF-8');

  if (Data = nil) or (Size = 0) then
    Exit('');
  Result := xmlCharToStr(xmlCharPtr(Data), Size);

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
  xmlDocSetRootElement(@Self, Value);
end;

function xmlDocHelper.ToAnsi(const Encoding: string; const Format: Boolean): RawByteString;
var
  Data: Pointer;
  Size: Integer;
begin
  xmlResetLocalBuffers;

  xmlDocDumpFormatMemoryEnc(doc, Data, Size, LocalXmlStr(Encoding), Ord(Format));

  if (Data = nil) or (Size = 0) then
  begin
    xmlFree(Data);
    Exit('');
  end;
  SetString(Result, PAnsiChar(Data), Size);

  xmlFree(Data);
end;

function xmlDocHelper.ToString(const Format: Boolean): string;
var
  Data: Pointer;
  Size: Integer;
begin
  xmlDocDumpFormatMemoryEnc(doc, Data, Size, 'UTF-8', Ord(Format));

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

function xmlDocHelper.Transform(const stylesheet: xmlDocPtr; out doc: xmlDocPtr): Boolean;
begin
  Result := False;

  XSLTLib.Initialize;

  var style := xsltParseStylesheetDoc(stylesheet);
  if style = nil then
    Exit;

  doc := xsltApplyStylesheet(style, @Self, nil);
  Result := doc <> nil;

  xsltFreeStylesheet(style);
end;

function xmlDocHelper.Transform(const stylesheet: xmlDocPtr; out S: string): Boolean;
var
  doc: xmlDocPtr;
  text: xmlCharPtr;
  len: Integer;
begin
  Result := False;

  XSLTLib.Initialize;

  var style := xsltParseStylesheetDoc(stylesheet);
  if style = nil then
    Exit;

  doc := xsltApplyStylesheet(style, @Self, nil);
  if doc <> nil then
  begin
    if xsltSaveResultToString(text, len, doc, style) = 0 then
    begin
      S := xmlCharToStr(text, len);
      Result := True;
      xmlFree(text);
    end;
  end;

  xsltFreeStylesheet(style);
end;

function xmlDocHelper.ToBytes(const Encoding: string; const Format: Boolean): TBytes;
var
  Data: Pointer;
  Size: Integer;
begin
  xmlResetLocalBuffers;

  xmlDocDumpFormatMemoryEnc(doc, Data, Size, LocalXmlStr(Encoding), Ord(Format));

  if (Data = nil) or (Size = 0) then
    Exit(nil);
  SetLength(Result, Size);
  Move(Data^, Pointer(Result)^, Size);

  XmlFree(Data);
end;

function xmlDocHelper.Save(const FileName: string; const Encoding: string; const Options: TxmlSaveOptions): Boolean;
begin
  xmlResetLocalBuffers;

  var ctx := xmlSaveToFilename(LocalXmlStr(FileName), LocalXmlStr(Encoding), XmlSaveOptions(Options));
  xmlSaveDoc(ctx, @Self);
  Result := xmlSaveFinish(ctx) = XML_ERR_OK;
end;

function xmlDocHelper.validate(ErrorHandler: xmlDocErrorHandler = nil): Boolean;
var
  ecb: TXmlCallback;
begin
  var ctx := xmlNewParserCtxt;
  if Assigned(ErrorHandler) then
  begin
    ecb.Handler := ErrorHandler;
    xmlCtxtSetErrorHandler(ctx, xmlDocErrorCallback, @ecb);
  end;
  Result := xmlCtxtValidateDocument(ctx, @Self) = 1;
  xmlFreeParserCtxt(ctx);
end;

function xmlDocHelper.ValidateNode(Node: xmlNodePtr; ErrorHandler: xmlDocErrorHandler): Boolean;
var
  ecb: TXmlCallback;
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
