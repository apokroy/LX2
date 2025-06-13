unit LX2.DOM.Classes;

interface

uses
  System.Types, System.SysUtils, System.Classes,
  libxml2.API, LX2.Types, LX2.Helpers, LX2.DOM;

type
  TXMLDocument = class;
  TXMLNode = class;

  TXMLError = class(TInterfacedObject, IXMLParseError)
  private
    FError: TXmlParseError;
  protected
    function  Get_ErrorCode: Integer;
    function  Get_Url: string;
    function  Get_Reason: string;
    function  Get_SrcText: string;
    function  Get_Line: Integer;
    function  Get_LinePos: Integer;
    function  Get_FilePos: Integer;
    function  Get_Level: xmlErrorLevel;
  public
    constructor Create; overload;
    constructor Create(const Error: TXmlParseError); overload;
    property  ErrorCode: Integer read Get_errorCode;
    property  Url: string read Get_url;
    property  Reason: string read Get_reason;
    property  SrcText: string read Get_srcText;
    property  Line: Integer read Get_line;
    property  LinePos: Integer read Get_linepos;
    property  FilePos: Integer read Get_filepos;
  end;

  TXMLErrors = class(TNoRefCountObject, IXMLErrors)
  private type
    TEnumerator = class(TInterfacedObject, IXMLErrorEnumerator)
    private
      FOwner: TXMLErrors;
      FIndex: NativeInt;
    public
      constructor Create(Owner: TXMLErrors);
      function GetCurrent: IXMLParseError;
      function MoveNext: Boolean;
    end;
  private
    FList: TInterfaceList;
    FIndex: NativeInt;
  protected
    function  Get_Count: NativeUInt; inline;
    function  Get_Item(Index: NativeUInt): IXMLParseError; inline;
    function  Get__newEnum: IXMLErrorEnumerator;
    function  Get_next: IXMLParseError;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Reset;
    function  MainError: IXMLParseError;
    function  GetEnumerator: IXMLErrorEnumerator;
    property  Count: NativeUInt read Get_Count;
    property  Items[Index: NativeUInt]: IXMLParseError read Get_Item; default;
  end;

  TXSLTError = class(TInterfacedObject, IXSLTError)
  private
    FReason: string;
  protected
    function  Get_Reason: string;
  public
    constructor Create(const Reason: string);
    property  Reason: string read FReason;
  end;

  TXSLTErrors = class(TNoRefCountObject, IXSLTErrors)
  private type
    TEnumerator = class(TInterfacedObject, IXSLTErrorEnumerator)
    private
      FOwner: TXSLTErrors;
      FIndex: NativeInt;
    public
      constructor Create(Owner: TXSLTErrors);
      function GetCurrent: IXSLTError;
      function MoveNext: Boolean;
    end;
  private
    FList: TInterfaceList;
  protected
    function  Get_Count: NativeUInt; inline;
    function  Get_Item(Index: NativeUInt): IXSLTError; inline;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function  GetEnumerator: IXSLTErrorEnumerator;
    property  Count: NativeUInt read Get_Count;
    property  Items[Index: NativeUInt]: IXSLTError read Get_Item; default;
  end;

  TXMLNodeEnumerator = class(TInterfacedObject, IXMLEnumerator)
  private
  protected
    function  DoGetCurrent: xmlNodePtr; virtual; abstract;
    function  DoMoveNext: Boolean; virtual; abstract;
    function  Predicate(Node: xmlNodePtr): Boolean; virtual;
    { IEnumerator }
    function  GetCurrent: IXMLNode;
  public
    procedure Reset; virtual; abstract;
    property  Current: IXMLNode read GetCurrent;
    function  MoveNext: Boolean;
  end;

  TXMLCustomNodeList = class(TInterfacedObject, IXMLNodeList)
  protected
    function  DoNextNode: xmlNodePtr; virtual; abstract;
    function  CreateEnumerator: TXMLNodeEnumerator; virtual; abstract;
     { MSXMLDOMNodeList }
    function  Get_Item(Index: NativeInt): IXMLNode; virtual; abstract;
    function  Get_Length: NativeInt; virtual; abstract;
    function  NextNode: IXMLNode;
    procedure Reset; virtual; abstract;
    property  Items[Index: NativeInt]: IXMLNode read Get_Item; default;
    property  Length: NativeInt read Get_Length;
    { Delphi enumerable }
    function  GetEnumerator: IXMLEnumerator;
    function  ToArray: TArray<IXMLNode>; virtual;
  end;

  TXMLNodeChildEnumerator = class(TXMLNodeEnumerator, IXMLEnumerator)
  private
    FNode: xmlNodePtr;
    FCurrent: xmlNodePtr;
    FIsFirst: Boolean;
  protected
    function  DoGetCurrent: xmlNodePtr; override;
    function  DoMoveNext: Boolean; override;
  public
    constructor Create(Node: xmlNodePtr);
    procedure Reset; override;
  end;

  TXMLNodeList = class(TXMLCustomNodeList, IXMLNodeList)
  private
    FNode: xmlNodePtr;
    FEnum: TXMLNodeChildEnumerator;
  protected
    function  DoNextNode: xmlNodePtr; override;
    function  CreateEnumerator: TXMLNodeEnumerator; override;
    property  Node: xmlNodePtr read FNode;
  public
    constructor Create(Node: xmlNodePtr);
    destructor Destroy; override;
    { MSXMLDOMNodeList }
    function  Get_Item(index: NativeInt): IXMLNode; override;
    function  Get_Length: NativeInt; override;
    procedure Reset; override;
  end;

  TXPathEnumerator = class(TXMLNodeEnumerator, IXMLEnumerator)
  private
    FObj: xmlXPathObjectPtr;
    FIndex: NativeInt;
  protected
    function  DoGetCurrent: xmlNodePtr; override;
    function  DoMoveNext: Boolean; override;
  public
    constructor Create(Obj: xmlXPathObjectPtr);
    procedure Reset; override;
  end;

  TXPathList = class(TXMLCustomNodeList, IXMLNodeList)
  private
    FObj: xmlXPathObjectPtr;
    FIndex: NativeInt;
  protected
    function  DoNextNode: xmlNodePtr; override;
    function  CreateEnumerator: TXMLNodeEnumerator; override;
  public
    constructor Create(Obj: xmlXPathObjectPtr);
    destructor Destroy; override;
    { MSXMLDOMNodeList }
    function  Get_Item(Index: NativeInt): IXMLNode; override;
    function  Get_Length: NativeInt; override;
    procedure Reset; override;
    { Delphi enumerable }
    function  ToArray: TArray<IXMLNode>; override;
  end;

  TXMLCustomNamedNodeMap = class(TXMLCustomNodeList, IXMLNamedNodeMap)
  protected
    function  FindItem(const Name: string): xmlNodePtr; virtual; abstract;
    function  FindQualifiedItem(const BaseName: string; const NamespaceURI: string): xmlNodePtr; virtual; abstract;
    procedure RemoveNode(Node: xmlNodePtr); virtual;
    procedure InsertNode(NewNode, AfterNode: xmlNodePtr); virtual; abstract;
  public
    { IXMLNamedNodeMap }
    function  GetNamedItem(const Name: string): IXMLNode;
    function  SetNamedItem(const NewItem: IXMLNode): IXMLNode;
    function  RemoveNamedItem(const Name: string): IXMLNode;
    function  GetQualifiedItem(const BaseName: string; const namespaceURI: string): IXMLNode;
    function  RemoveQualifiedItem(const BaseName: string; const namespaceURI: string): IXMLNode;
  end;

  TXMLNodeNamedNodeMap = class(TXMLCustomNamedNodeMap)
  private
    FParent: xmlNodePtr;
  protected
    procedure InsertNode(NewNode, AfterNode: xmlNodePtr); override;
  public
    constructor Create(const Parent: xmlNodePtr);
    property  Parent: xmlNodePtr read FParent;
  end;

  TXMLAttributes = class(TXMLNodeNamedNodeMap, IXMLAttributes)
  private type
    TEnumerator = class(TXMLNodeEnumerator, IXMLAttributesEnumerator)
    private
      FParent: xmlNodePtr;
      FCurrent: xmlAttrPtr;
      FIsFirst: Boolean;
    protected
      function  DoGetCurrent: xmlNodePtr; override;
      function  DoMoveNext: Boolean; override;
    public
      constructor Create(Parent: xmlNodePtr);
      function  GetCurrent: IXMLAttribute;
      procedure Reset; override;
    end;
  private
    FEnum: TEnumerator;
  protected
    function  DoNextNode: xmlNodePtr; override;
    function  CreateEnumerator: TXMLNodeEnumerator; override;
    function  Get_Attr(Index: NativeInt): IXmlAttribute;
    function  Get_Item(Index: NativeInt): IXMLNode; override;
    function  Get_Length: NativeInt; override;
    function  FindItem(const Name: string): xmlNodePtr; override;
    function  FindQualifiedItem(const BaseName: string; const NamespaceURI: string): xmlNodePtr; override;
  public
    constructor Create(const Parent: xmlNodePtr);
    destructor Destroy; override;
    procedure Reset; override;
    { IXMLAttributes }
    function  NextNode: IXMLAttribute;
    property  Item[index: NativeInt]: IXmlAttribute read Get_Attr; default;
    { Delphi enumerable }
    function  GetEnumerator: IXMLAttributesEnumerator;
    function  ToArray: TArray<IXmlAttribute>; reintroduce; overload;
  end;

  TXMLElementList = class(TXMLNodeNamedNodeMap)
  private type
    TMoveNext = function: Boolean of object;

    TEnumerator = class(TXMLNodeEnumerator)
    private
      FList: TXMLElementList;
      FCurrent: xmlNodePtr;
      FIsFirst: Boolean;
      FMask: Utf8String;
      FDoMoveNext: TMoveNext;
      function  DoNextSibling: Boolean;
      function  DoNextSiblingWithMask: Boolean;
      function  DoNextRecursive: Boolean;
      function  DoNextRecursiveWithMask: Boolean;
    protected
      function  DoGetCurrent: xmlNodePtr; override;
      function  DoMoveNext: Boolean; override;
    public
      constructor Create(List: TXMLElementList);
      procedure Reset; override;
    end;
  private
    FRecursive: Boolean;
    FMask: string;
    FUseMask: Boolean;
    FEnum: TEnumerator;
  protected
    function  DoNextNode: xmlNodePtr; override;
    function  CreateEnumerator: TXMLNodeEnumerator; override;
    function  Get_Item(Index: NativeInt): IXMLNode; override;
    function  Get_Length: NativeInt; override;
    function  FindItem(const Name: string): xmlNodePtr; override;
    function  FindQualifiedItem(const BaseName: string; const NamespaceURI: string): xmlNodePtr; override;
    property  UseMask: Boolean read FUseMask;
  public
    constructor Create(Parent: xmlNodePtr; Recursive: Boolean; Mask: string = '*');
    destructor Destroy; override;
    procedure Reset; override;
    property  Recursive: Boolean read FRecursive;
    property  Mask: string read FMask;
  end;

  TXMLNode = class(TInterfacedObject, IXMLNode)
  private
    procedure XPathErrorHandler(const error: xmlError);
  protected
    { IXMLNode }
    function  AppendChild(const NewChild: IXMLNode): IXMLNode;
    function  CloneNode(Deep: WordBool): IXMLNode;
    function  Get_Attributes: IXMLAttributes;
    function  Get_BaseName: string;
    function  Get_ChildNodes: IXMLNodeList;
    function  Get_FirstChild: IXMLNode;
    function  Get_LastChild: IXMLNode;
    function  Get_NamespaceURI: string;
    function  Get_NextSibling: IXMLNode;
    function  Get_NodeName: string;
    function  Get_NodeType: DOMNodeType;
    function  Get_NodeValue: string;
    function  Get_OwnerDocument: IXMLDocument;
    function  Get_ParentNode: IXMLNode;
    function  Get_Prefix: string;
    function  Get_PreviousSibling: IXMLNode;
    function  Get_Text: string;
    function  Get_Xml: string;
    function  HasChildNodes: Boolean;
    function  InsertBefore(const NewChild: IXMLNode; RefChild: IXMLNode): IXMLNode;
    function  RemoveChild(const ChildNode: IXMLNode): IXMLNode;
    function  ReplaceChild(const NewChild: IXMLNode; const OldChild: IXMLNode): IXMLNode;
    function  SelectNodes(const QueryString: string): IXMLNodeList;
    function  SelectSingleNode(const QueryString: string): IXMLNode;
    procedure Set_NodeValue(const Value: string);
    procedure Set_Text(const Text: string);
  protected
    NodePtr: xmlNodePtr;
    constructor Create(node: xmlNodePtr);
  public
    destructor Destroy; override;
    procedure ReconciliateNs; virtual;
    property  NodeName: string read Get_NodeName;
    property  NodeValue: string read Get_NodeValue write Set_NodeValue;
    property  NodeType: DOMNodeType read Get_NodeType;
    property  ParentNode: IXMLNode read Get_ParentNode;
    property  ChildNodes: IXMLNodeList read Get_ChildNodes;
    property  FirstChild: IXMLNode read Get_FirstChild;
    property  LastChild: IXMLNode read Get_LastChild;
    property  PreviousSibling: IXMLNode read Get_PreviousSibling;
    property  NextSibling: IXMLNode read Get_NextSibling;
    property  Attributes: IXMLAttributes read Get_Attributes;
    property  OwnerDocument: IXMLDocument read Get_OwnerDocument;
    property  Text: string read Get_Text write Set_Text;
    property  Xml: string read Get_Xml;
    property  NamespaceURI: string read Get_namespaceURI;
    property  Prefix: string read Get_prefix;
    property  BaseName: string read Get_baseName;
  end;

  TXMLAttribute = class(TXMLNode, IXMLAttribute)
  private
    function  GetAttrPtr: xmlAttrPtr; inline;
  protected
    constructor Create(AttrPtr: xmlAttrPtr);
    property  AttrPtr: xmlAttrPtr read GetAttrPtr;
  protected
    function  Get_Name: string;
    function  Get_Value: string;
    procedure Set_Value(const attrValue: string);
    property  Name: string read Get_Name;
    property  Value: string read Get_Value write Set_value;
  public
    destructor Destroy; override;
  end;

  TXMLElement = class(TXMLNode, IXMLElement)
  public
    function  GetAttribute(const Name: string): string;
    procedure SetAttribute(const Name: string; Value: string);
    function  GetAttributeNs(const NamespaceURI, Name: string): string;
    function  SetAttributeNs(const NamespaceURI, Name: string; const Value: string): IXMLAttribute;
    function  GetAttributeNode(const Name: string): IXMLAttribute;
    function  GetAttributeNodeNs(const NamespaceURI, Name: string): IXMLAttribute;
    function  HasAttribute(const Name: string): Boolean;
    function  HasAttributeNs(const NamespaceURI, Name: string): Boolean;
    function  AddChild(const Name: string; const Content: string = ''): IXMLElement;
    function  AddChildNs(const Name, NamespaceURI: string; const Content: string = ''): IXMLElement;
    function  RemoveAttribute(const Name: string): Boolean;
    function  RemoveAttributeNs(const NamespaceURI, Name: string): Boolean;
    function  RemoveAttributeNode(const Attribute: IXMLAttribute): IXMLAttribute;
    function  GetElementsByTagName(const TagName: string): IXMLNodeList;
    function  Get_TagName: string;
    procedure Normalize;
    property  TagName: string read Get_TagName;
  end;

  TXMLCharacterData = class(TXMLNode, IXMLCharacterData)
  public
    function  Get_data: string;
    procedure Set_data(const data: string);
    function  Get_length: NativeInt;
    function  SubstringData(offset: Integer; count: Integer): string;
    procedure AppendData(const data: string);
    procedure InsertData(offset: Integer; const data: string);
    procedure DeleteData(offset: Integer; count: Integer);
    procedure ReplaceData(offset: Integer; count: Integer; const data: string);
    property  Data: string read Get_data write Set_data;
    property  Length: NativeInt read Get_length;
  end;

  TXMLText = class(TXMLCharacterData, IXMLText)
  end;

  TXMLCDATA = class(TXMLCharacterData, IXMLCDATASection)
  end;

  TXMLComment = class(TXMLCharacterData, IXMLComment)
  end;

  TXMLEntityRef = class(TXMLNode, IXMLEntityReference)

  end;

  TXMLDocType = class(TXMLNode, IXMLDocumentType)
  end;

  TXMLProcessingInstruction = class(TXMLNode, IXMLProcessingInstruction)
  public
    function  Get_Target: string;
    function  Get_Data: string;
    procedure Set_Data(const Value: string);
    property  Target: string read Get_Target;
    property  Data: string read Get_Data write Set_Data;
  end;

  TXMLDocumentFragment = class(TXMLNode, IXMLDocumentFragment)

  end;

  TXMLSchemaCollection = class(TInterfacedObject, IXMLSchemaCollection)
  private const
    cImport: UTF8String = 'import';
    cSchemaNs: UTF8String = 'http://www.w3.org/2001/XMLSchema';
  private type
    PSchema = ^TSchema;
    TSchema = record
      NamespaceURI: string;
      Doc: IXMLDocument;
      Imports: TArray<NativeInt>;
      Parents: TArray<NativeInt>;
    end;
  private
    FList: TArray<TSchema>;
    FRoots: TArray<IXMLDocument>;
    FErrors: TXMLErrors;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Parse;
    function  Validate(const Doc: IXMLDocument): Boolean;
    function  IndexOf(const NamespaceURI: string): NativeInt;
    procedure Add(const NamespaceURI: string; Doc: IXMLDocument);
    procedure Remove(const NamespaceURI: string);
    function  Get_Length: NativeInt;
    function  Get_NamespaceURI(index: NativeInt): string;
    function  GetSchema(const NamespaceURI: string): IXMLDocument;
    property  Errors: TXMLErrors read FErrors;
    property  Length: NativeInt read Get_Length;
    property  NamespaceURI[index: NativeInt]: string read Get_NamespaceURI; default;
  end;

  TXMLDocument = class(TXMLNode, IXMLDocument)
  private
    FDocOwner: Boolean;
    FErrors: TXMLErrors;
    FXSLTErrors: TXSLTErrors;
    FValidateOnParse: Boolean;
    FResolveExternals: Boolean;
    FPreserveWhiteSpace: Boolean;
    FOptions: TXmlParserOptions;
    FSuccessError: IXMLParseError;
  protected
    procedure ErrorCallback(const error: xmlError); virtual;
    procedure XSLTError(const Msg: string); virtual;
    function  SetNewDoc(Doc: xmlDocPtr): xmlDocPtr;
    property  DocOwner: Boolean read FDocOwner;
  protected
    function  Clone(Recursive: Boolean = True): IXMLDocument;
    function  CreateAttribute(const name: string): IXMLAttribute;
    function  CreateCDATASection(const data: string): IXMLCDATASection;
    function  CreateChild(const Parent: IXMLElement; const Name: string; const NamespaceURI: string = ''; ResolveNamespace: Boolean = False; Content: string = ''): IXMLElement;
    function  CreateComment(const data: string): IXMLComment;
    function  CreateDocumentFragment: IXMLDocumentFragment;
    function  CreateElement(const TagName: string): IXMLElement;
    function  CreateElementNs(const NamespaceURI, Name: string): IXMLElement;
    function  CreateNode(NodeType: Integer; const name: string; const namespaceURI: string): IXMLNode;
    function  CreateProcessingInstruction(const target: string; const data: string): IXMLProcessingInstruction;
    function  CreateRoot(const RootName: string; const NamespaceURI: string = ''; Content: string = ''): IXMLElement;
    function  CreateTextNode(const data: string): IXMLText;
    function  Get_doctype: IXMLDocumentType;
    function  Get_documentElement: IXMLElement;
    function  Get_ParseError: IXMLParseError;
    function  Get_PreserveWhiteSpace: Boolean;
    function  Get_ReadyState: Integer;
    function  Get_ResolveExternals: Boolean;
    function  Get_Url: string;
    function  Get_ValidateOnParse: Boolean;
    function  GetElementsByTagName(const tagName: string): IXMLNodeList;
    function  GetErrors: IXMLErrors;
    function  GetXSLTErrors: IXSLTErrors;
    function  NodeFromID(const IdString: string): IXMLNode;
    procedure Normalize;
    procedure Save(const Url: string); overload;
    procedure Set_documentElement(const Element: IXMLElement);
    procedure Set_PreserveWhiteSpace(IsPreserving: Boolean);
    procedure Set_ResolveExternals(IsResolving: Boolean);
    procedure Set_ValidateOnParse(IsValidating: Boolean);
    function  Transform(const Stylesheet: IXMLDocument; out Doc: IXMLDocument): Boolean; overload;
    function  Transform(const Stylesheet: IXMLDocument; out S: RawByteString): Boolean; overload;
    function  Transform(const Stylesheet: IXMLDocument; out S: string): Boolean; overload;
    function  Validate: IXMLParseError;
    function  ValidateNode(const node: IXMLNode): IXMLParseError;
    property  Doctype: IXMLDocumentType read Get_Doctype;
    property  DocumentElement: IXMLElement read Get_DocumentElement write Set_DocumentElement;
    property  ReadyState: Integer read Get_ReadyState;
    property  ParseError: IXMLParseError read Get_ParseError;
    property  Url: string read Get_Url;
    property  ValidateOnParse: Boolean read Get_ValidateOnParse write Set_ValidateOnParse;
    property  ResolveExternals: Boolean read Get_ResolveExternals write Set_ResolveExternals;
    property  PreserveWhiteSpace: Boolean read Get_PreserveWhiteSpace write Set_PreserveWhiteSpace;
  public
    constructor Create; overload;
    constructor Create(doc: xmlDocPtr; DocOwner: Boolean); overload;
    destructor Destroy; override;

    function  LoadXML(const XML: RawByteString; const Options: TXmlParserOptions): Boolean; overload;
    function  LoadXML(const XML: string; const Options: TXmlParserOptions): Boolean; overload;
    function  Load(const Data: TBytes): Boolean; overload;
    function  Load(const Data: Pointer; Size: NativeUInt): Boolean; overload;
    function  Load(const URL: string): Boolean; overload;
    function  Load(Stream: TStream; const Encoding: Utf8String): Boolean; overload;

    function  Save(const FileName: string; const Encoding: string = 'UTF-8'; const Options: TxmlSaveOptions = []): Boolean; overload;
    function  Save(Stream: TStream; const Encoding: string = 'UTF-8'; const Options: TxmlSaveOptions = []): Boolean; overload;
    function  ToBytes(const Encoding: string = 'UTF-8'; const Format: Boolean = False): TBytes; overload;
    function  ToString(const Format: Boolean): string; reintroduce; overload;
    function  ToString: string; overload; override;
    function  ToUtf8(const Format: Boolean = False): RawByteString; overload;
    function  ToAnsi(const Encoding: string = 'windows-1251'; const Format: Boolean = False): RawByteString; overload;

    procedure ReconciliateNs; override;
    property  Errors: TXMLErrors read FErrors;
    property  XSLTErrors: IXSLTErrors read GetXSLTErrors;
    property  Options: TXmlParserOptions read FOptions write FOptions;
  end;

