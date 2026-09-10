/// <summary>
/// COM/IDispatch-compatible implementation of an MS XML DOM (MSXML2)-like API
/// (<c>IXMLDocument</c>, <c>IXMLNode</c>, <c>IXMLElement</c> and so on) over the
/// native libxml2 pointers (<c>xmlNodePtr</c>, <c>xmlDocPtr</c>, <c>xmlNsPtr</c>).
/// </summary>
/// <remarks>
/// <para>
/// <b>Ownership model (the key idea of the whole unit):</b> every libxml2 node
/// (<c>xmlNodePtr</c>) has a <c>_private: Pointer</c> field, used here to hold the back
/// reference to the Delphi wrapper (<c>TXMLNode</c> and descendants). This caches
/// "one xmlNodePtr, one Delphi wrapper": the <c>Cast(...)</c> functions (see below)
/// always check <c>Node._private</c> first and return the existing wrapper instead of
/// creating a new one. Without it, repeated calls such as <c>ParentNode.FirstChild</c>
/// would create a new managed object on every access.
/// </para>
/// <para>
/// <b>Mutual reference counting of the document and its nodes:</b> every
/// <c>TXMLNode</c> increments the refcount of its owning document on creation
/// (<c>TXMLDocument._AddRef</c>) and decrements it on destruction (<c>_Release</c>).
/// This guarantees that the document is not destroyed while at least one DOM object
/// referring to its nodes is alive, even when user code has lost every reference to the
/// `IXMLDocument` itself. Details are in the comments on <see cref="TXMLNode.Create"/>
/// and <see cref="TXMLNode.Destroy"/>.
/// </para>
/// <para>
/// <b>Global libxml2 node-deregister hook:</b> <see cref="NodeFreeCallback"/> is
/// registered once through <c>xmlDeregisterNodeDefault</c> and is invoked by libxml2
/// whenever libxml2 itself (rather than this wrapper) physically frees an
/// <c>xmlNodePtr</c>, for example when adjacent text nodes are merged inside
/// <c>xmlAddChild</c>. It keeps the Delphi wrapper from being left with a dangling
/// <c>NodePtr</c>.
/// </para>
/// </remarks>
unit LX2.DOM.Classes;

interface

uses
  System.Types, System.SysUtils, System.Classes, System.Generics.Collections,
  System.Rtti, RttiDispatch,
  libxml2.API, LX2.Types, LX2.Helpers, LX2.DOM;

