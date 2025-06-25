unit LX2.DOM.Classes;

interface

uses
  System.Types, System.SysUtils, System.Classes, System.Generics.Collections,
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
    function  InsertNode(NewNode, AfterNode: xmlNodePtr): xmlNodePtr; virtual; abstract;
  public
    { IXMLNamedNodeMap }
    function  GetNamedItem(const Name: string): IXMLNode;
    function  SetNamedItem(const NewItem: IXMLNode): IXMLNode;
    function  RemoveNamedItem(const Name: string): IXMLNode;
    function  GetQualifiedItem(const BaseName: string; const namespaceURI: string): IXMLNode;
    function  RemoveQualifiedItem(const BaseName: string; const namespaceURI: string): IXMLNode;
    function  getNamedItemNS(const namespaceURI, localName: string): IXMLNode;
    function  setNamedItemNS(const NewItem: IXMLNode): IXMLNode;
    function  removeNamedItemNS(const namespaceURI, localName: string): IXMLNode;
  end;

  TXMLNodeNamedNodeMap = class(TXMLCustomNamedNodeMap)
  private
    FParent: xmlNodePtr;
  protected
    function  InsertNode(NewNode, AfterNode: xmlNodePtr): xmlNodePtr; override;
  public
    constructor Create(const Parent: xmlNodePtr);
    property  Parent: xmlNodePtr read FParent;
  end;

  /// <summary>
  /// Node.NsDef & Node.properites enumeration <see cref="TXMLNsNode"/>
  /// </summary>
  TXMLAttributeList = class(TInterfacedObject, IXMLNodeList, IXMLNamedNodeMap)
  protected type
    TEnumState = (esStart, esNs, esAttr);

    TEnumerator = class(TInterfacedObject, IXMLEnumerator)
    private
      FParent: xmlNodePtr;
      FCurrent: Pointer;
      FState: TEnumState;
    public
      constructor Create(Parent: xmlNodePtr);
      function  GetCurrent: IXMLNode;
      procedure Reset;
      function  MoveNext: Boolean;
    end;

  private
    FEnum: TEnumerator;
    FParent: xmlNodePtr;
  protected
    function  Get_Item(Index: NativeInt): IXMLNode;
    function  Get_Length: NativeInt;
  protected
    function  FindAttr(const Name: string): xmlAttrPtr;
    function  FindNs(const Name: string): xmlNsPtr;
    function  FindQAttr(const BaseName, NamespaceURI: string): xmlAttrPtr;
    function  FindQNs(const BaseName, NamespaceURI: string): xmlNsPtr;
    property  Parent: xmlNodePtr read FParent;
  public
    constructor Create(const Parent: xmlNodePtr);
    destructor Destroy; override;
    procedure Reset;
    { IXMLNodeList }
    function  NextNode: IXMLNode;
    function  GetEnumerator: IXMLEnumerator;
    function  ToArray: TArray<IXMLNode>;
    { IXMLNamedNodeMap }
    function  GetNamedItem(const Name: string): IXMLNode;
    function  SetNamedItem(const NewItem: IXMLNode): IXMLNode;
    function  RemoveNamedItem(const Name: string): IXMLNode;
    function  GetQualifiedItem(const BaseName: string; const namespaceURI: string): IXMLNode;
    function  RemoveQualifiedItem(const BaseName: string; const namespaceURI: string): IXMLNode;
    function  getNamedItemNS(const namespaceURI, localName: string): IXMLNode;
    function  setNamedItemNS(const NewItem: IXMLNode): IXMLNode;
    function  removeNamedItemNS(const namespaceURI, localName: string): IXMLNode;
  end;

  TXMLAttributes = class(TXMLAttributeList, IXMLAttributes)
  protected type
    TEnumerator = class(TXMLAttributeList.TEnumerator, IXMLAttributesEnumerator)
    public
      function  GetCurrent: IXMLAttribute;
    end;
  protected
    function  Get_Attr(Index: NativeInt): IXmlAttribute;
  protected
  public
    { IXMLAttributes }
    function  NextNode: IXMLAttribute;
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
    FNamespaceURI: string;
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
    constructor Create(Parent: xmlNodePtr; Recursive: Boolean; const Mask: string = '*'; const NamespaceURI: string = '');
    destructor Destroy; override;
    procedure Reset; override;
    property  Recursive: Boolean read FRecursive;
    property  Mask: string read FMask;
    property  NamespaceURI: string read FNamespaceURI;
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
    function  HasAttributes: Boolean;
    function  HasChildNodes: Boolean;
    function  InsertBefore(const NewChild: IXMLNode; RefChild: IXMLNode): IXMLNode;
    procedure Normalize;
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

  /// <summary>
  /// MS XML threats NS declartion as Node, while libxml2 does not so wee need handle this scpecial case
  /// </summary>
  TXMLNsNode = class(TInterfacedObject, IXMLNode)
  protected
    { IXMLNode }
    function  AppendChild(const NewChild: IXMLNode): IXMLNode;
    function  CloneNode(Deep: WordBool): IXMLNode;
    function  CloneTo(Deep: WordBool; Parent: IXMLNode): IXMLNode;
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
    function  HasAttributes: Boolean;
    function  HasChildNodes: Boolean;
    function  InsertBefore(const NewChild: IXMLNode; RefChild: IXMLNode): IXMLNode;
    procedure Normalize;
    function  RemoveChild(const ChildNode: IXMLNode): IXMLNode;
    function  ReplaceChild(const NewChild: IXMLNode; const OldChild: IXMLNode): IXMLNode;
    function  SelectNodes(const QueryString: string): IXMLNodeList;
    function  SelectSingleNode(const QueryString: string): IXMLNode;
    procedure Set_NodeValue(const Value: string);
    procedure Set_Text(const Text: string);
  protected
    NsPtr: xmlNsPtr;
    Parent: xmlNodePtr;
    constructor Create(Ns: xmlNsPtr; Parent: xmlNodePtr);
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

  TXMLNsAttribute = class(TXMLNsNode, IXMLAttribute)
  protected
    function  Get_OwnerElement: IXMLElement;
    function  Get_Name: string;
    function  Get_Value: string;
    procedure Set_Value(const Value: string);
    property  Name: string read Get_Name;
    property  Value: string read Get_Value write Set_value;
  end;

  TXMLAttribute = class(TXMLNode, IXMLAttribute)
  private
    function  GetAttrPtr: xmlAttrPtr; inline;
  protected
    Unlinked: Boolean;
    UnlinkedPrefix: RawByteString;
    UnlinkedURI: RawByteString;
    constructor Create(AttrPtr: xmlAttrPtr);
    property  AttrPtr: xmlAttrPtr read GetAttrPtr;
  protected
    function  Get_Name: string;
    function  Get_OwnerElement: IXMLElement;
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

    function  NextSiblingElement: IXMLElement;
    function  FirstChildElement: IXMLElement;
    function  LastChildElement: IXMLElement;
    function  PreviousSiblingElement: IXMLElement;

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
  protected
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
    cImport = 'import';
    cInclude = 'include';
    cSchemaNs = 'http://www.w3.org/2001/XMLSchema';
  private type
    TItem = class
      NamespaceURI: string;
      URL: string;
      Doc: IXMLDocument;
    end;

    TItems = class(TObjectList<TItem>)
    public
      function Add(const NamespaceURI, URL: string; const Doc: IXMLDocument): TItem;
      function IndexOfURL(const URL: string): NativeInt;
    end;

    TSchema = class
      NamespaceURI: string;
      Doc: IXMLDocument;
    end;

    TSchemas = class(TObjectList<TSchema>)
    public
      function Add(const NamespaceURI: string; const Doc: IXMLDocument): TSchema;
    end;

  private
    FItems: TItems;
    FSchemas: TSchemas;
    FErrors: TXMLErrors;
    procedure ImportNode(Node: IXMLElement; const Location, TargetNamespace: string; const Resolver: IXMLResolver);
    procedure IncludeNode(Node: IXMLNode; const Location, TargetNamespace: string; const Resolver: IXMLResolver);
  protected
    function  ResourceLoader(const url, publicId: xmlCharPtr; resType: xmlResourceType; Flags: Integer; var output: xmlParserInputPtr): Integer;
    property  Items: TItems read FItems;
    property  Schemas: TSchemas read FSchemas;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Parse;
    function  Validate(const Doc: IXMLDocument): Boolean;
    function  IndexOf(const NamespaceURI: string): NativeInt;
    procedure Add(const NamespaceURI: string; const Doc: IXMLDocument; const Resolver: IXMLResolver = nil);
    procedure Remove(const NamespaceURI: string);
    function  Get_Length: NativeInt;
    function  Get_NamespaceURI(index: NativeInt): string;
    function  Get(const NamespaceURI: string): IXMLDocument;
    procedure AddCollection(const otherCollection: IXMLSchemaCollection);
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
    FSchemas: IXMLSchemaCollection;
  protected
    procedure ErrorCallback(const error: xmlError); virtual;
    procedure XSLTError(const Msg: string); virtual;
    function  SetNewDoc(Doc: xmlDocPtr): xmlDocPtr;
    property  DocOwner: Boolean read FDocOwner;
  protected
    function  Clone(Recursive: Boolean = True): IXMLDocument;
    function  CreateAttribute(const name: string): IXMLAttribute;
    function  createAttributeNS(const namespaceURI, qualifiedName: string): IXMLAttribute;
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
    function  Get_Schemas: IXMLSchemaCollection;
    function  Get_Url: string;
    function  Get_ValidateOnParse: Boolean;
    function  getElementById(const elementId: string): IXMLElement;
    function  GetElementsByTagName(const tagName: string): IXMLNodeList;
    function  getElementsByTagNameNS(const namespaceURI, localName: string): IXMLNodeList;
    function  GetErrors: IXMLErrors;
    function  GetXSLTErrors: IXSLTErrors;
    function  importNode(const node: IXMLNode; deep: Boolean): IXMLNode;
    function  NodeFromID(const IdString: string): IXMLNode;
    procedure Save(const Url: string); overload;
    procedure Set_documentElement(const Element: IXMLElement);
    procedure Set_PreserveWhiteSpace(IsPreserving: Boolean);
    procedure Set_ResolveExternals(IsResolving: Boolean);
    procedure Set_Schemas(const Value: IXMLSchemaCollection);
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
    var Ns := TXMLNode(Node._private).NodePtr.nsDef;
    while Ns <> nil do
    begin
      if Ns._private <> nil then
        TXMLNsNode(Ns._private).NsPtr := nil;
      Ns := Ns.next;
    end;
    TXMLNode(Node._private).NodePtr := nil;
  end;
