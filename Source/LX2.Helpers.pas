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

  /// <summary>Method-based callback invoked for libxml2/libxslt parsing, validation and XPath errors.</summary>
  xmlDocErrorHandler  = procedure(const error: xmlError) of object;
  /// <summary>
  /// Method-based callback allowing custom resolution of external resources
  /// (DTDs, external entities, schema imports, etc.) during parsing/validation.
  /// </summary>
  /// <remarks>
  /// Invoked through <see cref="xmlResourceLoaderCallback"/>, which wraps the
  /// call in a try/except and converts any raised exception into
  /// <c>XML_ERR_INTERNAL_ERROR</c> to prevent exceptions from propagating
  /// across the C-callback boundary into libxml2's C runtime (which would
  /// corrupt its internal state / crash).
  /// </remarks>
  xmlResourceLoader   = function(const url, publicId: xmlCharPtr; resType: xmlResourceType; Flags: Integer; var output: xmlParserInputPtr): Integer of object;
  /// <summary>Method-based callback for receiving libxslt transformation error/warning messages as decoded strings.</summary>
  xsltErrorHandler    = procedure(const Msg: string) of object;

  /// <summary>
  /// Represents a single XML namespace declaration (prefix + URI) used when
  /// registering namespaces for XPath queries.
  /// </summary>
  xmlNamespace = record
    /// <summary>Namespace prefix (without colon), e.g. "soap".</summary>
    Prefix: RawByteString;
    /// <summary>Namespace URI, e.g. "http://schemas.xmlsoap.org/soap/envelope/".</summary>
    URI: RawByteString;
  end;

  /// <summary>
  /// A list of namespace declarations, typically passed to XPath evaluation
  /// methods so that prefixed names in the query can be resolved.
  /// </summary>
  xmlNamespaces = TArray<xmlNamespace>;

  /// <summary>Helper providing convenience methods over <see cref="xmlNamespaces"/>.</summary>
  xmlNamespacesHelper = record helper for xmlNamespaces
    /// <summary>Appends a new namespace declaration to the array.</summary>
    /// <param name="Prefix">Namespace prefix.</param>
    /// <param name="URI">Namespace URI.</param>
    procedure Add(const Prefix, URI: RawByteString); inline;

    /// <summary>Returns the number of registered namespace declarations.</summary>
    function Count: NativeInt; inline;
  end;

  /// <summary>
  /// Record helper exposing a DOM-like API (similar to W3C DOM Node interface)
  /// over the low-level libxml2 <c>xmlNode</c> structure.
  /// </summary>
  /// <remarks>
  /// All properties/methods operate directly on the underlying libxml2 node
  /// via <c>@Self</c>; no additional memory is allocated unless explicitly
  /// documented (e.g. array-returning methods).
  /// </remarks>
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
    /// <summary>
    /// Creates a new child element with the given (optionally prefixed) name
    /// and appends it to this node.
    /// </summary>
    /// <param name="Name">
    /// Element name, optionally qualified as "prefix:local". The prefix must
    /// already be declared and reachable from this node (via <c>xmlSearchNs</c>);
    /// otherwise the node is created using the full literal <paramref name="Name"/>
    /// without a namespace binding.
    /// </param>
    /// <param name="Content">Optional text content (will be escaped).</param>
    /// <returns>The newly created and appended node, or <c>nil</c> on failure.</returns>
    function  AddChild(const Name: RawByteString; const Content: RawByteString = ''): xmlNodePtr;
    /// <summary>
    /// Creates a new child element bound to the specified namespace URI,
    /// creating and attaching the namespace declaration if it is not already
    /// in scope.
    /// </summary>
    /// <param name="Name">
    /// Element name, optionally qualified as "prefix:local". If a namespace
    /// with matching URI is not found in scope, <paramref name="Name"/> is
    /// split to obtain the desired prefix for the newly declared namespace.
    /// </param>
    /// <param name="NamespaceURI">Target namespace URI.</param>
    /// <param name="Content">Optional text content.</param>
    function  AddChildNs(const Name, NamespaceURI: RawByteString; const Content: RawByteString = ''): xmlNodePtr;
    /// <summary>
    /// Appends <paramref name="NewChild"/> as the last child of this node and
    /// reconciles namespace declarations across the moved subtree.
    /// </summary>
    function  AppendChild(const NewChild: xmlNodePtr): xmlNodePtr; inline;
    /// <summary>Returns the number of direct element children (ignores text/comment nodes).</summary>
    function  ChildElementCount: NativeInt; inline;
    /// <summary>
    /// Creates a deep or shallow copy of this node that is NOT attached to any
    /// document/parent. Caller is responsible for freeing or attaching the result.
    /// </summary>
    /// <param name="Deep">If <c>True</c>, clones the whole subtree; otherwise only this node.</param>
    function  CloneNode(Deep: Boolean): xmlNodePtr; inline;
    /// <summary>
    /// Determines whether <paramref name="Node"/> is this node itself or a
    /// descendant of it, by walking up the <c>parent</c> chain from
    /// <paramref name="Node"/>.
    /// </summary>
    function  Contains(const Node: xmlNodePtr): Boolean; inline;
    function  FirstElementChild: xmlNodePtr; inline;
    /// <summary>
    /// Returns the string value of an attribute, resolving namespace prefixes
    /// and the special "xmlns"/"xmlns:prefix" pseudo-attributes.
    /// </summary>
    /// <param name="Name">
    /// Attribute name. Special cases:
    /// <list type="bullet">
    /// <item><description>"xmlns" — returns the URI of the default namespace.</description></item>
    /// <item><description>"xmlns:prefix" — returns the URI bound to <c>prefix</c>.</description></item>
    /// <item><description>"prefix:local" — returns the value of the namespaced attribute.</description></item>
    /// </list>
    /// </param>
    /// <returns>Attribute value, or empty string if not found.</returns>
    function  GetAttribute(const Name: RawByteString): RawByteString; inline;
    /// <summary>
    /// Looks up an attribute node by (optionally prefixed) name, matching
    /// both local name and namespace prefix exactly.
    /// </summary>
    function  GetAttributeNode(const name: RawByteString): xmlAttrPtr; overload;
    /// <summary>Looks up an attribute node by local name and namespace URI.</summary>
    function  GetAttributeNodeNs(const namespaceURI, name: RawByteString): xmlAttrPtr; overload;
    /// <summary>Returns the value of a namespace-qualified attribute.</summary>
    function  GetAttributeNs(const NamespaceURI, Name: RawByteString): RawByteString; inline;
    /// <summary>
    /// Returns all descendant elements matching <paramref name="Name"/>
    /// ("*" matches any element), in document order.
    /// </summary>
    /// <remarks>
    /// Uses a growable buffer (starting capacity 16, doubling by +16 on overflow)
    /// to avoid re-counting matches in a separate pass.
    /// </remarks>
    function  GetElementsByTagName(const Name: RawByteString): xmlNodeArray;
    /// <summary>
    /// Returns the next node in document order relative to <paramref name="Root"/>,
    /// implementing a classic pre-order tree walk (used internally by
    /// <see cref="GetElementsByTagName"/>).
    /// </summary>
    /// <param name="Root">
    /// The node considered the traversal boundary; traversal stops (returns
    /// <c>nil</c>) once it would ascend past this node.
    /// </param>
    /// <remarks>
    /// Algorithm: descend into children first; if none, move to the next
    /// sibling; if none, walk up through parents until either <paramref name="Root"/>
    /// is reached (stop) or a parent with a next sibling is found. A defensive
    /// <c>nil</c> check guards against detached subtrees where <paramref name="Root"/>
    /// is not actually an ancestor.
    /// </remarks>
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
    function  PreviousElementSibling: xmlNodePtr; inline;
    procedure ReconciliateNs; inline;
    /// <summary>Removes the attribute with the given name, if present.</summary>
    procedure RemoveAttribute(const name: RawByteString); inline;
    /// <summary>
    /// Detaches and frees the given attribute node, then reconciles namespaces
    /// on this node.
    /// </summary>
    procedure RemoveAttributeNode(const Attr: xmlAttrPtr); inline;
    function  RemoveChild(const ChildNode: xmlNodePtr): xmlNodePtr; inline;
    function  ReplaceChild(const NewChild, OldChild: xmlNodePtr): xmlNodePtr; inline;
    function  SearchNs(const Prefix: RawByteString): xmlNsPtr; overload; inline;
    function  SearchNs(const Prefix: xmlCharPtr): xmlNsPtr; overload; inline;
    function  SearchNsByRef(const href: RawByteString): xmlNsPtr; overload; inline;
    function  SearchNsByRef(const href: xmlCharPtr): xmlNsPtr; overload; inline;
    /// <summary>Evaluates an XPath expression and returns matched nodes as an array.</summary>
    function  SelectNodes(const QueryString: RawByteString; const Namespaces: xmlNamespaces = nil): xmlNodeArray;
    /// <summary>
    /// Evaluates an XPath expression and returns the first matched node, or
    /// <c>nil</c> if none matched.
    /// </summary>
    /// <remarks>
    /// For simple path expressions (as determined by <c>TXPathQuery.IsSimple</c>),
    /// a fast-path parser/evaluator (<c>LX2.XPATH.TXPathQuery</c>) is used instead
    /// of the full libxml2 XPath engine, bypassing context/namespace setup for
    /// better performance on common cases like "a/b/c" or "@attr".
    /// </remarks>
    function  SelectSingleNode(const QueryString: RawByteString): xmlNodePtr;
    /// <summary>
    /// Sets the attribute value, creating the attribute (or namespace
    /// declaration, for "xmlns"/"xmlns:prefix" names) if it does not exist.
    /// </summary>
    /// <remarks>
    /// Unlike <see cref="SetAttributeNs"/>, the namespace for a "prefix:local"
    /// name is resolved via <c>xmlSearchNs</c> starting from this node — the
    /// prefix must already be in scope, otherwise the attribute is created
    /// without a namespace binding (silently).
    /// </remarks>
    procedure SetAttribute(const Name: RawByteString; const Value: RawByteString);
    /// <summary>
    /// Sets a namespace-qualified attribute value, resolving the namespace by
    /// its URI (not by prefix) and creating the property with that namespace.
    /// </summary>
    function  SetAttributeNs(const NamespaceURI, Name: RawByteString; const Value: RawByteString): xmlAttrPtr; inline;
    /// <summary>
    /// Applies an XSLT stylesheet to the subtree rooted at this node, treating
    /// this node as the initial context node, and produces a new document.
    /// </summary>
    /// <param name="stylesheet">
    /// Parsed stylesheet document. Internally cloned before parsing, because
    /// <c>xsltFreeStylesheet</c> takes ownership of (and frees) the underlying
    /// document — cloning avoids destroying the caller's stylesheet document.
    /// </param>
    /// <param name="doc">Receives the resulting transformed document on success.</param>
    /// <param name="errorHandler">Optional callback receiving libxslt error messages.</param>
    /// <returns><c>True</c> on success.</returns>
    /// <remarks>
    /// The compiled stylesheet (<c>xsltStylesheetPtr</c>) is always released
    /// before returning, regardless of the outcome — on failure it is released
    /// inside <c>XsltTransform</c> itself (and <c>style</c> set to <c>nil</c>),
    /// on success it is released by the caller after the result is consumed.
    /// Do not attempt to free it again externally.
    /// </remarks>
    function  Transform(const stylesheet: xmlDocPtr; out doc: xmlDocPtr; errorHandler: xsltErrorHandler = nil): Boolean; overload;
    /// <summary>Applies an XSLT stylesheet and serializes the result to a UTF-8/raw byte string.</summary>
    function  Transform(const stylesheet: xmlDocPtr; out S: RawByteString; errorHandler: xsltErrorHandler = nil): Boolean; overload;
    /// <summary>
    /// Applies an XSLT stylesheet and serializes the result to a Unicode string.
    /// </summary>
    /// <remarks>Internally serializes to raw bytes first, then decodes as UTF-8.</remarks>
    function  Transform(const stylesheet: xmlDocPtr; out S: string; errorHandler: xsltErrorHandler = nil): Boolean; overload;
    /// <summary>Applies an XSLT stylesheet and writes the serialized result to a stream.</summary>
    function  Transform(const stylesheet: xmlDocPtr; Stream: TStream; errorHandler: xsltErrorHandler = nil): Boolean; overload;
    property  Value: RawByteString read GetValue;
    /// <summary>
    /// Evaluates an XPath expression with this node as context node.
    /// </summary>
    /// <param name="queryString">XPath expression</param>
    /// <param name="namespaces">
    /// Explicit namespace bindings to register in the XPath context. If empty,
    /// all namespace declarations in scope on this node (<c>Self.ns</c> chain)
    /// are registered automatically.
    /// </param>
    /// <param name="ErrorHandler">Optional callback invoked on XPath errors.</param>
    /// <returns>
    /// The raw XPath result object. Caller must free it with
    /// <c>xmlXPathFreeObject</c> unless consumed by <see cref="SelectNodes"/>.
    /// </returns>
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
    /// <summary>
    /// Type-dependent "value" of the node per the DOM <c>nodeValue</c> semantics:
    /// text/CDATA/comment content for text-like nodes, attribute default value
    /// for attribute declarations, empty string otherwise.
    /// </summary>
    property  NodeValue: RawByteString read GetNodeValue write SetNodeValue;
    property  OwnerDocument: xmlDocPtr read GetOwnerDocument;
    property  ParentElement: xmlNodePtr read GetParentElement;
    property  ParentNode: xmlNodePtr read GetParentNode;
    /// <summary>
    /// XPath-style absolute path to this node from the document root
    /// (e.g. "/root/child[2]"), computed via <c>xmlGetNodePath</c>.
    /// </summary>
    property  Path: RawByteString read GetPath;
    property  Prefix: RawByteString read GetPrefix;
    property  PreviousSibling: xmlNodePtr read GetPreviousSibling;
    /// <summary>
    /// Qualified tag name including namespace prefix, e.g. "soap:Envelope".
    /// Returns the bare local name if the node has no namespace.
    /// </summary>
    property  TagName: RawByteString read GetTagName;
    /// <summary>Full text content of this node and all its text descendants (DOM <c>textContent</c> equivalent).</summary>
    property  Text: RawByteString read GetText write SetText;
    /// <summary>Serializes this node (and its subtree) to an XML string, without XML declaration.</summary>
    property  Xml: RawByteString read GetXml;
  end;

  /// <summary>Record helper exposing a DOM-like API over the libxml2 <c>xmlAttr</c> structure.</summary>
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
    /// <summary>
    /// Rebuilds the attribute's text content from scratch, handling the
    /// ID-attribute bookkeeping required by libxml2's ID table.
    /// </summary>
    /// <remarks>
    /// Order of operations matters here:
    /// 1) If this attribute currently participates in the DTD ID table
    ///    (<c>atype = XML_ATTRIBUTE_ID</c>), it is unregistered via
    ///    <c>xmlRemoveID</c> BEFORE its text content changes, since the ID
    ///    table is keyed by the old value.
    /// 2) The old child text node list is freed and replaced with a single
    ///    new text node (only if <paramref name="Value"/> is non-empty).
    /// 3) <c>ns</c> is re-derived from <c>parent.ns</c> — this assumes the
    ///    attribute's effective namespace always matches its owning element's
    ///    default namespace, which is a simplification (it does not preserve
    ///    a previously distinct attribute namespace).
    /// 4) If this was (and still conceptually is) an ID attribute, it is
    ///    re-registered via <c>xmlAddIDSafe</c> with the NEW value.
    /// </remarks>
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
    /// <summary>
    /// Qualified attribute name including namespace prefix (if any),
    /// e.g. "xlink:href". Returns bare local name for unqualified attributes.
    /// </summary>
    property  NodeName: RawByteString read GetName;
    /// <summary>
    /// Attribute value as plain text. Reading assumes a "simple" attribute
    /// with at most a single text/CDATA child node — attributes with mixed
    /// or entity-reference content are not fully supported and return an
    /// unassigned <c>Result</c> (empty string) in that branch.
    /// </summary>
    property  Value: RawByteString read GetValue write SetValue;
    property  OwnerDocument: xmlDocPtr read GetOwnerDocument;
    property  Prefix: RawByteString read GetPrefix;
    property  PreviousSibling: xmlAttrPtr read GetPreviousSibling;
    property  BaseURI: RawByteString read GetBaseURI write SetBaseURI;
  end;

  /// <summary>Record helper exposing document-level construction, I/O and transformation APIs over <c>xmlDoc</c>.</summary>
  xmlDocHelper = record helper for xmlDoc
  private type
    TSelf = type xmlDoc;
  private
    function  GetDocumentElement: xmlNodePtr; inline;
    function  GetUrl: RawByteString; inline;
    function  GetXml: RawByteString;
    /// <summary>
    /// Replaces the document's root element, freeing the previous root (if any).
    /// </summary>
    procedure SetDocumentElement(const Value: xmlNodePtr);
  public
    /// <summary>Creates an empty document with only an XML declaration.</summary>
    class function Create(const Version: RawByteString = '1.0'): xmlDocPtr; overload; static; inline;
    /// <summary>Parses an XML document from a raw byte buffer (assumed to already be in the target encoding).</summary>
    class function Create(const XML: RawByteString; const Options: TXmlParserOptions; ErrorHandler: xmlDocErrorHandler = nil): xmlDocPtr; overload; static; inline;
    /// <summary>Parses an XML document from a Unicode string (encoded to UTF-8 before parsing).</summary>
    class function Create(const XML: string; const Options: TXmlParserOptions; ErrorHandler: xmlDocErrorHandler = nil): xmlDocPtr; overload; static; inline;
    class function Create(const Data: TBytes; const Options: TXmlParserOptions; ErrorHandler: xmlDocErrorHandler = nil): xmlDocPtr; overload; static; inline;
    /// <summary>
    /// Parses an XML document from a raw memory buffer.
    /// </summary>
    /// <remarks>
    /// Uses <c>XML_INPUT_BUF_STATIC</c>, meaning libxml2 does NOT copy or take
    /// ownership of <paramref name="Data"/> — the caller must keep the buffer
    /// alive for the duration of the parse call (it is not needed afterwards,
    /// since the parsed DOM owns its own copies of text content).
    /// </remarks>
    class function Create(const Data: Pointer; Size: NativeUInt; const Options: TXmlParserOptions; ErrorHandler: xmlDocErrorHandler = nil): xmlDocPtr; overload; static;
    /// <summary>
    /// Parses an XML document directly from a file path/URL, honoring
    /// <c>XML_PARSE_NONET</c>/<c>XML_PARSE_UNZIP</c> automatically.
    /// </summary>
    class function CreateFromFile(const FileName: string; const Options: TXmlParserOptions; ErrorHandler: xmlDocErrorHandler = nil): xmlDocPtr; overload; static; inline;
    /// <summary>Parses an XML document by reading from a <c>TStream</c> via a custom libxml2 IO callback.</summary>
    class function Create(Stream: TStream; const Options: TXmlParserOptions; const Encoding: Utf8String; ErrorHandler: xmlDocErrorHandler = nil): xmlDocPtr; overload; static;
    /// <summary>
    /// Creates and attaches the root element of this (assumed empty) document.
    /// </summary>
    /// <param name="RootName">
    /// Root element name, optionally qualified as "prefix:local". If qualified,
    /// a NEW namespace declaration is always created with <paramref name="NamespaceURI"/>
    /// bound to that prefix — this does not search for an existing namespace
    /// in scope (there can be none yet, since this is the root).
    /// </param>
    /// <param name="NamespaceURI">Namespace URI</param>
    /// <param name="Content">Content if any</param>
    function  CreateRoot(const RootName: RawByteString; const NamespaceURI: RawByteString = ''; const Content: RawByteString = ''): xmlNodePtr;
    /// <summary>
    /// Creates a new element and appends it under <paramref name="Parent"/>,
    /// or creates the document root if <paramref name="Parent"/> is <c>nil</c>.
    /// </summary>
    /// <param name="Parent">Parent node, can be nil for create detached node</param>
    /// <param name="Name">Name of node, can be qualified name</param>
    /// <param name="NamespaceURI">Namespace URI</param>
    /// <param name="ResolveNamespace">Currently unused by the implementation — reserved.</param>
    /// <param name="Content">Content if any.</param>
    function  CreateChild(const Parent: xmlNodePtr; const Name: RawByteString; const NamespaceURI: RawByteString = ''; ResolveNamespace: Boolean = False; Content: RawByteString = ''): xmlNodePtr;
    procedure Free; inline;
    function  CanonicalizeTo(const FileName: string; Mode: TXmlC14NMode = TXmlC14NMode.xmlC14N; Comments: Boolean = False): Boolean; overload;
    /// <summary>
    /// Serializes the document per the XML Canonicalization (C14N) spec directly
    /// to a stream, without buffering the whole result in memory.
    /// </summary>
    function  CanonicalizeTo(const Stream: TStream; Mode: TXmlC14NMode = TXmlC14NMode.xmlC14N; Comments: Boolean = False): Boolean; overload;
    /// <summary>Serializes the document per C14N to an in-memory raw byte string.</summary>
    /// <exception cref="LX2InternalError">Raised if libxml2 reports a negative size (internal C14N failure).</exception>
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
    function  Save(const FileName: string; const Encoding: string = 'UTF-8'; const Options: TxmlSaveOptions = [xmlSaveNoEmpty]): Boolean; overload;
    function  Save(Stream: TStream; const Encoding: string = 'UTF-8'; const Options: TxmlSaveOptions = []): Boolean; overload;
    function  ToAnsi(const Encoding: string = 'windows-1251'; const Format: Boolean = False): RawByteString; overload;
    function  ToBytes(const Encoding: string = 'UTF-8'; const Format: Boolean = False): TBytes; overload;
    function  ToString(const Encoding: string = 'UTF-8'; const Format: Boolean = False): string; overload;
    function  ToUtf8(const Format: Boolean = False): RawByteString; overload;
    /// <summary>
    /// Applies an XSLT stylesheet to the entire document and produces a new
    /// result document.
    /// </summary>
    /// <remarks>
    /// See remarks on <see cref="xmlNodeHelper.Transform"/> regarding stylesheet
    /// cloning and lifetime of the compiled <c>xsltStylesheetPtr</c>.
    /// </remarks>
    function  Transform(const stylesheet: xmlDocPtr; out doc: xmlDocPtr; errorHandler: xsltErrorHandler = nil): Boolean; overload;
    /// <summary>
    /// Applies an XSLT stylesheet and decodes the result as a Unicode string,
    /// choosing the decoding based on the STYLESHEET's declared output encoding
    /// (falls back to raw byte-to-char conversion for non-UTF-8 encodings).
    /// </summary>
    /// <remarks>
    /// Note: this inspects <c>stylesheet.encoding</c> (the source stylesheet
    /// document's encoding attribute), not the actual <c>xsl:output encoding="..."</c>
    /// directive — for stylesheets where these differ, decoding may be incorrect.
    /// </remarks>
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
  libxslt.API, LX2.XPATH;

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

