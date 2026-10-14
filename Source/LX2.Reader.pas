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
/// Pull reader of XML documents over the libxml2 xmlTextReader, after System.Xml.XmlReader:
/// the caller moves a cursor through the nodes of the document in document order, memory
/// stays constant whatever the size of the document, and a record can be taken out as a
/// small DOM of its own.
/// </summary>
/// <remarks>
/// <para>
/// The methods that consume nodes follow the positioning rules of .NET: ReadElementContentAs*,
/// ReadInnerXml, ReadOuterXml, ReadElement, Skip and a successful ReadTo* leave the reader on
/// the node after the element. Called inside <c>while R.Read do</c>, the Read of the loop
/// then passes over the following node; <see cref="IXmlReader.Elements"/> and
/// <see cref="IXmlReader.ReadElements"/> walk records without that trap.
/// </para>
/// <para>
/// External entities, external DTDs and the network are never used. A DOCTYPE raises an
/// error unless <see cref="TXmlReaderSettings.DtdProcessing"/> allows it.
/// </para>
/// </remarks>
unit LX2.Reader;

interface

uses
  System.SysUtils, System.Classes,
  libxml2.API, LX2.Types, LX2.DOM, RttiDispatch;

type
  {$SCOPEDENUMS ON}
  /// <summary>Kind of the current node: the values of XmlNodeType in .NET and of
  /// xmlReaderTypes in libxml2. Document, Entity, EndEntity and XmlDeclaration never occur
  /// in a document libxml2 reads.</summary>
  TXmlNodeType = (None, Element, Attribute, Text, CDATA, EntityReference, Entity,
    ProcessingInstruction, Comment, Document, DocumentType, DocumentFragment, Notation,
    Whitespace, SignificantWhitespace, EndElement, EndEntity, XmlDeclaration);

  TXmlReadState = (Initial, Interactive, Error, EndOfFile, Closed);

  /// <summary>
  /// What a DOCTYPE does. Prohibit: EXmlReaderError at it. Ignore: the node is passed over
  /// and nothing of the DTD applies (a reference to a declared entity comes as an
  /// EntityReference node). Parse: the entities and attribute defaults of the internal
  /// subset apply. External subsets and external entities are never loaded.
  /// </summary>
  TXmlDtdProcessing = (Prohibit, Ignore, Parse);
  {$SCOPEDENUMS OFF}

  TXmlReaderErrorEvent = reference to procedure(const Error: TXmlParseError);

  /// <summary>
  /// Settings of a reader. A variable of this type starts with the defaults (class operator
  /// Initialize): no DTD, line numbers exact past 65535, text nodes up to 1 GB.
  /// </summary>
  TXmlReaderSettings = record
    /// <summary>libxml2 options. The reader adds XML_PARSE_NO_XXE and XML_PARSE_NONET, sets
    /// the DTD options from DtdProcessing and drops xmlParseNoDict, under which the names
    /// would die with their nodes. Default: [xmlParseBigLines, xmlParseHuge].</summary>
    Options: TXmlParserOptions;
    /// <summary>Default: Prohibit.</summary>
    DtdProcessing: TXmlDtdProcessing;
    /// <summary>Passes over whitespace-only text that is not under <c>xml:space="preserve"</c>;
    /// such text under it still comes, as SignificantWhitespace.</summary>
    IgnoreWhitespace: Boolean;
    IgnoreComments: Boolean;
    IgnoreProcessingInstructions: Boolean;
    /// <summary>Limit of the ratio of text made by entity expansion to the input; 0 keeps the
    /// default of libxml2 (5).</summary>
    MaxAmplification: Cardinal;
    /// <summary>Encoding of a document without a declaration, or against it; empty means
    /// detect. Text given as a <c>string</c> is UTF-16 and ignores it.</summary>
    Encoding: string;
    /// <summary>Base URI of relative references and the name of the document in messages.</summary>
    BaseURI: string;
    /// <summary>The reader frees the stream it reads when it is closed.</summary>
    CloseInput: Boolean;
    /// <summary>Validates while reading against the compiled set. The imports of the set
    /// are resolved when it compiles, not by the reader; the set must not change while the
    /// reader uses it.</summary>
    Schemas: IXMLSchemaCollection;
    /// <summary>Receives each validation error and warning. Without it the first validation
    /// error raises EXmlParserError from the Read that met it, as in .NET.</summary>
    OnValidationError: TXmlReaderErrorEvent;
    class operator Initialize(out Dest: TXmlReaderSettings);
  end;

  {$M+}
  IXmlReader = interface;

  IXmlReaderEnumerator = interface(IDispatchInvokable)
    ['{EB389217-58C6-474E-9D69-93FA687FC48E}']
    function  GetCurrent: IXmlReader;
    function  MoveNext: Boolean;
    property  Current: IXmlReader read GetCurrent;
  end;

  IXmlReaderEnumerable = interface(IDispatchInvokable)
    ['{34A7C72F-5875-45EF-9ADA-4406D5983BF0}']
    function  GetEnumerator: IXmlReaderEnumerator;
  end;

  IXmlElementEnumerator = interface(IDispatchInvokable)
    ['{9DF93C99-D8AA-439D-89D8-4117B955AE74}']
    function  GetCurrent: IXMLElement;
    function  MoveNext: Boolean;
    property  Current: IXMLElement read GetCurrent;
  end;

  IXmlElementEnumerable = interface(IDispatchInvokable)
    ['{0160E134-3194-4049-B958-9104204D5EF6}']
    function  GetEnumerator: IXmlElementEnumerator;
  end;

  /// <summary>
  /// Forward-only cursor over the nodes of an XML document (System.Xml.XmlReader). Made by
  /// <see cref="XmlReader"/>.
  /// </summary>
  /// <remarks>
  /// A name given alone matches the local name in any namespace; with a namespace URI both
  /// must match, and an empty URI means no namespace. Late-bound callers choose an overload by
  /// the number of arguments, so there are no parameters with default values.
  /// </remarks>
  IXmlReader = interface(IDispatchInvokable)
    ['{A6B8C492-4E9A-4B2E-8D9F-C6AE122C070F}']
    {$region 'Getters'}
    function  Get_AttributeCount: Integer;
    function  Get_BaseURI: string;
    function  Get_Depth: Integer;
    function  Get_EOF: Boolean;
    function  Get_Errors: IXMLErrors;
    function  Get_HasAttributes: Boolean;
    function  Get_HasValue: Boolean;
    function  Get_IsEmptyElement: Boolean;
    function  Get_IsNamespaceDeclaration: Boolean;
    function  Get_IsValid: Boolean;
    function  Get_LineNumber: Integer;
    function  Get_LocalName: string;
    function  Get_Name: string;
    function  Get_NamespaceURI: string;
    function  Get_NodeType: TXmlNodeType;
    function  Get_Prefix: string;
    function  Get_ReadState: TXmlReadState;
    function  Get_Value: string;
    function  Get_XmlLang: string;
    {$endregion}

    { Moving }
    /// <summary>To the next node: False at the end and after it. Malformed XML raises
    /// EXmlParserError, and the reader stays in the Error state.</summary>
    function  Read: Boolean;
    /// <summary>Past the current element with its subtree, past the element of the current
    /// attribute, otherwise one Read.</summary>
    procedure Skip;
    /// <summary>Past whitespace, comments, processing instructions and the DOCTYPE; from an
    /// attribute to its element. Returns the type of the node it stops on.</summary>
    function  MoveToContent: TXmlNodeType;
    /// <summary>On to the next element with this name in document order; False leaves the
    /// reader at the end.</summary>
    function  ReadToFollowing(const LocalName: string): Boolean; overload;
    function  ReadToFollowing(const LocalName, NamespaceURI: string): Boolean; overload;
    /// <summary>On to an element with this name inside the current element; False leaves
    /// the reader on the end tag of the current element (at once for an empty one).</summary>
    function  ReadToDescendant(const LocalName: string): Boolean; overload;
    function  ReadToDescendant(const LocalName, NamespaceURI: string): Boolean; overload;
    /// <summary>On to the next sibling element with this name; False leaves the reader on the
    /// end tag of the parent.</summary>
    function  ReadToNextSibling(const LocalName: string): Boolean; overload;
    function  ReadToNextSibling(const LocalName, NamespaceURI: string): Boolean; overload;
    /// <summary>
    /// A reader of the current element and its subtree (XmlReader.ReadSubtree): its first
    /// Read shows the element, it ends after the end tag of the element. Closing it leaves
    /// this reader on that end tag, or on the element when it is empty, never past it.
    /// </summary>
    function  ReadSubtree: IXmlReader;

    { Records }
    /// <summary>
    /// The elements with this name from the current position on, each as a reader of its
    /// subtree already on the element. The loop body may read the record or not: the next
    /// one is looked for after the end of the previous one either way, and an element of the
    /// same name inside a record is not one of them.
    /// </summary>
    function  Elements(const LocalName: string): IXmlReaderEnumerable; overload;
    function  Elements(const LocalName, NamespaceURI: string): IXmlReaderEnumerable; overload;
    /// <summary>The same elements, each copied by <see cref="ReadElement"/>.</summary>
    function  ReadElements(const LocalName: string): IXmlElementEnumerable; overload;
    function  ReadElements(const LocalName, NamespaceURI: string): IXmlElementEnumerable; overload;

    { Elements }
    /// <summary>MoveToContent, then True on an element (with this name).</summary>
    function  IsStartElement: Boolean; overload;
    function  IsStartElement(const LocalName: string): Boolean; overload;
    function  IsStartElement(const LocalName, NamespaceURI: string): Boolean; overload;
    /// <summary>MoveToContent, then past the start tag of an element (with this name);
    /// EXmlReaderError on anything else.</summary>
    procedure ReadStartElement; overload;
    procedure ReadStartElement(const LocalName: string); overload;
    procedure ReadStartElement(const LocalName, NamespaceURI: string); overload;
    /// <summary>MoveToContent, then past an end tag; EXmlReaderError on anything else.</summary>
    procedure ReadEndElement;

    { Content }
    /// <summary>On an attribute its value (the reader stays); otherwise text, CDATA and
    /// whitespace up to the next element or end tag, where the reader stops.
    /// EXmlReaderError on an element.</summary>
    function  ReadContentAsString: string;
    /// <summary>
    /// The text of the current element, comments and processing instructions left out, ''
    /// for an empty one; EXmlReaderError on a child element or when the reader is not on an
    /// element. Leaves the reader on the node after the end tag.
    /// </summary>
    function  ReadElementContentAsString: string; overload;
    /// <summary>The same for an element with this name, EXmlReaderError for another one.</summary>
    function  ReadElementContentAsString(const LocalName, NamespaceURI: string): string; overload;
    /// <summary>The content in the lexical space of the type (see XmlConvert): the same on
    /// every locale. EXmlReaderError on a value outside it.</summary>
    function  ReadElementContentAsInteger: Integer;
    function  ReadElementContentAsInt64: Int64;
    function  ReadElementContentAsDouble: Double;
    /// <summary>xs:decimal as Currency; a nonzero fifth fraction digit is an error rather
    /// than a rounded value.</summary>
    function  ReadElementContentAsCurrency: Currency;
    function  ReadElementContentAsBoolean: Boolean;
    /// <summary>xs:dateTime or xs:date, the time as written: a time zone is dropped.</summary>
    function  ReadElementContentAsDateTime: TDateTime;
    /// <summary>Decodes the base64 content of the current element into the stream as it
    /// goes, without a string for the whole text; returns the number of bytes written.</summary>
    function  ReadElementContentAsBase64(Stream: TStream): Int64;
    /// <summary>Markup of the content of the current element, or the value of an attribute;
    /// leaves the reader as ReadElementContentAsString does.</summary>
    function  ReadInnerXml: string;
    /// <summary>Markup of the current element with its subtree, with the declarations of the
    /// namespaces it uses from its ancestors; <c>name="value"</c> on an attribute.</summary>
    function  ReadOuterXml: string;
    /// <summary>
    /// Copies the current element with its subtree into a new document, as its document
    /// element, and moves past the element (XNode.ReadFrom). Every namespace in scope of the
    /// element is declared on the copy, used or not, so prefixes in values such as
    /// <c>xsi:type="t:Code"</c> keep their meaning; <c>xml:lang</c> and <c>xml:space</c> of the
    /// ancestors are not copied.
    /// </summary>
    function  ReadElement: IXMLElement; overload;
    /// <summary>The same copy made in <paramref name="Doc"/>, out of its tree
    /// (XmlDocument.ReadNode).</summary>
    function  ReadElement(const Doc: IXMLDocument): IXMLElement; overload;
    /// <summary>
    /// The current element with its subtree as nodes of the tree the reader builds, without a
    /// copy: the cheapest DOM of a record, and the reader does not move. The nodes live until
    /// the reader moves (for a record of <see cref="Elements"/>, while the loop body runs);
    /// a wrapper kept longer has lost its node: reads such as GetAttribute return empty
    /// values, other members fail with an access violation.
    /// ParentNode goes up the elements the reader has open and ends below the document;
    /// OwnerDocument is nil. To keep a record, ReadElement or CloneNode copies it.
    /// </summary>
    function  Expand: IXMLElement;

    { Attributes of the current element, also while the reader is on one of them }
    /// <summary>A qualified name: <c>p:a</c> is looked for by the namespace its prefix is
    /// bound to; '' when there is no such attribute.</summary>
    function  GetAttribute(const Name: string): string; overload;
    function  GetAttribute(const LocalName, NamespaceURI: string): string; overload;
    /// <summary>Namespace declarations come first, then the attributes, each in document order.</summary>
    function  GetAttribute(Index: Integer): string; overload;
    function  TryGetAttribute(const Name: string; out Value: string): Boolean; overload;
    function  TryGetAttribute(const LocalName, NamespaceURI: string; out Value: string): Boolean; overload;
    function  MoveToAttribute(const Name: string): Boolean; overload;
    function  MoveToAttribute(const LocalName, NamespaceURI: string): Boolean; overload;
    procedure MoveToAttribute(Index: Integer); overload;
    function  MoveToFirstAttribute: Boolean;
    function  MoveToNextAttribute: Boolean;
    function  MoveToElement: Boolean;
    /// <summary>On an attribute, steps through the text of its value.</summary>
    function  ReadAttributeValue: Boolean;

    /// <summary>The URI bound to the prefix in scope, of the default namespace for '';
    /// '' when unbound.</summary>
    function  LookupNamespace(const Prefix: string): string;
    /// <summary>Releases the document and the input; Read returns False after it.</summary>
    procedure Close;

    property  AttributeCount: Integer read Get_AttributeCount;
    property  BaseURI: string read Get_BaseURI;
    property  Depth: Integer read Get_Depth;
    property  EOF: Boolean read Get_EOF;
    /// <summary>Warnings and validation errors met so far; a fatal error raises instead.</summary>
    property  Errors: IXMLErrors read Get_Errors;
    property  HasAttributes: Boolean read Get_HasAttributes;
    property  HasValue: Boolean read Get_HasValue;
    /// <summary>The current node is an element without content (<c>&lt;a/&gt;</c>), which has
    /// no EndElement. False on an attribute.</summary>
    property  IsEmptyElement: Boolean read Get_IsEmptyElement;
    property  IsNamespaceDeclaration: Boolean read Get_IsNamespaceDeclaration;
    /// <summary>No validation error has been met.</summary>
    property  IsValid: Boolean read Get_IsValid;
    /// <summary>Line of the node: of the start tag for an end tag, of the element for an
    /// attribute; 0 when unknown. The column is known only for parse errors
    /// (EXmlParserError.Col).</summary>
    property  LineNumber: Integer read Get_LineNumber;
    property  LocalName: string read Get_LocalName;
    property  Name: string read Get_Name;
    property  NamespaceURI: string read Get_NamespaceURI;
    property  NodeType: TXmlNodeType read Get_NodeType;
    property  Prefix: string read Get_Prefix;
    property  ReadState: TXmlReadState read Get_ReadState;
    /// <summary>Made on the first access and kept until the reader moves.</summary>
    property  Value: string read Get_Value;
    property  XmlLang: string read Get_XmlLang;
  end;
  {$M-}

  /// <summary>Creates readers, as System.Xml.XmlReader.Create does. Text is read by
  /// CreateFromString and a file by CreateFromFile, so a string is never taken for the
  /// other.</summary>
  XmlReader = record
  public
    /// <summary>The stream is read as the reader goes; it is freed with the reader only
    /// with <see cref="TXmlReaderSettings.CloseInput"/>.</summary>
    class function Create(Stream: TStream): IXmlReader; overload; static;
    class function Create(Stream: TStream; const Settings: TXmlReaderSettings): IXmlReader; overload; static;
    /// <summary>The bytes of a document, parsed in place; the reader holds a reference to them.</summary>
    class function Create(const Data: TBytes): IXmlReader; overload; static;
    class function Create(const Data: TBytes; const Settings: TXmlReaderSettings): IXmlReader; overload; static;
    /// <summary>A reader over a loaded document (XmlNodeReader), which it keeps alive: no
    /// line numbers, no validation. Changes made to the document while it is read are not
    /// seen consistently.</summary>
    class function Create(const Doc: IXMLDocument): IXmlReader; overload; static;
    class function Create(const Doc: IXMLDocument; const Settings: TXmlReaderSettings): IXmlReader; overload; static;
    /// <summary>EFOpenError when the file cannot be opened.</summary>
    class function CreateFromFile(const FileName: string): IXmlReader; overload; static;
    class function CreateFromFile(const FileName: string; const Settings: TXmlReaderSettings): IXmlReader; overload; static;
    /// <summary>Text of a document; its encoding declaration does not apply.</summary>
    class function CreateFromString(const XML: string): IXmlReader; overload; static;
    class function CreateFromString(const XML: string; const Settings: TXmlReaderSettings): IXmlReader; overload; static;
    /// <summary>The bytes of a document: the encoding comes from its declaration or from
    /// <see cref="TXmlReaderSettings.Encoding"/>.</summary>
    class function CreateFromString(const XML: RawByteString): IXmlReader; overload; static;
    class function CreateFromString(const XML: RawByteString; const Settings: TXmlReaderSettings): IXmlReader; overload; static;
  end;

