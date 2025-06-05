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
/// This Unit provides Interface based DOM model, that is as close to MSXML 6 as possible.
/// It also contains additional functions that make it easier to work in Delphi, primarily the Save & Load methods, and some more
///</summary>
unit LX2.DOM;

interface

uses
  libxml2.API, LX2.Types,
  System.Types, System.SysUtils, System.Classes, System.Variants, System.Generics.Collections;

const
  NODE_INVALID = $00000000;
  NODE_ELEMENT = $00000001;
  NODE_ATTRIBUTE = $00000002;
  NODE_TEXT = $00000003;
  NODE_CDATA_SECTION = $00000004;
  NODE_ENTITY_REFERENCE = $00000005;
  NODE_ENTITY = $00000006;
  NODE_PROCESSING_INSTRUCTION = $00000007;
  NODE_COMMENT = $00000008;
  NODE_DOCUMENT = $00000009;
  NODE_DOCUMENT_TYPE = $0000000A;
  NODE_DOCUMENT_FRAGMENT = $0000000B;
  NODE_NOTATION = $0000000C;

type
  DOMNodeType = Cardinal;

  IXMLNodeBase = interface;
  IXMLNode = interface;
  IXMLAttribute = interface;
  IXMLDocument = interface;
  IXMLElement = interface;
  IXMLDocumentFragment = interface;

  IXMLEnumerator = interface
    ['{968817F3-A3E3-47B2-91C0-3DA96F0679E5}']
    function  GetCurrent: IXMLNode;
    function  MoveNext: Boolean;
    procedure Reset;
    property  Current: IXMLNode read GetCurrent;
  end;

  IXMLError = interface(IInvokable)
    ['{050FC792-9EA0-42ED-9998-7BEDE248D441}']
    function Get_errorCode: Integer;
    function Get_url: string;
    function Get_reason: string;
    function Get_srcText: string;
    function Get_line: Integer;
    function Get_linepos: Integer;
    function Get_filepos: Integer;
    function Get_Level: xmlErrorLevel;
    property ErrorCode: Integer read Get_errorCode;
    property Url: string read Get_url;
    property Reason: string read Get_reason;
    property SrcText: string read Get_srcText;
    property Line: Integer read Get_line;
    property LinePos: Integer read Get_linepos;
    property FilePos: Integer read Get_filepos;
    property Level: xmlErrorLevel read Get_Level;
  end;

  IXMLErrors = interface
    ['{265D0313-3550-40F7-B00A-AE15E5DC10DD}']
    function  Get_Count: NativeUInt;
    function  Get_Item(Index: NativeUInt): IXMLError;
    function  GetEnumerator: TEnumerator<IXMLError>;
    procedure Clear;
    property  Count: NativeUInt read Get_Count;
    property  Items[Index: NativeUInt]: IXMLError read Get_Item; default;
  end;

  IXMLAttributesEnumerator = interface
    ['{B4463181-232A-43FA-B405-016DCB87CBF0}']
    function  GetCurrent: IXMLAttribute;
    function  MoveNext: Boolean;
    procedure Reset;
    property  Current: IXMLAttribute read GetCurrent;
  end;

  IXMLNodeList = interface(IInvokable)
    { MSXMLDOMNodeList }
    function  Get_Item(index: NativeInt): IXMLNode;
    function  Get_Length: NativeInt;
    function  NextNode: IXMLNode;
    procedure Reset;
    property  Item[index: NativeInt]: IXMLNode read Get_Item; default;
    property  Length: NativeInt read Get_Length;
    { Delphi enumerable }
    function  GetEnumerator: IXMLEnumerator;
    function  ToArray: TArray<IXMLNode>;
  end;

  IXMLNamedNodeMap = interface(IXMLNodeList)
    ['{21E36CB7-DC37-4AD0-978D-55CEE4815E8D}']
    function GetNamedItem(const Name: string): IXMLNode;
    function SetNamedItem(const NewItem: IXMLNode): IXMLNode;
    function removeNamedItem(const Name: string): IXMLNode;
    function GetQualifiedItem(const BaseName: string; const namespaceURI: string): IXMLNode;
    function RemoveQualifiedItem(const BaseName: string; const namespaceURI: string): IXMLNode;
  end;

  IXMLAttributes = interface(IXMLNamedNodeMap)
    ['{3414F999-1B97-4926-A2EC-CF2740D3DB6D}']
    { MSXMLDOMNodeList }
    function  Get_Item(Index: NativeInt): IXMLAttribute;
    function  Get_Length: NativeInt;
    function  NextNode: IXMLAttribute;
    procedure Reset;
    property  Item[Index: NativeInt]: IXMLAttribute read Get_Item; default;
    property  Length: NativeInt read Get_Length;
    { Delphi enumerable }
    function  GetEnumerator: IXMLAttributesEnumerator;
    function  ToArray: TArray<IXMLAttribute>;
  end;

  IXMLNodeBase = interface(IInvokable)
    ['{2F1F846D-ADE5-4D37-B3D7-CA4EDFC1676D}']
  end;

  IXMLNode = interface(IXMLNodeBase)
    ['{10E23BB6-734C-4B28-8E6B-C33D0EB4F508}']
    function  Ptr: xmlNodePtr;
    procedure Link;
    procedure Unlink;
    function  Get_Value: string;
    property  Value: string read Get_value;
    { MS XML DOM }
    function  Get_NodeName: string;
    function  Get_NodeValue: Variant;
    procedure Set_NodeValue(const Value: Variant);
    function  Get_NodeType: DOMNodeType;
    function  Get_ParentNode: IXMLNode;
    function  Get_ChildNodes: IXMLNodeList;
    function  Get_FirstChild: IXMLNode;
    function  Get_LastChild: IXMLNode;
    function  Get_PreviousSibling: IXMLNode;
    function  Get_NextSibling: IXMLNode;
    function  Get_Attributes: IXMLAttributes;
    function  InsertBefore(const newChild: IXMLNode; refChild: IXMLNode) : IXMLNode;
    function  ReplaceChild(const newChild: IXMLNode; const oldChild: IXMLNode) : IXMLNode;
    function  RemoveChild(const childNode: IXMLNode): IXMLNode;
    function  AppendChild(const newChild: IXMLNode): IXMLNode;
    function  HasChildNodes: Boolean;
    function  Get_OwnerDocument: IXMLDocument;
    function  CloneNode(deep: WordBool): IXMLNode;
    function  Get_Text: string;
    procedure Set_Text(const text: string);
    function  Get_Xml: string;
    function  SelectNodes(const queryString: string): IXMLNodeList;
    function  SelectSingleNode(const queryString: string): IXMLNode;
    function  Get_NamespaceURI: string;
    function  Get_Prefix: string;
    function  Get_BaseName: string;
    property  NodeName: string read Get_NodeName;
    property  NodeValue: Variant read Get_NodeValue write Set_NodeValue;
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
    property  NamespaceURI: string read Get_NamespaceURI;
    property  Prefix: string read Get_Prefix;
    property  BaseName: string read Get_BaseName;
  end;

  IXMLAttribute = interface(IXMLNode)
    ['{A15B548F-C0C4-4347-90F2-D95F6B1A731E}']
    function  Get_Name: string;
    function  Get_Value: string;
    procedure Set_Value(const Value: string);
    property  Name: string read Get_name;
    property  Value: string read Get_value write Set_value;
  end;

  IXMLElement = interface(IXMLNode)
    ['{3D45E8A9-911B-4144-B171-F72AA9C6C0F4}']
    function  GetAttribute(const name: string): string;
    procedure SetAttribute(const name: string; Value: string);
    function  RemoveAttribute(const name: string): Boolean;
    function  GetAttributeNode(const name: string): IXMLAttribute;
    function  RemoveAttributeNode(const Attribute: IXMLAttribute): IXMLAttribute;
    function  GetElementsByTagName(const tagName: string): IXMLNodeList;
    procedure Normalize;
  end;

  IXMLDocumentFragment = interface(IXMLNode)
    ['{B52BF2CA-D722-4A11-A56E-883E25797D6E}']
  end;

  IXMLDocumentType = interface(IXMLNode)
    ['{29D72A9C-DAD4-403A-AB1F-DED633D13BCB}']
  end;

  IXMLCharacterData = interface(IXMLNode)
    ['{CBE3B84E-9AB6-471B-A1F0-8D67228EA376}']
    function  Get_Data: string;
    procedure Set_Data(const data: string);
    function  Get_Length: NativeInt;
    function  SubstringData(Offset: Integer; Count: Integer): string;
    procedure AppendData(const data: string);
    procedure InsertData(Offset: Integer; const Data: string);
    procedure DeleteData(Offset: Integer; Count: Integer);
    procedure ReplaceData(Offset: Integer; Count: Integer; const Data: string);
    property  Data: string read Get_Data write Set_Data;
    property  Length: NativeInt read Get_Length;
  end;

  IXMLText = interface(IXMLCharacterData)
    ['{68E9DA42-127C-4D68-A0A5-A0315E6A5D1D}']
  end;

  IXMLCDATASection = interface(IXMLText)
    ['{03629BE6-5595-4232-AF58-490AD614BA55}']
  end;

  IXMLComment = interface(IXMLCharacterData)
    ['{E079123D-5084-4CED-9123-B56249FF11C9}']
  end;

  IXMLProcessingInstruction = interface(IXMLNode)
    ['{78A63F59-B926-4249-A657-9CEF3727033D}']
    function  Get_Target: string;
    function  Get_Data: string;
    procedure Set_Data(const Value: string);
    property  Target: string read Get_Target;
    property  Data: string read Get_Data write Set_Data;
  end;

  IXMLEntityReference = interface(IXMLNode)
    ['{9E952BA5-89D5-4709-854D-BD47C56176B6}']
  end;

  IXMLSchemaCollection = interface
    ['{2A6AC718-70EB-4EA6-9731-ADA53297D3B3}']
    procedure Add(const namespaceURI: string; Doc: IXMLDocument);
    procedure Remove(const namespaceURI: string);
    function  Get_length: NativeInt;
    function  Get_namespaceURI(index: NativeInt): string;
    function  GetSchema(const namespaceURI: string): IXMLDocument;
    property  Length: NativeInt read Get_length;
    property  NamespaceURI[index: NativeInt]: string read Get_NamespaceURI; default;
  end;

  IXMLDocument = interface(IXMLNode)
    ['{ACAA6E03-6C69-45D9-A8C4-1DC1996CEB17}']
    function  GetErrors: IXMLErrors;
    function  GetXSLTErrors: TStrings;
    function  Load(const Data: Pointer; Size: NativeUInt): Boolean; overload;
    function  Load(const Data: TBytes): Boolean; overload;
    function  Load(const URL: string): Boolean; overload;
    function  Load(Stream: TStream; const Encoding: Utf8String): Boolean; overload;
    function  LoadXML(const XML: RawByteString; const Options: TXmlParserOptions): Boolean; overload;
    function  LoadXML(const XML: string): Boolean; overload;
    procedure ReconciliateNs;
    function  Save(const FileName: string; const Encoding: string = 'UTF-8'; const Options: TxmlSaveOptions = []): Boolean; overload;
    function  Save(Stream: TStream; const Encoding: string = 'UTF-8'; const Options: TxmlSaveOptions = []): Boolean; overload;
    function  ToAnsi(const Encoding: string = 'windows-1251'; const Format: Boolean = False): RawByteString; overload;
    function  ToBytes(const Encoding: string = 'UTF-8'; const Format: Boolean = False): TBytes; overload;
    function  ToString(const Format: Boolean): string; overload;
    function  ToString: string; overload;
    function  ToUtf8(const Format: Boolean = False): RawByteString; overload;
    function  Transform(const stylesheet: IXMLDocument; out doc: IXMLDocument): Boolean; overload;
    function  Transform(const stylesheet: IXMLDocument; out S: string): Boolean; overload;
    property  Errors: IXMLErrors read GetErrors;
    property  XSLTErrors: TStrings read GetXSLTErrors;
    { MS XML Like }
    function  Get_Doctype: IXMLDocumentType;
    function  Get_DocumentElement: IXMLElement;
    procedure Set_DocumentElement(const Element: IXMLElement);
    function  CreateElement(const tagName: string): IXMLElement;
    function  CreateDocumentFragment: IXMLDocumentFragment;
    function  CreateTextNode(const data: string): IXMLText;
    function  CreateComment(const data: string): IXMLComment;
    function  CreateCDATASection(const data: string): IXMLCDATASection;
    function  CreateProcessingInstruction(const target: string; const data: string): IXMLProcessingInstruction;
    function  CreateAttribute(const name: string): IXMLAttribute;
    function  GetElementsByTagName(const tagName: string): IXMLNodeList;
    function  CreateNode(NodeType: Integer; const name: string; const namespaceURI: string): IXMLNode;
    function  NodeFromID(const idString: string): IXMLNode;
    function  Get_ReadyState: Integer;
    function  Get_ParseError: IXMLError;
    function  Get_Url: string;
    function  Get_ValidateOnParse: Boolean;
    procedure Set_ValidateOnParse(isValidating: Boolean);
    function  Get_ResolveExternals: Boolean;
    procedure Set_ResolveExternals(isResolving: Boolean);
    function  Get_PreserveWhiteSpace: Boolean;
    procedure Set_PreserveWhiteSpace(isPreserving: Boolean);
    property  Doctype: IXMLDocumentType read Get_Doctype;
    property  DocumentElement: IXMLElement read Get_DocumentElement write Set_DocumentElement;
    property  ReadyState: Integer read Get_readyState;
    property  ParseError: IXMLError read Get_parseError;
    property  Url: string read Get_Url;
    property  ValidateOnParse: Boolean read Get_ValidateOnParse write Set_ValidateOnParse;
    property  ResolveExternals: Boolean read Get_ResolveExternals write Set_ResolveExternals;
    property  PreserveWhiteSpace: Boolean read Get_PreserveWhiteSpace write Set_PreserveWhiteSpace;
    function  Validate: IXMLError;
    function  ValidateNode(const node: IXMLNode): IXMLError;
  end;

  TXMLObject = class(TInterfacedObject, IInvokable)
  private
    class var FOldDeregisterNodeFunc: xmlDeregisterNodeFunc;
  protected
    class constructor Create;
    class property OldDeregisterNodeFunc: xmlDeregisterNodeFunc read FOldDeregisterNodeFunc;
  end;

  TXMLDocument = class;
  TXMLNode = class;

  TXMLError = class(TInterfacedObject, IXMLError)
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
  private
    FList: TList<IXMLError>;
  protected
    function  Get_Count: NativeUInt; inline;
    function  Get_Item(Index: NativeUInt): IXMLError; inline;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function  MainError: IXMLError;
    function  GetEnumerator: TEnumerator<IXMLError>;
    property  Count: NativeUInt read Get_Count;
    property  Items[Index: NativeUInt]: IXMLError read Get_Item; default;
  end;

  TXMLEnumerator = class(TInterfacedObject, IXMLEnumerator)
  private
    FNode: xmlNodePtr;
    FCurrent: xmlNodePtr;
  protected
    function  DoMoveNext: Boolean; virtual;
    function  Predicate(node: xmlNodePtr): Boolean; virtual;
    { IEnumerator }
    function  GetCurrent: IXMLNode;
  public
    constructor Create(Node: xmlNodePtr);
    procedure Reset; virtual;
    property  Current: xmlNodePtr read FCurrent;
    function  MoveNext: Boolean;
  end;

  ///<summary>
  /// MS DOM IXNMLDOMNodeList compatible & Delphi enumerable interface
  /// Enumerates sibling nodes started from First
  ///</summary>
  TXMLNodeList = class(TInterfacedObject, IXMLNodeList)
  private
    FEnumerator: IXMLEnumerator;
    FNode: xmlNodePtr;
  protected
    function  CreateEnumerator: TXMLEnumerator; virtual;
    property  Node: xmlNodePtr read FNode;
  public
    constructor Create(Node: xmlNodePtr);
    { MSXMLDOMNodeList }
    function  Get_Item(index: NativeInt): IXMLNode;
    function  Get_Length: NativeInt;
    function  NextNode: IXMLNode;
    procedure Reset;
    property  Item[index: NativeInt]: IXMLNode read Get_item; default;
    property  Length: NativeInt read Get_length;
    { Delphi enumerable }
    function  GetEnumerator: IXMLEnumerator;
    function  ToArray: TArray<IXMLNode>;
    property  Enumerator: IXMLEnumerator read FEnumerator;
  end;

  ///<summary>
  /// MS DOM IXNMLDOMNodeList compatible & Delphi enumerable interface
  /// Enumerator based on array
  ///</summary>
  TXMLNodeArrayList = class(TInterfacedObject, IXMLNodeList)
  private type
    TEnumerator = class(TInterfacedObject, IXMLEnumerator)
    private
      List: TXMLNodeArrayList;
      Index: NativeInt;
    public
      constructor Create(List: TXMLNodeArrayList);
      function  GetCurrent: IXMLNode; inline;
      function  MoveNext: Boolean; inline;
      procedure Reset; inline;
    end;
  private
    FCurrent: NativeInt;
    FLength: NativeInt;
    FNodes: TArray<xmlNodePtr>;
  public
    constructor Create(const Nodes: TArray<xmlNodePtr>);
    { MSXMLDOMNodeList }
    function  Get_item(Index: NativeInt): IXMLNode; inline;
    function  Get_length: NativeInt; inline;
    function  NextNode: IXMLNode; inline;
    procedure Reset; inline;
    property  Item[index: NativeInt]: IXMLNode read Get_item; default;
    property  Length: NativeInt read Get_length;
    { Delphi enumerator }
    function  GetCurrent: IXMLNode; inline;
    function  MoveNext: Boolean; inline;
    property  Current: IXMLNode read GetCurrent;
    { Delphi enumerable }
    function  GetEnumerator: IXMLEnumerator; inline;
    function  ToArray: TArray<IXMLNode>;
  end;

  TXMLNamedNodeMap = class(TXMLNodeArrayList, IXMLNamedNodeMap)
  protected
    function  GetItemByName(const Name: string): xmlNodePtr;
    function  GetQualifiedItemByName(const BaseName: string; const NamespaceURI: string): xmlNodePtr;
  public
    { IXMLNamedNodeMap }
    function  GetNamedItem(const Name: string): IXMLNode;
    function  SetNamedItem(const NewItem: IXMLNode): IXMLNode; virtual;
    function  RemoveNamedItem(const Name: string): IXMLNode;
    function  GetQualifiedItem(const BaseName: string; const namespaceURI: string): IXMLNode;
    function  RemoveQualifiedItem(const BaseName: string; const namespaceURI: string): IXMLNode;
  end;

  TXMLAttributes = class(TXMLNamedNodeMap, IXMLAttributes)
  private type
    TEnumerator = class(TInterfacedObject, IXMLAttributesEnumerator)
    private
      List: TXMLAttributes;
      Index: Integer;
    public
      constructor Create(List: TXMLAttributes);
      function  GetCurrent: IXMLAttribute; inline;
      function  MoveNext: Boolean; inline;
      procedure Reset; inline;
    end;
  private
    FParent: xmlNodePtr;
  protected
    property  Parent: xmlNodePtr read FParent;
  public
    constructor Create(const Parent: xmlNodePtr);
    { IXMLNamedNodeMap }
    function  SetNamedItem(const NewItem: IXMLNode): IXMLNode; override;
    { IXMLAttributes }
    function  NextNode: IXMLAttribute;
    function  Get_Item(index: NativeInt): IXmlAttribute;
    property  Item[index: NativeInt]: IXmlAttribute read Get_Item; default;
    { Delphi enumerable }
    function  GetEnumerator: IXMLAttributesEnumerator;
    function  ToArray: TArray<IXmlAttribute>;
  end;

  TXMLElementList = class(TXMLNamedNodeMap)
  protected
    function CreateChilds(Parent: xmlNodePtr; Mask: xmlCharPtr): TArray<xmlNodePtr>;
    function CreateDescendants(Parent: xmlNodePtr; Mask: xmlCharPtr): TArray<xmlNodePtr>;
  public
    constructor Create(Parent: xmlNodePtr; Recursive: Boolean; Mask: string = '*');
  end;

  TXMLNode = class(TXMLObject, IXMLNode)
  private
    FLinked: Boolean;
  protected
    function  Ptr: xmlNodePtr;
    function  Get_value: string;
    procedure Link;
    procedure Unlink;
    { IXMLNode }
    function  Get_NodeName: string;
    function  Get_NodeValue: Variant;
    procedure Set_NodeValue(const Value: Variant);
    function  Get_NodeType: DOMNodeType;
    function  Get_ParentNode: IXMLNode;
    function  Get_ChildNodes: IXMLNodeList;
    function  Get_FirstChild: IXMLNode;
    function  Get_LastChild: IXMLNode;
    function  Get_PreviousSibling: IXMLNode;
    function  Get_NextSibling: IXMLNode;
    function  Get_Attributes: IXMLAttributes;
    function  InsertBefore(const NewChild: IXMLNode; RefChild: IXMLNode): IXMLNode;
    function  ReplaceChild(const NewChild: IXMLNode; const OldChild: IXMLNode): IXMLNode;
    function  RemoveChild(const ChildNode: IXMLNode): IXMLNode;
    function  AppendChild(const NewChild: IXMLNode): IXMLNode;
    function  HasChildNodes: Boolean;
    function  Get_OwnerDocument: IXMLDocument;
    function  CloneNode(Deep: WordBool): IXMLNode;
    function  Get_Text: string;
    procedure Set_Text(const Text: string);
    function  Get_Xml: string;
    function  SelectNodes(const QueryString: string): IXMLNodeList;
    function  SelectSingleNode(const QueryString: string): IXMLNode;
    function  Get_NamespaceURI: string;
    function  Get_Prefix: string;
    function  Get_BaseName: string;
  protected
    NodePtr: xmlNodePtr;
    constructor Create(node: xmlNodePtr);
  public
    destructor Destroy; override;
    procedure ReconciliateNs; virtual;
    property  NodeName: string read Get_NodeName;
    property  NodeValue: Variant read Get_NodeValue write Set_NodeValue;
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
    { IXMLAttribute }
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
    function  GetAttribute(const name: string): string;
    procedure SetAttribute(const name: string; Value: string);
    function  RemoveAttribute(const name: string): Boolean;
    function  GetAttributeNode(const name: string): IXMLAttribute;
    function  RemoveAttributeNode(const Attribute: IXMLAttribute): IXMLAttribute;
    function  GetElementsByTagName(const tagName: string): IXMLNodeList;
    procedure Normalize;
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
    FList: TList<TSchema>;
    FRoots: TList<IXMLDocument>;
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
    property  Roots: TList<IXMLDocument> read FRoots;
  end;

  TXMLDocument = class(TXMLNode, IXMLDocument)
  private
    FDocOwner: Boolean;
    FErrors: TXMLErrors;
    FXSLTErrors: TStrings;
    FValidateOnParse: Boolean;
    FResolveExternals: Boolean;
    FPreserveWhiteSpace: Boolean;
    FOptions: TXmlParserOptions;
    FSuccessError: IXMLError;
    function  GetDoc: xmlDocPtr; inline;
    procedure SetDoc(value: xmlDocPtr); inline;
  protected
    procedure ErrorCallback(const error: xmlError); virtual;
    procedure XSLTError(const Msg: string); virtual;
    procedure BeforeLoad;
    property  Doc: xmlDocPtr read GetDoc write SetDoc;
    property  DocOwner: Boolean read FDocOwner;
  protected
    function  GetErrors: IXMLErrors;
    function  GetXSLTErrors: TStrings;
    { IXMLDocument }
    function  Get_doctype: IXMLDocumentType;
    function  Get_documentElement: IXMLElement;
    procedure Set_documentElement(const Element: IXMLElement);
    function  CreateElement(const TagName: string): IXMLElement;
    function  CreateDocumentFragment: IXMLDocumentFragment;
    function  CreateTextNode(const data: string): IXMLText;
    function  CreateComment(const data: string): IXMLComment;
    function  CreateCDATASection(const data: string): IXMLCDATASection;
    function  CreateProcessingInstruction(const target: string; const data: string): IXMLProcessingInstruction;
    function  CreateAttribute(const name: string): IXMLAttribute;
    function  GetElementsByTagName(const tagName: string): IXMLNodeList;
    function  CreateNode(NodeType: Integer; const name: string; const namespaceURI: string): IXMLNode;
    function  NodeFromID(const IdString: string): IXMLNode;
    function  Get_ReadyState: Integer;
    function  Get_ParseError: IXMLError;
    function  Get_Url: string;
    procedure Save(const Url: string); overload;
    function  Get_ValidateOnParse: Boolean;
    procedure Set_ValidateOnParse(IsValidating: Boolean);
    function  Get_ResolveExternals: Boolean;
    procedure Set_ResolveExternals(IsResolving: Boolean);
    function  Get_PreserveWhiteSpace: Boolean;
    procedure Set_PreserveWhiteSpace(IsPreserving: Boolean);
    function  Transform(const Stylesheet: IXMLDocument; out S: string): Boolean; overload;
    function  Transform(const Stylesheet: IXMLDocument; out Doc: IXMLDocument): Boolean; overload;
    function  Validate: IXMLError;
    function  ValidateNode(const node: IXMLNode): IXMLError;
    property  Doctype: IXMLDocumentType read Get_Doctype;
    property  DocumentElement: IXMLElement read Get_DocumentElement write Set_DocumentElement;
    property  ReadyState: Integer read Get_ReadyState;
    property  ParseError: IXMLError read Get_ParseError;
    property  Url: string read Get_Url;
    property  ValidateOnParse: Boolean read Get_ValidateOnParse write Set_ValidateOnParse;
    property  ResolveExternals: Boolean read Get_ResolveExternals write Set_ResolveExternals;
    property  PreserveWhiteSpace: Boolean read Get_PreserveWhiteSpace write Set_PreserveWhiteSpace;
  public
    constructor Create; overload;
    constructor Create(doc: xmlDocPtr; DocOwner: Boolean); overload;
    destructor Destroy; override;

    function  LoadXML(const XML: RawByteString; const Options: TXmlParserOptions): Boolean; overload;
    function  LoadXML(const XML: string): Boolean; overload;
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
    property  XSLTErrors: TStrings read FXSLTErrors;
    property  Options: TXmlParserOptions read FOptions write FOptions;
  end;

  XMLFactory = record
  public
    class function Cast(const Node: xmlNodePtr; Own: Boolean = True): IXMLNode; overload; static; inline;
    class function Cast(const Attr: xmlAttrPtr; Own: Boolean = True): IXMLAttribute; overload; static; inline;
    class function Cast(const Doc: xmlDocPtr; Own: Boolean): IXMLDocument; overload; static; inline;
  end;