procedure xsltErrorCallback(ctx: Pointer; const msg: xmlCharPtr); cdecl {$IFDEF CPUX64} varargs{$ENDIF};
begin
  if ctx <> nil then
  begin
    PXsltErrorCallback(ctx).Handler(xmlCharToStr(msg));
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
  if style = nil then   // критично: сигнализирует вызывающему коду, что стиль уже освобождён,
    Exit;               // чтобы тот не выполнил повторный xsltFreeStylesheet(style)

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
  begin
    xsltFreeStylesheet(style);
    style := nil;
  end;
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
  begin
    Ns := xmlSearchNs(Doc, @Self, xmlStrPtr(Prefix));
    if Ns = nil then
      Result := xmlNewDocRawNode(doc, Ns, xmlStrPtr(Name), xmlStrPtr(Content))
    else
      Result := xmlNewDocRawNode(doc, Ns, xmlStrPtr(LocalName), xmlStrPtr(Content))
  end
  else
    Result := xmlNewDocRawNode(doc, nil, xmlStrPtr(Name), xmlStrPtr(Content));

  if Result <> nil then
    AppendChild(Result);
end;

function xmlNodeHelper.AddChildNs(const Name, NamespaceURI, Content: RawByteString): xmlNodePtr;
var
  Prefix, LocalName: RawByteString;
