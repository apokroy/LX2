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
/// Classes and interfaces for SAX parser
///</summary>

unit LX2.SAX;

interface

uses
  System.SysUtils,
  libxml2.API, LX2.Types;

type
  TLX2SAXParserWrapper = class(TObject)
  private
    FOptions: TXmlParserOptions;
  protected
    SAX: xmlSAXHandler;
    Ctxt: xmlParserCtxtPtr;
    procedure PrepareContext; virtual;
  protected
    procedure SetDocumentLocator(loc: xmlSAXLocatorPtr); virtual;
    procedure StartDocument; virtual;
    procedure EndDocument; virtual;
    procedure StartElement(const localname, prefix, URI: xmlCharPtr; nb_namespaces: Integer; namespaces: xmlSAX2NsPtr; nb_attributes, nb_defaulted: Integer; attributes: xmlSAX2AttrPtr); virtual;
    procedure EndElement(const localname, prefix, URI: xmlCharPtr); virtual;
    procedure InternalSubset(const name, ExternalID, SystemID: xmlCharPtr); virtual;
    procedure ExternalSubset(const name, ExternalID, SystemID: xmlCharPtr); virtual;
    function  HasInternalSubset: Boolean; virtual;
    function  HasExternalSubset: Boolean; virtual;
    function  ResolveEntity(const publicId, systemId: xmlCharPtr): xmlParserInputPtr; virtual;
    function  GetEntity(const name: xmlCharPtr): xmlEntityPtr; virtual;
    function  GetParameterEntity(const name: xmlCharPtr): xmlEntityPtr; virtual;
    procedure EntityDecl(const name: xmlCharPtr; entType: Integer; publicId, systemId, content: xmlCharPtr); virtual;
    procedure NotationDecl(const name, publicId, systemId: xmlCharPtr); virtual;
    procedure AttributeDecl(const elem, fullname: xmlCharPtr; attrType, def: Integer; defaultValue: xmlCharPtr; tree: xmlEnumerationPtr); virtual;
    procedure ElementDecl(const name: xmlCharPtr; elemType: Integer; content: xmlElementContentPtr); virtual;
    procedure UnparsedEntityDecl(const name, publicId, systemId, notationName: xmlCharPtr); virtual;
    procedure Reference(const name: xmlCharPtr); virtual;
    procedure Characters(const ch: xmlCharPtr; len: Integer); virtual;
    procedure IgnorableWhitespace(const ch: xmlCharPtr; len: Integer); virtual;
    procedure ProcessingInstruction(const target, data: xmlCharPtr); virtual;
    procedure Comment(const value: xmlCharPtr); virtual;
    procedure CDataBlock(const value: xmlCharPtr; len: Integer); virtual;
    procedure StructuredError(const error: xmlErrorPtr); virtual;
  public
    constructor Create;
    destructor Destroy; override;
    function  ParseFile(const FileName: string): Boolean;
    function  Parse(const Xml: string): Boolean; overload;
    function  Parse(const Xml: RawByteString): Boolean; overload;
    function  Parse(const Data: Pointer; Size: NativeUInt): Boolean; overload;
    function  Parse(const Data: TBytes): Boolean; overload;
    procedure Stop;
    property  Options: TXmlParserOptions read FOptions write FOptions;
  end;

  ISAXLocator = interface
    ['{71F3FBC1-2EC3-4144-8FE2-C835B942AB00}']
    function GetPublicId: string;
    function GetSystemId: string;
    function GetLineNumber: Integer;
    function GetColumnNumber: Integer;
  end;

  TSAXLocator = class(TNoRefCountObject, ISAXLocator)
  protected
    Loc: xmlSAXLocatorPtr;
    Parser: TLX2SAXParserWrapper;
  public
    function GetPublicId: string;
    function GetSystemId: string;
    function GetLineNumber: Integer;
    function GetColumnNumber: Integer;
  end;

  TSAXAttribute = record
    Name: string;
    Prefix: string;
    URI: string;
    Value: string;
    Defaulted: Boolean;
  end;
  TSAXAttributes = TArray<TSAXAttribute>;

  TSAXNamespace = record
    Prefix: string;
    URI: string;
  end;
  TSAXNamespaces = TArray<TSAXNamespace>;

  ISAXContentHandler = interface(IUnknown)
  ['{C4E14ED1-8764-400B-98E3-139842A6DB03}']
    procedure PutDocumentLocator(const Locator: ISAXLocator);
    procedure StartDocument;
    procedure EndDocument;
    procedure StartElement(const LocalName, Prefix, URI: string; const Namespaces: TSAXNamespaces; const Attributes: TSAXAttributes);
    procedure EndElement(const LocalName, Prefix, URI: string);
    procedure Characters(const Chars: string);
    procedure IgnorableWhitespace(const Chars: string);
    procedure ProcessingInstruction(const Target, Data: string);
  end;

  TSAXCustomParser = class(TLX2SAXParserWrapper)
  private
    FErrors: TXmlParseErrors;
    FLocator: TSAXLocator;
    FPreserveWhitespaces: Boolean;
    function  GetLocator: ISAXLocator; inline;
  protected
    procedure PrepareContext; override;
  protected
    procedure SetDocumentLocator(loc: xmlSAXLocatorPtr); override;
    procedure StartDocument; override;
    procedure EndDocument; override;
    procedure EndElement(const localname, prefix, URI: xmlCharPtr); override;
    procedure StartElement(const localname, prefix, URI: xmlCharPtr; nb_namespaces: Integer; namespaces: xmlSAX2NsPtr; nb_attributes, nb_defaulted: Integer; attributes: xmlSAX2AttrPtr); override;
    procedure StructuredError(const error: xmlErrorPtr); override;
    procedure Characters(const ch: xmlCharPtr; len: Integer); override;
    procedure IgnorableWhitespace(const ch: xmlCharPtr; len: Integer); override;
    procedure ProcessingInstruction(const target, data: xmlCharPtr); override;
  protected
    procedure DoStartDocument; virtual;
    procedure DoEndDocument; virtual;
    procedure DoEndElement(const LocalName, Prefix, URI: string); virtual;
    procedure DoStartElement(const LocalName, Prefix, URI: string; const Namespaces: TSAXNamespaces; const Attributes: TSAXAttributes); virtual;
    procedure DoCharacters(const Chars: string); virtual;
    procedure DoIgnorableWhitespace(const Chars: string); virtual;
    procedure DoProcessingInstruction(const Target, Data: string); virtual;
  public
    constructor Create;
    destructor Destroy; override;
    property  Locator: ISAXLocator read GetLocator;
    property  Errors: TXmlParseErrors read FErrors;
    property  PreserveWhitespaces: Boolean read FPreserveWhitespaces write FPreserveWhitespaces;
  end;

  TSAXParser = class(TSAXCustomParser)
  private
    FHandler: ISAXContentHandler;
  protected
    procedure DoStartDocument; override;
    procedure DoEndDocument; override;
    procedure DoEndElement(const LocalName, Prefix, URI: string); override;
    procedure DoStartElement(const LocalName, Prefix, URI: string; const Namespaces: TSAXNamespaces; const Attributes: TSAXAttributes); override;
    procedure DoCharacters(const Chars: string); override;
    procedure DoIgnorableWhitespace(const Chars: string); override;
    procedure DoProcessingInstruction(const Target, Data: string); override;
  public
    property  Handler: ISAXContentHandler read FHandler write FHandler;
  end;

  TSAXCustomContentHandler = class(TInterfacedObject, ISAXContentHandler)
  public
    procedure PutDocumentLocator(const Locator: ISAXLocator); virtual;
    procedure StartDocument; virtual;
    procedure EndDocument; virtual;
    procedure StartElement(const LocalName, Prefix, URI: string; const Namespaces: TSAXNamespaces; const Attributes: TSAXAttributes); virtual;
    procedure EndElement(const LocalName, Prefix, URI: string); virtual;
    procedure Characters(const Chars: string); virtual;
    procedure IgnorableWhitespace(const Chars: string); virtual;
    procedure ProcessingInstruction(const Target, Data: string); virtual;
  end;