type
  TXMLDocument = class;
  TXMLNode = class;

  {$M+}
  TXMLBaseClass = class of TXMLBase;

  TXMLBase = class(TDispatchInvokable)
  end;
  {$M-}

  TXMLError = class(TXMLBase, IXMLParseError)
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

  TXMLErrors = class(TDispatchInvokable, IXMLErrors)
  private type
    TEnumerator = class(TDispatchInvokable, IXMLErrorEnumerator)
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
  public
    function  Get_Count: NativeInt; inline;
    function  Get_Item(Index: NativeInt): IXMLParseError; inline;
    function  Get__newEnum: IXMLErrorEnumerator;
    function  Get_next: IXMLParseError;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Reset;
    function  MainError: IXMLParseError;
    function  GetEnumerator: IXMLErrorEnumerator;
    property  Count: NativeInt read Get_Count;
    property  Items[Index: NativeInt]: IXMLParseError read Get_Item; default;
  end;

  TXSLTError = class(TXMLBase, IXSLTError)
  private
    FReason: string;
  public
    function  Get_Reason: string;
  public
    constructor Create(const Reason: string);
    property  Reason: string read FReason;
  end;

  TXSLTErrors = class(TDispatchInvokable, IXSLTErrors)
  private type
    TEnumerator = class(TDispatchInvokable, IXSLTErrorEnumerator)
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
  public
    function  Get_Count: NativeInt; inline;
    function  Get_Item(Index: NativeInt): IXSLTError; inline;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function  GetEnumerator: IXSLTErrorEnumerator;
    property  Count: NativeInt read Get_Count;
    property  Items[Index: NativeInt]: IXSLTError read Get_Item; default;
  end;

  TXMLNodeEnumerator = class(TXMLBase, IXMLEnumerator)
  protected
    function  DoGetCurrent: xmlNodePtr; virtual; abstract;
    function  DoMoveNext: Boolean; virtual; abstract;
    function  Predicate(Node: xmlNodePtr): Boolean; virtual;
  public
    { IEnumerator }
    function  GetCurrent: IXMLNode;
  public
    procedure Reset; virtual; abstract;
    property  Current: IXMLNode read GetCurrent;
    function  MoveNext: Boolean;
  end;

  TXMLCustomNodeList = class(TXMLBase, IXMLNodeList)
  protected
    function  DoNextNode: xmlNodePtr; virtual; abstract;
    function  CreateEnumerator: TXMLNodeEnumerator; virtual; abstract;
  public
     { MSXMLDOMNodeList }
    function  Get_Item(Index: NativeInt): IXMLNode; virtual; abstract;
    function  Get_Length: NativeInt; virtual; abstract;
    function  NextNode: IXMLNode;
    procedure Reset; virtual; abstract;
    { Delphi enumerable }
    function  GetEnumerator: IXMLEnumerator;
    function  ToArray: TArray<IXMLNode>; virtual;
    property  Items[Index: NativeInt]: IXMLNode read Get_Item; default;
    property  Length: NativeInt read Get_Length;
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
  /// MSXML-compatible view of "all attributes of a node" as a single
  /// <c>IXMLNodeList</c>/<c>IXMLNamedNodeMap</c> collection, hiding the fact that in
  /// libxml2 these are physically TWO DIFFERENT linked lists of the node:
  /// <c>Node.nsDef</c> (namespace declarations, <c>xmlns:...</c>) and
  /// <c>Node.properties</c> (ordinary attributes).
  /// </summary>
  /// <remarks>
  /// The reason for the merge is the MSXML DOM semantics, where
  /// <c>xmlns:prefix="uri"</c> is treated as an ordinary attribute of the element
  /// (available through <c>Attributes.GetNamedItem('xmlns:prefix')</c>), whereas in the
  /// libxml2 model it is a separate, specialised <c>xmlNs</c> structure that is neither an
  /// <c>xmlAttrPtr</c> nor an <c>xmlNodePtr</c>. Practically EVERY method of this class
  /// (<see cref="Get_Item"/>, <see cref="Get_Length"/>, <see cref="ToArray"/> and the
  /// internal <see cref="TEnumerator"/>) carries the paired logic "walk the whole
  /// <c>nsDef</c> first, then the whole <c>properties</c>", so namespace declarations
  /// always come BEFORE ordinary attributes in indexing and enumeration order.
  /// </remarks>
  TXMLAttributeList = class(TXMLBase, IXMLNodeList, IXMLNamedNodeMap)
  protected type
    TEnumState = (esStart, esNs, esAttr);

    TEnumerator = class(TDispatchInvokable, IXMLEnumerator)
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
  public
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
    property  Item[index: NativeInt]: IXMLNode read Get_Item; default;
    property  Length: NativeInt read Get_Length;
  end;

  TXMLAttributes = class(TXMLAttributeList, IXMLAttributes)
  protected type
    TEnumerator = class(TXMLAttributeList.TEnumerator, IXMLAttributesEnumerator)
    public
      function  GetCurrent: IXMLAttribute;
    end;
  public
    function  Get_Attr(Index: NativeInt): IXmlAttribute;
  public
    { IXMLAttributes }
    function  NextNode: IXMLAttribute;
    property  Item[Index: NativeInt]: IXMLAttribute read Get_Attr; default;
    { Delphi enumerable }
    function  GetEnumerator: IXMLAttributesEnumerator;
    function  ToArray: TArray<IXmlAttribute>; reintroduce; overload;
  end;

  /// <summary>
  /// Implementation of <c>getElementsByTagName</c>/<c>getElementsByTagNameNS</c>: a
  /// "live" set of elements (computed lazily on every walk, not a cached list) filtered
  /// by tag name (<see cref="Mask"/>) and, optionally, walking either the direct
  /// children only or the whole subtree (<see cref="Recursive"/>).
  /// </summary>
  /// <remarks>
  /// <para>
  /// <b>Dispatch through <c>TMoveNext = function: Boolean of object</c>:</b> instead of
  /// branching on <c>if Recursive then ... if UseMask then ...</c> inside every
  /// <c>MoveNext</c> call (two condition checks per iteration step), the walk
  /// implementation (DoNextSibling/DoNextSiblingWithMask/DoNextRecursive/
  /// DoNextRecursiveWithMask) is chosen ONCE in the constructor and stored as the method
  /// pointer <c>FDoMoveNext</c>, which removes the conditional jumps from the hot path
  /// of enumeration. This matters most for <see cref="Get_Item"/>/<see cref="Get_Length"/>
  /// (see the performance warning below), which recreate the enumerator and walk it to
  /// the end on every call.
  /// </para>
  /// <para>
  /// ⚠ <b>Performance warning:</b> <see cref="Get_Item"/> and <see cref="Get_Length"/>
  /// perform a FULL walk of the document (sub)tree on EVERY call (recreating
  /// <see cref="TEnumerator"/> from scratch), because the result of the walk is not
  /// cached anywhere. The typical user loop
  /// <c>for I := 0 to List.Length - 1 do Process(List[I])</c> is therefore O(n²) in the
  /// size of the document instead of the expected O(n). Prefer enumeration through
  /// <c>for..in</c> (a single pass over the same <c>Enum.MoveNext</c>) or an explicit
  /// <see cref="ToArray"/> to indexed access in a loop.
  /// </para>
  /// </remarks>
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
    function  FindItem(const Name: string): xmlNodePtr; override;
    function  FindQualifiedItem(const BaseName: string; const NamespaceURI: string): xmlNodePtr; override;
    property  UseMask: Boolean read FUseMask;
  public
    constructor Create(Parent: xmlNodePtr; Recursive: Boolean; const Mask: string = '*'; const NamespaceURI: string = '');
    destructor Destroy; override;
    procedure Reset; override;
    function  Get_Item(Index: NativeInt): IXMLNode; override;
    function  Get_Length: NativeInt; override;
    property  Recursive: Boolean read FRecursive;
    property  Mask: string read FMask;
    property  NamespaceURI: string read FNamespaceURI;
  end;

  TXMLNode = class(TXMLBase, IXMLNode)
  private
    FXSLTErrors: TXSLTErrors;
    procedure XPathErrorHandler(const error: xmlError);
    procedure XSLTError(const Msg: string); virtual;
  public
    { IXMLNode }
    function  AppendChild(const NewChild: IXMLNode): IXMLNode;
    function  CloneNode(Deep: WordBool): IXMLNode;
    function  Get_Attributes: IXMLAttributes; virtual;
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
    function  GetXSLTErrors: IXSLTErrors;
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
    function  Transform(const stylesheet: IXMLDocument; out doc: IXMLDocument): Boolean; overload; virtual;
    function  Transform(const stylesheet: IXMLDocument; out S: RawByteString): Boolean; overload; virtual;
    function  Transform(const stylesheet: IXMLDocument; out S: string): Boolean; overload; virtual;
    function  Transform(const stylesheet: IXMLDocument; Stream: TStream): Boolean; overload; virtual;
    function  TransformNodeToObject(const stylesheet: IXMLDocument; const output: IXMLDocument): Boolean; virtual;
    function  TransformNodeToStream(const stylesheet: IXMLDocument; const output: TStream): Boolean; virtual;
    function  TransformNode(const stylesheet: IXMLDocument): string; virtual;
  protected
    NodePtr: xmlNodePtr;
    FOwnerDocRefTaken: Boolean;
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
    property  XSLTErrors: TXSLTErrors read FXSLTErrors;
  end;

  /// <summary>
  /// MS XML threats NS declartion as Node, while libxml2 does not so wee need handle this scpecial case
  /// </summary>
  TXMLNsNode = class(TXMLBase, IXMLNode)
  public
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
    function  Transform(const stylesheet: IXMLDocument; out doc: IXMLDocument): Boolean; overload;
    function  Transform(const stylesheet: IXMLDocument; out S: RawByteString): Boolean; overload;
    function  Transform(const stylesheet: IXMLDocument; out S: string): Boolean; overload;
    function  Transform(const stylesheet: IXMLDocument; Stream: TStream): Boolean; overload; virtual;
    function  TransformNodeToObject(const stylesheet: IXMLDocument; const output: IXMLDocument): Boolean;
    function  TransformNodeToStream(const stylesheet: IXMLDocument; const output: TStream): Boolean;
    function  TransformNode(const stylesheet: IXMLDocument): string;
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
  public
    destructor Destroy; override;
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
  public
    function  Get_Name: string;
    function  Get_OwnerElement: IXMLElement;
    function  Get_Value: string;
    /// <summary>
    /// Replaces the attribute value by rebuilding its list of child nodes
    /// (<c>AttrPtr.children</c>) from scratch: in the libxml2/DOM model the value of an
    /// attribute is stored not as a string field but as the single text node child of the
    /// attribute (the same way the value of a text element lives in its child text nodes).
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b>The order of the steps is not arbitrary:</b>
    /// <list type="number">
    /// <item><description>
    /// The new text node (<c>xmlNewDocText</c>) is created FIRST, BEFORE the old content
    /// is removed. Had <c>AttrPtr.children</c> been cleared first and the creation of the
    /// new node (theoretically) failed, the attribute would be left without a value
    /// instead of keeping the old one; the current order minimises the window in which
    /// the operation can end in an intermediate state.
    /// </description></item>
    /// <item><description>
    /// If the attribute was an ID attribute (<c>AttrPtr.atype = XML_ATTRIBUTE_ID</c>), it
    /// is removed from the document's ID index (<c>xmlRemoveID</c>) BEFORE the value
    /// changes: the ID index stores (value → node) pairs, and changing the value would
    /// leave a stale entry in the index unless it had been removed in advance.
    /// </description></item>
    /// <item><description>
    /// The old child list is freed as a whole (<c>xmlFreeNodeList</c>), although in the
    /// vast majority of cases it holds exactly one text node. This covers the rare but
    /// legal XML case where the attribute value consists of SEVERAL nodes (text plus
    /// entity references, for example <c>attr="&amp;amp;foo"</c>).
    /// </description></item>
    /// </list>
    /// </para>
    /// </remarks>
    procedure Set_Value(const attrValue: string);
    property  Name: string read Get_Name;
    property  Value: string read Get_Value write Set_value;
  public
    destructor Destroy; override;
  end;

  TXMLElement = class(TXMLNode, IXMLElement)
  public
    function  Get_Attributes: IXMLAttributes; override;
    function  GetAttribute(const Name: string): string;
    procedure SetAttribute(const Name: string; Value: string); overload;
    procedure SetAttribute(const Name: string; Value: Int64); overload;
    procedure SetAttribute(const Name: string; Value: Boolean); overload;
    procedure SetAttribute(const Name: string; Value: TDateTime); overload;
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

    function  NextElementSibling: IXMLElement;
    function  FirstElementChild: IXMLElement;
    function  LastElementChild: IXMLElement;
    function  PreviousElementSibling: IXMLElement;

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

  /// <summary>
  /// A set of XML Schema documents compiled into one libxml2 <c>xmlSchema</c>, modelled on
  /// <c>XmlSchemaSet</c> in .NET: schemas are registered as in-memory documents
  /// (<see cref="Add"/>), and the links between them are resolved by the collection, not by
  /// the file system.
  /// </summary>
  /// <remarks>
  /// <para>Rules for <c>xs:import</c>, <c>xs:include</c> and <c>xs:redefine</c> at compile time:</para>
  /// <list type="bullet">
  /// <item><description>An <c>xs:import</c> of a namespace registered in the collection leads
  /// to the collection's schema; its <c>schemaLocation</c> is ignored.</description></item>
  /// <item><description>Other locations are requested from the <see cref="IXMLResolver"/>
  /// passed along with the document, or, when the document was loaded from a file, read from
  /// disk relative to it. The document obtained is processed by the same rules.</description></item>
  /// <item><description>An unresolved location is not an error: an <c>xs:include</c>/<c>xs:redefine</c>
  /// is skipped, an <c>xs:import</c> loses its location, and a warning is recorded in
  /// <see cref="Errors"/>. This way the documents of one namespace, added one by one, form a
  /// single schema even when they refer to each other by file names that exist nowhere;
  /// components that are really missing are reported by libxml2 as unresolved references.</description></item>
  /// </list>
  /// <para>Several documents of one namespace are joined by a wrapper schema made of
  /// <c>xs:include</c>, so each keeps its own <c>elementFormDefault</c> and prefixes. Every
  /// document reaches libxml2 from memory under a <c>lx2schema://schemas/N/name</c> address
  /// through the global external entity loader: libxml2 does not pass the loader set on the
  /// schema parser context (<c>xmlSchemaSetResourceLoader</c>) to the nested contexts, and an
  /// include inside an imported schema would be read from disk. The compiled schema is cached
  /// until the next <see cref="Add"/> or <see cref="Remove"/>; an instance is not meant to be
  /// used from several threads at once.</para>
  /// </remarks>
  TXMLSchemaCollection = class(TXMLBase, IXMLSchemaCollection)
  private const
    cImport = 'import';
    cInclude = 'include';
    cRedefine = 'redefine';
    cNamespace = 'namespace';
    cSchemaLocation = 'schemaLocation';
    cSchemaNs = 'http://www.w3.org/2001/XMLSchema';
    /// Target namespace of the root wrapper: only a schema that has a target namespace may
    /// import a schema without one (src-import.1.2).
    cRootNamespace = 'urn:lx2:schema-collection';
    cResourcePrefix: RawByteString = 'lx2schema://schemas/';
  protected type
    TSource = record
      Doc: IXMLDocument;
      Resolver: IXMLResolver;
    end;
    TItem = class
      NamespaceURI: string;
      Sources: TList<TSource>;
      /// The merged document Get hands out when there are several sources; lives until Invalidate.
      Merged: xmlDocPtr;
      /// Resource indices for the duration of a compilation: the namespace wrapper and every source.
      Resource: Integer;
      SourceResources: TArray<Integer>;
      constructor Create;
      destructor Destroy; override;
      procedure FreeMerged;
    end;
  private
    FItems: TObjectList<TItem>;
    FErrors: TXMLErrors;
    FCompiled: Boolean;
    FSchema: xmlSchemaPtr;
    /// The root wrapper: the schema refers to its nodes, so the document lives as long as FSchema.
    FRootDoc: xmlDocPtr;
    FResources: TList<TBytes>;
    FResourceUrls: TList<RawByteString>;
    FLocations: TDictionary<string, Integer>;
    FUnlocated: TDictionary<string, Boolean>;
    procedure Invalidate;
    function  ReserveResource(const Name: string): Integer;
    function  ResourceUrl(Index: Integer): RawByteString;
    function  AbsoluteLocation(const Location, BaseUrl: string): string;
    function  ResolveLocation(const Location, BaseUrl: string; const Resolver: IXMLResolver): Integer;
    procedure PrepareSchema(Index: Integer; Doc: xmlDocPtr; const BaseUrl: string; const Resolver: IXMLResolver);
    procedure Unlocated(const Location, BaseUrl, Element: string);
    procedure AddWarning(Code: Integer; const Text, Url: string);
    function  LoadResource(const Url: PUTF8Char): xmlParserInputPtr;
    function  MergedDoc(Item: TItem): xmlDocPtr;
  protected
    property  Items: TObjectList<TItem> read FItems;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>
    /// Compiles the registered schemas into one; the diagnostics go to <see cref="Errors"/>.
    /// <see cref="Validate"/> compiles on its own, a separate call is for checking the schemas
    /// without a document.
    /// </summary>
    procedure Compile;
    function  Validate(const Doc: IXMLDocument): Boolean;
    function  IndexOf(const NamespaceURI: string): NativeInt;
    procedure Add(const NamespaceURI: string; const Doc: IXMLDocument; const Resolver: IXMLResolver = nil);
    procedure Remove(const NamespaceURI: string);
    function  Get_Length: NativeInt;
    function  Get_NamespaceURI(index: NativeInt): string;
    function  Get_Errors: IXMLErrors;
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
    FValidateOnParse: Boolean;
    FResolveExternals: Boolean;
    FPreserveWhiteSpace: Boolean;
    FOptions: TXmlParserOptions;
    FSuccessError: IXMLParseError;
    FSchemas: IXMLSchemaCollection;
  protected
    procedure ErrorCallback(const error: xmlError); virtual;
    function  SetNewDoc(Doc: xmlDocPtr): xmlDocPtr;
    property  DocOwner: Boolean read FDocOwner;
  public
    function  CanonicalizeToFile(const FileName: string; Mode: TXmlC14NMode = TXmlC14NMode.xmlC14N; Comments: Boolean = False): Boolean;
    function  CanonicalizeToStream(const Stream: TStream; Mode: TXmlC14NMode = TXmlC14NMode.xmlC14N; Comments: Boolean = False): Boolean;
    function  Canonicalize(Mode: TXmlC14NMode = TXmlC14NMode.xmlC14N; Comments: Boolean = False): RawByteString;
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
    function  importNode(const node: IXMLNode; deep: Boolean): IXMLNode;
    function  NodeFromID(const IdString: string): IXMLNode;
    procedure Save(const Url: string); overload;
    procedure Set_documentElement(const Element: IXMLElement);
    procedure Set_PreserveWhiteSpace(IsPreserving: Boolean);
    procedure Set_ResolveExternals(IsResolving: Boolean);
    procedure Set_Schemas(const Value: IXMLSchemaCollection);
    procedure Set_ValidateOnParse(IsValidating: Boolean);
    function  Transform(const stylesheet: IXMLDocument; out doc: IXMLDocument): Boolean; overload; override;
    function  Transform(const stylesheet: IXMLDocument; out S: RawByteString): Boolean; overload; override;
    function  Transform(const stylesheet: IXMLDocument; out S: string): Boolean; overload; override;
    function  Transform(const stylesheet: IXMLDocument; Stream: TStream): Boolean; overload; override;
    function  TransformNodeToObject(const stylesheet: IXMLDocument; const output: IXMLDocument): Boolean; override;
    function  TransformNodeToStream(const stylesheet: IXMLDocument; const output: TStream): Boolean; override;
    function  TransformNode(const stylesheet: IXMLDocument): string; override;
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
    function  LoadFromBytes(const Data: TBytes): Boolean;
    function  LoadFromMemory(const Data: Pointer; Size: NativeUInt): Boolean;
    function  Load(const URL: string): Boolean;
    function  LoadFromStream(Stream: TStream; const Encoding: Utf8String): Boolean;

    function  Save(const FileName: string; const Encoding: string = 'UTF-8'; const Options: TxmlSaveOptions = []): Boolean; overload;
    function  SaveToStream(Stream: TStream; const Encoding: string = 'UTF-8'; const Options: TxmlSaveOptions = []): Boolean; overload;
    function  ToBytes(const Encoding: string = 'UTF-8'; const Format: Boolean = False): TBytes; overload;
    function  ToString(const Encoding: string; const Format: Boolean = False): string; reintroduce; overload;
    function  ToString(const Format: Boolean): string; reintroduce; overload;
    function  ToString: string; overload; override;
    function  ToUtf8(const Format: Boolean = False): RawByteString; overload;
    function  ToAnsi(const Encoding: string = 'windows-1251'; const Format: Boolean = False): RawByteString; overload;

    procedure ReconciliateNs; override;
    property  Errors: TXMLErrors read FErrors;
    property  Options: TXmlParserOptions read FOptions write FOptions;
  end;