end;

 procedure XSLTErrorHandler(Context: Pointer; const Msg: string);
 begin
   TXMLDocument(Context).XSLTError(Msg);
 end;

procedure CheckNotNode(const Node: IXMLNode);
begin
  if (Node <> nil) and not (TObject(Node) is TXMLNode) then
    raise EXmlUnsupported.CreateResFmt(@SUnsupportedBy, [NodeTypeName(xmlElementType(Node.NodeType))]);
end;

procedure ResolveUnlinked(Parent: xmlNodePtr; Node: TXMLNode);
var
  Ns: xmlNsPtr;
begin
  if not (Node is TXMLAttribute) then
    Exit;

  var Attr := TXMLAttribute(Node);

  if Attr.Unlinked then
  begin
    if (Attr.UnlinkedPrefix <> '') or (Attr.UnlinkedURI = '') then
      Ns := xmlSearchNs(Parent.doc, Parent, xmlCharPtr(Attr.UnlinkedPrefix))
    else if (Attr.UnlinkedPrefix = '') or (Attr.UnlinkedURI <> '') then
      Ns := xmlSearchNsByHref(Parent.doc, Parent, xmlCharPtr(Attr.UnlinkedURI))
    else
    begin
      Ns := xmlSearchNs(Parent.doc, Parent, xmlCharPtr(Attr.UnlinkedPrefix));
      if (Ns <> nil) and not xmlStrSame(xmlCharPtr(Attr.UnlinkedURI), xmlCharPtr(ns.href)) then
        Ns := nil;
    end;
    if Ns = nil then
      Ns := xmlNewNs(Parent, xmlCharPtr(Attr.UnlinkedURI), xmlCharPtr(Attr.UnlinkedPrefix));

    xmlSetNs(Node.NodePtr, ns);

    Attr.Unlinked := False;
  end;
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
    Result := TXMLAttribute(Attr._private);

end;

function Cast(const Attr: xmlAttrPtr; const Prefix, NamespaceURI: RawByteString): TXMLAttribute; overload;
begin
  if Attr = nil then
    Result := nil
  else if Attr._private = nil then
    Result := TXMLAttribute.Create(Attr)
  else
    Result := TXMLAttribute(Attr._private);
  Result.Unlinked := (Prefix <> '') or (NamespaceURI <> '');
  Result.UnlinkedPrefix := Prefix;
  Result.UnlinkedURI := NamespaceURI;