var
  DebugObjectCount: NativeInt = 0;

implementation

uses
  libxslt.API;

var
  GlobalLock: TObject;
  OldDeregisterNodeFunc: xmlDeregisterNodeFunc;

procedure NodeFreeCallback(Node: xmlNodePtr); cdecl;
begin
  if Node._private <> nil then
  begin
    TXMLNode(Node._private).NodePtr := nil;
  end;
end;

 procedure XSLTErrorHandler(Context: Pointer; const Msg: string);
 begin
   TXMLDocument(Context).XSLTError(Msg);
 end;

function Cast(const Node: xmlNodePtr): TXMLNode; overload;
begin
  if Node = nil then
    Exit(nil);

  if Node._private <> nil then
    Exit(TXMLNode(node._private));

  case Node.&type of
    XML_ELEMENT_NODE       : Result := TXMLElement.Create(Node);
    XML_ATTRIBUTE_NODE     : Result := TXMLAttribute.Create(xmlAttrPtr(Node));
    XML_TEXT_NODE          : Result := TXMLText.Create(Node);
    XML_CDATA_SECTION_NODE : Result := TXMLCDATA.Create(Node);
    XML_ENTITY_REF_NODE    : Result := TXMLEntityRef.Create(Node);
    XML_PI_NODE            : Result := TXMLProcessingInstruction.Create(Node);
    XML_COMMENT_NODE       : Result := TXMLComment.Create(Node);
    XML_DOCUMENT_FRAG_NODE : Result := TXMLDocumentFragment.Create(Node);
    XML_DTD_NODE           : Result := TXMLDocType.Create(Node);
  else
    Result := TXMLNode.Create(node);
  end;
