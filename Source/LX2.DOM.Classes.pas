/// <summary>
/// COM/IDispatch-совместимая реализация MS XML DOM (MSXML2)-подобного API
/// (<c>IXMLDocument</c>, <c>IXMLNode</c>, <c>IXMLElement</c> и т.д.) поверх
/// нативных указателей libxml2 (<c>xmlNodePtr</c>, <c>xmlDocPtr</c>, <c>xmlNsPtr</c>).
/// </summary>
/// <remarks>
/// <para>
/// <b>Модель владения памятью (ключевая идея всего модуля):</b> каждый
/// libxml2-узел (<c>xmlNodePtr</c>) имеет поле <c>_private: Pointer</c>,
/// используемое здесь для хранения обратной ссылки на Delphi-обёртку
/// (<c>TXMLNode</c> и потомки). Это даёт кэширование "один xmlNodePtr — одна
/// Delphi-обёртка": функции <c>Cast(...)</c> (см. ниже) всегда сначала
/// проверяют <c>Node._private</c> и возвращают существующую обёртку вместо
/// создания новой. Без этого повторные вызовы <c>ParentNode.FirstChild</c>
/// и т.п. создавали бы новый управляемый объект на каждое обращение.
/// </para>
/// <para>
/// <b>Взаимный refcounting документа и узлов:</b> каждый <c>TXMLNode</c>
/// при создании увеличивает refcount владеющего его документа
/// (<c>TXMLDocument._AddRef</c>), а при разрушении — уменьшает
/// (<c>_Release</c>). Это гарантирует, что документ не будет уничтожен,
/// пока жив хотя бы один DOM-объект, ссылающийся на его узлы, даже если
/// пользовательский код полностью потерял ссылку на сам `IXMLDocument`.
/// См. подробности в комментариях к <see cref="TXMLNode.Create"/> и
/// <see cref="TXMLNode.Destroy"/>.
/// </para>
/// <para>
/// <b>Глобальный libxml2 node-deregister hook:</b> <see cref="NodeFreeCallback"/>
/// регистрируется один раз через <c>xmlDeregisterNodeDefault</c> и вызывается
/// libxml2 всякий раз, когда сам libxml2 (а не эта обёртка) физически
/// освобождает <c>xmlNodePtr</c> — например, при слиянии соседних текстовых
/// узлов внутри <c>xmlAddChild</c>. Это необходимо, чтобы Delphi-обёртка не
/// осталась с "висящим" (dangling) указателем <c>NodePtr</c>.
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
  /// MSXML-совместимое представление "всех атрибутов узла" как единой
  /// коллекции <c>IXMLNodeList</c>/<c>IXMLNamedNodeMap</c>, скрывающее тот
  /// факт, что в libxml2 это физически ДВА РАЗНЫХ связных списка узла:
  /// <c>Node.nsDef</c> (объявления пространств имён, <c>xmlns:...</c>) и
  /// <c>Node.properties</c> (обычные атрибуты).
  /// </summary>
  /// <remarks>
  /// Причина такого объединения — семантика MSXML DOM, где
  /// <c>xmlns:prefix="uri"</c> трактуется как обычный атрибут элемента
  /// (доступный через <c>Attributes.GetNamedItem('xmlns:prefix')</c>), тогда
  /// как в модели libxml2 это отдельная, специализированная структура
  /// <c>xmlNs</c>, физически не являющаяся <c>xmlAttrPtr</c>/<c>xmlNodePtr</c>.
  /// Практически ВСЕ методы данного класса (<see cref="Get_Item"/>,
  /// <see cref="Get_Length"/>, <see cref="ToArray"/>, и внутренний
  /// <see cref="TEnumerator"/>) содержат парную логику: "сначала пройти весь
  /// <c>nsDef</c>, затем весь <c>properties</c>" — т.е. namespace-декларации
  /// всегда идут ПЕРЕД обычными атрибутами в индексации/порядке перечисления.
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
  /// Реализация <c>getElementsByTagName</c>/<c>getElementsByTagNameNS</c>:
  /// "живой" (вычисляемый лениво при каждом обходе, а не кэшируемый список)
  /// набор элементов, отфильтрованных по имени тега (<see cref="Mask"/>) и,
  /// опционально, обходящий либо только прямых потомков, либо всё поддерево
  /// (<see cref="Recursive"/>).
  /// </summary>
  /// <remarks>
  /// <para>
  /// <b>Диспетчеризация через <c>TMoveNext = function: Boolean of object</c>:</b>
  /// вместо ветвления <c>if Recursive then ... if UseMask then ...</c> внутри
  /// каждого вызова <c>MoveNext</c> (что означало бы 2 проверки условий на
  /// каждый шаг итерации), нужная реализация обхода
  /// (DoNextSibling/DoNextSiblingWithMask/DoNextRecursive/DoNextRecursiveWithMask)
  /// выбирается ОДИН РАЗ в конструкторе и сохраняется как метод-указатель
  /// <c>FDoMoveNext</c> — устраняя условные переходы из горячего пути
  /// перечисления. Это особенно важно для <see cref="Get_Item"/>/
  /// <see cref="Get_Length"/> (см. предупреждение о производительности ниже),
  /// которые пересоздают перечислитель и полностью проходят его на каждый
  /// вызов.
  /// </para>
  /// <para>
  /// ⚠ <b>Предупреждение о производительности:</b> <see cref="Get_Item"/> и
  /// <see cref="Get_Length"/> выполняют ПОЛНЫЙ обход (под)дерева документа на
  /// КАЖДЫЙ вызов (пересоздавая <see cref="TEnumerator"/> с нуля), поскольку
  /// результат обхода нигде не кэшируется. Типичный пользовательский цикл
  /// <c>for I := 0 to List.Length - 1 do Process(List[I])</c> имеет,
  /// следовательно, СЛОЖНОСТЬ O(n²) от размера документа вместо ожидаемого
  /// O(n). Предпочитайте перечисление через <c>for..in</c> (единый проход,
  /// использующий один и тот же <c>Enum.MoveNext</c>) или явный
  /// <see cref="ToArray"/> вместо индексного доступа в цикле.
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
    /// Заменяет значение атрибута, полностью пересобирая его список дочерних
    /// узлов (<c>AttrPtr.children</c>) — в модели libxml2/DOM значение атрибута
    /// физически хранится не как строковое поле, а как единственный текстовый
    /// узел-потомок атрибута (аналогично тому, как значение текстового элемента
    /// хранится в его дочерних текстовых узлах).
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b>Порядок действий небанален и важен:</b>
    /// <list type="number">
    /// <item><description>
    /// Новый текстовый узел (<c>xmlNewDocText</c>) создаётся ПЕРВЫМ, ДО удаления
    /// старого содержимого — если бы <c>AttrPtr.children</c> был очищен раньше,
    /// а создание нового узла (теоретически) завершилось неудачей, атрибут
    /// остался бы без значения вместо сохранения старого; текущий порядок
    /// минимизирует окно, в котором операция может завершиться в
    /// промежуточном состоянии.
    /// </description></item>
    /// <item><description>
    /// Если атрибут был ID-атрибутом (<c>AttrPtr.atype = XML_ATTRIBUTE_ID</c>),
    /// он снимается с ID-индекса документа (<c>xmlRemoveID</c>) ДО изменения
    /// значения — поскольку ID-индекс документа физически хранит пары
    /// (значение → узел), и смена значения атрибута сделала бы старую запись в
    /// индексе неверной, если бы не была удалена заранее.
    /// </description></item>
    /// <item><description>
    /// Старый список дочерних узлов освобождается (<c>xmlFreeNodeList</c>)
    /// целиком, хотя в подавляющем большинстве случаев там ровно один текстовый
    /// узел — это защищает от редкого, но допустимого в XML случая, когда
    /// значение атрибута представлено НЕСКОЛЬКИМИ узлами (текст +
    /// entity-ссылки, например <c>attr="&amp;amp;foo"</c>).
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

  TXMLSchemaCollection = class(TXMLBase, IXMLSchemaCollection)
  private const
    cImport = 'import';
    cInclude = 'include';
    cSchemaNs = 'http://www.w3.org/2001/XMLSchema';
  protected type
    TItem = class
      NamespaceURI: string;
      Schema: xmlDocPtr;
      Sources: TList<IXmlDocument>;
      Imports: TStringList;
      FileName: string;
      constructor Create;
      destructor Destroy; override;
    end;
  private
    FCompiled: Boolean;
    FItems: TList<TItem>;
    FErrors: TXMLErrors;
    FTempPath: string;
    FSchemaRoot: xmlDocPtr;
    procedure Cleanup;
  protected
    property  Items: TList<TItem> read FItems;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>
    /// Компилирует все зарегистрированные (через <see cref="Add"/>) исходные
    /// XSD-документы, сгруппированные по целевому namespace, в единый набор
    /// файлов на диске, объединяя множественные источники одного и того же
    /// namespace в единый XSD-документ на файл и корректно перестраивая
    /// <c>&lt;xs:import&gt;</c>/<c>&lt;xs:include&gt;</c> связи между ними.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b>Почему временные файлы, а не документы в памяти:</b> согласно
    /// комментарию в <see cref="Validate"/> ("custom ResourceLoader doesnt
    /// called when not direct import in xsd"), механизм разрешения путей
    /// libxml2 XML Schema для транзитивных (не прямых) <c>xs:import</c>
    /// корректно работает только при загрузке схемы С ДИСКА через файловый
    /// путь (<c>xmlSchemaNewParserCtxt</c> от имени файла), а не из документа,
    /// уже находящегося в памяти — отсюда необходимость сохранения
    /// скомпилированных схем во временную директорию (<c>FTempPath</c>) и
    /// последующей повторной загрузки последнего файла (<c>FSchemaRoot</c>)
    /// именно с диска.
    /// </para>
    /// <para>
    /// <b>Обработка <c>xs:import</c> vs <c>xs:include</c> (вложенные функции
    /// <c>IsImport</c>/<c>IsInclude</c>):</b>
    /// <list type="bullet">
    /// <item><description>
    /// <c>xs:include</c>-элементы полностью УДАЛЯЮТСЯ из дерева (поскольку их
    /// содержимое физически СЛИВАЕТСЯ в целевой документ через
    /// AddSource — в один namespace может быть несколько
    /// зарегистрированных исходных документов, объединяемых построчным клонированием
    /// узлов <c>xmlDOMWrapCloneNode</c>).
    /// </description></item>
    /// <item><description>
    /// <c>xs:import</c>-элементы также удаляются из исходного документа, но их
    /// целевой namespace ЗАПОМИНАЕТСЯ (<c>Item.Imports.Add(...)</c>) и позже
    /// заново синтезируется (второй проход <c>for I := 0 to Items.Count - 1</c>)
    /// с корректным <c>schemaLocation</c>, указывающим на итоговый файл этого
    /// импортируемого namespace (<c>Index.ToString + '.xsd'</c>) — поскольку
    /// путь к файлу известен только ПОСЛЕ того, как все схемы скомпилированы и
    /// сохранены, этот процесс не может быть выполнен за один проход.
    /// </description></item>
    /// </list>
    /// </para>
    /// <para>
    /// <b>Почему <c>FSchemaRoot</c> — это именно <c>Items.Last</c>:</b> "корневой"
    /// файл для финальной валидации выбирается как ПОСЛЕДНИЙ зарегистрированный
    /// namespace — неявное допущение, что вызывающий код регистрирует основную
    /// (целевую) схему последней через <see cref="Add"/>, а её зависимости
    /// (импортируемые схемы) — раньше. Если это предположение нарушается
    /// (основная схема добавлена не последней), валидация будет использовать
    /// не тот корневой документ.
    /// </para>
    /// </remarks>
    procedure Compile;
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
/// Callback, регистрируемый один раз глобально через
/// <c>xmlDeregisterNodeDefault</c>, вызываемый libxml2 непосредственно
/// перед физическим освобождением памяти любого <c>xmlNodePtr</c> —
/// НЕЗАВИСИМО от того, инициировано ли освобождение из кода этой Delphi-
/// обёртки или изнутри самого libxml2 (например, слияние соседних текстовых
/// узлов внутри <c>xmlAddChild</c>, или каскадное удаление поддерева).
/// </summary>
/// <remarks>
/// <para>
/// <b>Почему это необходимо:</b> Delphi-обёртка (<c>TXMLNode</c>) хранит
/// сырой указатель <c>NodePtr</c> на структуру libxml2. Если libxml2
/// физически освободит эту структуру без ведома обёртки, <c>NodePtr</c>
/// станет dangling-указателем, и любое последующее обращение к нему из
/// Delphi-кода приведёт к неопределённому поведению (обычно — access
/// violation при чтении освобождённой памяти, или ещё хуже — тихое чтение
/// уже переиспользованной под другие данные памяти).
/// </para>
/// <para>
/// <b>Что делает функция:</b> находит Delphi-обёртку через
/// <c>Node._private</c> (если она существует — то есть если на этот узел
/// когда-либо ссылался управляемый DOM-код) и:
/// <list type="number">
/// <item><description>
/// Обходит список объявленных на узле пространств имён (<c>nsDef</c>) и для
/// каждого, у которого есть своя обёртка (<c>Ns._private &lt;&gt; nil</c>,
/// т.е. на него ссылается объект <see cref="TXMLNsNode"/>), обнуляет его
/// поле <c>NsPtr</c> — поскольку освобождение узла в libxml2 обычно влечёт и
/// освобождение его <c>nsDef</c>-списка.
/// </description></item>
/// <item><description>
/// Обнуляет <c>NodePtr</c> самой обёртки узла, чтобы дальнейшие обращения к
/// её свойствам (которые все читают <c>NodePtr.*</c>) как минимум не читали
/// освобождённую память напрямую — хотя без дополнительных проверок
/// <c>NodePtr = nil</c> в каждом геттере это всё равно приведёт к access
/// violation при разыменовании <c>nil</c>, а не к тихой порче данных, что
/// строго предпочтительнее.
/// </description></item>
/// </list>
/// </para>
/// <para>
/// <b>Известное ограничение:</b> эта функция НЕ снимает ref-счётчик с
/// владеющего документа, который был установлен в
/// <see cref="TXMLNode.Create"/> — освобождение этого ref-а происходит
/// только в <see cref="TXMLNode.Destroy"/>, которая, однако, к этому
/// моменту уже не может прочитать <c>NodePtr.doc</c> (он уже <c>nil</c>).
/// См. соответствующее примечание в <see cref="TXMLNode.Destroy"/>.
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
/// Разрешает "отложенное" (<c>Unlinked</c>) пространство имён атрибута в
/// момент его фактического присоединения к дереву документа (см.
/// <c>Cast(xmlAttrPtr, Prefix, NamespaceURI)</c> и общее замечание там же).
/// </summary>
/// <remarks>
/// <para>
/// Вызывается из <see cref="TXMLNode.AppendChild"/>,
/// <see cref="TXMLNode.InsertBefore"/> и <see cref="TXMLAttributeList.SetNamedItem"/>
/// непосредственно перед фактическим прикреплением атрибута к родительскому
/// элементу — на этот момент уже известен конкретный узел дерева
/// (<paramref name="Parent"/>), от которого можно оттолкнуться при поиске/
/// создании подходящего <c>xmlNsPtr</c> через <c>xmlSearchNs</c>/
/// <c>xmlSearchNsByHref</c>.
/// </para>
/// <para>
/// <b>Логика выбора стратегии поиска (три ветки if/elsif/else) — на первый
/// взгляд неочевидна:</b>
/// <list type="bullet">
/// <item><description>
/// Если задан ТОЛЬКО префикс (URI неизвестен/пуст) — ищем существующую
/// декларацию namespace по префиксу (<c>xmlSearchNs</c>): предполагается,
/// что вызывающий код полагается на то пространство имён, что уже объявлено
/// в дереве под этим префиксом.
/// </description></item>
/// <item><description>
/// Если задан ТОЛЬКО URI (префикс неизвестен/пуст) — ищем по URI
/// (<c>xmlSearchNsByHref</c>): находим ЛЮБОЙ существующий в области
/// видимости префикс, под которым уже объявлен этот URI.
/// </description></item>
/// <item><description>
/// Если заданы ОБА (и префикс, и URI) — сначала ищем по префиксу, а затем
/// ДОПОЛНИТЕЛЬНО проверяем, что найденная декларация действительно имеет
/// именно этот URI (<c>xmlStrSame(...href)</c>); если URI не совпадает —
/// откатываемся к <c>Ns := nil</c>, что ниже приведёт к созданию НОВОЙ
/// namespace-декларации с этим префиксом и URI на самом узле
/// <paramref name="Parent"/> (через <c>xmlNewNs</c>), даже если префикс уже
/// использовался в дереве для другого URI — это соответствует ожидаемой
/// семантике: точное соответствие (prefix, URI) имеет приоритет над простым
/// совпадением одного из двух полей.
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
/// Возвращает уже существующую Delphi-обёртку документа (через
/// <c>Doc._private</c>), либо создаёт новую с флагом владения документом
/// (<c>DocOwner = True</c>), если обёртки ещё нет.
/// </summary>
/// <remarks>
/// <c>DocOwner = True</c> здесь означает, что созданная обёртка сама
/// вызовет <c>xmlFreeDoc</c> в своём деструкторе — это корректно, поскольку
/// единственный способ попасть в эту ветку "обёртки ещё нет" — это когда
/// документ был создан напрямую через libxml2 API в обход этого враппера
/// (например, документ трансформации XSLT), и теперь кто-то впервые
/// обращается к нему через DOM-обёртку (см. <c>TXMLNode.Get_OwnerDocument</c>).
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
/// Возвращает уже существующую обёртку узла, либо создаёт новую нужного
/// конкретного класса на основе <c>Node.&amp;type</c> (диспетчеризация по
/// <c>xmlElementType</c>: элемент → <see cref="TXMLElement"/>, текст →
/// <see cref="TXMLText"/>, и т.д.). Для неизвестных/необрабатываемых типов
/// узлов возвращается базовый <see cref="TXMLNode"/>.
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