implementation

uses
  System.Generics.Collections, LX2.Helpers, LX2.DOM.Classes;

resourcestring
  SReaderNotOnElement     = 'The reader is on a %s node, not on an element';
  SReaderElementNotFound  = 'Element "%s" is expected, the reader is on element "%s"';
  SReaderEndTagExpected   = 'An end tag is expected, the reader is on a %s node';
  SReaderMixedContent     = 'Element "%s" holds a child element where text is expected';
  SReaderContentOnElement = 'Content is read from text or an attribute, the reader is on element "%s"';
  SReaderInvalidValue     = '"%s" in element "%s" is not a valid %s value';
  SReaderInvalidBase64    = 'Element "%s" does not hold valid base64';
  SReaderDtdProhibited    = 'The document has a DOCTYPE, which the settings of the reader prohibit (DtdProcessing)';
  SReaderSchemaFailed     = 'The schemas do not compile: %s';
  SReaderWalkerSchema     = 'A reader over a loaded document does not validate';
  SReaderCannotOpen       = 'Cannot open file "%s"';
  SReaderNoInput          = 'The input of the reader cannot be opened';
  SReaderAttributeIndex   = 'Attribute index %d is out of range (%d attributes)';

const
  NodeTypeNames: array[TXmlNodeType] of string = ('none', 'element', 'attribute', 'text',
    'CDATA', 'entity reference', 'entity', 'processing instruction', 'comment', 'document',
    'document type', 'document fragment', 'notation', 'whitespace', 'significant whitespace',
    'end element', 'end entity', 'XML declaration');