implementation

procedure setDocumentLocatorCallback(ctx: Pointer; loc: xmlSAXLocatorPtr); cdecl;
begin
  TLX2SAXParserWrapper(ctx).SetDocumentLocator(loc);
end;

procedure startDocumentCallback(ctx: Pointer); cdecl;
begin
  TLX2SAXParserWrapper(ctx).StartDocument;
end;

procedure endDocumentCallback(ctx: Pointer); cdecl;
begin
  TLX2SAXParserWrapper(ctx).EndDocument;
end;

procedure startElementNsCallback(ctx: Pointer; const localname, prefix, URI: xmlCharPtr; nb_namespaces: Integer; namespaces: xmlSAX2NsPtr; nb_attributes, nb_defaulted: Integer; attributes: xmlSAX2AttrPtr); cdecl;
begin
  TLX2SAXParserWrapper(ctx).StartElement(localname, prefix, URI, nb_namespaces, namespaces, nb_attributes, nb_defaulted, attributes);
end;

procedure endElementNsCallback(ctx: Pointer; const localname, prefix, URI: xmlCharPtr); cdecl;
begin
  TLX2SAXParserWrapper(ctx).EndElement(localname, prefix, URI);
end;

procedure internalSubsetCallback(ctx: Pointer; const name, ExternalID, SystemID: xmlCharPtr); cdecl;
begin
  TLX2SAXParserWrapper(ctx).InternalSubset(name, ExternalID, SystemID);