end;

function Cast(const Attr: xmlAttrPtr): TXMLAttribute; overload;
begin
  if Attr = nil then
    Result := nil
  else if Attr._private = nil then
    Result := TXMLAttribute.Create(Attr)
  else
    Result := TXMLAttribute(Attr._private)

end;

{ TXMLNodeEnumerator }

function TXMLNodeEnumerator.GetCurrent: IXMLNode;
begin
  Result := Cast(DoGetCurrent);
end;

function TXMLNodeEnumerator.MoveNext: Boolean;
begin
  while True do
  begin
    Result := DoMoveNext;
    if Result and not Predicate(DoGetCurrent) then
      Continue
    else
      Break;
  end;
end;

function TXMLNodeEnumerator.Predicate(Node: xmlNodePtr): Boolean;
begin
  Result := True;
end;

{ TXMLCustomNodeList }

function TXMLCustomNodeList.GetEnumerator: IXMLEnumerator;
begin
  Result := CreateEnumerator;
end;

function TXMLCustomNodeList.NextNode: IXMLNode;
begin
  Result := Cast(DoNextNode);
end;

function TXMLCustomNodeList.ToArray: TArray<IXMLNode>;
var
  Capacity, Count: NativeInt;
begin
  Capacity := 16;
  Count := 0;

  SetLength(Result, Capacity);
  var Enum := CreateEnumerator;
  while Enum.MoveNext do
  begin
    if Count = Capacity then
    begin
      Inc(Capacity, Capacity shr 1);
      SetLength(Result, Capacity);
    end;
    Result[Count] := Enum.Current;
    Inc(Count);
  end;
  Enum.Free;
  SetLength(Result, Count);
end;

{ TXMLNodeChildEnumerator }

constructor TXMLNodeChildEnumerator.Create(Node: xmlNodePtr);
begin
  inherited Create;
  FNode := Node;
  FCurrent := nil;
  FIsFirst := True;
end;

function TXMLNodeChildEnumerator.DoGetCurrent: xmlNodePtr;
begin
  Result := FCurrent;
end;

function TXMLNodeChildEnumerator.DoMoveNext: Boolean;
begin
  if FIsFirst then
  begin
    FCurrent := FNode.children;
    FIsFirst := False;
  end
  else
    FCurrent := FCurrent.next;

  Result := FCurrent <> nil;
end;

procedure TXMLNodeChildEnumerator.Reset;
begin
  FIsFirst := True;
end;

{ TXMLNodeList }

constructor TXMLNodeList.Create(Node: xmlNodePtr);
begin
  inherited Create;
  FNode := Node;
  FEnum := TXMLNodeChildEnumerator.Create(Node);
end;

destructor TXMLNodeList.Destroy;
begin
  FreeAndNil(FEnum);
  inherited;
end;

function TXMLNodeList.CreateEnumerator: TXMLNodeEnumerator;
begin
  Result := TXMLNodeChildEnumerator.Create(Node);
end;

function TXMLNodeList.Get_Item(Index: NativeInt): IXMLNode;
begin
  var Current := Node.children;
  for var I := 0 to Index do
    if Current = nil then
      Exit(nil)
    else
      Current := Current.next;

  Result := Cast(Current);
end;

function TXMLNodeList.Get_Length: NativeInt;
begin
  Result := 0;
  var Current := Node.children;
  while Current <> nil do
  begin
    Inc(Result);
    Current := Current.next;
  end;
end;

function TXMLNodeList.DoNextNode: xmlNodePtr;
begin
  if FEnum.MoveNext then
    Result := FEnum.FCurrent
  else
    Result := nil;
end;

procedure TXMLNodeList.Reset;
begin
  FEnum.Reset;
end;

{ TXPathEnumerator }

constructor TXPathEnumerator.Create(Obj: xmlXPathObjectPtr);
begin
  inherited Create;
  FObj := Obj;
  FIndex := -1;
end;

function TXPathEnumerator.DoGetCurrent: xmlNodePtr;
begin
  Result := FObj.nodesetval.nodeTab[FIndex];
end;

function TXPathEnumerator.DoMoveNext: Boolean;
begin
  Inc(FIndex);
  Result := FIndex < FObj.nodesetval.nodeNr;
end;

procedure TXPathEnumerator.Reset;
begin
  FIndex := -1;
end;

{ TXPathList }

constructor TXPathList.Create(Obj: xmlXPathObjectPtr);
begin
  inherited Create;
  FObj := Obj;
  FIndex := -1;
end;

destructor TXPathList.Destroy;
begin
  xmlXPathFreeObject(FObj);
  inherited;
end;

function TXPathList.CreateEnumerator: TXMLNodeEnumerator;
begin
  Result := TXPathEnumerator.Create(FObj);
end;

function TXPathList.Get_Item(index: NativeInt): IXMLNode;
begin
  Result := Cast(FObj.nodesetval.nodeTab[Index]);
end;

function TXPathList.Get_Length: NativeInt;
begin
  Result := FObj.nodesetval.nodeNr;
end;

function TXPathList.DoNextNode: xmlNodePtr;
begin
  Inc(FIndex);
  if FIndex < FObj.nodesetval.nodeNr then
    Result := FObj.nodesetval.nodeTab[FIndex]
  else
    Result := nil;
end;

procedure TXPathList.Reset;
begin
  FIndex := -1;
end;

function TXPathList.ToArray: TArray<IXMLNode>;
begin
  SetLength(Result, FObj.nodesetval.nodeNr);
  for var I := 0 to FObj.nodesetval.nodeNr - 1 do
    Result[I] := Cast(FObj.nodesetval.nodeTab[I]);
end;

{ TXMLCustomNamedNodeMap }

function TXMLCustomNamedNodeMap.getNamedItem(const Name: string): IXMLNode;
begin
  Result := Cast(FindItem(Name));
end;

function TXMLCustomNamedNodeMap.getQualifiedItem(const BaseName, NamespaceURI: string): IXMLNode;
begin
  Result := Cast(FindQualifiedItem(BaseName, NamespaceURI));
end;

function TXMLCustomNamedNodeMap.removeNamedItem(const Name: string): IXMLNode;
begin
  var Node := FindItem(Name);
  if Node = nil then
    Exit(nil);

  RemoveNode(Node);
  Result := Cast(Node);
end;

procedure TXMLCustomNamedNodeMap.RemoveNode(Node: xmlNodePtr);
begin
  xmlUnlinkNode(Node);
end;

function TXMLCustomNamedNodeMap.removeQualifiedItem(const BaseName, NamespaceURI: string): IXMLNode;
begin
  var Node := FindQualifiedItem(BaseName, NamespaceURI);
  if Node = nil then
    Exit(nil);

  RemoveNode(Node);
  Result := Cast(Node);
end;