type
  TXMLNodeAccess = class(TXMLNode);

  /// <summary>
  /// The core of a reader: the moves, the state of the current node and its attributes. The
  /// composite methods (MoveToContent, ReadTo*, Read*Element*, ReadSubtree, the records)
  /// are written once on top of the core, so a reader of a subtree, whose core is bounded by
  /// its element, follows the same positioning rules.
  /// </summary>
  TXmlReaderBase = class(TDispatchInvokable, IXmlReader)
  protected
    /// <summary>The current node is an element or attribute with this name; atoms where the
    /// core has them.</summary>
    function  NameIs(const LocalName, NamespaceURI: string; AnyNamespace: Boolean): Boolean; virtual;
    function  FollowingNamed(const LocalName, NamespaceURI: string; AnyNamespace: Boolean): Boolean; virtual;
    function  DescendantNamed(const LocalName, NamespaceURI: string; AnyNamespace: Boolean): Boolean;
    function  SiblingNamed(const LocalName, NamespaceURI: string; AnyNamespace: Boolean): Boolean;
    function  StartElementNamed(const LocalName, NamespaceURI: string; AnyNamespace: Boolean): Boolean;
    procedure RequireStartElement(const LocalName, NamespaceURI: string; AnyNamespace: Boolean);
    /// <summary>Markup of the current element, of its content; does not move.</summary>
    function  CurrentOuterXml: string; virtual; abstract;
    function  CurrentInnerXml: string; virtual; abstract;
    /// <summary>The current element copied into Doc, out of its tree; does not move.</summary>
    function  CopyElement(const Doc: xmlDocPtr): xmlNodePtr; virtual; abstract;
    /// <summary>The value of the current node as UTF-8, in place when the core has it so;
    /// <paramref name="Keep"/> holds a copy otherwise.</summary>
    procedure ValueBytes(out P: PByte; out Len: NativeInt; var Keep: RawByteString); virtual;
    /// <summary>ReadElementContentAsString as UTF-8, for the typed reads.</summary>
    function  ReadElementContentUtf8: RawByteString; virtual;
    procedure RaiseError(const Msg: string);
    procedure RequireElement;
    procedure InvalidValue(const Value: RawByteString; const Element: string; Line: Integer; const TypeName: string);
  public
    { IXmlReader core }
    function  Get_AttributeCount: Integer; virtual; abstract;
    function  Get_BaseURI: string; virtual; abstract;
    function  Get_Depth: Integer; virtual; abstract;
    function  Get_EOF: Boolean; virtual; abstract;
    function  Get_Errors: IXMLErrors; virtual; abstract;
    function  Get_HasAttributes: Boolean; virtual; abstract;
    function  Get_HasValue: Boolean; virtual; abstract;
    function  Get_IsEmptyElement: Boolean; virtual; abstract;
    function  Get_IsNamespaceDeclaration: Boolean; virtual; abstract;
    function  Get_IsValid: Boolean; virtual; abstract;
    function  Get_LineNumber: Integer; virtual; abstract;
    function  Get_LocalName: string; virtual; abstract;
    function  Get_Name: string; virtual; abstract;
    function  Get_NamespaceURI: string; virtual; abstract;
    function  Get_NodeType: TXmlNodeType; virtual; abstract;
    function  Get_Prefix: string; virtual; abstract;
    function  Get_ReadState: TXmlReadState; virtual; abstract;
    function  Get_Value: string; virtual; abstract;
    function  Get_XmlLang: string; virtual; abstract;
    function  Read: Boolean; virtual; abstract;
    procedure Skip; virtual;
    function  GetAttribute(const Name: string): string; overload; virtual; abstract;
    function  GetAttribute(const LocalName, NamespaceURI: string): string; overload; virtual; abstract;
    function  GetAttribute(Index: Integer): string; overload; virtual; abstract;
    function  TryGetAttribute(const Name: string; out Value: string): Boolean; overload; virtual; abstract;
    function  TryGetAttribute(const LocalName, NamespaceURI: string; out Value: string): Boolean; overload; virtual; abstract;
    function  MoveToAttribute(const Name: string): Boolean; overload; virtual; abstract;
    function  MoveToAttribute(const LocalName, NamespaceURI: string): Boolean; overload; virtual; abstract;
    procedure MoveToAttribute(Index: Integer); overload; virtual; abstract;
    function  MoveToFirstAttribute: Boolean; virtual; abstract;
    function  MoveToNextAttribute: Boolean; virtual; abstract;
    function  MoveToElement: Boolean; virtual; abstract;
    function  ReadAttributeValue: Boolean; virtual; abstract;
    function  LookupNamespace(const Prefix: string): string; virtual; abstract;
    function  Expand: IXMLElement; virtual; abstract;
    procedure Close; virtual; abstract;

    { IXmlReader composites }
    function  MoveToContent: TXmlNodeType;
    function  ReadToFollowing(const LocalName: string): Boolean; overload;
    function  ReadToFollowing(const LocalName, NamespaceURI: string): Boolean; overload;
    function  ReadToDescendant(const LocalName: string): Boolean; overload;
    function  ReadToDescendant(const LocalName, NamespaceURI: string): Boolean; overload;
    function  ReadToNextSibling(const LocalName: string): Boolean; overload;
    function  ReadToNextSibling(const LocalName, NamespaceURI: string): Boolean; overload;
    function  ReadSubtree: IXmlReader;
    function  Elements(const LocalName: string): IXmlReaderEnumerable; overload;
    function  Elements(const LocalName, NamespaceURI: string): IXmlReaderEnumerable; overload;
    function  ReadElements(const LocalName: string): IXmlElementEnumerable; overload;
    function  ReadElements(const LocalName, NamespaceURI: string): IXmlElementEnumerable; overload;
    function  IsStartElement: Boolean; overload;
    function  IsStartElement(const LocalName: string): Boolean; overload;
    function  IsStartElement(const LocalName, NamespaceURI: string): Boolean; overload;
    procedure ReadStartElement; overload;
    procedure ReadStartElement(const LocalName: string); overload;
    procedure ReadStartElement(const LocalName, NamespaceURI: string); overload;
    procedure ReadEndElement;
    function  ReadContentAsString: string;
    function  ReadElementContentAsString: string; overload; virtual;
    function  ReadElementContentAsString(const LocalName, NamespaceURI: string): string; overload;
    function  ReadElementContentAsInteger: Integer;
    function  ReadElementContentAsInt64: Int64;
    function  ReadElementContentAsDouble: Double;
    function  ReadElementContentAsCurrency: Currency;
    function  ReadElementContentAsBoolean: Boolean;
    function  ReadElementContentAsDateTime: TDateTime;
    function  ReadElementContentAsBase64(Stream: TStream): Int64;
    function  ReadInnerXml: string;
    function  ReadOuterXml: string;
    function  ReadElement: IXMLElement; overload;
    function  ReadElement(const Doc: IXMLDocument): IXMLElement; overload;
    // A late-bound caller finds properties among those of the class
    property  AttributeCount: Integer read Get_AttributeCount;
    property  BaseURI: string read Get_BaseURI;
    property  Depth: Integer read Get_Depth;
    property  EOF: Boolean read Get_EOF;
    property  Errors: IXMLErrors read Get_Errors;
    property  HasAttributes: Boolean read Get_HasAttributes;
    property  HasValue: Boolean read Get_HasValue;
    property  IsEmptyElement: Boolean read Get_IsEmptyElement;
    property  IsNamespaceDeclaration: Boolean read Get_IsNamespaceDeclaration;
    property  IsValid: Boolean read Get_IsValid;
    property  LineNumber: Integer read Get_LineNumber;
    property  LocalName: string read Get_LocalName;
    property  Name: string read Get_Name;
    property  NamespaceURI: string read Get_NamespaceURI;
    property  NodeType: TXmlNodeType read Get_NodeType;
    property  Prefix: string read Get_Prefix;
    property  ReadState: TXmlReadState read Get_ReadState;
    property  Value: string read Get_Value;
    property  XmlLang: string read Get_XmlLang;
  end;

  /// <summary>Strings of the names a reader hands out, by their pointer in the dictionary of
  /// the reader, which keeps them as long as the reader lives: a string per distinct name,
  /// not per node.</summary>
  TNameCache = record
  private const
    Size = 256;
    Probes = 8;
  private
    FKeys: array[0..Size - 1] of Pointer;
    FValues: array[0..Size - 1] of string;
  public
    function Get(P: xmlCharPtr): string;
  end;

  TArgumentAtom = record
    Text: string;
    Atom: xmlCharPtr;
  end;

  /// <summary>The reader over libxml2.</summary>
  TXmlTextReader = class(TXmlReaderBase)
  private
    FReader: xmlTextReaderPtr;
    FSettings: TXmlReaderSettings;
    FState: TXmlReadState;
    FStream: TStream;
    FOwnsStream: Boolean;
    FDocument: IXMLDocument;
    FErrors: TXMLErrors;
    FErrorsRef: IXMLErrors;
    FValidationErrors: Integer;
    FPastProlog: Boolean;
    FWalker: Boolean;
    // State of the current position, dropped by every move
    FTypeValid: Boolean;
    FNodeType: TXmlNodeType;
    FValueValid: Boolean;
    FValue: string;
    FOnAttribute: Boolean;
    // Index of the current attribute, -1 while not known
    FAttributeIndex: Integer;
    FNames: TNameCache;
    FAtoms: array[0..3] of TArgumentAtom;
    FNextAtom: Integer;
    procedure HandleError(const error: xmlError);
    procedure Moved; inline;
    function  Step(Next: Boolean): Boolean;
    procedure CheckProlog;
    function  Filtered: Boolean;
    function  PreservesSpace: Boolean;
    function  AtomOf(const Name: string): xmlCharPtr; inline;
    function  NewAtom(const Name: string): xmlCharPtr;
    /// <summary>Index of the current attribute, found among the attributes when not known.</summary>
    function  AttributeIndex: Integer;
    procedure ReturnToAttribute(Index: Integer);
    function  Live: Boolean; inline;
  protected
    function  NameIs(const LocalName, NamespaceURI: string; AnyNamespace: Boolean): Boolean; override;
    function  FollowingNamed(const LocalName, NamespaceURI: string; AnyNamespace: Boolean): Boolean; override;
    function  CurrentOuterXml: string; override;
    function  CurrentInnerXml: string; override;
    function  CopyElement(const Doc: xmlDocPtr): xmlNodePtr; override;
    procedure ValueBytes(out P: PByte; out Len: NativeInt; var Keep: RawByteString); override;
    function  ReadElementContentUtf8: RawByteString; override;
  public
    constructor Create(const Settings: TXmlReaderSettings);
    destructor Destroy; override;
    /// <summary>Takes the native reader made for this object (its error handler is
    /// HandleError) and applies the settings that need it.</summary>
    procedure Attach(Reader: xmlTextReaderPtr);
    function  Get_AttributeCount: Integer; override;
    function  Get_BaseURI: string; override;
    function  Get_Depth: Integer; override;
    function  Get_EOF: Boolean; override;
    function  Get_Errors: IXMLErrors; override;
    function  Get_HasAttributes: Boolean; override;
    function  Get_HasValue: Boolean; override;
    function  Get_IsEmptyElement: Boolean; override;
    function  Get_IsNamespaceDeclaration: Boolean; override;
    function  Get_IsValid: Boolean; override;
    function  Get_LineNumber: Integer; override;
    function  Get_LocalName: string; override;
    function  Get_Name: string; override;
    function  Get_NamespaceURI: string; override;
    function  Get_NodeType: TXmlNodeType; override;
    function  Get_Prefix: string; override;
    function  Get_ReadState: TXmlReadState; override;
    function  Get_Value: string; override;
    function  Get_XmlLang: string; override;
    function  Read: Boolean; override;
    procedure Skip; override;
    function  GetAttribute(const Name: string): string; overload; override;
    function  GetAttribute(const LocalName, NamespaceURI: string): string; overload; override;
    function  GetAttribute(Index: Integer): string; overload; override;
    function  TryGetAttribute(const Name: string; out Value: string): Boolean; overload; override;
    function  TryGetAttribute(const LocalName, NamespaceURI: string; out Value: string): Boolean; overload; override;
    function  MoveToAttribute(const Name: string): Boolean; overload; override;
    function  MoveToAttribute(const LocalName, NamespaceURI: string): Boolean; overload; override;
    procedure MoveToAttribute(Index: Integer); overload; override;
    function  MoveToFirstAttribute: Boolean; override;
    function  MoveToNextAttribute: Boolean; override;
    function  MoveToElement: Boolean; override;
    function  ReadAttributeValue: Boolean; override;
    function  LookupNamespace(const Prefix: string): string; override;
    function  Expand: IXMLElement; override;
    procedure Close; override;
    function  ReadElementContentAsString: string; overload; override;
  end;

  /// <summary>
  /// The reader of an element and its subtree over the reader it was made from, as
  /// XmlSubtreeReader: Initial until the first Read, which shows the element without moving
  /// the outer reader; EndOfFile after the end tag of the element (after the element when it
  /// is empty). The outer reader never goes past that point through this one. Names,
  /// attributes and namespaces are those of the outer reader; Depth counts from the element.
  /// </summary>
  TXmlSubtreeReader = class(TXmlReaderBase)
  private
    FOuter: TXmlReaderBase;
    FOuterRef: IXmlReader;
    FInitialDepth: Integer;
    FState: TXmlReadState;
    function  Live: Boolean; inline;
  protected
    function  NameIs(const LocalName, NamespaceURI: string; AnyNamespace: Boolean): Boolean; override;
    function  CurrentOuterXml: string; override;
    function  CurrentInnerXml: string; override;
    function  CopyElement(const Doc: xmlDocPtr): xmlNodePtr; override;
    procedure ValueBytes(out P: PByte; out Len: NativeInt; var Keep: RawByteString); override;
  public
    constructor Create(Outer: TXmlReaderBase);
    destructor Destroy; override;
    function  Get_AttributeCount: Integer; override;
    function  Get_BaseURI: string; override;
    function  Get_Depth: Integer; override;
    function  Get_EOF: Boolean; override;
    function  Get_Errors: IXMLErrors; override;
    function  Get_HasAttributes: Boolean; override;
    function  Get_HasValue: Boolean; override;
    function  Get_IsEmptyElement: Boolean; override;
    function  Get_IsNamespaceDeclaration: Boolean; override;
    function  Get_IsValid: Boolean; override;
    function  Get_LineNumber: Integer; override;
    function  Get_LocalName: string; override;
    function  Get_Name: string; override;
    function  Get_NamespaceURI: string; override;
    function  Get_NodeType: TXmlNodeType; override;
    function  Get_Prefix: string; override;
    function  Get_ReadState: TXmlReadState; override;
    function  Get_Value: string; override;
    function  Get_XmlLang: string; override;
    function  Read: Boolean; override;
    function  GetAttribute(const Name: string): string; overload; override;
    function  GetAttribute(const LocalName, NamespaceURI: string): string; overload; override;
    function  GetAttribute(Index: Integer): string; overload; override;
    function  TryGetAttribute(const Name: string; out Value: string): Boolean; overload; override;
    function  TryGetAttribute(const LocalName, NamespaceURI: string; out Value: string): Boolean; overload; override;
    function  MoveToAttribute(const Name: string): Boolean; overload; override;
    function  MoveToAttribute(const LocalName, NamespaceURI: string): Boolean; overload; override;
    procedure MoveToAttribute(Index: Integer); overload; override;
    function  MoveToFirstAttribute: Boolean; override;
    function  MoveToNextAttribute: Boolean; override;
    function  MoveToElement: Boolean; override;
    function  ReadAttributeValue: Boolean; override;
    function  LookupNamespace(const Prefix: string): string; override;
    function  Expand: IXMLElement; override;
    procedure Close; override;
  end;

  /// <summary>Records as readers of their subtrees (IXmlReader.Elements).</summary>
  TXmlReaderElements = class(TDispatchInvokable, IXmlReaderEnumerable, IXmlReaderEnumerator)
  private
    FReader: TXmlReaderBase;
    FReaderRef: IXmlReader;
    FLocalName: string;
    FNamespaceURI: string;
    FAnyNamespace: Boolean;
    FCurrent: IXmlReader;
  public
    constructor Create(Reader: TXmlReaderBase; const LocalName, NamespaceURI: string; AnyNamespace: Boolean);
    function  GetEnumerator: IXmlReaderEnumerator;
    function  GetCurrent: IXmlReader;
    function  MoveNext: Boolean;
  end;

  /// <summary>Records as copies (IXmlReader.ReadElements).</summary>
  TXmlReaderNodes = class(TDispatchInvokable, IXmlElementEnumerable, IXmlElementEnumerator)
  private
    FReader: TXmlReaderBase;
    FReaderRef: IXmlReader;
    FLocalName: string;
    FNamespaceURI: string;
    FAnyNamespace: Boolean;
    FCurrent: IXMLElement;
  public
    constructor Create(Reader: TXmlReaderBase; const LocalName, NamespaceURI: string; AnyNamespace: Boolean);
    function  GetEnumerator: IXmlElementEnumerator;
    function  GetCurrent: IXMLElement;
    function  MoveNext: Boolean;
  end;