end;

procedure externalSubsetCallback(ctx: Pointer; const name, ExternalID, SystemID: xmlCharPtr); cdecl;
begin
  TLX2SAXParserWrapper(ctx).ExternalSubset(name, ExternalID, SystemID);
end;

function hasInternalSubsetCallback(ctx: Pointer): Integer; cdecl;
begin
  Result := Ord(TLX2SAXParserWrapper(ctx).HasInternalSubset);
end;

function hasExternalSubsetCallback(ctx: Pointer): Integer; cdecl;
begin
  Result := Ord(TLX2SAXParserWrapper(ctx).HasExternalSubset);
end;

function resolveEntityCallback(ctx: Pointer; const publicId, systemId: xmlCharPtr): xmlParserInputPtr; cdecl;
begin
  Result := TLX2SAXParserWrapper(ctx).ResolveEntity(publicId, systemId);
end;

function getEntityCallback(ctx: Pointer; const name: xmlCharPtr): xmlEntityPtr; cdecl;
begin
  Result := TLX2SAXParserWrapper(ctx).GetEntity(name);
end;

function getParameterEntityCallback(ctx: Pointer; const name: xmlCharPtr): xmlEntityPtr; cdecl;
begin
  Result := TLX2SAXParserWrapper(ctx).GetParameterEntity(name);
end;

procedure entityDeclCallback(ctx: Pointer; const name: xmlCharPtr; entType: Integer; publicId, systemId, content: xmlCharPtr); cdecl;
begin
  TLX2SAXParserWrapper(ctx).EntityDecl(name, entType, publicId, systemId, content);
end;

procedure notationDeclCallback(ctx: Pointer; const name, publicId, systemId: xmlCharPtr); cdecl;
begin
  TLX2SAXParserWrapper(ctx).NotationDecl(name, publicId, systemId);
end;

procedure attributeDeclCallback(ctx: Pointer; const elem, fullname: xmlCharPtr; attrType, def: Integer; defaultValue: xmlCharPtr; tree: xmlEnumerationPtr); cdecl;
begin
  TLX2SAXParserWrapper(ctx).AttributeDecl(elem, fullname, attrType, def, defaultValue, tree);
end;

procedure elementDeclCallback(ctx: Pointer; const name: xmlCharPtr; elemType: Integer; content: xmlElementContentPtr); cdecl;
begin
  TLX2SAXParserWrapper(ctx).ElementDecl(name, elemType, content);
end;

procedure unparsedEntityDeclCallback(ctx: Pointer; const name, publicId, systemId, notationName: xmlCharPtr); cdecl;
begin
  TLX2SAXParserWrapper(ctx).UnparsedEntityDecl(name, publicId, systemId, notationName);
