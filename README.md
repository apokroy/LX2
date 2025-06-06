# LX2
Delphi bindings to [libxml2](https://gitlab.gnome.org/GNOME/libxml2) and [libxslt](https://gitlab.gnome.org/GNOME/libxslt/) libraries. 
Requeries version 2.14 or higher of libxml2 and 1.1 of libxslt. 

Contains:

- Pure interface to the API (libxml2.API.pas, libxslt.API.pas), with the possibility of late binding to library files that you specify or load with defaults.
- Provides a more convenient way to work with library, based on record helpers for native libxml types (LX2.Helpers.pas).
- Small, but convenient layer above the SAX parser (LX2.SAX.pas), that contains base SAX parser wrapper and more complex version, based on context handler interfaces, that near to MS XML SAX parser interfaces.
- DOM interfaces that are close to the W3C standards and the MSXML library (LX2.DOM).
- If you need it, binaries to Win64 & Linux in repository.
>All API wrappers uses standard Delphi string type (UTF-16), but original UTF-8 encoding still accesible. 

## Initialize library
Before using the library, it must be initialized. You can specify which files will be used or use default settings.
You may call to load specific version: 
```delphi
LX2Lib.Load(FileName);
```
 or to use defaults:
```delphi
LX2Lib.Initialize; 
```
Default names is libxml2.so.16 and libxml2.dll.

Initialization is not necessary if you use SAX or DOM interfaces, LX2Lib and XSLTLib will be initialized automatically if they have not been loaded yet.
XSLTLib initialization called only when you use methods that need it, IXMLDocument.Transform for example.

## LX2.Types

## LX2.Helpers
#### Sample
- [Sample 1](/Samples/LX2SampleHelpers1.dproj) Load XML from string, output result, formatted output, canonicalization.
### Error handling
### xmlNodePtr
### xmlDocPtr
### xmlAttrPtr

## LX2.SAX
#### Sample
- [Sample 2](/Samples/LX2SampleSAX.dproj) SAX Handler that log all calls.
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


