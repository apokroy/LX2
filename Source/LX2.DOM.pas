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
  System.Types, System.SysUtils, System.Classes,
  LX2.Types, libxml2.API;

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

  IXMLNode = interface;
  IXMLAttribute = interface;
  IXMLDocument = interface;

  /// <summary>
  /// Base interface for all xml enumerators
  /// </summary>
  IXMLEnumerator = interface
    ['{D54A75D2-9D6F-4219-A895-469BFD549404}']
    function  GetCurrent: IXMLNode;
    function  MoveNext: Boolean;
    procedure Reset;
    property  Current: IXMLNode read GetCurrent;
  end;

  /// <summary>
  /// Returns information about XML Errors
  /// </summary>
  /// <remarks>
  /// MS IXMLDOMParseError compatible
  /// </remarks>
  IXMLParseError = interface
    ['{AE5CF111-97C1-4FD3-BFB0-559894DA43B4}']
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

  /// <summary>
  /// Enumerator for IXMLParseError collections
  /// </summary>
  IXMLErrorEnumerator = interface
    ['{B0B4327A-A186-4697-A830-68B62B3A525E}']
    function GetCurrent: IXMLParseError;
    function MoveNext: Boolean;
    property Current: IXMLParseError read GetCurrent;
  end;

  /// <summary>
  /// Collection of IXMLParseError
  /// </summary>
  /// <remarks>
  /// MS IXMLDOMParseErrorCollection compatible, except IXMLParseError is like IXMLDOMParseError, not IXMLDOMParseError2
  /// </remarks>
  IXMLErrors = interface
    ['{C48BAB36-1029-48B6-BC85-79E0FB9C23BC}']
    function  Get_Count: NativeUInt;
    function  Get_Item(Index: NativeUInt): IXMLParseError;
    function  GetEnumerator: IXMLErrorEnumerator;
    function  Get__newEnum: IXMLErrorEnumerator;
    function  Get_next: IXMLParseError;
    procedure Clear;
    procedure Reset;
    property  _newEnum: IXMLErrorEnumerator read Get__newEnum;
    property  Next: IXMLParseError read Get_next;
    property  Count: NativeUInt read Get_Count;
    property  Items[Index: NativeUInt]: IXMLParseError read Get_Item; default;
  end;

  /// <summary>
  /// Informaion about XSLT transformation error
  /// </summary>
  IXSLTError = interface
    ['{4B2EADC0-4C82-4101-A1E4-BC66F975ABB5}']
    function Get_reason: string;
    property Reason: string read Get_reason;
  end;

  /// <summary>
  /// Enumerator for IXSLTError collections
  /// </summary>
  IXSLTErrorEnumerator = interface
    ['{F23A8251-D36B-41C8-BD01-57578FE1674C}']
    function GetCurrent: IXSLTError;
    property Current: IXSLTError read GetCurrent;
    function MoveNext: Boolean;
  end;

  /// <summary>
  /// Collection of IXSLTError
  /// </summary>
  IXSLTErrors = interface
    ['{CD2275A7-3989-4CDE-BF17-5158193EA18C}']
    function  Get_Count: NativeUInt;
    function  Get_Item(Index: NativeUInt): IXSLTError;
    function  GetEnumerator: IXSLTErrorEnumerator;
    procedure Clear;
    property  Count: NativeUInt read Get_Count;
    property  Items[Index: NativeUInt]: IXSLTError read Get_Item; default;
  end;

  /// <summary>
  /// Enumerator for IXMLAttribute collections
  /// </summary>
  IXMLAttributesEnumerator = interface
    ['{099A865F-3210-4D18-A318-A6D259E9CE55}']
    function  GetCurrent: IXMLAttribute;
    function  MoveNext: Boolean;
    procedure Reset;
    property  Current: IXMLAttribute read GetCurrent;
  end;

  ///<summary>
  /// List of xml nodes
  ///</summary>
  /// <remarks>
  /// MS IXMLDOMNodeList compatible & Delphi enumerable interface
  /// </remarks>
  IXMLNodeList = interface
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

  ///<summary>
  /// Collection of nodes allow access nodes by name and qualified name
  /// Collection is live, thus any changes (add, remove nodes) is changes doument tree and vise versa.
  ///</summary>
  /// <remarks>
  /// MS IXMLDOMNodeList compatible
  /// Partially W3C DOM compatible
  /// </remarks>
  IXMLNamedNodeMap = interface(IXMLNodeList)
    ['{1D8272DD-58C6-4E1D-8327-7E678F30F8D5}']
    ///<summary>
    /// Collection of nodes
    ///</summary>
    function GetNamedItem(const Name: string): IXMLNode;
    function SetNamedItem(const NewItem: IXMLNode): IXMLNode;
    function RemoveNamedItem(const Name: string): IXMLNode;
    function GetQualifiedItem(const BaseName: string; const namespaceURI: string): IXMLNode;
    function RemoveQualifiedItem(const BaseName: string; const namespaceURI: string): IXMLNode;
  end;

  ///<summary>
  /// NamedNodeMap collection of attributes
  /// Collection is live, thus any changes (add, remove attributes) is changes node attributes and vise versa.
  ///</summary>
  /// <remarks>
  /// LX2 extension to NamedNodeMap
  /// </remarks>
  IXMLAttributes = interface(IXMLNamedNodeMap)
    ['{86C5ACFD-9460-4B71-91BA-E374A0852073}']
    { MSXMLDOMNodeList }
    function  Get_Attr(Index: NativeInt): IXMLAttribute;
    function  Get_Length: NativeInt;
    function  NextNode: IXMLAttribute;
    procedure Reset;
    property  Item[Index: NativeInt]: IXMLAttribute read Get_Attr; default;
    property  Length: NativeInt read Get_Length;
    { Delphi enumerable }
    function  GetEnumerator: IXMLAttributesEnumerator;
    function  ToArray: TArray<IXMLAttribute>;
  end;

  ///<summary>
  /// Base interface for all node types.
  ///</summary>
  /// <remarks>
  /// Near to be MS IXMLDOMNode compatible
  /// Near to be W3C DOM compatible
  /// </remarks>
  IXMLNode = interface
    ['{D5029FB0-0282-4476-A439-99677C23434A}']
    /// <summary>
    /// Appends NewChild as the end of child nodes ist.
    /// </summary>
    /// <param name="NewChild">
    /// A Node that appended at the end of child nodes list or attributes list if NewNode is attribute
    /// <param>
    /// <returns>
    /// Returns references to appended node or nil in case of error.
    /// It can be other than NewChild, for example text node can be merged with other text nodes
    /// </returns>
    function  AppendChild(const NewChild: IXMLNode): IXMLNode;

    /// <summary>
    /// Clones node
    /// </summary>
    /// <param name="Deep">
    /// if True clones all subtree
    /// <param>
    /// <returns>
    ///  New cloned node
    /// </returns>
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

    /// <summary>
    /// Checks that node has children
    /// </summary>
    /// <returns>
    ///  Returns True if node has children
    /// </returns>
    function  HasChildNodes: Boolean;

    /// <summary>
    /// Inserts node into into child list, before other node
    /// </summary>
    /// <param name="NewChild">
    ///  Node to insert
    /// <param>
    /// <param name="RefChild">
    ///  NewChild is inserted before RefChild. If RefChild is nil, NewChild append to end of list.
    /// <param>
    /// <returns>
    /// Returns inserted node or nil in case of error
    /// </returns>
    function  InsertBefore(const NewChild: IXMLNode; RefChild: IXMLNode) : IXMLNode;

    /// <summary>
    /// Removes ChildNode from child nodes list
    /// </summary>
    /// <param name="ChildNode">
    ///  Node to remove
    /// <param>
    /// <returns>
    ///  Removed node or nil in case of error
    /// </returns>
    function  RemoveChild(const ChildNode: IXMLNode): IXMLNode;

    /// <summary>
    /// Replaces OldChild with NewChild
    /// </summary>
    /// <param name="NewChild">
    ///  Node to replace old node
    /// <param>
    /// <param name="OldChild">
    ///  Node that is to be replaced by NewChild
    /// <param>
    /// <returns>
    ///  Returns OldChild or nil in case of error
    /// </returns>
    function  ReplaceChild(const NewChild: IXMLNode; const OldChild: IXMLNode) : IXMLNode;

    /// <summary>
    /// Returns list of nodes that matched XPath expression
    /// </summary>
    /// <param name="QueryString">
    ///  XPath expression
    /// <param>
    /// <returns>
    ///  List of nodes, that matching expression
    /// </returns>
    function  SelectNodes(const QueryString: string): IXMLNodeList;

    /// <summary>
    /// Returns first node that matched XPath expression
    /// </summary>
    /// <param name="QueryString">
    /// <param>
    /// <returns>
    /// </returns>
    function  SelectSingleNode(const QueryString: string): IXMLNode;

    procedure Set_NodeValue(const Value: string);
    procedure Set_Text(const text: string);

    /// <summary>
    ///
    /// </summary>
    property  Attributes: IXMLAttributes read Get_Attributes;

    /// <summary>
    ///
    /// </summary>
    property  BaseName: string read Get_BaseName;

    /// <summary>
    ///
    /// </summary>
    property  ChildNodes: IXMLNodeList read Get_ChildNodes;

    /// <summary>
    ///
    /// </summary>
    property  FirstChild: IXMLNode read Get_FirstChild;

    /// <summary>
    ///
    /// </summary>
    property  LastChild: IXMLNode read Get_LastChild;

    /// <summary>
    ///
    /// </summary>
    property  NamespaceURI: string read Get_NamespaceURI;

    /// <summary>
    ///
    /// </summary>
    property  NextSibling: IXMLNode read Get_NextSibling;

    /// <summary>
    ///
    /// </summary>
    property  NodeName: string read Get_NodeName;

    /// <summary>
    ///
    /// </summary>
    property  NodeType: DOMNodeType read Get_NodeType;

    /// <summary>
    ///
    /// </summary>
    property  NodeValue: string read Get_NodeValue write Set_NodeValue;

    /// <summary>
    ///
    /// </summary>
    property  OwnerDocument: IXMLDocument read Get_OwnerDocument;

    /// <summary>
    ///
    /// </summary>
    property  ParentNode: IXMLNode read Get_ParentNode;

    /// <summary>
    ///
    /// </summary>
    property  Prefix: string read Get_Prefix;

    /// <summary>
    ///
    /// </summary>
    property  PreviousSibling: IXMLNode read Get_PreviousSibling;

    /// <summary>
    ///
    /// </summary>
    property  Text: string read Get_Text write Set_Text;

    /// <summary>
    ///
    /// </summary>
    property  Xml: string read Get_Xml;
  end;

  IXMLAttribute = interface(IXMLNode)
    ['{3E56F4E4-A1F0-4F13-A84A-6AF2259DDB8D}']
    function  Get_Name: string;
    function  Get_Value: string;
    procedure Set_Value(const Value: string);
    property  Name: string read Get_name;
    property  Value: string read Get_value write Set_value;
  end;

  IXMLElement = interface(IXMLNode)
    ['{3E24AC42-F609-444B-922F-74064C28FF57}']
    function  AddChild(const Name: string; const Content: string = ''): IXMLElement;
    function  AddChildNs(const Name, NamespaceURI: string; const Content: string = ''): IXMLElement;
    function  Get_TagName: string;
    function  GetAttribute(const Name: string): string;
    function  GetAttributeNode(const Name: string): IXMLAttribute; overload;
    function  GetAttributeNodeNs(const NamespaceURI, Name: string): IXMLAttribute; overload;
    function  GetAttributeNs(const NamespaceURI, Name: string): string;
    function  GetElementsByTagName(const TagName: string): IXMLNodeList;
    function  HasAttribute(const Name: string): Boolean;
    function  HasAttributeNs(const NamespaceURI, Name: string): Boolean;
    procedure Normalize;
    function  RemoveAttribute(const Name: string): Boolean;
    function  RemoveAttributeNode(const Attribute: IXMLAttribute): IXMLAttribute;
    function  RemoveAttributeNs(const NamespaceURI, Name: string): Boolean;
    procedure SetAttribute(const Name: string; Value: string);
    function  SetAttributeNs(const NamespaceURI, Name: string; const Value: string): IXMLAttribute;
    property  TagName: string read Get_TagName;
  end;

  IXMLDocumentFragment = interface(IXMLNode)
    ['{83EDFB96-58F5-40FE-B45F-A7EBA752F20A}']
  end;

  IXMLDocumentType = interface(IXMLNode)
    ['{46C5C8FE-5C20-48D0-82F6-BDC83A575163}']
  end;

  IXMLCharacterData = interface(IXMLNode)
    ['{963AF383-26CB-451C-B7DA-615CF5BF542E}']
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
    ['{7C332616-AAD8-43B1-883E-38C5BCEBCEB0}']
  end;

  IXMLCDATASection = interface(IXMLText)
    ['{CAD8A860-5996-4373-9349-991729CCEEF0}']
  end;

  IXMLComment = interface(IXMLCharacterData)
    ['{F83E1FE5-A380-482C-A248-3CBDB8F41CCC}']
  end;

  IXMLProcessingInstruction = interface(IXMLNode)
    ['{F3DEDC25-DF14-4F97-B650-3585ADD0697E}']
    function  Get_Target: string;
    function  Get_Data: string;
    procedure Set_Data(const Value: string);
    property  Target: string read Get_Target;
    property  Data: string read Get_Data write Set_Data;
  end;

  IXMLEntityReference = interface(IXMLNode)
    ['{E15B0DD9-82E1-44BF-9DC5-73213AC492EC}']
  end;

  IXMLSchemaCollection = interface
    ['{EA6126A1-514A-4C6D-A026-C369452ECB42}']
    procedure Add(const namespaceURI: string; Doc: IXMLDocument);
    procedure Remove(const namespaceURI: string);
    function  Get_length: NativeInt;
    function  Get_namespaceURI(index: NativeInt): string;
    function  GetSchema(const namespaceURI: string): IXMLDocument;
    property  Length: NativeInt read Get_length;
    property  NamespaceURI[index: NativeInt]: string read Get_NamespaceURI; default;
  end;

  IXMLDocument = interface(IXMLNode)
    ['{8CE71137-BDB3-4A71-A505-EFB6D1181A5F}']
    function  Clone(Recursive: Boolean = True): IXMLDocument;
    function  CreateRoot(const RootName: string; const NamespaceURI: string = ''; Content: string = ''): IXMLElement;
    function  CreateChild(const Parent: IXMLElement; const Name: string; const NamespaceURI: string = ''; ResolveNamespace: Boolean = False; Content: string = ''): IXMLElement;
    function  GetErrors: IXMLErrors;
    function  GetXSLTErrors: IXSLTErrors;
    function  Load(const Data: Pointer; Size: NativeUInt): Boolean; overload;
    function  Load(const Data: TBytes): Boolean; overload;
    function  Load(const URL: string): Boolean; overload;
    function  Load(Stream: TStream; const Encoding: Utf8String): Boolean; overload;
    function  LoadXML(const XML: RawByteString; const Options: TXmlParserOptions = DefaultParserOptions): Boolean; overload;
    function  LoadXML(const XML: string; const Options: TXmlParserOptions = DefaultParserOptions): Boolean; overload;
    procedure Normalize;
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
    function  Transform(const stylesheet: IXMLDocument; out S: RawByteString): Boolean; overload;
    property  Errors: IXMLErrors read GetErrors;
    property  XSLTErrors: IXSLTErrors read GetXSLTErrors;
    { MS XML Like }
    function  Get_Doctype: IXMLDocumentType;
    function  Get_DocumentElement: IXMLElement;
    procedure Set_DocumentElement(const Element: IXMLElement);
    function  CreateElement(const tagName: string): IXMLElement;
    function  CreateElementNs(const NamespaceURI, Name: string): IXMLElement;
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
    function  Get_ParseError: IXMLParseError;
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
    property  ParseError: IXMLParseError read Get_parseError;
    property  Url: string read Get_Url;
    property  ValidateOnParse: Boolean read Get_ValidateOnParse write Set_ValidateOnParse;
    property  ResolveExternals: Boolean read Get_ResolveExternals write Set_ResolveExternals;
    property  PreserveWhiteSpace: Boolean read Get_PreserveWhiteSpace write Set_PreserveWhiteSpace;
    function  Validate: IXMLParseError;
    function  ValidateNode(const node: IXMLNode): IXMLParseError;
  end;

  function CoCreateXMLDocument: IXMLDocument;

implementation

uses
  LX2.DOM.Classes;

function CoCreateXMLDocument: IXMLDocument;
begin
  Result := TXMLDocument.Create;
end;

end.