end;

procedure referenceCallback(ctx: Pointer; const name: xmlCharPtr); cdecl;
begin
  TLX2SAXParserWrapper(ctx).Reference(name);
end;

procedure charactersCallback(ctx: Pointer; const ch: xmlCharPtr; len: Integer); cdecl;
begin
  TLX2SAXParserWrapper(ctx).Characters(ch, len);
end;

procedure ignorableWhitespaceCallback(ctx: Pointer; const ch: xmlCharPtr; len: Integer); cdecl;
begin
  TLX2SAXParserWrapper(ctx).IgnorableWhitespace(ch, len);
end;

procedure processingInstructionCallback(ctx: Pointer; const target, data: xmlCharPtr); cdecl;
begin
  TLX2SAXParserWrapper(ctx).ProcessingInstruction(target, data);
end;

procedure commentCallback(ctx: Pointer; const value: xmlCharPtr); cdecl;
begin
  TLX2SAXParserWrapper(ctx).Comment(value);
end;

procedure cdataBlockCallback(ctx: Pointer; const value: xmlCharPtr; len: Integer); cdecl;
begin
  TLX2SAXParserWrapper(ctx).CDataBlock(value, len);
end;

procedure StructuredErrorCallback(userData: Pointer; const error: xmlErrorPtr); cdecl;
begin
  TLX2SAXParserWrapper(userData).StructuredError(error);
end;

{ TLX2SAXParserWrapper }

constructor TLX2SAXParserWrapper.Create;
begin
  inherited Create;

  LX2Lib.Initialize;

  FOptions := DefaultParserOptions;

  FillChar(sax, SizeOf(xmlSAXHandler), 0);
  SAX.initialized := XML_SAX2_MAGIC;
  SAX.startElementNs        := StartElementNsCallback;
  SAX.endElementNs          := EndElementNsCallback;
  SAX.internalSubset        := InternalSubsetCallback;
  SAX.externalSubset        := ExternalSubsetCallback;
  SAX.hasInternalSubset     := HasInternalSubsetCallback;
  SAX.hasExternalSubset     := HasExternalSubsetCallback;
  SAX.resolveEntity         := ResolveEntityCallback;
  SAX.getEntity             := GetEntityCallback;
  SAX.getParameterEntity    := GetParameterEntityCallback;
  SAX.entityDecl            := EntityDeclCallback;
  SAX.attributeDecl         := AttributeDeclCallback;
  SAX.elementDecl           := ElementDeclCallback;
  SAX.notationDecl          := NotationDeclCallback;
  SAX.unparsedEntityDecl    := UnparsedEntityDeclCallback;
  SAX.setDocumentLocator    := SetDocumentLocatorCallback;
  SAX.startDocument         := StartDocumentCallback;
  SAX.endDocument           := EndDocumentCallback;
  SAX.reference             := ReferenceCallback;
  SAX.characters            := CharactersCallback;
  SAX.cdataBlock            := CDataBlockCallback;
  SAX.ignorableWhitespace   := ignorableWhitespaceCallback;
  SAX.processingInstruction := ProcessingInstructionCallback;
  SAX.comment               := CommentCallback;
end;

destructor TLX2SAXParserWrapper.Destroy;
begin
  if Ctxt <> nil then
    xmlFreeParserCtxt(Ctxt);
  inherited;
end;

function TLX2SAXParserWrapper.Parse(const Xml: string): Boolean;
begin
  Result := Parse(UTF8Encode(Xml));
end;

function TLX2SAXParserWrapper.Parse(const Xml: RawByteString): Boolean;
begin
  Result := Parse(Pointer(Xml), Length(Xml));
end;

function TLX2SAXParserWrapper.Parse(const Data: Pointer; Size: NativeUInt): Boolean;
begin
  Ctxt := xmlCreatePushParserCtxt(@sax, Self, nil, 0, nil);
  try
    PrepareContext;
    xmlParseChunk(ctxt, Data, Size, 1);

    Result := xmlCtxtGetStatus(Ctxt) = 0;
  finally
    xmlFreeParserCtxt(Ctxt);
    Ctxt := nil;
  end;