implementation

uses
  libxslt.API, LX2.Helpers;

procedure NodeFreeCallback(Node: xmlNodePtr); cdecl;
begin
  if Node._private <> nil then
  begin
    TXMLNode(Node._private).NodePtr := nil;
    TXMLNode(Node._private).Unlink;
    Node._private := nil;
  end;

  if Assigned(TXMLObject.OldDeregisterNodeFunc) then
    TXMLObject.OldDeregisterNodeFunc(Node);
end;

 procedure XSLTErrorHandler(Context: Pointer; const Msg: string);
 begin
   TXMLDocument(Context).XSLTError(Msg);
 end;

{ XMLFactory }

class function XMLFactory.Cast(const Node: xmlNodePtr; Own: Boolean): IXMLNode;
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
  if Own then
    Result.Link;
end;

class function XMLFactory.Cast(const Attr: xmlAttrPtr; Own: Boolean = True): IXMLAttribute;
begin
  if Attr = nil then
    Result := nil
  else if Attr._private = nil then
  begin
    Result := TXMLAttribute.Create(Attr);
    if Own then
      Result.Link;
  end
  else
    Result := TXMLAttribute(Attr._private)
end;

class function XMLFactory.Cast(const Doc: xmlDocPtr; Own: Boolean): IXMLDocument;
begin
  if Doc = nil then
    Result := nil
  else if Doc._private = nil then
    Result := TXMLDocument.Create(Doc, Own)
  else
    Result := TXMLDocument(Doc._private)