{ Base64 }

const
  Base64Invalid = -1;
  Base64Blank   = -2;
  Base64Pad     = -3;

var
  Base64Values: array[Byte] of ShortInt;

procedure InitBase64;
const
  Alphabet: RawByteString = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
begin
  for var B := Low(Byte) to High(Byte) do
    Base64Values[B] := Base64Invalid;
  for var I := 1 to Length(Alphabet) do
    Base64Values[Ord(Alphabet[I])] := I - 1;
  Base64Values[Ord(' ')] := Base64Blank;
  Base64Values[9] := Base64Blank;
  Base64Values[10] := Base64Blank;
  Base64Values[13] := Base64Blank;
  Base64Values[Ord('=')] := Base64Pad;
end;

type
  /// <summary>Decodes base64 handed over in pieces of any length into a stream. Whitespace
  /// anywhere is skipped, as xs:base64Binary allows; padding ends the data.</summary>
  TBase64Decoder = record
  private const
    BufferSize = 48 * 1024;
  private
    FStream: TStream;
    FBuffer: TBytes;
    FUsed: Integer;
    // The digits of the current quad, FCount of them, and the '=' that close it
    FQuad: Cardinal;
    FCount: Integer;
    FPadding: Integer;
    // A padded quad came: nothing but whitespace may follow
    FDone: Boolean;
    FWritten: Int64;
    procedure Emit(B: Byte); inline;
    procedure Flush;
  public
    procedure Start(Stream: TStream);
    function  Feed(P: PByte; Len: NativeInt): Boolean;
    function  Finish: Boolean;
    property  Written: Int64 read FWritten;
  end;

procedure TBase64Decoder.Start(Stream: TStream);
begin
  FStream := Stream;
  SetLength(FBuffer, BufferSize);
  FUsed := 0;
  FQuad := 0;
  FCount := 0;
  FPadding := 0;
  FDone := False;
  FWritten := 0;
end;

procedure TBase64Decoder.Emit(B: Byte);
begin
  if FUsed = BufferSize then
    Flush;
  FBuffer[FUsed] := B;
  Inc(FUsed);
end;

procedure TBase64Decoder.Flush;
begin
  if FUsed > 0 then
  begin
    FStream.WriteBuffer(FBuffer[0], FUsed);
    Inc(FWritten, FUsed);
    FUsed := 0;
  end;
end;

function TBase64Decoder.Feed(P: PByte; Len: NativeInt): Boolean;
begin
  while Len > 0 do
  begin
    var V := Base64Values[P^];
    Inc(P);
    Dec(Len);
    if V = Base64Blank then
      Continue;
    if (V = Base64Invalid) or FDone then
      Exit(False);
    if V = Base64Pad then
    begin
      // '=' closes a quad of which two or three digits came
      if FCount < 2 then
        Exit(False);
      Inc(FPadding);
      if FCount + FPadding = 4 then
      begin
        // Two digits hold one byte, three hold two, aligned to the top of the 24 bits
        FQuad := FQuad shl (6 * FPadding);
        Emit(Byte(FQuad shr 16));
        if FCount = 3 then
          Emit(Byte(FQuad shr 8));
        FDone := True;
      end;
      Continue;
    end;
    if FPadding > 0 then
      Exit(False);
    FQuad := (FQuad shl 6) or Cardinal(V);
    Inc(FCount);
    if FCount = 4 then
    begin
      Emit(Byte(FQuad shr 16));
      Emit(Byte(FQuad shr 8));
      Emit(Byte(FQuad));
      FQuad := 0;
      FCount := 0;
    end;
  end;
  Result := True;
end;

function TBase64Decoder.Finish: Boolean;
begin
  // The data ends on a whole quad: four digits, or a quad closed by padding
  Result := FDone or (FCount = 0);
  Flush;
end;

function EscapeAttribute(const Value: string): string;
begin
  Result := Value.Replace('&', '&amp;').Replace('<', '&lt;').Replace('"', '&quot;');
end;

{ TXmlReaderSettings }

class operator TXmlReaderSettings.Initialize(out Dest: TXmlReaderSettings);
begin
  Dest.Options := [xmlParseBigLines, xmlParseHuge];
  Dest.DtdProcessing := TXmlDtdProcessing.Prohibit;
  Dest.IgnoreWhitespace := False;
  Dest.IgnoreComments := False;
  Dest.IgnoreProcessingInstructions := False;
  Dest.MaxAmplification := 0;
  Dest.CloseInput := False;
end;

/// <summary>The parser options of a reader: the DTD options come from DtdProcessing alone.</summary>
function ParserOptions(const Settings: TXmlReaderSettings): TXmlParserOptions;
begin
  Result := Settings.Options - [xmlParseSubstituteEntity, xmlParseExternalDTD, xmlParseDTDAttrs, xmlParseDTDValidation];
  if Settings.DtdProcessing = TXmlDtdProcessing.Parse then
    Result := Result + [xmlParseSubstituteEntity, xmlParseDTDAttrs] + (Settings.Options * [xmlParseDTDValidation]);
end;

{ TNameCache }

function TNameCache.Get(P: xmlCharPtr): string;
begin
  if P = nil then
    Exit('');
  var I := Integer((NativeUInt(P) shr 4) xor (NativeUInt(P) shr 12)) and (Size - 1);
  for var Probe := 1 to Probes do
  begin
    if FKeys[I] = P then
      Exit(FValues[I]);
    if FKeys[I] = nil then
    begin
      FKeys[I] := P;
      FValues[I] := xmlCharToStr(P);
      Exit(FValues[I]);
    end;
    I := (I + 1) and (Size - 1);
  end;
  // The neighbourhood is taken: the name is not kept
  Result := xmlCharToStr(P);
end;

{ TXmlReaderBase }

procedure TXmlReaderBase.RaiseError(const Msg: string);
begin
  raise EXmlReaderError.Create(Msg, Get_LineNumber);
end;

procedure TXmlReaderBase.RequireElement;
begin
  if Get_NodeType <> TXmlNodeType.Element then
    RaiseError(Format(SReaderNotOnElement, [NodeTypeNames[Get_NodeType]]));
end;

procedure TXmlReaderBase.InvalidValue(const Value: RawByteString; const Element: string; Line: Integer; const TypeName: string);
begin
  raise EXmlReaderError.Create(Format(SReaderInvalidValue, [UTF8ToString(Value), Element, TypeName]), Line);
end;

function TXmlReaderBase.NameIs(const LocalName, NamespaceURI: string; AnyNamespace: Boolean): Boolean;
begin
  Result := (Get_LocalName = LocalName) and (AnyNamespace or (Get_NamespaceURI = NamespaceURI));
end;

procedure TXmlReaderBase.ValueBytes(out P: PByte; out Len: NativeInt; var Keep: RawByteString);
begin
  Keep := UTF8Encode(Get_Value);
  P := Pointer(Keep);
  Len := Length(Keep);
end;

function TXmlReaderBase.ReadElementContentUtf8: RawByteString;
begin
  Result := UTF8Encode(ReadElementContentAsString);
end;

procedure TXmlReaderBase.Skip;
begin
  if Get_ReadState <> TXmlReadState.Interactive then
    Exit;
  MoveToElement;
  if (Get_NodeType = TXmlNodeType.Element) and not Get_IsEmptyElement then
  begin
    var Level := Get_Depth;
    while Read and (Get_Depth > Level) do
      ;
    // On the end tag of the element
    if (Get_NodeType = TXmlNodeType.EndElement) and (Get_Depth = Level) then
      Read;
  end
  else
    Read;
end;

function TXmlReaderBase.MoveToContent: TXmlNodeType;
begin
  repeat
    Result := Get_NodeType;
    case Result of
      TXmlNodeType.Attribute:
        begin
          MoveToElement;
          Exit(TXmlNodeType.Element);
        end;
      TXmlNodeType.Element, TXmlNodeType.EndElement, TXmlNodeType.Text, TXmlNodeType.CDATA,
      TXmlNodeType.EntityReference, TXmlNodeType.EndEntity:
        Exit;
    end;
  until not Read;
  Result := Get_NodeType;
end;

function TXmlReaderBase.FollowingNamed(const LocalName, NamespaceURI: string; AnyNamespace: Boolean): Boolean;
begin
  while Read do
    if (Get_NodeType = TXmlNodeType.Element) and NameIs(LocalName, NamespaceURI, AnyNamespace) then
      Exit(True);
  Result := False;
end;

function TXmlReaderBase.DescendantNamed(const LocalName, NamespaceURI: string; AnyNamespace: Boolean): Boolean;
begin
  var Level := Get_Depth;
  case Get_NodeType of
    TXmlNodeType.Element:
      if Get_IsEmptyElement then
        Exit(False);
    TXmlNodeType.None:
      // Not started yet: the whole document is the scope
      if Get_ReadState = TXmlReadState.Initial then
        Level := -1
      else
        Exit(False);
  else
    Exit(False);
  end;
  while Read and (Get_Depth > Level) do
    if (Get_NodeType = TXmlNodeType.Element) and NameIs(LocalName, NamespaceURI, AnyNamespace) then
      Exit(True);
  Result := False;
end;

function TXmlReaderBase.SiblingNamed(const LocalName, NamespaceURI: string; AnyNamespace: Boolean): Boolean;
var
  T: TXmlNodeType;
begin
  repeat
    Skip;
    if Get_ReadState <> TXmlReadState.Interactive then
      Exit(False);
    T := Get_NodeType;
    if (T = TXmlNodeType.Element) and NameIs(LocalName, NamespaceURI, AnyNamespace) then
      Exit(True);
  until T = TXmlNodeType.EndElement;
  Result := False;
end;