var
  DebugObjectCount: NativeInt = 0;

implementation

uses
  libxslt.API, System.IOUtils;

var
  GlobalLock: TObject;
  OldDeregisterNodeFunc: xmlDeregisterNodeFunc;

function ISODateTimeToStr(Value: TDateTime): string;
const
  TwoDigit: array[0..60] of array[0..1] of Char = (
    '00', '01', '02', '03', '04', '05', '06', '07', '08', '09',
    '10', '11', '12', '13', '14', '15', '16', '17', '18', '19',
    '20', '21', '22', '23', '24', '25', '26', '27', '28', '29',
    '30', '31', '32', '33', '34', '35', '36', '37', '38', '39',
    '40', '41', '42', '43', '44', '45', '46', '47', '48', '49',
    '50', '51', '52', '53', '54', '55', '56', '57', '58', '59',
    '60');
var
  Y, M, D, H, S, MS: Word;
begin
  DecodeDate(Value, Y, M, D);
  Result := Y.ToString + '-' + M.ToString + '-' + D.ToString;
  if Frac(Value) <> 0 then
  begin
    DecodeTime(Value, H, M, S, MS);
    Result := Result + ' ' + H.ToString + ':' + M.ToString + ':' + S.ToString;
  end;
end;

/// <summary>
/// Callback registered once, globally, through <c>xmlDeregisterNodeDefault</c>; libxml2
/// invokes it right before it physically frees the memory of any <c>xmlNodePtr</c>,
/// REGARDLESS of whether the release was initiated by this Delphi wrapper or from inside
/// libxml2 itself (for example, merging adjacent text nodes inside <c>xmlAddChild</c>, or
/// the cascading removal of a subtree).
/// </summary>
/// <remarks>
/// <para>
/// <b>Why it is needed:</b> the Delphi wrapper (<c>TXMLNode</c>) holds a raw pointer
/// <c>NodePtr</c> to the libxml2 structure. If libxml2 frees that structure without the
/// wrapper knowing, <c>NodePtr</c> becomes a dangling pointer and any later access to it
/// from Delphi code is undefined behaviour (usually an access violation on reading freed
/// memory, or worse, a silent read of memory already reused for other data).
/// </para>
/// <para>
/// <b>What the function does:</b> finds the Delphi wrapper through <c>Node._private</c>
/// (if it exists, that is, if managed DOM code ever referred to this node) and:
/// <list type="number">
/// <item><description>
/// Walks the namespaces declared on the node (<c>nsDef</c>) and, for each one that has a
/// wrapper of its own (<c>Ns._private &lt;&gt; nil</c>, that is, a <see cref="TXMLNsNode"/>
/// object refers to it), clears its <c>NsPtr</c> field, because freeing a node in libxml2
/// normally frees its <c>nsDef</c> list as well.
/// </description></item>
/// <item><description>
/// Clears <c>NodePtr</c> of the node wrapper itself, so that later accesses to its
/// properties (all of which read <c>NodePtr.*</c>) at least do not read freed memory
/// directly. Without an extra <c>NodePtr = nil</c> check in every getter this still ends
/// in an access violation on dereferencing <c>nil</c>, but that is strictly preferable to
/// silent data corruption.
/// </description></item>
/// </list>
/// </para>
/// <para>
/// <b>Known limitation:</b> this function does NOT release the reference on the owning
/// document taken in <see cref="TXMLNode.Create"/>; that reference is released only in
/// <see cref="TXMLNode.Destroy"/>, which by then can no longer read <c>NodePtr.doc</c>
/// (it is already <c>nil</c>). See the corresponding note in <see cref="TXMLNode.Destroy"/>.
/// </para>
/// </remarks>
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

procedure CheckNotNode(const Node: IXMLNode);
begin
  if (Node <> nil) and not (TObject(Node) is TXMLNode) then
    raise EXmlUnsupported.CreateResFmt(@SUnsupportedBy, [NodeTypeName(xmlElementType(Node.NodeType))]);
end;

/// <summary>
/// Resolves the "deferred" (<c>Unlinked</c>) namespace of an attribute at the moment it is
/// actually attached to the document tree (see <c>Cast(xmlAttrPtr, Prefix, NamespaceURI)</c>
/// and the general note there).
/// </summary>
/// <remarks>
/// <para>
/// Called from <see cref="TXMLNode.AppendChild"/>, <see cref="TXMLNode.InsertBefore"/> and
/// <see cref="TXMLAttributeList.SetNamedItem"/> right before the attribute is attached to
/// its parent element: at that point the concrete tree node (<paramref name="Parent"/>) is
/// known, and the search for or creation of a suitable <c>xmlNsPtr</c> through
/// <c>xmlSearchNs</c>/<c>xmlSearchNsByHref</c> can start from it.
/// </para>
/// <para>
/// <b>The choice of search strategy (three if/elsif/else branches) is not obvious at
/// first sight:</b>
/// <list type="bullet">
/// <item><description>
/// If ONLY the prefix is given (the URI is unknown or empty), an existing namespace
/// declaration is looked up by prefix (<c>xmlSearchNs</c>): the caller is assumed to rely
/// on whatever namespace is already declared in the tree under that prefix.
/// </description></item>
/// <item><description>
/// If ONLY the URI is given (the prefix is unknown or empty), the lookup is by URI
/// (<c>xmlSearchNsByHref</c>): ANY prefix in scope under which that URI is already
/// declared will do.
/// </description></item>
/// <item><description>
/// If BOTH are given, the lookup is by prefix first, and the declaration found is
/// ADDITIONALLY checked to carry exactly this URI (<c>xmlStrSame(...href)</c>); on a
/// mismatch the code falls back to <c>Ns := nil</c>, which below creates a NEW namespace
/// declaration with this prefix and URI on the <paramref name="Parent"/> node itself
/// (through <c>xmlNewNs</c>), even if the prefix was already used in the tree for another
/// URI. That is the expected semantics: an exact (prefix, URI) match takes precedence over
/// a match on either field alone.
/// </description></item>
/// </list>
/// </para>
/// </remarks>
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

/// <summary>
/// Returns the existing Delphi wrapper of the document (through <c>Doc._private</c>), or
/// creates a new one that owns the document (<c>DocOwner = True</c>) when there is no
/// wrapper yet.
/// </summary>
/// <remarks>
/// <c>DocOwner = True</c> here means the wrapper created will call <c>xmlFreeDoc</c> in
/// its destructor. That is correct because the only way into the "no wrapper yet" branch
/// is a document created directly through the libxml2 API, bypassing this wrapper (for
/// example, the result of an XSLT transformation), that is now accessed through the DOM
/// for the first time (see <c>TXMLNode.Get_OwnerDocument</c>).
/// </remarks>
function Cast(const Doc: xmlDocPtr): TXMLDocument; overload;
begin
  if Doc = nil then
    Exit(nil);

  if Doc._private <> nil then
    Exit(TXMLDocument(Doc._private));

  Result := TXMLDocument.Create(Doc, True);
end;

/// <summary>
/// Returns the existing wrapper of the node, or creates a new one of the concrete class
/// chosen by <c>Node.&amp;type</c> (dispatch on <c>xmlElementType</c>: element →
/// <see cref="TXMLElement"/>, text → <see cref="TXMLText"/>, and so on). Unknown or
/// unhandled node types get the base <see cref="TXMLNode"/>.
/// </summary>
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

/// <summary>Attribute-specific version of <see cref="Cast(xmlNodePtr)"/> that saves the caller expecting a <see cref="TXMLAttribute"/> an explicit type cast.</summary>
function Cast(const Attr: xmlAttrPtr): TXMLAttribute; overload;
begin
  if Attr = nil then
    Result := nil
  else if Attr._private = nil then
    Result := TXMLAttribute.Create(Attr)
  else
    Result := TXMLAttribute(Attr._private);
end;