end;

{ TXMLObject }

class constructor TXMLObject.Create;
begin
  LX2Lib.Initialize;

  FOldDeregisterNodeFunc := xmlDeregisterNodeDefault(NodeFreeCallback);
end;

{ TXMLEnumerator }

constructor TXMLEnumerator.Create(Node: xmlNodePtr);
begin
  inherited Create;
  FNode := Node;
end;

function TXMLEnumerator.DoMoveNext: Boolean;
begin
  if FCurrent = nil then
    FCurrent := FNode.children
  else
    FCurrent := FCurrent.next;
  Result := FCurrent <> nil;
end;

function TXMLEnumerator.GetCurrent: IXMLNode;
begin
  Result := XMLFactory.Cast(FCurrent);
end;

function TXMLEnumerator.MoveNext: Boolean;
begin
  while True do
  begin
    Result := DoMoveNext;
    if Result and not Predicate(Current) then
      Continue
    else
      Break;
  end;
end;

function TXMLEnumerator.Predicate(Node: xmlNodePtr): Boolean;
begin
  Result := True;
end;

procedure TXMLEnumerator.Reset;
begin
  FCurrent := nil;
end;

{ TXMLElementList }

constructor TXMLElementList.Create(Parent: xmlNodePtr; Recursive: Boolean; Mask: string = '*');
var
  Filter: xmlCharPtr;
  S: RawByteString;