end;

function Cast(const Ns: xmlNsPtr; Parent: xmlNodePtr): TXMLNsAttribute; overload;
begin
  if Ns = nil then
    Result := nil
  else if Ns._private = nil then
    Result := TXMLNsAttribute.Create(Ns, Parent)
  else
    Result := TXMLNsAttribute(Ns._private);
end;

function xmlUnlinkNs(var List: xmlNsPtr; Ns: xmlNsPtr): Boolean;
begin
  if Ns = nil then
    Exit(False);

  if List = Ns then
  begin
    List := Ns.next;
    Ns.next := nil;
    Exit(True);
  end
  else
  begin
    var Cur := List;
    while Cur.next <> Ns do
      Cur := Cur.next;

    if Cur <> nil then
    begin
      Cur.next := Ns.next;
      Ns.next := nil;
      Exit(True);
    end;
  end;
  Result := False;
end;

procedure xmlRemoveNsDef(Node: xmlNodePtr; Ns: xmlNsPtr);
begin
  if not xmlUnlinkNs(Node.nsDef, Ns) then
    Exit;

  Ns.next := nil;
  Ns.context := nil;

  var Child := Node;
  while Child <> nil do
  begin
    xmlUnlinkNs(Child.ns, Ns);
    Child := Child.GetNext(Node);
  end;
end;

procedure xmlAppendNsDef(Node: xmlNodePtr; Ns: xmlNsPtr);
begin
  if Node.nsDef = nil then
  begin
    Node.nsDef := Ns;
  end
  else
  begin
    var Cur := Node.nsDef;
    while Cur.next <> nil do
      Cur := Cur.next;
    Cur.next := Ns;
  end;
  Ns.context := Node.doc;

  if (Ns._private <> nil) then
    TXMLNsNode(Ns._private).Parent := Node;
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

function TXMLCustomNamedNodeMap.getNamedItemNS(const namespaceURI, localName: string): IXMLNode;
begin
  Result := Cast(FindQualifiedItem(localName, namespaceURI));
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

function TXMLCustomNamedNodeMap.removeNamedItemNS(const namespaceURI, localName: string): IXMLNode;
begin
  RemoveQualifiedItem(localName, namespaceURI);
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

  CheckNotNode(NewItem);

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

  Result := Cast(InsertNode(NewNode, nil));
end;

function TXMLCustomNamedNodeMap.setNamedItemNS(const NewItem: IXMLNode): IXMLNode;
begin
  Result := setNamedItem(NewItem);
end;

{ TXMLNodeNamedNodeMap }

constructor TXMLNodeNamedNodeMap.Create(const Parent: xmlNodePtr);
begin
  inherited Create;
  FParent := Parent;
end;

function TXMLNodeNamedNodeMap.InsertNode(NewNode, AfterNode: xmlNodePtr): xmlNodePtr;
begin
  if AfterNode = nil then
    Result := xmlAddChild(Parent, NewNode)
  else
    Result := xmlAddNextSibling(NewNode, AfterNode);

  if Result <> nil then
    xmlReconciliateNs(Result.doc, Result);
end;

{ TXMLAttributeList.TEnumerator }

constructor TXMLAttributeList.TEnumerator.Create(Parent: xmlNodePtr);
begin
  inherited Create;
  FParent := Parent;
  FState := esStart;
  FCurrent := nil;
end;

function TXMLAttributeList.TEnumerator.GetCurrent: IXMLNode;
begin
  case FState of
    esStart: Result := nil;
    esNs:    Result := Cast(xmlNsPtr(FCurrent), FParent);
    esAttr:  Result := Cast(xmlAttrPtr(FCurrent));
  end;
end;

function TXMLAttributeList.TEnumerator.MoveNext: Boolean;
begin
  if FState = esStart then
  begin
    if FParent.nsDef <> nil then
    begin
      FCurrent := FParent.nsDef;
      FState := esNs;
    end
    else
    begin
      FCurrent := FParent.properties;
      FState := esAttr;
    end;
  end
  else if FState = esAttr then
    FCurrent := xmlAttrPtr(FCurrent).next
  else
    FCurrent := xmlNsPtr(FCurrent).next;

  Result := FCurrent <> nil;
end;

procedure TXMLAttributeList.TEnumerator.Reset;
begin
  FState := esStart;
end;

{ TXMLAttributeList }

constructor TXMLAttributeList.Create(const Parent: xmlNodePtr);
begin
  inherited Create;
  FParent := Parent;
  FEnum := TEnumerator.Create(Parent);
end;

destructor TXMLAttributeList.Destroy;
begin
  FreeAndNil(FEnum);
  inherited;
end;

function TXMLAttributeList.GetEnumerator: IXMLEnumerator;
begin
  Result := TXMLAttributeList.TEnumerator.Create(Parent);
end;

function TXMLAttributeList.FindNs(const Name: string): xmlNsPtr;
var
  Prefix, LocalName: RawByteString;
begin
  if SplitXMLName(Utf8Encode(Name), Prefix, LocalName) then
  begin
    if Prefix = 'xmlns' then
    begin
      var Ns := Parent.nsDef;
      while Ns <> nil do
      begin
        if xmlStrSame(Pointer(LocalName), Ns.prefix) then
          Exit(Ns);

        Ns := Ns.next;
      end;
    end;
  end
  else if LocalName = 'xmlns' then
  begin
    var Ns := Parent.nsDef;
    while Ns <> nil do
    begin
      if Ns.prefix = nil then
        Exit(Ns);

      Ns := Ns.next;
    end;
  end;
  Result := nil;
end;

function TXMLAttributeList.FindQNs(const BaseName, namespaceURI: string): xmlNsPtr;
begin
  var Name := UTF8Encode(BaseName);
  var URI := UTF8Encode(namespaceURI);
  if BaseName = 'xmlns' then
  begin
    var Ns := Parent.nsDef;
    while Ns <> nil do
    begin
      if (Ns.prefix = nil) and xmlStrSame(Pointer(URI), Ns.href) then
        Exit(Ns);

      Ns := Ns.next;
    end;
    Exit(nil);
  end;

  var Ns := Parent.nsDef;
  while Ns <> nil do
  begin
    if xmlStrSame(Pointer(Name), Ns.prefix) and xmlStrSame(Pointer(URI), Ns.href) then
      Exit(Ns);

    Ns := Ns.next;
  end;

  Result := nil;