/// <summary>Атрибут-специфичная версия <see cref="Cast(xmlNodePtr)"/>, сокращающая явное приведение типа для вызывающего кода, ожидающего именно <see cref="TXMLAttribute"/>.</summary>
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
/// Специальная перегрузка для "отвязанного" (unlinked) атрибута — созданного
/// в памяти, но ещё не подключённого к дереву документа, для которого
/// префикс/URI пространства имён ещё не могут быть разрешены через
/// <c>xmlSearchNs</c> (это возможно только после того, как атрибут будет
/// физически прикреплён к родительскому элементу — см.
/// <see cref="ResolveUnlinked"/>).
/// </summary>
/// <remarks>
/// Используется, например, при <c>CreateAttributeNS</c>, где вызывающий код
/// указывает namespace URI ДО того, как атрибут присоединён к какому-либо
/// элементу дерева — libxml2 не позволяет создать/найти <c>xmlNsPtr</c> без
/// контекста конкретного узла дерева, поэтому запрос на разрешение
/// пространства имён откладывается (<c>Attr.Unlinked := True</c>) до
/// момента фактического присоединения атрибута к элементу.
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
/// Оборачивает <c>xmlNsPtr</c> (namespace-декларацию узла, физически не
/// являющуюся отдельным DOM-узлом в libxml2) в MSXML-совместимый
/// псевдо-узел-атрибут <see cref="TXMLNsAttribute"/>, поскольку MSXML DOM
/// (в отличие от libxml2) трактует объявления <c>xmlns:prefix="uri"</c> как
/// обычные атрибуты элемента — см. общее замечание к <see cref="TXMLNsNode"/>.
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
/// Отвязывает узел <paramref name="Ns"/> от односвязного списка namespace-
/// деклараций <paramref name="List"/> (обычно — <c>Node.nsDef</c>),
/// корректируя указатели соседних элементов списка.
/// </summary>
/// <returns><c>True</c>, если <paramref name="Ns"/> был найден и отвязан; <c>False</c>, если он не найден в списке (или <c>nil</c>).</returns>
/// <remarks>
/// ⚠ Применять ТОЛЬКО к полям, реально являющимся головой связного списка
/// (<c>Node.nsDef</c>), а не к одиночным ссылкам на namespace (например,
/// <c>Node.ns</c> — используемое узлом пространство имён, а НЕ список его
/// объявленных пространств имён). Для одиночных ссылок используйте
/// <see cref="xmlClearNodeNsRef"/> — попытка передать <c>Node.ns</c> в
/// качестве <paramref name="List"/> сюда семантически некорректна: функция
/// присвоит полю значение <c>Ns.next</c> (следующий элемент ЧУЖОГО списка
/// <c>nsDef</c>), а не <c>nil</c>, что приведёт к тихой порче ссылки узла на
/// пространство имён.
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
/// Корректно сбрасывает ОДИНОЧНУЮ ссылку узла на используемое им
/// пространство имён (<c>Node.ns</c>) в <c>nil</c>, если она указывает
/// именно на удаляемый <paramref name="Ns"/> — в отличие от
/// <see cref="xmlUnlinkNs"/>, которая предназначена для работы со связными
/// списками, а не с одиночными полями.
/// </summary>
procedure xmlClearNodeNsRef(Node: xmlNodePtr; Ns: xmlNsPtr); inline;
begin
  if Node.ns = Ns then
    Node.ns := nil;