function TXmlReaderBase.StartElementNamed(const LocalName, NamespaceURI: string; AnyNamespace: Boolean): Boolean;
begin
  Result := (MoveToContent = TXmlNodeType.Element) and NameIs(LocalName, NamespaceURI, AnyNamespace);
end;

procedure TXmlReaderBase.RequireStartElement(const LocalName, NamespaceURI: string; AnyNamespace: Boolean);
begin
  if MoveToContent <> TXmlNodeType.Element then
    RaiseError(Format(SReaderNotOnElement, [NodeTypeNames[Get_NodeType]]));
  if not NameIs(LocalName, NamespaceURI, AnyNamespace) then
    RaiseError(Format(SReaderElementNotFound, [XmlQualifiedName.ToString(LocalName, NamespaceURI), Get_Name]));
end;

function TXmlReaderBase.ReadToFollowing(const LocalName: string): Boolean;
begin
  Result := FollowingNamed(LocalName, '', True);
end;

function TXmlReaderBase.ReadToFollowing(const LocalName, NamespaceURI: string): Boolean;
begin
  Result := FollowingNamed(LocalName, NamespaceURI, False);
end;

function TXmlReaderBase.ReadToDescendant(const LocalName: string): Boolean;
begin
  Result := DescendantNamed(LocalName, '', True);
end;

function TXmlReaderBase.ReadToDescendant(const LocalName, NamespaceURI: string): Boolean;
begin
  Result := DescendantNamed(LocalName, NamespaceURI, False);
end;

function TXmlReaderBase.ReadToNextSibling(const LocalName: string): Boolean;
begin
  Result := SiblingNamed(LocalName, '', True);
end;

function TXmlReaderBase.ReadToNextSibling(const LocalName, NamespaceURI: string): Boolean;
begin
  Result := SiblingNamed(LocalName, NamespaceURI, False);
end;

function TXmlReaderBase.ReadSubtree: IXmlReader;
begin
  RequireElement;
  Result := TXmlSubtreeReader.Create(Self);
end;

function TXmlReaderBase.Elements(const LocalName: string): IXmlReaderEnumerable;
begin
  Result := TXmlReaderElements.Create(Self, LocalName, '', True);
end;

function TXmlReaderBase.Elements(const LocalName, NamespaceURI: string): IXmlReaderEnumerable;
begin
  Result := TXmlReaderElements.Create(Self, LocalName, NamespaceURI, False);
end;

function TXmlReaderBase.ReadElements(const LocalName: string): IXmlElementEnumerable;
begin
  Result := TXmlReaderNodes.Create(Self, LocalName, '', True);
end;

function TXmlReaderBase.ReadElements(const LocalName, NamespaceURI: string): IXmlElementEnumerable;
begin
  Result := TXmlReaderNodes.Create(Self, LocalName, NamespaceURI, False);
end;

function TXmlReaderBase.IsStartElement: Boolean;
begin
  Result := MoveToContent = TXmlNodeType.Element;
end;

function TXmlReaderBase.IsStartElement(const LocalName: string): Boolean;
begin
  Result := StartElementNamed(LocalName, '', True);
end;

function TXmlReaderBase.IsStartElement(const LocalName, NamespaceURI: string): Boolean;
begin
  Result := StartElementNamed(LocalName, NamespaceURI, False);
end;

procedure TXmlReaderBase.ReadStartElement;
begin
  if MoveToContent <> TXmlNodeType.Element then
    RaiseError(Format(SReaderNotOnElement, [NodeTypeNames[Get_NodeType]]));
  Read;
end;

procedure TXmlReaderBase.ReadStartElement(const LocalName: string);
begin
  RequireStartElement(LocalName, '', True);
  Read;
end;

procedure TXmlReaderBase.ReadStartElement(const LocalName, NamespaceURI: string);
begin
  RequireStartElement(LocalName, NamespaceURI, False);
  Read;
end;

procedure TXmlReaderBase.ReadEndElement;
begin
  if MoveToContent <> TXmlNodeType.EndElement then
    RaiseError(Format(SReaderEndTagExpected, [NodeTypeNames[Get_NodeType]]));
  Read;
end;

function TXmlReaderBase.ReadContentAsString: string;
begin
  case Get_NodeType of
    TXmlNodeType.Element:
      RaiseError(Format(SReaderContentOnElement, [Get_Name]));
    TXmlNodeType.Attribute:
      Exit(Get_Value);
  end;
  Result := '';
  repeat
    case Get_NodeType of
      TXmlNodeType.Text, TXmlNodeType.CDATA, TXmlNodeType.Whitespace, TXmlNodeType.SignificantWhitespace:
        Result := Result + Get_Value;
      TXmlNodeType.Comment, TXmlNodeType.ProcessingInstruction, TXmlNodeType.EntityReference,
      TXmlNodeType.EndEntity:
        ;
    else
      Exit;
    end;
  until not Read;
end;

function TXmlReaderBase.ReadElementContentAsString: string;
begin
  RequireElement;
  if Get_IsEmptyElement then
  begin
    Read;
    Exit('');
  end;
  var Element := Get_Name;
  Read;
  if Get_NodeType = TXmlNodeType.Element then
    RaiseError(Format(SReaderMixedContent, [Element]));
  Result := ReadContentAsString;
  case Get_NodeType of
    TXmlNodeType.EndElement:
      Read;
    TXmlNodeType.Element:
      RaiseError(Format(SReaderMixedContent, [Element]));
  else
    RaiseError(Format(SReaderEndTagExpected, [NodeTypeNames[Get_NodeType]]));
  end;
end;

function TXmlReaderBase.ReadElementContentAsString(const LocalName, NamespaceURI: string): string;
begin
  RequireElement;
  if not NameIs(LocalName, NamespaceURI, False) then
    RaiseError(Format(SReaderElementNotFound, [XmlQualifiedName.ToString(LocalName, NamespaceURI), Get_Name]));
  Result := ReadElementContentAsString;
end;

function TXmlReaderBase.ReadElementContentAsInteger: Integer;
begin
  RequireElement;
  var Element := Get_Name;
  var Line := Get_LineNumber;
  var S := ReadElementContentUtf8;
  if not XmlConvert.TryToInteger(Pointer(S), Length(S), Result) then
    InvalidValue(S, Element, Line, 'xs:int');
end;

function TXmlReaderBase.ReadElementContentAsInt64: Int64;
begin
  RequireElement;
  var Element := Get_Name;
  var Line := Get_LineNumber;
  var S := ReadElementContentUtf8;
  if not XmlConvert.TryToInt64(Pointer(S), Length(S), Result) then
    InvalidValue(S, Element, Line, 'xs:long');
end;

function TXmlReaderBase.ReadElementContentAsDouble: Double;
begin
  RequireElement;
  var Element := Get_Name;
  var Line := Get_LineNumber;
  var S := ReadElementContentUtf8;
  if not XmlConvert.TryToDouble(Pointer(S), Length(S), Result) then
    InvalidValue(S, Element, Line, 'xs:double');
end;

function TXmlReaderBase.ReadElementContentAsCurrency: Currency;
begin
  RequireElement;
  var Element := Get_Name;
  var Line := Get_LineNumber;
  var S := ReadElementContentUtf8;
  if not XmlConvert.TryToCurrency(Pointer(S), Length(S), Result) then
    InvalidValue(S, Element, Line, 'xs:decimal');
end;

function TXmlReaderBase.ReadElementContentAsBoolean: Boolean;
begin
  RequireElement;
  var Element := Get_Name;
  var Line := Get_LineNumber;
  var S := ReadElementContentUtf8;
  if not XmlConvert.TryToBoolean(Pointer(S), Length(S), Result) then
    InvalidValue(S, Element, Line, 'xs:boolean');
end;

function TXmlReaderBase.ReadElementContentAsDateTime: TDateTime;
var
  Offset: Integer;
  HasOffset: Boolean;
begin
  RequireElement;
  var Element := Get_Name;
  var Line := Get_LineNumber;
  var S := ReadElementContentUtf8;
  if not XmlConvert.TryToDateTime(Pointer(S), Length(S), Result, Offset, HasOffset) then
    InvalidValue(S, Element, Line, 'xs:dateTime');
end;

function TXmlReaderBase.ReadElementContentAsBase64(Stream: TStream): Int64;
var
  Decoder: TBase64Decoder;
  P: PByte;
  Len: NativeInt;
  Keep: RawByteString;
begin
  RequireElement;
  if Get_IsEmptyElement then
  begin
    Read;
    Exit(0);
  end;
  var Element := Get_Name;
  var Line := Get_LineNumber;
  Decoder.Start(Stream);
  Read;
  repeat
    case Get_NodeType of
      TXmlNodeType.Text, TXmlNodeType.CDATA, TXmlNodeType.Whitespace, TXmlNodeType.SignificantWhitespace:
        begin
          ValueBytes(P, Len, Keep);
          if not Decoder.Feed(P, Len) then
            raise EXmlReaderError.Create(Format(SReaderInvalidBase64, [Element]), Line);
        end;
      TXmlNodeType.Comment, TXmlNodeType.ProcessingInstruction, TXmlNodeType.EntityReference,
      TXmlNodeType.EndEntity:
        ;
      TXmlNodeType.EndElement:
        Break;
      TXmlNodeType.Element:
        RaiseError(Format(SReaderMixedContent, [Element]));
    else
      RaiseError(Format(SReaderEndTagExpected, [NodeTypeNames[Get_NodeType]]));
    end;
  until not Read;
  if not Decoder.Finish then
    raise EXmlReaderError.Create(Format(SReaderInvalidBase64, [Element]), Line);
  Result := Decoder.Written;
  Read;
end;

function TXmlReaderBase.ReadInnerXml: string;
begin
  case Get_NodeType of
    TXmlNodeType.Element:
      begin
        Result := CurrentInnerXml;
        Skip;
      end;
    TXmlNodeType.Attribute:
      Result := Get_Value;
  else
    Read;
    Result := '';
  end;
end;

function TXmlReaderBase.ReadOuterXml: string;
begin
  case Get_NodeType of
    TXmlNodeType.Element:
      begin
        Result := CurrentOuterXml;
        Skip;
      end;
    TXmlNodeType.Attribute:
      Result := Get_Name + '="' + EscapeAttribute(Get_Value) + '"';
  else
    Read;
    Result := '';
  end;
end;

function TXmlReaderBase.ReadElement: IXMLElement;
begin
  RequireElement;
  var Doc := xmlDoc.Create;
  try
    xmlDocSetRootElement(Doc, CopyElement(Doc));
  except
    Doc.Free;
    raise;
  end;
  var Owner: IXMLDocument := TXMLDocument.Create(Doc, True);
  Result := Owner.DocumentElement;
  Skip;
end;

function TXmlReaderBase.ReadElement(const Doc: IXMLDocument): IXMLElement;
begin
  if Doc = nil then
    raise EArgumentNilException.Create('Doc');
  RequireElement;
  var Native := xmlDocPtr(TXMLNodeAccess(TObject(Doc)).NodePtr);
  Result := NodeWrapper(CopyElement(Native)) as IXMLElement;
  Skip;
end;

{ TXmlTextReader }

constructor TXmlTextReader.Create(const Settings: TXmlReaderSettings);
begin
  inherited Create;
  FSettings := Settings;
  FState := TXmlReadState.Initial;
  FErrors := TXMLErrors.Create;
  FErrorsRef := FErrors;
  FAttributeIndex := -1;
end;

destructor TXmlTextReader.Destroy;
begin
  Close;
  inherited;
end;