begin
  if Mask = '*' then
    Filter := nil
  else
  begin
    S := UTF8Encode(Mask);
    Filter := Pointer(S);
  end;

  if Parent = nil then
    inherited Create([])
  else if Recursive then
    inherited Create(CreateDescendants(Parent, Filter))
  else
    inherited Create(CreateChilds(Parent, Filter));
end;

function TXMLElementList.CreateChilds(Parent: xmlNodePtr; Mask: xmlCharPtr): TArray<xmlNodePtr>;
var
  Capacity, Index: Integer;
begin
  Capacity := 16;
  SetLength(Result, Capacity);

  Index := 0;
  var Node := Parent.FirstElementChild;
  while Node <> nil do
  begin
    if (Mask = nil) or xmlStrSame(Mask, Node.name) then
    begin
      if Index = Capacity then
      begin
        Inc(Capacity, Capacity shr 1);
        SetLength(Result, Capacity);
      end;
      Result[Index] := Node;
      Inc(Index);
    end;
    Node := Node.NextElementSibling;
  end;
  SetLength(Result, Index);
end;

function TXMLElementList.CreateDescendants(Parent: xmlNodePtr; Mask: xmlCharPtr): TArray<xmlNodePtr>;
var
  Capacity, Index: Integer;

  procedure Process(Parent: xmlNodePtr);
  begin
    var Node := Parent.FirstElementChild;
    while Node <> nil do
    begin
      if (Mask = nil) or xmlStrSame(Mask, Node.name) then
      begin
        if Index = Capacity then
        begin
          Inc(Capacity, Capacity shr 1);
          SetLength(Result, Capacity);
        end;
        Result[Index] := Node;
        Inc(Index);
      end;
      Process(Node);
      Node := Node.NextElementSibling;
    end;
  end;

begin
  Capacity := 16;
  SetLength(Result, Capacity);

  Index := 0;
  Process(Parent);
  SetLength(Result, Index);
end;

{ TXMLNodeArrayList.TEnumerator }

constructor TXMLNodeArrayList.TEnumerator.Create(List: TXMLNodeArrayList);
begin
  inherited Create;
  Self.List := List;
  Self.Index := -1;
end;

function TXMLNodeArrayList.TEnumerator.GetCurrent: IXMLNode;
begin
  Result := List[Index];
end;

function TXMLNodeArrayList.TEnumerator.MoveNext: Boolean;
begin
  Result := Index < List.Length - 1;
  if Result then
    Inc(Index);
end;

procedure TXMLNodeArrayList.TEnumerator.Reset;
begin
  Index := -1;
end;

{ TXMLNodeArrayList }

constructor TXMLNodeArrayList.Create(const Nodes: TArray<xmlNodePtr>);
begin
  inherited Create;
  FCurrent := -1;
  FNodes := Nodes;
  FLength := System.Length(Nodes);
end;

function TXMLNodeArrayList.GetCurrent: IXMLNode;
begin
  Result := XMLFactory.Cast(FNodes[FCurrent]);
end;

function TXMLNodeArrayList.GetEnumerator: IXMLEnumerator;
begin
  Result := TEnumerator.Create(Self);
end;

function TXMLNodeArrayList.Get_Item(Index: NativeInt): IXMLNode;
begin
  Result := XMLFactory.Cast(FNodes[Index]);