end;

/// <summary>
/// Полностью удаляет namespace-декларацию <paramref name="Ns"/> с узла
/// <paramref name="Node"/>: отвязывает её из <c>Node.nsDef</c> и обходит ВСЕ
/// узлы поддерева (<c>Node</c> и все его потомки через
/// <c>Node.GetNext(Node)</c> — обход всего поддерева в document order),
/// сбрасывая у каждого из них ссылку <c>Node.ns</c>, если она указывала
/// именно на удаляемое пространство имён.
/// </summary>
/// <remarks>
/// Этот полный обход поддерева необходим, потому что удаление
/// декларации пространства имён с элемента делает НЕВАЛИДНЫМИ все ссылки на
/// него у потомков — в libxml2/XML нет отдельного шага "переобъявления"
/// (в отличие от MSXML, где это иногда решается через
/// <c>ReconciliateNs</c>) при удалении, поэтому явная очистка ссылок
/// обязательна во избежание dangling-указателей <c>xmlNsPtr</c> у дочерних
/// узлов. Сложность операции — O(размер поддерева), что стоит учитывать при
/// частом удалении namespace-деклараций в больших документах.
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
/// Создаёт Delphi-обёртку над уже существующим <c>xmlNodePtr</c>,
/// устанавливая двустороннюю связь через <c>Node._private := Self</c>
/// (используется функциями <c>Cast(...)</c> для кэширования — см. замечание
/// к модулю в целом) и, если применимо, увеличивает refcount документа-
/// владельца.
/// </summary>
/// <remarks>
/// <para>
/// <b>Условие <c>FOwnerDocRefTaken</c>:</b>
/// <c>(Node.doc &lt;&gt; nil) and (xmlNodePtr(Node.doc) &lt;&gt; Node) and (Node.doc._private &lt;&gt; nil)</c>.
/// Третье условие в цепочке — <c>xmlNodePtr(Node.doc) &lt;&gt; Node</c> —
/// исключает случай, когда сам создаваемый объект И ЕСТЬ обёртка документа
/// (т.е. <c>TXMLDocument</c> унаследован от <c>TXMLNode</c> и вызывает этот
/// же конструктор через <c>inherited Create(xmlNodePtr(doc))</c>) —
/// документ не должен пытаться взять ref сам на себя, что привело бы к
/// невозможности когда-либо снизить refcount до нуля и разрушить объект.
/// </para>
/// <para>
/// Флаг <see cref="FOwnerDocRefTaken"/> запоминается отдельным полем (а не
/// вычисляется заново в <c>Destroy</c> из текущего состояния <c>NodePtr</c>),
/// поскольку к моменту разрушения объекта <c>NodePtr.doc</c> может быть уже
/// недоступен (см. <see cref="NodeFreeCallback"/>, обнуляющий <c>NodePtr</c>
/// при внешнем освобождении узла) — без сохранённого флага невозможно
/// достоверно узнать, был ли вообще взят ref в конструкторе.
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

  // Снимаем старую запись из ID-таблицы документа ДО того, как физически
  // изменится значение атрибута — иначе таблица будет содержать устаревшую
  // пару (старое значение -> узел).
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

  // Регистрируем НОВОЕ значение в ID-таблице документа, если атрибут
  // изначально был ID-атрибутом и получил непустое новое значение.
  // Сигнатура: xmlAddID(ctxt, doc, value, attr) — ctxt=nil означает
  // регистрацию без выполнения валидационных проверок уникальности,
  // см. conclase.net.
  if WasId and (AttrValue <> '') then
  begin
    AttrPtr.atype := XML_ATTRIBUTE_ID;   // xmlRemoveID могла сбросить/не менять atype — восстанавливаем явно
    if xmlAddID(nil, AttrPtr.parent.doc, Args.StrPtr(AttrValue), AttrPtr) = nil then
      LX2InternalError;   // например, дубликат ID в документе при включённой валидации
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
      xmlFreeDoc(xmlDocPtr(NodePtr));
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
          if Prefix = '' then
            xmlNewNs(Node, xmlStrPtr(HRef), nil)
          else
            xmlNewNs(Node, xmlStrPtr(HRef), xmlStrPtr(Prefix));
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
  Sources := TList<IXmlDocument>.Create;
  Imports := TStringList.Create;
  Imports.Sorted := True;
  Imports.CaseSensitive := True;