end;

function TXMLAttributeList.FindAttr(const Name: string): xmlAttrPtr;
var
  Prefix, LocalName: RawByteString;
begin
  if SplitXMLName(Utf8Encode(Name), Prefix, LocalName) then
  begin
    var Attr := Parent.properties;
    while Attr <> nil do
    begin
      if (Attr.ns <> nil) and xmlStrSame(Attr.ns.prefix, Pointer(Prefix)) and xmlStrSame(Attr.name, Pointer(LocalName)) then
        Exit(Attr);

      Attr := Attr.next;
    end;
  end
  else
  begin
    var Attr := Parent.properties;
    while Attr <> nil do
    begin
      if (Attr.ns = nil) and xmlStrSame(Attr.name, Pointer(LocalName)) then
        Exit(Attr);

      Attr := Attr.next;
    end;
  end;
  Result := nil;
end;

function TXMLAttributeList.FindQAttr(const BaseName, namespaceURI: string): xmlAttrPtr;
begin
  var Name := UTF8Encode(BaseName);
  var URI := UTF8Encode(namespaceURI);

  var Prop := Parent.properties;
  while Prop <> nil do
  begin
    if (Prop.ns <> nil) and xmlStrSame(Pointer(Name), Prop.name) and xmlStrSame(Pointer(URI), Prop.ns.href) then
      Exit(Prop);

    Prop := Prop.next;
  end;

  Result := nil;
end;

function TXMLAttributeList.GetNamedItem(const Name: string): IXMLNode;
begin
  var Ns := FindNs(Name);
  if Ns <> nil then
    Exit(Cast(Ns, Parent));

  var Attr := FindAttr(Name);
  if Attr <> nil then
    Exit(Cast(Attr));

  Result := nil;
end;

function TXMLAttributeList.getNamedItemNS(const namespaceURI, localName: string): IXMLNode;
begin
  Result := GetQualifiedItem(localName, namespaceURI);
end;

function TXMLAttributeList.GetQualifiedItem(const BaseName, namespaceURI: string): IXMLNode;
begin
  var Ns := FindQNs(BaseName, namespaceURI);
  if Ns <> nil then
    Exit(Cast(Ns, Parent));

  var Attr := FindQAttr(BaseName, namespaceURI);
  if Attr <> nil then
    Exit(Cast(Attr));

  Result := nil;
end;

function TXMLAttributeList.Get_Item(Index: NativeInt): IXMLNode;
begin
  var I := 0;
  var Ns := Parent.nsDef;
  while Ns <> nil do
  begin
    if I = Index then
      Exit(Cast(Ns, Parent));

    Inc(I);
    Ns := Ns.next;
  end;

  var Prop := Parent.properties;
  while Prop <> nil do
  begin
    if I = Index then
      Exit(Cast(Prop));

    Inc(I);
    Prop := Prop.next;
  end;
end;

function TXMLAttributeList.Get_Length: NativeInt;
begin
  Result := 0;
  var Ns := Parent.nsDef;
  while Ns <> nil do
  begin
    Inc(Result);
    Ns := Ns.next;
  end;

  var Prop := Parent.properties;
  while Prop <> nil do
  begin
    Inc(Result);
    Prop := Prop.next;
  end;
end;

function TXMLAttributeList.NextNode: IXMLNode;
begin
  if FEnum.MoveNext then
    Result := FEnum.GetCurrent
  else
    Result := nil;
end;

function TXMLAttributeList.RemoveNamedItem(const Name: string): IXMLNode;
begin
  var Ns := FindNs(Name);
  if Ns <> nil then
  begin
    xmlRemoveNsDef(Parent, ns);
    Exit(Cast(ns, Parent));
  end;

  var Attr := FindAttr(Name);
  if Attr <> nil then
  begin
    xmlUnlinkNode(xmlNodePtr(Attr));
    Exit(Cast(Attr));
  end;

  Result := nil;
end;

function TXMLAttributeList.removeNamedItemNS(const namespaceURI, localName: string): IXMLNode;
begin
  Result := RemoveQualifiedItem(localName, namespaceURI);
end;

function TXMLAttributeList.RemoveQualifiedItem(const BaseName, namespaceURI: string): IXMLNode;
begin
  var Ns := FindQNs(BaseName, namespaceURI);
  if Ns <> nil then
  begin
    xmlRemoveNsDef(Parent, ns);
    Exit(Cast(ns, Parent));
  end;

  var Attr := FindQAttr(BaseName, namespaceURI);
  if Attr <> nil then
  begin
    xmlUnlinkNode(xmlNodePtr(Attr));
    Exit(Cast(Attr));
  end;

  Result := nil;
end;

procedure TXMLAttributeList.Reset;
begin
  FEnum.Reset;
end;

function TXMLAttributeList.SetNamedItem(const NewItem: IXMLNode): IXMLNode;
begin
  var Obj := TObject(NewItem);

  if Obj is TXMLNsNode then
  begin
    xmlAppendNsDef(Parent, TXMLNsNode(Obj).NsPtr);
    Result := Cast(TXMLNsNode(Obj).NsPtr, Parent);
  end
  else if Obj is TXMLAttribute then
  begin
    var Attr := TXMLAttribute(Obj);
    ResolveUnlinked(Parent, Attr);
    var Child := xmlAddChild(Parent, xmlNodePtr(Attr.AttrPtr));
    if Child <> nil then
      xmlReconciliateNs(Child.doc, Child);
    Result := Cast(Child);
  end
  else
    Result := nil;
end;

function TXMLAttributeList.setNamedItemNS(const NewItem: IXMLNode): IXMLNode;
begin
  Result := SetNamedItem(NewItem);
end;

function TXMLAttributeList.ToArray: TArray<IXmlNode>;
begin
  var Capacity := 16;
  SetLength(Result, Capacity);

  var Count := 0;
  var Ns := Parent.nsDef;
  while Ns <> nil do
  begin
    if Count = Capacity then
    begin
      Capacity := Capacity shl 1;
      SetLength(Result, Capacity);
    end;
    Result[Count] := Cast(Ns, Parent);

    Inc(Count);

    Ns := Ns.next;
  end;

  var Prop := Parent.properties;
  while Prop <> nil do
  begin
    if Count = Capacity then
    begin
      Capacity := Capacity shl 1;
      SetLength(Result, Capacity);
    end;
    Result[Count] := Cast(Prop);

    Inc(Count);

    Prop := Prop.next;
  end;

  SetLength(Result, Count);