end;

function TXMLNodeArrayList.Get_Length: NativeInt;
begin
  Result := FLength;
end;

function TXMLNodeArrayList.MoveNext: Boolean;
begin
  Result := FCurrent < FLength - 1;
  if Result then
    Inc(FCurrent);
end;

function TXMLNodeArrayList.NextNode: IXMLNode;
begin
  if MoveNext then
    Result := Current
  else
    Result := nil;
end;

procedure TXMLNodeArrayList.Reset;
begin
  FCurrent := -1;
end;

function TXMLNodeArrayList.ToArray: TArray<IXMLNode>;
begin
  SetLength(Result, FLength);
  for var I := Low(FNodes) to High(FNodes) do
    Result[I] := XMLFactory.Cast(FNodes[I]);
end;

{ TXMLNodeList }

constructor TXMLNodeList.Create(Node: xmlNodePtr);
begin
  inherited Create;
  FNode := Node;
  FEnumerator := CreateEnumerator;
end;

function TXMLNodeList.CreateEnumerator: TXMLEnumerator;
begin
  Result := TXMLEnumerator.Create(Node);
end;

function TXMLNodeList.GetEnumerator: IXMLEnumerator;
begin
  Result := FEnumerator;
end;

function TXMLNodeList.Get_Item(Index: NativeInt): IXMLNode;
begin
  var Enum := CreateEnumerator;
  for var I := 0 to Index do
    if not Enum.MoveNext then
      Break;
  Enum.Free;

  Result := XMLFactory.Cast(Enum.Current);
end;

function TXMLNodeList.Get_Length: NativeInt;
begin
  Result := 0;
  var Enum := CreateEnumerator;
  while Enum.MoveNext do
    Inc(Result);
  Enum.Free;
end;

function TXMLNodeList.NextNode: IXMLNode;
begin
  if Enumerator.MoveNext then
    Result := Enumerator.Current
  else
    Result := nil;
end;

procedure TXMLNodeList.Reset;
begin
  Enumerator.Reset;
end;

function TXMLNodeList.ToArray: TArray<IXMLNode>;
begin
  var Enum := CreateEnumerator;

  var L := 0;
  while Enum.MoveNext do
    Inc(L);
  SetLength(Result, L);

  Enum.Reset;

  var I := 0;
  while Enum.MoveNext do
  begin
    Result[I] := XMLFactory.Cast(Enum.Current);
    Inc(I);
  end;
  Enum.Free;
end;

{ TXMLNamedNodeMap }

function TXMLNamedNodeMap.GetItemByName(const Name: string): xmlNodePtr;
var
  Prefix, Base: PUTF8Char;
begin
  ResetLocalBuffers;
  SplitXMLName(Name, Prefix, Base);

  for var I := 0 to Length - 1 do
  begin
    var Node := FNodes[I];
    if xmlStrSame(Node.name, Base) then
    begin
      if ((Prefix = nil) and (node.ns = nil)) or xmlStrSame(Prefix, node.ns.prefix) then
        Exit(node);
    end;
  end;

  Result := nil;
end;

function TXMLNamedNodeMap.GetQualifiedItemByName(const BaseName: string; const NamespaceURI: string): xmlNodePtr;
var
  Base, URI: PUTF8Char;
begin
  ResetLocalBuffers;
  Base := LocalXmlStr(BaseName);
  URI := LocalXmlStr(NamespaceURI);

  for var I := 0 to Length - 1 do
  begin
    var Node := FNodes[I];
    if xmlStrSame(Node.name, Base) then
    begin
      if ((URI = nil) and (Node.ns = nil)) or xmlStrSame(URI, Node.ns.href) then
        Exit(Node);
    end;
  end;

  Result := nil;
end;

function TXMLNamedNodeMap.getNamedItem(const Name: string): IXMLNode;
begin
  var Node := GetItemByName(Name);
  if Node = nil then
    Exit(nil);

  Result := XMLFactory.Cast(Node);
end;

function TXMLNamedNodeMap.getQualifiedItem(const BaseName, NamespaceURI: string): IXMLNode;
begin
  var Node := GetQualifiedItemByName(BaseName, NamespaceURI);
  if Node = nil then
    Exit(nil);

  Result := XMLFactory.Cast(Node);
end;

function TXMLNamedNodeMap.removeNamedItem(const Name: string): IXMLNode;
begin
  var Node := GetItemByName(Name);
  if Node = nil then
    Exit(nil);

  xmlUnlinkNode(Node);
  Result := XMLFactory.Cast(Node);
  if Node._private <> nil then
    TXMLNode(Node._private).Unlink;
end;

function TXMLNamedNodeMap.removeQualifiedItem(const BaseName, NamespaceURI: string): IXMLNode;
begin
  var Node := GetQualifiedItemByName(BaseName, namespaceURI);
  if Node = nil then
    Exit(nil);

  xmlUnlinkNode(Node);

  Result := XMLFactory.Cast(Node);
  if Node._private <> nil then
    TXMLNode(Node._private).Unlink;
end;

function TXMLNamedNodeMap.setNamedItem(const NewItem: IXMLNode): IXMLNode;
begin
  var L := System.Length(FNodes);
  SetLength(FNodes, L + 1);
  FNodes[L] := NewItem.Ptr;
end;

{ TXMLAttributes.TEnumerator }

constructor TXMLAttributes.TEnumerator.Create(List: TXMLAttributes);
begin
  inherited Create;
  Self.List := List;
  Self.Index := -1;
end;

function TXMLAttributes.TEnumerator.GetCurrent: IXMLAttribute;
begin
  Result := List[Index];
end;

function TXMLAttributes.TEnumerator.MoveNext: Boolean;
begin
  Result := Index < List.Length - 1;
  if Result then
    Inc(Index);
end;

procedure TXMLAttributes.TEnumerator.Reset;
begin
  Index := -1;
end;

{ TXMLAttributes }

constructor TXMLAttributes.Create(const Parent: xmlNodePtr);
var
  List: TArray<xmlNodePtr>;
begin
  FParent := Parent;

  var L := 0;
  var Prop := Parent.properties;
  while Prop <> nil do
  begin
    Inc(L);
    Prop := Prop.next;
  end;

  SetLength(List, L);
  L := 0;
  Prop := Parent.properties;
  while Prop <> nil do
  begin
    List[L] := xmlNodePtr(Prop);
    Inc(L);
    Prop := Prop.next;
  end;

  inherited Create(List);
end;

function TXMLAttributes.GetEnumerator: IXMLAttributesEnumerator;
begin
  Result := TEnumerator.Create(Self);
end;

function TXMLAttributes.Get_item(Index: NativeInt): IXmlAttribute;
begin
  Result := XMLFactory.Cast(xmlAttrPtr(FNodes[Index]));
end;

function TXMLAttributes.NextNode: IXMLAttribute;
begin
  Result := inherited NextNode as IXMLAttribute;
end;

function TXMLAttributes.setNamedItem(const NewItem: IXMLNode): IXMLNode;
begin
  Result := XMLFactory.Cast(xmlAttrPtr(xmlAddChild(Parent, NewItem.Ptr)));
  if Result <> nil then
    inherited;
end;

function TXMLAttributes.ToArray: TArray<IXmlAttribute>;
begin
  SetLength(Result, Length);

  for var I := 0 to Length - 1 do
    Result[I] := XMLFactory.Cast(xmlAttrPtr(FNodes));
end;

{ TXMLNode }

constructor TXMLNode.Create(Node: xmlNodePtr);
begin
  inherited Create;
  NodePtr := Node;
  NodePtr._private := Self;
end;

destructor TXMLNode.Destroy;
begin
  if NodePtr <> nil then
  begin
    NodePtr._private := nil;
    if not FLinked then
    begin
      xmlFreeNode(NodePtr);
      NodePtr := nil;
    end;
  end;

  inherited;
end;

function TXMLNode.AppendChild(const NewChild: IXMLNode): IXMLNode;
begin
  Result := TXMLNode.Create(LX2CheckNodeExists(xmlAddChild(NodePtr, NewChild.Ptr)));
  if Result <> nil then Result.Link;
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
  Result := NodePtr.BaseName;
end;

function TXMLNode.Get_ChildNodes: IXMLNodeList;
begin
  Result := TXMLNodeList.Create(NodePtr.Children);