procedure TXmlTextReader.Attach(Reader: xmlTextReaderPtr);
begin
  FReader := Reader;
  FWalker := Reader.IsWalker;
  if FWalker then
  begin
    if FSettings.Schemas <> nil then
      raise EXmlReaderError.Create(SReaderWalkerSchema, 0);
    Exit;
  end;
  if FSettings.MaxAmplification > 0 then
    xmlTextReaderSetMaxAmplification(Reader, FSettings.MaxAmplification);
  if FSettings.Schemas <> nil then
  begin
    var Collection := TObject(FSettings.Schemas) as TXMLSchemaCollection;
    var Schema := Collection.CompiledSchema;
    if Schema = nil then
    begin
      var Reason := '';
      if Collection.Errors.Count > 0 then
        Reason := Collection.Errors[0].Reason;
      raise EXmlReaderError.Create(Format(SReaderSchemaFailed, [Reason]), 0);
    end;
    Reader.SetSchema(Schema);
  end;
end;

function TXmlTextReader.Live: Boolean;
begin
  Result := FState = TXmlReadState.Interactive;
end;

procedure TXmlTextReader.HandleError(const error: xmlError);
begin
  // A fatal error comes out of Read as EXmlParserError
  if error.level = XML_ERR_FATAL then
    Exit;
  var E := TXmlParseError.Create(error);
  FErrors.Add(E);
  if (error.domain = Ord(XML_FROM_SCHEMASV)) or (error.domain = Ord(XML_FROM_VALID)) then
  begin
    if error.level <> XML_ERR_WARNING then
      Inc(FValidationErrors);
    if Assigned(FSettings.OnValidationError) then
      FSettings.OnValidationError(E)
    else if error.level <> XML_ERR_WARNING then
      // Raised from inside libxml2: the reader keeps it and Read raises it
      raise EXmlParserError.Create(E);
  end;
end;

procedure TXmlTextReader.Moved;
begin
  FTypeValid := False;
  FValueValid := False;
end;

function TXmlTextReader.Step(Next: Boolean): Boolean;
begin
  Moved;
  FOnAttribute := False;
  FAttributeIndex := -1;
  try
    if Next then
      Result := FReader.Skip
    else
      Result := FReader.Read;
  except
    // A validation error or an exception of a handler leaves the reader usable
    if FReader.Failed then
      FState := TXmlReadState.Error
    else
      FState := TXmlReadState.Interactive;
    raise;
  end;
  if Result then
  begin
    FState := TXmlReadState.Interactive;
    if not FPastProlog then
      CheckProlog;
  end
  else
    FState := TXmlReadState.EndOfFile;
end;

procedure TXmlTextReader.CheckProlog;
begin
  case FReader.NodeType of
    XML_READER_TYPE_ELEMENT:
      FPastProlog := True;
    XML_READER_TYPE_DOCUMENT_TYPE:
      // A loaded document is past the decision: a walker reports its DOCTYPE
      if (FSettings.DtdProcessing = TXmlDtdProcessing.Prohibit) and not FWalker then
      begin
        FState := TXmlReadState.Error;
        raise EXmlReaderError.Create(SReaderDtdProhibited, 0);
      end;
  end;
end;

function TXmlTextReader.PreservesSpace: Boolean;
begin
  var Node := FReader.CurrentNode;
  Result := (Node <> nil) and (Node.parent <> nil) and (xmlNodeGetSpacePreserve(Node.parent) = 1);
end;

function TXmlTextReader.Filtered: Boolean;
begin
  case Get_NodeType of
    TXmlNodeType.Whitespace:
      Result := FSettings.IgnoreWhitespace;
    TXmlNodeType.Comment:
      Result := FSettings.IgnoreComments;
    TXmlNodeType.ProcessingInstruction:
      Result := FSettings.IgnoreProcessingInstructions;
    TXmlNodeType.DocumentType:
      Result := FSettings.DtdProcessing = TXmlDtdProcessing.Ignore;
  else
    Result := False;
  end;
end;

function TXmlTextReader.AtomOf(const Name: string): xmlCharPtr;
begin
  // The cache holds a reference to each string it keeps, so the same pointer is the same text
  for var I := Low(FAtoms) to High(FAtoms) do
    if Pointer(FAtoms[I].Text) = Pointer(Name) then
      Exit(FAtoms[I].Atom);
  Result := NewAtom(Name);
end;

function TXmlTextReader.NewAtom(const Name: string): xmlCharPtr;
begin
  if Name = '' then
    Exit(nil);
  Result := FReader.Atom(UTF8Encode(Name));
  FAtoms[FNextAtom].Text := Name;
  FAtoms[FNextAtom].Atom := Result;
  FNextAtom := (FNextAtom + 1) mod Length(FAtoms);
end;

function TXmlTextReader.NameIs(const LocalName, NamespaceURI: string; AnyNamespace: Boolean): Boolean;
begin
  if not Live then
    Exit(False);
  // Equal names are one pointer in the dictionary of a streaming reader; a walker's names
  // live in its document, where the text decides
  Result := xmlStrSame(FReader.LocalNamePtr, AtomOf(LocalName)) and
    (AnyNamespace or xmlStrSame(FReader.NamespaceURIPtr, AtomOf(NamespaceURI)));
end;

function TXmlTextReader.FollowingNamed(const LocalName, NamespaceURI: string; AnyNamespace: Boolean): Boolean;
begin
  if FState in [TXmlReadState.EndOfFile, TXmlReadState.Error, TXmlReadState.Closed] then
    Exit(False);
  var Local := AtomOf(LocalName);
  var Ns := AtomOf(NamespaceURI);
  // Elements are never filtered: the nodes passed over need no filtering either
  while Step(False) do
    if AnyNamespace then
    begin
      if FReader.IsElement(Local) then
        Exit(True);
    end
    else if FReader.IsElement(Local, Ns) then
      Exit(True);
  Result := False;
end;

function TXmlTextReader.Read: Boolean;
begin
  if FState in [TXmlReadState.EndOfFile, TXmlReadState.Error, TXmlReadState.Closed] then
    Exit(False);
  Result := Step(False);
  while Result and Filtered do
    Result := Step(False);
end;

procedure TXmlTextReader.Skip;
var
  Moved: Boolean;
  Depth: Integer;
begin
  if not Live then
    Exit;
  if FWalker then
  begin
    // Over a loaded document xmlTextReaderNext takes the xmlTextReaderNextTree path, which on
    // the last child of an element goes straight to the element's next sibling and leaves its
    // end tag out. The streaming reader reports that end tag, and so does this one: the subtree
    // is read to its end tag, then the reader steps once past it, as .NET Skip does
    if FOnAttribute then
      FReader.MoveToElement;
    Moved := True;
    if (FReader.NodeType = XML_READER_TYPE_ELEMENT) and not FReader.IsEmptyElement then
    begin
      Depth := FReader.Depth;
      repeat
        Moved := Step(False);
      until not Moved or ((FReader.NodeType = XML_READER_TYPE_END_ELEMENT) and (FReader.Depth = Depth));
    end;
    if Moved then
      Moved := Step(False);
  end
  else
    Moved := Step(True);
  while Moved and Filtered do
    Moved := Step(False);
end;

function TXmlTextReader.Get_NodeType: TXmlNodeType;
begin
  if not FTypeValid then
  begin
    FTypeValid := True;
    if not Live then
      FNodeType := TXmlNodeType.None
    else
    begin
      var T := FReader.NodeType;
      // libxml2 calls all whitespace-only text significant; it is significant under
      // xml:space="preserve" only, as in .NET
      if (T = XML_READER_TYPE_SIGNIFICANT_WHITESPACE) and not PreservesSpace then
        T := XML_READER_TYPE_WHITESPACE;
      FNodeType := TXmlNodeType(Ord(T));
    end;
  end;
  Result := FNodeType;
end;

function TXmlTextReader.Get_Value: string;
begin
  if not Live then
    Exit('');
  if not FValueValid then
  begin
    FValue := xmlCharToStr(FReader.ValuePtr);
    FValueValid := True;
  end;
  Result := FValue;
end;

procedure TXmlTextReader.ValueBytes(out P: PByte; out Len: NativeInt; var Keep: RawByteString);
begin
  if not Live then
  begin
    P := nil;
    Len := 0;
    Exit;
  end;
  P := PByte(FReader.ValuePtr);
  Len := xmlStrLen(xmlCharPtr(P));
end;

function TXmlTextReader.Get_Name: string;
begin
  if not Live then
    Exit('');
  Result := FNames.Get(FReader.NamePtr);
end;

function TXmlTextReader.Get_LocalName: string;
begin
  if not Live then
    Exit('');
  // The local name of an xmlns:p declaration is its prefix in the declaration itself, which
  // is not in the dictionary: it is not cached
  if FReader.IsNamespaceDecl then
    Result := xmlCharToStr(FReader.LocalNamePtr)
  else
    Result := FNames.Get(FReader.LocalNamePtr);
end;

function TXmlTextReader.Get_NamespaceURI: string;
begin
  if not Live then
    Exit('');
  Result := FNames.Get(FReader.NamespaceURIPtr);
end;

function TXmlTextReader.Get_Prefix: string;
begin
  if not Live then
    Exit('');
  Result := FNames.Get(FReader.PrefixPtr);
end;

function TXmlTextReader.Get_Depth: Integer;
begin
  if not Live then
    Exit(0);
  Result := FReader.Depth;
end;

function TXmlTextReader.Get_EOF: Boolean;
begin
  Result := FState = TXmlReadState.EndOfFile;
end;

function TXmlTextReader.Get_Errors: IXMLErrors;
begin
  Result := FErrorsRef;
end;

function TXmlTextReader.Get_HasAttributes: Boolean;
begin
  Result := Live and FReader.HasAttributes;
end;

function TXmlTextReader.Get_HasValue: Boolean;
begin
  Result := Live and FReader.HasValue;
end;

function TXmlTextReader.Get_IsEmptyElement: Boolean;
begin
  Result := Live and FReader.IsEmptyElement;
end;

function TXmlTextReader.Get_IsNamespaceDeclaration: Boolean;
begin
  Result := Live and FReader.IsNamespaceDecl;
end;

function TXmlTextReader.Get_IsValid: Boolean;
begin
  Result := FValidationErrors = 0;
end;

function TXmlTextReader.Get_LineNumber: Integer;
begin
  if not Live then
    Exit(0);
  Result := FReader.LineNumber;
end;

function TXmlTextReader.Get_BaseURI: string;
begin
  if not Live then
    Exit('');
  Result := xmlCharToStr(xmlTextReaderConstBaseUri(FReader));
end;

function TXmlTextReader.Get_XmlLang: string;
begin
  if not Live then
    Exit('');
  Result := xmlCharToStr(xmlTextReaderConstXmlLang(FReader));
end;

function TXmlTextReader.Get_ReadState: TXmlReadState;
begin
  Result := FState;
end;

function TXmlTextReader.AttributeIndex: Integer;
begin
  if FAttributeIndex >= 0 then
    Exit(FAttributeIndex);
  var Current := FReader.CurrentNode;
  FReader.MoveToElement;
  Result := 0;
  if FReader.MoveToFirstAttribute then
    repeat
      if FReader.CurrentNode = Current then
        Break;
      Inc(Result);
    until not FReader.MoveToNextAttribute;
  FAttributeIndex := Result;
end;

procedure TXmlTextReader.ReturnToAttribute(Index: Integer);
begin
  xmlTextReaderMoveToAttributeNo(FReader, Index);
  FAttributeIndex := Index;
  Moved;
end;

function TXmlTextReader.Get_AttributeCount: Integer;
begin
  if not Live then
    Exit(0);
  if not FOnAttribute then
    Exit(FReader.AttributeCount);
  // libxml2 counts nothing while on an attribute; .NET counts the attributes of the element
  var Index := AttributeIndex;
  FReader.MoveToElement;
  Result := FReader.AttributeCount;
  ReturnToAttribute(Index);