/// <summary>
/// Special overload for an unlinked attribute: one created in memory but not yet attached
/// to the document tree, whose namespace prefix/URI cannot be resolved through
/// <c>xmlSearchNs</c> yet (that becomes possible only once the attribute is physically
/// attached to a parent element, see <see cref="ResolveUnlinked"/>).
/// </summary>
/// <remarks>
/// Used, for example, by <c>CreateAttributeNS</c>, where the caller names the namespace
/// URI BEFORE the attribute is attached to any element of the tree. libxml2 cannot create
/// or find an <c>xmlNsPtr</c> without the context of a concrete tree node, so the
/// namespace resolution is deferred (<c>Attr.Unlinked := True</c>) until the attribute is
/// actually attached to an element.
/// </remarks>
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

/// <summary>
/// Wraps an <c>xmlNsPtr</c> (a namespace declaration of a node, which is not a separate
/// DOM node in libxml2) into the MSXML-compatible pseudo attribute node
/// <see cref="TXMLNsAttribute"/>, because MSXML DOM, unlike libxml2, treats
/// <c>xmlns:prefix="uri"</c> declarations as ordinary attributes of the element; see the
/// general note on <see cref="TXMLNsNode"/>.
/// </summary>
function Cast(const Ns: xmlNsPtr; Parent: xmlNodePtr): TXMLNsAttribute; overload;
begin
  if Ns = nil then
    Result := nil
  else if Ns._private = nil then
    Result := TXMLNsAttribute.Create(Ns, Parent)
  else
    Result := TXMLNsAttribute(Ns._private);
end;

/// <summary>
/// Unlinks <paramref name="Ns"/> from the singly linked list of namespace declarations
/// <paramref name="List"/> (normally <c>Node.nsDef</c>), fixing up the pointers of the
/// neighbouring entries.
/// </summary>
/// <returns><c>True</c> if <paramref name="Ns"/> was found and unlinked; <c>False</c> if it is not in the list (or is <c>nil</c>).</returns>
/// <remarks>
/// ⚠ Apply ONLY to fields that really are the head of a linked list (<c>Node.nsDef</c>),
/// never to single namespace references such as <c>Node.ns</c>, the namespace the node
/// uses, which is NOT the list of namespaces it declares. For single references use
/// <see cref="xmlClearNodeNsRef"/>: passing <c>Node.ns</c> as <paramref name="List"/> is
/// semantically wrong, the function would assign <c>Ns.next</c> (the next entry of SOME
/// OTHER <c>nsDef</c> list) to the field instead of <c>nil</c>, silently corrupting the
/// node's namespace reference.
/// </remarks>
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
    while (Cur <> nil) and (Cur.next <> Ns) do
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

/// <summary>
/// Resets the SINGLE reference of a node to the namespace it uses (<c>Node.ns</c>) to
/// <c>nil</c> when it points at the <paramref name="Ns"/> being removed, unlike
/// <see cref="xmlUnlinkNs"/>, which works on linked lists rather than single fields.
/// </summary>
procedure xmlClearNodeNsRef(Node: xmlNodePtr; Ns: xmlNsPtr); inline;
begin
  if Node.ns = Ns then
    Node.ns := nil;
end;

/// <summary>
/// Removes the namespace declaration <paramref name="Ns"/> from <paramref name="Node"/>
/// completely: unlinks it from <c>Node.nsDef</c> and walks EVERY node of the subtree
/// (<c>Node</c> and all its descendants through <c>Node.GetNext(Node)</c>, a walk of the
/// whole subtree in document order), resetting the <c>Node.ns</c> reference of each one
/// that pointed at the namespace being removed.
/// </summary>
/// <remarks>
/// The full walk of the subtree is required because removing a namespace declaration
/// from an element INVALIDATES every reference to it in the descendants; libxml2/XML has
/// no separate "redeclare" step on removal (unlike MSXML, where <c>ReconciliateNs</c>
/// sometimes takes care of it), so the references must be cleared explicitly to avoid
/// dangling <c>xmlNsPtr</c> pointers in child nodes. The operation is O(size of the
/// subtree), which matters when namespace declarations are removed often in large
/// documents.
/// </remarks>
procedure xmlRemoveNsDef(Node: xmlNodePtr; Ns: xmlNsPtr);
begin
  if not xmlUnlinkNs(Node.nsDef, Ns) then
    Exit;

  Ns.next := nil;
  Ns.context := nil;

  var Child := Node;
  while Child <> nil do
  begin
    xmlClearNodeNsRef(Child, Ns);
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
  for var I := 0 to Index - 1 do
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
  var DocChanged := Parent.doc <> NewNode.doc;
  if (NewNode.doc <> nil) and (Parent.doc <> NewNode.doc) and (NewNode.doc._private <> nil) then
    TXmlDocument(NewNode.doc._private)._Release;

  if AfterNode = nil then
    Result := xmlAddChild(Parent, NewNode)
  else
    Result := xmlAddNextSibling(NewNode, AfterNode);

  if Result <> nil then
    xmlReconciliateNs(Result.doc, Result);

  if DocChanged and (Result.doc <> nil) and (Result.doc._private <> nil) then
    TXmlDocument(Result.doc._private)._AddRef;
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
  Result := inherited NextNode as IXmlAttribute;
end;

function TXMLAttributes.ToArray: TArray<IXmlAttribute>;
begin
  var Base := inherited ToArray;
  SetLength(Result, System.Length(Base));
  for var I := 0 to High(Base) do
    Result[I] := Base[I] as IXmlAttribute;
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
      if xmlStrSame(Node.Name, Pointer(LocalName)) and ((URI = '') or ((Node.ns <> nil) and xmlStrSame(Node.ns.href, Pointer(URI)))) then
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

/// <summary>
/// Creates the Delphi wrapper over an existing <c>xmlNodePtr</c>, establishing the
/// two-way link through <c>Node._private := Self</c> (used by the <c>Cast(...)</c>
/// functions for caching, see the note on the unit as a whole) and, where applicable,
/// increments the refcount of the owning document.
/// </summary>
/// <remarks>
/// <para>
/// <b>The <c>FOwnerDocRefTaken</c> condition:</b>
/// <c>(Node.doc &lt;&gt; nil) and (xmlNodePtr(Node.doc) &lt;&gt; Node) and (Node.doc._private &lt;&gt; nil)</c>.
/// The middle term, <c>xmlNodePtr(Node.doc) &lt;&gt; Node</c>, excludes the case where the
/// object being created IS the document wrapper (<c>TXMLDocument</c> descends from
/// <c>TXMLNode</c> and calls this very constructor through
/// <c>inherited Create(xmlNodePtr(doc))</c>): a document must not take a reference on
/// itself, or its refcount could never drop to zero and the object would never be
/// destroyed.
/// </para>
/// <para>
/// The <see cref="FOwnerDocRefTaken"/> flag is kept in a field of its own rather than
/// recomputed in <c>Destroy</c> from the current state of <c>NodePtr</c>, because by the
/// time the object is destroyed <c>NodePtr.doc</c> may no longer be reachable (see
/// <see cref="NodeFreeCallback"/>, which clears <c>NodePtr</c> when the node is freed
/// externally); without the stored flag there is no reliable way to tell whether the
/// constructor took a reference at all.
/// </para>
/// </remarks>
constructor TXMLNode.Create(Node: xmlNodePtr);
begin
  inherited Create;
  NodePtr := Node;
  NodePtr._private := Self;

  FOwnerDocRefTaken := (Node.doc <> nil) and (xmlNodePtr(Node.doc) <> Node) and (Node.doc._private <> nil);
  if FOwnerDocRefTaken then
    TXMLDocument(Node.doc._private)._AddRef;

  FXSLTErrors := TXSLTErrors.Create;
  FXSLTErrors._AddRef;

  {$IFDEF DEBUG}
  AtomicIncrement(DebugObjectCount);
  {$ENDIF}
end;

destructor TXMLNode.Destroy;
var
  doc: TXMLDocument;
begin
  doc := nil;
  if FOwnerDocRefTaken and (NodePtr <> nil) and (NodePtr._private = Self) then
  begin
    if (NodePtr.doc <> nil) and (NodePtr.doc._private <> nil) then
      doc := TXMLDocument(NodePtr.doc._private);

    NodePtr._private := nil;
    if NodePtr.parent = nil then
      xmlFreeNode(NodePtr);
  end;

  if FXSLTErrors <> nil then
    FXSLTErrors._Release;

  {$IFDEF DEBUG}
  AtomicDecrement(DebugObjectCount);
  {$ENDIF}

  inherited;

  if doc <> nil then
    doc._Release;
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
      var DocChanged := NodePtr.doc <> NewNode.NodePtr.doc;

      if (NewNode.NodePtr.doc <> nil) and (NewNode.NodePtr.doc._private <> nil) then
        TXmlDocument(NewNode.NodePtr.doc._private)._Release;

      if xmlDOMWrapAdoptNode(nil, nil, NewNode.NodePtr, NodePtr.doc, NodePtr, 0)  = 0 then
      begin
        var AddedNode := NodePtr.AppendChild(NewNode.NodePtr);
        Result := Cast(AddedNode);
        if DocChanged and (AddedNode.doc <> nil) and (AddedNode.doc._private <> nil) then
          TXmlDocument(AddedNode.doc._private)._AddRef;
      end
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
    var NewNode := TXMLNode(NewChild);

    var DocChanged := NodePtr.doc <> NewNode.NodePtr.doc;

    if (NewNode.NodePtr.doc <> nil) and (NewNode.NodePtr.doc._private <> nil) then
      TXmlDocument(NewNode.NodePtr.doc._private)._Release;

    ResolveUnlinked(NodePtr, NewNode);
    var AddedNode := NodePtr.InsertBefore(NewNode.NodePtr, TXMLNode(RefChild).NodePtr);
    Result := Cast(AddedNode);

    if DocChanged and (AddedNode.doc <> nil) and (AddedNode.doc._private <> nil) then
      TXmlDocument(AddedNode.doc._private)._AddRef;
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
  Result := nil;
end;

function TXMLNode.Get_BaseName: string;
begin
  Result := xmlCharToStr(NodePtr.name);
end;

function TXMLNode.Get_ChildNodes: IXMLNodeList;
begin
  Result := TXMLNodeList.Create(NodePtr);
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

  Result := TXMLDocument(NodePtr.OwnerDocument._private);
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

function TXMLNode.GetXSLTErrors: IXSLTErrors;
begin
  Result := FXSLTErrors;
end;

procedure TXMLNode.XSLTError(const Msg: string);
begin
  FXSLTErrors.FList.Add(TXSLTError.Create(Msg) as IXSLTError);
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
  NodePtr.RemoveChild(Node.NodePtr);
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

function TXMLNode.Transform(const Stylesheet: IXMLDocument; out Doc: IXMLDocument): Boolean;
var
  Res: xmlDocPtr;