end;

function TLX2SAXParserWrapper.Parse(const Data: TBytes): Boolean;
begin
  Result := Parse(Pointer(Data), Length(Data));
end;

function TLX2SAXParserWrapper.ParseFile(const FileName: string): Boolean;
const
  BufferSize = 16 * 1024;
var
  Chunk: array[0..BufferSize - 1] of Byte;
begin
  var Handle := FileOpen(FileName, fmOpenRead or fmShareDenyWrite);
  if Handle = INVALID_HANDLE_VALUE then
    RaiseLastOSError;
  try
    Ctxt := xmlCreatePushParserCtxt(@sax, Self, nil, 0, xmlCharPtr(Utf8Encode(FileName)));
    try
      PrepareContext;
      var ChunkSize := FileRead(Handle, Chunk, BufferSize);
      while ChunkSize > 0 do
      begin
        xmlParseChunk(ctxt, @Chunk, ChunkSize, 0);
        ChunkSize := FileRead(Handle, Chunk, BufferSize);
      end;
      xmlParseChunk(ctxt, nil, 0, 1);

      Result := xmlCtxtGetStatus(ctxt) = 0;
    finally
      xmlFreeParserCtxt(Ctxt);
      Ctxt := nil;
    end;
  finally
    FileClose(Handle);
  end;
end;

procedure TLX2SAXParserWrapper.PrepareContext;
begin
  xmlCtxtSetErrorHandler(Ctxt, StructuredErrorCallback, Self);
  xmlCtxtSetOptions(Ctxt, XmlParserOptions(Options));
end;

procedure TLX2SAXParserWrapper.Stop;
begin
  xmlStopParser(ctxt);
end;

procedure TLX2SAXParserWrapper.StructuredError(const error: xmlErrorPtr);
begin

end;

procedure TLX2SAXParserWrapper.AttributeDecl(const elem, fullname: xmlCharPtr; attrType, def: Integer; defaultValue: xmlCharPtr; tree: xmlEnumerationPtr);
begin

end;

procedure TLX2SAXParserWrapper.CDataBlock(const value: xmlCharPtr; len: Integer);
begin

end;

procedure TLX2SAXParserWrapper.Characters(const ch: xmlCharPtr; len: Integer);
begin

end;

procedure TLX2SAXParserWrapper.Comment(const value: xmlCharPtr);
begin

end;

procedure TLX2SAXParserWrapper.ElementDecl(const name: xmlCharPtr; elemType: Integer; content: xmlElementContentPtr);
begin

end;

procedure TLX2SAXParserWrapper.EndDocument;
begin

end;

procedure TLX2SAXParserWrapper.EndElement(const localname, prefix, URI: xmlCharPtr);
begin

end;

procedure TLX2SAXParserWrapper.EntityDecl(const name: xmlCharPtr; entType: Integer; publicId, systemId, content: xmlCharPtr);
begin

end;

procedure TLX2SAXParserWrapper.ExternalSubset(const name, ExternalID, SystemID: xmlCharPtr);
begin

end;

function TLX2SAXParserWrapper.GetEntity(const name: xmlCharPtr): xmlEntityPtr;
begin
  Result := xmlSAX2GetEntity(Ctxt, name);
end;

function TLX2SAXParserWrapper.GetParameterEntity(const name: xmlCharPtr): xmlEntityPtr;
begin
  Result := xmlSAX2GetParameterEntity(Ctxt, name);
end;

function TLX2SAXParserWrapper.HasExternalSubset: Boolean;
begin
  Result := xmlSAX2HasExternalSubset(Ctxt) = 1;
end;

function TLX2SAXParserWrapper.HasInternalSubset: Boolean;
begin
  Result := xmlSAX2HasInternalSubset(Ctxt) = 1;
end;

procedure TLX2SAXParserWrapper.IgnorableWhitespace(const ch: xmlCharPtr; len: Integer);
begin

end;

procedure TLX2SAXParserWrapper.InternalSubset(const name, ExternalID, SystemID: xmlCharPtr);
begin