end;

function TXMLNode.Get_FirstChild: IXMLNode;
begin
  Result := XMLFactory.Cast(NodePtr.children);
  if Result <> nil then Result.Link;
end;

function TXMLNode.Get_LastChild: IXMLNode;
begin
  Result := XMLFactory.Cast(NodePtr.last);
  if Result <> nil then Result.Link;
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
  Result := XMLFactory.Cast(NodePtr.next);
  if Result <> nil then Result.Link;
end;

function TXMLNode.Get_NodeName: string;
begin
  Result := NodePtr.NodeName;
end;

function TXMLNode.Get_NodeType: DOMNodeType;
begin
  Result := DOMNodeType(NodePtr.&type);
end;

function TXMLNode.Get_NodeValue: Variant;
begin
  case NodePtr.&type of
    XML_ATTRIBUTE_NODE:     Result := NodePtr.text;
    XML_CDATA_SECTION_NODE,
    XML_COMMENT_NODE,
    XML_TEXT_NODE,
    XML_PI_NODE:            Result := NodePtr.text;
  else
    Result := null;
  end;
end;

function TXMLNode.Get_OwnerDocument: IXMLDocument;
begin
  Result := XMLFactory.Cast(NodePtr.OwnerDocument, False);
end;

function TXMLNode.Get_ParentNode: IXMLNode;
begin
  Result := XMLFactory.Cast(NodePtr.parent);
  if Result <> nil then Result.Link;
end;

function TXMLNode.Get_Prefix: string;
begin
  Result := NodePtr.Prefix;
end;

function TXMLNode.Get_PreviousSibling: IXMLNode;
begin
  Result := XMLFactory.Cast(NodePtr.prev);
  if Result <> nil then Result.Link;
end;

function TXMLNode.Get_Text: string;
begin
  Result := NodePtr.Text;
end;

function TXMLNode.Get_Value: string;
begin
  Result := NodePtr.Value;
end;

function TXMLNode.Get_Xml: string;
begin
  Result := NodePtr.Xml;
end;

function TXMLNode.HasChildNodes: Boolean;
begin
  Result := NodePtr.HasChildNodes;
end;

function TXMLNode.InsertBefore(const NewChild: IXMLNode; RefChild: IXMLNode): IXMLNode;
begin
  Result := XMLFactory.Cast(NodePtr.InsertBefore(NewChild.Ptr, RefChild.Ptr));
  if Result <> nil then Result.Link;
end;

function TXMLNode.Ptr: xmlNodePtr;
begin
  Result := NodePtr;
end;

procedure TXMLNode.ReconciliateNs;
begin
  NodePtr.ReconciliateNs;
end;

procedure TXMLNode.Link;
begin
  if FLinked then
    Exit;
  _AddRef;
  FLinked := True;
end;

function TXMLNode.RemoveChild(const ChildNode: IXMLNode): IXMLNode;
begin
  Result := XMLFactory.Cast(NodePtr.RemoveChild(TXMLNode(ChildNode).NodePtr));
  Result.Unlink;
end;

function TXMLNode.ReplaceChild(const NewChild, OldChild: IXMLNode): IXMLNode;
begin
  Result := XMLFactory.Cast(NodePtr.ReplaceChild(TXMLNode(NewChild).NodePtr, TXMLNode(OldChild).NodePtr));
  oldChild.Unlink;
end;

function TXMLNode.SelectNodes(const QueryString: string): IXMLNodeList;
begin
  Result := TXMLNodeArrayList.Create(NodePtr.SelectNodes(QueryString));
end;

function TXMLNode.SelectSingleNode(const QueryString: string): IXMLNode;
begin
  Result := XMLFactory.Cast(NodePtr.SelectSingleNode(QueryString));
end;

procedure TXMLNode.Set_NodeValue(const Value: Variant);
begin
  case NodePtr.&type of
    XML_ATTRIBUTE_NODE:     NodePtr.text := VarToStr(Value); //TODO: What a rules to convert data types?
    XML_CDATA_SECTION_NODE,
    XML_COMMENT_NODE,
    XML_TEXT_NODE,
    XML_PI_NODE:            NodePtr.text := VarToStr(Value);
  else
    LX2NodeTypeError(NodePtr.&type);
  end;
end;

procedure TXMLNode.Set_Text(const text: string);
begin
  NodePtr.Text := text;
end;

procedure TXMLNode.Unlink;
begin
  if FLinked then
    _Release;
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
  Result := AttrPtr.Name;
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
    ResetLocalBuffers;
    children := xmlNewDocText(AttrPtr.parent.doc, LocalXmlStr(attrValue));
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

function TXMLElement.GetAttribute(const name: string): string;
begin
  Result := NodePtr.Attribute[name];
end;

function TXMLElement.GetAttributeNode(const name: string): IXMLAttribute;
begin
  Result := XMLFactory.Cast(NodePtr.FindAttribute(name));
end;

function TXMLElement.GetElementsByTagName(const tagName: string): IXMLNodeList;
begin
  Result := TXMLElementList.Create(NodePtr, True, tagName);
end;

procedure TXMLElement.Normalize;
begin
  var Node := NodePtr.children;
  while Node <> nil do
  begin
    if Node.&type in [XML_TEXT_NODE, XML_CDATA_SECTION_NODE] then
    begin
      var Next := Node.next;
      while Next <> nil do
      begin
        if (Next.&type in [XML_TEXT_NODE, XML_CDATA_SECTION_NODE]) then
        begin
          xmlNodeAddContent(Node, xmlNodeGetContent(Next));
          var Tmp := Next;
          Next := Next.next;
          xmlUnlinkNode(Tmp);
          xmlFreeNode(Tmp);
        end
        else
          Break;
      end;
      Break;
    end;
    Node := Node.next;
  end;
end;

function TXMLElement.RemoveAttribute(const Name: string): Boolean;
var
  Prefix, LocalName: xmlCharPtr;
begin
  ResetLocalBuffers;

  SplitXMLName(Name, Prefix, LocalName);
  if Prefix = nil then
    Result := xmlUnsetProp(NodePtr, LocalName) = 0
  else
  begin
    var Ns := NodePtr.SearchNs(Prefix);
    if Ns <> nil then
      Result := xmlUnsetNsProp(NodePtr, Ns, LocalName) = 0
    else
      Result := False;
  end;
end;

function TXMLElement.RemoveAttributeNode(const Attribute: IXMLAttribute): IXMLAttribute;
begin
  if (Attribute <> nil) and (Attribute.Ptr.parent = NodePtr) then
  begin
    Result := Attribute;
    xmlUnlinkNode(Attribute.Ptr);
    Attribute.Unlink;
  end
  else
    Result := nil;
end;

procedure TXMLElement.SetAttribute(const Name: string; Value: string);
begin
  ResetLocalBuffers;
  xmlSetProp(NodePtr, LocalXmlStr(Name), LocalXmlStr(Value));
end;

{ TXMLCharacterData }

procedure TXMLCharacterData.AppendData(const Data: string);
begin
  ResetLocalBuffers;
  xmlNodeAddContent(NodePtr, LocalXmlStr(Data));
end;

procedure TXMLCharacterData.DeleteData(offset, count: Integer);
begin
  var S := xmlCharToStr(NodePtr.content);

  Delete(S, offset, count);

  ResetLocalBuffers;
  xmlNodeSetContent(NodePtr, LocalXmlStr(S));
end;

function TXMLCharacterData.Get_Data: string;
begin
  Result := xmlCharToStr(NodePtr.content);
end;

function TXMLCharacterData.Get_Length: NativeInt;
begin
  Result := Utf8toUtf16Count(NodePtr.content);
end;

procedure TXMLCharacterData.InsertData(offset: Integer; const data: string);
begin
  var S := xmlCharToStr(NodePtr.content);

  Insert(data, S, offset);

  ResetLocalBuffers;
  xmlNodeSetContent(NodePtr, LocalXmlStr(S));
end;

procedure TXMLCharacterData.ReplaceData(offset, count: Integer; const data: string);
begin
  var S := xmlCharToStr(NodePtr.content);

  Delete(S, offset, count);
  Insert(data, S, offset);

  ResetLocalBuffers;
  xmlNodeSetContent(NodePtr, LocalXmlStr(S));
end;