function TXMLCustomNamedNodeMap.setNamedItem(const NewItem: IXMLNode): IXMLNode;
begin
  if NewItem = nil then
    Exit(nil);

  Result := NewItem;

  var NewNode := TXmlNode(NewItem).NodePtr;

  // setNamedItem replaces existing node
  if NewNode.ns <> nil then
  begin
    var OldNode := FindQualifiedItem(xmlCharToStr(NewNode.name), xmlCharToStr(NewNode.ns.href));
    if OldNode <> nil then
     RemoveNode(OldNode);
  end
  else
  begin
    var OldNode := FindItem(xmlCharToStr(NewNode.name));
    if OldNode <> nil then
     RemoveNode(OldNode);
  end;

  // If has ns - insert before first node without xmlns
  if NewNode.ns <> nil then
  begin
    var Enum := CreateEnumerator;
    while Enum.MoveNext do
    begin
      var Current := Enum.DoGetCurrent;
      if Current.ns = nil then
      begin
        InsertNode(NewNode, Current);
        Exit;
      end;
    end;
  end;

  // Else, append last
  InsertNode(NewNode, nil);

  NewNode.ReconciliateNs;
end;

{ TXMLNodeNamedNodeMap }

constructor TXMLNodeNamedNodeMap.Create(const Parent: xmlNodePtr);
begin
  inherited Create;
  FParent := Parent;
end;

procedure TXMLNodeNamedNodeMap.InsertNode(NewNode, AfterNode: xmlNodePtr);
begin
  if AfterNode = nil then
    xmlAddChild(Parent, NewNode)
  else
    xmlAddNextSibling(NewNode, AfterNode);
end;

{ TXMLAttributes.TEnumerator }

constructor TXMLAttributes.TEnumerator.Create(Parent: xmlNodePtr);
begin
  inherited Create;
  FParent := Parent;
  FIsFirst := True;
end;

function TXMLAttributes.TEnumerator.GetCurrent: IXMLAttribute;
begin
  Result := Cast(FCurrent);
end;

function TXMLAttributes.TEnumerator.DoGetCurrent: xmlNodePtr;
begin
  Result := xmlNodePtr(FCurrent);
end;

function TXMLAttributes.TEnumerator.DoMoveNext: Boolean;
begin
  if FIsFirst then
  begin
    FCurrent := FParent.properties;
    FIsFirst := False;
  end
  else
    FCurrent := FCurrent.next;

  Result := FCurrent <> nil;
end;

procedure TXMLAttributes.TEnumerator.Reset;
begin
  FIsFirst := True;
end;

{ TXMLAttributes }

constructor TXMLAttributes.Create(const Parent: xmlNodePtr);
begin
  inherited Create(Parent);
  FEnum := TEnumerator.Create(Parent);
end;

destructor TXMLAttributes.Destroy;
begin
  FreeAndNil(FEnum);
  inherited;
end;

function TXMLAttributes.CreateEnumerator: TXMLNodeEnumerator;
begin
  Result := TXMLAttributes.TEnumerator.Create(Parent);
end;

function TXMLAttributes.DoNextNode: xmlNodePtr;
begin
  if FEnum.MoveNext then
    Result := xmlNodePtr(FEnum.FCurrent)
  else
    Result := nil;
end;

function TXMLAttributes.FindItem(const Name: string): xmlNodePtr;
var
  Prefix, LocalName: RawByteString;
begin
  if SplitXMLName(UTF8Encode(Name), Prefix, LocalName) then
  begin
    var Attr := Parent.properties;
    while Attr <> nil do
    begin
      if (Attr.ns <> nil) and xmlStrSame(Attr.ns.prefix, Pointer(Prefix)) and xmlStrSame(Attr.Name, Pointer(LocalName)) then
        Exit(xmlNodePtr(Attr));
      Attr := Attr.next;
    end;
  end
  else
  begin
    var Attr := Parent.properties;
    while Attr <> nil do
    begin
      if xmlStrSame(Attr.Name, Pointer(LocalName)) then
        Exit(xmlNodePtr(Attr));
      Attr := Attr.next;
    end;
  end;
  Result := nil;
end;

function TXMLAttributes.FindQualifiedItem(const BaseName, NamespaceURI: string): xmlNodePtr;
var
  Name, URI: RawByteString;
begin
  URI := Utf8Encode(NamespaceURI);
  Name := Utf8Encode(BaseName);
  var Attr := Parent.properties;
  while Attr <> nil do
  begin
    if (Attr.ns <> nil) and xmlStrSame(Attr.ns.href, Pointer(URI)) and xmlStrSame(Attr.Name, Pointer(Name)) then
      Exit(xmlNodePtr(Attr));
    Attr := Attr.next;
  end;
  Result := nil;
end;

function TXMLAttributes.GetEnumerator: IXMLAttributesEnumerator;
begin
  Result := TEnumerator.Create(Parent);
end;

function TXMLAttributes.Get_Item(Index: NativeInt): IXmlNode;
begin
  Result := Get_Attr(Index);
end;

function TXMLAttributes.Get_Length: NativeInt;
begin
  Result := 0;
  var Attr := Parent.properties;
  while Attr <> nil do
  begin
    Inc(Result);
    Attr := Attr.next;
  end;
end;

function TXMLAttributes.Get_Attr(Index: NativeInt): IXmlAttribute;
begin
  var Attr := Parent.properties;
  for var I := 0 to Index do
  begin
    if Attr = nil then
      Exit(nil);

    if I = Index then
      Exit(Cast(Attr))
    else
      Attr := Attr.next;
  end;
end;

function TXMLAttributes.NextNode: IXMLAttribute;
begin
  Result := Cast(xmlAttrPtr(DoNextNode));
end;

procedure TXMLAttributes.Reset;
begin
  FEnum.Reset;
end;

function TXMLAttributes.ToArray: TArray<IXmlAttribute>;
var
  Capacity, Count: NativeInt;
begin
  if Parent.properties = nil then
    Exit(nil);

  Capacity := 16;
  Count := 0;

  SetLength(Result, Capacity);
  var Attr := Parent.properties;
  while Attr <> nil do
  begin
    if Count = Capacity then
    begin
      Inc(Capacity, Capacity shr 1);
      SetLength(Result, Capacity);
    end;
    Result[Count] := Cast(Attr);
    Inc(Count);

    Attr := Attr.next;
  end;
  SetLength(Result, Count);
end;

{ TXMLElementList.TEnumerator }

constructor TXMLElementList.TEnumerator.Create(List: TXMLElementList);
begin
  inherited Create;
  FList := List;
  FIsFirst := True;
  FMask := Utf8Encode(List.Mask);
  if List.Recursive then
  begin
    if List.UseMask then
      FDoMoveNext := DoNextRecursiveWithMask
    else
      FDoMoveNext := DoNextRecursive
  end
  else if List.UseMask then
    FDoMoveNext := DoNextSiblingWithMask
  else
    FDoMoveNext := DoNextSibling;
end;

function TXMLElementList.TEnumerator.DoGetCurrent: xmlNodePtr;
begin
  Result := FCurrent;
end;

function TXMLElementList.TEnumerator.DoMoveNext: Boolean;
begin
  Result := FDoMoveNext;
end;

procedure TXMLElementList.TEnumerator.Reset;
begin
  FIsFirst := True;
end;

function TXMLElementList.TEnumerator.DoNextRecursive: Boolean;
begin
  if FIsFirst then
  begin
    FCurrent := FList.Parent.children;
    FIsFirst := False;
  end
  else
    FCurrent := FCurrent.GetNext(FList.Parent);

  while FCurrent <> nil do
  begin
    if FCurrent.&type = XML_ELEMENT_NODE then
      Break;
    FCurrent := FCurrent.GetNext(FList.Parent);
  end;

  Result := FCurrent <>  nil;
end;

function TXMLElementList.TEnumerator.DoNextRecursiveWithMask: Boolean;
begin
  if FIsFirst then
  begin
    FCurrent := FList.Parent.children;
    FIsFirst := False;
  end
  else
    FCurrent := FCurrent.GetNext(FList.Parent);

  while FCurrent <> nil do
  begin
    if (FCurrent.&type = XML_ELEMENT_NODE) and (FCurrent.TagName = FMask) then
      Break;

    FCurrent := FCurrent.GetNext(FList.Parent);
  end;
  Result := FCurrent <>  nil;
end;

function TXMLElementList.TEnumerator.DoNextSibling: Boolean;
begin
  if FIsFirst then
  begin
    FCurrent := FList.Parent.children;
    FIsFirst := False;
  end
  else
    FCurrent := FCurrent.next;

  while FCurrent <> nil do
  begin
    if FCurrent.&type = XML_ELEMENT_NODE then
      Break;
    FCurrent := FCurrent.next;
  end;

  Result := FCurrent <>  nil;
end;

function TXMLElementList.TEnumerator.DoNextSiblingWithMask: Boolean;
begin
  if FIsFirst then
  begin
    FCurrent := FList.Parent.children;
    FIsFirst := False;
  end
  else
    FCurrent := FCurrent.next;

  while FCurrent <> nil do
  begin
    if (FCurrent.&type = XML_ELEMENT_NODE) and (FCurrent.TagName = FMask) then
      Break;
    FCurrent := FCurrent.next;
  end;

  Result := FCurrent <>  nil;
end;

{ TXMLElementList }

constructor TXMLElementList.Create(Parent: xmlNodePtr; Recursive: Boolean; Mask: string);
begin
  inherited Create(Parent);
  FRecursive := Recursive;
  FMask := Mask;
  FUseMask := not ((Mask = '*') or (Mask = ''));
  FEnum := TEnumerator.Create(Self);
  {$IFDEF DEBUG}
  Inc(DebugObjectCount);
  {$ENDIF}
end;

destructor TXMLElementList.Destroy;
begin
  {$IFDEF DEBUG}
  Dec(DebugObjectCount);
  {$ENDIF}
  FreeAndNil(FEnum);
  inherited;
end;

function TXMLElementList.CreateEnumerator: TXMLNodeEnumerator;
begin
  Result := TEnumerator.Create(Self);
end;

function TXMLElementList.DoNextNode: xmlNodePtr;
begin
  if FEnum.MoveNext then
    Result := FEnum.FCurrent
  else
    Result := nil;
end;

function TXMLElementList.FindItem(const Name: string): xmlNodePtr;
var
  Prefix, LocalName: RawByteString;
begin
  Result := nil;
  if SplitXMLName(UTF8Encode(Name), Prefix, LocalName) then
  begin
    var Enum := TEnumerator.Create(Self);
    while Enum.MoveNext do
    begin
      var Node := Enum.FCurrent;
      if (Node.ns <> nil) and xmlStrSame(Node.ns.prefix, Pointer(Prefix)) and xmlStrSame(Node.Name, Pointer(LocalName)) then
      begin
        Result := Node;
        Break;
      end;
    end;
    Enum.Free;
  end
  else
  begin
    var Enum := TEnumerator.Create(Self);
    while Enum.MoveNext do
    begin
      var Node := Enum.FCurrent;
      if xmlStrSame(Node.Name, Pointer(LocalName)) then
      begin
        Result := Node;
        Break;
      end;
    end;
    Enum.Free;
  end;