end;

destructor TXMLSchemaCollection.TItem.Destroy;
begin
  if Schema <> nil then
  begin
    xmlFreeDoc(Schema);
    Schema := nil;
  end;
  FreeAndNil(Sources);
  FreeAndNil(Imports);
  inherited;
end;

{ TXMLSchemaCollection }

/// <summary>
/// Мост между структурированными XML Schema ошибками libxml2 (вызываемыми
/// НАПРЯМУЮ из C-кода libxml2 через указатель функции, зарегистрированный
/// через <c>xmlSchemaSetParserStructuredErrors</c>/<c>SetValidStructuredErrors</c>)
/// и управляемым Delphi-обработчиком ошибок документа.
/// </summary>
/// <remarks>
/// Обёрнут в <c>try..except</c>, ПОЛНОСТЬЮ поглощающий любое исключение —
/// это необходимо, поскольку данная функция вызывается напрямую из
/// нативного C-кода libxml2 (объявлена <c>cdecl</c>), у которого нет
/// механизма Pascal-исключений/finally-блоков в стеке вызовов: если бы
/// Delphi-исключение "просочилось" через границу C-вызова обратно в
/// libxml2, это привело бы к неопределённому поведению/аварийному
/// завершению процесса, а не к корректной обработке ошибки на стороне
/// Pascal-кода.
/// </remarks>
procedure SchemaParserErrorCallback(userData: Pointer; const error: xmlErrorPtr); cdecl;
begin
  try
    var Err := TXMLError.Create(TXmlParseError.Create(error^)) as IXMLParseError;
    TXMLDocument(userData).Errors.FList.Add(Err);
  except
    // No exception, becouse libxml2 is plain c, without try catch
  end;
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
  Cleanup;

  FreeAndNil(FItems);
  FErrors._Release;
  inherited;