end;

procedure TLX2SAXParserWrapper.NotationDecl(const name, publicId, systemId: xmlCharPtr);
begin

end;

procedure TLX2SAXParserWrapper.ProcessingInstruction(const target, data: xmlCharPtr);
begin

end;

procedure TLX2SAXParserWrapper.Reference(const name: xmlCharPtr);
begin

end;

function TLX2SAXParserWrapper.ResolveEntity(const publicId, systemId: xmlCharPtr): xmlParserInputPtr;
begin
  Result := xmlSAX2ResolveEntity(Ctxt, publicId, systemId);
end;

procedure TLX2SAXParserWrapper.SetDocumentLocator(loc: xmlSAXLocatorPtr);
begin

end;

procedure TLX2SAXParserWrapper.StartDocument;
begin

end;

procedure TLX2SAXParserWrapper.StartElement(const localname, prefix, URI: xmlCharPtr; nb_namespaces: Integer; namespaces: xmlSAX2NsPtr; nb_attributes, nb_defaulted: Integer; attributes: xmlSAX2AttrPtr);
begin

end;

procedure TLX2SAXParserWrapper.UnparsedEntityDecl(const name, publicId, systemId, notationName: xmlCharPtr);
begin

end;

{ TSAXCustomParser }

constructor TSAXCustomParser.Create;
begin
  inherited Create;
  FErrors := TXMLParseErrors.Create;
  FLocator := TSAXLocator.Create;
  FLocator.Parser := Self;
end;

destructor TSAXCustomParser.Destroy;
begin
  FreeAndNil(FErrors);
  FreeAndNil(FLocator);
  inherited;
end;

procedure TSAXCustomParser.DoCharacters(const Chars: string);
begin

end;

procedure TSAXCustomParser.DoEndDocument;
begin

end;

procedure TSAXCustomParser.DoEndElement(const LocalName, Prefix, URI: string);
begin

end;

procedure TSAXCustomParser.DoIgnorableWhitespace(const Chars: string);
begin

end;

procedure TSAXCustomParser.DoProcessingInstruction(const Target, Data: string);
begin

end;

procedure TSAXCustomParser.DoStartDocument;
begin

end;

procedure TSAXCustomParser.DoStartElement(const LocalName, Prefix, URI: string; const Namespaces: TSAXNamespaces; const Attributes: TSAXAttributes);
begin

end;

procedure TSAXCustomParser.PrepareContext;
begin
  inherited;
  FErrors.Clear;
end;

function TSAXCustomParser.GetLocator: ISAXLocator;
begin
  Result := FLocator;
end;

procedure TSAXCustomParser.StartDocument;
begin
  DoStartDocument;
end;

procedure TSAXCustomParser.EndDocument;
begin
  DoEndDocument;
end;

procedure TSAXCustomParser.StartElement(const localname, prefix, URI: xmlCharPtr; nb_namespaces: Integer; namespaces: xmlSAX2NsPtr; nb_attributes, nb_defaulted: Integer; attributes: xmlSAX2AttrPtr);
var
  AttrList: TSAXAttributes;
  NsList: TSAXNamespaces;
begin
  if attributes <> nil then
  begin
    SetLength(AttrList, nb_attributes);

    var Attr := attributes;
    for var I := 0 to nb_attributes - 1 do
    begin
      AttrList[I].Name := xmlCharToStr(Attr.localname);
      AttrList[I].Prefix := xmlCharToStr(Attr.prefix);
      AttrList[I].URI := xmlCharToStr(Attr.URI);
      AttrList[I].Defaulted := I >= (nb_attributes - nb_defaulted);
      AttrList[I].Value := xmlCharToStr(Attr.value, NativeUInt(Attr.valueEnd - Attr.value));
      Inc(Attr);
    end;
  end;

  if namespaces <> nil then
  begin
    SetLength(NsList, nb_namespaces);
    var Ns := namespaces;
    for var I := 0 to nb_namespaces - 1 do
    begin
      NsList[I].Prefix := xmlCharToStr(Ns.prefix);
      NsList[I].URI := xmlCharToStr(Ns.URI);

      Inc(Ns);
    end;
  end;

  DoStartElement(xmlCharToStr(localname), xmlCharToStr(prefix), xmlCharToStr(URI), NsList, AttrList);