end;

function TXMLElementList.FindQualifiedItem(const BaseName, NamespaceURI: string): xmlNodePtr;
var
  Name, URI: RawByteString;
begin
  Result := nil;
  URI := Utf8Encode(NamespaceURI);
  Name := Utf8Encode(BaseName);
  var Enum := TEnumerator.Create(Self);
  while Enum.MoveNext do
  begin
    var Node := Enum.FCurrent;
    if (Node.ns <> nil) and xmlStrSame(Node.ns.href, Pointer(URI)) and xmlStrSame(Node.Name, Pointer(Name)) then
    begin
      Result := Node;
      Break;
    end;
  end;
  Enum.Free;
end;

function TXMLElementList.Get_Item(Index: NativeInt): IXMLNode;
begin
  var Enum := TEnumerator.Create(Self);
  var Count := 0;
  while Enum.MoveNext do
  begin
    if Count = Index then
    begin
      Result := Enum.Current;
      Break;
    end;
    Inc(Count);
  end;
  Enum.Free;
end;

function TXMLElementList.Get_Length: NativeInt;
begin
  Result := 0;
  var Enum := TEnumerator.Create(Self);
  while Enum.MoveNext do
    Inc(Result);
  Enum.Free;
end;

procedure TXMLElementList.Reset;
begin
  FEnum.Reset;
end;

{ TXMLNode }

constructor TXMLNode.Create(Node: xmlNodePtr);
begin
  inherited Create;
  NodePtr := Node;
  NodePtr._private := Self;

  {$IFDEF DEBUG}
  AtomicIncrement(DebugObjectCount);
  {$ENDIF}
end;

destructor TXMLNode.Destroy;
begin
  if (NodePtr <> nil) and (NodePtr._private = Self) then
  begin
    NodePtr._private := nil;
    if NodePtr.parent = nil then
      xmlFreeNode(NodePtr);
  end;

  {$IFDEF DEBUG}
  AtomicDecrement(DebugObjectCount);
  {$ENDIF}

  inherited;
end;

function TXMLNode.AppendChild(const NewChild: IXMLNode): IXMLNode;
begin
  // xmlAddChild can merge nodes, then Old can be freed
  var NewNode := NodePtr.AppendChild(TXMLNode(NewChild).NodePtr);
  Result := Cast(LX2CheckNodeExists(NewNode));
end;

function TXMLNode.InsertBefore(const NewChild: IXMLNode; RefChild: IXMLNode): IXMLNode;
begin
  var NewNode := NodePtr.InsertBefore(TXMLNode(NewChild).NodePtr, TXMLNode(RefChild).NodePtr);
  Result := Cast(LX2CheckNodeExists(NewNode));
end;

function TXMLNode.CloneNode(Deep: WordBool): IXMLNode;
var
  NewNode: xmlNodePtr;
begin
  if xmlDOMWrapCloneNode(nil, NodePtr.doc, NodePtr, NewNode, NodePtr.doc, nil, Ord(Deep), 0) <> 0 then
    LX2InternalError;
  Result := TXMLNode.Create(NewNode);
end;

function TXMLNode.Get_Attributes: IXMLAttributes;
begin
  Result := TXMLAttributes.Create(NodePtr);
end;

function TXMLNode.Get_BaseName: string;
begin
  Result := xmlCharToStr(NodePtr.name);
end;

function TXMLNode.Get_ChildNodes: IXMLNodeList;
begin
  Result := TXMLNodeList.Create(NodePtr.Children);
end;

function TXMLNode.Get_FirstChild: IXMLNode;
begin
  Result := Cast(NodePtr.children);
end;

function TXMLNode.Get_LastChild: IXMLNode;
begin
  Result := Cast(NodePtr.last);
end;

function TXMLNode.Get_NamespaceURI: string;
begin
  if NodePtr.ns = nil then
    Result := ''
  else
    Result := xmlCharToStr(NodePtr.ns.href);
end;

function TXMLNode.Get_NextSibling: IXMLNode;
begin
  Result := Cast(NodePtr.next);
end;

function TXMLNode.Get_NodeName: string;
begin
  case NodePtr.&type of
    XML_ELEMENT_NODE       : Result := TXMLElement(Self).TagName;
    XML_ATTRIBUTE_NODE     : Result := TXMLAttribute(Self).Name;
    XML_TEXT_NODE          : Result := '#text';
    XML_CDATA_SECTION_NODE : Result := '#cdata-section';
    XML_COMMENT_NODE       : Result := '#comment';
    XML_DOCUMENT_NODE      : Result := '#document';
    XML_DOCUMENT_FRAG_NODE : Result := '#document-fragment';
  else
    Result := xmlCharToStr(NodePtr.name);
  end;
end;

function TXMLNode.Get_NodeType: DOMNodeType;
begin
  Result := DOMNodeType(NodePtr.&type);
end;

function TXMLNode.Get_NodeValue: string;
begin
  case NodePtr.&type of
    XML_ATTRIBUTE_NODE:     Result := xmlCharToStrAndFree(xmlNodeGetContent(NodePtr));
    XML_CDATA_SECTION_NODE,
    XML_COMMENT_NODE,
    XML_TEXT_NODE,
    XML_PI_NODE:            Result := xmlCharToStrAndFree(xmlNodeGetContent(NodePtr));
    XML_ATTRIBUTE_DECL:     Result := xmlCharToStr(xmlAttributePtr(NodePtr).defaultValue);
  else
    Result := '';
  end;
end;

function TXMLNode.Get_OwnerDocument: IXMLDocument;
begin
  if NodePtr.OwnerDocument._private = nil then
    Exit(nil);

  Result := TXMLDocument(NodePtr.OwnerDocument);
end;

function TXMLNode.Get_ParentNode: IXMLNode;
begin
  Result := Cast(NodePtr.parent);
end;

function TXMLNode.Get_Prefix: string;
begin
  if NodePtr.ns = nil then
    Result := ''
  else
    Result := xmlCharToStr(NodePtr.ns.prefix);
end;

function TXMLNode.Get_PreviousSibling: IXMLNode;
begin
  Result := Cast(NodePtr.prev);
end;

function TXMLNode.Get_Text: string;
begin
  Result := xmlCharToStrAndFree(xmlNodeGetContent(NodePtr));
end;

function TXMLNode.Get_Xml: string;
begin
  var Buf := xmlAllocOutputBuffer(nil);
  xmlNodeDumpOutput(Buf, NodePtr.doc, NodePtr, 0, 0, nil);
  Result := xmlCharToStr(xmlOutputBufferGetContent(Buf), xmlOutputBufferGetSize(Buf));
  xmlOutputBufferClose(Buf);
end;

function TXMLNode.HasChildNodes: Boolean;
begin
  Result := NodePtr.HasChildNodes;
end;

procedure TXMLNode.ReconciliateNs;
begin
  NodePtr.ReconciliateNs;
end;

function TXMLNode.RemoveChild(const ChildNode: IXMLNode): IXMLNode;
begin
  Result := ChildNode;
  var Node := TXMLNode(ChildNode);
  var OldPtr := NodePtr.RemoveChild(Node.NodePtr);
  xmlFreeNode(OldPtr);
end;

function TXMLNode.ReplaceChild(const NewChild, OldChild: IXMLNode): IXMLNode;
begin
  var New := TXMLNode(NewChild);
  var Old := TXMLNode(OldChild);
  Result := Cast(NodePtr.ReplaceChild(New.NodePtr, Old.NodePtr));
  xmlFreeNode(Old.NodePtr);
end;

function TXMLNode.SelectNodes(const QueryString: string): IXMLNodeList;
begin
  var Obj := NodePtr.XPathEval(Utf8Encode(QueryString), nil, XPathErrorHandler);
  if Obj = nil then
    Exit(nil);
  Result := TXPathList.Create(Obj);
end;

function TXMLNode.SelectSingleNode(const QueryString: string): IXMLNode;
begin
  Result := Cast(NodePtr.SelectSingleNode(Utf8Encode(QueryString)));
end;

procedure TXMLNode.Set_NodeValue(const Value: string);
begin
  case NodePtr.&type of
    XML_ATTRIBUTE_NODE:     NodePtr.text := Utf8Encode(Value);
    XML_CDATA_SECTION_NODE,
    XML_COMMENT_NODE,
    XML_TEXT_NODE,
    XML_PI_NODE:            NodePtr.text := Utf8Encode(Value);
  else
    LX2NodeTypeError(NodePtr.&type);
  end;
end;

procedure TXMLNode.Set_Text(const text: string);
begin
  NodePtr.Text := Utf8Encode(text);
end;

procedure TXMLNode.XPathErrorHandler(const error: xmlError);
begin
end;

{ TXMLAttribute }

constructor TXMLAttribute.Create(AttrPtr: xmlAttrPtr);
begin
  inherited Create(xmlNodePtr(AttrPtr));
end;

destructor TXMLAttribute.Destroy;
begin
  inherited;
end;

function TXMLAttribute.GetAttrPtr: xmlAttrPtr;
begin
  Result := xmlAttrPtr(NodePtr);
end;

function TXMLAttribute.Get_Name: string;
begin
  Result := UTF8ToUnicodeString(AttrPtr.Name);
end;

function TXMLAttribute.Get_Value: string;
begin
  Result := xmlCharToStrAndFree(xmlNodeGetContent(NodePtr));
end;

procedure TXMLAttribute.Set_Value(const AttrValue: string);
begin
  var children: xmlNodePtr := nil;

  if AttrValue <> '' then
  begin
    children := xmlNewDocText(AttrPtr.parent.doc, xmlCharPtr(Utf8Encode(attrValue)));
    if children = nil then
      LX2InternalError;
  end;

  if (AttrPtr.atype = XML_ATTRIBUTE_ID) then
  begin
    xmlRemoveID(AttrPtr.parent.doc, AttrPtr);
    AttrPtr.atype := XML_ATTRIBUTE_ID;
  end;

  if AttrPtr.children <> nil then
    xmlFreeNodeList(AttrPtr.children);
  AttrPtr.children := nil;
  AttrPtr.last := nil;

  if children <> nil then
  begin
    AttrPtr.children := children;
    var Tmp := children;
    while Tmp <> nil do
    begin
      Tmp.parent := NodePtr;
      if Tmp.next = nil then
        AttrPtr.last := Tmp;
      Tmp := Tmp.next;
    end;
  end;
end;

{ TXMLElement }

function TXMLElement.GetAttribute(const Name: string): string;
begin
  Result := xmlCharToStrAndFree(xmlGetProp(NodePtr, xmlStrPtr(Utf8Encode(name))));
end;