end;

procedure TXMLSchemaCollection.Cleanup;
begin
  for var I := 0 to Items.Count - 1 do
    if Items[I].Schema <> nil then
    begin
      xmlFreeDoc(Items[I].Schema);
      Items[I].Schema := nil;
    end;

  if FTempPath <> '' then
    TDirectory.Delete(FTempPath, True);
end;

procedure TXMLSchemaCollection.AddCollection(const otherCollection: IXMLSchemaCollection);
begin
  var Src := TXMLSchemaCollection(otherCollection);
  for var I := 0 to Src.Items.Count - 1 do
    for var J := 0 to Src.Items[I].Sources.Count - 1 do
      Add(Src.Items[I].NamespaceURI, Src.Items[I].Sources[J]);
end;

procedure TXMLSchemaCollection.Add(const NamespaceURI: string; const Doc: IXMLDocument; const Resolver: IXMLResolver);
var
  Item: TItem;
begin
  var Index := IndexOf(NamespaceURI);
  if Index >= 0 then
    Item := Items[Index]
  else
  begin
    Item := TItem.Create;
    Item.NamespaceURI := NamespaceURI;
    Items.Add(Item);
  end;

  // Prevent re-adding doc
  for var I := 0 to Item.Sources.Count - 1 do
    if TXmlDocument(Item.Sources[I]).NodePtr = TXmlDocument(Doc).NodePtr then
      Exit;

  Item.Sources.Add(Doc);

  FCompiled := False;