begin
  FXSLTErrors.Clear;

  Result := NodePtr.Transform(xmlDocPtr(TXMLDocument(stylesheet).NodePtr), Res, XSLTError);
  if Result then
    Doc := TXMLDocument.Create(Res, True);
end;

function TXMLNode.Transform(const Stylesheet: IXMLDocument; out S: RawByteString): Boolean;
begin
  FXSLTErrors.Clear;

  Result := NodePtr.Transform(xmlDocPtr(TXMLDocument(Stylesheet).NodePtr), S, XSLTError);
end;

function TXMLNode.Transform(const Stylesheet: IXMLDocument; out S: string): Boolean;
begin
  FXSLTErrors.Clear;

  Result := NodePtr.Transform(xmlDocPtr(TXMLDocument(Stylesheet).NodePtr), S, XSLTError);
end;

function TXMLNode.Transform(const stylesheet: IXMLDocument; Stream: TStream): Boolean;
begin
  FXSLTErrors.Clear;

  Result := NodePtr.Transform(xmlDocPtr(TXMLDocument(Stylesheet).NodePtr), Stream, XSLTError);
end;

function TXMLNode.TransformNode(const stylesheet: IXMLDocument): string;
begin
  FXSLTErrors.Clear;

  xmlDocPtr(NodePtr).Transform(xmlDocPtr(TXMLDocument(Stylesheet).NodePtr), Result, XSLTError);
end;

function TXMLNode.TransformNodeToObject(const stylesheet, output: IXMLDocument): Boolean;
var
  Doc: XmlDocPtr;
begin
  FXSLTErrors.Clear;

  Result := NodePtr.Transform(xmlDocPtr(TXMLDocument(Stylesheet).NodePtr), Doc, XSLTError);
  if Result then
  begin
    xmlFreeDoc(xmlDocPtr(NodePtr));
    TXMLDocument(output).NodePtr := xmlNodePtr(Doc);
  end;
end;

function TXMLNode.TransformNodeToStream(const stylesheet: IXMLDocument; const output: TStream): Boolean;
begin
  FXSLTErrors.Clear;

  Result := NodePtr.Transform(xmlDocPtr(TXMLDocument(Stylesheet).NodePtr), output, XSLTError);
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
  if xmlAttrPtr(NodePtr).ns = nil then
    Result := xmlCharToStr(xmlAttrPtr(NodePtr).name)
  else
    Result := xmlCharToStr(xmlAttrPtr(NodePtr).ns.prefix) + ':' + xmlCharToStr(xmlAttrPtr(NodePtr).name);
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
  var Args: TXmlArgs;
  var children: xmlNodePtr := nil;
  var WasId := AttrPtr.atype = XML_ATTRIBUTE_ID;

  if AttrValue <> '' then
  begin
    children := xmlNewDocText(AttrPtr.parent.doc, Args.StrPtr(attrValue));
    if children = nil then
      LX2InternalError;
  end;

  // The old entry leaves the document's ID table BEFORE the attribute value changes,
  // otherwise the table would keep a stale (old value -> node) pair.
  if WasId then
    xmlRemoveID(AttrPtr.parent.doc, AttrPtr);

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

  // The NEW value is registered in the document's ID table when the attribute was an ID
  // attribute to begin with and received a non-empty value. Signature:
  // xmlAddID(ctxt, doc, value, attr); ctxt = nil registers without the uniqueness checks
  // of validation.
  if WasId and (AttrValue <> '') then
  begin
    AttrPtr.atype := XML_ATTRIBUTE_ID;   // xmlRemoveID may have reset atype; restore it explicitly
    if xmlAddID(nil, AttrPtr.parent.doc, Args.StrPtr(AttrValue), AttrPtr) = nil then
      LX2InternalError;   // for example, a duplicate ID in the document with validation on
  end;
end;

{ TXMLElement }

function TXMLElement.GetAttribute(const Name: string): string;
begin
  Result := UTF8ToUnicodeString(NodePtr.GetAttribute(Utf8Encode(Name)));
end;

function TXMLElement.GetAttributeNode(const Name: string): IXMLAttribute;
begin
  Result := Cast(NodePtr.GetAttributeNode(Utf8Encode(Name)));
end;

function TXMLElement.GetAttributeNodeNs(const NamespaceURI, Name: string): IXMLAttribute;
begin
  var Args: TXmlArgs;
  Result := Cast(NodePtr.GetAttributeNodeNs(Args.StrPtr(NamespaceURI), Args.StrPtr(Name)));
end;

function TXMLElement.GetAttributeNs(const NamespaceURI, Name: string): string;
begin
  var Args: TXmlArgs;
  // xmlGetNsProp takes the local name first and the namespace second
  Result := xmlCharToStrAndFree(xmlGetNsProp(NodePtr, Args.StrPtr(Name), Args.StrPtr(NamespaceURI)));
end;

procedure TXMLElement.SetAttribute(const Name: string; Value: Int64);
begin
  SetAttribute(Name, Value.ToString);
end;

procedure TXMLElement.SetAttribute(const Name: string; Value: Boolean);
const
  cBool: array[Boolean] of string = ('0', '1');
begin
  SetAttribute(Name, cBool[Value]);
end;

procedure TXMLElement.SetAttribute(const Name: string; Value: TDateTime);
begin
  SetAttribute(Name, ISODateTimeToStr(Value));
end;

function TXMLElement.SetAttributeNs(const NamespaceURI, Name: string; const Value: string): IXMLAttribute;
begin
  var Args: TXmlArgs;
  Result := Cast(NodePtr.SetAttributeNs(Args.StrPtr(NamespaceURI), Args.StrPtr(Name), Args.StrPtr(Value)));
end;

function TXMLElement.HasAttribute(const Name: string): Boolean;
begin
  var Args: TXmlArgs;
  Result := NodePtr.HasAttribute(Args.StrPtr(Name));
end;

function TXMLElement.HasAttributeNs(const NamespaceURI, Name: string): Boolean;
begin
  var Args: TXmlArgs;
  Result := NodePtr.HasAttributeNs(Args.StrPtr(NamespaceURI), Args.StrPtr(Name));
end;

function TXMLElement.AddChild(const Name: string; const Content: string = ''): IXMLElement;
begin
  var Args: TXmlArgs;
  Result := Cast(NodePtr.AddChild(Args.StrPtr(Name), Args.StrPtr(Content))) as IXMLElement;
end;

function TXMLElement.AddChildNs(const Name, NamespaceURI: string; const Content: string = ''): IXMLElement;
begin
  var Args: TXmlArgs;
  Result := Cast(NodePtr.AddChildNs(Args.StrPtr(Name), Args.StrPtr(NamespaceURI), Args.StrPtr(Content))) as IXMLElement;
end;

function TXMLElement.FirstElementChild: IXMLElement;
begin
  Result := Cast(xmlFirstElementChild(NodePtr)) as IXMLElement;
end;

function TXMLElement.LastElementChild: IXMLElement;
begin
  Result := Cast(xmlLastElementChild(NodePtr)) as IXMLElement;
end;

function TXMLElement.NextElementSibling: IXMLElement;
begin
  Result := Cast(xmlNextElementSibling(NodePtr)) as IXMLElement;
end;

function TXMLElement.PreviousElementSibling: IXMLElement;
begin
  Result := Cast(xmlPreviousElementSibling(NodePtr)) as IXMLElement;
end;

function TXMLElement.GetElementsByTagName(const tagName: string): IXMLNodeList;
begin
  Result := TXMLElementList.Create(NodePtr, False, tagName);
end;

function TXMLElement.Get_Attributes: IXMLAttributes;
begin
  Result := TXMLAttributes.Create(NodePtr);
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
    Result := xmlUnsetProp(NodePtr, xmlStrPtr(LocalName)) = 0
  else
  begin
    var Ns := NodePtr.SearchNs(Prefix);
    if Ns <> nil then
      Result := xmlUnsetNsProp(NodePtr, Ns, xmlStrPtr(LocalName)) = 0
    else
      Result := False;
  end;
end;

function TXMLElement.RemoveAttributeNs(const NamespaceURI, Name: string): Boolean;
begin
  var Args: TXmlArgs;
  var Ns := NodePtr.SearchNsByRef(Utf8Encode(NamespaceURI));
  if Ns = nil then
    Exit(False);
  Result := xmlUnsetNsProp(NodePtr, Ns, Args.StrPtr(Name)) = 0
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
  var Args: TXmlArgs;
  xmlNodeAddContent(NodePtr, Args.StrPtr(Data));
end;

procedure TXMLCharacterData.DeleteData(Offset, Count: Integer);
begin
  var Args: TXmlArgs;
  var S := xmlCharToStr(NodePtr.content);

  Delete(S, offset, count);

  xmlNodeSetContent(NodePtr, nil);
  xmlNodeAddContent(NodePtr, Args.StrPtr(S));
end;

function TXMLCharacterData.Get_Data: string;
begin
  Result := xmlCharToStr(NodePtr.content);
end;

function TXMLCharacterData.Get_Length: NativeInt;
begin
  // a node with no content has no characters; Utf8toUtf16Count wants a buffer
  if NodePtr.content = nil then
    Result := 0
  else
    Result := Utf8toUtf16Count(NodePtr.content);
end;

procedure TXMLCharacterData.InsertData(Offset: Integer; const Data: string);
begin
  var Args: TXmlArgs;
  var S := xmlCharToStr(NodePtr.content);

  Insert(data, S, Offset);

  xmlNodeSetContent(NodePtr, nil);
  xmlNodeAddContent(NodePtr, Args.StrPtr(S));
end;

procedure TXMLCharacterData.ReplaceData(Offset, Count: Integer; const Data: string);
begin
  var Args: TXmlArgs;
  var S := xmlCharToStr(NodePtr.content);

  Delete(S, Offset, Count);
  Insert(data, S, Offset);

  xmlNodeSetContent(NodePtr, nil);
  xmlNodeAddContent(NodePtr, Args.StrPtr(S));
end;

procedure TXMLCharacterData.Set_Data(const Data: string);
begin
  var Args: TXmlArgs;
  xmlNodeSetContent(NodePtr, nil);
  xmlNodeAddContent(NodePtr, Args.StrPtr(Data));
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
  var Args: TXmlArgs;
  xmlNodeSetContent(NodePtr, nil);
  xmlNodeAddContent(NodePtr, Args.StrPtr(Value));
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

function TXMLErrors.Get_Count: NativeInt;
begin
  Result := FList.Count;
end;

function TXMLErrors.Get_Item(Index: NativeInt): IXMLParseError;
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

function TXSLTErrors.Get_Count: NativeInt;
begin
  Result := FList.Count;
end;

function TXSLTErrors.Get_Item(Index: NativeInt): IXSLTError;
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
end;