begin
  var Ns := xmlSearchNsByHRef(doc, @Self, xmlStrPtr(NamespaceURI));

  if Ns = nil then
  begin
    if SplitXMLName(Name, Prefix, LocalName) then
    begin
      Result := xmlNewDocRawNode(doc, nil, xmlStrPtr(LocalName), xmlStrPtr(Content));

      Ns := xmlNewNs(Result, xmlStrPtr(NamespaceURI), xmlStrPtr(Prefix));
      xmlSetNs(Result, ns);
    end
    else
      Result := xmlNewDocRawNode(doc, Ns, xmlStrPtr(Name), xmlStrPtr(Content));
  end
  else
    Result := xmlNewDocRawNode(doc, Ns, xmlStrPtr(Name), xmlStrPtr(Content));

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
        if (Attr.ns <> nil) and xmlStrSame(Attr.ns.prefix, Pointer(Prefix))and xmlStrSame(Attr.name, Pointer(LocalName)) then
          Exit(xmlAttrPtr(Attr).Value);
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

      if Result = nil then Exit(nil);    // защита от случая, когда Root
                                         // не является предком стартового узла
                                         // (например, узел был отсоединён от дерева)
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
    node := node.GetNext(@Self);
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
  if ns = nil then
    Result := ''
  else
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
  Result := xmlHasNsProp(@Self, xmlStrPtr(Name), xmlStrPtr(NamespaceURI)) <> nil;
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
    Result := xmlAddPrevSibling(RefChild, NewChild);
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
      // Every prefix declared on the context node or one of its ancestors is visible to
      // the expression, the way it is in the document; a declaration closer to the node
      // shadows the same prefix declared further up, so the walk starts at the node and
      // never overwrites a prefix already registered.
      var node: xmlNodePtr := @Self;
      while (node <> nil) and (node.&type = XML_ELEMENT_NODE) do
      begin
        var ns := node.nsDef;
        while ns <> nil do
        begin
          if (ns.prefix <> nil) and (xmlXPathNsLookup(ctx, ns.prefix) = nil) then
            xmlXPathRegisterNs(ctx, ns.prefix, ns.href);
          ns := ns.next;
        end;
        node := node.parent;
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

  if (xpathObj.nodesetval <> nil) and (xpathObj.nodesetval.nodeNr > 0) then
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
  if queryString = '' then
    Exit(nil);

  if TXPathQuery.IsSimple(queryString) then
  begin
    Result := TXPathQuery.Parse(QueryString).Select(@Self);
    Exit;
  end;

  // Same evaluation as SelectNodes: the namespaces in scope are registered, and the
  // result object is released on every path, including an empty node set.
  var xpathObj := XPathEval(queryString, nil, nil);
  if xpathObj = nil then
    Exit(nil);
  try
    if (xpathObj.nodesetval <> nil) and (xpathObj.nodesetval.nodeNr > 0) then
      Result := xpathObj.nodesetval.nodeTab[0]
    else
      Result := nil;
  finally
    xmlXPathFreeObject(xpathObj);
  end;