end;

procedure TXMLSchemaCollection.Compile;

  function IsImport(const Node: xmlNodePtr): Boolean; inline;
  begin
    Result := (Node.NamespaceURI = cSchemaNs) and (Node.LocalName = cImport);
  end;

  function IsInclude(const Node: xmlNodePtr): Boolean; inline;
  begin
    Result := (Node.NamespaceURI = cSchemaNs) and (Node.LocalName = cInclude);
  end;

  procedure ProcessImports(Item: TItem; Doc: xmlDocPtr);
  var
    Elem: xmlNodePtr;
  begin
    Elem := Doc.documentElement.FirstElementChild;
    while Elem <> nil do
    begin
      if IsImport(Elem) then
      begin
        var Import := Elem;
        Elem := Elem.NextElementSibling;
        Item.Imports.Add(Utf8ToString(Import.GetAttribute('namespace')));

        Import.parent.RemoveChild(Import);
      end
      else if IsInclude(Elem) then
      begin
        var Temp := Elem;
        Elem := Elem.NextElementSibling;
        Temp.parent.RemoveChild(Temp);
      end
      else
        Elem := Elem.NextElementSibling;
    end;
  end;

  procedure AddSource(Item: TItem; Doc: xmlDocPtr);
  var
    Elem, NewNode: xmlNodePtr;
  begin
    Elem := Doc.documentElement.FirstElementChild;
    while Elem <> nil do
    begin
      if IsImport(Elem) then
        Item.Imports.Add(UTF8ToString(Elem.GetAttribute('namespace')))
      else if IsInclude(Elem) then
        Elem := Elem.NextElementSibling
      else
      begin
        if xmlDOMWrapCloneNode(nil, Elem.doc, Elem, NewNode, Item.Schema, nil, 1, 0) = 0 then
          Item.Schema.documentElement.AppendChild(NewNode);
      end;
      Elem := Elem.NextElementSibling;
    end;
  end;