end;

{ TXMLAttributes.TEnumerator }

function TXMLAttributes.TEnumerator.GetCurrent: IXMLAttribute;
begin
  Result := inherited GetCurrent as IXMLAttribute;
end;

{ TXMLAttributes }

function TXMLAttributes.GetEnumerator: IXMLAttributesEnumerator;
begin
  Result := TEnumerator.Create(Parent);
end;

function TXMLAttributes.Get_Attr(Index: NativeInt): IXmlAttribute;
begin
  Result := Get_Item(Index) as IXmlAttribute;
end;

function TXMLAttributes.NextNode: IXMLAttribute;
begin
  Result := NextNode as IXmlAttribute;
end;

function TXMLAttributes.ToArray: TArray<IXmlAttribute>;
begin
  var Capacity := 16;
  SetLength(Result, Capacity);

  var Count := 0;
  var Ns := Parent.nsDef;
  while Ns <> nil do
  begin
    if Count = Capacity then
    begin
      Capacity := Capacity shl 1;
      SetLength(Result, Capacity);
    end;
    Result[Count] := Cast(Ns, Parent);

    Inc(Count);

    Ns := Ns.next;
  end;

  var Prop := Parent.properties;
  while Prop <> nil do
  begin
    if Count = Capacity then
    begin
      Capacity := Capacity shl 1;
      SetLength(Result, Capacity);
    end;
    Result[Count] := Cast(Prop);

    Inc(Count);

    Prop := Prop.next;
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

constructor TXMLElementList.Create(Parent: xmlNodePtr; Recursive: Boolean; const Mask, NamespaceURI: string);
begin
  inherited Create(Parent);
  FRecursive := Recursive;
  FMask := Mask;
  FUseMask := not ((Mask = '*') or (Mask = ''));
  FNamespaceURI := NamespaceURI;
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
  Prefix, LocalName, URI: RawByteString;
begin
  Result := nil;
  URI := UTF8Encode(NamespaceURI);
  if SplitXMLName(UTF8Encode(Name), Prefix, LocalName) then
  begin
    var Enum := TEnumerator.Create(Self);
    while Enum.MoveNext do
    begin
      var Node := Enum.FCurrent;
      if ((Node.ns <> nil) and xmlStrSame(Node.ns.prefix, Pointer(Prefix)))
        and ((URI = '') or xmlStrSame(Node.ns.href, Pointer(URI)))
        and xmlStrSame(Node.Name, Pointer(LocalName)) then
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
      if xmlStrSame(Node.Name, Pointer(LocalName)) and ((URI = '') or xmlStrSame(Node.ns.href, Pointer(URI))) then
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
  if TObject(NewChild) is TXMLNsNode then
  begin
    xmlSetNs(NodePtr, TXMLNsNode(NewChild).NsPtr);
    Result := NewChild;
  end
  else
  begin
    var NewNode := TXMLNode(NewChild);
    if NewNode.NodePtr.doc = NodePtr.doc then
    begin
      ResolveUnlinked(NodePtr, NewNode);
      // xmlAddChild can merge nodes, then Old can be freed
      Result := Cast(NodePtr.AppendChild(NewNode.NodePtr));
    end
    else
    begin
      if xmlDOMWrapAdoptNode(nil, nil, NewNode.NodePtr, NodePtr.doc, NodePtr, 0)  = 0 then
        Result := Cast(NodePtr.AppendChild(NewNode.NodePtr))
      else
        Result := nil;
    end;
  end;
end;

function TXMLNode.InsertBefore(const NewChild: IXMLNode; RefChild: IXMLNode): IXMLNode;
begin
  if TObject(NewChild) is TXMLNsNode then
  begin
    xmlSetNs(NodePtr, TXMLNsNode(NewChild).NsPtr);
    Result := NewChild;
  end
  else
  begin
    ResolveUnlinked(NodePtr, TXMLNode(NewChild));
    var NewNode := NodePtr.InsertBefore(TXMLNode(NewChild).NodePtr, TXMLNode(RefChild).NodePtr);
    Result := Cast(NewNode);
  end;
end;

procedure TXMLNode.Normalize;
begin
  //TODO: We always normalized?
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

function TXMLNode.HasAttributes: Boolean;
begin
  Result := (NodePtr.nsDef <> nil) or (NodePtr.properties <> nil);
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
    raise EXmlUnsupported.CreateResFmt(@SUnsupportedBy, [NodeTypeName(NodePtr.&type)]);
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

function TXMLAttribute.Get_OwnerElement: IXMLElement;
begin
  var Parent := AttrPtr.parent;
  while (Parent <> nil) and (Parent.&type <> XML_ELEMENT_NODE) do
    Parent := Parent.parent;

  Result := Cast(Parent) as IXMLElement;
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

function TXMLElement.AddChild(const Name: string; const Content: string = ''): IXMLElement;
begin
  Result := Cast(NodePtr.AddChild(xmlCharPtr(Utf8Encode(Name)), xmlCharPtr(Utf8Encode(Content)))) as IXMLElement;
end;

function TXMLElement.AddChildNs(const Name, NamespaceURI: string; const Content: string = ''): IXMLElement;
begin
  Result := Cast(NodePtr.AddChildNs(xmlCharPtr(Utf8Encode(Name)), xmlCharPtr(Utf8Encode(NamespaceURI)), xmlCharPtr(Utf8Encode(Content)))) as IXMLElement;
end;

function TXMLElement.FirstChildElement: IXMLElement;
begin
  Result := Cast(xmlFirstElementChild(NodePtr)) as IXMLElement;
end;

function TXMLElement.LastChildElement: IXMLElement;
begin
  Result := Cast(xmlLastElementChild(NodePtr)) as IXMLElement;
end;

function TXMLElement.NextSiblingElement: IXMLElement;
begin
  Result := Cast(xmlNextElementSibling(NodePtr)) as IXMLElement;
end;

function TXMLElement.PreviousSiblingElement: IXMLElement;
begin
  Result := Cast(xmlPreviousElementSibling(NodePtr)) as IXMLElement;
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
  NodePtr.SetAttribute(Utf8Encode(Name), Utf8Encode(Value));
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
var
 Prefix, LocalName: RawByteString;