constructor TXMLDocument.Create(doc: xmlDocPtr; DocOwner: Boolean);
begin
  inherited Create(xmlNodePtr(doc));

  FErrors := TXMLErrors.Create;
  FErrors._AddRef;

  FSuccessError := TXMLError.Create;
  FSuccessError._AddRef;

  FDocOwner := DocOwner;
  FValidateOnParse := True;
  FOptions := DefaultParserOptions;
end;

destructor TXMLDocument.Destroy;
begin
  if NodePtr <> nil then
  begin
    if DocOwner then
      xmlFreeDoc(xmlDocPtr(NodePtr))
    else if NodePtr._private = Self then
      NodePtr._private := nil;   // the document outlives this wrapper: Cast() must not find it again
    NodePtr := nil;
  end;
  inherited;
  if FErrors <> nil then
    FErrors._Release;
  if FSuccessError <> nil then
    FSuccessError._Release;
end;

function TXMLDocument.Canonicalize(Mode: TXmlC14NMode; Comments: Boolean): RawByteString;
begin
  Result := xmlDocPtr(NodePtr).Canonicalize(Mode, Comments);
end;

function TXMLDocument.CanonicalizeToFile(const FileName: string; Mode: TXmlC14NMode; Comments: Boolean): Boolean;
begin
  Result := xmlDocPtr(NodePtr).CanonicalizeTo(FileName, Mode, Comments);
end;

function TXMLDocument.CanonicalizeToStream(const Stream: TStream; Mode: TXmlC14NMode; Comments: Boolean): Boolean;
begin
  Result := xmlDocPtr(NodePtr).CanonicalizeTo(Stream, Mode, Comments);
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
      Result := Cast(xmlNewNs(nil, nil, xmlStrPtr(LocalName)), nil)
    else
      Result := Cast(xmlNewDocProp(xmlDocPtr(NodePtr), xmlStrPtr(LocalName), nil), Prefix, '');
  end
  else if Name = 'xmlns' then
    Result := Cast(xmlNewNs(nil, '', nil), nil)
  else
    Result := Cast(xmlNewDocProp(xmlDocPtr(NodePtr), xmlStrPtr(LocalName), nil));
end;

function TXMLDocument.createAttributeNS(const namespaceURI, qualifiedName: string): IXMLAttribute;
var
 Prefix, LocalName: RawByteString;
begin
  var Args: TXmlArgs;
  if SplitXMLName(UTF8Encode(qualifiedName), Prefix, LocalName) then
  begin
    if Prefix = 'xmlns' then
      Result := Cast(xmlNewNs(nil, Args.StrPtr(namespaceURI), xmlStrPtr(LocalName)), nil)
    else
      Result := Cast(xmlNewDocProp(xmlDocPtr(NodePtr), xmlStrPtr(LocalName), nil), Prefix, Utf8Encode(namespaceURI));
  end
  else if LocalName = 'xmlns' then
    Result := Cast(xmlNewNs(nil, Args.StrPtr(namespaceURI), nil), nil)
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
  var Args: TXmlArgs;
  var S := Utf8Encode(Data);
  Result := Cast(xmlNewDocComment(xmlDocPtr(NodePtr), Args.StrPtr(Data))) as IXMLComment;
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
  SplitXMLName(Utf8Encode(Name), Prefix, LocalName);
  if NamespaceURI <> '' then
    HRef := Utf8Encode(NamespaceURI)
  else
    HRef := '';

  case NodeType of
    NODE_ATTRIBUTE:
      Result := Cast(xmlNewDocProp(xmlDocPtr(NodePtr), xmlStrPtr(LocalName), nil));
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
      begin
        var Node := xmlNewDocNode(xmlDocPtr(NodePtr), nil, xmlStrPtr(LocalName), nil);
        if HRef <> '' then
        begin
          // xmlNewNs only declares the namespace on the node; the element is put
          // into it by assigning Node.ns.
          if Prefix = '' then
            Node.ns := xmlNewNs(Node, xmlStrPtr(HRef), nil)
          else
            Node.ns := xmlNewNs(Node, xmlStrPtr(HRef), xmlStrPtr(Prefix));
        end;
        Result := Cast(Node);
      end;
    NODE_PROCESSING_INSTRUCTION:
      Result := Cast(xmlNewDocPI(xmlDocPtr(NodePtr), xmlStrPtr(LocalName), nil));
  else
    Result := nil;
  end;
end;

function TXMLDocument.CreateProcessingInstruction(const Target, Data: string): IXMLProcessingInstruction;
begin
  var Args: TXmlArgs;
  Result := Cast(xmlNewDocPI(xmlDocPtr(NodePtr), Args.StrPtr(Target), Args.StrPtr(Data))) as IXMLProcessingInstruction;
end;

function TXMLDocument.CreateTextNode(const Data: string): IXMLText;
begin
  var Args: TXmlArgs;
  Result := Cast(xmlNewDocText(xmlDocPtr(NodePtr), Args.StrPtr(Data))) as IXMLText;
end;

procedure TXMLDocument.ErrorCallback(const error: xmlError);
begin
  var Err := TXMLError.Create(TXmlParseError.Create(error));
  Errors.FList.Add(Err);
end;

function TXMLDocument.getElementById(const elementId: string): IXMLElement;
begin
  var Args: TXmlArgs;
  var Attr := xmlGetID(xmlDocPtr(NodePtr), Args.StrPtr(elementId));
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

function TXMLDocument.LoadFromBytes(const Data: TBytes): Boolean;
begin
  Result := SetNewDoc(xmlDoc.Create(Data, Options, ErrorCallback)) <> nil;
  if Result and FValidateOnParse and (FSchemas <> nil) then
    Result := FSchemas.Validate(Self);
end;

function TXMLDocument.LoadFromMemory(const Data: Pointer; Size: NativeUInt): Boolean;
begin
  Result := SetNewDoc(xmlDoc.Create(Data, Size, Options, ErrorCallback)) <> nil;
  if Result and FValidateOnParse and (FSchemas <> nil) then
    Result := FSchemas.Validate(Self);
end;

function TXMLDocument.LoadFromStream(Stream: TStream; const Encoding: Utf8String): Boolean;
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
  var Args: TXmlArgs;
  var Attr := xmlGetID(xmlDocPtr(NodePtr), Args.StrPtr(IdString));
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
  var Args: TXmlArgs;
  xmlSaveFile(Args.StrPtr(url), xmlDocPtr(NodePtr));
end;

function TXMLDocument.Save(const FileName, Encoding: string; const Options: TxmlSaveOptions): Boolean;
begin
  Result := xmlDocPtr(NodePtr).Save(FileName, Encoding, Options);
end;

function TXMLDocument.SaveToStream(Stream: TStream; const Encoding: string; const Options: TxmlSaveOptions): Boolean;
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

function TXMLDocument.ToString(const Format: Boolean): string;
begin
  Result := xmlDocPtr(NodePtr).ToString('', Format);
end;

function TXMLDocument.ToString(const Encoding: string; const Format: Boolean): string;
begin
  Result := xmlDocPtr(NodePtr).ToString(Encoding, Format);
end;

function TXMLDocument.ToUtf8(const Format: Boolean): RawByteString;
begin
  Result := xmlDocPtr(NodePtr).ToUtf8(Format);
end;

function TXMLDocument.Transform(const Stylesheet: IXMLDocument; out Doc: IXMLDocument): Boolean;
var
  Res: xmlDocPtr;
begin
  FXSLTErrors.Clear;

  Result := xmlDocPtr(NodePtr).Transform(xmlDocPtr(TXMLDocument(stylesheet).NodePtr), Res, XSLTError);
  if Result then
    Doc := TXMLDocument.Create(Res, True);
end;

function TXMLDocument.Transform(const Stylesheet: IXMLDocument; out S: RawByteString): Boolean;
begin
  FXSLTErrors.Clear;

  Result := xmlDocPtr(NodePtr).Transform(xmlDocPtr(TXMLDocument(Stylesheet).NodePtr), S, XSLTError);
end;

function TXMLDocument.Transform(const Stylesheet: IXMLDocument; out S: string): Boolean;
begin
  FXSLTErrors.Clear;

  Result := xmlDocPtr(NodePtr).Transform(xmlDocPtr(TXMLDocument(Stylesheet).NodePtr), S, XSLTError);
end;

function TXMLDocument.Transform(const stylesheet: IXMLDocument; Stream: TStream): Boolean;
begin
  FXSLTErrors.Clear;

  Result := xmlDocPtr(NodePtr).Transform(xmlDocPtr(TXMLDocument(Stylesheet).NodePtr), Stream, XSLTError);
end;

function TXMLDocument.TransformNode(const stylesheet: IXMLDocument): string;
begin
  FXSLTErrors.Clear;

  xmlDocPtr(NodePtr).Transform(xmlDocPtr(TXMLDocument(Stylesheet).NodePtr), Result, XSLTError);
end;

function TXMLDocument.TransformNodeToObject(const stylesheet, output: IXMLDocument): Boolean;
var
  Doc: XmlDocPtr;
begin
  FXSLTErrors.Clear;

  Result := xmlDocPtr(NodePtr).Transform(xmlDocPtr(TXMLDocument(Stylesheet).NodePtr), Doc, XSLTError);
  if Result then
  begin
    xmlFreeDoc(xmlDocPtr(NodePtr));
    TXMLDocument(output).NodePtr := xmlNodePtr(Doc);
  end;
end;

function TXMLDocument.TransformNodeToStream(const stylesheet: IXMLDocument; const output: TStream): Boolean;
begin
  FXSLTErrors.Clear;

  Result := xmlDocPtr(NodePtr).Transform(xmlDocPtr(TXMLDocument(Stylesheet).NodePtr), output, XSLTError);
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
  CheckNotNode(Node);

  Errors.FList.Clear;

  xmlDocPtr(NodePtr).ValidateNode(TXMLNode(Node).NodePtr, ErrorCallback);

  if Errors.Count = 0 then
    Exit(FSuccessError)
  else
    Result := Errors.MainError;
end;

function TXMLDocument.ToString: string;
begin
  Result := ToString(False);
end;

{ TXMLSchemaCollection.TItem }

constructor TXMLSchemaCollection.TItem.Create;
begin
  inherited Create;
  Sources := TList<TSource>.Create;
  Resource := -1;
end;

destructor TXMLSchemaCollection.TItem.Destroy;
begin
  FreeMerged;
  FreeAndNil(Sources);
  inherited;
end;

procedure TXMLSchemaCollection.TItem.FreeMerged;
begin
  if Merged <> nil then
  begin
    xmlFreeDoc(Merged);
    Merged := nil;
  end;
end;

{ TXMLSchemaCollection }