end;

function TXmlTextReader.GetAttribute(const Name: string): string;
begin
  TryGetAttribute(Name, Result);
end;

function TXmlTextReader.GetAttribute(const LocalName, NamespaceURI: string): string;
begin
  TryGetAttribute(LocalName, NamespaceURI, Result);
end;

// The names go to libxml2 through a buffer on the stack and the value comes back as a string
// at once: no UTF-8 strings in between
function TXmlTextReader.TryGetAttribute(const Name: string; out Value: string): Boolean;
var
  Args: TXmlArgs;
  P: xmlCharPtr;
begin
  Value := '';
  if not Live then
    Exit(False);
  if FOnAttribute then
  begin
    var Index := AttributeIndex;
    FReader.MoveToElement;
    P := xmlTextReaderGetAttribute(FReader, Args.StrPtr(Name));
    ReturnToAttribute(Index);
  end
  else
    P := xmlTextReaderGetAttribute(FReader, Args.StrPtr(Name));
  Result := P <> nil;
  Value := xmlCharToStrAndFree(P);
end;

function TXmlTextReader.TryGetAttribute(const LocalName, NamespaceURI: string; out Value: string): Boolean;
var
  Args: TXmlArgs;
  P: xmlCharPtr;
begin
  Value := '';
  if not Live then
    Exit(False);
  if FOnAttribute then
  begin
    var Index := AttributeIndex;
    FReader.MoveToElement;
    P := xmlTextReaderGetAttributeNs(FReader, Args.StrPtr(LocalName), Args.StrPtr(NamespaceURI));
    ReturnToAttribute(Index);
  end
  else
    P := xmlTextReaderGetAttributeNs(FReader, Args.StrPtr(LocalName), Args.StrPtr(NamespaceURI));
  Result := P <> nil;
  Value := xmlCharToStrAndFree(P);
end;

function TXmlTextReader.GetAttribute(Index: Integer): string;
begin
  var Count := Get_AttributeCount;
  if (Index < 0) or (Index >= Count) then
    raise EArgumentOutOfRangeException.CreateResFmt(@SReaderAttributeIndex, [Index, Count]);
  if FOnAttribute then
  begin
    var Current := AttributeIndex;
    FReader.MoveToElement;
    Result := xmlCharToStrAndFree(xmlTextReaderGetAttributeNo(FReader, Index));
    ReturnToAttribute(Current);
  end
  else
    Result := xmlCharToStrAndFree(xmlTextReaderGetAttributeNo(FReader, Index));
end;

function TXmlTextReader.MoveToAttribute(const Name: string): Boolean;
begin
  if not Live then
    Exit(False);
  Result := FReader.MoveToAttribute(UTF8Encode(Name));
  if Result then
  begin
    Moved;
    FOnAttribute := True;
    FAttributeIndex := -1;
  end;
end;

function TXmlTextReader.MoveToAttribute(const LocalName, NamespaceURI: string): Boolean;
begin
  if not Live then
    Exit(False);
  Result := FReader.MoveToAttribute(UTF8Encode(LocalName), UTF8Encode(NamespaceURI));
  if Result then
  begin
    Moved;
    FOnAttribute := True;
    FAttributeIndex := -1;
  end;
end;

procedure TXmlTextReader.MoveToAttribute(Index: Integer);
begin
  var Count := Get_AttributeCount;
  if (Index < 0) or (Index >= Count) then
    raise EArgumentOutOfRangeException.CreateResFmt(@SReaderAttributeIndex, [Index, Count]);
  xmlTextReaderMoveToAttributeNo(FReader, Index);
  Moved;
  FOnAttribute := True;
  FAttributeIndex := Index;
end;

function TXmlTextReader.MoveToFirstAttribute: Boolean;
begin
  if not Live then
    Exit(False);
  Result := FReader.MoveToFirstAttribute;
  if Result then
  begin
    Moved;
    FOnAttribute := True;
    FAttributeIndex := 0;
  end;
end;

function TXmlTextReader.MoveToNextAttribute: Boolean;
begin
  if not Live then
    Exit(False);
  if not FOnAttribute then
    Exit(MoveToFirstAttribute);
  var Index := AttributeIndex;
  Result := FReader.MoveToNextAttribute;
  if Result then
  begin
    Moved;
    FAttributeIndex := Index + 1;
  end;
end;

function TXmlTextReader.MoveToElement: Boolean;
begin
  if not (Live and FOnAttribute) then
    Exit(False);
  Result := FReader.MoveToElement;
  Moved;
  FOnAttribute := False;
  FAttributeIndex := -1;
end;

function TXmlTextReader.ReadAttributeValue: Boolean;
begin
  if not (Live and FOnAttribute) then
    Exit(False);
  Result := FReader.ReadAttributeValue;
  if Result then
    Moved;
end;

function TXmlTextReader.LookupNamespace(const Prefix: string): string;
begin
  if not Live then
    Exit('');
  Result := UTF8ToString(FReader.LookupNamespace(UTF8Encode(Prefix)));
end;

function TXmlTextReader.Expand: IXMLElement;
begin
  RequireElement;
  // The subtree is parsed to its end here; a malformed rest of it is the error of this call
  var Node := FReader.Expand;
  if Node = nil then
  begin
    if FReader.Failed then
      FState := TXmlReadState.Error;
    var E := FReader.LastError;
    if (E <> nil) and (E.code <> 0) then
      raise EXmlParserError.Create(E^);
    raise EXmlReaderError.Create(Format(SReaderNotOnElement, [NodeTypeNames[Get_NodeType]]), Get_LineNumber);
  end;
  Result := NodeWrapper(Node) as IXMLElement;
end;

procedure TXmlTextReader.Close;
begin
  if FState = TXmlReadState.Closed then
    Exit;
  FState := TXmlReadState.Closed;
  Moved;
  FReader.Free;
  FReader := nil;
  if FOwnsStream then
    FreeAndNil(FStream);
  FDocument := nil;
end;

function TXmlTextReader.CurrentOuterXml: string;
begin
  Result := UTF8ToString(FReader.OuterXml);
end;

function TXmlTextReader.CurrentInnerXml: string;
begin
  Result := UTF8ToString(FReader.InnerXml);
end;

function TXmlTextReader.CopyElement(const Doc: xmlDocPtr): xmlNodePtr;
begin
  if FOnAttribute then
    MoveToElement;
  try
    Result := FReader.CopyNode(Doc);
  except
    if FReader.Failed then
      FState := TXmlReadState.Error;
    raise;
  end;
end;

function TXmlTextReader.ReadElementContentUtf8: RawByteString;
begin
  RequireElement;
  if FReader.IsEmptyElement then
  begin
    Read;
    Exit('');
  end;
  // The name lives in the dictionary of the reader, the moves below leave it alone
  var Element := FReader.NamePtr;
  Result := '';
  // Text in place, without a string per node: the nodes filtered out by the settings are
  // comments, processing instructions and whitespace, and the content takes them as they are
  while Step(False) do
    case FReader.NodeType of
      XML_READER_TYPE_TEXT, XML_READER_TYPE_CDATA, XML_READER_TYPE_WHITESPACE, XML_READER_TYPE_SIGNIFICANT_WHITESPACE:
        if Result = '' then
          Result := FReader.Value
        else
          Result := Result + FReader.Value;
      XML_READER_TYPE_COMMENT, XML_READER_TYPE_PROCESSING_INSTRUCTION, XML_READER_TYPE_ENTITY_REFERENCE,
      XML_READER_TYPE_END_ENTITY:
        ;
      XML_READER_TYPE_END_ELEMENT:
        begin
          Read;
          Exit;
        end;
      XML_READER_TYPE_ELEMENT:
        RaiseError(Format(SReaderMixedContent, [xmlCharToStr(Element)]));
    else
      Break;
    end;
  RaiseError(Format(SReaderEndTagExpected, [NodeTypeNames[Get_NodeType]]));
end;

function TXmlTextReader.ReadElementContentAsString: string;
begin
  Result := UTF8ToString(ReadElementContentUtf8);
end;

{ TXmlSubtreeReader }

constructor TXmlSubtreeReader.Create(Outer: TXmlReaderBase);
begin
  inherited Create;
  FOuter := Outer;
  FOuterRef := Outer;
  FInitialDepth := Outer.Get_Depth;
  FState := TXmlReadState.Initial;
end;

destructor TXmlSubtreeReader.Destroy;
begin
  Close;
  inherited;
end;

function TXmlSubtreeReader.Live: Boolean;
begin
  Result := FState = TXmlReadState.Interactive;
end;

function TXmlSubtreeReader.Read: Boolean;
begin
  case FState of
    TXmlReadState.Initial:
      begin
        // The outer reader is on the element already
        FState := TXmlReadState.Interactive;
        Exit(True);
      end;
    TXmlReadState.Interactive:
      ;
  else
    Exit(False);
  end;
  FOuter.MoveToElement;
  // The element itself when it is empty, or its end tag: the subtree is over
  if (FOuter.Get_Depth = FInitialDepth) and
    ((FOuter.Get_NodeType = TXmlNodeType.EndElement) or
     ((FOuter.Get_NodeType = TXmlNodeType.Element) and FOuter.Get_IsEmptyElement)) then
  begin
    FState := TXmlReadState.EndOfFile;
    Exit(False);
  end;
  try
    Result := FOuter.Read;
  except
    if FOuter.Get_ReadState = TXmlReadState.Error then
      FState := TXmlReadState.Error;
    raise;
  end;
  if not Result or (FOuter.Get_Depth < FInitialDepth) then
  begin
    FState := TXmlReadState.EndOfFile;
    Result := False;
  end;
end;

procedure TXmlSubtreeReader.Close;
begin
  if FState in [TXmlReadState.Closed] then
    Exit;
  if FState in [TXmlReadState.Initial, TXmlReadState.Interactive] then
  begin
    // To the end tag of the element, or stay on it when it is empty; never past it
    FOuter.MoveToElement;
    if (FOuter.Get_Depth = FInitialDepth) and (FOuter.Get_NodeType = TXmlNodeType.Element) and
      not FOuter.Get_IsEmptyElement then
      FOuter.Read;
    while (FOuter.Get_Depth > FInitialDepth) and FOuter.Read do
      ;
  end;
  FState := TXmlReadState.Closed;
end;

function TXmlSubtreeReader.NameIs(const LocalName, NamespaceURI: string; AnyNamespace: Boolean): Boolean;
begin
  Result := Live and FOuter.NameIs(LocalName, NamespaceURI, AnyNamespace);
end;

function TXmlSubtreeReader.CurrentOuterXml: string;
begin
  Result := FOuter.CurrentOuterXml;
end;

function TXmlSubtreeReader.CurrentInnerXml: string;
begin
  Result := FOuter.CurrentInnerXml;
end;

function TXmlSubtreeReader.CopyElement(const Doc: xmlDocPtr): xmlNodePtr;
begin
  Result := FOuter.CopyElement(Doc);
end;

procedure TXmlSubtreeReader.ValueBytes(out P: PByte; out Len: NativeInt; var Keep: RawByteString);
begin
  FOuter.ValueBytes(P, Len, Keep);
end;

function TXmlSubtreeReader.Get_AttributeCount: Integer;
begin
  if Live then Result := FOuter.Get_AttributeCount else Result := 0;
end;

function TXmlSubtreeReader.Get_BaseURI: string;
begin
  if Live then Result := FOuter.Get_BaseURI else Result := '';
end;

function TXmlSubtreeReader.Get_Depth: Integer;
begin
  if Live then Result := FOuter.Get_Depth - FInitialDepth else Result := 0;
end;

function TXmlSubtreeReader.Get_EOF: Boolean;
begin
  Result := FState = TXmlReadState.EndOfFile;