begin
  if SplitXMLName(UTF8Encode(Name), Prefix, LocalName) then
  begin
    if Prefix = 'xmlns' then
      Result := Cast(xmlNewNs(nil, nil, xmlCharPtr(LocalName)), nil)
    else
      Result := Cast(xmlNewDocProp(xmlDocPtr(NodePtr), xmlStrPtr(Utf8Encode(LocalName)), nil), Prefix, '');
  end
  else if Name = 'xmlns' then
    Result := Cast(xmlNewNs(nil, '', nil), nil)
  else
    Result := Cast(xmlNewDocProp(xmlDocPtr(NodePtr), xmlCharPtr(LocalName), nil));
end;

function TXMLDocument.createAttributeNS(const namespaceURI, qualifiedName: string): IXMLAttribute;
var
 Prefix, LocalName: RawByteString;
begin
  if SplitXMLName(UTF8Encode(qualifiedName), Prefix, LocalName) then
  begin
    if Prefix = 'xmlns' then
      Result := Cast(xmlNewNs(nil, xmlStrPtr(Utf8Encode(namespaceURI)), xmlStrPtr(Utf8Encode(LocalName))), nil)
    else
      Result := Cast(xmlNewDocProp(xmlDocPtr(NodePtr), xmlStrPtr(LocalName), nil), Utf8Encode(Prefix), Utf8Encode(namespaceURI));
  end
  else if LocalName = 'xmlns' then
    Result := Cast(xmlNewNs(nil, xmlStrPtr(Utf8Encode(namespaceURI)), nil), nil)
  else
    Result := Cast(xmlNewDocProp(xmlDocPtr(NodePtr), xmlStrPtr(LocalName), nil), Utf8Encode(Prefix), Utf8Encode(namespaceURI));
end;

function TXMLDocument.CreateCDATASection(const Data: string): IXMLCDATASection;
begin
  var S := Utf8Encode(Data);
  var L := Length(Data);

  Result := Cast(xmlNewCDataBlock(xmlDocPtr(NodePtr), xmlStrPtr(S), L)) as IXMLCDATASection;
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
  CheckNotNode(Parent);
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
  begin
    SplitXMLName(Utf8Encode(Name), Prefix, LocalName);
    HRef := '';
  end;

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

function TXMLDocument.getElementById(const elementId: string): IXMLElement;
begin
  var Attr := xmlGetID(xmlDocPtr(NodePtr), xmlStrPtr(Utf8Encode(elementId)));
  if (Attr = nil) or (Attr.parent = nil) then
    Exit(nil);

  Result := Cast(Attr.parent) as IXMLElement;
end;

function TXMLDocument.getElementsByTagName(const TagName: string): IXMLNodeList;
begin
  if xmlDocPtr(NodePtr).documentElement = nil  then
    Exit(nil);

  Result := TXMLElementList.Create(xmlDocPtr(NodePtr).documentElement, True, TagName);
end;

function TXMLDocument.getElementsByTagNameNS(const namespaceURI, localName: string): IXMLNodeList;
begin
  if xmlDocPtr(NodePtr).documentElement = nil  then
    Exit(nil);

  Result := TXMLElementList.Create(xmlDocPtr(NodePtr).documentElement, True, localName, namespaceURI);
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

function TXMLDocument.Get_Schemas: IXMLSchemaCollection;
begin
  Result := FSchemas;
end;

function TXMLDocument.Get_Url: string;
begin
  Result := Utf8ToUnicodeString(xmlDocPtr(NodePtr).URL);
end;

function TXMLDocument.Get_ValidateOnParse: Boolean;
begin
  Result := FValidateOnParse;
end;

function TXMLDocument.importNode(const node: IXMLNode; deep: Boolean): IXMLNode;
begin
  Result := node.cloneNode(deep);
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
  if Result and FValidateOnParse and (FSchemas <> nil) then
    Result := FSchemas.Validate(Self);
end;

function TXMLDocument.Load(const Data: TBytes): Boolean;
begin
  Result := SetNewDoc(xmlDoc.Create(Data, Options, ErrorCallback)) <> nil;
  if Result and FValidateOnParse and (FSchemas <> nil) then
    Result := FSchemas.Validate(Self);
end;

function TXMLDocument.Load(const Data: Pointer; Size: NativeUInt): Boolean;
begin
  Result := SetNewDoc(xmlDoc.Create(Data, Size, Options, ErrorCallback)) <> nil;
  if Result and FValidateOnParse and (FSchemas <> nil) then
    Result := FSchemas.Validate(Self);
end;

function TXMLDocument.Load(Stream: TStream; const Encoding: Utf8String): Boolean;
begin
  Result := SetNewDoc(xmlDoc.Create(Stream, Options, Encoding, ErrorCallback)) <> nil;
  if Result and FValidateOnParse and (FSchemas <> nil) then
    Result := FSchemas.Validate(Self);
end;

function TXMLDocument.LoadXML(const XML: string; const Options: TXmlParserOptions): Boolean;
begin
  Result := SetNewDoc(xmlDoc.Create(XML, Options, ErrorCallback)) <> nil;
  if Result and FValidateOnParse and (FSchemas <> nil) then
    Result := FSchemas.Validate(Self);
end;

function TXMLDocument.LoadXML(const XML: RawByteString; const Options: TXmlParserOptions): Boolean;
begin
  Result := SetNewDoc(xmlDoc.Create(XML, Options, ErrorCallback)) <> nil;
  if Result and FValidateOnParse and (FSchemas <> nil) then
    Result := FSchemas.Validate(Self);
end;

function TXMLDocument.NodeFromID(const IdString: string): IXMLNode;
begin
  var Attr := xmlGetID(xmlDocPtr(NodePtr), xmlCharPtr(Utf8Encode(IdString)));
  if Attr = nil then
    Exit(nil);

  Result := Cast(Attr.Parent);
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

procedure TXMLDocument.Set_Schemas(const Value: IXMLSchemaCollection);
begin
  FSchemas := Value;
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

  if FSchemas <> nil then
    xmlDocPtr(NodePtr).Validate(ErrorCallback, TXMLSchemaCollection(FSchemas).ResourceLoader)
  else
    xmlDocPtr(NodePtr).Validate(ErrorCallback);

  if Errors.Count = 0 then
    Exit(FSuccessError)
  else
    Result := Errors.MainError;
end;

function TXMLDocument.ValidateNode(const Node: IXMLNode): IXMLParseError;
begin
  CheckNotNode(Node);

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

{ TXMLSchemaCollection.TItems }

function TXMLSchemaCollection.TItems.Add(const NamespaceURI, URL: string; const Doc: IXMLDocument): TItem;
begin
  Result := TItem.Create;
  Result.NamespaceURI := NamespaceURI;
  Result.URL := URL;
  Result.Doc := Doc;

  inherited Add(Result);