end;

procedure TSAXCustomParser.EndElement(const localname, prefix, URI: xmlCharPtr);
begin
  DoEndElement(xmlCharToStr(localname), xmlCharToStr(prefix), xmlCharToStr(URI));
end;

procedure TSAXCustomParser.Characters(const ch: xmlCharPtr; len: Integer);
begin
  if not PreserveWhitespaces then
  begin
    while len > 0 do
      if ch[len - 1] = #32 then
        Dec(Len)
      else
        Break;

    if (len > 0) and (ch[len - 1] = #10) then
      Dec(len);
  end;

  if len > 0 then
    DoCharacters(xmlCharToStr(ch, len));
end;

procedure TSAXCustomParser.IgnorableWhitespace(const ch: xmlCharPtr; len: Integer);
begin
  DoIgnorableWhitespace(xmlCharToStr(ch, len));
end;

procedure TSAXCustomParser.ProcessingInstruction(const target, data: xmlCharPtr);
begin
  DoProcessingInstruction(xmlCharToStr(target), xmlCharToStr(data));
end;

procedure TSAXCustomParser.SetDocumentLocator(loc: xmlSAXLocatorPtr);
begin
  FLocator.Loc := loc;
end;

procedure TSAXCustomParser.StructuredError(const error: xmlErrorPtr);
begin
  FErrors.Add(error^);
end;

{ TSAXParser }

procedure TSAXParser.DoCharacters(const Chars: string);
begin
  Handler.Characters(Chars);
end;

procedure TSAXParser.DoEndDocument;
begin
  Handler.EndDocument;
end;

procedure TSAXParser.DoEndElement(const LocalName, Prefix, URI: string);
begin
  Handler.EndElement(LocalName, Prefix, URI)
end;

procedure TSAXParser.DoIgnorableWhitespace(const Chars: string);
begin
  Handler.IgnorableWhitespace(Chars);
end;

procedure TSAXParser.DoProcessingInstruction(const Target, Data: string);
begin
  Handler.ProcessingInstruction(Target, Data);
end;

procedure TSAXParser.DoStartDocument;
begin
  Handler.StartDocument;
end;

procedure TSAXParser.DoStartElement(const LocalName, Prefix, URI: string; const Namespaces: TSAXNamespaces; const Attributes: TSAXAttributes);
begin
  Handler.StartElement(LocalName, Prefix, URI, Namespaces, Attributes);
end;

{ TSAXLocator }

function TSAXLocator.GetColumnNumber: Integer;
begin
  Result := loc.getColumnNumber(Parser.Ctxt);
end;

function TSAXLocator.GetLineNumber: Integer;
begin
  Result := loc.getLineNumber(Parser.Ctxt);
end;

function TSAXLocator.GetPublicId: string;
begin
  Result := xmlCharToStr(loc.getPublicId(Parser.Ctxt));
end;

function TSAXLocator.GetSystemId: string;
begin
  Result := xmlCharToStr(loc.getSystemId(Parser.Ctxt));
end;

{ TSAXCustomContentHandler }

procedure TSAXCustomContentHandler.Characters(const Chars: string);
begin

end;

procedure TSAXCustomContentHandler.EndDocument;
begin

end;

procedure TSAXCustomContentHandler.EndElement(const LocalName, Prefix, URI: string);
begin

end;

procedure TSAXCustomContentHandler.IgnorableWhitespace(const Chars: string);
begin

end;

procedure TSAXCustomContentHandler.ProcessingInstruction(const Target, Data: string);
begin

end;

procedure TSAXCustomContentHandler.PutDocumentLocator(const Locator: ISAXLocator);
begin

end;

procedure TSAXCustomContentHandler.StartDocument;
begin

end;

procedure TSAXCustomContentHandler.StartElement(const LocalName, Prefix, URI: string; const Namespaces: TSAXNamespaces; const Attributes: TSAXAttributes);
begin

end;

end.
