# LX2
Delphi bindings to [libxml2](https://gitlab.gnome.org/GNOME/libxml2) and [libxslt](https://gitlab.gnome.org/GNOME/libxslt/) libraries. 
Requeries version 2.14 or higher of libxml2 and 1.1 of libxslt. 

One of the most important goals of the project is the cross-platform replacement of MSXML 6.0. Therefore, where possible, the library should follow the W3C DOM model, but compatibility with MSXML is a priority.

Contains:

- Pure interface to the API (libxml2.API.pas, libxslt.API.pas), with the possibility of late binding to library files that you specify or load with defaults.
- Provides a more convenient way to work with library, based on record helpers for native libxml types (LX2.Helpers.pas).
- Small, but convenient layer above the SAX parser (LX2.SAX.pas), that contains base SAX parser wrapper and more complex version, based on context handler interfaces, that near to MS XML SAX parser interfaces.
- DOM interfaces that are close to the W3C standards and the MSXML library (LX2.DOM).
- If you need it, binaries for Win64 & Linux in repository.

> [!WARNING]
> A significant part of the library's code has been tested using synthetic tests, but has not yet been tested in production environment.
>
> Win32 not tested at all.

## TODOs
- XML Doc all significant sources;
- Reader API wrappers;

## Samples
All provided sample projects uses simple test API, that tracking libxml2 memory leaks and DOM interfaces refcounting errors, FastMM4 memory leaks detection also used.

## Initialize library
Before using the library, it must be initialized. You can specify which files will be used or use default settings.
You may load specific version: 
```delphi
LX2Lib.Load(FileName);
```
 or use defaults:
```delphi
LX2Lib.Initialize; 
```
Default names is libxml2.so.16 and libxml2.dll.

Initialization is not necessary for SAX or DOM interfaces, LX2Lib and XSLTLib will be initialized automatically, if they have not been loaded yet.
XSLTLib initialization called only when you use methods that need it, IXMLDocument.Transform for example.

## LX2.Types
Contains types common to all library units (except API wrapper units):
- Exception classes
- Delphi style enums
- Delphi style error classes
- Utility functions

## LX2.Helpers
Unit contains record helpers for libxml2 structures, that provides more "object oriented" style. Also adds support for some Delphi types, TStream for example.

Sample code:
```Delphi
var Doc := xmlDoc.CreateFromFile('C:\Test.xml', DefaultParserOptions); //Loads file to xmlDoc tree

WriteLn(Doc.ToString(True));     // Get formatted (True) XML as Delphi string (UTF16)

WriteLn(Doc.Canonicalized);      // Output canonicalized XML 

Doc.Save(MyStream, 'UTF-8'); // Saves XML to provided TStream object 

Doc.Free;                        // xmlFreeDoc(Doc);
```
For example xmlDoc.CreateFromFile wraps this code:
```Delphi
class function xmlDocHelper.CreateFromFile(const FileName: string; const Options: TXmlParserOptions; ErrorHandler: xmlDocErrorHandler = nil): xmlDocPtr;
var
  input: xmlParserInputPtr;
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

  xmlCtxtUseOptions(ctx, XmlParserOptions(Options));

  if xmlNewInputFromUrl(xmlCharPtr(Utf8Encode(filename)), XML_INPUT_BUF_STATIC, input) = XML_ERR_OK then
    Result := xmlCtxtParseDocument(ctx, input)
  else
    Result := nil;

  xmlFreeParserCtxt(ctx);
end;
```

#### Sample
- [Sample 1](/Samples/LX2SampleHelpers1.dpr) Load XML from string, output result, formatted output, canonicalization.
- [Sample 2](/Samples/LX2SampleHelpers2.dpr) XSLT Transform sample.
- [Sample 3](/Samples/LX2SampleHelpers3.dpr) Traverse nodes.
- [Sample 4](/Samples/LX2SampleHelpers4.dpr) Create tree from code.
### Error handling
### xmlNodePtr
### xmlDocPtr
### xmlAttrPtr

## LX2.SAX
#### Sample
- [Sample 1](/Samples/LX2SampleSAX1.dpr) SAX Handler that log all calls.
### TLX2SAXParserWrapper
### TSAXParser
### ISAXContentHandler
...

## LX2.DOM
#### Sample
- [Sample 1](/Samples/LX2SampleDOM1.dpr) Load XML from string, modify tree, formatted output.
- [Sample 2](/Samples/LX2SampleDOM2.dpr) DOM Collections.
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