procedure TXMLCharacterData.Set_Data(const data: string);
begin
  ResetLocalBuffers;
  xmlNodeSetContent(NodePtr, LocalXmlStr(data));
end;

function TXMLCharacterData.SubstringData(offset, count: Integer): string;
begin
  Result := Copy(xmlCharToStr(NodePtr.content), offset, count);
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
  ResetLocalBuffers;
  xmlNodeSetContent(NodePtr, LocalXmlStr(data));
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

{ TXMLErrors }

constructor TXMLErrors.Create;
begin
  inherited Create;
  FList := TList<IXMLError>.Create;
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

function TXMLErrors.GetEnumerator: TEnumerator<IXMLError>;
begin
  Result := FList.GetEnumerator;
end;

function TXMLErrors.Get_Count: NativeUInt;
begin
  Result := FList.Count;
end;

function TXMLErrors.Get_Item(Index: NativeUInt): IXMLError;
begin
  Result := FList[Index];
end;

function TXMLErrors.MainError: IXMLError;
begin
  if FList.Count = 0 then
    Exit(nil);

  Result := FList.List[FList.Count - 1];
  for var I := Count - 2 downto 0 do
    if FList.List[I].level > Result.level then
      Result := FList.List[I];
end;

{ TXMLDocument }

constructor TXMLDocument.Create;
begin
  Create(xmlNewDoc(nil), True);
  FSuccessError := TXMLError.Create;
end;

constructor TXMLDocument.Create(doc: xmlDocPtr; DocOwner: Boolean);
begin
  inherited Create(xmlNodePtr(doc));
  FDocOwner := DocOwner;
  FErrors := TXMLErrors.Create;
  FXSLTErrors := TStringList.Create;
  FSuccessError := nil;
  FValidateOnParse := True;
end;

destructor TXMLDocument.Destroy;
begin
  if NodePtr <> nil then
  begin
    if DocOwner then
      xmlFreeDoc(Doc);
    NodePtr := nil;
  end;
  inherited;
  FreeAndNil(FErrors);
  FreeAndNil(FXSLTErrors);
end;

function TXMLDocument.CreateAttribute(const Name: string): IXMLAttribute;
begin
  Result := XMLFactory.Cast(xmlNewDocProp(doc, LocalXmlStr(Name), nil));
end;

function TXMLDocument.CreateCDATASection(const Data: string): IXMLCDATASection;
var
  L: NativeUInt;
begin
  ResetLocalBuffers;

  L := Length(Data);
  var P := LocalXmlStr(Pointer(Data), L);

  Result := XMLFactory.Cast(xmlNewCDataBlock(Doc, P, L)) as IXMLCDATASection;
end;

function TXMLDocument.CreateComment(const Data: string): IXMLComment;
begin
  ResetLocalBuffers;
  Result := XMLFactory.Cast(xmlNewDocComment(Doc, LocalXmlStr(Data))) as IXMLComment;
end;

function TXMLDocument.CreateDocumentFragment: IXMLDocumentFragment;
begin
  Result := XMLFactory.Cast(xmlNewDocFragment(doc)) as IXMLDocumentFragment;
end;

function TXMLDocument.CreateElement(const TagName: string): IXMLElement;
var
  Prefix, Base: PUTF8Char;
begin
  ResetLocalBuffers;
  SplitXMLName(TagName, Prefix, Base);

  if Prefix = nil then
    Result := XMLFactory.Cast(xmlNewDocRawNode(Doc, nil, Base, nil), False) as IXMLElement
  else
  begin
    var Node := Doc.documentElement;
    if Node <> nil then
    begin
      var Ns := Node.SearchNs(Prefix);
      if Ns <> nil then
        Exit(XMLFactory.Cast(xmlNewDocRawNode(Doc, Ns, Base, nil), False) as IXMLElement)
    end;
    Result := XMLFactory.Cast(xmlNewDocRawNode(Doc, nil, LocalXmlStr(TagName), nil), False) as IXMLElement;
  end;
end;

function TXMLDocument.CreateNode(NodeType: Integer; const Name, NamespaceURI: string): IXMLNode;
var
  Prefix, LocalName, HRef: xmlCharPtr;
begin
  ResetLocalBuffers;
  if NamespaceURI <> '' then
  begin
    SplitXMLName(Name, Prefix, LocalName);
    HRef := LocalXmlStr(NamespaceURI);
  end
  else
  begin
    LocalName := LocalXmlStr(Name);
    HRef := nil;
    Prefix := nil;
  end;

  case NodeType of
    NODE_ATTRIBUTE:
      Result := XMLFactory.Cast(xmlNewDocProp(doc, localName, nil), False);
    NODE_CDATA_SECTION:
      Result := XMLFactory.Cast(xmlNewCDataBlock(doc, nil, 0), False);
    NODE_COMMENT:
      Result := XMLFactory.Cast(xmlNewDocComment(doc, nil), False);
    NODE_DOCUMENT:
      Result := XMLFactory.Cast(xmlNewDoc(nil), True);
    NODE_DOCUMENT_FRAGMENT:
      Result := XMLFactory.Cast(xmlNewDocFragment(doc), False);
    NODE_TEXT:
      Result := XMLFactory.Cast(xmlNewDocText(doc, nil), False);
    NODE_ELEMENT:
      if href = nil then
        Result := XMLFactory.Cast(xmlNewDocNode(doc, nil, localName, nil), False)
      else
        Result := XMLFactory.Cast(xmlNewDocNode(doc, xmlNewNs(nil, href, prefix), localName, nil), False);
    NODE_PROCESSING_INSTRUCTION:
      Result := XMLFactory.Cast(xmlNewDocPI(doc, localName, nil), False);
  else
    Result := nil;
  end;
  xmlFree(Prefix);
  xmlFree(LocalName);
  xmlFree(HRef);
end;

function TXMLDocument.CreateProcessingInstruction(const Target, Data: string): IXMLProcessingInstruction;
begin
  ResetLocalBuffers;
  Result := XMLFactory.Cast(xmlNewDocPI(Doc, LocalXmlStr(Target), LocalXmlStr(Data))) as IXMLProcessingInstruction;
end;

function TXMLDocument.CreateTextNode(const Data: string): IXMLText;
begin
  ResetLocalBuffers;
  Result := XMLFactory.Cast(xmlNewDocText(Doc, LocalXmlStr(Data))) as IXMLText;
end;

procedure TXMLDocument.ErrorCallback(const error: xmlError);
begin
  var Err := TXMLError.Create(TXmlParseError.Create(error));
  Errors.FList.Add(Err);
end;

function TXMLDocument.GetDoc: xmlDocPtr;
begin
  Result := xmlDocPtr(NodePtr);
end;

function TXMLDocument.getElementsByTagName(const TagName: string): IXMLNodeList;
begin
  if Doc.documentElement = nil  then
    Exit(nil);

  Result := TXMLElementList.Create(Doc.documentElement, True, TagName);
end;

function TXMLDocument.getErrors: IXMLErrors;
begin
  Result := FErrors;
end;

function TXMLDocument.GetXSLTErrors: TStrings;
begin
  Result := FXSLTErrors;
end;

function TXMLDocument.Get_DocType: IXMLDocumentType;
begin
  if (doc.children <> nil) and (doc.children.&type = XML_DTD_NODE) then
    Result := XMLFactory.Cast(doc.children) as IXMLDocumentType
  else
    Result := nil;
end;

function TXMLDocument.Get_DocumentElement: IXMLElement;
begin
  Result := XMLFactory.Cast(Doc.documentElement) as IXMLElement;
  if Result <> nil then Result.Link;
end;

function TXMLDocument.Get_ParseError: IXMLError;
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
  if (doc.properties and Ord(XML_DOC_WELLFORMED)) = Ord(XML_DOC_WELLFORMED) then
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
  Result := doc.URL;
end;

function TXMLDocument.Get_ValidateOnParse: Boolean;
begin
  Result := FValidateOnParse;
end;

procedure TXMLDocument.BeforeLoad;
begin
  xmlFreeDoc(doc);
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
  BeforeLoad;
  Doc := Doc.CreateFromFile(URL, Options, ErrorCallback);
  Result := Doc <> nil;
end;

function TXMLDocument.Load(const Data: TBytes): Boolean;
begin
  BeforeLoad;
  Doc := Doc.Create(Data, Options, ErrorCallback);
  Result := Doc <> nil;