end;

procedure xmlNodeHelper.SetAttribute(const Name, Value: RawByteString);
var
  Prefix, LocalName: RawByteString;
begin
  if Name = 'xmlns' then
    xmlSetNs(@Self, xmlNewNs(@Self, xmlStrPtr(Value), nil))
  else
  begin
    if SplitXMLName(Name, Prefix, LocalName) then
    begin
      if Prefix = 'xmlns' then
        xmlNewNs(@Self, xmlStrPtr(Value), xmlStrPtr(LocalName))
      else
      begin
        var Ns := xmlSearchNs(doc, @Self, xmlStrPtr(Prefix));
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
  if Result then
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
    xsltFreeStylesheet(style);
  end;
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
begin
  Result := XsltTransform(stylesheet, Self.doc, @Self, style, output, errorHandler);
  if Result then
  begin
    var Buffer := xmlOutputBufferCreateIO(@IOWriteStream, @IOCloseStream, Pointer(Stream), nil);
    if Buffer <> nil then
      xsltSaveResultTo(Buffer, output, style)
    else
      Result := False;
    xmlFreeDoc(output);
    xsltFreeStylesheet(style);
  end;
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
  if ns = nil then
    Result := xmlCharToRaw(TSelf(Self).name)
  else
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
  begin
    if child.content = nil then
      Exit('')
    else
      Exit(xmlCharToRaw(child.content));
  end
  else
    Exit(xmlCharToRawAndFree(xmlNodeListGetString(doc, children, 1)));
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
    xmlRemoveID(doc, @self);

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
  Result := xmlNewDoc(xmlStrPtr(Version));
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
  var Args: TXmlArgs;
  var ctx := xmlNewParserCtxt();
  if ctx = nil then
    Exit(nil);

  if Assigned(ErrorHandler) then
  begin
    ecb.Handler := ErrorHandler;
    xmlCtxtSetErrorHandler(ctx, xmlDocErrorCallback, @ecb);
  end;

  xmlCtxtUseOptions(ctx, XmlParserOptions(Options) or XML_PARSE_UNZIP or XML_PARSE_NONET);

  if xmlNewInputFromUrl(Args.StrPtr(filename), 0, input) = XML_ERR_OK then
  begin
    Result := xmlCtxtParseDocument(ctx, input);
    //xmlFreeInputStream(input);
  end
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
    ns := xmlNewNs(nil, xmlStrPtr(NamespaceURI), xmlStrPtr(Prefix))
  else if NamespaceURI <> '' then
    ns := xmlNewNs(nil, xmlStrPtr(NamespaceURI), nil)
  else
    ns := nil;

  Result := xmlNewDocRawNode(@Self, ns, xmlStrPtr(RootName), xmlStrPtr(content));

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
      ns := xmlNewNs(nil, xmlStrPtr(NamespaceURI), xmlStrPtr(Prefix))
  end
  else if NamespaceURI <> '' then
    ns := xmlNewNs(nil, xmlStrPtr(NamespaceURI), nil)
  else
    ns := nil;

  Result := xmlNewDocRawNode(Parent.doc, ns, xmlStrPtr(LocalName), xmlStrPtr(Content));
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
  var Args: TXmlArgs;
  Result := xmlC14NDocSave(Doc, nil, xmlC14NMode(Ord(Mode)), nil, Ord(Comments), Args.StrPtr(FileName), 0) = 0;