end;

function TXMLSchemaCollection.TItems.IndexOfURL(const URL: string): NativeInt;
begin
  for var I := 0 to Count - 1 do
    if AnsiSameText(List[I].URL, URL) then
      Exit(I);

  Result := -1;
end;

function TXMLSchemaCollection.TSchemas.Add(const NamespaceURI: string; const Doc: IXMLDocument): TSchema;
begin
  Result := TSchema.Create;
  Result.NamespaceURI := NamespaceURI;
  Result.Doc := Doc;

  inherited Add(Result);
end;

{ TXMLSchemaCollection }

procedure SchemaParserErrorCallback(userData: Pointer; const error: xmlErrorPtr); cdecl;
begin
  try
    var Err := TXMLError.Create(TXmlParseError.Create(error^));
    TXMLDocument(userData).Errors.FList.Add(Err as IXMLParseError);
  except
    // No exception, becouse libxml2 is plain c, without try catch
  end;
end;

constructor TXMLSchemaCollection.Create;
begin
  inherited Create;
  FErrors := TXMLErrors.Create;
  FItems := TItems.Create(True);
  FSchemas := TSchemas.Create(True);
end;

destructor TXMLSchemaCollection.Destroy;
begin
  FreeAndNil(FItems);
  FreeAndNil(FSchemas);
  FreeAndNil(FErrors);
  inherited;
end;

function TXMLSchemaCollection.ResourceLoader(const url: xmlCharPtr; const publicId: xmlCharPtr; resType: xmlResourceType; Flags: Integer; var output: xmlParserInputPtr): Integer;
begin
  Result := Ord(XML_IO_ENOENT);
end;

procedure TXMLSchemaCollection.AddCollection(const otherCollection: IXMLSchemaCollection);
begin
  var Src := TXMLSchemaCollection(otherCollection);
  for var I := 0 to Src.Items.Count - 1 do
  begin
    var Item := Src.Items[I];
    Add(Item.NamespaceURI, Item.Doc);
  end;
end;

procedure TXMLSchemaCollection.Parse;
begin

end;

procedure TXMLSchemaCollection.ImportNode(Node: IXMLElement; const Location, TargetNamespace: string; const Resolver: IXMLResolver);
begin
  var URI := Node.GetAttribute('namespace');
  if URI = '' then
    URI := TargetNamespace;

  var Index := Items.IndexOfURL(Location);
  if (Index < 0) and (Resolver <> nil) then
  begin
    var Data := Resolver.Resolve(Location);
    if System.Length(Data) > 0 then
    begin
      var Include := TXMLDocument.Create as IXMLDocument;
      if Include.Load(Data) then
        Add(URI, Include);
    end;
  end;
end;

procedure TXMLSchemaCollection.IncludeNode(Node: IXMLNode; const Location, TargetNamespace: string; const Resolver: IXMLResolver);
begin
  var Index := Items.IndexOfURL(Location);
  if (Index < 0) and (Resolver <> nil) then
  begin
    var Data := Resolver.Resolve(Location);
    if System.Length(Data) > 0 then
    begin
      var Include := TXMLDocument.Create as IXMLDocument;
      if Include.Load(Data) then
        Add(TargetNamespace, Include);
    end;
  end;
end;

procedure TXMLSchemaCollection.Add(const NamespaceURI: string; const Doc: IXMLDocument; const Resolver: IXMLResolver);
var
  URI: string;
begin
  URI := xmlNormalizeString(NamespaceURI);

  Items.Add(URI, '', Doc);

  var Index := IndexOf(URI);

  if Index < 0 then
  begin
    FSchemas.Add(URI, Doc);
  end
  else
  begin
    var Item := Items[Index];
    var Node := Doc.DocumentElement.FirstChildElement;
    while Node <> nil do
    begin
      // Try load imports via Resolver, if not succesful - just ignore, like MSXML do
      if (Node.NamespaceURI = cSchemaNs) and (Node.LocalName = cImport) then
      begin
        var Location := Node.GetAttribute('schemaLocation');
        if Location <> '' then
          ImportNode(Node, Location, NamespaceURI, Resolver);
      end
      else if (Node.NamespaceURI = cSchemaNs) and (Node.LocalName = cInclude) then
      begin
        var Location := Node.GetAttribute('schemaLocation');
        if Location <> '' then
          IncludeNode(Node, Location, NamespaceURI, Resolver);
      end
      else
      begin
        Item.Doc.DocumentElement.AppendChild(Node.CloneNode(True));
      end;
      Node := Node.NextSiblingElement;
    end;
  end;
end;

function TXMLSchemaCollection.Get(const NamespaceURI: string): IXMLDocument;
begin
  var Index := IndexOf(xmlNormalizeString(NamespaceURI));
  if Index < 0 then
    Result := nil
  else
    Result := Schemas[Index].Doc;
end;

function TXMLSchemaCollection.Get_Length: NativeInt;
begin
  Result := Schemas.Count;
end;

function TXMLSchemaCollection.Get_NamespaceURI(Index: NativeInt): string;
begin
  Result := Schemas[Index].NamespaceURI;
end;

function TXMLSchemaCollection.IndexOf(const NamespaceURI: string): NativeInt;
var
  URI: string;
begin
  URI := xmlNormalizeString(NamespaceURI);
  for var I := 0 to Schemas.Count - 1 do
    if AnsiSameText(Schemas[I].NamespaceURI, URI) then
      Exit(I);

  Result := -1;
end;

procedure TXMLSchemaCollection.Remove(const NamespaceURI: string);
begin
  var Index := IndexOf(NamespaceURI);
  if Index >= 0 then
    Schemas.Delete(Index);
end;

function TXMLSchemaCollection.Validate(const Doc: IXMLDocument): Boolean;
var
  rcb: TXmlResourceCallback;
  vctxt: xmlSchemaValidCtxtPtr;