threadvar
  /// The collection being compiled in this thread: it alone answers lx2schema:// addresses.
  /// Compilation is synchronous, so a per-thread pointer is enough, and the global libxml2
  /// loader stays shared by all threads.
  CurrentSchemaLoader: TXMLSchemaCollection;

var
  DefaultEntityLoader: xmlExternalEntityLoader;

/// Structured libxml2 errors (schema parsing and document validation) are collected into
/// the TXMLErrors passed as userData. Called from C code: no exception may escape.
procedure SchemaErrorCallback(userData: Pointer; const error: xmlErrorPtr); cdecl;
begin
  try
    TXMLErrors(userData).FList.Add(TXMLError.Create(TXmlParseError.Create(error^)) as IXMLParseError);
  except
  end;
end;

/// Global libxml2 external entity loader: the resource addresses of the collection being
/// compiled are served from memory, everything else goes to the loader installed before it.
function SchemaEntityLoader(const URL, ID: PUTF8Char; context: xmlParserCtxtPtr): xmlParserInputPtr; cdecl;
begin
  Result := nil;
  try
    if (CurrentSchemaLoader <> nil) and (URL <> nil) then
      Result := CurrentSchemaLoader.LoadResource(URL);
    if (Result = nil) and Assigned(DefaultEntityLoader) then
      Result := DefaultEntityLoader(URL, ID, context);
  except
    Result := nil;
  end;
end;

/// Puts SchemaEntityLoader in front of the libxml2 loader. Checked before every compilation:
/// after the library is unloaded and loaded again, libxml2 is back to its own loader.
procedure InstallSchemaEntityLoader;
begin
  var Current := xmlGetExternalEntityLoader();
  if Pointer(@Current) = Pointer(@SchemaEntityLoader) then
    Exit;

  TMonitor.Enter(GlobalLock);
  try
    Current := xmlGetExternalEntityLoader();
    if Pointer(@Current) <> Pointer(@SchemaEntityLoader) then
    begin
      DefaultEntityLoader := Current;
      xmlSetExternalEntityLoader(SchemaEntityLoader);
    end;
  finally
    TMonitor.Exit(GlobalLock);
  end;
end;

/// The tail of a resource address, safe for xmlCanonicPath and xmlBuildURI: characters
/// outside the RFC 3986 unreserved set become underscores. The tail only makes the
/// diagnostics readable, the resource is found by its number.
function ResourceUrlTail(const Name: string): RawByteString;
begin
  SetLength(Result, System.Length(Name));
  for var I := 1 to System.Length(Name) do
    if CharInSet(Name[I], ['A'..'Z', 'a'..'z', '0'..'9', '.', '-', '_', '~', ':', '/']) then
      Result[I] := AnsiChar(Name[I])
    else
      Result[I] := '_';
end;

constructor TXMLSchemaCollection.Create;
begin
  inherited Create;
  FErrors := TXMLErrors.Create;
  FErrors._AddRef;
  FItems := TObjectList<TItem>.Create;
end;

destructor TXMLSchemaCollection.Destroy;
begin
  Invalidate;
  FreeAndNil(FItems);
  FErrors._Release;
  inherited;
end;

procedure TXMLSchemaCollection.Invalidate;
begin
  FCompiled := False;
  // The schema holds pointers into the root wrapper: the schema goes first, then the document.
  if FSchema <> nil then
  begin
    xmlSchemaFree(FSchema);
    FSchema := nil;
  end;
  if FRootDoc <> nil then
  begin
    xmlFreeDoc(FRootDoc);
    FRootDoc := nil;
  end;
  for var Item in FItems do
    Item.FreeMerged;
  FErrors.Clear;
end;

procedure TXMLSchemaCollection.AddCollection(const otherCollection: IXMLSchemaCollection);
begin
  if otherCollection = nil then
    Exit;

  var Src := TXMLSchemaCollection(otherCollection);
  if Src = Self then
    Exit;

  for var Item in Src.FItems do
    for var Source in Item.Sources do
      Add(Item.NamespaceURI, Source.Doc, Source.Resolver);
end;

procedure TXMLSchemaCollection.Add(const NamespaceURI: string; const Doc: IXMLDocument; const Resolver: IXMLResolver);
var
  Item: TItem;
  Source: TSource;
begin
  if Doc = nil then
    raise EArgumentNilException.Create('Doc');

  var Index := IndexOf(NamespaceURI);
  if Index >= 0 then
    Item := FItems[Index]
  else
  begin
    Item := TItem.Create;
    Item.NamespaceURI := NamespaceURI;
    FItems.Add(Item);
  end;

  for var Existing in Item.Sources do
    if TXMLDocument(Existing.Doc).NodePtr = TXMLDocument(Doc).NodePtr then
      Exit;

  Source.Doc := Doc;
  Source.Resolver := Resolver;
  Item.Sources.Add(Source);

  Invalidate;
end;

function TXMLSchemaCollection.ReserveResource(const Name: string): Integer;
begin
  Result := FResources.Add(nil);
  FResourceUrls.Add(cResourcePrefix + RawByteString(IntToStr(Result)) + '/' + ResourceUrlTail(Name));
end;

function TXMLSchemaCollection.ResourceUrl(Index: Integer): RawByteString;
begin
  Result := FResourceUrls[Index];
end;

function TXMLSchemaCollection.AbsoluteLocation(const Location, BaseUrl: string): string;
var
  Args: TXmlArgs;
begin
  if BaseUrl = '' then
    Exit(Location);

  var Uri := xmlBuildURI(Args.StrPtr(Location), Args.StrPtr(BaseUrl));
  if Uri = nil then
    Exit(Location);

  Result := UTF8ToString(Uri);
  xmlFree(Uri);
end;

procedure TXMLSchemaCollection.AddWarning(Code: Integer; const Text, Url: string);
var
  Err: xmlError;
begin
  var Msg := UTF8Encode(Text);
  var Source := UTF8Encode(Url);
  FillChar(Err, SizeOf(Err), 0);
  Err.domain := Ord(XML_FROM_SCHEMASP);
  Err.code := Code;
  Err.level := XML_ERR_WARNING;
  Err.message := Pointer(Msg);
  Err.&file := Pointer(Source);
  FErrors.FList.Add(TXMLError.Create(TXmlParseError.Create(Err)) as IXMLParseError);
end;

procedure TXMLSchemaCollection.Unlocated(const Location, BaseUrl, Element: string);
begin
  var Absolute := AbsoluteLocation(Location, BaseUrl);
  if FUnlocated.ContainsKey(Absolute) then
    Exit;
  FUnlocated.Add(Absolute, True);
  AddWarning(Ord(XML_SCHEMAP_WARN_UNLOCATED_SCHEMA),
    Format('Failed to locate a schema at location ''%s''. Skipping the %s', [Absolute, Element]), BaseUrl);
end;

function TXMLSchemaCollection.ResolveLocation(const Location, BaseUrl: string; const Resolver: IXMLResolver): Integer;
var
  Data: TBytes;
begin
  var Absolute := AbsoluteLocation(Location, BaseUrl);
  if FLocations.TryGetValue(Absolute, Result) then
    Exit;

  if Resolver <> nil then
    Data := Resolver.Resolve(Absolute);
  // A document loaded from a file pulls its neighbours from disk, as libxml2 itself would.
  // A document from memory has no base address, so there is nowhere to look for a relative one.
  if (Data = nil) and (BaseUrl <> '') and FileExists(Absolute) then
    Data := TFile.ReadAllBytes(Absolute);
  if Data = nil then
    Exit(-1);

  // The slot is taken before the document is processed: circular includes find it taken.
  Result := ReserveResource(Absolute);
  FLocations.Add(Absolute, Result);

  var Doc := xmlDoc.Create(Data, DefaultParserOptions);
  if Doc = nil then
  begin
    // libxml2 reports the syntax error while parsing the schema, with the resource address and line.
    FResources[Result] := Data;
    Exit;
  end;

  try
    PrepareSchema(Result, Doc, Absolute, Resolver);
  finally
    xmlFreeDoc(Doc);
  end;
end;

procedure TXMLSchemaCollection.PrepareSchema(Index: Integer; Doc: xmlDocPtr; const BaseUrl: string; const Resolver: IXMLResolver);
begin
  var Root := Doc.documentElement;
  if Root <> nil then
  begin
    // xs:import, xs:include and xs:redefine appear only among the direct children of xs:schema.
    var Elem := Root.FirstElementChild;
    while Elem <> nil do
    begin
      var Next := Elem.NextElementSibling;
      if Elem.NamespaceURI = cSchemaNs then
      begin
        var Name := Elem.LocalName;
        if Name = cImport then
        begin
          var Target := IndexOf(UTF8ToString(Elem.GetAttribute(cNamespace)));
          if Target >= 0 then
            Elem.SetAttribute(cSchemaLocation, ResourceUrl(FItems[Target].Resource))
          else if Elem.HasAttribute(cSchemaLocation) then
          begin
            var Location := UTF8ToString(Elem.GetAttribute(cSchemaLocation));
            var Found := ResolveLocation(Location, BaseUrl, Resolver);
            if Found >= 0 then
              Elem.SetAttribute(cSchemaLocation, ResourceUrl(Found))
            else
            begin
              // An import without a location is merely noted by libxml2: references to the
              // namespace stay legal, and its components come from other parts of the set.
              Elem.RemoveAttribute(cSchemaLocation);
              Unlocated(Location, BaseUrl, cImport);
            end;
          end;
        end
        else if (Name = cInclude) or (Name = cRedefine) then
        begin
          // An empty location is left to libxml2: the missing mandatory schemaLocation is its error.
          var Location := UTF8ToString(Elem.GetAttribute(cSchemaLocation));
          if Location <> '' then
          begin
            var Found := ResolveLocation(Location, BaseUrl, Resolver);
            if Found >= 0 then
              Elem.SetAttribute(cSchemaLocation, ResourceUrl(Found))
            else
            begin
              xmlUnlinkNode(Elem);
              xmlFreeNode(Elem);
              Unlocated(Location, BaseUrl, UTF8ToString(Name));
            end;
          end;
        end;
      end;
      Elem := Next;
    end;
  end;

  FResources[Index] := Doc.ToBytes('UTF-8');
end;