end;

function TXMLDocument.Load(const Data: Pointer; Size: NativeUInt): Boolean;
begin
  BeforeLoad;
  Doc := Doc.Create(Data, Size, Options, ErrorCallback);
  Result := Doc <> nil;
end;

function TXMLDocument.Load(Stream: TStream; const Encoding: Utf8String): Boolean;
begin
  BeforeLoad;
  Doc := Doc.Create(Stream, Options, Encoding, ErrorCallback);
  Result := Doc <> nil;
end;

function TXMLDocument.LoadXML(const XML: string): Boolean;
begin
  BeforeLoad;
  Doc := xmlDoc.Create(XML, Options, ErrorCallback);
  Result := Doc <> nil;
end;

function TXMLDocument.LoadXML(const XML: RawByteString; const Options: TXmlParserOptions): Boolean;
begin
  BeforeLoad;
  Doc := xmlDoc.Create(XML, Options, ErrorCallback);
  Result := Doc <> nil;
end;

function TXMLDocument.NodeFromID(const IdString: string): IXMLNode;
begin
  ResetLocalBuffers;
  var Attr := xmlGetID(Doc, LocalXmlStr(IdString));
  if Attr = nil then
    Exit(nil);

  Result := XMLFactory.Cast(Attr.Parent);
end;

procedure TXMLDocument.ReconciliateNs;
begin
  xmlReconciliateNs(Doc, doc.documentElement);
end;

procedure TXMLDocument.Save(const Url: string);
begin
  ResetLocalBuffers;
  xmlSaveFile(LocalXmlStr(url), doc);
end;

function TXMLDocument.Save(const FileName, Encoding: string; const Options: TxmlSaveOptions): Boolean;
begin
  Result := Doc.Save(FileName, Encoding, Options);
end;

function TXMLDocument.Save(Stream: TStream; const Encoding: string; const Options: TxmlSaveOptions): Boolean;
begin
  Result := Doc.Save(Stream, Encoding, Options);
end;

procedure TXMLDocument.SetDoc(Value: xmlDocPtr);
begin
  NodePtr := xmlNodePtr(Value);
end;

procedure TXMLDocument.Set_documentElement(const Element: IXMLElement);
begin
  doc.documentElement := Element.Ptr;
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
  Result := Doc.ToAnsi(Encoding, Format);
end;

function TXMLDocument.ToBytes(const Encoding: string; const Format: Boolean): TBytes;
begin
  Result := Doc.ToBytes(Encoding, Format);
end;

function TXMLDocument.ToString: string;
begin
  Result := Doc.ToString(False);
end;

function TXMLDocument.ToString(const Format: Boolean): string;
begin
  Result := Doc.ToString(Format);
end;

function TXMLDocument.ToUtf8(const Format: Boolean): RawByteString;
begin
  Result := Doc.ToUtf8(Format);
end;

function TXMLDocument.Transform(const Stylesheet: IXMLDocument; out Doc: IXMLDocument): Boolean;
var
  Res: xmlDocPtr;
begin
  TXSLTThreadErrorContext.Start(Self, XSLTErrorHandler);
  try
    FXSLTErrors.Clear;

    Result := xmlDocPtr(NodePtr).Transform(xmlDocPtr(stylesheet.Ptr), res);
    if Result then
      doc := TXMLDocument.Create(res, True);
  finally
    TXSLTThreadErrorContext.Stop
  end;
end;

function TXMLDocument.Transform(const Stylesheet: IXMLDocument; out S: string): Boolean;
begin
  TXSLTThreadErrorContext.Start(Self, XSLTErrorHandler);
  try
    FXSLTErrors.Clear;

    Result := xmlDocPtr(NodePtr).Transform(xmlDocPtr(Stylesheet.Ptr), S);

  finally
    TXSLTThreadErrorContext.Stop
  end;
end;

function TXMLDocument.Validate: IXMLError;
begin
  Errors.FList.Clear;

  doc.validate(ErrorCallback);

  if Errors.Count = 0 then
    Exit(FSuccessError)
  else
    Result := Errors.MainError;
end;

function TXMLDocument.ValidateNode(const Node: IXMLNode): IXMLError;
begin
  Errors.FList.Clear;

  doc.ValidateNode(Node.Ptr, ErrorCallback);

  if Errors.Count = 0 then
    Exit(FSuccessError)
  else
    Result := Errors.MainError;
end;

procedure TXMLDocument.XSLTError(const Msg: string);
begin
  XSLTErrors.Add(Msg);
end;

{ TXMLSchemaCollection }

function SchemaResourceCallback(ctxt: Pointer; const url, publicId: xmlCharPtr; &type: xmlResourceType; flags: Integer; var output: xmlParserInputPtr): Integer; cdecl;
begin
  var Col := TXMLSchemaCollection(ctxt);
  var Index := Col.IndexOf(xmlCharToStr(url));
  if Index >= 0 then
  begin
    var Data := Col.FList[Index].Doc.ToBytes;
    output := xmlNewInputFromMemory(nil, Pointer(Data), Length(Data), XML_INPUT_BUF_STATIC);
    Result := 0;
  end
  else
    Result := -1;
end;

procedure SchemaParserErrorCallback(userData: Pointer; const error: xmlErrorPtr); cdecl;
begin
  var Err := TXMLError.Create(TXmlParseError.Create(error^));
  TXMLDocument(userData).Errors.FList.Add(Err);
end;

constructor TXMLSchemaCollection.Create;
begin
  inherited Create;
  FList := TList<TSchema>.Create;
  FRoots := TList<IXMLDocument>.Create;
  FErrors := TXMLErrors.Create;
end;

destructor TXMLSchemaCollection.Destroy;
begin
  FreeAndNil(FRoots);
  FreeAndNil(FList);
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
            var parentSchema := FList.List[importIndex];
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
  for var I := 0 to FList.Count - 1 do
  begin
    var root := FList.List[I].Doc.documentElement.Ptr;
    var ns := root.SearchNsByRef(Pointer(cSchemaNs));
    ExtractImports(@FList.List[I], root, ns, I);
  end;

  for var I := 0 to FList.Count - 1 do
    if System.Length(FList.List[I].Parents) = 0 then
      FRoots.Add(FList.List[I].Doc);
end;

procedure TXMLSchemaCollection.Add(const NamespaceURI: string; Doc: IXMLDocument);
var
  Item: TSchema;
begin
  var Index := IndexOf(NamespaceURI);

  Item.NamespaceURI := NamespaceURI;
  Item.Doc := Doc;

  if Index < 0 then
    FList.Add(Item)
  else
    FList[Index] := Item;
end;

function TXMLSchemaCollection.GetSchema(const NamespaceURI: string): IXMLDocument;
begin
  var Index := IndexOf(NamespaceURI);
  if Index < 0 then
    Result := nil
  else
    Result := FList[Index].Doc;
end;

function TXMLSchemaCollection.Get_Length: NativeInt;
begin
  Result := FList.Count;
end;

function TXMLSchemaCollection.Get_NamespaceURI(Index: NativeInt): string;
begin
  Result := FList[Index].NamespaceURI;
end;

function TXMLSchemaCollection.IndexOf(const NamespaceURI: string): NativeInt;
begin

  Result := 0;
  while Result < FList.Count do
  begin
    if AnsiSameText(FList.List[Result].NamespaceURI, NamespaceURI) then
      Exit;
    Inc(Result);
  end;
  Result := -1;
end;

procedure TXMLSchemaCollection.Remove(const NamespaceURI: string);
begin
  var Index := IndexOf(NamespaceURI);
  if Index >= 0 then
    FList.Delete(Index);
end;

function TXMLSchemaCollection.Validate(const Doc: IXMLDocument): Boolean;
begin
  Result := True;
  Doc.errors.clear;

  Parse;

  for var I := 0 to Roots.Count - 1 do
  begin
    var ctxt := xmlSchemaNewDocParserCtxt(xmlDocPtr(Roots[I].Ptr));
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

    Result := xmlSchemaValidateDoc(vctxt, xmlDocPtr(Doc.Ptr)) = 0;

    xmlSchemaFreeValidCtxt(vctxt);
    xmlSchemaFree(schema);
    xmlSchemaFreeParserCtxt(ctxt);
    if Result then
      Break;
  end;
end;

end.