begin
  Result := True;
  Doc.errors.clear;

  Parse;

  for var I := 0 to Schemas.Count - 1 do
  begin
    var ctxt := xmlSchemaNewDocParserCtxt(xmlDocPtr(TXMLDocument(Schemas[I].Doc).NodePtr));
    rcb.Handler := ResourceLoader;
    xmlSchemaSetResourceLoader(ctxt, xmlResourceLoaderCallback, @rcb);
    xmlSchemaSetParserStructuredErrors(ctxt, SchemaParserErrorCallback, TXmlDocument(Doc));

    var schema := xmlSchemaParse(ctxt);
    if schema = nil then
    begin
      xmlSchemaFreeParserCtxt(ctxt);
      Exit(False);
    end
    else
    begin
      vctxt := xmlSchemaNewValidCtxt(schema);
      if vctxt = nil then
      begin
        xmlSchemaFree(schema);
        xmlSchemaFreeParserCtxt(ctxt);
        Exit(False);
      end;
    end;

    xmlSchemaSetValidStructuredErrors(vctxt, SchemaParserErrorCallback, TXmlDocument(Doc));

    Result := xmlSchemaValidateDoc(vctxt, xmlDocPtr(TXMLDocument(Doc).NodePtr)) = 0;

    xmlSchemaFreeValidCtxt(vctxt);
    xmlSchemaFree(schema);
    xmlSchemaFreeParserCtxt(ctxt);

    if not Result then
      Break;
  end;
end;

{ TXMLNsNode }

constructor TXMLNsNode.Create(Ns: xmlNsPtr; Parent: xmlNodePtr);
begin
  inherited Create;
  Self.NsPtr := Ns;
  Self.NsPtr._private := Self;
  Self.Parent := Parent;
end;

destructor TXMLNsNode.Destroy;
begin
  if NsPtr <> nil then
  begin
    NsPtr._private := nil;
    if NsPtr.context = nil then
      xmlFreeNs(NsPtr);
  end;
  inherited;
end;

function TXMLNsNode.AppendChild(const NewChild: IXMLNode): IXMLNode;
begin
  raise EXmlUnsupported.CreateRes(@SUnsupportedByAttrDecl);
end;

function TXMLNsNode.CloneNode(Deep: WordBool): IXMLNode;
begin
  raise EXmlUnsupported.CreateRes(@SUnsupportedByAttrDecl);
end;

function TXMLNsNode.CloneTo(Deep: WordBool; Parent: IXMLNode): IXMLNode;
begin
  raise EXmlUnsupported.CreateRes(@SUnsupportedByAttrDecl);
end;

function TXMLNsNode.Get_Attributes: IXMLAttributes;
begin
  Result := nil;
end;

function TXMLNsNode.Get_BaseName: string;
begin
  Result := xmlCharToStr(NsPtr.prefix);
end;

function TXMLNsNode.Get_ChildNodes: IXMLNodeList;
begin
  Result := nil;
end;

function TXMLNsNode.Get_FirstChild: IXMLNode;
begin
  Result := nil;
end;

function TXMLNsNode.Get_LastChild: IXMLNode;
begin
  Result := nil;
end;

function TXMLNsNode.Get_NamespaceURI: string;
begin
  Result := xmlCharToStr(NsPtr.href);
end;

function TXMLNsNode.Get_NextSibling: IXMLNode;
begin
  if NsPtr.next <> nil then
    Result := Cast(NsPtr.next, Parent)
  else if Parent.properties <> nil then
    Result := Cast(Parent.properties)
  else
    Result := nil;
end;

function TXMLNsNode.Get_NodeName: string;
begin
  Result := 'xmlns:' + xmlCharToStr(NsPtr.prefix);
end;

function TXMLNsNode.Get_NodeType: DOMNodeType;
begin
  Result := NODE_ATTRIBUTE;
end;

function TXMLNsNode.Get_NodeValue: string;
begin
  Result := xmlCharToStr(NsPtr.href);
end;

function TXMLNsNode.Get_OwnerDocument: IXMLDocument;
begin
  if (NsPtr.context <> nil) and (NsPtr.context._private <> nil) then
    Result := TXMLDocument(NsPtr.context._private)
  else
    Result := nil;
end;

function TXMLNsNode.Get_ParentNode: IXMLNode;
begin
  Result := Cast(Parent);
end;

function TXMLNsNode.Get_Prefix: string;
begin
  Result := 'xmlns';
end;

function TXMLNsNode.Get_PreviousSibling: IXMLNode;
begin
  var Prop := Parent.nsDef;
  while Prop <> nil do
  begin
    if Prop.next = NsPtr then
      Exit(Cast(Prop, Parent));
  end;
  Result := nil;
end;

function TXMLNsNode.Get_Text: string;
begin
  Result := xmlCharToStr(NsPtr.href);
end;

function TXMLNsNode.Get_Xml: string;
begin
  Result := '';
end;

function TXMLNsNode.HasAttributes: Boolean;
begin
  Result := False;
end;

function TXMLNsNode.HasChildNodes: Boolean;
begin
  Result := False;
end;

function TXMLNsNode.InsertBefore(const NewChild: IXMLNode; RefChild: IXMLNode): IXMLNode;
begin
  raise EXmlUnsupported.CreateRes(@SUnsupportedByAttrDecl);
end;

procedure TXMLNsNode.Normalize;
begin

end;

procedure TXMLNsNode.ReconciliateNs;
begin

end;

function TXMLNsNode.RemoveChild(const ChildNode: IXMLNode): IXMLNode;
begin
  raise EXmlUnsupported.CreateRes(@SUnsupportedByAttrDecl);
end;

function TXMLNsNode.ReplaceChild(const NewChild, OldChild: IXMLNode): IXMLNode;
begin
  raise EXmlUnsupported.CreateRes(@SUnsupportedByAttrDecl);
end;

function TXMLNsNode.SelectNodes(const QueryString: string): IXMLNodeList;
begin
  Result := nil;
end;

function TXMLNsNode.SelectSingleNode(const QueryString: string): IXMLNode;
begin
  Result := nil;
end;

procedure TXMLNsNode.Set_NodeValue(const Value: string);
begin
  Set_Text(Value)
end;

procedure TXMLNsNode.Set_Text(const Text: string);
begin
  xmlFree(NsPtr.href);
  NsPtr.href := xmlStrdup(xmlCharPtr(Utf8Encode(Text)));
end;

{ TXMLNsAttribute }

function TXMLNsAttribute.Get_Name: string;
begin
  Result := NodeName;
end;

function TXMLNsAttribute.Get_OwnerElement: IXMLElement;
begin
  Result := Cast(Parent) as IXMLElement;
end;

function TXMLNsAttribute.Get_Value: string;
begin
  Result := NodeValue;
end;

procedure TXMLNsAttribute.Set_Value(const Value: string);
begin
  NodeValue := Value;
end;

{ TXMLSchemaCollection.TSchemas }

initialization
  GlobalLock := TObject.Create;

finalization
  FreeAndNil(GlobalLock);

end.