function TXMLElement.GetAttributeNode(const Name: string): IXMLAttribute;
begin
  Result := Cast(NodePtr.GetAttributeNode(Utf8Encode(Name)));
end;

function TXMLElement.GetAttributeNodeNs(const NamespaceURI, Name: string): IXMLAttribute;
begin
  Result := Cast(NodePtr.GetAttributeNodeNs(xmlCharPtr(Utf8Encode(NamespaceURI)), xmlCharPtr(Utf8Encode(Name))));
end;

function TXMLElement.GetAttributeNs(const NamespaceURI, Name: string): string;
begin
  Result := xmlCharToStrAndFree(xmlGetNsProp(NodePtr, xmlStrPtr(Utf8Encode(NamespaceURI)), xmlStrPtr(Utf8Encode(Name))));
end;

function TXMLElement.SetAttributeNs(const NamespaceURI, Name: string; const Value: string): IXMLAttribute;
begin
  Result := Cast(NodePtr.SetAttributeNs(xmlCharPtr(Utf8Encode(NamespaceURI)), xmlCharPtr(Utf8Encode(Name)), xmlCharPtr(Utf8Encode(Value))));
end;

function TXMLElement.HasAttribute(const Name: string): Boolean;
begin
  Result := NodePtr.HasAttribute(xmlCharPtr(Utf8Encode(Name)));
end;

function TXMLElement.HasAttributeNs(const NamespaceURI, Name: string): Boolean;
begin
  Result := NodePtr.HasAttributeNs(xmlCharPtr(Utf8Encode(NamespaceURI)), xmlCharPtr(Utf8Encode(Name)));
end;

procedure TXMLElement.Normalize;
begin

end;

function TXMLElement.AddChild(const Name: string; const Content: string = ''): IXMLElement;
begin
  Result := Cast(NodePtr.AddChild(xmlCharPtr(Utf8Encode(Name)), xmlCharPtr(Utf8Encode(Content)))) as IXMLElement;
end;

function TXMLElement.AddChildNs(const Name, NamespaceURI: string; const Content: string = ''): IXMLElement;
begin
  Result := Cast(NodePtr.AddChildNs(xmlCharPtr(Utf8Encode(Name)), xmlCharPtr(Utf8Encode(NamespaceURI)), xmlCharPtr(Utf8Encode(Content)))) as IXMLElement;
end;

function TXMLElement.GetElementsByTagName(const tagName: string): IXMLNodeList;
begin
  Result := TXMLElementList.Create(NodePtr, False, tagName);
end;

function TXMLElement.Get_TagName: string;
begin
  Result := UTF8ToUnicodeString(NodePtr.TagName);
end;

function TXMLElement.RemoveAttribute(const Name: string): Boolean;
var
  Prefix, LocalName: RawByteString;
begin
  SplitXMLName(Utf8Encode(Name), Prefix, LocalName);
  if Prefix = '' then
    Result := xmlUnsetProp(NodePtr, xmlCharPtr(LocalName)) = 0
  else
  begin
    var Ns := NodePtr.SearchNs(Prefix);
    if Ns <> nil then
      Result := xmlUnsetNsProp(NodePtr, Ns, xmlCharPtr(LocalName)) = 0
    else
      Result := False;
  end;
end;

function TXMLElement.RemoveAttributeNs(const NamespaceURI, Name: string): Boolean;
begin
  var Ns := NodePtr.SearchNsByRef(Utf8Encode(NamespaceURI));
  if Ns = nil then
    Exit(False);
  Result := xmlUnsetNsProp(NodePtr, Ns, xmlCharPtr(Utf8Encode(Name))) = 0
end;

function TXMLElement.RemoveAttributeNode(const Attribute: IXMLAttribute): IXMLAttribute;
begin
  if Attribute = nil then
    Exit(nil);

  var Attr := TXMLAttribute(Attribute);
  if Attr.NodePtr.parent = NodePtr then
  begin
    Result := Attribute;
    xmlUnlinkNode(Attr.NodePtr);
  end
  else
    Result := nil;
end;

procedure TXMLElement.SetAttribute(const Name: string; Value: string);
begin
  xmlSetProp(NodePtr, xmlCharPtr(Utf8Encode(Name)), xmlCharPtr(Utf8Encode(Value)));
end;

{ TXMLCharacterData }

procedure TXMLCharacterData.AppendData(const Data: string);
begin
  xmlNodeAddContent(NodePtr, xmlCharPtr(Utf8Encode(Data)));
end;

procedure TXMLCharacterData.DeleteData(Offset, Count: Integer);
begin
  var S := xmlCharToStr(NodePtr.content);

  Delete(S, offset, count);

  xmlNodeSetContent(NodePtr, nil);
  xmlNodeAddContent(NodePtr, XmlCharPtr(UTF8Encode(S)));
end;

function TXMLCharacterData.Get_Data: string;
begin
  Result := xmlCharToStr(NodePtr.content);
end;

function TXMLCharacterData.Get_Length: NativeInt;
begin
  Result := Utf8toUtf16Count(NodePtr.content);
end;

procedure TXMLCharacterData.InsertData(Offset: Integer; const Data: string);
begin
  var S := xmlCharToStr(NodePtr.content);

  Insert(data, S, Offset);

  xmlNodeSetContent(NodePtr, nil);
  xmlNodeAddContent(NodePtr, XmlCharPtr(UTF8Encode(S)));
end;

procedure TXMLCharacterData.ReplaceData(Offset, Count: Integer; const Data: string);
begin
  var S := xmlCharToStr(NodePtr.content);

  Delete(S, Offset, Count);
  Insert(data, S, Offset);

  xmlNodeSetContent(NodePtr, nil);
  xmlNodeAddContent(NodePtr, XmlCharPtr(UTF8Encode(S)));
end;

procedure TXMLCharacterData.Set_Data(const Data: string);
begin
  xmlNodeSetContent(NodePtr, nil);
  xmlNodeAddContent(NodePtr, XmlCharPtr(UTF8Encode(Data)));
end;

function TXMLCharacterData.SubstringData(Offset, Count: Integer): string;
begin
  Result := Copy(xmlCharToStr(NodePtr.content), Offset, Count);
end;

{ TXMLProcessingInstruction }

function TXMLProcessingInstruction.Get_Data: string;
begin
  Result := xmlCharToStr(NodePtr.content);
end;

function TXMLProcessingInstruction.Get_Target: string;
begin
  Result := xmlCharToStr(NodePtr.name);
end;

procedure TXMLProcessingInstruction.Set_Data(const Value: string);
begin
  xmlNodeSetContent(NodePtr, nil);
  xmlNodeAddContent(NodePtr, XmlCharPtr(UTF8Encode(Value)));
end;

{ TXMLError }

constructor TXMLError.Create(const Error: TXmlParseError);
begin
  Create;
  FError := Error;
end;

constructor TXMLError.Create;
begin
end;

function TXMLError.Get_ErrorCode: Integer;
begin
  Result := FError.Code;
end;

function TXMLError.Get_FilePos: Integer;
begin
  Result := 0;
end;

function TXMLError.Get_Level: xmlErrorLevel;
begin
  Result := FError.Level;
end;

function TXMLError.Get_Line: Integer;
begin
  Result := FError.Line;
end;

function TXMLError.Get_LinePos: Integer;
begin
  Result := FError.Col;
end;

function TXMLError.Get_Reason: string;
begin
  Result := FError.Text;
end;

function TXMLError.Get_SrcText: string;
begin
  Result := FError.Source;
end;

function TXMLError.Get_Url: string;
begin
  Result := FError.Url;
end;

{ TXMLErrors.TEnumerator }

constructor TXMLErrors.TEnumerator.Create(Owner: TXMLErrors);
begin
  inherited Create;
  FOwner := Owner;
  FIndex := -1;
end;

function TXMLErrors.TEnumerator.GetCurrent: IXMLParseError;
begin
  Result := FOwner.FList[FIndex] as IXMLParseError;
end;

function TXMLErrors.TEnumerator.MoveNext: Boolean;
begin
  Inc(FIndex);
  Result := FIndex < FOwner.FList.Count;
end;

{ TXMLErrors }

constructor TXMLErrors.Create;
begin
  inherited Create;
  FList := TInterfaceList.Create;
  FIndex := -1;
end;

destructor TXMLErrors.Destroy;
begin
  FreeAndNil(FList);
  inherited;
end;

procedure TXMLErrors.Clear;
begin
  FList.Clear;
end;

function TXMLErrors.GetEnumerator: IXMLErrorEnumerator;
begin
  Result := TEnumerator.Create(Self);
end;

function TXMLErrors.Get_Count: NativeUInt;
begin
  Result := FList.Count;
end;

function TXMLErrors.Get_Item(Index: NativeUInt): IXMLParseError;
begin
  Result := FList[Index] as IXMLParseError;
end;

function TXMLErrors.Get_next: IXMLParseError;
begin
  Inc(FIndex);
  if FIndex < FList.Count then
    Result := FList[FIndex] as IXMLParseError
  else
    Result := nil;
end;

function TXMLErrors.Get__newEnum: IXMLErrorEnumerator;
begin
  Result := GetEnumerator;
end;

function TXMLErrors.MainError: IXMLParseError;
begin
  if FList.Count = 0 then
    Exit(nil);

  Result := FList[FList.Count - 1] as IXMLParseError;
  for var I := Count - 2 downto 0 do
    if (FList[I] as IXMLParseError).level > Result.level then
      Result := FList[I] as IXMLParseError;
end;

procedure TXMLErrors.Reset;
begin
  FIndex := -1;
end;

{ TXSLTError }

constructor TXSLTError.Create(const Reason: string);
begin
  inherited Create;
  FReason := Reason;
end;

function TXSLTError.Get_Reason: string;
begin
  Result := FReason;
end;

{ TXSLTErrors.TEnumerator }

constructor TXSLTErrors.TEnumerator.Create(Owner: TXSLTErrors);
begin
  inherited Create;
  FOwner := Owner;
  FIndex := -1;
end;

function TXSLTErrors.TEnumerator.GetCurrent: IXSLTError;
begin
  Result := FOwner.FList[FIndex] as IXSLTError;
end;

function TXSLTErrors.TEnumerator.MoveNext: Boolean;
begin
  Inc(FIndex);
  Result := FIndex < FOwner.FList.Count;
end;

{ TXSLTErrors }

constructor TXSLTErrors.Create;
begin
  inherited Create;
  FList := TInterfaceList.Create;
end;

destructor TXSLTErrors.Destroy;
begin
  FreeAndNil(FList);
  inherited;
end;

procedure TXSLTErrors.Clear;
begin
  FList.Clear;
end;

function TXSLTErrors.GetEnumerator: IXSLTErrorEnumerator;
begin
  Result := TEnumerator.Create(Self);