end;

function TXmlSubtreeReader.Get_Errors: IXMLErrors;
begin
  Result := FOuter.Get_Errors;
end;

function TXmlSubtreeReader.Get_HasAttributes: Boolean;
begin
  Result := Live and FOuter.Get_HasAttributes;
end;

function TXmlSubtreeReader.Get_HasValue: Boolean;
begin
  Result := Live and FOuter.Get_HasValue;
end;

function TXmlSubtreeReader.Get_IsEmptyElement: Boolean;
begin
  Result := Live and FOuter.Get_IsEmptyElement;
end;

function TXmlSubtreeReader.Get_IsNamespaceDeclaration: Boolean;
begin
  Result := Live and FOuter.Get_IsNamespaceDeclaration;
end;

function TXmlSubtreeReader.Get_IsValid: Boolean;
begin
  Result := FOuter.Get_IsValid;
end;

function TXmlSubtreeReader.Get_LineNumber: Integer;
begin
  if Live then Result := FOuter.Get_LineNumber else Result := 0;
end;

function TXmlSubtreeReader.Get_LocalName: string;
begin
  if Live then Result := FOuter.Get_LocalName else Result := '';
end;

function TXmlSubtreeReader.Get_Name: string;
begin
  if Live then Result := FOuter.Get_Name else Result := '';
end;

function TXmlSubtreeReader.Get_NamespaceURI: string;
begin
  if Live then Result := FOuter.Get_NamespaceURI else Result := '';
end;

function TXmlSubtreeReader.Get_NodeType: TXmlNodeType;
begin
  if Live then Result := FOuter.Get_NodeType else Result := TXmlNodeType.None;
end;

function TXmlSubtreeReader.Get_Prefix: string;
begin
  if Live then Result := FOuter.Get_Prefix else Result := '';
end;

function TXmlSubtreeReader.Get_ReadState: TXmlReadState;
begin
  Result := FState;
end;

function TXmlSubtreeReader.Get_Value: string;
begin
  if Live then Result := FOuter.Get_Value else Result := '';
end;

function TXmlSubtreeReader.Get_XmlLang: string;
begin
  if Live then Result := FOuter.Get_XmlLang else Result := '';
end;

function TXmlSubtreeReader.GetAttribute(const Name: string): string;
begin
  if Live then Result := FOuter.GetAttribute(Name) else Result := '';
end;

function TXmlSubtreeReader.GetAttribute(const LocalName, NamespaceURI: string): string;
begin
  if Live then Result := FOuter.GetAttribute(LocalName, NamespaceURI) else Result := '';
end;

function TXmlSubtreeReader.GetAttribute(Index: Integer): string;
begin
  Result := FOuter.GetAttribute(Index);
end;

function TXmlSubtreeReader.TryGetAttribute(const Name: string; out Value: string): Boolean;
begin
  Value := '';
  Result := Live and FOuter.TryGetAttribute(Name, Value);
end;

function TXmlSubtreeReader.TryGetAttribute(const LocalName, NamespaceURI: string; out Value: string): Boolean;
begin
  Value := '';
  Result := Live and FOuter.TryGetAttribute(LocalName, NamespaceURI, Value);
end;

function TXmlSubtreeReader.MoveToAttribute(const Name: string): Boolean;
begin
  Result := Live and FOuter.MoveToAttribute(Name);
end;

function TXmlSubtreeReader.MoveToAttribute(const LocalName, NamespaceURI: string): Boolean;
begin
  Result := Live and FOuter.MoveToAttribute(LocalName, NamespaceURI);
end;

procedure TXmlSubtreeReader.MoveToAttribute(Index: Integer);
begin
  FOuter.MoveToAttribute(Index);
end;

function TXmlSubtreeReader.MoveToFirstAttribute: Boolean;
begin
  Result := Live and FOuter.MoveToFirstAttribute;
end;

function TXmlSubtreeReader.MoveToNextAttribute: Boolean;
begin
  Result := Live and FOuter.MoveToNextAttribute;
end;

function TXmlSubtreeReader.MoveToElement: Boolean;
begin
  Result := Live and FOuter.MoveToElement;
end;

function TXmlSubtreeReader.ReadAttributeValue: Boolean;
begin
  Result := Live and FOuter.ReadAttributeValue;
end;

function TXmlSubtreeReader.LookupNamespace(const Prefix: string): string;
begin
  if Live then Result := FOuter.LookupNamespace(Prefix) else Result := '';
end;

function TXmlSubtreeReader.Expand: IXMLElement;
begin
  RequireElement;
  Result := FOuter.Expand;
end;

{ TXmlReaderElements }

constructor TXmlReaderElements.Create(Reader: TXmlReaderBase; const LocalName, NamespaceURI: string; AnyNamespace: Boolean);
begin
  inherited Create;
  FReader := Reader;
  FReaderRef := Reader;
  FLocalName := LocalName;
  FNamespaceURI := NamespaceURI;
  FAnyNamespace := AnyNamespace;
end;

function TXmlReaderElements.GetEnumerator: IXmlReaderEnumerator;
begin
  Result := Self;
end;

function TXmlReaderElements.GetCurrent: IXmlReader;
begin
  Result := FCurrent;
end;

function TXmlReaderElements.MoveNext: Boolean;
begin
  if FCurrent <> nil then
  begin
    FCurrent.Close;
    FCurrent := nil;
    // Closing leaves the reader on the end tag of the record, or on the record itself when
    // it is empty: then the search starts past it
    if FReader.Get_NodeType = TXmlNodeType.Element then
      FReader.Read;
  end;
  if not ((FReader.Get_NodeType = TXmlNodeType.Element) and FReader.NameIs(FLocalName, FNamespaceURI, FAnyNamespace)) then
    if not FReader.FollowingNamed(FLocalName, FNamespaceURI, FAnyNamespace) then
      Exit(False);
  FCurrent := FReader.ReadSubtree;
  FCurrent.Read;
  Result := True;
end;

{ TXmlReaderNodes }

constructor TXmlReaderNodes.Create(Reader: TXmlReaderBase; const LocalName, NamespaceURI: string; AnyNamespace: Boolean);
begin
  inherited Create;
  FReader := Reader;
  FReaderRef := Reader;
  FLocalName := LocalName;
  FNamespaceURI := NamespaceURI;
  FAnyNamespace := AnyNamespace;
end;

function TXmlReaderNodes.GetEnumerator: IXmlElementEnumerator;
begin
  Result := Self;
end;

function TXmlReaderNodes.GetCurrent: IXMLElement;
begin
  Result := FCurrent;
end;

function TXmlReaderNodes.MoveNext: Boolean;
begin
  FCurrent := nil;
  // ReadElement leaves the reader on the node after the record, which may be the next one
  if not ((FReader.Get_NodeType = TXmlNodeType.Element) and FReader.NameIs(FLocalName, FNamespaceURI, FAnyNamespace)) then
    if not FReader.FollowingNamed(FLocalName, FNamespaceURI, FAnyNamespace) then
      Exit(False);
  FCurrent := FReader.ReadElement;
  Result := True;
end;

{ XmlReader }

function NewReader(const Settings: TXmlReaderSettings): TXmlTextReader;
begin
  // Every reader starts here, so the reader layer initialises the library itself, as the
  // DOM and SAX layers do. The node-free callback goes in here as well: Expand wraps nodes of
  // the reader's tree, and the wrapper must learn that the reader has freed its node even when
  // no document object ever installed the callback
  LX2Lib.Initialize;
  SetNodeFreeCallback;
  Result := TXmlTextReader.Create(Settings);
end;

/// <summary>Attaches the native reader to the object; without one the input could not be
/// opened. The caller holds the object through an interface, which frees it on the error.</summary>
procedure Finish(Reader: TXmlTextReader; Native: xmlTextReaderPtr; const FileName: string = '');
begin
  if Native = nil then
    if FileName <> '' then
      raise EFOpenError.CreateResFmt(@SReaderCannotOpen, [FileName])
    else
      raise EXmlReaderError.Create(SReaderNoInput, 0);
  Reader.Attach(Native);
end;

class function XmlReader.Create(Stream: TStream): IXmlReader;
var
  Settings: TXmlReaderSettings;
begin
  Result := Create(Stream, Settings);
end;

class function XmlReader.Create(Stream: TStream; const Settings: TXmlReaderSettings): IXmlReader;
begin
  if Stream = nil then
    raise EArgumentNilException.Create('Stream');
  var Reader := NewReader(Settings);
  Result := Reader;
  Reader.FStream := Stream;
  Reader.FOwnsStream := Settings.CloseInput;
  Finish(Reader, xmlTextReader.Create(Stream, ParserOptions(Settings), UTF8Encode(Settings.Encoding), Reader.HandleError,
    UTF8Encode(Settings.BaseURI)));
end;

class function XmlReader.Create(const Data: TBytes): IXmlReader;
var
  Settings: TXmlReaderSettings;
begin
  Result := Create(Data, Settings);
end;

class function XmlReader.Create(const Data: TBytes; const Settings: TXmlReaderSettings): IXmlReader;
begin
  var Reader := NewReader(Settings);
  Result := Reader;
  Finish(Reader, xmlTextReader.Create(Data, ParserOptions(Settings), Reader.HandleError,
    UTF8Encode(Settings.BaseURI), UTF8Encode(Settings.Encoding)));
end;

class function XmlReader.Create(const Doc: IXMLDocument): IXmlReader;
var
  Settings: TXmlReaderSettings;
begin
  Result := Create(Doc, Settings);
end;

class function XmlReader.Create(const Doc: IXMLDocument; const Settings: TXmlReaderSettings): IXmlReader;
begin
  if Doc = nil then
    raise EArgumentNilException.Create('Doc');
  var Reader := NewReader(Settings);
  Result := Reader;
  Reader.FDocument := Doc;
  Finish(Reader, xmlTextReader.CreateWalker(xmlDocPtr(TXMLNodeAccess(TObject(Doc)).NodePtr)));
end;

class function XmlReader.CreateFromFile(const FileName: string): IXmlReader;
var
  Settings: TXmlReaderSettings;
begin
  Result := CreateFromFile(FileName, Settings);
end;

class function XmlReader.CreateFromFile(const FileName: string; const Settings: TXmlReaderSettings): IXmlReader;
begin
  var Reader := NewReader(Settings);
  Result := Reader;
  Finish(Reader, xmlTextReader.CreateFromFile(FileName, ParserOptions(Settings), Reader.HandleError,
    UTF8Encode(Settings.Encoding)), FileName);
end;

class function XmlReader.CreateFromString(const XML: string): IXmlReader;
var
  Settings: TXmlReaderSettings;
begin
  Result := CreateFromString(XML, Settings);
end;

class function XmlReader.CreateFromString(const XML: string; const Settings: TXmlReaderSettings): IXmlReader;
begin
  var Reader := NewReader(Settings);
  Result := Reader;
  Finish(Reader, xmlTextReader.Create(XML, ParserOptions(Settings), Reader.HandleError, UTF8Encode(Settings.BaseURI)));
end;

class function XmlReader.CreateFromString(const XML: RawByteString): IXmlReader;
var
  Settings: TXmlReaderSettings;
begin
  Result := CreateFromString(XML, Settings);
end;

class function XmlReader.CreateFromString(const XML: RawByteString; const Settings: TXmlReaderSettings): IXmlReader;
begin
  var Reader := NewReader(Settings);
  Result := Reader;
  Finish(Reader, xmlTextReader.Create(XML, ParserOptions(Settings), Reader.HandleError,
    UTF8Encode(Settings.BaseURI), UTF8Encode(Settings.Encoding)));
end;

initialization
  InitBase64;

end.