end;

function xmlDocHelper.Canonicalize(Mode: TXmlC14NMode; Comments: Boolean): RawByteString;
var
  Data: xmlCharPtr;
begin
  var Size := xmlC14NDocDumpMemory(Doc, nil, xmlC14NMode(Mode), nil, Ord(Comments), Data);
  if Size < 0 then
    LX2InternalError;

  SetString(Result, Data, Size);

  xmlFree(Data);
end;

function xmlDocHelper.Clone(Recursive: Boolean): xmlDocPtr;
begin
  Result := xmlCopyDoc(@Self, Ord(Recursive));
end;

function xmlDocHelper.CreateAttribute(const Name, Value: RawByteString): xmlAttrPtr;
begin
  Result := xmlNewDocProp(@Self, xmlStrPtr(Name), xmlStrPtr(Value));
end;

function xmlDocHelper.CreateCDATASection(const Data: RawByteString): xmlNodePtr;
begin
  Result := xmlNewCDataBlock(@Self, xmlStrPtr(Data), Length(Data));
end;

function xmlDocHelper.CreateComment(const Data: RawByteString): xmlNodePtr;
begin
  Result := xmlNewDocComment(@Self, xmlStrPtr(Data));
end;

function xmlDocHelper.CreateDocumentFragment: xmlNodePtr;
begin
  Result := xmlNewDocFragment(@Self);