function TXMLSchemaCollection.LoadResource(const Url: PUTF8Char): xmlParserInputPtr;
begin
  Result := nil;
  if FResources = nil then
    Exit;

  var P := Url;
  var Prefix := PUTF8Char(cResourcePrefix);
  while Prefix^ <> #0 do
  begin
    if P^ <> Prefix^ then
      Exit;
    Inc(P);
    Inc(Prefix);
  end;

  var Index := 0;
  var Digits := 0;
  while CharInSet(P^, ['0'..'9']) do
  begin
    Index := Index * 10 + Ord(P^) - Ord('0');
    Inc(P);
    Inc(Digits);
  end;
  if (Digits = 0) or (Digits > 9) or (Index >= FResources.Count) then
    Exit;

  var Data := FResources[Index];
  if Data = nil then
    Exit;

  // Flags 0: libxml2 copies the buffer and does not depend on the lifetime of the TBytes.
  Result := xmlNewInputFromMemory(Url, @Data[0], System.Length(Data), xmlParserInputFlags(0));
end;

procedure TXMLSchemaCollection.Compile;

  function AttrValue(const Value: string): RawByteString;
  begin
    Result := xmlEscapeString(UTF8Encode(Value));
  end;

var
  Wrapper, Root: RawByteString;
begin
  Invalidate;

  FResources := TList<TBytes>.Create;
  FResourceUrls := TList<RawByteString>.Create;
  FLocations := TDictionary<string, Integer>.Create;
  FUnlocated := TDictionary<string, Boolean>.Create;
  try
    // The slots of the wrappers and sources are taken up front: an import of a namespace of
    // the collection and an include of a document loaded from a file refer to them before
    // the documents themselves are processed, mutual references included.
    for var Item in FItems do
    begin
      if Item.NamespaceURI <> '' then
        Item.Resource := ReserveResource(Item.NamespaceURI)
      else
        Item.Resource := ReserveResource('no-namespace');
      SetLength(Item.SourceResources, Item.Sources.Count);
      for var I := 0 to Item.Sources.Count - 1 do
      begin
        var Url := Item.Sources[I].Doc.Url;
        if Url <> '' then
        begin
          Item.SourceResources[I] := ReserveResource(Url);
          FLocations.AddOrSetValue(Url, Item.SourceResources[I]);
        end
        else
          Item.SourceResources[I] := ReserveResource(Item.NamespaceURI + '/source' + IntToStr(I));
      end;
    end;

    for var Item in FItems do
    begin
      Wrapper := '<xs:schema xmlns:xs="' + cSchemaNs + '"';
      if Item.NamespaceURI <> '' then
        Wrapper := Wrapper + ' targetNamespace="' + AttrValue(Item.NamespaceURI) + '"';
      Wrapper := Wrapper + '>';
      for var I := 0 to Item.Sources.Count - 1 do
      begin
        var Source := Item.Sources[I];
        var Copy := xmlDocPtr(TXMLDocument(Source.Doc).NodePtr).Clone(True);
        try
          PrepareSchema(Item.SourceResources[I], Copy, Source.Doc.Url, Source.Resolver);
        finally
          xmlFreeDoc(Copy);
        end;
        Wrapper := Wrapper + '<xs:include schemaLocation="' + ResourceUrl(Item.SourceResources[I]) + '"/>';
      end;
      Wrapper := Wrapper + '</xs:schema>';
      FResources[Item.Resource] := BytesOf(Wrapper);
    end;

    Root := '<xs:schema xmlns:xs="' + cSchemaNs + '" targetNamespace="' + cRootNamespace + '">';
    for var Item in FItems do
    begin
      Root := Root + '<xs:import';
      if Item.NamespaceURI <> '' then
        Root := Root + ' namespace="' + AttrValue(Item.NamespaceURI) + '"';
      Root := Root + ' schemaLocation="' + ResourceUrl(Item.Resource) + '"/>';
    end;
    Root := Root + '</xs:schema>';
    FRootDoc := xmlDoc.Create(Root, DefaultParserOptions);

    InstallSchemaEntityLoader;
    var ctxt := xmlSchemaNewDocParserCtxt(FRootDoc);
    xmlSchemaSetParserStructuredErrors(ctxt, SchemaErrorCallback, FErrors);
    var Previous := CurrentSchemaLoader;
    CurrentSchemaLoader := Self;
    try
      FSchema := xmlSchemaParse(ctxt);
    finally
      CurrentSchemaLoader := Previous;
      xmlSchemaFreeParserCtxt(ctxt);
    end;
  finally
    FreeAndNil(FResources);
    FreeAndNil(FResourceUrls);
    FreeAndNil(FLocations);
    FreeAndNil(FUnlocated);
  end;

  FCompiled := True;
end;

function TXMLSchemaCollection.Validate(const Doc: IXMLDocument): Boolean;
begin
  if Doc = nil then
    raise EArgumentNilException.Create('Doc');

  var Document := TXMLDocument(Doc);
  Document.Errors.Clear;

  if not FCompiled then
    Compile;

  if FSchema = nil then
  begin
    // The schema did not compile: the document is not at fault, but the caller looks at its ParseError.
    for var I := 0 to FErrors.Count - 1 do
      Document.Errors.FList.Add(FErrors[I]);
    Exit(False);
  end;

  var vctxt := xmlSchemaNewValidCtxt(FSchema);
  if vctxt = nil then
    Exit(False);
  try
    xmlSchemaSetValidStructuredErrors(vctxt, SchemaErrorCallback, Document.Errors);
    Result := xmlSchemaValidateDoc(vctxt, xmlDocPtr(Document.NodePtr)) = 0;
  finally
    xmlSchemaFreeValidCtxt(vctxt);
  end;
end;

function TXMLSchemaCollection.MergedDoc(Item: TItem): xmlDocPtr;

  function IsLink(const Node: xmlNodePtr): Boolean;
  begin
    Result := (Node.NamespaceURI = cSchemaNs) and ((Node.LocalName = cInclude) or (Node.LocalName = cImport));
  end;

  function HasImport(const Root: xmlNodePtr; const Namespace: RawByteString): Boolean;
  begin
    var Elem := Root.FirstElementChild;
    while Elem <> nil do
    begin
      if (Elem.NamespaceURI = cSchemaNs) and (Elem.LocalName = cImport) and (Elem.GetAttribute(cNamespace) = Namespace) then
        Exit(True);
      Elem := Elem.NextElementSibling;
    end;
    Result := False;
  end;

var
  Copy: xmlNodePtr;
begin
  if Item.Merged <> nil then
    Exit(Item.Merged);

  // The declarations of every source under the header of the first one; includes are not
  // needed, their content is already here, imports are carried over one per namespace.
  var Doc := xmlDocPtr(TXMLDocument(Item.Sources[0].Doc).NodePtr).Clone(True);
  var Root := Doc.documentElement;
  if Root <> nil then
  begin
    var Link := Root.FirstElementChild;
    while Link <> nil do
    begin
      var Next := Link.NextElementSibling;
      if (Link.NamespaceURI = cSchemaNs) and (Link.LocalName = cInclude) then
      begin
        xmlUnlinkNode(Link);
        xmlFreeNode(Link);
      end;
      Link := Next;
    end;

    for var I := 1 to Item.Sources.Count - 1 do
    begin
      var Source := xmlDocPtr(TXMLDocument(Item.Sources[I].Doc).NodePtr);
      if Source.documentElement = nil then
        Continue;
      var Elem := Source.documentElement.FirstElementChild;
      while Elem <> nil do
      begin
        if not IsLink(Elem) then
        begin
          if xmlDOMWrapCloneNode(nil, Source, Elem, Copy, Doc, nil, 1, 0) = 0 then
            Root.AppendChild(Copy);
        end
        else if (Elem.LocalName = cImport) and not HasImport(Root, Elem.GetAttribute(cNamespace)) then
        begin
          if xmlDOMWrapCloneNode(nil, Source, Elem, Copy, Doc, nil, 1, 0) = 0 then
            Root.InsertBefore(Copy, Root.FirstElementChild);
        end;
        Elem := Elem.NextElementSibling;
      end;
    end;
  end;

  Item.Merged := Doc;
  Result := Doc;
end;

function TXMLSchemaCollection.Get(const NamespaceURI: string): IXMLDocument;
begin
  var Index := IndexOf(NamespaceURI);
  if Index < 0 then
    Exit(nil);

  var Item := FItems[Index];
  if Item.Sources.Count = 1 then
    Exit(Item.Sources[0].Doc);

  // The merged document belongs to the collection: the wrapper must not free it, and Cast()
  // would create an owning one.
  var Merged := MergedDoc(Item);
  if Merged._private <> nil then
    Result := TXMLDocument(Merged._private)
  else
    Result := TXMLDocument.Create(Merged, False);
end;

function TXMLSchemaCollection.Get_Errors: IXMLErrors;
begin
  Result := FErrors;
end;

function TXMLSchemaCollection.Get_Length: NativeInt;
begin
  Result := FItems.Count;
end;

function TXMLSchemaCollection.Get_NamespaceURI(Index: NativeInt): string;
begin
  Result := FItems[Index].NamespaceURI;
end;

function TXMLSchemaCollection.IndexOf(const NamespaceURI: string): NativeInt;
begin
  for var I := 0 to FItems.Count - 1 do
    if FItems[I].NamespaceURI = NamespaceURI then
      Exit(I);
  Result := -1;
end;

procedure TXMLSchemaCollection.Remove(const NamespaceURI: string);
begin
  var Index := IndexOf(NamespaceURI);
  if Index >= 0 then
  begin
    Invalidate;
    FItems.Delete(Index);
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
    {if NsPtr.context = nil then
      xmlFreeNs(NsPtr);}
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
    Prop := Prop.next;
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
  var Args: TXmlArgs;
  xmlFree(NsPtr.href);
  NsPtr.href := xmlStrdup(Args.StrPtr(Text));
end;

function TXMLNsNode.Transform(const stylesheet: IXMLDocument; out S: string): Boolean;
begin
  Result := False;
end;

function TXMLNsNode.Transform(const stylesheet: IXMLDocument; out S: RawByteString): Boolean;
begin
  Result := False;
end;

function TXMLNsNode.Transform(const stylesheet: IXMLDocument; out doc: IXMLDocument): Boolean;
begin
  Result := False;
end;

function TXMLNsNode.Transform(const stylesheet: IXMLDocument; Stream: TStream): Boolean;
begin
  Result := False;
end;

function TXMLNsNode.TransformNode(const stylesheet: IXMLDocument): string;
begin
  Result := '';
end;

function TXMLNsNode.TransformNodeToStream(const stylesheet: IXMLDocument; const output: TStream): Boolean;
begin
  Result := False;
end;

function TXMLNsNode.TransformNodeToObject(const stylesheet, output: IXMLDocument): Boolean;
begin
  Result := False;
end;

{ TXMLNsAttribute }

destructor TXMLNsAttribute.Destroy;
begin
  inherited;
end;

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

initialization
  GlobalLock := TObject.Create;

finalization
  FreeAndNil(GlobalLock);

end.