end;

function TXSLTErrors.Get_Count: NativeUInt;
begin
  Result := FList.Count;
end;

function TXSLTErrors.Get_Item(Index: NativeUInt): IXSLTError;
begin
  Result := FList[Index] as IXSLTError;
end;

{ TXMLDocument }

constructor TXMLDocument.Create;
begin
  TMonitor.Enter(GlobalLock);
  try
    LX2Lib.Initialize;

    if not Assigned(OldDeregisterNodeFunc) then
      OldDeregisterNodeFunc := xmlDeregisterNodeDefault(NodeFreeCallback);
  finally
    TMonitor.Exit(GlobalLock);
  end;

  Create(xmlNewDoc(nil), True);
  FSuccessError := TXMLError.Create;
end;

constructor TXMLDocument.Create(doc: xmlDocPtr; DocOwner: Boolean);
begin
  inherited Create(xmlNodePtr(doc));
  FDocOwner := DocOwner;
  FErrors := TXMLErrors.Create;
  FXSLTErrors := TXSLTErrors.Create;
  FSuccessError := nil;
  FValidateOnParse := True;
end;

destructor TXMLDocument.Destroy;
begin
  if NodePtr <> nil then
  begin
    if DocOwner then
      xmlFreeDoc(xmlDocPtr(NodePtr));
    NodePtr := nil;
  end;
  inherited;
  FreeAndNil(FErrors);
  FreeAndNil(FXSLTErrors);
end;

function TXMLDocument.Clone(Recursive: Boolean): IXMLDocument;
begin
  Result := TXMLDocument.Create(xmlDocPtr(NodePtr).Clone(Recursive), True);
end;

function TXMLDocument.CreateAttribute(const Name: string): IXMLAttribute;
begin
  Result := Cast(xmlNewDocProp(xmlDocPtr(NodePtr), xmlCharPtr(Utf8Encode(Name)), nil));
end;

function TXMLDocument.CreateCDATASection(const Data: string): IXMLCDATASection;
begin
  var S := Utf8Encode(Data);
  var L := Length(Data);

  Result := Cast(xmlNewCDataBlock(xmlDocPtr(NodePtr), xmlCharPtr(S), L)) as IXMLCDATASection;
end;

function TXMLDocument.CreateComment(const Data: string): IXMLComment;
begin
  var S := Utf8Encode(Data);
  Result := Cast(xmlNewDocComment(xmlDocPtr(NodePtr), xmlCharPtr(Utf8Encode(Data)))) as IXMLComment;
end;

function TXMLDocument.CreateDocumentFragment: IXMLDocumentFragment;
begin
  Result := Cast(xmlNewDocFragment(xmlDocPtr(NodePtr))) as IXMLDocumentFragment;
end;

function TXMLDocument.CreateElement(const TagName: string): IXMLElement;
begin
  Result := CreateNode(NODE_ELEMENT, TagName, '') as IXMLElement;
end;

function TXMLDocument.CreateElementNs(const NamespaceURI, Name: string): IXMLElement;
begin
  Result := Cast(xmlDocPtr(NodePtr).CreateElementNs(Utf8Encode(NamespaceURI), Utf8Encode(Name))) as IXMLElement;
end;

function TXMLDocument.CreateRoot(const RootName: string; const NamespaceURI: string = ''; Content: string = ''): IXMLElement;
begin
  Result := Cast(xmlDocPtr(NodePtr).CreateRoot(Utf8Encode(RootName), Utf8Encode(NamespaceURI), Utf8Encode(Content))) as IXMLElement;
end;

function TXMLDocument.CreateChild(const Parent: IXMLElement; const Name: string; const NamespaceURI: string = ''; ResolveNamespace: Boolean = False; Content: string = ''): IXMLElement;
begin
  Result := Cast(xmlDocPtr(NodePtr).CreateChild(TXMLNode(Parent).NodePtr, Utf8Encode(Name), Utf8Encode(NamespaceURI), ResolveNamespace, Utf8Encode(Content))) as IXMLElement;
end;

function TXMLDocument.CreateNode(NodeType: Integer; const Name, NamespaceURI: string): IXMLNode;
var
  Prefix, LocalName, HRef: RawByteString;
begin
  if NamespaceURI <> '' then
  begin
    SplitXMLName(Utf8Encode(Name), Prefix, LocalName);
    HRef := Utf8Encode(NamespaceURI);
  end
  else
    SplitXMLName(Utf8Encode(Name), Prefix, LocalName);

  case NodeType of
    NODE_ATTRIBUTE:
      Result := Cast(xmlNewDocProp(xmlDocPtr(NodePtr), xmlCharPtr(LocalName), nil));
    NODE_CDATA_SECTION:
      Result := Cast(xmlNewCDataBlock(xmlDocPtr(NodePtr), nil, 0));
    NODE_COMMENT:
      Result := Cast(xmlNewDocComment(xmlDocPtr(NodePtr), nil));
    NODE_DOCUMENT:
      Result := TXmlDocument.Create;
    NODE_DOCUMENT_FRAGMENT:
      Result := Cast(xmlNewDocFragment(xmlDocPtr(NodePtr)));
    NODE_TEXT:
      Result := Cast(xmlNewDocText(xmlDocPtr(NodePtr), nil));
    NODE_ELEMENT:
      if href = '' then
      begin
        if Prefix = '' then
          Result := Cast(xmlNewDocNode(xmlDocPtr(NodePtr), nil, xmlCharPtr(LocalName), nil))
        else
          Result := Cast(xmlNewDocNode(xmlDocPtr(NodePtr), xmlNewNs(nil, nil, xmlCharPtr(Prefix)), xmlCharPtr(LocalName), nil))
      end
      else
        Result := Cast(xmlNewDocNode(xmlDocPtr(NodePtr), xmlNewNs(nil, xmlCharPtr(HRef), xmlCharPtr(Prefix)), xmlCharPtr(LocalName), nil));
    NODE_PROCESSING_INSTRUCTION:
      Result := Cast(xmlNewDocPI(xmlDocPtr(NodePtr), xmlCharPtr(LocalName), nil));
  else
    Result := nil;
  end;
end;

function TXMLDocument.CreateProcessingInstruction(const Target, Data: string): IXMLProcessingInstruction;
begin
  Result := Cast(xmlNewDocPI(xmlDocPtr(NodePtr), xmlCharPtr(Utf8Encode(Target)), xmlCharPtr(Utf8Encode(Data)))) as IXMLProcessingInstruction;
end;

function TXMLDocument.CreateTextNode(const Data: string): IXMLText;
begin
  Result := Cast(xmlNewDocText(xmlDocPtr(NodePtr), xmlCharPtr(Utf8Encode(Data)))) as IXMLText;
end;

procedure TXMLDocument.ErrorCallback(const error: xmlError);
begin
  var Err := TXMLError.Create(TXmlParseError.Create(error));
  Errors.FList.Add(Err);
end;

function TXMLDocument.getElementsByTagName(const TagName: string): IXMLNodeList;
begin
  if xmlDocPtr(NodePtr).documentElement = nil  then
    Exit(nil);

  Result := TXMLElementList.Create(xmlDocPtr(NodePtr).documentElement, True, TagName);
end;

function TXMLDocument.getErrors: IXMLErrors;
begin
  Result := FErrors;
end;

function TXMLDocument.GetXSLTErrors: IXSLTErrors;
begin
  Result := FXSLTErrors;
end;

function TXMLDocument.Get_DocType: IXMLDocumentType;
begin
  if (xmlDocPtr(NodePtr).children <> nil) and (xmlDocPtr(NodePtr).children.&type = XML_DTD_NODE) then
    Result := Cast(xmlDocPtr(NodePtr).children) as IXMLDocumentType
  else
    Result := nil;
end;

function TXMLDocument.Get_DocumentElement: IXMLElement;
begin
  Result := Cast(xmlDocPtr(NodePtr).documentElement) as IXMLElement;
end;

function TXMLDocument.Get_ParseError: IXMLParseError;
begin
  if Errors.Count > 0 then
    Result := Errors.MainError
  else
    Result := FSuccessError;
end;

function TXMLDocument.Get_PreserveWhiteSpace: Boolean;
begin
  Result := FPreserveWhiteSpace;
end;

function TXMLDocument.Get_ReadyState: Integer;
begin
  if (xmlDocPtr(NodePtr).properties and Ord(XML_DOC_WELLFORMED)) = Ord(XML_DOC_WELLFORMED) then
    Result := 4   //MS DOM COMPLETED
  else
    Result := 2;  //MS DOM LOADED
end;

function TXMLDocument.Get_ResolveExternals: Boolean;
begin
  Result := FResolveExternals;
end;

function TXMLDocument.Get_Url: string;
begin
  Result := Utf8ToUnicodeString(xmlDocPtr(NodePtr).URL);
end;

function TXMLDocument.Get_ValidateOnParse: Boolean;
begin
  Result := FValidateOnParse;
end;

function TXMLDocument.SetNewDoc(Doc: xmlDocPtr): xmlDocPtr;
begin
  Result := Doc;
  if Doc = nil then
    Exit;

  NodePtr._private := nil;
  xmlFreeDoc(Pointer(NodePtr));
  NodePtr := Pointer(Doc);
  NodePtr._private := Self;

  Errors.FList.Clear;

  if ValidateOnParse then
    Include(FOptions, xmlParseDTDValidation)
  else
    Exclude(FOptions, xmlParseDTDValidation);

  if resolveExternals then
  begin
    Exclude(FOptions, xmlParseNoXXE);
    Include(FOptions, xmlParseExternalDTD);
  end
  else
  begin
    Exclude(FOptions, xmlParseExternalDTD);
  end;
end;

function TXMLDocument.Load(const URL: string): Boolean;
begin
  Result := SetNewDoc(xmlDoc.CreateFromFile(URL, Options, ErrorCallback)) <> nil;
end;

function TXMLDocument.Load(const Data: TBytes): Boolean;
begin
  Result := SetNewDoc(xmlDoc.Create(Data, Options, ErrorCallback)) <> nil;
end;

function TXMLDocument.Load(const Data: Pointer; Size: NativeUInt): Boolean;
begin
  Result := SetNewDoc(xmlDoc.Create(Data, Size, Options, ErrorCallback)) <> nil;
end;

function TXMLDocument.Load(Stream: TStream; const Encoding: Utf8String): Boolean;
begin
  Result := SetNewDoc(xmlDoc.Create(Stream, Options, Encoding, ErrorCallback)) <> nil;
end;

function TXMLDocument.LoadXML(const XML: string; const Options: TXmlParserOptions): Boolean;
begin
  Result := SetNewDoc(xmlDoc.Create(XML, Options, ErrorCallback)) <> nil;
end;