end;

function xmlDocHelper.CreateElement(const Name: RawByteString): xmlNodePtr;
begin
  Result := xmlNewDocRawNode(@Self, nil, xmlStrPtr(Name), nil);
end;

function xmlDocHelper.CreateElementNs(const NamespaceURI, Name: RawByteString): xmlNodePtr;
begin
  Result := xmlNewDocRawNode(@Self, nil, xmlStrPtr(Name), nil);
  xmlSetNs(Result, xmlNewNs(Result, xmlStrPtr(NamespaceURI), nil));
end;

function xmlDocHelper.CreateEntityReference(const Name: RawByteString): xmlNodePtr;
begin
  Result := xmlNewReference(@Self, xmlStrPtr(Name));
end;

function xmlDocHelper.CreateProcessingInstruction(const Target, Data: RawByteString): xmlNodePtr;
begin
  Result := xmlNewDocPI(@Self, xmlStrPtr(Target), xmlStrPtr(Data));
end;

function xmlDocHelper.CreateTextNode(const Data: RawByteString): xmlNodePtr;
begin
  Result := xmlNewDocText(@Self,  xmlStrPtr(data));
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
  var Args: TXmlArgs;
  var ctx := xmlSaveToIO(IOWriteStream, nil, Stream, Args.StrPtr(Encoding), XmlSaveOptions(Options));
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
  var Args: TXmlArgs;
  xmlDocDumpFormatMemoryEnc(doc, Data, Size, Args.StrPtr(Encoding), Ord(Format));

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
  var Args: TXmlArgs;
  xmlDocDumpFormatMemoryEnc(doc, Data, Size, Args.StrPtr(Encoding), Ord(Format));

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
    xsltFreeStylesheet(style);
  end;
