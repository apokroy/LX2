# LX2
libxml2 and libxslt bindings to Delphi. Requeries version 2.14 or higher of libxml2 and 1.1 of libxslt. 

Contains:

- Pure interface to the API (libxml2.API.pas, libxslt.API.pas), with the possibility of late binding to library files that you specify or load with defaults.
- Provides a more convenient way to work with library, based on record helpers for native libxml types (LX2.Helpers.pas).
- Small, but convenient layer above the SAX parser (LX2.SAX.pas), that contains base SAX parser wrapper and more complex version, based on context handler interfaces, that near to MS XML SAX parser interfaces.
- DOM interfaces that are close to the W3C standards and the MSXML library (LX2.DOM).
- If you need it, binaries to Win64 & Linux in repository.
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