function TXMLDocument.LoadXML(const XML: RawByteString; const Options: TXmlParserOptions): Boolean;
begin
  Result := SetNewDoc(xmlDoc.Create(XML, Options, ErrorCallback)) <> nil;
end;

function TXMLDocument.NodeFromID(const IdString: string): IXMLNode;
begin
  var Attr := xmlGetID(xmlDocPtr(NodePtr), xmlCharPtr(Utf8Encode(IdString)));
  if Attr = nil then
    Exit(nil);

  Result := Cast(Attr.Parent);
end;

procedure TXMLDocument.Normalize;
begin

end;

procedure TXMLDocument.ReconciliateNs;
begin
  xmlReconciliateNs(xmlDocPtr(NodePtr), xmlDocPtr(NodePtr).documentElement);
end;

procedure TXMLDocument.Save(const Url: string);
begin
  xmlSaveFile(xmlCharPtr(Utf8Encode(url)), xmlDocPtr(NodePtr));
end;

function TXMLDocument.Save(const FileName, Encoding: string; const Options: TxmlSaveOptions): Boolean;
begin
  Result := xmlDocPtr(NodePtr).Save(FileName, Encoding, Options);
end;

function TXMLDocument.Save(Stream: TStream; const Encoding: string; const Options: TxmlSaveOptions): Boolean;
begin
  Result := xmlDocPtr(NodePtr).Save(Stream, Encoding, Options);
end;

procedure TXMLDocument.Set_documentElement(const Element: IXMLElement);
begin
  if Element = nil then
    xmlDocPtr(NodePtr).documentElement := nil
  else
    xmlDocPtr(NodePtr).documentElement := TXMLNode(Element).NodePtr;
end;

procedure TXMLDocument.Set_preserveWhiteSpace(isPreserving: Boolean);
begin
  FPreserveWhiteSpace := isPreserving;
end;

procedure TXMLDocument.Set_resolveExternals(IsResolving: Boolean);
begin
  FResolveExternals := IsResolving;
end;

procedure TXMLDocument.Set_validateOnParse(IsValidating: Boolean);
begin
  FValidateOnParse := IsValidating;
end;

function TXMLDocument.ToAnsi(const Encoding: string; const Format: Boolean): RawByteString;
begin
  Result := xmlDocPtr(NodePtr).ToAnsi(Encoding, Format);
end;

function TXMLDocument.ToBytes(const Encoding: string; const Format: Boolean): TBytes;
begin
  Result := xmlDocPtr(NodePtr).ToBytes(Encoding, Format);
end;

function TXMLDocument.ToString: string;
begin
  Result := xmlDocPtr(NodePtr).ToString(False);
end;

function TXMLDocument.ToString(const Format: Boolean): string;
begin
  Result := xmlDocPtr(NodePtr).ToString(Format);
end;

function TXMLDocument.ToUtf8(const Format: Boolean): RawByteString;
begin
  Result := xmlDocPtr(NodePtr).ToUtf8(Format);
end;

function TXMLDocument.Transform(const Stylesheet: IXMLDocument; out Doc: IXMLDocument): Boolean;
var
  Res: xmlDocPtr;
begin
  TXSLTThreadErrorContext.Start(Self, XSLTErrorHandler);
  try
    FXSLTErrors.Clear;

    Result := xmlDocPtr(NodePtr).Transform(xmlDocPtr(TXMLDocument(stylesheet).NodePtr), Res);
    if Result then
      Doc := TXMLDocument.Create(Res, True);
  finally
    TXSLTThreadErrorContext.Stop
  end;
end;

function TXMLDocument.Transform(const Stylesheet: IXMLDocument; out S: RawByteString): Boolean;
begin
  TXSLTThreadErrorContext.Start(Self, XSLTErrorHandler);
  try
    FXSLTErrors.Clear;

    Result := xmlDocPtr(NodePtr).Transform(xmlDocPtr(TXMLDocument(Stylesheet).NodePtr), S);
  finally
    TXSLTThreadErrorContext.Stop
  end;
end;

function TXMLDocument.Transform(const Stylesheet: IXMLDocument; out S: string): Boolean;
begin
  TXSLTThreadErrorContext.Start(Self, XSLTErrorHandler);
  try
    FXSLTErrors.Clear;

    Result := xmlDocPtr(NodePtr).Transform(xmlDocPtr(TXMLDocument(Stylesheet).NodePtr), S);

  finally
    TXSLTThreadErrorContext.Stop
  end;
end;

function TXMLDocument.Validate: IXMLParseError;
begin
  Errors.FList.Clear;

  xmlDocPtr(NodePtr).Validate(ErrorCallback);

  if Errors.Count = 0 then
    Exit(FSuccessError)
  else
    Result := Errors.MainError;
end;

function TXMLDocument.ValidateNode(const Node: IXMLNode): IXMLParseError;
begin
  Errors.FList.Clear;

  xmlDocPtr(NodePtr).ValidateNode(TXMLNode(Node).NodePtr, ErrorCallback);

  if Errors.Count = 0 then
    Exit(FSuccessError)
  else
    Result := Errors.MainError;
end;

procedure TXMLDocument.XSLTError(const Msg: string);
begin
  FXSLTErrors.FList.Add(TXSLTError.Create(Msg) as IXSLTError);
end;

{ TXMLSchemaCollection }

function SchemaResourceCallback(ctxt: Pointer; const url, publicId: xmlCharPtr; &type: xmlResourceType; flags: Integer; var output: xmlParserInputPtr): Integer; cdecl;
begin
  var Col := TXMLSchemaCollection(ctxt);
  var Index := Col.IndexOf(xmlCharToStr(url));
  if Index >= 0 then
  begin
    var Data := TXMLSchemaCollection.TSchema(Col.FList[Index]).Doc.ToBytes;
    output := xmlNewInputFromMemory(nil, xmlCharPtr(Data), Length(Data), XML_INPUT_BUF_STATIC);
    Result := 0;
  end
  else
    Result := -1;
end;

procedure SchemaParserErrorCallback(userData: Pointer; const error: xmlErrorPtr); cdecl;
begin
  var Err := TXMLError.Create(TXmlParseError.Create(error^));
  TXMLDocument(userData).Errors.FList.Add(Err as IXMLParseError);
end;

constructor TXMLSchemaCollection.Create;
begin
  inherited Create;
  FErrors := TXMLErrors.Create;
end;

destructor TXMLSchemaCollection.Destroy;
begin
  FreeAndNil(FErrors);
  inherited;
end;

procedure TXMLSchemaCollection.Parse;

  procedure ExtractImports(Schema: PSchema; parent: xmlNodePtr; ns: xmlNsPtr; Index: NativeInt);
  begin
    var Node := parent.FirstElementChild;
    while Node <> nil do
    begin
      if xmlStrSame(Node.name, Pointer(cImport)) and (Node.ns = ns) then
      begin
        var location := xmlGetProp(Node, 'schemaLocation');
        if location <> nil then
        begin
          var importIndex := IndexOf(UTF8ToWideString(location));
          if importIndex >= 0 then
          begin
            Schema.Imports := Schema.Imports + [importIndex];
            var parentSchema := FList[importIndex];
            parentSchema.Parents := parentSchema.Parents + [Index];
          end;
        end;
      end
      else
        ExtractImports(Schema, Node, ns, Index);

      Node := Node.NextElementSibling;
    end;
  end;

begin
  for var I := Low(FList) to High(FList) do
  begin
    var root := TXMLNode(FList[I].Doc.documentElement).NodePtr;
    var ns := root.SearchNsByRef(Pointer(cSchemaNs));
    ExtractImports(@FList[I], root, ns, I);
  end;

  for var I := Low(FList) to High(FList) do
    if System.Length(FList[I].Parents) = 0 then
      FRoots := FRoots + [FList[I].Doc];
end;

procedure TXMLSchemaCollection.Add(const NamespaceURI: string; Doc: IXMLDocument);
var
  Item: TSchema;
  URI: string;
begin
  URI := xmlNormalizeString(NamespaceURI);
  var Index := IndexOf(URI);

  Item.NamespaceURI := URI;
  Item.Doc := Doc;

  if Index < 0 then
    FList := FList + [Item]
  else
    FList[Index] := Item;
end;

function TXMLSchemaCollection.GetSchema(const NamespaceURI: string): IXMLDocument;
begin
  var Index := IndexOf(xmlNormalizeString(NamespaceURI));
  if Index < 0 then
    Result := nil
  else
    Result := FList[Index].Doc;
end;

function TXMLSchemaCollection.Get_Length: NativeInt;
begin
  Result := System.Length(FList);
end;

function TXMLSchemaCollection.Get_NamespaceURI(Index: NativeInt): string;
begin
  Result := FList[Index].NamespaceURI;
end;

function TXMLSchemaCollection.IndexOf(const NamespaceURI: string): NativeInt;
var
  URI: string;
begin
  URI := xmlNormalizeString(NamespaceURI);
  Result := 0;
  while Result < High(FList) do
  begin
    if AnsiSameText(FList[Result].NamespaceURI, URI) then
      Exit;
    Inc(Result);
  end;
  Result := -1;
end;

procedure TXMLSchemaCollection.Remove(const NamespaceURI: string);
begin
  var Index := IndexOf(NamespaceURI);
  if Index >= 0 then
    Delete(FList, Index, 1);
end;

function TXMLSchemaCollection.Validate(const Doc: IXMLDocument): Boolean;
begin
  Result := True;
  Doc.errors.clear;

  Parse;

  for var I := Low(FRoots) to High(FRoots) do
  begin
    var ctxt := xmlSchemaNewDocParserCtxt(xmlDocPtr(TXMLDocument(FRoots[I]).NodePtr));
    xmlSchemaSetResourceLoader(ctxt, SchemaResourceCallback, Self);
    xmlSchemaSetParserStructuredErrors(ctxt, SchemaParserErrorCallback, TXmlDocument(Doc));

    var schema := xmlSchemaParse(ctxt);
    if schema = nil then
    begin
      Result := False;
      Continue;
    end;
    var vctxt := xmlSchemaNewValidCtxt(schema);
    if vctxt = nil then
    begin
      Result := False;
      Continue;
    end;

    xmlSchemaSetValidStructuredErrors(vctxt, SchemaParserErrorCallback, TXmlDocument(Doc));

    Result := xmlSchemaValidateDoc(vctxt, xmlDocPtr(TXMLDocument(Doc).NodePtr)) = 0;

    xmlSchemaFreeValidCtxt(vctxt);
    xmlSchemaFree(schema);
    xmlSchemaFreeParserCtxt(ctxt);
    if Result then
      Break;
  end;
end;

initialization
  GlobalLock := TObject.Create;

finalization
  FreeAndNil(GlobalLock);

end.