end;

function xmlDocHelper.Transform(const stylesheet: xmlDocPtr; out S: string; errorHandler: xsltErrorHandler): Boolean;
var
  Text: RawByteString;
begin
  Result := Transform(stylesheet, Text, errorHandler);
  if Result then
  begin
    if AnsiSameText(string(stylesheet.encoding), 'utf-8') then
      S := UTF8ToUnicodeString(Text)
    else
      S := string(Text);
  end;
end;

function xmlDocHelper.Transform(const stylesheet: xmlDocPtr; Stream: TStream; errorHandler: xsltErrorHandler): Boolean;
var
  style: xsltStylesheetPtr;
  output: xmlDocPtr;
begin
  Result := XsltTransform(stylesheet, @Self, @Self, style, output, errorHandler);
  if Result then
  begin
    var Buffer := xmlOutputBufferCreateIO(@IOWriteStream, @IOCloseStream, Pointer(Stream), nil);
    if Buffer <> nil then
      xsltSaveResultTo(Buffer, output, style)
    else
      Result := False;
    xmlFreeDoc(output);
    xsltFreeStylesheet(style);
  end;
end;

function xmlDocHelper.ToBytes(const Encoding: string; const Format: Boolean): TBytes;
var
  Data: Pointer;
  Size: Integer;
begin
  var Args: TXmlArgs;
  xmlDocDumpFormatMemoryEnc(doc, Data, Size, Args.StrPtr(Encoding), Ord(Format));

  if (Data = nil) or (Size = 0) then
    Exit(nil);
  SetLength(Result, Size);
  Move(Data^, Pointer(Result)^, Size);

  XmlFree(Data);
end;

function xmlDocHelper.Save(const FileName: string; const Encoding: string; const Options: TxmlSaveOptions): Boolean;
begin
  var Args: TXmlArgs;
  var ctx := xmlSaveToFilename(Args.StrPtr(FileName), Args.StrPtr(Encoding), XmlSaveOptions(Options));
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