var
  Source: xmlDocPtr;
  I, J: NativeInt;
  Item: TItem;
begin
  //Cleanup;

  FTempPath := TPath.GetTempPath + TPath.GetGUIDFileName + PathDelim;
  TDirectory.CreateDirectory(FTempPath);

  for I := 0 to Items.Count - 1 do
  begin
    Item := Items[I];

    if Item.Schema <> nil then
      xmlFreeDoc(Item.Schema);

    Source := xmlDocPtr(TXmlDocument(Item.Sources[0]).NodePtr);
    Item.Schema := xmlDoc.Create(Source.ToBytes, DefaultParserOptions);
    ProcessImports(Item, Item.Schema);

    for J := 1 to Item.Sources.Count - 1 do
      AddSource(Item, xmlDocPtr(TXmlDocument(Item.Sources[J]).NodePtr));
  end;

  for I := 0 to Items.Count - 1 do
  begin
    Item := Items[I];

    var ns := Item.Schema.documentElement.nsDef;
    while ns <> nil do
    begin
      if xmlStrSame(ns.href, cSchemaNs) then
        Break;
      ns := ns.next;
    end;

    for J := 0 to Item.Imports.Count - 1 do
    begin
      var Index := IndexOf(Item.Imports[J]);
      if Index >= 0 then
      begin
        var Import := xmlNewDocNode(Item.Schema, ns, 'import', nil);
        Import.SetAttribute('namespace', Utf8Encode(Item.Imports[J]));
        Import.SetAttribute('schemaLocation', Utf8Encode(Index.ToString + '.xsd'));
        Item.Schema.documentElement.InsertBefore(Import, Item.Schema.documentElement.FirstElementChild);
      end;
    end;
    Item.FileName := FTempPath + I.ToString + '.xsd';
    Item.Schema.Save(Item.FileName);
  end;

  if FSchemaRoot <> nil then
  begin
    xmlFreeDoc(FSchemaRoot);
    FSchemaRoot := nil;
  end;

  FSchemaRoot := xmlDoc.CreateFromFile(Items.Last.FileName, DefaultParserOptions);

  FCompiled := True;
