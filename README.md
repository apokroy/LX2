# LX2
libxml2 and libxslt bindings to Delphi based on 2.14 version of libxml2 and 1.1.43 version of libxslt.

It contains pure interface to the API (libxml2.API.pas, libxslt.API.pas), with the possibility of late binding to library files that you specify or load with defaults.

In addition, it provides a more convenient way to work with library, based on record helpers for native libxml types (LX2.Helpers.pas).

Also, we have a small but convenient layer above the SAX parser (LX2.SAX.pas), that contains base SAX parser wrapper and more complex version, based on context handler interfaces, that near to MS XML SAX parser interfaces.

Finally, we can offer you DOM interfaces that are close to the W3C standards and the MSXML library (LX2.DOM).

>All API wrappers uses standard Delphi string type (UTF-16), but original UTF-8 encoding still accesible. 

## Initialize library
#### Sample

## LX2.Helpers
#### Sample
### Error handling
### xmlNodePtr
### xmlDocPtr
### xmlAttrPtr

## LX2.SAX
#### Sample
### TLX2SAXParserWrapper
### TSAXParser
### ISAXContentHandler
...

## LX2.DOM
#### Sample
### Interface list
- [LX2](#lx2)
  - [Initialize library](#initialize-library)
      - [Sample](#sample)
  - [LX2.Helpers](#lx2helpers)
      - [Sample](#sample-1)
    - [Error handling](#error-handling)
    - [xmlNodePtr](#xmlnodeptr)
    - [xmlDocPtr](#xmldocptr)
    - [xmlAttrPtr](#xmlattrptr)
  - [LX2.SAX](#lx2sax)
      - [Sample](#sample-2)
    - [TLX2SAXParserWrapper](#tlx2saxparserwrapper)
    - [TSAXParser](#tsaxparser)
    - [ISAXContentHandler](#isaxcontenthandler)
  - [LX2.DOM](#lx2dom)
      - [Sample](#sample-3)
    - [Interface list](#interface-list)
      - [IXMLEnumerator](#ixmlenumerator)
      - [IXMLError](#ixmlerror)
      - [IXMLErrors](#ixmlerrors)
      - [IXMLAttributesEnumerator](#ixmlattributesenumerator)
      - [IXMLNodeList](#ixmlnodelist)
      - [IXMLNamedNodeMap](#ixmlnamednodemap)
      - [IXMLAttributes](#ixmlattributes)
      - [IXMLNode](#ixmlnode)
      - [IXMLAttribute](#ixmlattribute)
      - [IXMLElement](#ixmlelement)
      - [IXMLDocumentFragment](#ixmldocumentfragment)
      - [IXMLDocumentType](#ixmldocumenttype)
      - [IXMLCharacterData](#ixmlcharacterdata)
      - [IXMLText](#ixmltext)
      - [IXMLCDATASection](#ixmlcdatasection)
      - [IXMLComment](#ixmlcomment)
      - [IXMLProcessingInstruction](#ixmlprocessinginstruction)
      - [IXMLEntityReference](#ixmlentityreference)
      - [IXMLSchemaCollection](#ixmlschemacollection)
      - [IXMLDocument](#ixmldocument)

#### IXMLEnumerator
#### IXMLError
#### IXMLErrors
#### IXMLAttributesEnumerator
#### IXMLNodeList
#### IXMLNamedNodeMap
#### IXMLAttributes
#### IXMLNode
#### IXMLAttribute
#### IXMLElement
#### IXMLDocumentFragment
#### IXMLDocumentType
#### IXMLCharacterData
#### IXMLText
#### IXMLCDATASection
#### IXMLComment
#### IXMLProcessingInstruction
#### IXMLEntityReference
#### IXMLSchemaCollection
#### IXMLDocument