end;

function TXMLSchemaCollection.Validate(const Doc: IXMLDocument): Boolean;
var
  vctxt: xmlSchemaValidCtxtPtr;
  SchemaDoc: xmlDocPtr;
begin
  Doc.errors.clear;

  if (Items.Count = 1) and (Items[0].Sources.Count = 1) then
  begin
    // Typical situation - one schema file
    SchemaDoc := xmlDocPtr(TXmlDocument(Items[0].Sources[0]).NodePtr);
  end
  else
  begin
    // We save compiled schema to files & load last one again, that allows resolve paths by libxml
    // custom ResourceLoader doesnt called when not direct import in xsd
    if not FCompiled then
      Compile;

    SchemaDoc := FSchemaRoot;
  end;

  var ctxt := xmlSchemaNewDocParserCtxt(SchemaDoc);
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

  var DocPtr := xmlDocPtr(TXMLDocument(Doc).NodePtr);
  Result := xmlSchemaValidateDoc(vctxt, DocPtr) = 0;
  //TODO: Временная заглушка, пока не научимся нормально схемы обрабатывать
  if not Result and (Doc.Errors.Count > 0) then
    Result := Doc.Errors[0].ErrorCode = 1845;

  xmlSchemaFreeValidCtxt(vctxt);
  xmlSchemaFree(schema);
  xmlSchemaFreeParserCtxt(ctxt);
end;

function TXMLSchemaCollection.Get(const NamespaceURI: string): IXMLDocument;
begin
  if not FCompiled then
    Compile;

  var Index := IndexOf(NamespaceURI);
  if Index >= 0 then
    Result := Cast(FItems[Index].Schema)
  else
    Result := nil;
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
  Result := 0;
  while Result < FItems.Count do
    if FItems[Result].NamespaceURI = NamespaceURI then
      Exit
    else
      Inc(Result);
  Result := -1;
end;

procedure TXMLSchemaCollection.Remove(const NamespaceURI: string);
begin
  var Index := IndexOf(NamespaceURI);
  if Index >= 0 then
    FItems.Delete(Index);
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
