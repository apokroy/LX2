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


///This file contains translation of libxml2 header files, libxml2 license:
/// see https://gitlab.gnome.org/GNOME/libxml2/-/blob/master/Copyright?ref_type=heads

/// <summary>
/// <para>
/// This Unit provides full access to the libxml2 API (based on libxml2 version 2.15), except for some functions and headers marked as deprecated or candidates for removal in future versions. For example, Schematron are not imported.
/// </para>
/// <para>
/// Also, auxiliary functions are not included, such as working with streams, strings, and regular expressions, if they are not required for XML processing functions and/or have direct analogues in Delphi RTL.
/// All definitions described as outdated but left in the library are marked as DEPRECATED with a corresponding comment.
/// Also generic error handling not supported, use Structured Errors instead.
/// </para>
/// <para>
/// All (not all at this momemt) definitions are commented based on the official libxml2 documentation and comments in the source library
/// and are available in Code Hints directly from the Delphi code editor.
/// You can also build an XML Help using the built-in Delphi tools.
/// (btw this documentation not always helpfull)))
/// </para>
/// <para>
/// Precomplied binaries: libxml2.dll (statically linked with ICONV, ZLib, XZ), and libxml2.so.16 present in project repository
///
/// </para>
///</summary>
unit libxml2.API;

interface

{$ALIGN 8}
{$MINENUMSIZE 4}

uses
  {$IFDEF MSWINDOWS}
    Winapi.Windows,
  {$ENDIF}
  {$IFDEF POSIX}
    Posix.StdDef,
  {$ENDIF}
  System.Types, System.SysUtils;

const
  {$IFDEF MSWINDOWS}
  libxml2 = 'libxml2.dll';
  {$ENDIF}
  {$IFDEF POSIX}
  libxml2 = 'libxml2.so.16';
  {$ENDIF}

type
  LX2Lib = record
  private class var
    FIsLoaded: Boolean;
    FLibraryFileName: string;
    Handle: THandle;
  public
    class procedure Initialize; static;
    class procedure Load(const LibraryFileName: string = libxml2); static;
    class procedure Unload; static;
    class property IsLoaded: Boolean read FIsLoaded;
    class property LibraryFileName: string read FLibraryFileName;
  end;

type
  ulong = type LongWord;
  long  = type LongInt;
  uint  = type Cardinal;

const
  XML_SAX2_MAGIC = $DEEDBEAF;

type
  xmlChar    = UTF8Char;
  xmlCharPtr = PUTF8Char;
  xmlEnumSet = UInt32;

  xmlCharPtrArrayPtr = ^xmlCharPtrArray;
  xmlCharPtrArray = array[0..0] of xmlCharPtr;

  { Forward declarations }

  ///<summary>An xmlValidCtxt is used for error reporting when validating</summary>
  xmlValidCtxtPtr = ^xmlValidCtxt;
  xmlValidCtxt = record end;

{$region 'xmlerror.h'}

type
  ///<summary>Indicates the level of an error.</summary>
  xmlErrorLevel = (
    ///<summary>Success</summary>
    XML_ERR_NONE    = 0,
    ///<summary>A simple warning</summary>
    XML_ERR_WARNING = 1,
    ///<summary>A recoverable error (namespace and validity errors, certain undeclared entities) </summary>
    XML_ERR_ERROR   = 2,
    ///<summary>A fatal error (not well-formed, OOM and I/O errors) </summary>
    XML_ERR_FATAL   = 3
  );

  ///<summary>Indicates where an error may have come from. </summary>
  xmlErrorDomain = (
    ///<summary>Unknown</summary>
    XML_FROM_NONE = 0,
    ///<summary>The XML parser</summary>
    XML_FROM_PARSER,
    ///<summary>The tree module</summary>
    ///<remarks>unused</remarks>
    XML_FROM_TREE,
    ///<summary>The XML Namespace module</summary>
    XML_FROM_NAMESPACE,
    ///<summary>The XML DTD validation with parser context</summary>
    XML_FROM_DTD,
    ///<summary>The HTML parser</summary>
    XML_FROM_HTML,
    ///<summary>The memory allocator</summary>
    ///<remarks>unused</remarks>
    XML_FROM_MEMORY,
    ///<summary>The serialization code</summary>
    XML_FROM_OUTPUT,
    ///<summary> The Input/Output stack</summary>
    XML_FROM_IO,
    ///<summary>The FTP module</summary>
    ///<remarks>unused</remarks>
    XML_FROM_FTP,
    ///<summary>The HTTP module</summary>
    ///<remarks>unused</remarks>
    XML_FROM_HTTP,
    ///<summary>The XInclude processing</summary>
    XML_FROM_XINCLUDE,
    ///<summary>The XPath module</summary>
    XML_FROM_XPATH,
    ///<summary>The XPointer module</summary>
    XML_FROM_XPOINTER,
    ///<summary>The regular expressions module</summary>
    XML_FROM_REGEXP,
    ///<summary>The W3C XML Schemas Datatype module</summary>
    XML_FROM_DATATYPE,
    ///<summary>The W3C XML Schemas parser module</summary>
    XML_FROM_SCHEMASP,
    ///<summary>The W3C XML Schemas validation module</summary>
    XML_FROM_SCHEMASV,
    ///<summary>The Relax-NG parser module</summary>
    XML_FROM_RELAXNGP,
    ///<summary>The Relax-NG validator module</summary>
    XML_FROM_RELAXNGV,
    ///<summary>The Catalog module</summary>
    XML_FROM_CATALOG,
    ///<summary>The Canonicalization module</summary>
    XML_FROM_C14N,
    ///<summary>The XSLT engine from libxslt</summary>
    XML_FROM_XSLT,
    ///<summary>The XML DTD validation with valid context</summary>
    XML_FROM_VALID,
    ///<summary>The error checking module</summary>
    XML_FROM_CHECK,
    ///<summary>The xmlwriter module</summary>
    XML_FROM_WRITER,
    ///<summary>The dynamically loaded module module</summary>
    XML_FROM_MODULE,
    ///<summary>The module handling character conversion</summary>
    XML_FROM_I18N,
    ///<summary>The Schematron validator module</summary>
    XML_FROM_SCHEMATRONV,
    ///<summary>The buffers module</summary>
    XML_FROM_BUFFER,
    ///<summary>The URI module</summary>
    XML_FROM_URI
  );

  ///<summary>Error codes</summary>
  xmlParserErrors = (
    ///<summary>Success</summary>
    XML_ERR_OK = 0,
    XML_ERR_INTERNAL_ERROR, { 1 }
    XML_ERR_NO_MEMORY, { 2 }
    XML_ERR_DOCUMENT_START, { 3 }
    XML_ERR_DOCUMENT_EMPTY, { 4 }
    XML_ERR_DOCUMENT_END, { 5 }
    XML_ERR_INVALID_HEX_CHARREF, { 6 }
    XML_ERR_INVALID_DEC_CHARREF, { 7 }
    XML_ERR_INVALID_CHARREF, { 8 }
    XML_ERR_INVALID_CHAR, { 9 }
    XML_ERR_CHARREF_AT_EOF, { 10 }
    XML_ERR_CHARREF_IN_PROLOG, { 11 }
    XML_ERR_CHARREF_IN_EPILOG, { 12 }
    XML_ERR_CHARREF_IN_DTD, { 13 }
    XML_ERR_ENTITYREF_AT_EOF, { 14 }
    XML_ERR_ENTITYREF_IN_PROLOG, { 15 }
    XML_ERR_ENTITYREF_IN_EPILOG, { 16 }
    XML_ERR_ENTITYREF_IN_DTD, { 17 }
    XML_ERR_PEREF_AT_EOF, { 18 }
    XML_ERR_PEREF_IN_PROLOG, { 19 }
    XML_ERR_PEREF_IN_EPILOG, { 20 }
    XML_ERR_PEREF_IN_INT_SUBSET, { 21 }
    XML_ERR_ENTITYREF_NO_NAME, { 22 }
    XML_ERR_ENTITYREF_SEMICOL_MISSING, { 23 }
    XML_ERR_PEREF_NO_NAME, { 24 }
    XML_ERR_PEREF_SEMICOL_MISSING, { 25 }
    XML_ERR_UNDECLARED_ENTITY, { 26 }
    XML_WAR_UNDECLARED_ENTITY, { 27 }
    XML_ERR_UNPARSED_ENTITY, { 28 }
    XML_ERR_ENTITY_IS_EXTERNAL, { 29 }
    XML_ERR_ENTITY_IS_PARAMETER, { 30 }
    XML_ERR_UNKNOWN_ENCODING, { 31 }
    XML_ERR_UNSUPPORTED_ENCODING, { 32 }
    XML_ERR_STRING_NOT_STARTED, { 33 }
    XML_ERR_STRING_NOT_CLOSED, { 34 }
    XML_ERR_NS_DECL_ERROR, { 35 }
    XML_ERR_ENTITY_NOT_STARTED, { 36 }
    XML_ERR_ENTITY_NOT_FINISHED, { 37 }
    XML_ERR_LT_IN_ATTRIBUTE, { 38 }
    XML_ERR_ATTRIBUTE_NOT_STARTED, { 39 }
    XML_ERR_ATTRIBUTE_NOT_FINISHED, { 40 }
    XML_ERR_ATTRIBUTE_WITHOUT_VALUE, { 41 }
    XML_ERR_ATTRIBUTE_REDEFINED, { 42 }
    XML_ERR_LITERAL_NOT_STARTED, { 43 }
    XML_ERR_LITERAL_NOT_FINISHED, { 44 }
    XML_ERR_COMMENT_NOT_FINISHED, { 45 }
    XML_ERR_PI_NOT_STARTED, { 46 }
    XML_ERR_PI_NOT_FINISHED, { 47 }
    XML_ERR_NOTATION_NOT_STARTED, { 48 }
    XML_ERR_NOTATION_NOT_FINISHED, { 49 }
    XML_ERR_ATTLIST_NOT_STARTED, { 50 }
    XML_ERR_ATTLIST_NOT_FINISHED, { 51 }
    XML_ERR_MIXED_NOT_STARTED, { 52 }
    XML_ERR_MIXED_NOT_FINISHED, { 53 }
    XML_ERR_ELEMCONTENT_NOT_STARTED, { 54 }
    XML_ERR_ELEMCONTENT_NOT_FINISHED, { 55 }
    XML_ERR_XMLDECL_NOT_STARTED, { 56 }
    XML_ERR_XMLDECL_NOT_FINISHED, { 57 }
    XML_ERR_CONDSEC_NOT_STARTED, { 58 }
    XML_ERR_CONDSEC_NOT_FINISHED, { 59 }
    XML_ERR_EXT_SUBSET_NOT_FINISHED, { 60 }
    XML_ERR_DOCTYPE_NOT_FINISHED, { 61 }
    XML_ERR_MISPLACED_CDATA_END, { 62 }
    XML_ERR_CDATA_NOT_FINISHED, { 63 }
    XML_ERR_RESERVED_XML_NAME, { 64 }
    XML_ERR_SPACE_REQUIRED, { 65 }
    XML_ERR_SEPARATOR_REQUIRED, { 66 }
    XML_ERR_NMTOKEN_REQUIRED, { 67 }
    XML_ERR_NAME_REQUIRED, { 68 }
    XML_ERR_PCDATA_REQUIRED, { 69 }
    XML_ERR_URI_REQUIRED, { 70 }
    XML_ERR_PUBID_REQUIRED, { 71 }
    XML_ERR_LT_REQUIRED, { 72 }
    XML_ERR_GT_REQUIRED, { 73 }
    XML_ERR_LTSLASH_REQUIRED, { 74 }
    XML_ERR_EQUAL_REQUIRED, { 75 }
    XML_ERR_TAG_NAME_MISMATCH, { 76 }
    XML_ERR_TAG_NOT_FINISHED, { 77 }
    XML_ERR_STANDALONE_VALUE, { 78 }
    XML_ERR_ENCODING_NAME, { 79 }
    XML_ERR_HYPHEN_IN_COMMENT, { 80 }
    XML_ERR_INVALID_ENCODING, { 81 }
    XML_ERR_EXT_ENTITY_STANDALONE, { 82 }
    XML_ERR_CONDSEC_INVALID, { 83 }
    XML_ERR_VALUE_REQUIRED, { 84 }
    XML_ERR_NOT_WELL_BALANCED, { 85 }
    XML_ERR_EXTRA_CONTENT, { 86 }
    XML_ERR_ENTITY_CHAR_ERROR, { 87 }
    XML_ERR_ENTITY_PE_INTERNAL, { 88 }
    XML_ERR_ENTITY_LOOP, { 89 }
    XML_ERR_ENTITY_BOUNDARY, { 90 }
    XML_ERR_INVALID_URI, { 91 }
    XML_ERR_URI_FRAGMENT, { 92 }
    XML_WAR_CATALOG_PI, { 93 }
    XML_ERR_NO_DTD, { 94 }
    XML_ERR_CONDSEC_INVALID_KEYWORD, { 95 }
    XML_ERR_VERSION_MISSING, { 96 }
    XML_WAR_UNKNOWN_VERSION, { 97 }
    XML_WAR_LANG_VALUE, { 98 }
    XML_WAR_NS_URI, { 99 }
    XML_WAR_NS_URI_RELATIVE, { 100 }
    XML_ERR_MISSING_ENCODING, { 101 }
    XML_WAR_SPACE_VALUE, { 102 }
    XML_ERR_NOT_STANDALONE, { 103 }
    XML_ERR_ENTITY_PROCESSING, { 104 }
    XML_ERR_NOTATION_PROCESSING, { 105 }
    XML_WAR_NS_COLUMN, { 106 }
    XML_WAR_ENTITY_REDEFINED, { 107 }
    XML_ERR_UNKNOWN_VERSION, { 108 }
    XML_ERR_VERSION_MISMATCH, { 109 }
    XML_ERR_NAME_TOO_LONG, { 110 }
    XML_ERR_USER_STOP, { 111 }
    XML_ERR_COMMENT_ABRUPTLY_ENDED, { 112 }
    XML_WAR_ENCODING_MISMATCH, { 113 }
    XML_ERR_RESOURCE_LIMIT, { 114 }
    XML_ERR_ARGUMENT, { 115 }
    XML_ERR_SYSTEM, { 116 }
    XML_ERR_REDECL_PREDEF_ENTITY, { 117 }
    XML_ERR_INT_SUBSET_NOT_FINISHED, { 118 }
    XML_NS_ERR_XML_NAMESPACE = 200,
    XML_NS_ERR_UNDEFINED_NAMESPACE, { 201 }
    XML_NS_ERR_QNAME, { 202 }
    XML_NS_ERR_ATTRIBUTE_REDEFINED, { 203 }
    XML_NS_ERR_EMPTY, { 204 }
    XML_NS_ERR_COLON, { 205 }
    XML_DTD_ATTRIBUTE_DEFAULT = 500,
    XML_DTD_ATTRIBUTE_REDEFINED, { 501 }
    XML_DTD_ATTRIBUTE_VALUE, { 502 }
    XML_DTD_CONTENT_ERROR, { 503 }
    XML_DTD_CONTENT_MODEL, { 504 }
    XML_DTD_CONTENT_NOT_DETERMINIST, { 505 }
    XML_DTD_DIFFERENT_PREFIX, { 506 }
    XML_DTD_ELEM_DEFAULT_NAMESPACE, { 507 }
    XML_DTD_ELEM_NAMESPACE, { 508 }
    XML_DTD_ELEM_REDEFINED, { 509 }
    XML_DTD_EMPTY_NOTATION, { 510 }
    XML_DTD_ENTITY_TYPE, { 511 }
    XML_DTD_ID_FIXED, { 512 }
    XML_DTD_ID_REDEFINED, { 513 }
    XML_DTD_ID_SUBSET, { 514 }
    XML_DTD_INVALID_CHILD, { 515 }
    XML_DTD_INVALID_DEFAULT, { 516 }
    XML_DTD_LOAD_ERROR, { 517 }
    XML_DTD_MISSING_ATTRIBUTE, { 518 }
    XML_DTD_MIXED_CORRUPT, { 519 }
    XML_DTD_MULTIPLE_ID, { 520 }
    XML_DTD_NO_DOC, { 521 }
    XML_DTD_NO_DTD, { 522 }
    XML_DTD_NO_ELEM_NAME, { 523 }
    XML_DTD_NO_PREFIX, { 524 }
    XML_DTD_NO_ROOT, { 525 }
    XML_DTD_NOTATION_REDEFINED, { 526 }
    XML_DTD_NOTATION_VALUE, { 527 }
    XML_DTD_NOT_EMPTY, { 528 }
    XML_DTD_NOT_PCDATA, { 529 }
    XML_DTD_NOT_STANDALONE, { 530 }
    XML_DTD_ROOT_NAME, { 531 }
    XML_DTD_STANDALONE_WHITE_SPACE, { 532 }
    XML_DTD_UNKNOWN_ATTRIBUTE, { 533 }
    XML_DTD_UNKNOWN_ELEM, { 534 }
    XML_DTD_UNKNOWN_ENTITY, { 535 }
    XML_DTD_UNKNOWN_ID, { 536 }
    XML_DTD_UNKNOWN_NOTATION, { 537 }
    XML_DTD_STANDALONE_DEFAULTED, { 538 }
    XML_DTD_XMLID_VALUE, { 539 }
    XML_DTD_XMLID_TYPE, { 540 }
    XML_DTD_DUP_TOKEN, { 541 }
    XML_HTML_STRUCURE_ERROR = 800,
    XML_HTML_UNKNOWN_TAG, { 801 }
    XML_HTML_INCORRECTLY_OPENED_COMMENT, { 802 }
    XML_RNGP_ANYNAME_ATTR_ANCESTOR = 1000,
    XML_RNGP_ATTR_CONFLICT, { 1001 }
    XML_RNGP_ATTRIBUTE_CHILDREN, { 1002 }
    XML_RNGP_ATTRIBUTE_CONTENT, { 1003 }
    XML_RNGP_ATTRIBUTE_EMPTY, { 1004 }
    XML_RNGP_ATTRIBUTE_NOOP, { 1005 }
    XML_RNGP_CHOICE_CONTENT, { 1006 }
    XML_RNGP_CHOICE_EMPTY, { 1007 }
    XML_RNGP_CREATE_FAILURE, { 1008 }
    XML_RNGP_DATA_CONTENT, { 1009 }
    XML_RNGP_DEF_CHOICE_AND_INTERLEAVE, { 1010 }
    XML_RNGP_DEFINE_CREATE_FAILED, { 1011 }
    XML_RNGP_DEFINE_EMPTY, { 1012 }
    XML_RNGP_DEFINE_MISSING, { 1013 }
    XML_RNGP_DEFINE_NAME_MISSING, { 1014 }
    XML_RNGP_ELEM_CONTENT_EMPTY, { 1015 }
    XML_RNGP_ELEM_CONTENT_ERROR, { 1016 }
    XML_RNGP_ELEMENT_EMPTY, { 1017 }
    XML_RNGP_ELEMENT_CONTENT, { 1018 }
    XML_RNGP_ELEMENT_NAME, { 1019 }
    XML_RNGP_ELEMENT_NO_CONTENT, { 1020 }
    XML_RNGP_ELEM_TEXT_CONFLICT, { 1021 }
    XML_RNGP_EMPTY, { 1022 }
    XML_RNGP_EMPTY_CONSTRUCT, { 1023 }
    XML_RNGP_EMPTY_CONTENT, { 1024 }
    XML_RNGP_EMPTY_NOT_EMPTY, { 1025 }
    XML_RNGP_ERROR_TYPE_LIB, { 1026 }
    XML_RNGP_EXCEPT_EMPTY, { 1027 }
    XML_RNGP_EXCEPT_MISSING, { 1028 }
    XML_RNGP_EXCEPT_MULTIPLE, { 1029 }
    XML_RNGP_EXCEPT_NO_CONTENT, { 1030 }
    XML_RNGP_EXTERNALREF_EMTPY, { 1031 }
    XML_RNGP_EXTERNAL_REF_FAILURE, { 1032 }
    XML_RNGP_EXTERNALREF_RECURSE, { 1033 }
    XML_RNGP_FORBIDDEN_ATTRIBUTE, { 1034 }
    XML_RNGP_FOREIGN_ELEMENT, { 1035 }
    XML_RNGP_GRAMMAR_CONTENT, { 1036 }
    XML_RNGP_GRAMMAR_EMPTY, { 1037 }
    XML_RNGP_GRAMMAR_MISSING, { 1038 }
    XML_RNGP_GRAMMAR_NO_START, { 1039 }
    XML_RNGP_GROUP_ATTR_CONFLICT, { 1040 }
    XML_RNGP_HREF_ERROR, { 1041 }
    XML_RNGP_INCLUDE_EMPTY, { 1042 }
    XML_RNGP_INCLUDE_FAILURE, { 1043 }
    XML_RNGP_INCLUDE_RECURSE, { 1044 }
    XML_RNGP_INTERLEAVE_ADD, { 1045 }
    XML_RNGP_INTERLEAVE_CREATE_FAILED, { 1046 }
    XML_RNGP_INTERLEAVE_EMPTY, { 1047 }
    XML_RNGP_INTERLEAVE_NO_CONTENT, { 1048 }
    XML_RNGP_INVALID_DEFINE_NAME, { 1049 }
    XML_RNGP_INVALID_URI, { 1050 }
    XML_RNGP_INVALID_VALUE, { 1051 }
    XML_RNGP_MISSING_HREF, { 1052 }
    XML_RNGP_NAME_MISSING, { 1053 }
    XML_RNGP_NEED_COMBINE, { 1054 }
    XML_RNGP_NOTALLOWED_NOT_EMPTY, { 1055 }
    XML_RNGP_NSNAME_ATTR_ANCESTOR, { 1056 }
    XML_RNGP_NSNAME_NO_NS, { 1057 }
    XML_RNGP_PARAM_FORBIDDEN, { 1058 }
    XML_RNGP_PARAM_NAME_MISSING, { 1059 }
    XML_RNGP_PARENTREF_CREATE_FAILED, { 1060 }
    XML_RNGP_PARENTREF_NAME_INVALID, { 1061 }
    XML_RNGP_PARENTREF_NO_NAME, { 1062 }
    XML_RNGP_PARENTREF_NO_PARENT, { 1063 }
    XML_RNGP_PARENTREF_NOT_EMPTY, { 1064 }
    XML_RNGP_PARSE_ERROR, { 1065 }
    XML_RNGP_PAT_ANYNAME_EXCEPT_ANYNAME, { 1066 }
    XML_RNGP_PAT_ATTR_ATTR, { 1067 }
    XML_RNGP_PAT_ATTR_ELEM, { 1068 }
    XML_RNGP_PAT_DATA_EXCEPT_ATTR, { 1069 }
    XML_RNGP_PAT_DATA_EXCEPT_ELEM, { 1070 }
    XML_RNGP_PAT_DATA_EXCEPT_EMPTY, { 1071 }
    XML_RNGP_PAT_DATA_EXCEPT_GROUP, { 1072 }
    XML_RNGP_PAT_DATA_EXCEPT_INTERLEAVE, { 1073 }
    XML_RNGP_PAT_DATA_EXCEPT_LIST, { 1074 }
    XML_RNGP_PAT_DATA_EXCEPT_ONEMORE, { 1075 }
    XML_RNGP_PAT_DATA_EXCEPT_REF, { 1076 }
    XML_RNGP_PAT_DATA_EXCEPT_TEXT, { 1077 }
    XML_RNGP_PAT_LIST_ATTR, { 1078 }
    XML_RNGP_PAT_LIST_ELEM, { 1079 }
    XML_RNGP_PAT_LIST_INTERLEAVE, { 1080 }
    XML_RNGP_PAT_LIST_LIST, { 1081 }
    XML_RNGP_PAT_LIST_REF, { 1082 }
    XML_RNGP_PAT_LIST_TEXT, { 1083 }
    XML_RNGP_PAT_NSNAME_EXCEPT_ANYNAME, { 1084 }
    XML_RNGP_PAT_NSNAME_EXCEPT_NSNAME, { 1085 }
    XML_RNGP_PAT_ONEMORE_GROUP_ATTR, { 1086 }
    XML_RNGP_PAT_ONEMORE_INTERLEAVE_ATTR, { 1087 }
    XML_RNGP_PAT_START_ATTR, { 1088 }
    XML_RNGP_PAT_START_DATA, { 1089 }
    XML_RNGP_PAT_START_EMPTY, { 1090 }
    XML_RNGP_PAT_START_GROUP, { 1091 }
    XML_RNGP_PAT_START_INTERLEAVE, { 1092 }
    XML_RNGP_PAT_START_LIST, { 1093 }
    XML_RNGP_PAT_START_ONEMORE, { 1094 }
    XML_RNGP_PAT_START_TEXT, { 1095 }
    XML_RNGP_PAT_START_VALUE, { 1096 }
    XML_RNGP_PREFIX_UNDEFINED, { 1097 }
    XML_RNGP_REF_CREATE_FAILED, { 1098 }
    XML_RNGP_REF_CYCLE, { 1099 }
    XML_RNGP_REF_NAME_INVALID, { 1100 }
    XML_RNGP_REF_NO_DEF, { 1101 }
    XML_RNGP_REF_NO_NAME, { 1102 }
    XML_RNGP_REF_NOT_EMPTY, { 1103 }
    XML_RNGP_START_CHOICE_AND_INTERLEAVE, { 1104 }
    XML_RNGP_START_CONTENT, { 1105 }
    XML_RNGP_START_EMPTY, { 1106 }
    XML_RNGP_START_MISSING, { 1107 }
    XML_RNGP_TEXT_EXPECTED, { 1108 }
    XML_RNGP_TEXT_HAS_CHILD, { 1109 }
    XML_RNGP_TYPE_MISSING, { 1110 }
    XML_RNGP_TYPE_NOT_FOUND, { 1111 }
    XML_RNGP_TYPE_VALUE, { 1112 }
    XML_RNGP_UNKNOWN_ATTRIBUTE, { 1113 }
    XML_RNGP_UNKNOWN_COMBINE, { 1114 }
    XML_RNGP_UNKNOWN_CONSTRUCT, { 1115 }
    XML_RNGP_UNKNOWN_TYPE_LIB, { 1116 }
    XML_RNGP_URI_FRAGMENT, { 1117 }
    XML_RNGP_URI_NOT_ABSOLUTE, { 1118 }
    XML_RNGP_VALUE_EMPTY, { 1119 }
    XML_RNGP_VALUE_NO_CONTENT, { 1120 }
    XML_RNGP_XMLNS_NAME, { 1121 }
    XML_RNGP_XML_NS, { 1122 }
    XML_XPATH_EXPRESSION_OK = 1200,
    XML_XPATH_NUMBER_ERROR, { 1201 }
    XML_XPATH_UNFINISHED_LITERAL_ERROR, { 1202 }
    XML_XPATH_START_LITERAL_ERROR, { 1203 }
    XML_XPATH_VARIABLE_REF_ERROR, { 1204 }
    XML_XPATH_UNDEF_VARIABLE_ERROR, { 1205 }
    XML_XPATH_INVALID_PREDICATE_ERROR, { 1206 }
    XML_XPATH_EXPR_ERROR, { 1207 }
    XML_XPATH_UNCLOSED_ERROR, { 1208 }
    XML_XPATH_UNKNOWN_FUNC_ERROR, { 1209 }
    XML_XPATH_INVALID_OPERAND, { 1210 }
    XML_XPATH_INVALID_TYPE, { 1211 }
    XML_XPATH_INVALID_ARITY, { 1212 }
    XML_XPATH_INVALID_CTXT_SIZE, { 1213 }
    XML_XPATH_INVALID_CTXT_POSITION, { 1214 }
    XML_XPATH_MEMORY_ERROR, { 1215 }
    XML_XPTR_SYNTAX_ERROR, { 1216 }
    XML_XPTR_RESOURCE_ERROR, { 1217 }
    XML_XPTR_SUB_RESOURCE_ERROR, { 1218 }
    XML_XPATH_UNDEF_PREFIX_ERROR, { 1219 }
    XML_XPATH_ENCODING_ERROR, { 1220 }
    XML_XPATH_INVALID_CHAR_ERROR, { 1221 }
    XML_TREE_INVALID_HEX = 1300,
    XML_TREE_INVALID_DEC, { 1301 }
    XML_TREE_UNTERMINATED_ENTITY, { 1302 }
    XML_TREE_NOT_UTF8, { 1303 }
    XML_SAVE_NOT_UTF8 = 1400,
    XML_SAVE_CHAR_INVALID, { 1401 }
    XML_SAVE_NO_DOCTYPE, { 1402 }
    XML_SAVE_UNKNOWN_ENCODING, { 1403 }
    XML_REGEXP_COMPILE_ERROR = 1450,
    XML_IO_UNKNOWN = 1500,
    XML_IO_EACCES, { 1501 }
    XML_IO_EAGAIN, { 1502 }
    XML_IO_EBADF, { 1503 }
    XML_IO_EBADMSG, { 1504 }
    XML_IO_EBUSY, { 1505 }
    XML_IO_ECANCELED, { 1506 }
    XML_IO_ECHILD, { 1507 }
    XML_IO_EDEADLK, { 1508 }
    XML_IO_EDOM, { 1509 }
    XML_IO_EEXIST, { 1510 }
    XML_IO_EFAULT, { 1511 }
    XML_IO_EFBIG, { 1512 }
    XML_IO_EINPROGRESS, { 1513 }
    XML_IO_EINTR, { 1514 }
    XML_IO_EINVAL, { 1515 }
    XML_IO_EIO, { 1516 }
    XML_IO_EISDIR, { 1517 }
    XML_IO_EMFILE, { 1518 }
    XML_IO_EMLINK, { 1519 }
    XML_IO_EMSGSIZE, { 1520 }
    XML_IO_ENAMETOOLONG, { 1521 }
    XML_IO_ENFILE, { 1522 }
    XML_IO_ENODEV, { 1523 }
    XML_IO_ENOENT, { 1524 }
    XML_IO_ENOEXEC, { 1525 }
    XML_IO_ENOLCK, { 1526 }
    XML_IO_ENOMEM, { 1527 }
    XML_IO_ENOSPC, { 1528 }
    XML_IO_ENOSYS, { 1529 }
    XML_IO_ENOTDIR, { 1530 }
    XML_IO_ENOTEMPTY, { 1531 }
    XML_IO_ENOTSUP, { 1532 }
    XML_IO_ENOTTY, { 1533 }
    XML_IO_ENXIO, { 1534 }
    XML_IO_EPERM, { 1535 }
    XML_IO_EPIPE, { 1536 }
    XML_IO_ERANGE, { 1537 }
    XML_IO_EROFS, { 1538 }
    XML_IO_ESPIPE, { 1539 }
    XML_IO_ESRCH, { 1540 }
    XML_IO_ETIMEDOUT, { 1541 }
    XML_IO_EXDEV, { 1542 }
    XML_IO_NETWORK_ATTEMPT, { 1543 }
    XML_IO_ENCODER, { 1544 }
    XML_IO_FLUSH, { 1545 }
    XML_IO_WRITE, { 1546 }
    XML_IO_NO_INPUT, { 1547 }
    XML_IO_BUFFER_FULL, { 1548 }
    XML_IO_LOAD_ERROR, { 1549 }
    XML_IO_ENOTSOCK, { 1550 }
    XML_IO_EISCONN, { 1551 }
    XML_IO_ECONNREFUSED, { 1552 }
    XML_IO_ENETUNREACH, { 1553 }
    XML_IO_EADDRINUSE, { 1554 }
    XML_IO_EALREADY, { 1555 }
    XML_IO_EAFNOSUPPORT, { 1556 }
    XML_IO_UNSUPPORTED_PROTOCOL, { 1557 }
    XML_XINCLUDE_RECURSION=1600,
    XML_XINCLUDE_PARSE_VALUE, { 1601 }
    XML_XINCLUDE_ENTITY_DEF_MISMATCH, { 1602 }
    XML_XINCLUDE_NO_HREF, { 1603 }
    XML_XINCLUDE_NO_FALLBACK, { 1604 }
    XML_XINCLUDE_HREF_URI, { 1605 }
    XML_XINCLUDE_TEXT_FRAGMENT, { 1606 }
    XML_XINCLUDE_TEXT_DOCUMENT, { 1607 }
    XML_XINCLUDE_INVALID_CHAR, { 1608 }
    XML_XINCLUDE_BUILD_FAILED, { 1609 }
    XML_XINCLUDE_UNKNOWN_ENCODING, { 1610 }
    XML_XINCLUDE_MULTIPLE_ROOT, { 1611 }
    XML_XINCLUDE_XPTR_FAILED, { 1612 }
    XML_XINCLUDE_XPTR_RESULT, { 1613 }
    XML_XINCLUDE_INCLUDE_IN_INCLUDE, { 1614 }
    XML_XINCLUDE_FALLBACKS_IN_INCLUDE, { 1615 }
    XML_XINCLUDE_FALLBACK_NOT_IN_INCLUDE, { 1616 }
    XML_XINCLUDE_DEPRECATED_NS, { 1617 }
    XML_XINCLUDE_FRAGMENT_ID, { 1618 }
    XML_CATALOG_MISSING_ATTR = 1650,
    XML_CATALOG_ENTRY_BROKEN, { 1651 }
    XML_CATALOG_PREFER_VALUE, { 1652 }
    XML_CATALOG_NOT_CATALOG, { 1653 }
    XML_CATALOG_RECURSION, { 1654 }
    XML_SCHEMAP_PREFIX_UNDEFINED = 1700,
    XML_SCHEMAP_ATTRFORMDEFAULT_VALUE, { 1701 }
    XML_SCHEMAP_ATTRGRP_NONAME_NOREF, { 1702 }
    XML_SCHEMAP_ATTR_NONAME_NOREF, { 1703 }
    XML_SCHEMAP_COMPLEXTYPE_NONAME_NOREF, { 1704 }
    XML_SCHEMAP_ELEMFORMDEFAULT_VALUE, { 1705 }
    XML_SCHEMAP_ELEM_NONAME_NOREF, { 1706 }
    XML_SCHEMAP_EXTENSION_NO_BASE, { 1707 }
    XML_SCHEMAP_FACET_NO_VALUE, { 1708 }
    XML_SCHEMAP_FAILED_BUILD_IMPORT, { 1709 }
    XML_SCHEMAP_GROUP_NONAME_NOREF, { 1710 }
    XML_SCHEMAP_IMPORT_NAMESPACE_NOT_URI, { 1711 }
    XML_SCHEMAP_IMPORT_REDEFINE_NSNAME, { 1712 }
    XML_SCHEMAP_IMPORT_SCHEMA_NOT_URI, { 1713 }
    XML_SCHEMAP_INVALID_BOOLEAN, { 1714 }
    XML_SCHEMAP_INVALID_ENUM, { 1715 }
    XML_SCHEMAP_INVALID_FACET, { 1716 }
    XML_SCHEMAP_INVALID_FACET_VALUE, { 1717 }
    XML_SCHEMAP_INVALID_MAXOCCURS, { 1718 }
    XML_SCHEMAP_INVALID_MINOCCURS, { 1719 }
    XML_SCHEMAP_INVALID_REF_AND_SUBTYPE, { 1720 }
    XML_SCHEMAP_INVALID_WHITE_SPACE, { 1721 }
    XML_SCHEMAP_NOATTR_NOREF, { 1722 }
    XML_SCHEMAP_NOTATION_NO_NAME, { 1723 }
    XML_SCHEMAP_NOTYPE_NOREF, { 1724 }
    XML_SCHEMAP_REF_AND_SUBTYPE, { 1725 }
    XML_SCHEMAP_RESTRICTION_NONAME_NOREF, { 1726 }
    XML_SCHEMAP_SIMPLETYPE_NONAME, { 1727 }
    XML_SCHEMAP_TYPE_AND_SUBTYPE, { 1728 }
    XML_SCHEMAP_UNKNOWN_ALL_CHILD, { 1729 }
    XML_SCHEMAP_UNKNOWN_ANYATTRIBUTE_CHILD, { 1730 }
    XML_SCHEMAP_UNKNOWN_ATTR_CHILD, { 1731 }
    XML_SCHEMAP_UNKNOWN_ATTRGRP_CHILD, { 1732 }
    XML_SCHEMAP_UNKNOWN_ATTRIBUTE_GROUP, { 1733 }
    XML_SCHEMAP_UNKNOWN_BASE_TYPE, { 1734 }
    XML_SCHEMAP_UNKNOWN_CHOICE_CHILD, { 1735 }
    XML_SCHEMAP_UNKNOWN_COMPLEXCONTENT_CHILD, { 1736 }
    XML_SCHEMAP_UNKNOWN_COMPLEXTYPE_CHILD, { 1737 }
    XML_SCHEMAP_UNKNOWN_ELEM_CHILD, { 1738 }
    XML_SCHEMAP_UNKNOWN_EXTENSION_CHILD, { 1739 }
    XML_SCHEMAP_UNKNOWN_FACET_CHILD, { 1740 }
    XML_SCHEMAP_UNKNOWN_FACET_TYPE, { 1741 }
    XML_SCHEMAP_UNKNOWN_GROUP_CHILD, { 1742 }
    XML_SCHEMAP_UNKNOWN_IMPORT_CHILD, { 1743 }
    XML_SCHEMAP_UNKNOWN_LIST_CHILD, { 1744 }
    XML_SCHEMAP_UNKNOWN_NOTATION_CHILD, { 1745 }
    XML_SCHEMAP_UNKNOWN_PROCESSCONTENT_CHILD, { 1746 }
    XML_SCHEMAP_UNKNOWN_REF, { 1747 }
    XML_SCHEMAP_UNKNOWN_RESTRICTION_CHILD, { 1748 }
    XML_SCHEMAP_UNKNOWN_SCHEMAS_CHILD, { 1749 }
    XML_SCHEMAP_UNKNOWN_SEQUENCE_CHILD, { 1750 }
    XML_SCHEMAP_UNKNOWN_SIMPLECONTENT_CHILD, { 1751 }
    XML_SCHEMAP_UNKNOWN_SIMPLETYPE_CHILD, { 1752 }
    XML_SCHEMAP_UNKNOWN_TYPE, { 1753 }
    XML_SCHEMAP_UNKNOWN_UNION_CHILD, { 1754 }
    XML_SCHEMAP_ELEM_DEFAULT_FIXED, { 1755 }
    XML_SCHEMAP_REGEXP_INVALID, { 1756 }
    XML_SCHEMAP_FAILED_LOAD, { 1757 }
    XML_SCHEMAP_NOTHING_TO_PARSE, { 1758 }
    XML_SCHEMAP_NOROOT, { 1759 }
    XML_SCHEMAP_REDEFINED_GROUP, { 1760 }
    XML_SCHEMAP_REDEFINED_TYPE, { 1761 }
    XML_SCHEMAP_REDEFINED_ELEMENT, { 1762 }
    XML_SCHEMAP_REDEFINED_ATTRGROUP, { 1763 }
    XML_SCHEMAP_REDEFINED_ATTR, { 1764 }
    XML_SCHEMAP_REDEFINED_NOTATION, { 1765 }
    XML_SCHEMAP_FAILED_PARSE, { 1766 }
    XML_SCHEMAP_UNKNOWN_PREFIX, { 1767 }
    XML_SCHEMAP_DEF_AND_PREFIX, { 1768 }
    XML_SCHEMAP_UNKNOWN_INCLUDE_CHILD, { 1769 }
    XML_SCHEMAP_INCLUDE_SCHEMA_NOT_URI, { 1770 }
    XML_SCHEMAP_INCLUDE_SCHEMA_NO_URI, { 1771 }
    XML_SCHEMAP_NOT_SCHEMA, { 1772 }
    XML_SCHEMAP_UNKNOWN_MEMBER_TYPE, { 1773 }
    XML_SCHEMAP_INVALID_ATTR_USE, { 1774 }
    XML_SCHEMAP_RECURSIVE, { 1775 }
    XML_SCHEMAP_SUPERNUMEROUS_LIST_ITEM_TYPE, { 1776 }
    XML_SCHEMAP_INVALID_ATTR_COMBINATION, { 1777 }
    XML_SCHEMAP_INVALID_ATTR_INLINE_COMBINATION, { 1778 }
    XML_SCHEMAP_MISSING_SIMPLETYPE_CHILD, { 1779 }
    XML_SCHEMAP_INVALID_ATTR_NAME, { 1780 }
    XML_SCHEMAP_REF_AND_CONTENT, { 1781 }
    XML_SCHEMAP_CT_PROPS_CORRECT_1, { 1782 }
    XML_SCHEMAP_CT_PROPS_CORRECT_2, { 1783 }
    XML_SCHEMAP_CT_PROPS_CORRECT_3, { 1784 }
    XML_SCHEMAP_CT_PROPS_CORRECT_4, { 1785 }
    XML_SCHEMAP_CT_PROPS_CORRECT_5, { 1786 }
    XML_SCHEMAP_DERIVATION_OK_RESTRICTION_1, { 1787 }
    XML_SCHEMAP_DERIVATION_OK_RESTRICTION_2_1_1, { 1788 }
    XML_SCHEMAP_DERIVATION_OK_RESTRICTION_2_1_2, { 1789 }
    XML_SCHEMAP_DERIVATION_OK_RESTRICTION_2_2, { 1790 }
    XML_SCHEMAP_DERIVATION_OK_RESTRICTION_3, { 1791 }
    XML_SCHEMAP_WILDCARD_INVALID_NS_MEMBER, { 1792 }
    XML_SCHEMAP_INTERSECTION_NOT_EXPRESSIBLE, { 1793 }
    XML_SCHEMAP_UNION_NOT_EXPRESSIBLE, { 1794 }
    XML_SCHEMAP_SRC_IMPORT_3_1, { 1795 }
    XML_SCHEMAP_SRC_IMPORT_3_2, { 1796 }
    XML_SCHEMAP_DERIVATION_OK_RESTRICTION_4_1, { 1797 }
    XML_SCHEMAP_DERIVATION_OK_RESTRICTION_4_2, { 1798 }
    XML_SCHEMAP_DERIVATION_OK_RESTRICTION_4_3, { 1799 }
    XML_SCHEMAP_COS_CT_EXTENDS_1_3, { 1800 }
    XML_SCHEMAV_NOROOT = 1801,
    XML_SCHEMAV_UNDECLAREDELEM, { 1802 }
    XML_SCHEMAV_NOTTOPLEVEL, { 1803 }
    XML_SCHEMAV_MISSING, { 1804 }
    XML_SCHEMAV_WRONGELEM, { 1805 }
    XML_SCHEMAV_NOTYPE, { 1806 }
    XML_SCHEMAV_NOROLLBACK, { 1807 }
    XML_SCHEMAV_ISABSTRACT, { 1808 }
    XML_SCHEMAV_NOTEMPTY, { 1809 }
    XML_SCHEMAV_ELEMCONT, { 1810 }
    XML_SCHEMAV_HAVEDEFAULT, { 1811 }
    XML_SCHEMAV_NOTNILLABLE, { 1812 }
    XML_SCHEMAV_EXTRACONTENT, { 1813 }
    XML_SCHEMAV_INVALIDATTR, { 1814 }
    XML_SCHEMAV_INVALIDELEM, { 1815 }
    XML_SCHEMAV_NOTDETERMINIST, { 1816 }
    XML_SCHEMAV_CONSTRUCT, { 1817 }
    XML_SCHEMAV_INTERNAL, { 1818 }
    XML_SCHEMAV_NOTSIMPLE, { 1819 }
    XML_SCHEMAV_ATTRUNKNOWN, { 1820 }
    XML_SCHEMAV_ATTRINVALID, { 1821 }
    XML_SCHEMAV_VALUE, { 1822 }
    XML_SCHEMAV_FACET, { 1823 }
    XML_SCHEMAV_CVC_DATATYPE_VALID_1_2_1, { 1824 }
    XML_SCHEMAV_CVC_DATATYPE_VALID_1_2_2, { 1825 }
    XML_SCHEMAV_CVC_DATATYPE_VALID_1_2_3, { 1826 }
    XML_SCHEMAV_CVC_TYPE_3_1_1, { 1827 }
    XML_SCHEMAV_CVC_TYPE_3_1_2, { 1828 }
    XML_SCHEMAV_CVC_FACET_VALID, { 1829 }
    XML_SCHEMAV_CVC_LENGTH_VALID, { 1830 }
    XML_SCHEMAV_CVC_MINLENGTH_VALID, { 1831 }
    XML_SCHEMAV_CVC_MAXLENGTH_VALID, { 1832 }
    XML_SCHEMAV_CVC_MININCLUSIVE_VALID, { 1833 }
    XML_SCHEMAV_CVC_MAXINCLUSIVE_VALID, { 1834 }
    XML_SCHEMAV_CVC_MINEXCLUSIVE_VALID, { 1835 }
    XML_SCHEMAV_CVC_MAXEXCLUSIVE_VALID, { 1836 }
    XML_SCHEMAV_CVC_TOTALDIGITS_VALID, { 1837 }
    XML_SCHEMAV_CVC_FRACTIONDIGITS_VALID, { 1838 }
    XML_SCHEMAV_CVC_PATTERN_VALID, { 1839 }
    XML_SCHEMAV_CVC_ENUMERATION_VALID, { 1840 }
    XML_SCHEMAV_CVC_COMPLEX_TYPE_2_1, { 1841 }
    XML_SCHEMAV_CVC_COMPLEX_TYPE_2_2, { 1842 }
    XML_SCHEMAV_CVC_COMPLEX_TYPE_2_3, { 1843 }
    XML_SCHEMAV_CVC_COMPLEX_TYPE_2_4, { 1844 }
    XML_SCHEMAV_CVC_ELT_1, { 1845 }
    XML_SCHEMAV_CVC_ELT_2, { 1846 }
    XML_SCHEMAV_CVC_ELT_3_1, { 1847 }
    XML_SCHEMAV_CVC_ELT_3_2_1, { 1848 }
    XML_SCHEMAV_CVC_ELT_3_2_2, { 1849 }
    XML_SCHEMAV_CVC_ELT_4_1, { 1850 }
    XML_SCHEMAV_CVC_ELT_4_2, { 1851 }
    XML_SCHEMAV_CVC_ELT_4_3, { 1852 }
    XML_SCHEMAV_CVC_ELT_5_1_1, { 1853 }
    XML_SCHEMAV_CVC_ELT_5_1_2, { 1854 }
    XML_SCHEMAV_CVC_ELT_5_2_1, { 1855 }
    XML_SCHEMAV_CVC_ELT_5_2_2_1, { 1856 }
    XML_SCHEMAV_CVC_ELT_5_2_2_2_1, { 1857 }
    XML_SCHEMAV_CVC_ELT_5_2_2_2_2, { 1858 }
    XML_SCHEMAV_CVC_ELT_6, { 1859 }
    XML_SCHEMAV_CVC_ELT_7, { 1860 }
    XML_SCHEMAV_CVC_ATTRIBUTE_1, { 1861 }
    XML_SCHEMAV_CVC_ATTRIBUTE_2, { 1862 }
    XML_SCHEMAV_CVC_ATTRIBUTE_3, { 1863 }
    XML_SCHEMAV_CVC_ATTRIBUTE_4, { 1864 }
    XML_SCHEMAV_CVC_COMPLEX_TYPE_3_1, { 1865 }
    XML_SCHEMAV_CVC_COMPLEX_TYPE_3_2_1, { 1866 }
    XML_SCHEMAV_CVC_COMPLEX_TYPE_3_2_2, { 1867 }
    XML_SCHEMAV_CVC_COMPLEX_TYPE_4, { 1868 }
    XML_SCHEMAV_CVC_COMPLEX_TYPE_5_1, { 1869 }
    XML_SCHEMAV_CVC_COMPLEX_TYPE_5_2, { 1870 }
    XML_SCHEMAV_ELEMENT_CONTENT, { 1871 }
    XML_SCHEMAV_DOCUMENT_ELEMENT_MISSING, { 1872 }
    XML_SCHEMAV_CVC_COMPLEX_TYPE_1, { 1873 }
    XML_SCHEMAV_CVC_AU, { 1874 }
    XML_SCHEMAV_CVC_TYPE_1, { 1875 }
    XML_SCHEMAV_CVC_TYPE_2, { 1876 }
    XML_SCHEMAV_CVC_IDC, { 1877 }
    XML_SCHEMAV_CVC_WILDCARD, { 1878 }
    XML_SCHEMAV_MISC, { 1879 }
    XML_XPTR_UNKNOWN_SCHEME = 1900,
    XML_XPTR_CHILDSEQ_START, { 1901 }
    XML_XPTR_EVAL_FAILED, { 1902 }
    XML_XPTR_EXTRA_OBJECTS, { 1903 }
    XML_C14N_CREATE_CTXT = 1950,
    XML_C14N_REQUIRES_UTF8, { 1951 }
    XML_C14N_CREATE_STACK, { 1952 }
    XML_C14N_INVALID_NODE, { 1953 }
    XML_C14N_UNKNOW_NODE, { 1954 }
    XML_C14N_RELATIVE_NAMESPACE, { 1955 }
    XML_FTP_PASV_ANSWER = 2000,
    XML_FTP_EPSV_ANSWER, { 2001 }
    XML_FTP_ACCNT, { 2002 }
    XML_FTP_URL_SYNTAX, { 2003 }
    XML_HTTP_URL_SYNTAX = 2020,
    XML_HTTP_USE_IP, { 2021 }
    XML_HTTP_UNKNOWN_HOST, { 2022 }
    XML_SCHEMAP_SRC_SIMPLE_TYPE_1 = 3000,
    XML_SCHEMAP_SRC_SIMPLE_TYPE_2, { 3001 }
    XML_SCHEMAP_SRC_SIMPLE_TYPE_3, { 3002 }
    XML_SCHEMAP_SRC_SIMPLE_TYPE_4, { 3003 }
    XML_SCHEMAP_SRC_RESOLVE, { 3004 }
    XML_SCHEMAP_SRC_RESTRICTION_BASE_OR_SIMPLETYPE, { 3005 }
    XML_SCHEMAP_SRC_LIST_ITEMTYPE_OR_SIMPLETYPE, { 3006 }
    XML_SCHEMAP_SRC_UNION_MEMBERTYPES_OR_SIMPLETYPES, { 3007 }
    XML_SCHEMAP_ST_PROPS_CORRECT_1, { 3008 }
    XML_SCHEMAP_ST_PROPS_CORRECT_2, { 3009 }
    XML_SCHEMAP_ST_PROPS_CORRECT_3, { 3010 }
    XML_SCHEMAP_COS_ST_RESTRICTS_1_1, { 3011 }
    XML_SCHEMAP_COS_ST_RESTRICTS_1_2, { 3012 }
    XML_SCHEMAP_COS_ST_RESTRICTS_1_3_1, { 3013 }
    XML_SCHEMAP_COS_ST_RESTRICTS_1_3_2, { 3014 }
    XML_SCHEMAP_COS_ST_RESTRICTS_2_1, { 3015 }
    XML_SCHEMAP_COS_ST_RESTRICTS_2_3_1_1, { 3016 }
    XML_SCHEMAP_COS_ST_RESTRICTS_2_3_1_2, { 3017 }
    XML_SCHEMAP_COS_ST_RESTRICTS_2_3_2_1, { 3018 }
    XML_SCHEMAP_COS_ST_RESTRICTS_2_3_2_2, { 3019 }
    XML_SCHEMAP_COS_ST_RESTRICTS_2_3_2_3, { 3020 }
    XML_SCHEMAP_COS_ST_RESTRICTS_2_3_2_4, { 3021 }
    XML_SCHEMAP_COS_ST_RESTRICTS_2_3_2_5, { 3022 }
    XML_SCHEMAP_COS_ST_RESTRICTS_3_1, { 3023 }
    XML_SCHEMAP_COS_ST_RESTRICTS_3_3_1, { 3024 }
    XML_SCHEMAP_COS_ST_RESTRICTS_3_3_1_2, { 3025 }
    XML_SCHEMAP_COS_ST_RESTRICTS_3_3_2_2, { 3026 }
    XML_SCHEMAP_COS_ST_RESTRICTS_3_3_2_1, { 3027 }
    XML_SCHEMAP_COS_ST_RESTRICTS_3_3_2_3, { 3028 }
    XML_SCHEMAP_COS_ST_RESTRICTS_3_3_2_4, { 3029 }
    XML_SCHEMAP_COS_ST_RESTRICTS_3_3_2_5, { 3030 }
    XML_SCHEMAP_COS_ST_DERIVED_OK_2_1, { 3031 }
    XML_SCHEMAP_COS_ST_DERIVED_OK_2_2, { 3032 }
    XML_SCHEMAP_S4S_ELEM_NOT_ALLOWED, { 3033 }
    XML_SCHEMAP_S4S_ELEM_MISSING, { 3034 }
    XML_SCHEMAP_S4S_ATTR_NOT_ALLOWED, { 3035 }
    XML_SCHEMAP_S4S_ATTR_MISSING, { 3036 }
    XML_SCHEMAP_S4S_ATTR_INVALID_VALUE, { 3037 }
    XML_SCHEMAP_SRC_ELEMENT_1, { 3038 }
    XML_SCHEMAP_SRC_ELEMENT_2_1, { 3039 }
    XML_SCHEMAP_SRC_ELEMENT_2_2, { 3040 }
    XML_SCHEMAP_SRC_ELEMENT_3, { 3041 }
    XML_SCHEMAP_P_PROPS_CORRECT_1, { 3042 }
    XML_SCHEMAP_P_PROPS_CORRECT_2_1, { 3043 }
    XML_SCHEMAP_P_PROPS_CORRECT_2_2, { 3044 }
    XML_SCHEMAP_E_PROPS_CORRECT_2, { 3045 }
    XML_SCHEMAP_E_PROPS_CORRECT_3, { 3046 }
    XML_SCHEMAP_E_PROPS_CORRECT_4, { 3047 }
    XML_SCHEMAP_E_PROPS_CORRECT_5, { 3048 }
    XML_SCHEMAP_E_PROPS_CORRECT_6, { 3049 }
    XML_SCHEMAP_SRC_INCLUDE, { 3050 }
    XML_SCHEMAP_SRC_ATTRIBUTE_1, { 3051 }
    XML_SCHEMAP_SRC_ATTRIBUTE_2, { 3052 }
    XML_SCHEMAP_SRC_ATTRIBUTE_3_1, { 3053 }
    XML_SCHEMAP_SRC_ATTRIBUTE_3_2, { 3054 }
    XML_SCHEMAP_SRC_ATTRIBUTE_4, { 3055 }
    XML_SCHEMAP_NO_XMLNS, { 3056 }
    XML_SCHEMAP_NO_XSI, { 3057 }
    XML_SCHEMAP_COS_VALID_DEFAULT_1, { 3058 }
    XML_SCHEMAP_COS_VALID_DEFAULT_2_1, { 3059 }
    XML_SCHEMAP_COS_VALID_DEFAULT_2_2_1, { 3060 }
    XML_SCHEMAP_COS_VALID_DEFAULT_2_2_2, { 3061 }
    XML_SCHEMAP_CVC_SIMPLE_TYPE, { 3062 }
    XML_SCHEMAP_COS_CT_EXTENDS_1_1, { 3063 }
    XML_SCHEMAP_SRC_IMPORT_1_1, { 3064 }
    XML_SCHEMAP_SRC_IMPORT_1_2, { 3065 }
    XML_SCHEMAP_SRC_IMPORT_2, { 3066 }
    XML_SCHEMAP_SRC_IMPORT_2_1, { 3067 }
    XML_SCHEMAP_SRC_IMPORT_2_2, { 3068 }
    XML_SCHEMAP_INTERNAL, { 3069 non-W3C }
    XML_SCHEMAP_NOT_DETERMINISTIC, { 3070 non-W3C }
    XML_SCHEMAP_SRC_ATTRIBUTE_GROUP_1, { 3071 }
    XML_SCHEMAP_SRC_ATTRIBUTE_GROUP_2, { 3072 }
    XML_SCHEMAP_SRC_ATTRIBUTE_GROUP_3, { 3073 }
    XML_SCHEMAP_MG_PROPS_CORRECT_1, { 3074 }
    XML_SCHEMAP_MG_PROPS_CORRECT_2, { 3075 }
    XML_SCHEMAP_SRC_CT_1, { 3076 }
    XML_SCHEMAP_DERIVATION_OK_RESTRICTION_2_1_3, { 3077 }
    XML_SCHEMAP_AU_PROPS_CORRECT_2, { 3078 }
    XML_SCHEMAP_A_PROPS_CORRECT_2, { 3079 }
    XML_SCHEMAP_C_PROPS_CORRECT, { 3080 }
    XML_SCHEMAP_SRC_REDEFINE, { 3081 }
    XML_SCHEMAP_SRC_IMPORT, { 3082 }
    XML_SCHEMAP_WARN_SKIP_SCHEMA, { 3083 }
    XML_SCHEMAP_WARN_UNLOCATED_SCHEMA, { 3084 }
    XML_SCHEMAP_WARN_ATTR_REDECL_PROH, { 3085 }
    XML_SCHEMAP_WARN_ATTR_POINTLESS_PROH, { 3085 }
    XML_SCHEMAP_AG_PROPS_CORRECT, { 3086 }
    XML_SCHEMAP_COS_CT_EXTENDS_1_2, { 3087 }
    XML_SCHEMAP_AU_PROPS_CORRECT, { 3088 }
    XML_SCHEMAP_A_PROPS_CORRECT_3, { 3089 }
    XML_SCHEMAP_COS_ALL_LIMITED, { 3090 }
    XML_SCHEMATRONV_ASSERT = 4000, { 4000 }
    XML_SCHEMATRONV_REPORT,
    XML_MODULE_OPEN = 4900, { 4900 }
    XML_MODULE_CLOSE, { 4901 }
    XML_CHECK_FOUND_ELEMENT = 5000,
    XML_CHECK_FOUND_ATTRIBUTE, { 5001 }
    XML_CHECK_FOUND_TEXT, { 5002 }
    XML_CHECK_FOUND_CDATA, { 5003 }
    XML_CHECK_FOUND_ENTITYREF, { 5004 }
    XML_CHECK_FOUND_ENTITY, { 5005 }
    XML_CHECK_FOUND_PI, { 5006 }
    XML_CHECK_FOUND_COMMENT, { 5007 }
    XML_CHECK_FOUND_DOCTYPE, { 5008 }
    XML_CHECK_FOUND_FRAGMENT, { 5009 }
    XML_CHECK_FOUND_NOTATION, { 5010 }
    XML_CHECK_UNKNOWN_NODE, { 5011 }
    XML_CHECK_ENTITY_TYPE, { 5012 }
    XML_CHECK_NO_PARENT, { 5013 }
    XML_CHECK_NO_DOC, { 5014 }
    XML_CHECK_NO_NAME, { 5015 }
    XML_CHECK_NO_ELEM, { 5016 }
    XML_CHECK_WRONG_DOC, { 5017 }
    XML_CHECK_NO_PREV, { 5018 }
    XML_CHECK_WRONG_PREV, { 5019 }
    XML_CHECK_NO_NEXT, { 5020 }
    XML_CHECK_WRONG_NEXT, { 5021 }
    XML_CHECK_NOT_DTD, { 5022 }
    XML_CHECK_NOT_ATTR, { 5023 }
    XML_CHECK_NOT_ATTR_DECL, { 5024 }
    XML_CHECK_NOT_ELEM_DECL, { 5025 }
    XML_CHECK_NOT_ENTITY_DECL, { 5026 }
    XML_CHECK_NOT_NS_DECL, { 5027 }
    XML_CHECK_NO_HREF, { 5028 }
    XML_CHECK_WRONG_PARENT,{ 5029 }
    XML_CHECK_NS_SCOPE, { 5030 }
    XML_CHECK_NS_ANCESTOR, { 5031 }
    XML_CHECK_NOT_UTF8, { 5032 }
    XML_CHECK_NO_DICT, { 5033 }
    XML_CHECK_NOT_NCNAME, { 5034 }
    XML_CHECK_OUTSIDE_DICT, { 5035 }
    XML_CHECK_WRONG_NAME, { 5036 }
    XML_CHECK_NAME_NOT_NULL, { 5037 }
    XML_I18N_NO_NAME = 6000,
    XML_I18N_NO_HANDLER, { 6001 }
    XML_I18N_EXCESS_HANDLER, { 6002 }
    XML_I18N_CONV_FAILED, { 6003 }
    XML_I18N_NO_OUTPUT, { 6004 }
    XML_BUF_OVERFLOW = 7000
  );

  xmlErrorPtr = ^xmlError;
  ///<summary>An object containing information about an error.</summary>
  xmlError  = record
    domain: Integer;     // What part of the library raised this error
    code: Integer;       // The error code, e.g. an xmlParserError
    message: PUTF8Char;  // human-readable informative error message
    level: xmlErrorLevel;// how consequent is the error
    &file: PUTF8Char;    // the filename
    line: Integer;       // the line number if available
    str1: PUTF8Char;     // extra string information
    str2: PUTF8Char;     // extra string information
    str3: PUTF8Char;     // extra string information
    int1: Integer;       // extra number information
    int2: Integer;       // error column # or 0 if N/A
    ctxt: Pointer;       // the parser context if available
    node: Pointer;       // the node in the tree
  end;

  /// <summary>
  /// Structured error callback receiving an xmlError.
  /// </summary>
  /// <param name="userData">user provided data for the error callback </param>
  /// <param name="error">the error being raised </param>
  xmlStructuredErrorFunc = procedure(userData: Pointer; const error: xmlErrorPtr); cdecl;

  /// <summary>
  /// Signature of the function to use when there is an error and no parsing or validity context available .
  /// </summary>
  /// <param name="ctx">a parsing context</param>
  /// <param name="msg">the message</param>
  xmlGenericErrorFunc = procedure(ctx: Pointer; const msg: xmlCharPtr); cdecl varargs;

var
  /// <summary>
  /// Get the last error raised in this thread.
  /// </summary>
  /// <returns>Get the last error raised in this thread.</returns>
  xmlGetLastError              : function: xmlErrorPtr; cdecl;

  /// <summary>
  /// Reset the last error to success.
  /// </summary>
  xmlResetLastError            : procedure; cdecl;

  /// <summary>
  /// Get the last error raised.
  /// Note that the XML parser typically doesn't stop after encountering an error and will often report multiple errors.
  /// Most of the time, the last error isn't useful.
  /// Future versions might return the first parser error instead.
  /// </summary>
  /// <param name="ctx">an XML parser context </param>
  /// <returns>nil if no error occurred or a pointer to the error </returns>
  xmlCtxtGetLastError          : function (ctx: Pointer): xmlErrorPtr; cdecl;

  /// <summary>
  /// Reset the last parser error to success.
  /// This does not change the well-formedness status.
  /// </summary>
  /// <param name="ctx">an XML parser context </param>
  xmlCtxtResetLastError        : procedure(ctx: Pointer); cdecl;

  /// <summary>
  /// Reset the error to success.
  /// </summary>
  /// <param name="err">pointer to the error </param>
  xmlResetError                : procedure(err: xmlErrorPtr); cdecl;

  /// <summary>
  /// Copy an error
  /// </summary>
  /// <param name="fromErr">a source error</param>
  /// <param name="toErr">a target error </param>
  /// <returns>0 in case of success and -1 in case of error. </returns>
  xmlCopyError                 : function (const fromErr, toErr: xmlErrorPtr): Integer; cdecl;

{$endregion}

{$region 'xmlmemory.h'}

type
  xmlFreeFunc    = procedure(mem: Pointer); cdecl;
  xmlMallocFunc  = function(size: size_t): Pointer; cdecl;
  xmlReallocFunc = function(mem: Pointer; size: size_t): Pointer; cdecl;
  xmlStrdupFunc  = function(const str: PAnsiChar): PAnsiChar; cdecl;

var
  ///<summary>The variable holding the libxml free() implementation. </summary>
  xmlFree          : xmlFreeFunc;
  ///<summary>a malloc() equivalent, with logging of the allocation info.</summary>
  xmlMalloc        : xmlMallocFunc;
  ///<summary>The variable holding the libxml realloc() implementation. </summary>
  xmlRealloc       : xmlReallocFunc;
  ///<summary>The variable holding the libxml strdup() implementation. </summary>
  xmlStrdup        : xmlStrdupFunc;
  ///<summary></summary>
  xmlMemFree       : xmlFreeFunc;
  ///<summary></summary>
  xmlMemMalloc     : xmlMallocFunc;
  ///<summary></summary>
  xmlMemoryStrdup  : xmlStrdupFunc;
  ///<summary>a realloc() equivalent, with logging of the allocation info. </summary>
  xmlMemRealloc    : xmlReallocFunc;
  ///<summary>Provides the memory access functions set currently in use. </summary>
  xmlMemGet        : function(var freeFunc: xmlFreeFunc; var mallocFunc: xmlMallocFunc; var reallocFunc: xmlReallocFunc; var strdupFunc: xmlStrdupFunc): Integer; cdecl;
  ///<summary>Override the default memory access functions with a new set This has to be called before any other libxml routines !</summary>
  xmlMemSetup      : function(freeFunc: xmlFreeFunc; mallocFunc: xmlMallocFunc; reallocFunc: xmlReallocFunc; strdupFunc: xmlStrdupFunc): Integer; cdecl;
  ///<summary></summary>
  xmlMemUsed       : function: size_t; cdecl;

{$endregion}

{$region 'dict.h'}

/// string dictionary
/// dictionary of reusable strings, just used to avoid allocation and freeing operations.

type
  xmlDictPtr = ^xmlDict;
  xmlDict = record end;

var
  /// <summary>
  /// Create a new dictionary.
  /// </summary>
  /// <returns>
  ///  the newly created dictionary, or nil if an error occurred.
  /// </returns>
  xmlDictCreate               : function: xmlDictPtr; cdecl;

  /// <summary>
  /// Set a size limit for the dictionary Added in 2.9.0.
  /// </summary>
  /// <param name="dict">the dictionary</param>
  /// <param name="limit">the limit in bytes</param>
  /// <returns>
  /// the previous limit of the dictionary or 0
  /// </returns>
  xmlDictSetLimit             : function (dict: xmlDictPtr; limit: size_t): size_t; cdecl;

  /// <summary>
  /// Get how much memory is used by a dictionary for strings Added in 2.9.0.
  /// </summary>
  /// <param name="dict">the dictionary</param>
  /// <returns>
  /// the amount of strings allocated
  /// </returns>
  xmlDictGetUsage             : function (dict: xmlDictPtr): size_t; cdecl;

  /// <summary>
  /// Create a new dictionary, inheriting strings from the read-only dictionary sub.
  /// On lookup, strings are first searched in the new dictionary, then in sub, and if not found are created in the new dictionary.
  /// </summary>
  /// <param name="sub">an existing dictionary</param>
  /// <returns>
  /// the newly created dictionary, or nil if an error occurred.
  /// </returns>
  xmlDictCreateSub            : function (sub: xmlDictPtr): xmlDictPtr; cdecl;

  /// <summary>
  /// Increment the reference counter of a dictionary.
  /// </summary>
  /// <param name="dict">the dictionary</param>
  /// <returns>
  /// 0 in case of success and -1 in case of error
  /// </returns>
  xmlDictReference            : function (dict: xmlDictPtr): Integer; cdecl;

  /// <summary>
  /// Free the hash dict and its contents.
  /// The userdata is deallocated with f if provided.
  /// </summary>
  /// <param name="dict">the dictionary</param>
  xmlDictFree                 : procedure(dict: xmlDictPtr); cdecl;

  /// <summary>
  /// Lookup a string and add it to the dictionary if it wasn't found.
  /// </summary>
  /// <param name="dict">dictionary</param>
  /// <param name="name">string key</param>
  /// <param name="len">length of the key, if -1 it is recomputed</param>
  /// <returns>
  ///  the interned copy of the string or nil if a memory allocation failed.
  /// </returns>
  xmlDictLookup               : function (dict: xmlDictPtr; name: xmlCharPtr; len: Integer): xmlCharPtr; cdecl;

  /// <summary>
  /// Check if a string exists in the dictionary.
  /// </summary>
  /// <param name="dict">dictionary</param>
  /// <param name="name">the name of the userdata </param>
  /// <param name="len">length of the key, if -1 it is recomputed</param>
  /// <returns>
  ///  the internal copy of the name or nil if not found.
  /// </returns>
  xmlDictExists               : function (dict: xmlDictPtr; name: xmlCharPtr; len: Integer): xmlCharPtr; cdecl;

  /// <summary>
  /// Lookup the QName prefix:name and add it to the dictionary if it wasn't found.
  /// </summary>
  /// <param name="dict">the dictionary </param>
  /// <param name="prefix">the prefix</param>
  /// <param name="name">the name</param>
  /// <returns>
  /// The interned copy of the string or nil if a memory allocation failed.
  /// </returns>
  xmlDictQLookup              : function (dict: xmlDictPtr; prefix: xmlCharPtr; name: xmlCharPtr): xmlCharPtr; cdecl;

  /// <summary>
  /// check if a string is owned by the dictionary
  /// </summary>
  /// <param name="dict">the dictionary</param>
  /// <param name="str">the string</param>
  /// <returns>
  /// 1 if true, 0 if false and -1 in case of error -1 in case of error
  /// </returns>
  xmlDictOwns                 : function (dict: xmlDictPtr; str: xmlCharPtr): Integer; cdecl;

  /// <summary>
  /// Query the number of elements installed in the hash dict.
  /// </summary>
  /// <param name="dict">the dictionary</param>
  /// <returns>
  /// the number of elements in the dictionary or -1 in case of error
  /// </returns>
  xmlDictSize                 : function (dict: xmlDictPtr): Integer; cdecl;

  {$endregion}

{$region 'three.h'}

type
  ///<summary>The different element types carried by an XML tree</summary>
  xmlElementType = (
    ///<summary></summary>
    XML_INVALID            = 0,
    ///<summary>element</summary>
    XML_ELEMENT_NODE       = 1,
    ///<summary>attribute</summary>
    XML_ATTRIBUTE_NODE     = 2,
    ///<summary>text</summary>
    XML_TEXT_NODE          = 3,
    ///<summary>CDATA section</summary>
    XML_CDATA_SECTION_NODE = 4,
    ///<summary>entity reference</summary>
    XML_ENTITY_REF_NODE    = 5,
    ///<summary>unused<</summary>
    XML_ENTITY_NODE        = 6,
    ///<summary>processing instruction </summary>
    XML_PI_NODE            = 7,
    ///<summary>comment</summary>
    XML_COMMENT_NODE       = 8,
    ///<summary>document</summary>
    XML_DOCUMENT_NODE      = 9,
    ///<summary>unused</summary>
    XML_DOCUMENT_TYPE_NODE = 10,
    ///<summary>document fragment</summary>
    XML_DOCUMENT_FRAG_NODE = 11,
    ///<summary>unused</summary>
    XML_NOTATION_NODE      = 12,
    ///<summary>HTML document</summary>
    XML_HTML_DOCUMENT_NODE = 13,
    ///<summary>DTD</summary>
    XML_DTD_NODE           = 14,
    ///<summary>element declaration</summary>
    XML_ELEMENT_DECL       = 15,
    ///<summary>attribute declaration</summary>
    XML_ATTRIBUTE_DECL     = 16,
    ///<summary>entity declaration</summary>
    XML_ENTITY_DECL        = 17,
    ///<summary>XPath namespace node</summary>
    XML_NAMESPACE_DECL     = 18,
    ///<summary>XInclude start marker</summary>
    XML_XINCLUDE_START     = 19,
    ///<summary>XInclude end marker</summary>
    XML_XINCLUDE_END       = 20
  );

  xmlNsType = type xmlElementType;

  ///<summary>A DTD Attribute type definition</summary>
  xmlAttributeType = (
    XML_ATTRIBUTE_CDATA = 1,
    XML_ATTRIBUTE_ID,
    XML_ATTRIBUTE_IDREF,
    XML_ATTRIBUTE_IDREFS,
    XML_ATTRIBUTE_ENTITY,
    XML_ATTRIBUTE_ENTITIES,
    XML_ATTRIBUTE_NMTOKEN,
    XML_ATTRIBUTE_NMTOKENS,
    XML_ATTRIBUTE_ENUMERATION,
    XML_ATTRIBUTE_NOTATION
  );

  ///<summary>A DTD Attribute default definition</summary>
  xmlAttributeDefault = (
    XML_ATTRIBUTE_NONE = 1,
    XML_ATTRIBUTE_REQUIRED,
    XML_ATTRIBUTE_IMPLIED,
    XML_ATTRIBUTE_FIXED
  );
  /// <summary>
  /// A buffer structure, this old construct is limited to 2GB and is being deprecated, use API with xmlBuf instead.
  /// </summary>
  xmlBufferPtr = ^xmlBuffer;
  xmlBuffer = record end;

  /// <summary>
  /// A buffer structure, new one, the actual structure internals are not public.
  /// </summary>
  xmlBufPtr = ^xmlBuf;
  xmlBuf = record end;

  /// <summary>
  /// A DTD Notation definition.
  /// </summary>
  /// <remarks>
  /// Should be treated as opaque. Accessing members directly is deprecated.
  /// </remarks>
  xmlNotationPtr = ^xmlNotation;
  xmlNotation = record
    name: xmlCharPtr;     // Notation name
    PublicID: xmlCharPtr; // Public identifier, if any
    SystemID: xmlCharPtr; // System identifier, if any
  end;

  /// <summary>
  /// List structure used when there is an enumeration in DTDs.
  /// </summary>
  /// <remarks>
  /// Should be treated as opaque. Accessing members directly is deprecated.
  /// </remarks>
  xmlEnumerationPtr = ^xmlEnumeration;
  xmlEnumeration = record
    next: xmlEnumerationPtr;
    name: xmlCharPtr;
  end;

  /// <summary>
  /// An XML or HTML document.
  /// </summary>
  xmlDocPtr = ^xmlDoc;

  /// <summary>
  /// An XML ID instance
  /// </summary>
  xmlIDPtr = ^xmlID;

  /// <summary>
  /// A node in an XML or HTML tree.
  /// This is used for
  ///   XML_ELEMENT_NODE
  ///   XML_TEXT_NODE
  ///   XML_CDATA_SECTION_NODE
  ///   XML_ENTITY_REF_NODE
  ///   XML_PI_NODE
  ///   XML_COMMENT_NODE
  ///   XML_XINCLUDE_START_NODE
  ///   XML_XINCLUDE_END_NODE
  /// </summary>
  xmlNodePtr = ^xmlNode;

  /// <summary>
  /// Note that prefix = nil is valid, it defines the default namespace within the subtree (until overridden).
  /// xmlNsType is unified with xmlElementType.
  /// </summary>
  xmlNsPtr = ^xmlNs;
  xmlNs = record
    /// <summary>next namespace</summary>
    next: xmlNsPtr;
    /// <summary>XML_NAMESPACE_DECL</summary>
    &type: xmlNsType;
    /// <summary>namespace URI</summary>
    href: xmlCharPtr;
    /// <summary>namespace prefix</summary>
    prefix: xmlCharPtr;
    /// <summary>application data</summary>
    _private: Pointer;
    /// <summary>normally an xmlDoc</summary>
    context: xmlDocPtr;
  end;

  /// <summary>
  /// Common header for all node types (dont declared in libxml2)
  /// </summary>
  xmlNodeHeaderPtr = ^xmlNodeHeader;
  xmlNodeHeader = record
    _private: Pointer;
    &type: xmlElementType;
    name: xmlCharPtr;
    children: xmlNodePtr;
    last: xmlNodePtr;
    parent: xmlNodePtr;
    next: xmlNodePtr;
    prev: xmlNodePtr;
    doc: xmlDocPtr;
  end;

  /// <summary>
  /// An attribute on an XML node.
  /// </summary>
  xmlAttrPtr = ^xmlAttr;
  xmlAttr = record
    /// <summary>application data</summary>
    _private: Pointer;
    /// <summary>XML_ATTRIBUTE_NODE</summary>
    &type: xmlElementType;
    /// <summary>local name </summary>
    name: xmlCharPtr;
    /// <summary>first child</summary>
    children: xmlNodePtr;
    /// <summary>last child</summary>
    last: xmlNodePtr;
    /// <summary>parent node</summary>
    parent: xmlNodePtr;
    /// <summary>next sibling</summary>
    next: xmlAttrPtr;
    /// <summary>previous sibling</summary>
    prev: xmlAttrPtr;
    /// <summary>containing document</summary>
    doc: xmlDocPtr;
    /// <summary>namespace if any</summary>
    ns: xmlNsPtr;
    /// <summary>attribute type if validating</summary>
    atype: xmlAttributeType;
    /// <summary>for type/PSVI information</summary>
    psvi: Pointer;
    /// <summary>ID struct if any</summary>
    id: xmlIDPtr;
  end;

  /// <summary>
  /// An XML ID instance
  /// </summary>
  /// <remarks>
  /// Should be treated as opaque. Accessing members directly is deprecated.
  /// </remarks>
  xmlID = record
    next: xmlIDPtr;
    value: xmlCharPtr;
    attr: xmlAttrPtr;
    name: xmlCharPtr;
    lineno: Integer;
    doc: xmlDocPtr;
  end;

  /// <summary>
  /// A node in an XML or HTML tree.
  /// This is used for
  ///   XML_ELEMENT_NODE
  ///   XML_TEXT_NODE
  ///   XML_CDATA_SECTION_NODE
  ///   XML_ENTITY_REF_NODE
  ///   XML_PI_NODE
  ///   XML_COMMENT_NODE
  ///   XML_XINCLUDE_START_NODE
  ///   XML_XINCLUDE_END_NODE
  /// </summary>
  xmlNode = record
    ///<summary>application data </summary>
    _private: Pointer;
    ///<summary>type enum</summary>
    &type: xmlElementType;
    ///<summary>local name for elements</summary>
    name: xmlCharPtr;
    ///<summary>first child</summary>
    children: xmlNodePtr;
    ///<summary>last child</summary>
    last: xmlNodePtr;
    ///<summary>parent node</summary>
    parent: xmlNodePtr;
    ///<summary>next sibling</summary>
    next: xmlNodePtr;
    ///<summary>previous sibling</summary>
    prev: xmlNodePtr;
    ///<summary>containing document </summary>
    doc: xmlDocPtr;

    { End of common part }

    ///<summary>namespace if any</summary>
    ns: XmlNsPtr;
    ///<summary>content of text, comment, PI nodes</summary>
    content: xmlCharPtr;
    ///<summary>attributes for elements</summary>
    properties: xmlAttrPtr;
    ///<summary>namespace definitions on this node</summary>
    nsDef: xmlNsPtr;
    ///<summary>for type/PSVI information</summary>
    psvi: Pointer;
    ///<summary>line number</summary>
    line: Word;
    ///<summary>extra data for XPath/XSLT</summary>
    extra: Word;
  end;

  /// <summary>
  /// An XML DTD, as defined by <!DOCTYPE ... There is actually one for the internal subset and for the external subset.
  /// </summary>
  xmlDtdPtr = ^xmlDtd;
  xmlDtd  = record
    /// <summary>application data</summary>
    _private: Pointer;
    /// <summary>XML_DTD_NODE</summary>
    &type: xmlElementType;
    /// <summary>name of the DTD </summary>
    name: xmlCharPtr;
    /// <summary>first child</summary>
    children: xmlNodePtr;
    /// <summary>last child</summary>
    last: xmlNodePtr;
    /// <summary>parent node</summary>
    parent: xmlDocPtr;
    /// <summary>next sibling</summary>
    next: xmlNodePtr;
    /// <summary>previous sibling</summary>
    prev: xmlNodePtr;
    /// <summary>containing document</summary>
    doc: xmlDocPtr;

    { End of common part }

    /// <summary>hash table for notations if any</summary>
    notations: Pointer;
    /// <summary>hash table for elements if any</summary>
    elements: Pointer;
    /// <summary>hash table for attributes if any</summary>
    attributes: Pointer;
    /// <summary>hash table for entities if any</summary>
    entities: Pointer;
    /// <summary>public identifier</summary>
    ExternalID: xmlCharPtr;
    /// <summary>system identifier</summary>
    SystemID: xmlCharPtr;
    /// <summary>hash table for parameter entities if any</summary>
    pentities: Pointer;
  end;

  /// <summary>
  /// An XML or HTML document.
  /// </summary>
  xmlDoc = record
    ///<summary>application data </summary>
    _private: Pointer;
    ///<summary>XML_DOCUMENT_NODE or XML_HTML_DOCUMENT_NODE</summary>
    &type: xmlElementType;
    ///<summary>name</summary>
    name: xmlCharPtr;
    ///<summary>first child</summary>
    children: xmlNodePtr;
    ///<summary>last child</summary>
    last: xmlNodePtr;
    ///<summary>parent node</summary>
    parent: xmlNodePtr;
    ///<summary>next sibling</summary>
    next: xmlNodePtr;
    ///<summary>previous sibling</summary>
    prev: xmlNodePtr;
    ///<summary>reference to itself</summary>
    doc: xmlDocPtr;

    { End of common part }

    ///<summary>level of zlib compression</summary>
    compression: Integer;
    ///<summary>standalone document (no external refs) </summary>
    standalone: Integer;
    ///<summary>internal subset</summary>
    intSubset: xmlDtdPtr;
    ///<summary>external subset</summary>
    extSubset: xmlDtdPtr;
    ///<summary>used to hold the XML namespace if needed</summary>
    oldNs: xmlNsPtr;
    ///<summary>version string from XML declaration</summary>
    version: xmlCharPtr;
    ///<summary>actual encoding if any</summary>
    encoding: xmlCharPtr;
    ///<summary>hash table for ID attributes if any</summary>
    ids: Pointer;
    ///<summary>hash table for IDREFs attributes if any</summary>
    refs: Pointer;
    ///<summary>URI of the document</summary>
    URL: xmlCharPtr;
    ///<summary>unused</summary>
    charset: Integer;
    ///<summary>dict used to allocate names if any</summary>
    dict: xmlDictPtr;
    ///<summary>for type/PSVI information</summary>
    psvi: Pointer;
    ///<summary>xmlParserOption enum used to parse the document</summary>
    parseFlags: Integer;
    ///<summary>xmlDocProperties of the document</summary>
    properties: Integer;
  end;

  /// <summary>
  /// An Attribute declaration in a DTD.
  /// </summary>
  /// <remarks>
  /// Should be treated as opaque. Accessing members directly is deprecated.
  /// </remarks>
  xmlAttributePtr = ^xmlAttribute;
  xmlAttribute = record
    _private: Pointer;             // application data
    &type: xmlElementType;         // XML_ENTITY_DECL, must be second !
    name: xmlCharPtr;              // Entity name
    children: xmlNodePtr;          // nil
    last: xmlNodePtr;              // nil
    parent: xmlNodePtr;            // -> DTD
    next: xmlNodePtr;              // next sibling link
    prev: xmlNodePtr;              // previous sibling link
    doc: xmlDocPtr;                 // the containing document
    nexth: xmlAttributePtr;        // next in hash table
    atype: xmlAttributeType;       // The attribute type
    def: xmlAttributeDefault;      // the default
    defaultValue: xmlCharPtr;      // or the default value
    tree: xmlEnumerationPtr;       // or the enumeration tree if any
    prefix: xmlCharPtr;            // the namespace prefix if any
    elem: xmlCharPtr;              // Element holding the attribute
  end;

  ///<summary>Possible definitions of element content types.</summary>
  xmlElementContentType = (
    XML_ELEMENT_CONTENT_PCDATA = 1,
    XML_ELEMENT_CONTENT_ELEMENT,
    XML_ELEMENT_CONTENT_SEQ,
    XML_ELEMENT_CONTENT_OR
  );

  ///<summary>Possible definitions of element content occurrences.</summary>
  xmlElementContentOccur = (
    XML_ELEMENT_CONTENT_ONCE = 1,
    XML_ELEMENT_CONTENT_OPT,
    XML_ELEMENT_CONTENT_MULT,
    XML_ELEMENT_CONTENT_PLUS
  );

  ///<summary>The different possibilities for an element content type. </summary>
  xmlElementTypeVal = (
    XML_ELEMENT_TYPE_UNDEFINED = 0,
    XML_ELEMENT_TYPE_EMPTY,
    XML_ELEMENT_TYPE_ANY,
    XML_ELEMENT_TYPE_MIXED,
    XML_ELEMENT_TYPE_ELEMENT
  );

  ///<summary>Set of properties of the document as found by the parser Some of them are linked to similarly named xmlParserOption.</summary>
  xmlDocProperties = (
    ///<summary>document is XML well formed</summary>
    XML_DOC_WELLFORMED = 1,
    ///<summary>document is Namespace valid</summary>
    XML_DOC_NSVALID    = 2,
    ///<summary>parsed with old XML-1.0 parser</summary>
    XML_DOC_OLD10      = 4,
    ///<summary>DTD validation was successful</summary>
    XML_DOC_DTDVALID   = 8,
    ///<summary>XInclude substitution was done</summary>
    XML_DOC_XINCLUDE   = 16,
    ///<summary>Document was built using the API and not by parsing an instance</summary>
    XML_DOC_USERBUILT  = 32,
    ///<summary>built for internal processing</summary>
    XML_DOC_INTERNAL   = 64,
    ///<summary>parsed or built HTML document</summary>
    XML_DOC_HTML       = 128
  );

  /// <summary>
  /// An XML Element content as stored after parsing an element definition in a DTD
  /// </summary>
  /// <remarks>
  /// Should be treated as opaque. Accessing members directly is deprecated.
  /// </remarks>
  xmlElementContentPtr = ^xmlElementContent;
  xmlElementContent  = record
    &type: xmlElementContentType;
    ocur: xmlElementContentOccur;
    name: xmlCharPtr;
    c1: xmlElementContentPtr;
    c2: xmlElementContentPtr;
    parent: xmlElementContentPtr;
    prefix: xmlCharPtr;
  end;

  /// <summary>
  /// An XML Element declaration from a DTD
  /// </summary>
  /// <remarks>
  /// Should be treated as opaque. Accessing members directly is deprecated.
  /// </remarks>
  xmlElementPtr = ^xmlElement;
  xmlElement = record
    _private: Pointer;
    &type: xmlElementType;
    name: xmlCharPtr;
    children: xmlNodePtr;
    last: xmlNodePtr;
    parent: xmlNodePtr;
    next: xmlNodePtr;
    prev: xmlNodePtr;
    doc: xmlDocPtr;

    { End of common part }

    etype: xmlElementTypeVal;
    content: xmlElementContentPtr;
    attributes: xmlAttributePtr;
    prefix: xmlCharPtr;
    contModel: Pointer;
  end;

  /// <summary>Context for DOM wrapper-operations.</summary>
  xmlDOMWrapCtxtPtr = ^xmlDOMWrapCtxt;

  xmlDOMWrapAcquireNsFunction = function(ctxt: xmlDOMWrapCtxtPtr; node: xmlNodePtr; nsName, nsPrefix: xmlCharPtr): xmlNsPtr; cdecl;

  /// <summary>Context for DOM wrapper-operations.</summary>
  xmlDOMWrapCtxt = record
    _private: Pointer;
    &type: Integer;
    namespaceMap: Pointer;
    getNsForNodeFunc: xmlDOMWrapAcquireNsFunction;
  end;

  xmlNsPtrArrayPtr = ^xmlNsPtrArray;
  xmlNsPtrArray = array[0..0] of xmlNsPtr;

  ///<summary>Signature for the registration callback of a created node.</summary>
  xmlRegisterNodeFunc   = procedure(node: xmlNodePtr); cdecl;
  ///<summary>Signature for the deregistration callback of a discarded node.</summary>
  xmlDeregisterNodeFunc = procedure(node: xmlNodePtr); cdecl;

var
  /// <summary>Check that a value conforms to the lexical space of NCName. </summary>
  /// <param name="value">the value to check</param>
  /// <param name="space">allow spaces in front and end of the string</param>
  /// <returns>0 if this validates, a positive error code number otherwise and -1 in case of internal or API error. </returns>
  xmlValidateNCName         : function(const value: xmlCharPtr; space: Integer): Integer; cdecl;

  /// <summary>Check that a value conforms to the lexical space of QName.</summary>
  /// <param name="value">the value to check</param>
  /// <param name="space">allow spaces in front and end of the string</param>
  /// <returns>0 if this validates, a positive error code number otherwise and -1 in case of internal or API error. </returns>
  xmlValidateQName          : function(const value: xmlCharPtr; space: Integer): Integer; cdecl;

  /// <summary>Check that a value conforms to the lexical space of Name</summary>
  /// <param name="value">the value to check</param>
  /// <param name="space">allow spaces in front and end of the string</param>
  /// <returns>0 if this validates, a positive error code number otherwise and -1 in case of internal or API error. </returns>
  xmlValidateName           : function(const value: xmlCharPtr; space: Integer): Integer; cdecl;

  /// <summary>Check that a value conforms to the lexical space of NMToken. </summary>
  /// <param name="value">the value to check</param>
  /// <param name="space">allow spaces in front and end of the string</param>
  /// <returns>0 if this validates, a positive error code number otherwise and -1 in case of internal or API error. </returns>
  xmlValidateNMToken        : function(const value: xmlCharPtr; space: Integer): Integer; cdecl;

  /// <summary>
  /// Build a QName from prefix and local name.
  /// Builds the QName prefix:ncname in memory if there is enough space and prefix is not nil nor empty, otherwise allocate a new string. If prefix is nil or empty it returns ncname.
  ///</summary>
  /// <param name="ncname">the Name</param>
  /// <param name="prefix">the prefix</param>
  /// <param name="memory">preallocated memory</param>
  /// <param name="len">preallocated memory length</param>
  /// <returns>the new string which must be freed by the caller if different from memory and ncname or nil in case of error </returns>
  xmlBuildQName             : function(const ncname, prefix, memory: xmlCharPtr; len: Integer): xmlCharPtr; cdecl;

  /// <summary>Parse an XML qualified name</summary>
  /// <param name="name">the full QName</param>
  /// <param name="len">len</param>
  /// <returns>nil if it is not a Qualified Name, otherwise, update len with the length in byte of the prefix and return a pointer to the start of the name without the prefix</returns>
  xmlSplitQName3            : function(const name: xmlCharPtr; var len: Integer): xmlCharPtr; cdecl;

  /// <summary>Create a DTD node.
  /// If a document is provided and it already has an internal subset, the existing DTD object is returned without creating a new object.
  /// If the document has no internal subset, it will be set to the created DTD.
  /// </summary>
  /// <param name="doc">the document pointer (optional) </param>
  /// <param name="name">the DTD name (optional) </param>
  /// <param name="publicId">public identifier of the DTD (optional) </param>
  /// <param name="systemId">system identifier (URL) of the DTD (optional)</param>
  /// <returns>a pointer to the new or existing DTD object or nil if arguments are invalid or a memory allocation failed.</returns>
  xmlCreateIntSubset        : function(doc: xmlDocPtr; const name, publicId, systemId: xmlCharPtr): xmlDtdPtr; cdecl;


  /// <summary></summary>
  /// <param name="doc">the document pointer (optional) </param>
  /// <param name="name">the DTD name (optional) </param>
  /// <param name="ExternalID">public identifier of the DTD (optional) </param>
  /// <param name="SystemID">system identifier (URL) of the DTD (optional)</param>
  /// <returns></returns>
  xmlNewDtd                 : function(doc: xmlDocPtr; const name, ExternalID, SystemID: xmlCharPtr): xmlDtdPtr; cdecl;

  /// <summary>Get the internal subset of a document. </summary>
  /// <param name="doc">the document pointer </param>
  /// <returns>a pointer to the DTD object or nil if not found. </returns>
  xmlGetIntSubset           : function(doc: xmlDocPtr): xmlDtdPtr; cdecl;

  /// <summary>Free a DTD structure. </summary>
  /// <param name="cur">The DTD structure to free up </param>
  xmlFreeDtd                : procedure(cur: xmlDtdPtr); cdecl;

  /// <summary>Create a new namespace.
  ///
  /// For a default namespace, prefix should be nil. The namespace URI in href is not checked. You should make sure to pass a valid URI.
  ///
  /// If node is provided, it must be an element node. The namespace will be appended to the node's namespace declarations. It is an error if the node already has a definition for the prefix or default namespace.
  /// </summary>
  /// <param name="node">the element carrying the namespace (optional) </param>
  /// <param name="href">the URI associated </param>
  /// <param name="prefix">the prefix for the namespace (optional) </param>
  /// <returns></returns>
  xmlNewNs                  : function(node: xmlNodePtr; const href, prefix: xmlCharPtr): xmlNsPtr; cdecl;

  /// <summary>Free an xmlNs object. </summary>
  /// <param name="cur">the namespace pointer</param>
  xmlFreeNs                 : procedure(cur: xmlNsPtr); cdecl;

  /// <summary>Free a list of xmlNs objects. </summary>
  /// <param name="cur">the first namespace pointer </param>
  xmlFreeNsList             : procedure(cur: xmlNsPtr); cdecl;

  /// <summary>
  ///  Creates a new XML document.
  ///  If version is nil, "1.0" is used.
  /// </summary>
  /// <param name="version">XML version string like "1.0" (optional) </param>
  /// <returns>a new document or nil if a memory allocation failed. </returns>
  xmlNewDoc                 : function(const version: xmlCharPtr): xmlDocPtr; cdecl;

  /// <summary>Free a document including all children and associated DTDs. </summary>
  /// <param name="cur">pointer to the document </param>
  xmlFreeDoc                : procedure(cur: xmlDocPtr); cdecl;

  /// <summary>
  ///  Create an attribute node.
  ///
  ///  If provided, value is expected to be a valid XML attribute value possibly containing character and entity references.
  ///  Syntax errors and references to undeclared entities are ignored silently. If you want to pass a raw string, see <see cref="xmlNewProp"/>.
  ///</summary>
  /// <param name="doc">the target document (optional) </param>
  /// <param name="name">the name of the attribute </param>
  /// <param name="value">attribute value with XML references (optional) </param>
  /// <returns>a pointer to the attribute or nil if arguments are invalid or a memory allocation failed. </returns>
  xmlNewDocProp             : function(doc: xmlDocPtr; const name, value: xmlCharPtr): xmlAttrPtr; cdecl;

  /// <summary>
  /// Create an attribute node.
  /// If provided, value should be a raw, unescaped string.
  /// If node is provided, the created attribute will be appended without checking for duplicate names. It is an error if node is not an element.
  /// </summary>
  /// <param name="node">the parent node (optional) </param>
  /// <param name="name">the name of the attribute </param>
  /// <param name="value">the value of the attribute (optional) </param>
  /// <returns></returns>
  xmlNewProp                : function(node: xmlNodePtr; const name, value: xmlCharPtr): xmlAttrPtr; cdecl;

  /// <summary>Create an attribute node.
  /// If provided, value should be a raw, unescaped string.
  /// If node is provided, the created attribute will be appended without checking for duplicate names. It is an error if node is not an element.</summary>
  /// <param name="node">the parent node (optional) </param>
  /// <param name="ns">the namespace (optional) </param>
  /// <param name="name">the local name of the attribute </param>
  /// <param name="value">the value of the attribute (optional) </param>
  /// <returns>a pointer to the attribute or nil if arguments are invalid or a memory allocation failed. </returns>
  xmlNewNsProp              : function(node: xmlNodePtr; ns: xmlNsPtr; const name, value: xmlCharPtr): xmlAttrPtr; cdecl;

  /// <summary>
  ///  Create an attribute node.
  /// Like <see cref="xmlNewNsProp"/>, but the name string will be used directly without making a copy. Takes ownership of name which will also be freed on error.
  /// </summary>
  /// <param name="node">the parent node (optional) </param>
  /// <param name="ns">the namespace (optional) </param>
  /// <param name="name">the local name of the attribute </param>
  /// <param name="value">the value of the attribute (optional) </param>
  /// <returns></returns>
  xmlNewNsPropEatName       : function(node: xmlNodePtr; ns: xmlNsPtr; name: xmlCharPtr; const value: xmlCharPtr): xmlAttrPtr; cdecl;

  /// <summary>Free an attribute list including all children. </summary>
  /// <param name="cur">the first attribute in the list </param>
  xmlFreePropList           : procedure(cur: xmlAttrPtr); cdecl;

  /// <summary>Free an attribute including all children. </summary>
  /// <param name="cur">an attribute </param>
  xmlFreeProp               : procedure(cur: xmlAttrPtr); cdecl;

  /// <summary>
  ///  Create a copy of the attribute.
  ///  This function sets the parent pointer of the copy to target but doesn't set the attribute on the target element. Users should consider to set the attribute by calling <see cref="xmlAddChild"/> afterwards or reset the parent pointer to nil.
  /// </summary>
  /// <param name="target">the element where the attribute will be grafted </param>
  /// <param name="cur">the attribute</param>
  /// <returns>the copied attribute or nil if a memory allocation failed. </returns>
  xmlCopyProp               : function(target: xmlNodePtr; cur: xmlAttrPtr): xmlAttrPtr; cdecl;

  /// <summary>
  ///  Create a copy of an attribute list.
  /// This function sets the parent pointers of the copied attributes to target but doesn't set the attributes on the target element
  /// </summary>
  /// <param name="target">the element where the attributes will be grafted </param>
  /// <param name="cur">the first attribute </param>
  /// <returns>the head of the copied list or nil if a memory allocation failed. </returns>
  xmlCopyPropList           : function(target: xmlNodePtr; cur: xmlAttrPtr): xmlAttrPtr; cdecl;

  /// <summary>Copy a DTD.</summary>
  /// <param name="dtd">the DTD </param>
  /// <returns>the copied DTD or nil if a memory allocation failed.</returns>
  xmlCopyDtd                : function(dtd: xmlDtdPtr): xmlDtdPtr; cdecl;

  /// <summary>Copy a document.
  /// If recursive, the content tree will be copied too as well as DTD, namespaces and entities.</summary>
  /// <param name="doc">the document </param>
  /// <param name="recursive">if not zero do a recursive copy.</param>
  /// <returns>the copied document or nil if a memory allocation failed. </returns>
  xmlCopyDoc                : function(doc: xmlDocPtr; recursive: Integer): xmlDocPtr; cdecl;

  /// <summary>
  /// <para>
  /// Create an element node.
  /// </para>
  /// <para>
  /// If provided, content is expected to be a valid XML attribute value possibly containing character and entity references. Syntax errors and references to undeclared entities are ignored silently. Only references are handled, nested elements, comments or PIs are not. See <see cref="xmlNewDocRawNode"/> for an alternative.
  /// </para>
  /// <para>
  /// General notes on object creation:
  /// </para>
  /// <para>
  /// Each node and all its children are associated with the same document. The document should be provided when creating nodes to avoid a performance penalty when adding the node to a document tree. Note that a document only owns nodes reachable from the root node. Unlinked subtrees must be freed manually.
  /// </para>
  ///</summary>
  /// <param name="doc">the target document </param>
  /// <param name="ns">namespace (optional)</param>
  /// <param name="name">the node name</param>
  /// <param name="content">text content with XML references (optional) </param>
  /// <returns>a pointer to the new node object or nil if arguments are invalid or a memory allocation failed.</returns>
  xmlNewDocNode             : function(doc: xmlDocPtr; ns: xmlNsPtr; const name, content: xmlCharPtr): xmlNodePtr; cdecl;

  /// <summary>
  ///  Create an element node.
  /// Like <see cref="xmlNewDocNode"/>, but the name string will be used directly without making a copy. Takes ownership of name which will also be freed on error.
  ///</summary>
  /// <param name="doc">the target document </param>
  /// <param name="ns">namespace (optional)</param>
  /// <param name="name">the node name</param>
  /// <param name="content">text content with XML references (optional) </param>
  /// <returns>a pointer to the new node object or nil if arguments are invalid or a memory allocation failed.</returns>
  xmlNewDocNodeEatName      : function(doc: xmlDocPtr; ns: xmlNsPtr; const name, content: xmlCharPtr): xmlNodePtr; cdecl;

  /// <summary>Create a new child element and append it to a parent element.
  /// If ns is nil, the newly created element inherits the namespace of the parent.
  /// If provided, content is expected to be a valid XML attribute value possibly containing character and entity references. Text and entity reference node will be added to the child element, see xmlNewDocNode().</summary>
  /// <param name="parent">the parent node</param>
  /// <param name="ns">a namespace (optional)</param>
  /// <param name="name">the name of the child </param>
  /// <param name="content">text content with XML references (optional)</param>
  /// <returns>a pointer to the new node object or nil if arguments are invalid or a memory allocation failed. </returns>
  xmlNewChild               : function(parent: xmlNodePtr; ns: xmlNsPtr; const name, content: xmlCharPtr): xmlNodePtr; cdecl;

  /// <summary>Create a new text node. </summary>
  /// <param name="doc">the target document</param>
  /// <param name="content">raw text content (optional) </param>
  /// <returns>a pointer to the new node object or nil if a memory allocation failed. </returns>
  xmlNewDocText             : function(const doc: xmlDocPtr; content: xmlCharPtr): xmlNodePtr; cdecl;

  /// <summary>Create a processing instruction object. </summary>
  /// <param name="doc">the target document (optional) </param>
  /// <param name="name">the processing instruction target</param>
  /// <param name="content">the PI content (optional) </param>
  /// <returns>a pointer to the new node object or nil if arguments are invalid or a memory allocation failed.</returns>
  xmlNewDocPI               : function(doc: xmlDocPtr; const name, content: xmlCharPtr): xmlNodePtr; cdecl;

  /// <summary>Create a new text node.</summary>
  /// <param name="doc">the target document</param>
  /// <param name="content">raw text content (optional)</param>
  /// <param name="len">size of text content</param>
  /// <returns>Returns a pointer to the new node object or nil if a memory allocation failed.</returns>
  xmlNewDocTextLen          : function(doc: xmlDocPtr; const content: xmlCharPtr; len: Integer): xmlNodePtr; cdecl;

  /// <summary>Create a comment node.</summary>
  /// <param name="doc">the document</param>
  /// <param name="content">the comment content</param>
  /// <returns>Returns a pointer to the new node object or nil if a memory allocation failed.</returns>
  xmlNewDocComment          : function(doc: xmlDocPtr; const content: xmlCharPtr): xmlNodePtr; cdecl;

  /// <summary>Create a CDATA section node.</summary>
  /// <param name="doc">the document</param>
  /// <param name="content">the comment content</param>
  /// <param name="len">size of text content</param>
  /// <returns>Returns a pointer to the new node object or nil if a memory allocation failed.</returns>
  xmlNewCDataBlock          : function(doc: xmlDocPtr; const content: xmlCharPtr; len: Integer): xmlNodePtr; cdecl;

  /// <summary>
  ///  This function is MISNAMED. It doesn't create a character reference but an entity reference.
  ///  Create an empty entity reference node. This function doesn't attempt to look up the entity in doc.
  ///  Entity names like '&entity;' are handled as well
  /// </summary>
  /// <param name="doc">the target document (optional)</param>
  /// <param name="name">the entity name</param>
  /// <returns>Returns a pointer to the new node object or nil if arguments are invalid or a memory allocation failed.</returns>
  xmlNewCharRef             : function(doc: xmlDocPtr; const name: xmlCharPtr): xmlNodePtr; cdecl;

  /// <summary>
  /// Create a new entity reference node, linking the result with the entity in doc if found.
  /// Entity names like '&entity;' are handled as we</summary>
  /// <param name="doc">the target document (optional)</param>
  /// <param name="name">the entity name</param>
  /// <returns>Returns a pointer to the new node object or nil if arguments are invalid or a memory allocation failed.</returns>
  xmlNewReference           : function(doc: xmlDocPtr; const name: xmlCharPtr): xmlNodePtr; cdecl;

  /// <summary>Copy a node into another document.</summary>
  /// <param name="node">the node</param>
  /// <param name="doc">the document</param>
  /// <param name="recursive">
  /// if 1 do a recursive copy (properties, namespaces and children when applicable)
  /// if 2 copy properties and namespaces (when applicable)
  // </param>
  /// <returns>Returns the copied node or nil if a memory allocation failed.</returns>
  xmlDocCopyNode            : function(node: xmlNodePtr; doc: xmlDocPtr; recursive: Integer): xmlNodePtr; cdecl;

  /// <summary>Copy a node list and all children into a new document.</summary>
  /// <param name="doc">the target document</param>
  /// <param name="node"the first node in the list.></param>
  /// <returns>Returns the head of the copied list or nil if a memory allocation failed.</returns>
  xmlDocCopyNodeList        : function(doc: xmlDocPtr; node: xmlNodePtr): xmlNodePtr; cdecl;

  /// <summary>
  ///  Create a new child element and append it to a parent element.
  ///
  /// If ns is nil, the newly created element inherits the namespace
  /// of the parent.
  ///
  /// If content is provided, a text node will be added to the child
  /// element, <see cref="xmlNewDocRawNode"/>.
  /// </summary>
  /// <param name="parent">the parent node</param>
  /// <param name="ns">a namespace (optional)</param>
  /// <param name="name">the name of the child</param>
  /// <param name="content">raw text content of the child (optional)</param>
  /// <returns>Returns a pointer to the new node object or nil if arguments are invalid or a memory allocation failed.</returns>
  xmlNewTextChild           : function(parent: xmlNodePtr; ns: xmlNsPtr; const name, content: xmlCharPtr): xmlNodePtr; cdecl;

  /// <summary>
  /// Create an element node.
  ///
  /// If provided, content should be a raw, unescaped string.
  ///
  /// Returns a pointer to the new node object or nil if arguments are
  /// invalid or a memory allocation failed.
  ///</summary>
  /// <param name="doc">the target document</param>
  /// <param name="ns">a namespace (optional)</param>
  /// <param name="name">the node name</param>
  /// <param name="content">raw text content (optional)</param>
  /// <returns>Returns a pointer to the new node object or nil if arguments are invalid or a memory allocation failed.</returns>
  xmlNewDocRawNode          : function(doc: xmlDocPtr; ns: xmlNsPtr; const name, content: xmlCharPtr): xmlNodePtr; cdecl;

  /// <summary>Create a document fragment node.</summary>
  /// <param name="doc">the target document (optional)</param>
  /// <returns>Returns a pointer to the new node object or nil if a memory allocation failed.</returns>
  xmlNewDocFragment         : function(doc: xmlDocPtr): xmlNodePtr; cdecl;

  /// <summary>
  /// Get line number of node.
  /// Try to override the limitation of lines being store in 16 bits ints
  /// if XML_PARSE_BIG_LINES parser option was used
  /// </summary>
  /// <param name="node">valid node</param>
  /// <returns>Returns the line number if successful, -1 otherwise</returns>
  xmlGetLineNo              : function(const node: xmlNodePtr): LongInt; cdecl;

  /// <summary>Build a structure based Path for the given node</summary>
  /// <param name="node">a node</param>
  /// <returns>Returns the new path or nil in case of error. The caller must free the returned string</returns>
  xmlGetNodePath            : function(const node: xmlNodePtr): xmlCharPtr; cdecl;

  /// <summary>Get the root element of the document (doc.children is a list containing possibly comments, PIs, etc ...).</summary>
  /// <param name="doc">the document</param>
  /// <returns>Returns the root element or nil if no element was found.</returns>
  xmlDocGetRootElement      : function(const doc: xmlDocPtr): xmlNodePtr; cdecl;

  /// <summary>Find the last child of a node.</summary>
  /// <param name="parent">the parent node</param>
  /// <returns>Returns the last child or mil if parent has no children.</returns>
  xmlGetLastChild           : function(const parent: xmlNodePtr): xmlNodePtr; cdecl;

  /// <summary>Is this node a Text node ?</summary>
  /// <param name="node">the node</param>
  /// <returns>Returns 1 yes, 0 no</returns>
  xmlNodeIsText             : function(const node: xmlNodePtr): Integer; cdecl;

  /// <summary>Checks whether this node is an empty or whitespace only (and possibly ignorable) text-node.</summary>
  /// <param name="node">The node</param>
  /// <returns>Returns 1 yes, 0 no</returns>
  xmlIsBlankNode            : function(const node: xmlNodePtr): Integer; cdecl;

  /// <summary>
  ///  Set the root element of the document (doc.children is a list
  ///  containing possibly comments, PIs, etc ...).
  ///
  /// root must be an element node. It is unlinked before insertion.
  /// </summary>
  /// <param name="doc">the document</param>
  /// <param name="root">the new document root element, if root is nil no action is taken, to remove a node from a document use xmlUnlinkNode(root) instead.</param>
  /// <returns>Returns the unlinked old root element or nil if the document didn't have a root element or a memory allocation failed.</returns>
  xmlDocSetRootElement      : function(doc: xmlDocPtr; root: xmlNodePtr): xmlNodePtr; cdecl;

  /// <summary>Set (or reset) the name of a node.</summary>
  /// <param name="cur">the node being changed</param>
  /// <param name="name">the new tag name</param>
  xmlNodeSetName            : procedure(cur: xmlNodePtr; const name: xmlCharPtr); cdecl;

  /// <summary>
  ///
  /// Unlink cur and append it to the children of parent.
  ///
  /// If cur is a text node, it may be merged with an adjacent text
  /// node and freed. In this case the text node containing the merged
  /// content is returned.
  ///
  /// If cur is an attribute node, it is appended to the attributes of
  /// parent. If the attribute list contains an attribute with a name
  /// matching cur, the old attribute is destroyed.
  ///
  /// General notes:
  ///
  /// Move operations like xmlAddChild can cause element or attribute
  /// nodes to reference namespaces that aren't declared in one of
  /// their ancestors. This can lead to use-after-free errors if the
  /// elements containing the declarations are freed later, especially
  /// when moving nodes from one document to another. You should
  /// consider calling xmlReconciliateNs after a move operation to
  /// normalize namespaces. Another option is to call
  /// xmlDOMWrapAdoptNode with the target parent before moving a node.
  ///
  /// For the most part, move operations don't check whether the
  /// resulting tree structure is valid. Users must make sure that
  /// parent nodes only receive children of valid types. Inserted
  /// child nodes must never be an ancestor of the parent node to
  /// avoid cycles in the tree structure. In general, only
  /// document, document fragments, elements and attributes
  /// should be used as parent nodes.
  ///
  /// When moving a node between documents and a memory allocation
  /// fails, the node's content will be corrupted and it will be
  /// unlinked. In this case, the node must be freed manually.
  ///
  /// Moving DTDs between documents isn't supported.
  /// </summary>
  /// <param name="parent">the parent node</param>
  /// <param name="cur">the child node</param>
  /// <returns>Returns cur or a sibling if cur was merged. Returns nil if arguments are invalid or a memory allocation failed.</returns>
  xmlAddChild               : function(parent, cur: xmlNodePtr): xmlNodePtr; cdecl;

  /// <summary>
  ///  Append a node list to another node. <see cref="xmlAddChild"/>
  /// <summary>
  /// <param name="parent">the parent node</param>
  /// <param name="cur">the first node in the list</param>
  /// <returns>Returns the last child or nil in case of error.</returns>
  xmlAddChildList           : function(parent, cur: xmlNodePtr): xmlNodePtr; cdecl;

  /// <summary>
  /// Unlink the old node. If cur is provided, it is unlinked and
  /// inserted in place of old.
  ///
  /// It is an error if old has no parent.
  ///
  /// Unlike xmlAddChild, this function doesn't merge text nodes or
  /// delete duplicate attributes.
  ///
  /// See the notes in <see cref="xmlAddChild"/>.
  /// </summary>
  /// <param name="old">the old node</param>
  /// <param name="cur">the node (optional)</param>
  /// <returns>Returns old or nil if arguments are invalid or a memory allocation failed.</returns>
  xmlReplaceNode            : function(old, cur: xmlNodePtr): xmlNodePtr; cdecl;

  /// <summary>
  /// Unlinks cur and inserts it as previous sibling before @next.
  ///
  /// Unlike xmlAddChild this function does not merge text nodes.
  ///
  /// If cur is an attribute node, it is inserted before attribute
  /// @next. If the attribute list contains an attribute with a name
  /// matching @cur, the old attribute is destroyed.
  ///
  /// See the notes in <see cref="xmlAddChild"/>.
  ///</summary>
  /// <param name="next">the target node</param>
  /// <param name="cur">new node</param>
  /// <returns>Returns @cur or a sibling if @cur was merged. Returns nil if arguments are invalid or a memory allocation failed.</returns>
  xmlAddPrevSibling         : function(next, cur: xmlNodePtr): xmlNodePtr; cdecl;

  /// <summary>
  /// Unlinks cur and inserts it as last sibling of node.
  ///
  /// If cur is a text node, it may be merged with an adjacent text
  /// node and freed. In this case the text node containing the merged
  /// content is returned.
  ///
  /// If cur is an attribute node, it is appended to the attribute
  /// list containing @node. If the attribute list contains an attribute
  /// with a name matching cur, the old attribute is destroyed.
  ///
  /// See the notes in <see cref="xmlAddChild"/>.
  ///</summary>
  /// <param name="node">the target node</param>
  /// <param name="cur">the new node</param>
  /// <returns>Returns @cur or a sibling if @cur was merged. Returns nil if arguments are invalid or a memory allocation failed.</returns>
  xmlAddSibling             : function(node, cur: xmlNodePtr): xmlNodePtr; cdecl;

  /// <summary>
  /// Unlinks cur and inserts it as next sibling after prev.
  ///
  /// Unlike xmlAddChild this function does not merge text nodes.
  ///
  /// If cur is an attribute node, it is inserted after attribute
  /// prev. If the attribute list contains an attribute with a name
  /// matching cur, the old attribute is destroyed.
  ///
  /// See the notes in <see cref="xmlAddChild"/>.
  /// </summary>
  /// <param name="prev">the target node</param>
  /// <param name="cur">the new node</param>
  /// <returns>Returns cur or a sibling if @cur was merged. Returns nil if arguments are invalid or a memory allocation failed.</returns>
  xmlAddNextSibling         : function(prev, cur: xmlNodePtr): xmlNodePtr; cdecl;

  /// <summary>
  /// Unlink a node from its tree.
  ///
  /// The node is not freed. Unless it is reinserted, it must be managed
  /// manually and freed eventually by calling xmlFreeNode.
  ///</summary>
  /// <param name="cur">the node</param>
  xmlUnlinkNode             : procedure(cur: xmlNodePtr); cdecl;

  /// <summary>Merge the second text node into the first. If first is nil, second is returned. Otherwise, the second node is unlinked and freed.</summary>
  /// <param name="first">the first text node</param>
  /// <param name="second">the second text node being merged</param>
  /// <returns>Returns the first text node augmented or nil in case of error.</returns>
  xmlTextMerge              : function(first, second: xmlNodePtr): xmlNodePtr; cdecl;

  /// <summary>
  /// Concat the given string at the end of the existing node content.
  ///
  /// If len is -1, the string length will be calculated.
  /// </summary>
  /// <param name="node">the node</param>
  /// <param name="content">the content</param>
  /// <param name="len">content len</param>
  /// <returns>Returns -1 in case of error, 0 otherwise</returns>
  xmlTextConcat             : function(node: xmlNodePtr; const content: xmlCharPtr; len: Integer): Integer; cdecl;

  /// <summary>Free a node list including all children.</summary>
  /// <param name="cur">the first node in the list</param>
  xmlFreeNodeList           : procedure(cur: xmlNodePtr); cdecl;

  /// <summary>
  ///  Free a node including all the children.
  ///
  /// This doesn't unlink the node from the tree. Call xmlUnlinkNode first unless cur is a root node.
  ///</summary>
  /// <param name="cur">The node</param>
  xmlFreeNode               : procedure(cur: xmlNodePtr); cdecl;

  /// <summary>Set (or reset) an attribute carried by a node.
  /// If name has a prefix, then the corresponding namespace-binding will be used, if in scope; it is an error it there's no such ns-binding for the prefix in scope.</summary>
  /// <param name="node">the node</param>
  /// <param name="name">the attribute name (a QName)</param>
  /// <param name="value">the attribute value</param>
  /// <returns>Returns the attribute pointer.</returns>
  xmlSetProp                : function(node: xmlNodePtr; const name, value: xmlCharPtr): xmlAttrPtr; cdecl;

  /// <summary>Set (or reset) an attribute carried by a node. The ns structure must be in scope, this is not checked</summary>
  /// <param name="node">the node</param>
  /// <param name="ns">the namespace definition</param>
  /// <param name="name">the attribute name</param>
  /// <param name="value">the attribute value</param>
  /// <returns>Returns the attribute pointer.</returns>
  xmlSetNsProp              : function(node: xmlNodePtr; ns: xmlNsPtr; const name, value: xmlCharPtr): xmlAttrPtr; cdecl;

  /// <summary>
  /// Search and get the value of an attribute associated to a node
  /// This attribute has to be anchored in the namespace specified.
  /// This does the entity substitution. The returned value must be
  /// freed by the caller.
  ///
  /// Returns 0 on success, 1 if no attribute was found, -1 if a memory allocation failed.
  /// </summary>
  /// <param name="node">the node</param>
  /// <param name="name">the attribute name</param>
  /// <param name="nsUri">the URI of the namespace</param>
  /// <param name="out">the returned string</param>
  /// <returns></returns>
  xmlNodeGetAttrValue       : function(const node: xmlNodePtr; const name, nsUri: xmlCharPtr; var &out: xmlCharPtr): Integer; cdecl;

  /// <summary>
  /// Search and get the value of an attribute associated to a node.
  /// This does the entity substitution.
  /// This function looks in DTD attribute declaration for #FIXED or default declaration values.
  /// </summary>
  /// <remarks>
  /// This function acts independently of namespaces associated to the attribute. Use xmlGetNsProp() or xmlGetNoNsProp() for namespace aware processing.
  ///
  /// This function doesn't allow to distinguish malloc failures from  missing attributes. It's more robust to use xmlNodeGetAttrValue.
  /// </remarks>
  /// <param name="node">the node</param>
  /// <param name="name">the attribute name</param>
  /// <returns></returns>
  xmlGetProp                : function(const node: xmlNodePtr; const name: xmlCharPtr): xmlCharPtr; cdecl;

  /// <summary>
  /// Search an attribute associated to a node
  /// This function also looks in DTD attribute declaration for #FIXED or default declaration values.
  /// </summary>
  /// <param name="node">the node</param>
  /// <param name="name">the attribute name</param>
  /// <returns>Returns the attribute or the attribute declaration or nil if neither was found.
  /// Also returns nill if a memory allocation failed making this function unreliable.
  /// </returns>
  xmlHasProp                : function(const node: xmlNodePtr; const name: xmlCharPtr): xmlAttrPtr; cdecl;

  /// <summary>
  /// Search for an attribute associated to a node
  /// This attribute has to be anchored in the namespace specified.
  /// This does the entity substitution.
  /// This function looks in DTD attribute declaration for #FIXED or default declaration values.
  /// Note that a namespace of nil indicates to use the default namespace.
  /// </summary>
  /// <param name="node">the node</param>
  /// <param name="name">the attribute name</param>
  /// <param name="nameSpace">the URI of the namespace</param>
  /// <returns>
  /// Returns the attribute or the attribute declaration or nil if neither was found. Also returns nil if a memory allocation failed making this function unreliable.
  /// </returns>
  xmlHasNsProp              : function(const node: xmlNodePtr; const name, nameSpace: xmlCharPtr): xmlAttrPtr; cdecl;

  /// <summary>
  /// Search for an attribute associated to a node
  /// This attribute has to be anchored in the namespace specified.
  /// This does the entity substitution.
  /// This function looks in DTD attribute declaration for #FIXED or
  /// default declaration values.
  /// Note that a namespace of nil indicates to use the default namespace.
  /// </summary>
  /// <param name="node">the node</param>
  /// <param name="name">the attribute name</param>
  /// <param name="nameSpace">the URI of the namespace</param>
  /// <returns>
  /// Returns the attribute or the attribute declaration or nil if
  /// neither was found. Also returns nil if a memory allocation failed
  /// making this function unreliable.
  ///</returns>
  xmlGetNsProp              : function(const node: xmlNodePtr; const name, nameSpace: xmlCharPtr): xmlCharPtr; cdecl;

  /// <summary>
  /// Serializes attribute children (text and entity reference nodes) into a string.
  ///
  /// If inLine is true, entity references will be substituted.
  /// Otherwise, entity references will be kept and special characters
  /// like '&' as well as non-ASCII chars will be escaped. See <see cref="xmlNodeListGetRawString"/> for an alternative option.
  /// </summary>
  /// <param name="doc">a document (optional)</param>
  /// <param name="list">a node list of attribute children</param>
  /// <param name="inLine">whether entity references are substituted</param>
  /// <returns>Returns a string or nil if a memory allocation failed.</returns>
  xmlNodeListGetString      : function(const doc: xmlDocPtr; const list: xmlNodePtr; &inLine: Integer): xmlCharPtr; cdecl;

  /// <summary>
  /// Serializes attribute children (text and entity reference nodes) into a string.
  ///
  /// If inLine is true, entity references will be substituted.
  /// Otherwise, entity references will be kept and special characters
  /// like '&' will be escaped.
  ///</summary>
  /// <param name="doc">a document (optional)</param>
  /// <param name="list">a node list of attribute children</param>
  /// <param name="inLine">whether entity references are substituted</param>
  /// <returns>Returns a string or nil if a memory allocation failed.</returns>
  xmlNodeListGetRawString   : function(const doc: xmlDocPtr; const list: xmlNodePtr; &inLine: Integer): xmlCharPtr; cdecl;

  /// <summary>
  /// Replace the text content of a node.
  ///
  /// Sets the raw text content of text, CDATA, comment or PI nodes.
  ///
  /// For element and attribute nodes, removes all children and
  /// replaces them by parsing content which is expected to be a
  /// valid XML attribute value possibly containing character and
  /// entity references. Syntax errors and references to undeclared
  /// entities are ignored silently. Unfortunately, there isn't an
  /// API to pass raw content directly. An inefficient work-around
  /// is to escape the content with xmlEncodeSpecialChars before
  /// passing it. A better trick is clearing the old content
  /// with xmlNodeSetContent(node, nil) first and then calling
  /// xmlNodeAddContent(node, content). Unlike this function,
  /// xmlNodeAddContent accepts raw text.
  /// </summary>
  /// <param name="cur">the node being modified</param>
  /// <param name="content">the new value of the content</param>
  /// <returns></returns>
  xmlNodeSetContent         : function(const cur: xmlNodePtr; const content: xmlCharPtr): Integer; cdecl;

  /// <summary>See <see cref="xmlNodeSetContent"/>.</summary>
  /// <param name="cur">the node being modified</param>
  /// <param name="content">the new value of the content</param>
  /// <param name="len">the size of content</param>
  /// <returns>Returns 0 on success, 1 on error, -1 if a memory allocation failed.</returns>
  xmlNodeSetContentLen      : function(const cur: xmlNodePtr; const content: xmlCharPtr; len: Integer): Integer; cdecl;

  /// <summary>Append the extra substring to the node content.</summary>
  /// <remarks>In contrast to xmlNodeSetContent(), content is supposed to be raw text, so unescaped XML special chars are allowed, entity references are not supported.</remarks>
  /// <param name="cur">the node being modified</param>
  /// <param name="content">extra content</param>
  /// <returns>Returns 0 on success, 1 on error, -1 if a memory allocation failed.</returns>
  xmlNodeAddContent         : function(const cur: xmlNodePtr; const content: xmlCharPtr): Integer; cdecl;

  /// <summary>Append the extra substring to the node content.</summary>
  /// <remarks>In contrast to xmlNodeSetContentLen(), content is supposed to be raw text, so unescaped XML special chars are allowed, entity references are not supported.</remarks>
  /// <param name="cur">the node being modified</param>
  /// <param name="content">extra content</param>
  /// <param name="len">the size of content</param>
  /// <returns>Returns 0 on success, 1 on error, -1 if a memory allocation failed.</returns>
  xmlNodeAddContentLen      : function(const cur: xmlNodePtr; const content: xmlCharPtr; len: Integer): Integer; cdecl;

  /// <summary>
  /// Read the value of a node, this can be either the text carried
  /// directly by this node if it's a TEXT node or the aggregate string
  /// of the values carried by this node child's (TEXT and ENTITY_REF).
  /// Entity references are substituted.
  /// </summary>
  /// <param name="cur">the node being read</param>
  /// <returns>
  /// Returns a new xmlCharPtr or nil if no content is available.
  /// It's up to the caller to free the memory with xmlFree().
  ///</returns>
  xmlNodeGetContent         : function(const cur: xmlNodePtr): xmlCharPtr; cdecl;

  /// <summary>
  /// Read the value of a node cur, this can be either the text carried
  /// directly by this node if it's a TEXT node or the aggregate string
  /// of the values carried by this node child's (TEXT and ENTITY_REF).
  /// Entity references are substituted.
  /// Fills up the buffer buf with this value
  /// </summary>
  /// <param name="buf">a buffer xmlBufPtr</param>
  /// <param name="cur">the node being read</param>
  /// <returns>Returns 0 in case of success and -1 in case of error.</returns>
  xmlBufGetNodeContent      : function(buf: xmlBufPtr; cur: xmlNodePtr): Integer; cdecl;

  /// <summary>Searches the language of a node, i.e. the values of the xml:lang attribute or the one carried by the nearest ancestor.</summary>
  /// <param name="cur">the node being checked</param>
  /// <returns>
  /// Returns a pointer to the lang value, or nil if not found.
  /// It's up to the caller to free the memory with xmlFree().
  /// </returns>
  xmlNodeGetLang            : function(const cur: xmlNodePtr): xmlCharPtr; cdecl;

  /// <summary>Searches the space preserving behaviour of a node, i.e. the values of the xml:space attribute or the one carried by the nearest ancestor.</summary>
  /// <param name="cur">the node being checked</param>
  /// <returns>Returns -1 if xml:space is not inherited, 0 if "default", 1 if "preserve"</returns>
  xmlNodeGetSpacePreserve   : function(const cur: xmlNodePtr): Integer; cdecl;

  /// <summary>Set the language of a node, i.e. the values of the xml:lang attribute.</summary>
  /// <param name="cur">the node being changed</param>
  /// <param name="lang">the language description</param>
  /// <returns>Return 0 on success, 1 if arguments are invalid, -1 if a memory allocation failed.</returns>
  xmlNodeSetLang            : function(const cur: xmlNodePtr; const lang: xmlCharPtr): Integer; cdecl;

  /// <summary>Set (or reset) the space preserving behaviour of a node, i.e. the value of the xml:space attribute.</summary>
  /// <param name="cur">the node being changed</param>
  /// <param name="val">the xml:space value ("0": default, 1: "preserve")</param>
  /// <returns>Return 0 on success, 1 if arguments are invalid, -1 if a memory allocation failed.</returns>
  xmlNodeSetSpacePreserve   : function(const cur: xmlNodePtr; val: Integer): Integer; cdecl;

  /// <summary>
  /// Searches for the BASE URL. The code should work on both XML
  /// and HTML document even if base mechanisms are completely different.
  /// It returns the base as defined in RFC 2396 sections
  /// 5.1.1. Base URI within Document Content
  /// and
  /// 5.1.2. Base URI from the Encapsulating Entity
  /// However it does not return the document base (5.1.3), use doc.URL in this case
  /// </summary>
  /// <param name="doc">the document the node pertains to</param>
  /// <param name="cur">the node being checked</param>
  /// <param name="baseOut">pointer to base</param>
  /// <returns>Return 0 in case of success, 1 if a URI or argument is invalid, -1 if a memory allocation failed.</returns>
  xmlNodeGetBaseSafe        : function(const doc: xmlDocPtr; const cur: xmlNodePtr; var baseOut: xmlCharPtr): Integer; cdecl;

  /// <summary>
  /// See <see cref="xmlNodeGetBaseSafe"/>.
  /// This function doesn't allow to distinguish memory allocation failures from a non-existing base.
  /// </summary>
  /// <param name="doc">the document the node pertains to</param>
  /// <param name="cur">the node being checked</param>
  /// <returns></returns>
  xmlNodeGetBase            : function(const doc: xmlDocPtr; const cur: xmlNodePtr): xmlCharPtr; cdecl;

  /// <summary>Set (or reset) the base URI of a node, i.e. the value of the xml:base attribute.</summary>
  /// <param name="cur">the node being changed</param>
  /// <param name="uri">the new base URI</param>
  /// <returns>Returns 0 on success, -1 on error.</returns>
  xmlNodeSetBase            : function(const cur: xmlNodePtr; const uri: xmlCharPtr): Integer; cdecl;

  /// <summary>
  /// Unlink and free an attribute including all children.
  ///
  /// Note this doesn't work for namespace declarations.
  ///
  /// The attribute must have a non-nill parent pointer.</summary>
  /// <param name="cur">an attribute</param>
  /// <returns>Returns 0 on success or -1 if the attribute was not found or arguments are invalid.</returns>
  xmlRemoveProp             : function(cur: xmlAttrPtr): Integer; cdecl;

  /// <summary>Remove an attribute carried by a node.</summary>
  /// <param name="node">the node</param>
  /// <param name="ns">the namespace definition</param>
  /// <param name="name">the attribute name</param>
  /// <returns>Returns 0 if successful, -1 if not found</returns>
  xmlUnsetNsProp            : function(node: xmlNodePtr; ns: xmlNsPtr; const name: xmlCharPtr): Integer; cdecl;

  /// <summary>Remove an attribute carried by a node.</summary>
  /// <param name="node">the node</param>
  /// <param name="name">the attribute name</param>
  /// <returns>Returns 0 if successful, -1 if not found</returns>
  xmlUnsetProp              : function(node: xmlNodePtr; const name: xmlCharPtr): Integer; cdecl;

  /// <summary>Serialize text attribute values to an xml simple buffer</summary>
  /// <param name="buf">the XML buffer output</param>
  /// <param name="doc">the document</param>
  /// <param name="attr">the attribute node</param>
  /// <param name="str">the text content</param>
  xmlAttrSerializeTxtContent: procedure(buf: xmlBufferPtr; doc: xmlDocPtr; attr: xmlAttrPtr; str: xmlCharPtr); cdecl;

  /// <summary>
  /// This function checks that all the namespaces declared within the given tree are properly declared.
  /// This is needed for example after Copy or Cut and then paste operations.
  /// The subtree may still hold pointers to namespace declarations outside the subtree or invalid/masked.
  /// As much as possible the function try to reuse the existing namespaces found in the new environment.
  /// If not possible the new namespaces are redeclared on tree at the top of the given subtree
  /// </summary>
  /// <param name="doc">the document</param>
  /// <param name="tree">a node defining the subtree to reconciliate</param>
  /// <returns>Returns 0 on success or -1 in case of error.</returns>
  xmlReconciliateNs         : function(doc: xmlDocPtr; tree: xmlNodePtr): Integer; cdecl;

  /// <summary>
  /// Dump an XML document in memory and return the #xmlChar and it's size.
  /// It's up to the caller to free the memory with xmlFree().
  /// Note that format = 1 provide node indenting only if xmlIndentTreeOutput = 1
  /// or xmlKeepBlanksDefault(0) was called
  /// </summary>
  /// <param name="cur">the document</param>
  /// <param name="mem">the memory pointer</param>
  /// <param name="size">the memory length</param>
  /// <param name="format">should formatting spaces been added</param>
  xmlDocDumpFormatMemory    : procedure(cur: xmlDocPtr; var mem: Pointer; var size: Integer; format: Integer); cdecl;

  /// <summary>
  /// Dump an XML document in memory and return the #xmlChar and it's size in bytes.
  /// It's up to the caller to free the memory with xmlFree().
  /// The resulting byte array is zero terminated, though the last 0 is not included in the returned size.
  /// </summary>
  /// <param name="cur">the document</param>
  /// <param name="mem">the memory pointer</param>
  /// <param name="size">the memory length</param>
  /// <returns></returns>
  xmlDocDumpMemory          : procedure(cur: xmlDocPtr; var mem: Pointer; var size: Integer); cdecl;

  /// <summary>
  /// Dump the current DOM tree into memory using the character encoding specified by the caller.
  /// Note it is up to the caller of this function to free the allocated memory with xmlFree().
  /// </summary>
  /// <param name="cur">Document to generate XML text from</param>
  /// <param name="mem">Memory pointer for allocated XML text</param>
  /// <param name="size">Length of the generated XML text</param>
  /// <param name="encoding">Character encoding to use when generating XML text</param>
  xmlDocDumpMemoryEnc       : procedure(cur: xmlDocPtr; var mem: Pointer; var size: Integer; const encoding: PUTF8Char); cdecl;

  /// <summary>
  /// Dump the current DOM tree into memory using the character encoding specified
  /// by the caller.  Note it is up to the caller of this function to free the
  /// allocated memory with xmlFree().
  /// Note that format = 1 provide node indenting only if xmlIndentTreeOutput = 1
  /// or xmlKeepBlanksDefault(0) was calle
  /// </summary>
  /// <param name="cur">Document to generate XML text from</param>
  /// <param name="mem">Memory pointer for allocated XML text</param>
  /// <param name="size">Length of the generated XML text</param>
  /// <param name="encoding">Character encoding to use when generating XML text</param>
  /// <param name="format">should formatting spaces been added</param>
  xmlDocDumpFormatMemoryEnc : procedure(cur: xmlDocPtr; var mem: Pointer; var size: Integer; const encoding: PUTF8Char; format: Integer); cdecl;

  /// <summary>
  /// Dump an XML node, recursive behaviour, children are printed too.
  /// Note that @format = 1 provide node indenting only if xmlIndentTreeOutput = 1 or xmlKeepBlanksDefault(0) was called
  /// </summary>
  /// <param name="buf">the XML buffer output</param>
  /// <param name="doc">the document</param>
  /// <param name="cur">the current node</param>
  /// <param name="level">the imbrication level for indenting</param>
  /// <param name="format">is formatting allowed</param>
  /// <returns>Returns the number of bytes written to the buffer, in case of error 0 is returned or buf stores the error</returns>
  xmlBufNodeDump            : function(buf: xmlBufPtr; doc: xmlDocPtr; cur: xmlNodePtr; level, format: Integer): size_t; cdecl;

  /// <summary>Try to find if the document correspond to an XHTML DTD</summary>
  /// <param name="systemID">the system identifier</param>
  /// <param name="publicID">the public identifier</param>
  /// <returns>Returns 1 if true, 0 if not and -1 in case of error</returns>
  xmlIsXHTML                : function(const systemID, publicID: xmlCharPtr): Integer; cdecl;

  /// <summary>get the compression ratio for a document, ZLIB based</summary>
  /// <param name="doc">the document</param>
  /// <returns>Returns 0 (uncompressed) to 9 (max compression)</returns>
  xmlGetDocCompressMode     : function(const doc: xmlDoc): Integer; cdecl;

  /// <summary>
  /// set the compression ratio for a document, ZLIB based
  /// Correct values: 0 (uncompressed) to 9 (max compression
  /// </summary>
  /// <param name="doc">the document</param>
  /// <param name="mode">the compression ratio</param>
  xmlSetDocCompressMode     : procedure(const doc: xmlDoc; mode: Integer); cdecl;

  /// <summary>Allocates and initializes a new DOM-wrapper context.</summary>
  /// <returns>Returns the xmlDOMWrapCtxtPtr or nil in case of an internal error.</returns>
  xmlDOMWrapNewCtxt         : function: xmlDOMWrapCtxtPtr; cdecl;

  /// <summary>Frees the DOM-wrapper context.</summary>
  /// <param name="ctxt">the DOM-wrapper context</param>
  xmlDOMWrapFreeCtxt        : procedure(ctxt: xmlDOMWrapCtxtPtr); cdecl;

  /// <summary>
  /// Ensures that ns-references point to ns-decls hold on element-nodes.
  /// Ensures that the tree is namespace wellformed by creating additional
  /// ns-decls where needed. Note that, since prefixes of already existent
  /// ns-decls can be shadowed by this process, it could break QNames in
  /// attribute values or element content.
  /// </summary>
  /// <param name="ctxt">DOM wrapper context, unused at the moment</param>
  /// <param name="elem">the element-node</param>
  /// <param name="options">option flags</param>
  /// <returns>Returns 0 if succeeded, -1 otherwise and on API/internal errors</returns>
  xmlDOMWrapReconcileNamespaces : function(ctxt: xmlDOMWrapCtxtPtr; elem: xmlNodePtr; options: Integer): Integer; cdecl;

  /// <summary>
  /// References of out-of scope ns-decls are remapped to point to destDoc:
  /// 1) If destParent is given, then nsDef entries on element-nodes are used
  /// 2) If no destParent is given, then destDoc.oldNs entries are used
  ///    This is the case when you have an unlinked node and just want to move it
  ///    to the context of
  ///
  /// If destParent is given, it ensures that the tree is namespace
  /// wellformed by creating additional ns-decls where needed.
  /// Note that, since prefixes of already existent ns-decls can be
  /// shadowed by this process, it could break QNames in attribute
  /// values or element content.
  /// </summary>
  /// <param name="ctxt">the optional context for custom processing</param>
  /// <param name="srcDoc">the optional sourceDoc</param>
  /// <param name="node">the node to start wit</param>
  /// <param name="destDoc">the destination doc</param>
  /// <param name="destParent">the optional new parent of node in destDoc</param>
  /// <param name="options">option flags</param>
  /// <returns>
  /// Returns 0 if the operation succeeded,
  ///         1 if a node of unsupported type was given,
  ///         2 if a node of not yet supported type was given and
  ///         -1 on API/internal errors.
  ///</returns>
  xmlDOMWrapAdoptNode       : function(ctxt: xmlDOMWrapCtxtPtr; srcDoc: xmlDocPtr; node: xmlNodePtr; destDoc: xmlDocPtr; destParent: xmlNodePtr; options: Integer): Integer; cdecl;

  /// <summary>
  /// Unlinks the given node from its owner.
  /// This will substitute ns-references to node.nsDef for
  /// ns-references to doc.oldNs, thus ensuring the removed
  /// branch to be autark wrt ns-references.
  /// </summary>
  /// <param name="ctxt">a DOM wrapper context</param>
  /// <param name="srcDoc">the doc</param>
  /// <param name="node">the node to be removed.</param>
  /// <param name="options">set of options, unused at the moment</param>
  /// <returns>Returns 0 on success, 1 if the node is not supported, -1 on API and internal errors.</returns>
  xmlDOMWrapRemoveNode      : function(ctxt: xmlDOMWrapCtxtPtr; srcDoc: xmlDocPtr; node: xmlNodePtr; options: Integer): Integer; cdecl;

  /// <summary>
  /// References of out-of scope ns-decls are remapped to point to destDoc:
  /// 1) If destParent is given, then nsDef entries on element-nodes are used
  /// 2) If no destParent is given, then destDoc.oldNs entries are used.
  ///    This is the case when you don't know already where the cloned branch
  ///    will be added to.
  ///
  /// If destParent is given, it ensures that the tree is namespace
  /// wellformed by creating additional ns-decls where needed.
  /// Note that, since prefixes of already existent ns-decls can be
  /// shadowed by this process, it could break QNames in attribute
  /// values or element content.
  /// </summary>
  /// <param name="ctxt">the optional context for custom processing</param>
  /// <param name="srcDoc">the optional sourceDoc</param>
  /// <param name="node">the node to start with</param>
  /// <param name="clonedNode">the clone of the given node</param>
  /// <param name="destDoc">the destination doc</param>
  /// <param name="destParent">the optional new parent of node in destDoc</param>
  /// <param name="deep">descend into child if set</param>
  /// <param name="options">option flags</param>
  /// <returns>
  /// Returns 0 if the operation succeeded,
  ///         1 if a node of unsupported (or not yet supported) type was given,
  ///         -1 on API/internal errors.
  /// </returns>
  xmlDOMWrapCloneNode       : function(ctxt: xmlDOMWrapCtxtPtr; srcDoc: xmlDocPtr; node: xmlNodePtr; var clonedNode: xmlNodePtr; destDoc: xmlDocPtr; destParent: xmlNodePtr; deep, options: Integer): Integer; cdecl;

  /// <summary>Count the number of child nodes which are elements.
  /// Note that entity references are not expanded.</summary>
  /// <param name="parent">the parent node</param>
  /// <returns>Returns the number of element children or 0 if arguments are invalid.</returns>
  xmlChildElementCount      : function(parent: xmlNodePtr): ulong; cdecl;

  /// <summary>
  /// Find the closest following sibling which is a element.
  /// Note that entity references are not expanded.</summary>
  /// <param name="node">the current node</param>
  /// <returns>Returns the sibling or nil if no sibling was found.</returns>
  xmlNextElementSibling     : function(node: xmlNodePtr): xmlNodePtr; cdecl;

  /// <summary>Find the first child node which is an element.
  /// Note that entity references are not expanded.
  /// </summary>
  /// <param name="parent">the parent node</param>
  /// <returns>Returns the first element or NULL if parent has no children</returns>
  xmlFirstElementChild      : function(parent: xmlNodePtr): xmlNodePtr; cdecl;

  /// <summary>
  /// Find the first child node which is an element.
  /// Note that entity references are not expanded.
  /// </summary>
  /// <param name="parent">the parent node</param>
  /// <returns>Returns the first element or nil if parent has no children.</returns>
  xmlLastElementChild       : function(parent: xmlNodePtr): xmlNodePtr; cdecl;

  /// <summary>
  ///  Find the closest preceding sibling which is a element.
  ///  Note that entity references are not expanded.
  /// </summary>
  /// <param name="node">the current node</param>
  /// <returns>Returns the sibling or NULL if no sibling was found.</returns>
  xmlPreviousElementSibling : function(node: xmlNodePtr): xmlNodePtr; cdecl;

  /// <summary>Registers a callback for node destruction</summary>
  /// <param name="func">function pointer to the new DeregisterNodeFunc</param>
  /// <returns>Returns the previous value of the deregistration function</returns>
  xmlDeregisterNodeDefault  : function(func: xmlDeregisterNodeFunc): xmlDeregisterNodeFunc; cdecl;

  /// <summary>routine to create an XML buffer.</summary>
  /// <returns>the new structure.</returns>
  xmlBufferCreate           : function: xmlBufferPtr; cdecl;

  /// <summary>routine to create an XML buffer.</summary>
  /// <param name="size">initial size of buffer</param>
  /// <returns>the new structure.</returns>
  xmlBufferCreateSize       : function (size: size_t): xmlBufferPtr; cdecl;

  /// <param name="mem">the memory area</param>
  /// <param name="size">the size in bytes</param>
  /// <returns>Returns an XML buffer initialized with bytes</returns>
  xmlBufferCreateStatic     : function (mem: Pointer; size: size_t): xmlBufferPtr; cdecl;

  /// <summary>Frees an XML buffer. It frees both the content and the structure which encapsulate it.</summary>
  /// <param name="buf">the buffer to free</param>
  xmlBufferFree             : procedure(buf: xmlBufferPtr); cdecl;

  /// <summary>Add a string range to an XML buffer. if len == -1, the length of str is recomputed.</summary>
  /// <param name="buf">the buffer to dump</param>
  /// <param name="str">the xmlCharPtr string</param>
  /// <param name="len">the number of xmlChar to add</param>
  /// <returns>Returns a xmlParserErrors code.</returns>
  xmlBufferAdd              : function (buf: xmlBufferPtr; const str: xmlCharPtr; len: Integer): Integer; cdecl;

  /// <summary>Add a string range to the beginning of an XML buffer.
  /// if len = -1, the length of str is recomputed.</summary>
  /// <param name="buf">the buffer</param>
  /// <param name="str">the xmlCharPtr string</param>
  /// <param name="len">the number of xmlChar to add</param>
  /// <returns>Returns a xmlParserErrors code.</returns>
  xmlBufferAddHead          : function (buf: xmlBufferPtr; const str: xmlCharPtr; len: Integer): Integer; cdecl;

  /// <summary>Append a zero terminated string to an XML buffer.</summary>
  /// <param name="buf">the buffer to add to</param>
  /// <param name="str">the #xmlChar string</param>
  /// <returns>Returns 0 successful, a positive error code number otherwise and -1 in case of internal or API error.</returns>
  xmlBufferCat              : function (buf: xmlBufferPtr; const str: xmlCharPtr): Integer; cdecl;

  /// <summary>Append a zero terminated C string to an XML buffer.</summary>
  /// <param name="buf">the buffer to dump</param>
  /// <param name="str">the C char string</param>
  /// <returns>Returns 0 successful, a positive error code number otherwise and -1 in case of internal or API error</returns>
  xmlBufferCCat             : function (buf: xmlBufferPtr; const str: PAnsiChar): Integer; cdecl;

  /// <summary>empty a buffer</summary>
  /// <param name="buf">the buffer</param>
  xmlBufferEmpty            : procedure(buf: xmlBufferPtr); cdecl;

  /// <summary>Function to extract the content of a buffer</summary>
  /// <param name="buf">the buffer</param>
  /// <returns>Returns the internal content</returns>
  xmlBufferContent          : function (buf: xmlBufferPtr): xmlCharPtr; cdecl;

  /// <summary>
  /// Remove the string contained in a buffer and gie it back to the
  /// caller. The buffer is reset to an empty content.
  /// This doesn't work with immutable buffers as they can't be reset.
  /// </summary>
  /// <param name="buf">the buffer</param>
  /// <returns>Returns the previous string contained by the buffer</returns>
  xmlBufferDetach           : function (buf: xmlBufferPtr): xmlCharPtr; cdecl;

  /// <summary>
  /// Remove the string contained in a buffer and give it back to the
  /// caller. The buffer is reset to an empty content.
  /// This doesn't work with immutable buffers as they can't be reset.
  /// </summary>
  /// <param name="buf">the buffer</param>
  /// <returns>Returns the previous string contained by the buffer.</returns>
  xmlBufferLength           : function (buf: xmlBufferPtr): Integer; cdecl;

  /// <summary>
  /// routine which manage and grows an output buffer. This one writes
  /// a quoted or double quoted #xmlChar string, checking first if it holds
  /// quote or double-quotes internally
  /// </summary>
  /// <param name="buf">the XML buffer output</param>
  /// <param name="str">the string to add</param>
  xmlBufferWriteQuotedString: procedure (buf: xmlBufferPtr; str: xmlCharPtr); cdecl;

  /// <summary>Function to extract the content of a buffer</summary>
  /// <param name="buf">the buffer</param>
  /// <returns>Returns the internal content</returns>
  xmlBufContent             : function(buf: xmlBufferPtr): xmlCharPtr; cdecl;

  /// <summary>Function to extract the end of the content of a buffer</summary>
  /// <param name="buf">the buffer</param>
  /// <returns>Returns the end of the internal content or nil in case of error</returns>
  xmlBufEnd                 : function (buf: xmlBufferPtr): xmlCharPtr; cdecl;

  /// <summary>Function to get the length of a buffer</summary>
  /// <param name="buf">the buffer</param>
  /// <returns>Returns the length of data in the internal content</returns>
  xmlBufUse                 : function (buf: xmlBufferPtr): size_t; cdecl;

  /// <summary>
  /// Search a Ns registered under a given name space for a document.
  /// recurse on the parents until it finds the defined namespace
  /// or return nil otherwise.
  /// nameSpace can be nil, this is a search for the default namespace.
  /// We don't allow to cross entities boundaries. If you don't declare
  /// the namespace within those you will be in troubles !!! A warning
  /// is generated to cover this case.
  ///</summary>
  /// <param name="doc">the document</param>
  /// <param name="node">the current node</param>
  /// <param name="nameSpace">the namespace prefix</param>
  /// <returns>
  /// Returns the namespace pointer or NULL if no namespace was found or
  /// a memory allocation failed. Allocations can only fail if the "xml"
  /// namespace is queried.
  /// </returns>
  xmlSearchNs               : function(doc: xmlDocPtr; node: xmlNodePtr; const nameSpace: xmlCharPtr): xmlNsPtr; cdecl;

  /// <summary>
  /// Search a Ns aliasing a given URI. Recurse on the parents until it finds the defined namespace or return nil otherwise.
  /// </summary>
  /// <param name="doc">the document</param>
  /// <param name="node">the current node</param>
  /// <param name="href">the namespace value</param>
  /// <returns>
  /// Returns the namespace pointer or nil if no namespace was found or a memory allocation failed.
  /// Allocations can only fail if the "xml" namespace is queried.
  /// </returns>
  xmlSearchNsByHref         : function(doc: xmlDocPtr; node: xmlNodePtr; const href: xmlCharPtr): xmlNsPtr; cdecl;

  /// <summary>
  /// Find all in-scope namespaces of a node. out returns a nil
  /// terminated array of namespace pointers that must be freed by
  /// the caller.
  /// </summary>
  /// <param name="doc">the document</param>
  /// <param name="node">the current node</param>
  /// <param name="out">the returned namespace array</param>
  /// <returns>Returns 0 on success, 1 if no namespaces were found, -1 if a memory allocation failed.</returns>
  xmlGetNsListSafe          : function(const doc: xmlDocPtr; node: xmlNodePtr; var &out: xmlNsPtrArray): Integer; cdecl;

  /// <summary>
  /// Find all in-scope namespaces of a node.
  ///
  /// Use<see cref="xmlGetNsListSafe"/> for better error reporting.</summary>
  /// <param name="doc">the document</param>
  /// <param name="node">the current node</param>
  /// <returns>
  /// Returns a nil terminated array of namespace pointers that must
  /// be freed by the caller or nil if no namespaces were found or
  /// a memory allocation failed.
  ///</returns>
  xmlGetNsList              : function(const doc: xmlDocPtr; node: xmlNodePtr): xmlNsPtr; cdecl;

  /// <summary>Set the namespace of an element or attribute node. Passing a nil namespace unsets the namespace.</summary>
  /// <param name="node">a node in the document</param>
  /// <param name="ns">a namespace pointer (optional)</param>
  xmlSetNs                  : procedure(node: xmlNodePtr; ns: xmlNsPtr); cdecl;

  /// <summary>Copy a namespace.</summary>
  /// <param name="cur">the namespace</param>
  /// <returns>Returns the copied namespace or NULL if a memory allocation failed.</returns>
  xmlCopyNamespace          : function(cur: xmlNsPtr): xmlNsPtr; cdecl;

  /// <summary>Copy a namespace list.</summary>
  /// <param name="cur">the first namespace</param>
  /// <returns>Returns the head of the copied list or nil if a memory allocation failed.</returns>
  xmlCopyNamespaceList      : function(cur: xmlNsPtr): xmlNsPtr; cdecl;

{$endregion}

{$region 'encoding.h'}

type
  xmlCharEncodingHandlerPtr = ^xmlCharEncodingHandler;
  /// <summary>
  ///  A character encoding conversion handler for non UTF-8 encodings
  /// </summary>
  /// <remarks>
  /// This structure will be made private.
  /// </remarks>
  xmlCharEncodingHandler = record end;

  xmlCharEncConverterPtr = ^xmlCharEncConverter;
  ///<summary>A character encoding conversion handler for non UTF-8 encodings</summary>
  /// <remarks>
  /// This structure will be made private.
  /// </remarks>
  xmlCharEncConverter = record end;

  /// <summary>
  ///  Encoding conversion errors.
  /// </summary>
  xmlCharEncError = (
    /// <summary>Success</summary>
    XML_ENC_ERR_SUCCESS     =  0,
    /// <summary>Internal or unclassified error. </summary>
    XML_ENC_ERR_INTERNAL    = -1,
    /// <summary>Invalid or untranslatable input sequence. </summary>
    XML_ENC_ERR_INPUT       = -2,
    /// <summary>Not enough space in output buffer. </summary>
    XML_ENC_ERR_SPACE       = -3,
    /// <summary>Out-of-memory error.</summary>
    XML_ENC_ERR_MEMORY      = -4
  );

type
  xmlCharEncFlags = type xmlEnumSet;
const
  XML_ENC_INPUT  = xmlCharEncFlags(1);
  XML_ENC_OUTPUT = xmlCharEncFlags(2);

type
  /// <summary>
  ///  Predefined values for some standard encodings.
  /// </summary>
  xmlCharEncoding = (
    XML_CHAR_ENCODING_ERROR=   -1, // No char encoding detected
    XML_CHAR_ENCODING_NONE=     0, // No char encoding detected
    XML_CHAR_ENCODING_UTF8=     1, // UTF-8
    XML_CHAR_ENCODING_UTF16LE=  2, // UTF-16 little endian
    XML_CHAR_ENCODING_UTF16BE=  3, // UTF-16 big endian
    XML_CHAR_ENCODING_UCS4LE=   4, // UCS-4 little endian
    XML_CHAR_ENCODING_UCS4BE=   5, // UCS-4 big endian
    XML_CHAR_ENCODING_EBCDIC=   6, // EBCDIC uh!
    XML_CHAR_ENCODING_UCS4_2143=7, // UCS-4 unusual ordering
    XML_CHAR_ENCODING_UCS4_3412=8, // UCS-4 unusual ordering
    XML_CHAR_ENCODING_UCS2  =   9, // UCS-2
    XML_CHAR_ENCODING_8859_1=   10,// ISO-8859-1 ISO Latin 1
    XML_CHAR_ENCODING_8859_2=   11,// ISO-8859-2 ISO Latin 2
    XML_CHAR_ENCODING_8859_3=   12,// ISO-8859-3
    XML_CHAR_ENCODING_8859_4=   13,// ISO-8859-4
    XML_CHAR_ENCODING_8859_5=   14,// ISO-8859-5
    XML_CHAR_ENCODING_8859_6=   15,// ISO-8859-6
    XML_CHAR_ENCODING_8859_7=   16,// ISO-8859-7
    XML_CHAR_ENCODING_8859_8=   17,// ISO-8859-8
    XML_CHAR_ENCODING_8859_9=   18,// ISO-8859-9
    XML_CHAR_ENCODING_2022_JP=  19,// ISO-2022-JP
    XML_CHAR_ENCODING_SHIFT_JIS=20,// Shift_JIS
    XML_CHAR_ENCODING_EUC_JP=   21,// EUC-JP
    XML_CHAR_ENCODING_ASCII=    22,// pure ASCII
    { Available since 2.14.0 }
    XML_CHAR_ENCODING_UTF16=    23,// UTF-16 native
    XML_CHAR_ENCODING_HTML=     24,// HTML (output only)
    XML_CHAR_ENCODING_8859_10=  25,// ISO-8859-10
    XML_CHAR_ENCODING_8859_11=  26,// ISO-8859-11
    XML_CHAR_ENCODING_8859_13=  27,// ISO-8859-13
    XML_CHAR_ENCODING_8859_14=  28,// ISO-8859-14
    XML_CHAR_ENCODING_8859_15=  29,// ISO-8859-15
    XML_CHAR_ENCODING_8859_16=  30, // ISO-8859-16
    { windows-1252, available since 2.15 }
    XML_CHAR_ENCODING_WINDOWS_1252 = 31
   );

  /// <summary>
  /// Free a conversion context.
  /// </summary>
  /// <param name="vctxt">conversion context</param>
  xmlCharEncConvCtxtDtor = procedure(vctxt: Pointer); cdecl;

  /// <summary>
  /// Convert characters to UTF-8.
  /// On success, the value of inlen after return is the number of bytes consumed and outlen is the number of bytes produced.
  /// </summary>
  /// <param name="output">a pointer to an array of bytes to store the UTF-8 result</param>
  /// <param name="outlen">the length of out </param>
  /// <param name="input">a pointer to an array of chars in the original encoding </param>
  /// <param name="inlen">the length of input </param>
  /// <returns>
  /// the number of bytes written or an xmlCharEncError code.
  /// </returns>
   xmlCharEncodingInputFunc  = function (output: xmlCharPtr; var outlen: Integer; input: xmlCharPtr; var inlen: Integer): Integer; cdecl;

  /// <summary>
  /// Convert characters from UTF-8.
  /// On success, the value of inlen after return is the number of bytes consumed and outlen is the number of bytes produced.
  /// </summary>
  /// <param name="output">a pointer to an array of bytes to store the result </param>
  /// <param name="outlen">the length of out </param>
  /// <param name="input">a pointer to an array of UTF-8 chars </param>
  /// <param name="inlen">the length of input </param>
  /// <returns>
  /// the number of bytes written or an xmlCharEncError code.
  /// </returns>
   xmlCharEncodingOutputFunc  = function (output: xmlCharPtr; var outlen: Integer; input: xmlCharPtr; var inlen: Integer): Integer; cdecl;

  /// <summary>
  /// Convert between character encodings.
  /// The value of inlen after return is the number of bytes consumed and outlen is the number of bytes produced.
  /// If the converter can consume partial multi-byte sequences, the flush flag can be used to detect truncated sequences at EOF. Otherwise, the flag can be ignored.
  /// </summary>
  /// <param name="vctxt">conversion context </param>
  /// <param name="output">a pointer to an array of bytes to store the result </param>
  /// <param name="outlen">the length of out</param>
  /// <param name="input">a pointer to an array of input bytes</param>
  /// <param name="inlen">the length of in</param>
  /// <param name="flush">end of input </param>
  /// <returns>
  /// an xmlCharEncError code.
  /// </returns>
  xmlCharEncConvFunc = function(vctxt: Pointer; output: Pointer; var outlen: Integer; input: Pointer; var inlen: Integer; flush: Integer): xmlCharEncError; cdecl;

  /// <summary>
  /// If this function returns <see cref="XML_ERR_OK"/>, it must fill the out pointer with an encoding handler.
  /// The handler can be obtained from <see cref="xmlCharEncNewCustomHandler"/>.
  /// flags can contain <see cref="XML_ENC_INPUT"/>, <see cref="XML_ENC_OUTPUT"/> or both.
  /// </summary>
  /// <param name="vctxt">user data </param>
  /// <param name="name">encoding name </param>
  /// <param name="flags">bit mask of flags </param>
  /// <param name="output">pointer to resulting handler </param>
  /// <returns>
  /// an xmlCharEncError code.
  /// </returns>
  xmlCharEncConvImpl = function(vctxt: Pointer; name: PUTF8Char; flags: xmlCharEncFlags; var output: xmlCharEncConverterPtr): Integer; cdecl;

var
  /// <summary>
  /// Find or create a handler matching the encoding.
  /// The following converters are looked up in order:
  ///
  /// - Built-in handler (UTF-8, UTF-16, ISO-8859-1, ASCII)
  /// - User-registered global handler (deprecated)
  /// - iconv if enabled
  /// - ICU if enabled
  ///
  /// The handler must be closed with xmlCharEncCloseFunc().
  ///
  /// If the encoding is UTF-8, a nil handler and no error code will be returned.
  /// </summary>
  /// <param name="enc">an xmlCharEncoding value. </param>
  /// <param name="output">pointer to result </param>
  /// <returns>
  ///  XML_ERR_OK, XML_ERR_UNSUPPORTED_ENCODING or another xmlParserErrors error code
  /// </returns>
  xmlLookupCharEncodingHandler: function(enc: xmlCharEncoding; var output: xmlCharEncodingHandlerPtr): xmlParserErrors; cdecl;

  /// <summary>
  /// Find or create a handler matching the encoding.
  /// The following converters are looked up in order:
  ///
  /// - Built-in handler (UTF-8, UTF-16, ISO-8859-1, ASCII)
  /// - User-registered global handler (deprecated)
  /// - iconv if enabled
  /// - ICU if enabled
  ///
  /// The handler must be closed with xmlCharEncCloseFunc().
  ///
  /// If the encoding is UTF-8, a nil handler and no error code will be returned.
  /// </summary>
  /// <param name="name">a string describing the char encoding. </param>
  /// <param name="output">boolean, use handler for output</param>
  /// <param name="out">pointer to result </param>
  /// <returns>
  ///  XML_ERR_OK, XML_ERR_UNSUPPORTED_ENCODING or another xmlParserErrors error code
  /// </returns>
  xmlOpenCharEncodingHandler: function(name: xmlCharPtr; output: Integer; var &out: xmlCharEncodingHandlerPtr): xmlParserErrors; cdecl;

  xmlCreateCharEncodingHandler: function(name: xmlCharPtr; flags: xmlCharEncFlags; impl: xmlCharEncConvImpl; implCtxt: Pointer; var &out: xmlCharEncodingHandlerPtr): xmlParserErrors; cdecl;

  xmlGetCharEncodingHandler: function(enc: xmlCharEncoding): xmlCharEncodingHandlerPtr; cdecl;

  xmlFindCharEncodingHandler: function(name: xmlCharPtr): xmlCharEncodingHandlerPtr; cdecl;

  xmlNewCharEncodingHandler: function(name: xmlCharPtr; input: xmlCharEncodingInputFunc; output: xmlCharEncodingOutputFunc): xmlCharEncodingHandlerPtr; cdecl;

  xmlCharEncNewCustomHandler: function(name: xmlCharPtr; input: xmlCharEncConvFunc; output: xmlCharEncConvFunc; ctxtDtor: xmlCharEncConvCtxtDtor; inputCtxt: Pointer; outputCtxt: Pointer; var &out: xmlCharEncodingHandlerPtr): xmlParserErrors; cdecl;

  xmlAddEncodingAlias: function(name: xmlCharPtr; alias: PUTF8Char): Integer; cdecl;

  xmlDelEncodingAlias: function(const alias: PUTF8Char): Integer; cdecl;

  xmlGetEncodingAlias: function(const alias: PUTF8Char): PUTF8Char; cdecl;

  xmlCleanupEncodingAliases : procedure; cdecl;

  xmlParseCharEncoding: function (name: PUTF8Char): xmlCharEncoding; cdecl;

  xmlGetCharEncodingName: function(enc: xmlCharEncoding): PUTF8Char; cdecl;

  xmlDetectCharEncoding: function(input: Pointer; len: Integer): xmlCharEncoding; cdecl;

  xmlCharEncOutFunc: function(handler: xmlCharEncodingHandlerPtr; output, input: xmlBufferPtr): Integer; cdecl;

  xmlCharEncInFunc: function(handler: xmlCharEncodingHandlerPtr; output, input: xmlBufferPtr): Integer; cdecl;

  xmlCharEncCloseFunc: function(handler: xmlCharEncodingHandlerPtr): Integer; cdecl;

  xmlUTF8ToIsolat1: function(): Integer; cdecl;

  xmlIsolat1ToUTF8: function(output: PUTF8Char; var outlen: Integer; input: PAnsiChar; var inlen: Integer): Integer; cdecl;

{$endregion}

{$region 'xmlIO.h'}

type
  ///<summary>Output buffer.</summary>
  xmlOutputBufferPtr = ^xmlOutputBuffer;
  xmlOutputBuffer = record end;

  ///<summary>Parser input buffer.</summary>
  xmlParserInputBufferPtr = ^xmlParserInputBuffer;
  xmlParserInputBuffer = record end;

  /// <summary>
  /// Callback used in the I/O Input API to detect if the current handler can provide input functionality for this resource.
  /// </summary>
  /// <param name="filename">the filename or URI</param>
  /// <returns>
  /// Returns 1 if yes and 0 if another Input module should be used
  /// </returns>
  xmlInputMatchCallback  = function(filename: PUTF8Char): Integer; cdecl;

  /// <summary>
  /// Callback used in the I/O Input API to open the resource.
  /// </summary>
  /// <param name="filename">the filename or URI </param>
  /// <returns>
  /// an Input context or nil in case or error
  /// </returns>
  xmlInputOpenCallback   = function(filename: PUTF8Char): Pointer; cdecl;

  /// <summary>
  /// Callback used in the I/O Input API to read the resource.
  /// </summary>
  /// <param name="context">an Input context</param>
  /// <param name="buffer">the buffer to store data read </param>
  /// <param name="len">the length of the buffer in bytes</param>
  /// <returns>
  /// the number of bytes read or -1 in case of error
  /// </returns>
  xmlInputReadCallback   = function(context: Pointer; buffer: PUTF8Char; len: Integer): Integer; cdecl;

  /// <summary>
  /// Callback used in the I/O Input API to close the resource.
  /// </summary>
  /// <param name="context">	an Input context</param>
  /// <returns>
  /// 0 or -1 in case of error
  /// </returns>
  xmlInputCloseCallback  = function(context: Pointer): Integer; cdecl;

  /// <summary>
  /// Callback used in the I/O Input API to detect if the current handler can provide input functionality for this resource
  /// </summary>
  /// <param name="filename">the filename or URI </param>
  /// <returns>
  /// 1 if yes and 0 if another Input module should be used
  /// </returns>
  xmlOutputMatchCallback = function(const filename: PUTF8Char): Integer; cdecl;

  /// <summary>
  /// Callback used in the I/O Output API to open the resource.
  /// </summary>
  /// <param name="filename">the filename or URI </param>
  /// <returns>
  /// an Output context or nil in case or error
  /// </returns>
  xmlOutputOpenCallback  = function(const filename: PUTF8Char): Pointer; cdecl;

  /// <summary>
  /// Callback used in the I/O Output API to write to the resource.
  /// </summary>
  /// <param name="context">an Output context </param>
  /// <param name="buffer">the buffer of data to write</param>
  /// <param name="len">the length of the buffer in bytes</param>
  /// <returns>
  ///  the number of bytes written or -1 in case of error
  /// </returns>
  xmlOutputWriteCallback = function(context: Pointer; buffer: PUTF8Char; len: Integer): Integer; cdecl;

  /// <summary>
  /// Callback used in the I/O Output API to close the resource.
  /// </summary>
  /// <param name="context">an Output context </param>
  /// <returns>
  /// 0 or -1 in case of error
  /// </returns>
  xmlOutputCloseCallback = function(context: Pointer): Integer; cdecl;

  /// <summary>
  /// Signature for the function doing the lookup for a suitable input method corresponding to an URI.
  /// </summary>
  /// <param name="URI">the URI to read from </param>
  ///  <param name="enc">the requested source encoding </param>
  /// <returns>
  /// the new xmlParserInputBuffer in case of success or nil if no method was found.
  /// </returns>
  xmlParserInputBufferCreateFilenameFunc = function(const URI: PUTF8Char; enc: xmlCharEncoding): xmlParserInputBufferPtr; cdecl;

  /// <summary>
  /// Create a buffered output for the progressive saving of a file If filename is "-" then we use stdout as the output.
  /// Automatic support for ZLIB/Compress compressed document is provided by default if found at compile-time.
  /// Consumes encoder but not in error case.
  /// Internal implementation, never uses the callback installed with <see cref="xmlOutputBufferCreateFilenameDefault"/>
  /// </summary>
  /// <param name="URI">a C string containing the URI or filename </param>
  /// <param name="encoder">the encoding converter or nil </param>
  /// <param name="compression">the compression ration (0 none, 9 max)</param>
  /// <returns>
  ///
  /// </returns>
  xmlOutputBufferCreateFilenameFunc = function(const URI: PUTF8Char; encoder: xmlCharEncodingHandlerPtr; compression: Integer): xmlOutputBufferPtr; cdecl;

var
  xmlCleanupInputCallbacks     : procedure; cdecl;
  xmlPopInputCallbacks         : function: Integer; cdecl;
  xmlRegisterDefaultInputCallbacks: procedure; cdecl;
  xmlAllocParserInputBuffer    : function (enc: xmlCharEncoding): xmlParserInputBufferPtr; cdecl;
  xmlParserInputBufferCreateFilename: function(const URI: PUTF8Char; enc: xmlCharEncoding): xmlParserInputBufferPtr; cdecl;
  xmlParserInputBufferCreateFd : function(fd: Integer; enc: xmlCharEncoding): xmlParserInputBufferPtr; cdecl;
  xmlParserInputBufferCreateMem: function(const mem: Pointer; size: Integer; enc: xmlCharEncoding): xmlParserInputBufferPtr; cdecl;
  xmlParserInputBufferCreateStatic: function(const mem: Pointer; size: Integer; enc: xmlCharEncoding): xmlParserInputBufferPtr; cdecl;
  xmlParserInputBufferCreateIO : function(ioread: xmlInputReadCallback; ioclose: xmlInputCloseCallback; ioctx: Pointer; enc: xmlCharEncoding): xmlParserInputBufferPtr; cdecl;
  xmlFreeParserInputBuffer     : procedure(input: xmlParserInputBufferPtr); cdecl;
  xmlParserGetDirectory        : function (const filename: PUTF8Char): PUTF8Char; cdecl;
  xmlRegisterInputCallbacks    : function (matchFunc: xmlInputMatchCallback; openFunc: xmlInputOpenCallback; readFunc: xmlInputReadCallback; closeFunc: xmlInputCloseCallback): Integer; cdecl;
  xmlCleanupOutputCallbacks    : procedure; cdecl;
  xmlPopOutputCallbacks        : function: Integer; cdecl;
  xmlRegisterDefaultOutputCallbacks: procedure; cdecl;
  xmlAllocOutputBuffer         : function (encoder: xmlCharEncodingHandlerPtr): xmlOutputBufferPtr; cdecl;
  xmlOutputBufferCreateFilename: function(const URI: PUTF8Char; encoder: xmlCharEncodingHandlerPtr; compression: Integer): xmlOutputBufferPtr; cdecl;
  xmlOutputBufferCreateBuffer  : function(buffer: xmlBufferPtr; encoder: xmlCharEncodingHandlerPtr): xmlOutputBufferPtr; cdecl;
  xmlOutputBufferCreateFd      : function (fd: Integer; encoder: xmlCharEncodingHandlerPtr): xmlOutputBufferPtr; cdecl;
  xmlOutputBufferCreateIO      : function (iowrite: xmlOutputWriteCallback; ioclose: xmlOutputCloseCallback; ioctx: Pointer; encoder: xmlCharEncodingHandlerPtr): xmlOutputBufferPtr; cdecl;
  xmlOutputBufferGetContent    : function (output: xmlOutputBufferPtr): XmlCharPtr; cdecl;
  xmlOutputBufferGetSize       : function (output: xmlOutputBufferPtr): size_t; cdecl;
  xmlOutputBufferWrite         : function (output: xmlOutputBufferPtr; len: Integer; const buf: PUTF8Char): Integer; cdecl;
  xmlOutputBufferWriteString   : function (output: xmlOutputBufferPtr; const str: PUTF8Char): Integer; cdecl;
  xmlOutputBufferWriteEscape   : function (output: xmlOutputBufferPtr; const str: xmlCharPtr; escaping: xmlCharEncodingOutputFunc): Integer; cdecl;
  xmlOutputBufferFlush         : function (output: xmlOutputBufferPtr): Integer; cdecl;
  xmlOutputBufferClose         : function (output: xmlOutputBufferPtr): Integer; cdecl;
  xmlRegisterOutputCallbacks   : function (matchFunc: xmlOutputMatchCallback; openFunc: xmlOutputOpenCallback; writeFunc: xmlOutputWriteCallback; closeFunc: xmlOutputCloseCallback): Integer; cdecl;
  xmlOutputBufferCreateFilenameDefault: function(func: xmlOutputBufferCreateFilenameFunc): xmlOutputBufferCreateFilenameFunc; cdecl;

{$endregion}

{$region 'entities.h'}

type
  xmlEntityType = (
    XML_INTERNAL_GENERAL_ENTITY = 1,
    XML_EXTERNAL_GENERAL_PARSED_ENTITY = 2,
    XML_EXTERNAL_GENERAL_UNPARSED_ENTITY = 3,
    XML_INTERNAL_PARAMETER_ENTITY = 4,
    XML_EXTERNAL_PARAMETER_ENTITY = 5,
    XML_INTERNAL_PREDEFINED_ENTITY = 6
  );

  xmlEntitiesTablePtr = ^xmlEntitiesTable;
  xmlEntitiesTable = record end;

  xmlEntityPtr = ^xmlEntity;
  xmlEntity = record
    ///<summary>application data</summary>
    _private: Pointer;
    ///<summary>XML_ENTITY_DECL, must be second !</summary>
    &type: xmlElementType;
    ///<summary>Entity name</summary>
    name: xmlCharPtr;
    ///<summary>First child link</summary>
    children: xmlNodePtr;
    ///<summary>Last child link</summary>
    last: xmlNodePtr;
    ///<summary>-> DTD</summary>
    parent: xmlNodePtr;
    ///<summary>next sibling link</summary>
    next: xmlNodePtr;
    ///<summary>previous sibling link</summary>
    prev: xmlNodePtr;
    ///<summary>the containing document</summary>
    doc: xmlDoc;
    ///<summary>content without ref substitution</summary>
    orig: xmlCharPtr;
    ///<summary>content or ndata if unparsed</summary>
    content: xmlCharPtr;
    ///<summary>the content length</summary>
    length: Integer;
    ///<summary>The entity type</summary>
    etype: xmlEntityType;
    ///<summary>External identifier for PUBLIC</summary>
    ExternalID: xmlCharPtr;
    ///<summary>URI for a SYSTEM or PUBLIC Entity</summary>
    SystemID: xmlCharPtr;
    ///<summary>unused</summary>
    nexte: xmlEntityPtr;
    ///<summary>the full URI as computed</summary>
    URI: xmlCharPtr;
    ///<summary>unused</summary>
    owner: Integer;
    ///<summary>various flags</summary>
    flags: Integer;
    ///<summary>expanded size</summary>
    expandedSize: ulong;
  end;

var
  xmlNewEntity            : function (doc: xmlDocPtr; name: xmlCharPtr; &type: Integer; const ExternalID, SystemID, content: xmlCharPtr): xmlEntityPtr; cdecl;
  xmlFreeEntity           : procedure(entity: xmlEntityPtr); cdecl;
  xmlAddEntity            : function (doc: xmlDocPtr; extSubset: Integer; name: xmlCharPtr; &type: Integer; const ExternalID, SystemID, content: xmlCharPtr; &out: xmlEntityPtr): Integer; cdecl;
  xmlAddDocEntity         : function (doc: xmlDocPtr; name: xmlCharPtr; &type: Integer; const ExternalID, SystemID, content: xmlCharPtr): xmlEntityPtr; cdecl;
  xmlAddDtdEntity         : function (doc: xmlDocPtr; name: xmlCharPtr; &type: Integer; const ExternalID, SystemID, content: xmlCharPtr): xmlEntityPtr; cdecl;
  xmlGetPredefinedEntity  : function (const name: xmlCharPtr): xmlEntityPtr; cdecl;
  xmlGetDocEntity         : function (doc: xmlDocPtr; const name: xmlCharPtr): xmlEntityPtr; cdecl;
  xmlGetDtdEntity         : function (doc: xmlDocPtr; const name: xmlCharPtr): xmlEntityPtr; cdecl;
  xmlGetParameterEntity   : function (doc: xmlDocPtr; const name: xmlCharPtr): xmlEntityPtr; cdecl;
  xmlEncodeEntitiesReentrant: function (doc: xmlDocPtr; const input: xmlCharPtr): xmlEntityPtr; cdecl;
  xmlEncodeSpecialChars   : function (doc: xmlDocPtr; const input: xmlCharPtr): xmlCharPtr; cdecl;

  xmlCreateEntitiesTable  : function: xmlEntitiesTablePtr; cdecl;
  xmlCopyEntitiesTable    : function(table: xmlEntitiesTablePtr): xmlEntitiesTablePtr; cdecl;
  xmlFreeEntitiesTable    : procedure (table: xmlEntitiesTablePtr); cdecl;
  xmlDumpEntitiesTable    : procedure (buf: xmlBufferPtr; table: xmlEntitiesTablePtr); cdecl;
  xmlDumpEntityDecl       : procedure (buf: xmlBuffer; ent: xmlEntityPtr); cdecl;

{$endregion}

{$region 'Parser.h'}

type
  /// <summary> Status after parsing a document. </summary>
  xmlParserStatus = type xmlEnumSet;
const
  /// <summary>not well-formed </summary>
  XML_STATUS_NOT_WELL_FORMED          = xmlParserStatus(1);
  /// <summary>not namespace-well-formed </summary>
  XML_STATUS_NOT_NS_WELL_FORMED       = xmlParserStatus(2);
  /// <summary>DTD validation failed.</summary>
  XML_STATUS_DTD_VALIDATION_FAILED    = xmlParserStatus(4);
  /// <summary>catastrophic failure like OOM or I/O error</summary>
  XML_STATUS_CATASTROPHIC_ERROR       = xmlParserStatus(8);

type
  /// <summary>Resource type for resource loaders. </summary>
  xmlResourceType = (
    /// <summary>unknown</summary>
    XML_RESOURCE_UNKNOWN = 0,
    /// <summary>main document</summary>
    XML_RESOURCE_MAIN_DOCUMENT,
    /// <summary>external DTD</summary>
    XML_RESOURCE_DTD,
    /// <summary>external general entity</summary>
    XML_RESOURCE_GENERAL_ENTITY,
    /// <summary>external parameter entity</summary>
    XML_RESOURCE_PARAMETER_ENTITY,
    /// <summary>XIncluded document</summary>
    XML_RESOURCE_XINCLUDE,
    /// <summary>XIncluded text</summary>
    XML_RESOURCE_XINCLUDE_TEXT
  );

type
  /// <summary>Flags for parser input.</summary>
  xmlParserInputFlags = type xmlEnumSet;
const
  /// <summary>The input buffer won't be changed during parsing. </summary>
  XML_INPUT_BUF_STATIC            = xmlParserInputFlags(2);
  /// <summary>The input buffer is zero-terminated.</summary>
  /// <remarks>Note that the zero byte shouldn't be included in buffer size.</remarks>
  XML_INPUT_BUF_ZERO_TERMINATED   = xmlParserInputFlags(4);
  /// <summary>Uncompress gzipped file input.</summary>
  XML_INPUT_UNZIP                 = xmlParserInputFlags(8);
  /// <summary>Allow network access. </summary>
  // <remarks>Unused internally</remarks>
  XML_INPUT_NETWORK               = xmlParserInputFlags(16);

type
  /// <summary>This is the set of XML parser options that can be passed to <see cref="xmlReadDoc"/>, <see cref="xmlCtxtSetOptions"/> and other functions</summary>
  xmlParserOption = type xmlEnumSet;
const
  /// <summary>
  /// Enable "recovery" mode which allows non-wellformed documents.
  /// How this mode behaves exactly is unspecified and may change without further notice. Use of this feature is DISCOURAGED.
  /// Not supported by the push parser.
  ///</summary>
  XML_PARSE_RECOVER    = 1 shl 0;
  /// <summary>
  /// Despite the confusing name, this option enables substitution of entities.
  /// The resulting tree won't contain any entity reference nodes.
  /// This option also enables loading of external entities (both general and parameter entities) which is dangerous. If you process untrusted data, it's recommended to set the XML_PARSE_NO_XXE option to disable loading of external entities.
  ///</summary>
  XML_PARSE_NOENT      = 1 shl 1;
  /// <summary>
  /// Enables loading of an external DTD and the loading and substitution of external parameter entities.
  /// Has no effect if XML_PARSE_NO_XXE is set.
  ///</summary>
  XML_PARSE_DTDLOAD    = 1 shl 2;
  /// <summary>
  /// Adds default attributes from the DTD to the result document.
  /// Implies XML_PARSE_DTDLOAD, but loading of external content can be disabled with XML_PARSE_NO_XXE.
  ///</summary>
  XML_PARSE_DTDATTR    = 1 shl 3;
  /// <summary>
  /// This option enables DTD validation which requires to load external DTDs and external entities (both general and parameter entities) unless XML_PARSE_NO_XXE was set.
  ///</summary>
  XML_PARSE_DTDVALID   = 1 shl 4;
  /// <summary>
  ///  Disable error and warning reports to the error handlers.
  /// Errors are still accessible with <see cref="xmlCtxtGetLastError"/>.
  ///</summary>
  XML_PARSE_NOERROR    = 1 shl 5;
  /// <summary>
  /// Disable warning reports.
  ///</summary>
  XML_PARSE_NOWARNING  = 1 shl 6;
  /// <summary>
  /// Enable some pedantic warnings.
  /// </summary>
  XML_PARSE_PEDANTIC   = 1 shl 7;
  /// <summary>
  /// Remove some whitespace from the result document.
  /// Where to remove whitespace depends on DTD element declarations or a broken heuristic with unfixable bugs. Use of this option is DISCOURAGED.
  /// Not supported by the push parser.
  ///</summary>
  XML_PARSE_NOBLANKS   = 1 shl 8;
  /// <summary>
  /// Always invoke the deprecated SAX1 startElement and endElement handlers.
  /// </summary>
  XML_PARSE_SAX1       = 1 shl 9 deprecated 'This option will be removed in a future version';
  /// <summary>
  /// Enable XInclude processing.
  /// This option only affects the xmlTextReader and XInclude interfaces.
  ///</summary>
  XML_PARSE_XINCLUDE   = 1 shl 10;
  /// <summary>
  ///  Disable network access with the built-in HTTP or FTP clients.
  /// </summary>
  /// <remarks>
  /// After the last built-in network client was removed in 2.15, this option has no effect expect for being passed on to custom resource loaders.
  /// </remarks>
  XML_PARSE_NONET      = 1 shl 11;
  /// <summary>
  /// Create a document without interned strings, making all strings separate memory allocations.
  ///</summary>
  XML_PARSE_NODICT     = 1 shl 12;
  /// <summary>
  /// Remove redundant namespace declarations from the result document.
  ///</summary>
  XML_PARSE_NSCLEAN    = 1 shl 13;
  /// <summary>
  ///  Output normal text nodes instead of CDATA nodes.
  ///</summary>
  XML_PARSE_NOCDATA    = 1 shl 14;
  /// <summary>
  ///  Don't generate XInclude start/end nodes when expanding inclusions.
  /// This option only affects the xmlTextReader and XInclude interfaces.
  ///</summary>
  XML_PARSE_NOXINCNODE = 1 shl 15;
  /// <summary>
  /// Store small strings directly in the node struct to save memory.
  ///</summary>
  XML_PARSE_COMPACT    = 1 shl 16;
  /// <summary>
  /// Use old Name productions from before XML 1.0 Fifth Edition.
  ///</summary>
  XML_PARSE_OLD10      = 1 shl 17 deprecated 'This option will be removed in a future version.';
  /// <summary>
  /// Don't fix up XInclude xml:base URIs.
  /// This option only affects the xmlTextReader and XInclude interfaces.
  ///</summary>
  XML_PARSE_NOBASEFIX  = 1 shl 18;
  /// <summary>
  /// Relax some internal limits.
  ///
  /// Maximum size of text nodes, tags, comments, processing instructions, CDATA sections, entity values
  /// normal: 10M huge: 1B
  ///
  /// Maximum size of names, system literals, pubid literals
  /// normal: 50K huge: 10M
  ///
  /// Maximum nesting depth of elements
  /// normal: 256 huge: 2048
  ///
  /// Maximum nesting depth of entities
  /// normal: 20 huge: 40
  ///</summary>
  XML_PARSE_HUGE       = 1 shl 19;
  /// <summary>
  /// Enable an unspecified legacy mode for SAX parsers.
  ///</summary>
  XML_PARSE_OLDSAX     = 1 shl 20 deprecated 'This option will be removed in a future version. ';
  /// <summary>
  /// Ignore the encoding in the XML declaration.
  /// This option is mostly unneeded these days. The only effect is to enforce UTF-8 decoding of ASCII-like data.
  ///</summary>
  XML_PARSE_IGNORE_ENC = 1 shl 21;
  /// <summary>
  /// Enable reporting of line numbers larger than 65535.
  ///</summary>
  XML_PARSE_BIG_LINES  = 1 shl 22;
  /// <summary>
  /// Disables loading of external DTDs or entities.
  ///</summary>
  ///<remarks>since 2.13.0</remarks>
  XML_PARSE_NO_XXE     = 1 shl 23;
  /// <summary>
  /// Setting this option is discouraged to avoid zip bombs.
  /// </summary>
  ///<remarks>since 2.14.0</remarks>
  XML_PARSE_UNZIP      = 1 shl 24;
  /// <summary>
  /// Enable input decompression.
  /// Disables the global system XML catalog.
  /// </summary>
  ///<remarks>since 2.14.0</remarks>
  XML_PARSE_NO_SYS_CATALOG = 1 shl 25;
  /// <summary>
  /// Enable XML catalog processing instructions.
  /// </summary>
  ///<remarks>since 2.14.0</remarks>
  XML_PARSE_NO_CATALOG_PI  = 1 shl 26;

type
  /// <summary>
  ///  Used to examine the existence of features that can be enabled or disabled at compile-time.
  /// They used to be called XML_FEATURE_xxx but this clashed with Expat
  /// </summary>
  xmlFeature = (
    /// <summary>Multithreading support</summary>
    XML_WITH_THREAD = 1,
    /// <summary>Deprecated: Always available </summary>
    XML_WITH_TREE = 2,
    /// <summary>Serialization support. </summary>
    XML_WITH_OUTPUT = 3,
    /// <summary>Push parser. </summary>
    XML_WITH_PUSH = 4,
    /// <summary>XML Reader. </summary>
    XML_WITH_READER = 5,
    /// <summary>Streaming patterns. </summary>
    XML_WITH_PATTERN = 6,
    /// <summary>XML Writer. </summary>
    XML_WITH_WRITER = 7,
    /// <summary>Legacy SAX1 API. </summary>
    XML_WITH_SAX1 = 8,
    /// <summary>Deprecated: FTP support was removed </summary>
    XML_WITH_FTP = 9,
    /// <summary>Deprecated: HTTP support was removed</summary>
    XML_WITH_HTTP = 10,
    /// <summary>DTD validation. </summary>
    XML_WITH_VALID = 11,
    /// <summary>HTML parser.</summary>
    XML_WITH_HTML = 12,
    /// <summary>Legacy symbols.</summary>
    XML_WITH_LEGACY = 13,
    /// <summary>Canonical XML. </summary>
    XML_WITH_C14N = 14,
    /// <summary>XML Catalogs. </summary>
    XML_WITH_CATALOG = 15,
    /// <summary>XPath.</summary>
    XML_WITH_XPATH = 16,
    /// <summary>XPointer.</summary>
    XML_WITH_XPTR = 17,
    /// <summary>XInclude.</summary>
    XML_WITH_XINCLUDE = 18,
    /// <summary>iconv</summary>
    XML_WITH_ICONV = 19,
    /// <summary>Built-in ISO-8859-X.</summary>
    XML_WITH_ISO8859X = 20,
    /// <summary>Deprecated: Removed </summary>
    XML_WITH_UNICODE = 21,
    /// <summary>Regular expressions. </summary>
    XML_WITH_REGEXP = 22,
    /// <summary>Deprecated:Same as XML_WITH_REGEX</summary>
    XML_WITH_AUTOMATA = 23,
    /// <summary>Deprecated: Removed </summary>
    XML_WITH_EXPR = 24,
    /// <summary>XML Schemas</summary>
    XML_WITH_SCHEMAS = 25,
    /// <summary>Schematron</summary>
    XML_WITH_SCHEMATRON = 26,
    /// <summary>Loadable modules</summary>
    XML_WITH_MODULES = 27,
    /// <summary>Debugging API</summary>
    XML_WITH_DEBUG = 28,
    /// <summary>Deprecated:Removed</summary>
    XML_WITH_DEBUG_MEM = 29,
    /// <summary>Deprecated:Removed</summary>
    XML_WITH_DEBUG_RUN = 30,
    /// <summary>GZIP compression</summary>
    XML_WITH_ZLIB = 31,
    /// <summary>ICU</summary>
    XML_WITH_ICU = 32,
    /// <summary>LZMA compression</summary>
    XML_WITH_LZMA = 33,
    /// <summary>RELAXNG</summary><remarks>since 2.14.0</remarks>
    XML_WITH_RELAXNG = 34
  );

  /// <summary>
  /// An xmlParserInput is an input flow for the XML processor.
  /// Each entity parsed is associated an xmlParserInput (except the
  /// few predefined ones). This is the case both for internal entities
  /// - in which case the flow is already completely in memory - or
  /// external entities - in which case we use the buf structure for
  /// progressive reading and I18N conversions to the internal UTF-8 format.
  ///</summary>
  xmlParserInputPtr = ^xmlParserInput;
  xmlParserInput = record end;

  /// <summary> The parser context. </summary>
  xmlParserCtxtPtr = ^xmlParserCtxt;
  xmlParserCtxt = record end;

  /// <summary> A SAX locator </summary>
  xmlSAXLocatorPtr = ^xmlSAXLocator;
  xmlSAXLocator = packed record
    getPublicId: function(ctx: Pointer): xmlCharPtr; cdecl;
    getSystemId: function(ctx: Pointer): xmlCharPtr; cdecl;
    getLineNumber: function(ctx: Pointer): Integer; cdecl;
    getColumnNumber: function(ctx: Pointer): Integer; cdecl;
  end;

  xmlSAX2NsPtr = ^xmlSAX2Ns;
  xmlSAX2Ns = packed record
    prefix: xmlCharPtr;
    URI: xmlCharPtr;
  end;

  xmlSAX2AttrPtr = ^xmlSAX2Attr;
  xmlSAX2Attr = packed record
    localname: xmlCharPtr;
    prefix: xmlCharPtr;
    URI: xmlCharPtr;
    value: xmlCharPtr;
    valueEnd: xmlCharPtr;
  end;

  internalSubsetSAXFunc     = procedure(ctx: Pointer; const name, ExternalID, SystemID: xmlCharPtr); cdecl;
  isStandaloneSAXFunc       = function (ctx: Pointer): Integer; cdecl;
  hasInternalSubsetSAXFunc  = function (ctx: Pointer): Integer; cdecl;
  hasExternalSubsetSAXFunc  = function (ctx: Pointer): Integer; cdecl;
  resolveEntitySAXFunc      = function (ctx: Pointer; const publicId, systemId: xmlCharPtr): xmlParserInputPtr; cdecl;
  getEntitySAXFunc          = function (ctx: Pointer; const name: xmlCharPtr): xmlEntityPtr; cdecl;
  getParameterEntitySAXFunc = function (ctx: Pointer; const name: xmlCharPtr): xmlEntityPtr; cdecl;
  entityDeclSAXFunc         = procedure(ctx: Pointer; const name: xmlCharPtr; entType: Integer; publicId, systemId, content: xmlCharPtr); cdecl;
  notationDeclSAXFunc       = procedure(ctx: Pointer; const name, publicId, systemId: xmlCharPtr); cdecl;
  attributeDeclSAXFunc      = procedure(ctx: Pointer; const elem, fullname: xmlCharPtr; attrType, def: Integer; defaultValue: xmlCharPtr; tree: xmlEnumerationPtr); cdecl;
  elementDeclSAXFunc        = procedure(ctx: Pointer; const name: xmlCharPtr; elemType: Integer; content: xmlElementContentPtr); cdecl;
  unparsedEntityDeclSAXFunc = procedure(ctx: Pointer; const name, publicId, systemId, notationName: xmlCharPtr); cdecl;
  setDocumentLocatorSAXFunc = procedure(ctx: Pointer; loc: xmlSAXLocatorPtr); cdecl;
  startDocumentSAXFunc      = procedure(ctx: Pointer); cdecl;
  endDocumentSAXFunc        = procedure(ctx: Pointer); cdecl;
  startElementSAXFunc       = procedure(ctx: Pointer); cdecl;
  endElementSAXFunc         = procedure(ctx: Pointer; const name: xmlCharPtr); cdecl;
  referenceSAXFunc          = procedure(ctx: Pointer; const name: xmlCharPtr); cdecl;

  charactersSAXFunc         = procedure(ctx: Pointer; const ch: xmlCharPtr; len: Integer); cdecl;
  ignorableWhitespaceSAXFunc= procedure(ctx: Pointer; const ch: xmlCharPtr; len: Integer); cdecl;
  processingInstructionSAXFunc= procedure(ctx: Pointer; const target, data: xmlCharPtr); cdecl;
  commentSAXFunc            = procedure(ctx: Pointer; const value: xmlCharPtr); cdecl;
  cdataBlockSAXFunc         = procedure(ctx: Pointer; const value: xmlCharPtr; len: Integer); cdecl;
  warningSAXFunc            = procedure(ctx: Pointer; const msg: xmlCharPtr); cdecl varargs;
  errorSAXFunc              = procedure(ctx: Pointer; const msg: xmlCharPtr); cdecl varargs;
  fatalErrorSAXFunc         = procedure(ctx: Pointer; const msg: xmlCharPtr); cdecl varargs;
  externalSubsetSAXFunc     = procedure(ctx: Pointer; const name, ExternalID, SystemID: xmlCharPtr); cdecl;
  startElementNsSAX2Func    = procedure(ctx: Pointer; const localname, prefix, URI: xmlCharPtr; nb_namespaces: Integer; namespaces: xmlSAX2NsPtr; nb_attributes, nb_defaulted: Integer; attributes: xmlSAX2AttrPtr); cdecl;
  endElementNsSAX2Func      = procedure(ctx: Pointer; const localname, prefix, URI: xmlCharPtr); cdecl;

  ///<summary></summary>
  xmlSAXHandlerPtr = ^xmlSAXHandler;
  xmlSAXHandler = record
    ///<summary>Called after the start of the document type declaration was parsed. </summary>
    internalSubset: internalSubsetSAXFunc;
    ///<summary>Standalone status. </summary>
    isStandalone: isStandaloneSAXFunc;
    ///<summary>Internal subset availability. </summary>
    hasInternalSubset: hasInternalSubsetSAXFunc;
    ///<summary>External subset availability. </summary>
    hasExternalSubset: hasExternalSubsetSAXFunc;
    ///<summary>Only called when loading external DTDs. </summary>
    resolveEntity: resolveEntitySAXFunc;
    ///<summary>Called when looking up general entities. </summary>
    getEntity: getEntitySAXFunc;
    ///<summary>Called after an entity declaration was parsed. </summary>
    entityDecl: entityDeclSAXFunc;
    ///<summary>Called after a notation declaration was parsed. </summary>
    notationDecl: notationDeclSAXFunc;
    ///<summary>Called after an attribute declaration was parsed. </summary>
    attributeDecl: attributeDeclSAXFunc;
    ///<summary>Called after an element declaration was parsed. </summary>
    elementDecl: elementDeclSAXFunc;
    ///<summary>Called after an unparsed entity declaration was parsed. </summary>
    unparsedEntityDecl: unparsedEntityDeclSAXFunc;
    ///<summary>This callback receives the "document locator" at startup, which is always the global xmlDefaultSAXLocator. </summary>
    setDocumentLocator: setDocumentLocatorSAXFunc;
    ///<summary>Called after the XML declaration was parsed. </summary>
    startDocument: startDocumentSAXFunc;
    ///<summary>Called at the end of the document. </summary>
    endDocument: endDocumentSAXFunc;
    ///<summary>Legacy start tag handler. </summary>
    startElement: startElementSAXFunc;
    ///<summary>See <see cref="xmlSAXHandler.startElement"/></summary>
    endElement: endElementSAXFunc;
    ///<summary>Called after an entity reference was parsed. </summary>
    &reference: referenceSAXFunc;
    ///<summary>Called after a character data was parsed. </summary>
    characters: charactersSAXFunc;
    ///<summary>Called after "ignorable" whitespace was parsed. </summary>
    ignorableWhitespace: ignorableWhitespaceSAXFunc;
    ///<summary>Called after a processing instruction was parsed. </summary>
    processingInstruction: processingInstructionSAXFunc;
    ///<summary>Called after a comment was parsed. </summary>
    comment: commentSAXFunc;
    ///<summary>Callback for warning messages. </summary>
    warning: warningSAXFunc;
    ///<summary>Callback for error messages. </summary>
    error: errorSAXFunc;
    ///<summary>Unused, all errors go to error.</summary>
    fatalError: fatalErrorSAXFunc;
    ///<summary>Called when looking up parameter entities. </summary>
    getParameterEntity: getParameterEntitySAXFunc;
    ///<summary>Called after a CDATA section was parsed. </summary>
    cdataBlock: cdataBlockSAXFunc;
    ///<summary>Called to parse the external subset. </summary>
    externalSubset: externalSubsetSAXFunc;
    ///<summary> `initialized` should always be set to XML_SAX2_MAGIC to enable the
    /// modern SAX2 interface.
    /// </summary>
    initialized: uint;
    /// The following members are only used by the SAX2 interface.
    ///<summary>Application data. </summary>
    _private: Pointer;
    ///<summary>Called after a start tag was parsed. </summary>
    startElementNs: startElementNsSAX2Func;
    ///<summary>Called after an end tag was parsed. </summary>
    endElementNs: endElementNsSAX2Func;
    ///<summary>Structured error handler. </summary>
    serror: xmlStructuredErrorFunc;
  end;

  xmlParserNodeInfoPtr = ^xmlParserNodeInfo;
  xmlParserNodeInfo = record
    node: xmlNodePtr;
    // Position & line # that text that created the node begins & ends on
    begin_pos: ulong;
    begin_line: ulong;
    end_pos: ulong;
    end_line: ulong;
  end;

  xmlParserNodeInfoSeqPtr = ^xmlParserNodeInfoSeq;
  xmlParserNodeInfoSeq = record
    maximum: ulong;
    length: ulong;
    buffer: xmlParserNodeInfoPtr;
  end;

  xmlNodeArrayPtr = ^xmlNodeArray;
  xmlNodeArray = array[0..0] of xmlNodePtr;

  xmlExternalEntityLoader   = function(const URL, ID: PUTF8Char; context: xmlParserCtxtPtr): xmlParserInputPtr; cdecl;
  xmlResourceLoader         = function(ctxt: Pointer; const url, publicId: xmlCharPtr; &type: xmlResourceType; flags: Integer; var output: xmlParserInputPtr): Integer; cdecl;

var
  xmlCleanupParser          : procedure; cdecl;
  xmlClearNodeInfoSeq       : procedure(seq: xmlParserNodeInfoSeqPtr); cdecl;
  xmlCreateDocParserCtxt    : function (const cur: XmlCharPtr): xmlParserCtxtPtr; cdecl;
  xmlCreateEntityParserCtxt : function (URL, ID, base: xmlCharPtr): xmlParserCtxtPtr; cdecl;
  xmlCreateFileParserCtxt   : function (filename: PUTF8Char): xmlParserCtxtPtr; cdecl;
  xmlCreateIOParserCtxt     : function (sax: xmlSAXHandlerPtr; user_data: Pointer; ioread: xmlInputReadCallback; ioclose: xmlInputCloseCallback; ioctx: Pointer; enc: xmlCharEncoding): xmlParserCtxtPtr; cdecl;
  xmlCreateMemoryParserCtxt : function (buffer: Pointer; size: Integer): xmlParserCtxtPtr; cdecl;
  xmlCreatePushParserCtxt   : function (sax: xmlSAXHandlerPtr; user_data: Pointer; chunk: PUTF8Char; size: Integer; const filename: PUTF8Char): xmlParserCtxtPtr; cdecl;
  xmlCreateURLParserCtxt    : function (filename: PUTF8Char; options: Integer): xmlParserCtxtPtr; cdecl;
  xmlCtxtErrMemory          : procedure(ctxt: xmlParserCtxtPtr); cdecl;
  xmlCtxtGetCatalogs        : function (ctxt: xmlParserCtxtPtr): Pointer; cdecl;
  xmlCtxtGetDeclaredEncoding: function(ctxt: xmlParserCtxtPtr): xmlCharPtr; cdecl;
  xmlCtxtGetDict            : function (ctxt: xmlParserCtxtPtr): xmlDictPtr; cdecl;
  xmlCtxtGetOptions         : function (ctxt: xmlParserCtxtPtr): Integer; cdecl;
  xmlCtxtGetPrivate         : function (ctxt: xmlParserCtxtPtr): Pointer; cdecl;
  xmlCtxtGetStandalone      : function (ctxt: xmlParserCtxtPtr): Integer; cdecl;
  xmlCtxtGetStatus          : function (ctxt: xmlParserCtxtPtr): Integer; cdecl;
  xmlCtxtGetValidCtxt       : function (ctxt: xmlParserCtxtPtr): xmlValidCtxtPtr; cdecl;
  xmlCtxtGetVersion         : function (ctxt: xmlParserCtxtPtr): xmlCharPtr; cdecl;
  xmlCtxtParseContent       : function (ctxt: xmlParserCtxtPtr; input: xmlParserInputPtr; node: xmlNodePtr; hasTextDecl: Integer): xmlNodePtr; cdecl;
  xmlCtxtParseDocument      : function (ctxt: xmlParserCtxtPtr; input: xmlParserInputPtr): xmlDocPtr; cdecl;
  xmlCtxtParseDtd           : function (ctxt: xmlParserCtxtPtr; input: xmlParserInputPtr; publicId, systemId: xmlCharPtr): xmlDTDPtr; cdecl;
  xmlCtxtReadDoc            : function (ctxt: xmlParserCtxtPtr; const cur, URL, encoding: xmlCharPtr; options: Integer): xmlDocPtr; cdecl;
  xmlCtxtReadFd             : function (ctxt: xmlParserCtxtPtr; fd: Integer; const URL, encoding: xmlCharPtr; options: Integer): xmlDocPtr; cdecl;
  xmlCtxtReadFile           : function (ctxt: xmlParserCtxtPtr; const filename, encoding: xmlCharPtr; options: Integer): xmlDocPtr; cdecl;
  xmlCtxtReadIO             : function (ctxt: xmlParserCtxtPtr; ioread: xmlInputReadCallback; ioclose: xmlInputCloseCallback; ioctx: Pointer; const URL, encoding: xmlCharPtr; options: Integer): xmlDocPtr; cdecl;
  xmlCtxtReset             : procedure(ctxt: xmlParserCtxtPtr); cdecl;
  xmlCtxtResetPush          : function (ctxt: xmlParserCtxtPtr; const chunk: Pointer; size: Integer; const filename, encoding: PUTF8Char): Integer; cdecl;
  xmlCtxtSetCatalogs        : procedure(ctxt: xmlParserCtxtPtr; catalogs: Pointer); cdecl;
  xmlCtxtSetCharEncConvImpl : procedure(ctxt: xmlParserCtxtPtr; impl: xmlCharEncConvImpl; vctxt: Pointer); cdecl;
  xmlCtxtSetDict            : procedure(ctxt: xmlParserCtxtPtr; dict: xmlDictPtr); cdecl;
  xmlCtxtSetErrorHandler    : procedure(ctxt: xmlParserCtxtPtr; handler: xmlStructuredErrorFunc; data: Pointer); cdecl;
  xmlCtxtSetMaxAmplification: procedure(ctxt: xmlParserCtxtPtr; maxAmpl: ulong); cdecl;
  xmlCtxtSetOptions         : function (ctxt: xmlParserCtxtPtr; options: Integer): Integer; cdecl;
  xmlCtxtSetPrivate         : procedure(ctxt: xmlParserCtxtPtr; priv: Pointer); cdecl;
  xmlCtxtSetResourceLoader  : procedure(ctxt: xmlParserCtxtPtr; loader: xmlResourceLoader; vctxt: Pointer); cdecl;
  xmlCtxtUseOptions         : function (ctxt: xmlParserCtxtPtr; options: Integer): Integer; cdecl;
  xmlFreeInputStream        : procedure(input: xmlParserInputPtr); cdecl;
  xmlFreeParserCtxt         : procedure(ctxt: xmlParserCtxtPtr); cdecl;
  xmlGetExternalEntityLoader: function: xmlExternalEntityLoader; cdecl;
  xmlInitNodeInfoSeq        : procedure(seq: xmlParserNodeInfoSeqPtr); cdecl;
  xmlInputSetEncodingHandler: function (input: xmlParserInputPtr; handler: xmlCharEncodingHandler): xmlParserErrors; cdecl;
  xmlIOParseDTD             : function(sax: xmlSAXHandler; input: xmlParserInputBufferPtr; encoding: xmlCharEncoding): xmlDtdPtr; cdecl;
  xmlLoadExternalEntity     : function (const URL, ID: PUTF8Char; ctxt: xmlParserCtxtPtr): xmlParserInputPtr; cdecl;
  xmlNewInputFromFd         : function (url: xmlCharPtr; fd: Integer; flags: xmlParserInputFlags): xmlParserInputPtr; cdecl;
  xmlNewInputFromFile       : function (ctxt: xmlParserCtxtPtr; filename: PUTF8Char): xmlParserInputPtr; cdecl;
  xmlNewInputFromIO         : function (url: xmlCharPtr; ioRead: xmlInputReadCallback; ioClose: xmlInputCloseCallback; ioCtxt: Pointer; flags: xmlParserInputFlags): xmlParserInputPtr; cdecl;
  xmlNewInputFromMemory     : function (url: xmlCharPtr; mem: Pointer; size: size_t; flags: xmlParserInputFlags): xmlParserInputPtr; cdecl;
  xmlNewInputFromString     : function (url: xmlCharPtr; str: xmlCharPtr; flags: xmlParserInputFlags): xmlParserInputPtr; cdecl;
  xmlNewInputFromUrl        : function (url: xmlCharPtr; flags: xmlParserInputFlags; var output: xmlParserInputPtr): xmlParserErrors; cdecl;
  xmlNewInputStream         : function (ctxt: xmlParserCtxtPtr): xmlParserInputPtr; cdecl;
  xmlNewIOInputStream       : function (ctxt: xmlParserCtxtPtr; input: xmlParserInputBufferPtr; enc: xmlCharEncoding): xmlParserInputPtr; cdecl;
  xmlNewParserCtxt          : function: xmlParserCtxtPtr; cdecl;
  xmlNewSAXParserCtxt       : function (const sax: xmlSAXHandlerPtr; userData: Pointer): xmlParserCtxtPtr; cdecl;
  xmlNewStringInputStream   : function (ctxt: xmlParserCtxtPtr; buffer: xmlCharPtr): xmlParserInputPtr; cdecl;
  xmlNoNetExternalEntityLoader:function (const URL, ID: PUTF8Char; ctxt: xmlParserCtxtPtr): xmlOutputBufferPtr; cdecl;
  xmlParseBalancedChunkMemory: function(doc: xmlDocPtr; sax: xmlSAXHandlerPtr; user_data: Pointer; depth: Integer; const str: xmlCharPtr; lst: xmlNodeArrayPtr): Integer; cdecl;
  xmlParseBalancedChunkMemoryRecover: function(doc: xmlDocPtr; sax: xmlSAXHandlerPtr; user_data: Pointer; depth: Integer; const str: xmlCharPtr; lst: xmlNodeArrayPtr; recover: Integer): Integer; cdecl;
  xmlParseChunk             : function (ctxt: xmlParserCtxtPtr; const chunk: Pointer; size, terminate: Integer): Integer; cdecl;
  xmlParseCtxtExternalEntity: function(ctxt: xmlParserCtxtPtr; const URL, ID: xmlCharPtr; lst: xmlNodeArrayPtr): Integer; cdecl;
  xmlParseDoc               : function (const cur: xmlCharPtr): xmlDocPtr; cdecl;
  xmlParseDocument          : function (ctxt: xmlParserCtxtPtr): Integer; cdecl;
  xmlParseDTD               : function (const publicId, systemId: xmlCharPtr): xmlDtdPtr; cdecl;
  xmlParseExtParsedEnt      : function (ctxt: xmlParserCtxtPtr): Integer; cdecl;
  xmlParseFile              : function (const filename: PUTF8Char): xmlDocPtr; cdecl;
  xmlParseInNodeContext     : function (node: xmlNodePtr; const data: PUTF8Char; datalen: Integer; options: Integer; lst: xmlNodeArrayPtr): xmlParserErrors; cdecl;
  xmlParseMemory            : function (const buffer: PUTF8Char; size: Integer): xmlDocPtr; cdecl;
  xmlParserAddNodeInfo      : procedure(ctxt: xmlParserCtxtPtr; info: xmlParserNodeInfoPtr); cdecl;
  xmlParserFindNodeInfo     : function (ctxt: xmlParserCtxtPtr; node: xmlNodePtr): xmlParserNodeInfoPtr; cdecl;
  xmlParserFindNodeInfoIndex: function(seq: xmlParserNodeInfoSeqPtr; node: xmlNodePtr): ulong; cdecl;
  xmlParserInputGrow        : function (input: xmlParserInputPtr; len: Integer): Integer; cdecl;
  xmlReadDoc                : function (const cur, URL, encoding: xmlCharPtr; options: Integer): xmlDocPtr; cdecl;
  xmlReadFd                 : function (fd: Integer; const URL, encoding: xmlCharPtr; options: Integer): xmlDocPtr; cdecl;
  xmlReadFile               : function(const URL, encoding: PUTF8Char; options: Integer): xmlDocPtr; cdecl;
  xmlReadIO                 : function (ioread: xmlInputReadCallback; ioclose: xmlInputCloseCallback; ioctx: Pointer; const URL, encoding: xmlCharPtr; options: Integer): xmlDocPtr; cdecl;
  xmlReadMemory             : function(const buffer: PUTF8Char; size: Integer; const URL, encoding: PUTF8Char; options: Integer): xmlDocPtr; cdecl;
  xmlSetExternalEntityLoader: procedure(f: xmlExternalEntityLoader); cdecl;
  xmlSplitQName             : function (ctxt: xmlParserCtxtPtr; name: xmlCharPtr; var prefix: xmlCharPtr) : xmlCharPtr; cdecl;
  xmlStopParser             : procedure(ctxt: xmlParserCtxtPtr); cdecl;
  xmlSwitchEncoding         : function (ctxt: xmlParserCtxtPtr; enc: xmlCharEncoding): Integer; cdecl;
  xmlSwitchEncodingName     : function (ctxt: xmlParserCtxtPtr; encoding: PUTF8Char): Integer; cdecl;
  xmlSwitchToEncoding       : function (ctxt: xmlParserCtxtPtr; handler: xmlCharEncodingHandlerPtr): Integer; cdecl;

{$endregion}

{$region 'xmlsave.h'}

type
  xmlSaveOption = type Integer;
  const
    XML_SAVE_FORMAT     = 1 shl 0; // format save output
    XML_SAVE_NO_DECL    = 1 shl 1; // drop the xml declaration
    XML_SAVE_NO_EMPTY   = 1 shl 2; // no empty tags
    XML_SAVE_NO_XHTML   = 1 shl 3; // disable XHTML1 specific rules
    XML_SAVE_XHTML      = 1 shl 4; // force XHTML1 specific rules
    XML_SAVE_AS_XML     = 1 shl 5; // force XML serialization on HTML doc
    XML_SAVE_AS_HTML    = 1 shl 6; // force HTML serialization on XML doc
    XML_SAVE_WSNONSIG   = 1 shl 7; // format with non-significant whitespace
    XML_SAVE_EMPTY      = 1 shl 8; // force empty tags; overriding global
    XML_SAVE_NO_INDENT  = 1 shl 9; // disable indenting
    XML_SAVE_INDENT     = 1 shl 10;// force indenting; overriding global

type
  xmlSaveCtxtPtr = ^xmlSaveCtxt;
  xmlSaveCtxt = record end;

var
  xmlSaveDoc                : function(ctxt: xmlSaveCtxtPtr; doc: xmlDocPtr): long; cdecl;
  xmlSaveTree               : function(ctxt: xmlSaveCtxtPtr; node: xmlNodePtr): long; cdecl;
  xmlSaveFlush              : function(ctxt: xmlSaveCtxtPtr): Integer; cdecl;
  xmlSaveClose              : function(ctxt: xmlSaveCtxtPtr): Integer;  cdecl;
  xmlSaveFinish             : function(ctxt: xmlSaveCtxtPtr): xmlParserErrors; cdecl;
  xmlSaveFile               : function(filename: PUTF8Char; cur: xmlDocPtr): Integer; cdecl;
  xmlSaveFormatFile         : function(filename: PUTF8Char; cur: xmlDocPtr; format: Integer): Integer; cdecl;
  xmlSaveFormatFileEnc      : function(filename: PUTF8Char; cur: xmlDocPtr; const encoding: PUTF8Char; format: Integer): Integer; cdecl;
  xmlSaveFileEnc            : function(filename: PUTF8Char; cur: xmlDocPtr; const encoding: PUTF8Char): Integer; cdecl;
  xmlNodeDump               : function(buf: xmlBufferPtr; doc: xmlDocPtr; cur: xmlNodePtr; level: Integer; format: Integer): Integer; cdecl;
  xmlNodeDumpOutput         : procedure(buf: xmlOutputBufferPtr; doc: xmlDocPtr; cur: xmlNodePtr; level: Integer; format: Integer; const encoding: xmlCharPtr); cdecl;
  xmlSaveToFd               : function(fd: Integer; encoding: xmlCharPtr; options: Integer): xmlSaveCtxtPtr; cdecl;
  xmlSaveToFilename         : function(filename: xmlCharPtr; encoding: xmlCharPtr; options: Integer): xmlSaveCtxtPtr; cdecl;
  xmlSaveToBuffer           : function(buffer: xmlBuffer; encoding: xmlCharPtr; options: Integer): xmlSaveCtxtPtr; cdecl;
  xmlSaveToIO               : function(iowrite: xmlOutputWriteCallback; ioclose: xmlOutputCloseCallback; ioctx: Pointer; encoding: xmlCharPtr; options: Integer): xmlSaveCtxtPtr; cdecl;
{$endregion}

{$region 'valid.h'}

type
  xmlIDTablePtr = ^xmlIDTable;
  xmlIDTable = record end;

  xmlValidityErrorFunc   = procedure(ctx: Pointer; const msg: PUTF8Char); cdecl varargs;
  xmlValidityWarningFunc = procedure(ctx: Pointer; const msg: PUTF8Char); cdecl varargs;

var
  xmlAddIDSafe                : function (attr: xmlAttrPtr; value: xmlCharPtr): Integer; cdecl;
  xmlAddID                    : function (ctx: xmlValidCtxtPtr; doc: xmlDocPtr; value: xmlCharPtr; attr: xmlAttrPtr): xmlIDPtr; cdecl;
  xmlFreeIDTable              : procedure(table: xmlIDTablePtr); cdecl;
  xmlGetID                    : function (doc: xmlDocPtr; ID: xmlCharPtr): xmlAttrPtr; cdecl;
  xmlIsID                     : function (doc: xmlDocPtr; elem: xmlNodePtr; attr: xmlAttrPtr): Integer; cdecl;
  xmlRemoveID                 : function (doc: xmlDocPtr; attr: xmlAttrPtr): Integer; cdecl;
  xmlFreeEnumeration          : procedure(cur: xmlEnumerationPtr); cdecl;
  xmlNewValidCtxt             : function: xmlValidCtxtPtr; cdecl;
  xmlFreeValidCtxt            : procedure(ctx: xmlValidCtxtPtr); cdecl;

  xmlValidateDtd              : function (ctx: xmlValidCtxtPtr; doc: xmlDocPtr; dtd: xmlDtdPtr): Integer; cdecl;
  xmlValidateElement          : function (ctx: xmlValidCtxtPtr; doc: xmlDocPtr; elem: xmlNodePtr): Integer; cdecl;

  xmlCtxtValidateDocument     : function (ctxt: xmlParserCtxtPtr; doc: xmlDocPtr): Integer; cdecl;
  xmlCtxtValidateDtd          : function (ctxt: xmlParserCtxtPtr; doc: xmlDocPtr; dtd: xmlDtdPtr): Integer; cdecl;

  xmlIsMixedElement           : function (doc: xmlDocPtr; name: xmlCharPtr): Integer; cdecl;
  xmlGetDtdAttrDesc           : function (dtd: xmlDtdPtr; elem, name: xmlCharPtr): xmlAttributePtr; cdecl;
  xmlGetDtdQAttrDesc          : function (dtd: xmlDtdPtr; elem, name, prefix: xmlCharPtr): xmlAttributePtr; cdecl;
  xmlGetDtdNotationDesc       : function (dtd: xmlDtdPtr; name: xmlCharPtr): xmlNotationPtr; cdecl;
  xmlGetDtdQElementDesc       : function (dtd: xmlDtdPtr; name: xmlCharPtr; prefix: xmlCharPtr): xmlElementPtr; cdecl;
  xmlGetDtdElementDesc        : function (dtd: xmlDtdPtr; name: xmlCharPtr): xmlElementPtr; cdecl;

  xmlValidGetPotentialChildren: function (ctree: xmlElementContent; names: xmlNodeArrayPtr; len: Integer; max: Integer): Integer; cdecl;

  xmlValidGetValidElements    : function (prev, next: xmlCharPtr; names: xmlNodeArrayPtr; max: Integer): Integer; cdecl;
  xmlValidateNameValue        : function (value: xmlCharPtr): Integer; cdecl;
  xmlValidateNamesValue       : function (value: xmlCharPtr): Integer; cdecl;
  xmlValidateNmtokenValue     : function (value: xmlCharPtr): Integer; cdecl;
  xmlValidateNmtokensValue    : function (value: xmlCharPtr): Integer; cdecl;

  xmlAddNotationDecl          : function (ctx: xmlValidCtxtPtr; dtd: xmlDtdPtr; name, PublicID, SystemID: xmlCharPtr): xmlNotationPtr; cdecl;

{$endregion}

{$region 'SAX2'}

var
  xmlSAX2GetPublicId        : function (ctx: Pointer): xmlCharPtr; cdecl;
  xmlSAX2GetSystemId        : function (ctx: Pointer): xmlCharPtr; cdecl;
  xmlSAX2SetDocumentLocator : procedure(ctx: Pointer; loc: xmlSAXLocatorPtr); cdecl;
  xmlSAX2GetLineNumber      : function (ctx: Pointer): Integer; cdecl;
  xmlSAX2GetColumnNumber    : function (ctx: Pointer): Integer; cdecl;
  xmlSAX2IsStandalone       : function (ctx: Pointer): Integer; cdecl;
  xmlSAX2HasInternalSubset  : function (ctx: Pointer): Integer; cdecl;
  xmlSAX2HasExternalSubset  : function (ctx: Pointer): Integer; cdecl;
  xmlSAX2InternalSubset     : procedure(ctx: Pointer; const name, ExternalID, SystemID: xmlCharPtr); cdecl;
  xmlSAX2ExternalSubset     : procedure(ctx: Pointer; const name, ExternalID, SystemID: xmlCharPtr); cdecl;
  xmlSAX2GetEntity          : function (ctx: Pointer; const name: xmlCharPtr): xmlEntityPtr; cdecl;
  xmlSAX2GetParameterEntity : function (ctx: Pointer; const name: xmlCharPtr): xmlEntityPtr; cdecl;
  xmlSAX2ResolveEntity      : function (ctx: Pointer; const publicId, systemId: xmlCharPtr): xmlParserInputPtr; cdecl;
  xmlSAX2EntityDecl         : procedure(ctx: Pointer; const name: xmlCharPtr; entType: Integer; publicId, systemId, content: xmlCharPtr); cdecl;
  xmlSAX2AttributeDecl      : procedure(ctx: Pointer; const elem, fullname: xmlCharPtr; attrType, def: Integer; defaultValue: xmlCharPtr; tree: xmlEnumerationPtr); cdecl;
  xmlSAX2ElementDecl        : procedure(ctx: Pointer; const name: xmlCharPtr; elemType: Integer; content: xmlElementContentPtr); cdecl;
  xmlSAX2NotationDecl       : procedure(ctx: Pointer; const name, publicId, systemId: xmlCharPtr); cdecl;
  xmlSAX2UnparsedEntityDecl : procedure(ctx: Pointer; const name, publicId, systemId, notationName: xmlCharPtr); cdecl;
  xmlSAX2StartDocument      : procedure(ctx: Pointer); cdecl;
  xmlSAX2EndDocument        : procedure(ctx: Pointer); cdecl;
  xmlSAX2StartElementNs     : procedure(ctx: Pointer; const localname, prefix, URI: xmlCharPtr; nb_namespaces: Integer; namespaces: xmlSAX2NsPtr; nb_attributes, nb_defaulted: Integer; attributes: xmlSAX2AttrPtr); cdecl;
  xmlSAX2EndElementNs       : procedure(ctx: Pointer; const localname, prefix, URI: xmlCharPtr); cdecl;
  xmlSAX2Reference          : procedure(ctx: Pointer; const name: xmlCharPtr); cdecl;
  xmlSAX2Characters         : procedure(ctx: Pointer; const ch: xmlCharPtr; len: Integer); cdecl;
  xmlSAX2IgnorableWhitespace: procedure(ctx: Pointer; const ch: xmlCharPtr; len: Integer); cdecl;
  xmlSAX2ProcessingInstruction: procedure(ctx: Pointer; const target, data: xmlCharPtr); cdecl;
  xmlSAX2Comment            : procedure(ctx: Pointer; const value: xmlCharPtr); cdecl;
  xmlSAX2CDataBlock         :  procedure(ctx: Pointer; const value: xmlCharPtr; len: Integer); cdecl;
  xmlSAXDefaultVersion      : function(version: Integer): Integer; cdecl;
  xmlSAXVersion             : function(hdlr: xmlSAXHandlerPtr; version: Integer): Integer; cdecl;
  xmlSAX2InitDefaultSAXHandler : procedure(hdlr: xmlSAXHandlerPtr; warning: Integer); cdecl;
  xmlSAX2InitHtmlDefaultSAXHandler : procedure(hdlr: xmlSAXHandlerPtr); cdecl;


{$endregion}

{$region 'xmlschemas.h'}

type
  xmlSchemaValidOption = (
    XML_SCHEMA_VAL_VC_I_CREATE = 1
  );

  xmlSchemaValidCtxtPtr = ^xmlSchemaValidCtxt;
  xmlSchemaValidCtxt = record end;

  xmlSchemaParserCtxtPtr = ^xmlSchemaParserCtxt;
  xmlSchemaParserCtxt = record end;

  xmlSchemaPtr = ^xmlSchema;
  xmlSchema = record end;

  xmlSchemaSAXPlugPtr = ^xmlSchemaSAXPlugRec;
  xmlSchemaSAXPlugRec = record end;

  xmlSchemaValidityErrorFunc   = procedure(ctx: Pointer; msg: xmlCharPtr); cdecl varargs;
  xmlSchemaValidityWarningFunc = procedure(ctx: Pointer; msg: xmlCharPtr); cdecl varargs;
  xmlSchemaValidityLocatorFunc = function (ctx: Pointer; var fileName: xmlCharPtr; var line: ulong): Integer; cdecl;

var
  xmlSchemaNewParserCtxt      : function (URL: xmlCharPtr): xmlSchemaParserCtxtPtr; cdecl;
  xmlSchemaNewMemParserCtxt   : function (buffer: Pointer; size: Integer): xmlSchemaParserCtxtPtr; cdecl;
  xmlSchemaNewDocParserCtxt   : function (doc: xmlDocPtr) : xmlSchemaParserCtxtPtr; cdecl;
  xmlSchemaFreeParserCtxt     : procedure(ctxt: xmlSchemaParserCtxtPtr); cdecl;
  xmlSchemaSetParserErrors    : procedure(ctxt: xmlSchemaParserCtxtPtr; err: xmlSchemaValidityErrorFunc; warn: xmlSchemaValidityWarningFunc; ctx: Pointer); cdecl;
  xmlSchemaSetParserStructuredErrors : procedure(ctxt: xmlSchemaParserCtxtPtr;serror: xmlStructuredErrorFunc; ctx: Pointer); cdecl;
  xmlSchemaGetParserErrors    : function (ctxt: xmlSchemaParserCtxtPtr; var err: xmlSchemaValidityErrorFunc; var warn: xmlSchemaValidityWarningFunc; var ctx: Pointer): Integer; cdecl;
  xmlSchemaSetResourceLoader  : procedure(ctxt: xmlSchemaParserCtxtPtr; loader: xmlResourceLoader; data: Pointer); cdecl;
  xmlSchemaIsValid            : function (ctxt: xmlSchemaValidCtxtPtr): Integer; cdecl;
  xmlSchemaParse              : function (ctxt: xmlSchemaParserCtxtPtr): xmlSchemaPtr; cdecl;
  xmlSchemaFree               : procedure(schema: xmlSchemaPtr); cdecl;
  xmlSchemaDump               : procedure(ctxt: xmlSchemaParserCtxtPtr); cdecl;
  xmlSchemaSetValidErrors     : procedure(ctxt: xmlSchemaValidCtxtPtr; err: xmlSchemaValidityErrorFunc; warn: xmlSchemaValidityWarningFunc; ctx: Pointer); cdecl;
  xmlSchemaSetValidStructuredErrors: procedure(ctxt: xmlSchemaValidCtxtPtr; serror: xmlStructuredErrorFunc; ctx: Pointer); cdecl;
  xmlSchemaGetValidErrors     : function(ctxt: xmlSchemaValidCtxtPtr; var erro: xmlSchemaValidityErrorFunc; var warn: xmlSchemaValidityWarningFunc; var ctx: Pointer): Integer; cdecl;
  xmlSchemaSetValidOptions    : function(ctxt: xmlSchemaValidCtxtPtr; options: Integer): Integer; cdecl;
  xmlSchemaValidateSetFilename: procedure(vctxt: xmlSchemaValidCtxtPtr; filename: xmlCharPtr); cdecl;
  xmlSchemaValidCtxtGetOptions: function(ctxt: xmlSchemaValidCtxtPtr): Integer; cdecl;
  xmlSchemaNewValidCtxt       : function(schema: xmlSchemaPtr): xmlSchemaValidCtxtPtr; cdecl;
  xmlSchemaFreeValidCtxt      : procedure(ctxt: xmlSchemaValidCtxtPtr); cdecl;
  xmlSchemaValidateDoc        : function (ctxt: xmlSchemaValidCtxtPtr; instance: xmlDocPtr): Integer; cdecl;
  xmlSchemaValidateOneElement : function (ctxt: xmlSchemaValidCtxtPtr; elem: xmlDocPtr): Integer; cdecl;
  xmlSchemaValidateStream     : function (ctxt: xmlSchemaValidCtxtPtr; input: xmlParserInputBufferPtr; enc: xmlCharEncoding; sax: xmlSAXHandler; user_data: Pointer): Integer; cdecl;
  xmlSchemaValidateFile       : function (ctxt: xmlSchemaValidCtxtPtr; filename: xmlCharPtr; options: Integer): Integer; cdecl;
  xmlSchemaValidCtxtGetParserCtxt: function(ctxt: xmlSchemaValidCtxtPtr): xmlParserCtxtPtr; cdecl;
  xmlSchemaSAXPlug           : function (ctxt: xmlSchemaValidCtxtPtr; sax: xmlSAXHandlerPtr; var user_data: Pointer): xmlSchemaSAXPlugPtr; cdecl;
  xmlSchemaSAXUnplug         : function (plug: xmlSchemaSAXPlugPtr): Integer; cdecl;
  xmlSchemaValidateSetLocator: procedure(vctxt: xmlSchemaValidCtxtPtr; f: xmlSchemaValidityLocatorFunc; ctxt: Pointer); cdecl;

{$endregion}

{$region 'xpath.h'}

type
  xmlXPathObjectType = (
    XPATH_UNDEFINED,
    XPATH_NODESET,
    XPATH_BOOLEAN,
    XPATH_NUMBER,
    XPATH_STRING,
    XPATH_POINT,
    XPATH_RANGE,
    XPATH_LOCATIONSET,
    XPATH_USERS,
    XPATH_XSLT_TREE
  );

  xmlNodeSetPtr = ^xmlNodeSet;
  xmlNodeSet = record
    nodeNr: Integer;          // number of nodes in the set
    nodeMax: Integer;         // size of the array as allocated
    nodeTab: xmlNodeArrayPtr; // array of nodes in no particular order
  end;

  xmlXPathObjectPtr = ^xmlXPathObject;
  xmlXPathObject = record
    &type: xmlXPathObjectType;
    nodesetval: xmlNodeSetPtr;
    boolval: Integer;
    floatval: Double;
    stringval: xmlCharPtr;
    user: Pointer;
    index: Integer;
    user2: Pointer;
    index2: Integer;
  end;

  xmlXPathContextPtr = ^xmlXPathContext;
  xmlXPathContext = record end;

  xmlXPathParserContextPtr = ^xmlXPathParserContext;
  xmlXPathParserContext = record end;

  xmlXPathCompExprPtr = ^xmlXPathCompExpr;
  xmlXPathCompExpr = record end;

  ///<summary>
  /// An XPath function.
  /// The arguments (if any) are popped out from the context stack and the result is pushed on the stack.
  ///</summary>
  ///<param name="ctxt">the XPath interprestation context</param>
  ///<param name="nargs">the number of arguments</param>
  xmlXPathFunction = procedure(ctxt: xmlXPathParserContextPtr; nargs: Integer); cdecl;

  ///<summary>
  /// Prototype for callbacks used to plug variable lookup in the XPath engine.
  ///</summary>
  ///<param name="ctxt">an XPath context </param>
  ///<param name="name">name of the variable </param>
  ///<param name="ns_uri">the namespace name hosting this variable</param>
  ///<results>the XPath function or nil if not found.</results>
  xmlXPathVariableLookupFunc = function(ctxt: Pointer; name, ns_uri: xmlCharPtr): xmlXPathObject; cdecl;

  ///<summary>
  /// the namespace name hosting this variable
  ///</summary>
  ///<param name="ctxt">an XPath context </param>
  ///<param name="name">name of the function </param>
  ///<param name="ns_uri">the namespace name hosting this variable</param>
  ///<results>the XPath function or nil if not found.</results>
  xmlXPathFuncLookupFunc = function(ctxt: Pointer; name, ns_uri: xmlCharPtr): xmlXPathFunction; cdecl;

var
  xmlXPathFreeObject           : procedure(obj: xmlXPathObjectPtr); cdecl;
  xmlXPathNodeSetCreate        : function (val: xmlNodePtr): xmlNodeSetPtr; cdecl;
  xmlXPathFreeNodeSetList      : procedure(obj: xmlXPathObjectPtr); cdecl;
  xmlXPathFreeNodeSet          : procedure(obj: xmlNodeSetPtr); cdecl;
  xmlXPathObjectCopy           : function (val: xmlXPathObjectPtr): xmlXPathObjectPtr; cdecl;
  xmlXPathCmpNodes             : function (node1, node2: xmlNodePtr): Integer; cdecl;
  xmlXPathCastNumberToBoolean  : function(val: Double): Integer; cdecl;
  xmlXPathCastStringToBoolean  : function(val: xmlCharPtr): Integer; cdecl;
  xmlXPathCastNodeSetToBoolean : function(ns: xmlNodeSetPtr): Integer; cdecl;
  xmlXPathCastToBoolean        : function(val: xmlXPathObjectPtr): Integer; cdecl;
  xmlXPathCastBooleanToNumber  : function(val: Integer): Double; cdecl;
  xmlXPathCastStringToNumber   : function(val: xmlCharPtr): Double; cdecl;
  xmlXPathCastNodeToNumber     : function(node: xmlNodePtr): Double; cdecl;
  xmlXPathCastNodeSetToNumber  : function(ns: xmlNodeSetPtr): Double; cdecl;
  xmlXPathCastToNumber         : function(val: xmlXPathObjectPtr): Double; cdecl;
  xmlXPathCastBooleanToString  : function(val: Integer): xmlCharPtr; cdecl;
  xmlXPathCastNumberToString   : function(val: Double): xmlCharPtr; cdecl;
  xmlXPathCastNodeToString     : function(node: xmlNodePtr): xmlCharPtr; cdecl;
  xmlXPathCastNodeSetToString  : function(ns: xmlNodeSetPtr): xmlCharPtr; cdecl;
  xmlXPathCastToString         : function(val: xmlXPathObjectPtr): xmlCharPtr; cdecl;
  xmlXPathConvertBoolean       : function(val: xmlXPathObjectPtr): xmlXPathObjectPtr; cdecl;
  xmlXPathConvertNumber        : function(val: xmlXPathObjectPtr): xmlXPathObjectPtr; cdecl;
  xmlXPathConvertString        : function(val: xmlXPathObjectPtr): xmlXPathObjectPtr; cdecl;
  xmlXPathNewContext           : function (doc: xmlDocPtr): xmlXPathContextPtr; cdecl;
  xmlXPathFreeContext          : procedure(ctxt: xmlXPathContextPtr); cdecl;
  xmlXPathSetErrorHandler      : procedure(ctxt: xmlXPathContextPtr; handler: xmlStructuredErrorFunc; context: Pointer); cdecl;
  xmlXPathContextSetCache      : function (ctxt: xmlXPathContextPtr; active, value, options: Integer): Integer; cdecl;
  xmlXPathOrderDocElems        : function (doc: xmlDocPtr): long; cdecl;
  xmlXPathSetContextNode       : function (node: xmlNodePtr; ctx: xmlXPathContextPtr): Integer; cdecl;
  xmlXPathNodeEval             : function (node: xmlNodePtr; str: xmlCharPtr; ctx: xmlXPathContextPtr): xmlXPathObjectPtr; cdecl;
  xmlXPathEval                 : function (str: xmlCharPtr; ctx: xmlXPathContextPtr): xmlXPathObjectPtr; cdecl;
  xmlXPathEvalExpression       : function (str: xmlCharPtr; ctx: xmlXPathContextPtr): xmlXPathObjectPtr; cdecl;
  xmlXPathEvalPredicate        : function (ctx: xmlXPathContextPtr; res: xmlXPathObjectPtr): Integer; cdecl;
  xmlXPathCompile              : function (str: xmlCharPtr): xmlXPathCompExprPtr; cdecl;
  xmlXPathCtxtCompile          : function (ctx: xmlXPathContextPtr; str: xmlCharPtr): xmlXPathCompExprPtr; cdecl;
  xmlXPathCompiledEval         : function (comp: xmlXPathCompExprPtr; ctx: xmlXPathContextPtr): xmlXPathObjectPtr; cdecl;
  xmlXPathCompiledEvalToBoolean: function (comp: xmlXPathCompExprPtr; ctx: xmlXPathContextPtr): Integer; cdecl;
  xmlXPathFreeCompExpr         : procedure(comp: xmlXPathCompExprPtr); cdecl;
  xmlXPathIsNaN                : function (val: double): Integer; cdecl;
  xmlXPathIsInf                : function (val: double): Integer; cdecl;
  xmlXPathPopBoolean           : function (ctxt: xmlXPathParserContext): Integer; cdecl;
  xmlXPathPopNumber            : function (ctxt: xmlXPathParserContext): Double; cdecl;
  xmlXPathPopString            : function (ctxt: xmlXPathParserContext): xmlCharPtr; cdecl;
  xmlXPathPopNodeSet           : function (ctxt: xmlXPathParserContext): xmlNodeSetPtr; cdecl;
  xmlXPathPopExternal          : function (ctxt: xmlXPathParserContext): Pointer; cdecl;
  xmlXPathRegisterVariableLookup:procedure(ctxt: xmlXPathContextPtr; f: xmlXPathVariableLookupFunc; data: Pointer); cdecl;
  xmlXPathRegisterFuncLookup   : procedure(ctxt: xmlXPathContextPtr; f: xmlXPathFuncLookupFunc; funcCtxt: Pointer); cdecl;
  xmlXPathError                : procedure(ctxt: xmlXPathParserContext; char: xmlCharPtr; line, no: Integer); cdecl;
  xmlXPathErr                  : procedure(ctxt: xmlXPathParserContext; error: Integer); cdecl;
  xmlXPathNodeSetContains      : function (cur: xmlNodeSet; val: xmlNodePtr): Integer; cdecl;
  xmlXPathDifference           : function (nodes1, node2: xmlNodeSetPtr): xmlNodeSetPtr; cdecl;
  xmlXPathIntersection         : function (nodes1, node2: xmlNodeSetPtr): xmlNodeSetPtr; cdecl;
  xmlXPathDistinctSorted       : function (nodes: xmlNodeSet): xmlNodeSetPtr; cdecl;
  xmlXPathDistinct             : function (nodes: xmlNodeSetPtr): xmlNodeSetPtr; cdecl;
  xmlXPathHasSameNodes         : function (nodes1, nodes2: xmlNodeSetPtr): Integer; cdecl;
  xmlXPathNodeLeadingSorted    : function (nodes: xmlNodeSetPtr; node: xmlNodePtr): xmlNodeSetPtr; cdecl;
  xmlXPathLeadingSorted        : function (nodes1, nodes2: xmlNodeSetPtr): xmlNodeSetPtr; cdecl;
  xmlXPathNodeLeading          : function (nodes: xmlNodeSetPtr; node: xmlNodePtr): xmlNodeSetPtr; cdecl;
  xmlXPathLeading              : function (nodes1, nodes2: xmlNodeSetPtr): xmlNodeSetPtr; cdecl;
  xmlXPathNodeTrailingSorted   : function (nodes: xmlNodeSetPtr; node: xmlNodePtr): xmlNodeSetPtr; cdecl;
  xmlXPathTrailingSorted       : function (nodes1, nodes2: xmlNodeSetPtr): xmlNodeSetPtr; cdecl;
  xmlXPathNodeTrailing         : function (nodes: xmlNodeSetPtr; node: xmlNodePtr): xmlNodeSetPtr; cdecl;
  xmlXPathTrailing             : function (nodes1, nodes2: xmlNodeSetPtr): xmlNodeSetPtr; cdecl;
  xmlXPathRegisterNs           : function (ctxt: xmlXPathContextPtr; prefix, ns_uri: xmlCharPtr): Integer; cdecl;
  xmlXPathNsLookup             : function (ctxt: xmlXPathContextPtr; prefix: xmlCharPtr): xmlCharPtr; cdecl;
  xmlXPathRegisteredNsCleanup  : procedure(ctxt: xmlXPathContextPtr); cdecl;
  xmlXPathRegisterFunc         : function (ctxt: xmlXPathContextPtr; name: xmlCharPtr; f: xmlXPathFunction): Integer; cdecl;
  xmlXPathRegisterFuncNS       : function (ctxt: xmlXPathContextPtr; name, ns_uri: xmlCharPtr; f: xmlXPathFunction): Integer; cdecl;
  xmlXPathRegisterVariable     : function (ctxt: xmlXPathContextPtr; name: xmlCharPtr; value: xmlXPathObjectPtr): Integer; cdecl;
  xmlXPathRegisterVariableNS   : function (ctxt: xmlXPathContextPtr; name, ns_uri: xmlCharPtr; value: xmlXPathObjectPtr): Integer; cdecl;
  xmlXPathFunctionLookup       : function (ctxt: xmlXPathContextPtr; name: xmlCharPtr): xmlXPathFunction; cdecl;
  xmlXPathFunctionLookupNS     : function (ctxt: xmlXPathContextPtr; name, ns_uri: xmlCharPtr): xmlXPathFunction; cdecl;
  xmlXPathRegisteredFuncsCleanup:procedure(ctxt: xmlXPathContextPtr); cdecl;
  xmlXPathVariableLookup       : function (ctxt: xmlXPathContextPtr; name: xmlCharPtr): xmlXPathObjectPtr; cdecl;
  xmlXPathVariableLookupNS     : function (ctxt: xmlXPathContextPtr; name, ns_uri: xmlCharPtr): xmlXPathObjectPtr; cdecl;
  xmlXPathRegisteredVariablesCleanup : procedure(ctxt: xmlXPathContextPtr); cdecl;
  xmlXPathNewParserContext     : function (str: xmlCharPtr; ctxt: xmlXPathContextPtr): xmlXPathParserContextPtr; cdecl;
  xmlXPathFreeParserContext    : procedure(ctxt: xmlXPathParserContext); cdecl;
  xmlXPathValuePop             : function (ctxt: xmlXPathParserContext): xmlXPathObjectPtr; cdecl;
  xmlXPathValuePush            : function (ctxt: xmlXPathParserContext; value: xmlXPathObjectPtr): Integer; cdecl;
  xmlXPathNewString            : function  (val: xmlCharPtr): xmlXPathObjectPtr; cdecl;
  xmlXPathNewCString           : function (val: PAnsiChar): xmlXPathObjectPtr; cdecl;
  xmlXPathWrapString           : function (val: PAnsiChar): xmlXPathObjectPtr; cdecl;
  xmlXPathWrapCString          : function (val: PAnsiChar): xmlXPathObjectPtr; cdecl;
  xmlXPathNewFloat             : function (val: Double): xmlXPathObjectPtr; cdecl;
  xmlXPathNewBoolean           : function (val: Integer): xmlXPathObjectPtr; cdecl;
  xmlXPathNewNodeSet           : function (val: xmlNodePtr): xmlXPathObjectPtr; cdecl;
  xmlXPathNewValueTree         : function (val: xmlNodePtr): xmlXPathObjectPtr; cdecl;
  xmlXPathNodeSetAdd           : function (cur: xmlNodeSetPtr; val: xmlNodePtr): Integer; cdecl;
  xmlXPathNodeSetAddUnique     : function (cur: xmlNodeSetPtr; vaL: xmlNodePtr): Integer; cdecl;
  xmlXPathNodeSetAddNs         : function (cur: xmlNodeSetPtr; node: xmlNodePtr; ns: xmlNsPtr): Integer; cdecl;
  xmlXPathNodeSetSort          : procedure(&set: xmlNodeSetPtr); cdecl;
  xmlXPathRoot                 : procedure(ctxt: xmlXPathParserContext); cdecl;
  xmlXPathEvalExpr             : procedure(ctxt: xmlXPathParserContext); cdecl;
  xmlXPathParseName            : function (ctxt: xmlXPathParserContext): xmlCharPtr; cdecl;
  xmlXPathParseNCName          : function (ctxt: xmlXPathParserContext): xmlCharPtr; cdecl;
  xmlXPathStringEvalNumber     : function (str: xmlCharPtr): Double; cdecl;
  xmlXPathEvaluatePredicateResult : function(ctxt: xmlXPathParserContext; res: xmlXPathObjectPtr): Integer; cdecl;
  xmlXPathRegisterAllFunctions : procedure(ctxt: xmlXPathContextPtr); cdecl;
  xmlXPathNodeSetMerge         : function(val1, val2: xmlNodeSetPtr): xmlNodeSetPtr; cdecl;
  xmlXPathNodeSetDel           : procedure(cur: xmlNodeSetPtr; val: xmlNodePtr); cdecl;
  xmlXPathNodeSetRemove        : procedure(cur: xmlNodeSetPtr; val: Integer); cdecl;
  xmlXPathNewNodeSetList       : function(val: xmlNodeSetPtr): xmlXPathObjectPtr; cdecl;
  xmlXPathWrapNodeSet          : function(val: xmlNodeSetPtr): xmlXPathObjectPtr; cdecl;
  xmlXPathWrapExternal         : function(val: Pointer): xmlXPathObjectPtr; cdecl;
  xmlXPathEqualValues          : function(ctxt: xmlXPathParserContext): Integer; cdecl;
  xmlXPathNotEqualValues       : function(ctxt: xmlXPathParserContext): Integer; cdecl;
  xmlXPathCompareValues        : function(ctxt: xmlXPathParserContext; inf, strict: Integer): Integer; cdecl;
  xmlXPathValueFlipSign        : procedure(ctxt: xmlXPathParserContext); cdecl;
  xmlXPathAddValues            : procedure(ctxt: xmlXPathParserContext); cdecl;
  xmlXPathSubValues            : procedure(ctxt: xmlXPathParserContext); cdecl;
  xmlXPathMultValues           : procedure(ctxt: xmlXPathParserContext); cdecl;
  xmlXPathDivValues            : procedure(ctxt: xmlXPathParserContext); cdecl;
  xmlXPathModValues            : procedure(ctxt: xmlXPathParserContext); cdecl;
  xmlXPathIsNodeType           : function(name: xmlCharPtr): Integer; cdecl;
  xmlXPathNextSelf             : function(ctxt: xmlXPathParserContext; cur: xmlNodePtr): xmlNodePtr; cdecl;
  xmlXPathNextChild            : function(ctxt: xmlXPathParserContext; cur: xmlNodePtr): xmlNodePtr; cdecl;
  xmlXPathNextDescendant       : function(ctxt: xmlXPathParserContext; cur: xmlNodePtr): xmlNodePtr; cdecl;
  xmlXPathNextDescendantOrSelf : function(ctxt: xmlXPathParserContext; cur: xmlNodePtr): xmlNodePtr; cdecl;
  xmlXPathNextParent           : function(ctxt: xmlXPathParserContext; cur: xmlNodePtr): xmlNodePtr; cdecl;
  xmlXPathNextAncestorOrSelf   : function(ctxt: xmlXPathParserContext; cur: xmlNodePtr): xmlNodePtr; cdecl;
  xmlXPathNextFollowingSibling : function(ctxt: xmlXPathParserContext; cur: xmlNodePtr): xmlNodePtr; cdecl;
  xmlXPathNextFollowing        : function(ctxt: xmlXPathParserContext; cur: xmlNodePtr): xmlNodePtr; cdecl;
  xmlXPathNextNamespace        : function(ctxt: xmlXPathParserContext; cur: xmlNodePtr): xmlNodePtr; cdecl;
  xmlXPathNextAttribute        : function(ctxt: xmlXPathParserContext; cur: xmlNodePtr): xmlNodePtr; cdecl;
  xmlXPathNextPreceding        : function(ctxt: xmlXPathParserContext; cur: xmlNodePtr): xmlNodePtr; cdecl;
  xmlXPathNextAncestor         : function(ctxt: xmlXPathParserContext; cur: xmlNodePtr): xmlNodePtr; cdecl;
  xmlXPathNextPrecedingSibling : function(ctxt: xmlXPathParserContext; cur: xmlNodePtr): xmlNodePtr; cdecl;
  xmlXPathLastFunction         : procedure(ctxt: xmlXPathParserContext; nargs: Integer); cdecl;
  xmlXPathPositionFunction     : procedure(ctxt: xmlXPathParserContext; nargs: Integer); cdecl;
  xmlXPathCountFunction        : procedure(ctxt: xmlXPathParserContext; nargs: Integer); cdecl;
  xmlXPathIdFunction           : procedure(ctxt: xmlXPathParserContext; nargs: Integer); cdecl;
  xmlXPathLocalNameFunction    : procedure(ctxt: xmlXPathParserContext; nargs: Integer); cdecl;
  xmlXPathNamespaceURIFunction : procedure(ctxt: xmlXPathParserContext; nargs: Integer); cdecl;
  xmlXPathStringFunction       : procedure(ctxt: xmlXPathParserContext; nargs: Integer); cdecl;
  xmlXPathStringLengthFunction : procedure(ctxt: xmlXPathParserContext; nargs: Integer); cdecl;
  xmlXPathConcatFunction       : procedure(ctxt: xmlXPathParserContext; nargs: Integer); cdecl;
  xmlXPathContainsFunction     : procedure(ctxt: xmlXPathParserContext; nargs: Integer); cdecl;
  xmlXPathStartsWithFunction   : procedure(ctxt: xmlXPathParserContext; nargs: Integer); cdecl;
  xmlXPathSubstringFunction    : procedure(ctxt: xmlXPathParserContext; nargs: Integer); cdecl;
  xmlXPathSubstringBeforeFunction:procedure(ctxt: xmlXPathParserContext; nargs: Integer); cdecl;
  xmlXPathSubstringAfterFunction:procedure(ctxt: xmlXPathParserContext; nargs: Integer); cdecl;
  xmlXPathNormalizeFunction    : procedure(ctxt: xmlXPathParserContext; nargs: Integer); cdecl;
  xmlXPathTranslateFunction    : procedure(ctxt: xmlXPathParserContext; nargs: Integer); cdecl;
  xmlXPathNotFunction          : procedure(ctxt: xmlXPathParserContext; nargs: Integer); cdecl;
  xmlXPathTrueFunction         : procedure(ctxt: xmlXPathParserContext; nargs: Integer); cdecl;
  xmlXPathFalseFunction        : procedure(ctxt: xmlXPathParserContext; nargs: Integer); cdecl;
  xmlXPathLangFunction         : procedure(ctxt: xmlXPathParserContext; nargs: Integer); cdecl;
  xmlXPathNumberFunction       : procedure(ctxt: xmlXPathParserContext; nargs: Integer); cdecl;
  xmlXPathSumFunction          : procedure(ctxt: xmlXPathParserContext; nargs: Integer); cdecl;
  xmlXPathFloorFunction        : procedure(ctxt: xmlXPathParserContext; nargs: Integer); cdecl;
  xmlXPathCeilingFunction      : procedure(ctxt: xmlXPathParserContext; nargs: Integer); cdecl;
  xmlXPathRoundFunction        : procedure(ctxt: xmlXPathParserContext; nargs: Integer); cdecl;
  xmlXPathBooleanFunction      : procedure(ctxt: xmlXPathParserContext; nargs: Integer); cdecl;
  xmlXPathNodeSetFreeNs        : procedure(ns: xmlNsPtr); cdecl;

{$endregion}

{$region 'C14N'}

type
  ///<summary>
  /// This is the core C14N function. Signature for a C14N callback on visible nodes
  ///</summary>
  ///<param name = "user_data">user data</param>
  ///<param name = "node">the current node</param>
  ///<param name = "parent">he parent node</param>
  ///<returns>1 if the node should be included</returns>
  xmlC14NIsVisibleCallback = function(user_data: Pointer; node, parent: xmlNodePtr): Integer; cdecl;

  ///<summary>
  /// Predefined values for C14N modes.
  ///</summary>
  xmlC14NMode = (
    ///<summary>Original C14N 1.0 spec.</summary>
    XML_C14N_1_0,
    ///<summary>Exclusive C14N 1.0 spec.</summary>
    XML_C14N_EXCLUSIVE_1_0,
    ///<summary>C14N 1.1 spec.</summary>
    XML_C14N_1_1
  );

var
  ///<summary>
  /// Dumps the canonized image of given XML document into memory.
  /// For details see "Canonical XML" (http://www.w3.org/TR/xml-c14n) or "Exclusive XML Canonicalization" (http://www.w3.org/TR/xml-exc-c14n)
  ///</summary>
  ///<param name = "doc">the XML document for canonization </param>
  ///<param name = "nodes">the nodes set to be included in the canonized image or nil if all document nodes should be included</param>
  ///<param name = "mode">the c14n mode (see <see cref="xmlC14NMode"/>) </param>
  ///<param name = "inclusive_ns_prefixes">the list of inclusive namespace prefixes ended with a nil or nil if there is no inclusive namespaces (only for exclusive canonicalization, ignored otherwise) </param>
  ///<param name = "with_comments">include comments in the result (0) or not (not equal 0) </param>
  ///<param name = "doc_txt_ptr">the memory pointer for allocated canonical XML text; the caller of this functions is responsible for calling xmlFree() to free allocated memory </param>
  ///<returns>the number of bytes written on success or a negative value on fail </returns>
  xmlC14NDocDumpMemory         : function (doc: xmlDocPtr; nodes: xmlNodeSetPtr; mode: xmlC14NMode; inclusive_ns_prefixes: xmlCharPtr; with_comments: Integer; var doc_txt_ptr: xmlCharPtr): Integer; cdecl;

  ///<summary>
  /// Dumps the canonized image of given XML document into the file.
  /// For details see "Canonical XML" (http://www.w3.org/TR/xml-c14n) or "Exclusive XML Canonicalization" (http://www.w3.org/TR/xml-exc-c14n)
  ///</summary>
  ///<param name = "doc">the XML document for canonization </param>
  ///<param name = "nodes">the nodes set to be included in the canonized image or nil if all document nodes should be included</param>
  ///<param name = "mode">the c14n mode (see <see cref="xmlC14NMode"/>) </param>
  ///<param name = "inclusive_ns_prefixes">the list of inclusive namespace prefixes ended with a nil or nil if there is no inclusive namespaces (only for exclusive canonicalization, ignored otherwise) </param>
  ///<param name = "with_comments">include comments in the result (0) or not (not equal 0) </param>
  ///<param name = "filename">the filename to store canonical XML image</param>
  ///<param name = "compression">the compression level: -1 - libxml default, 0 - uncompressed, >0 - compression level</param>
  ///<returns>the number of bytes written on success or a negative value on fail </returns>
  xmlC14NDocSave               : function (doc: xmlDocPtr; nodes: xmlNodeSetPtr; mode: xmlC14NMode; inclusive_ns_prefixes: xmlCharPtr; with_comments: Integer; filename: xmlCharPtr; compression: Integer): Integer; cdecl;

  ///<summary>
  /// Dumps the canonized image of given XML document into the provided buffer.
  /// For details see "Canonical XML" (http://www.w3.org/TR/xml-c14n) or "Exclusive XML Canonicalization" (http://www.w3.org/TR/xml-exc-c14n)
  ///</summary>
  ///<param name = "doc">the XML document for canonization </param>
  ///<param name = "nodes">the nodes set to be included in the canonized image or nil if all document nodes should be included</param>
  ///<param name = "mode">the c14n mode (see <see cref="xmlC14NMode"/>) </param>
  ///<param name = "inclusive_ns_prefixes">the list of inclusive namespace prefixes ended with a nil or nil if there is no inclusive namespaces (only for exclusive canonicalization, ignored otherwise) </param>
  ///<param name = "with_comments">include comments in the result (0) or not (not equal 0) </param>
  ///<param name = "buf">the output buffer to store canonical XML; this buffer MUST have encoder=nil because C14N requires UTF-8 output </param>
  ///<returns>the number of bytes written on success or a negative value on fail </returns>
  xmlC14NDocSaveTo             : function (doc: xmlDocPtr; nodes: xmlNodeSetPtr; mode: xmlC14NMode; inclusive_ns_prefixes: xmlCharPtr; with_comments: Integer; buf: xmlOutputBufferPtr): Integer; cdecl;

{$endregion}

{$region 'xmlschematypes.h'}

type
  xmlSchemaWhitespaceValueType = (
    XML_SCHEMA_WHITESPACE_UNKNOWN = 0,
    XML_SCHEMA_WHITESPACE_PRESERVE = 1,
    XML_SCHEMA_WHITESPACE_REPLACE = 2,
    XML_SCHEMA_WHITESPACE_COLLAPSE = 3
  );

  xmlSchemaValType = (
    XML_SCHEMAS_UNKNOWN = 0,
    XML_SCHEMAS_STRING = 1,
    XML_SCHEMAS_NORMSTRING = 2,
    XML_SCHEMAS_DECIMAL = 3,
    XML_SCHEMAS_TIME = 4,
    XML_SCHEMAS_GDAY = 5,
    XML_SCHEMAS_GMONTH = 6,
    XML_SCHEMAS_GMONTHDAY = 7,
    XML_SCHEMAS_GYEAR = 8,
    XML_SCHEMAS_GYEARMONTH = 9,
    XML_SCHEMAS_DATE = 10,
    XML_SCHEMAS_DATETIME = 11,
    XML_SCHEMAS_DURATION = 12,
    XML_SCHEMAS_FLOAT = 13,
    XML_SCHEMAS_DOUBLE = 14,
    XML_SCHEMAS_BOOLEAN = 15,
    XML_SCHEMAS_TOKEN = 16,
    XML_SCHEMAS_LANGUAGE = 17,
    XML_SCHEMAS_NMTOKEN = 18,
    XML_SCHEMAS_NMTOKENS = 19,
    XML_SCHEMAS_NAME = 20,
    XML_SCHEMAS_QNAME = 21,
    XML_SCHEMAS_NCNAME = 22,
    XML_SCHEMAS_ID = 23,
    XML_SCHEMAS_IDREF = 24,
    XML_SCHEMAS_IDREFS = 25,
    XML_SCHEMAS_ENTITY = 26,
    XML_SCHEMAS_ENTITIES = 27,
    XML_SCHEMAS_NOTATION = 28,
    XML_SCHEMAS_ANYURI = 29,
    XML_SCHEMAS_INTEGER = 30,
    XML_SCHEMAS_NPINTEGER = 31,
    XML_SCHEMAS_NINTEGER = 32,
    XML_SCHEMAS_NNINTEGER = 33,
    XML_SCHEMAS_PINTEGER = 34,
    XML_SCHEMAS_INT = 35,
    XML_SCHEMAS_UINT = 36,
    XML_SCHEMAS_LONG = 37,
    XML_SCHEMAS_ULONG = 38,
    XML_SCHEMAS_SHORT = 39,
    XML_SCHEMAS_USHORT = 40,
    XML_SCHEMAS_BYTE = 41,
    XML_SCHEMAS_UBYTE = 42,
    XML_SCHEMAS_HEXBINARY = 43,
    XML_SCHEMAS_BASE64BINARY = 44,
    XML_SCHEMAS_ANYTYPE = 45,
    XML_SCHEMAS_ANYSIMPLETYPE = 46
  );

  xmlSchemaTypePtr = ^xmlSchemaType;
  xmlSchemaType = record end;

  xmlSchemaValPtr = ^xmlSchemaVal;
  xmlSchemaVal = record end;

  xmlSchemaFacetPtr = ^xmlSchemaFacet;
  xmlSchemaFacet = record end;

var
  xmlSchemaInitTypes           : function: Integer; cdecl;
  xmlSchemaGetPredefinedType   : function (name, ns: xmlCharPtr): xmlSchemaTypePtr; cdecl;
  xmlSchemaValidatePredefinedType:function(&type: xmlSchemaTypePtr; value: xmlCharPtr; var val: xmlSchemaValPtr): Integer; cdecl;
  xmlSchemaValPredefTypeNode   : function (&type: xmlSchemaTypePtr; value: xmlCharPtr; var val: xmlSchemaValPtr; node: xmlNodePtr): Integer; cdecl;
  xmlSchemaValidateFacet       : function (base: xmlSchemaTypePtr; facet: xmlSchemaFacetPtr; value: xmlCharPtr; val: xmlSchemaValPtr): Integer; cdecl;
  xmlSchemaValidateFacetWhtsp  : function (facet: xmlSchemaFacetPtr; fws: xmlSchemaWhitespaceValueType; valType: xmlSchemaValType; value: xmlCharPtr; val: xmlSchemaValPtr; ws: xmlSchemaWhitespaceValueType): Integer; cdecl;
  xmlSchemaFreeValue           : procedure(val: xmlSchemaValPtr); cdecl;
  xmlSchemaNewFacet            : function: xmlSchemaFacetPtr; cdecl;
  xmlSchemaCheckFacet          : function (facet: xmlSchemaFacetPtr; typeDecl: xmlSchemaTypePtr; ctxt: xmlSchemaParserCtxtPtr; name: xmlCharPtr): Integer; cdecl;
  xmlSchemaFreeFacet           : procedure(facet: xmlSchemaFacetPtr); cdecl;
  xmlSchemaCompareValues       : function(x: xmlSchemaValPtr; y: xmlSchemaValPtr): Integer; cdecl;
  xmlSchemaGetBuiltInListSimpleTypeItemType : function(&type: xmlSchemaTypePtr): xmlSchemaTypePtr; cdecl;
  xmlSchemaValidateListSimpleTypeFacet : function(facet: xmlSchemaFacetPtr; value: xmlCharPtr; actualLen: ulong; var expectedLen: ulong): Integer; cdecl;
  xmlSchemaGetBuiltInType      : function (&type: xmlSchemaValType): xmlSchemaTypePtr; cdecl;
  xmlSchemaIsBuiltInTypeFacet  : function (&type: xmlSchemaTypePtr; facetType: Integer): Integer; cdecl;
  xmlSchemaCollapseString      : function (value: xmlCharPtr): xmlCharPtr; cdecl;
  xmlSchemaWhiteSpaceReplace   : function (value: xmlCharPtr): xmlCharPtr; cdecl;
  xmlSchemaGetFacetValueAsULong: function (facet: xmlSchemaFacetPtr): ulong; cdecl;
  xmlSchemaValidateLengthFacet : function (&type: xmlSchemaTypePtr; facet: xmlSchemaFacetPtr; value: xmlCharPtr; val: xmlSchemaValPtr; var length: ulong): Integer; cdecl;
  xmlSchemaValidateLengthFacetWhtsp:function(facet: xmlSchemaFacetPtr; valType: xmlSchemaValType; value: xmlCharPtr; val: xmlSchemaValPtr; var length: ulong; ws: xmlSchemaWhitespaceValueType): Integer; cdecl;
  xmlSchemaValPredefTypeNodeNoNorm:function(&type: xmlSchemaTypePtr; value: xmlCharPtr; var xmlSchemaValPtr; node: xmlNodePtr): Integer; cdecl;
  xmlSchemaGetCanonValue       : function(val: xmlSchemaValPtr; var retValue: xmlCharPtr): Integer; cdecl;
  xmlSchemaGetCanonValueWhtsp  : function(val: xmlSchemaValPtr; var retValue: xmlCharPtr; ws: xmlSchemaWhitespaceValueType): Integer; cdecl;
  xmlSchemaValueAppend         : function(prev: xmlSchemaValPtr; cur: xmlSchemaValPtr): Integer; cdecl;
  xmlSchemaValueGetNext        : function(cur: xmlSchemaValPtr): xmlSchemaValPtr; cdecl;
  xmlSchemaValueGetAsString    : function(val: xmlSchemaValPtr): xmlCharPtr; cdecl;
  xmlSchemaValueGetAsBoolean   : function(val: xmlSchemaValPtr): Integer; cdecl;
  xmlSchemaNewStringValue      : function(&type: xmlSchemaValType; value: xmlCharPtr): xmlSchemaValPtr; cdecl;
  xmlSchemaNewNOTATIONValue    : function(name, ns: xmlCharPtr): xmlSchemaValPtr; cdecl;
  xmlSchemaNewQNameValue       : function(namespaceName, localName: xmlCharPtr): xmlSchemaValPtr; cdecl;
  xmlSchemaCompareValuesWhtsp  : function(x: xmlSchemaValPtr; xws: xmlSchemaWhitespaceValueType; y: xmlSchemaValPtr; yws: xmlSchemaWhitespaceValueType): Integer; cdecl;
  xmlSchemaCopyValue           : function(val: xmlSchemaValPtr): xmlSchemaValPtr; cdecl;
  xmlSchemaGetValType          : function(val: xmlSchemaValPtr): xmlSchemaValType; cdecl;

{$endregion}

{$region 'catalog.h'}

const
  ///<summary>The namespace for the XML Catalogs elements.</summary>
  XML_CATALOGS_NAMESPACE = 'urn:oasis:names:tc:entity:xmlns:xml:catalog';

  ///<summary>The specific XML Catalog Processing Instruction name.</summary>
  XML_CATALOG_PI = 'oasis-xml-catalog';

type
  ///<summary>The API is voluntarily limited to general cataloging.</summary>
  xmlCatalogPrefer = (
    XML_CATA_PREFER_NONE = 0,
    XML_CATA_PREFER_PUBLIC = 1,
    XML_CATA_PREFER_SYSTEM
  );

  xmlCatalogAllow = (
    XML_CATA_ALLOW_NONE = 0,
    XML_CATA_ALLOW_GLOBAL = 1,
    XML_CATA_ALLOW_DOCUMENT = 2,
    XML_CATA_ALLOW_ALL = 3
  );

  xmlCatalogPtr = ^xmlCatalog;
  xmlCatalog = record end;

var
  xmlNewCatalog                : function (sgml: Integer): xmlCatalogPtr; cdecl;
  xmlLoadACatalog              : function(const filename: xmlCharPtr): xmlCatalogPtr; cdecl;
  xmlLoadSGMLSuperCatalog      : function(filename: xmlCharPtr): xmlCatalogPtr; cdecl;
  xmlConvertSGMLCatalog        : function(catal: xmlCatalogPtr): Integer; cdecl;
  xmlACatalogAdd               : function(catal: xmlCatalogPtr; &type, orig, replace: xmlCharPtr): Integer; cdecl;
  xmlACatalogRemove            : function(catal: xmlCatalogPtr; value: xmlCharPtr): Integer; cdecl;
  xmlACatalogResolve           : function(catal: xmlCatalogPtr; pubID, sysID: xmlCharPtr): xmlCharPtr; cdecl;
  xmlACatalogResolveSystem     : function(catal: xmlCatalogPtr; sysID: xmlCharPtr): xmlCharPtr; cdecl;
  xmlACatalogResolvePublic     : function(catal: xmlCatalogPtr; pubID: xmlCharPtr): xmlCharPtr; cdecl;
  xmlACatalogResolveURI        : function(catal: xmlCatalogPtr; URI: xmlCharPtr): xmlCharPtr; cdecl;
  xmlFreeCatalog               : procedure(catal: xmlCatalogPtr); cdecl;
  xmlCatalogIsEmpty            : function(catal: xmlCatalogPtr): Integer; cdecl;
  xmlInitializeCatalog         : procedure; cdecl;
  xmlLoadCatalog               : function(filename: xmlCharPtr): Integer cdecl;
  xmlLoadCatalogs              : procedure(paths: PUTF8Char) cdecl;
  xmlCatalogCleanup            : procedure; cdecl;
  xmlCatalogResolve            : function(pubID, sysID: xmlCharPtr): xmlCharPtr; cdecl;
  xmlCatalogResolveSystem      : function(sysID: xmlCharPtr): xmlCharPtr; cdecl;
  xmlCatalogResolvePublic      : function(pubID: xmlCharPtr): xmlCharPtr; cdecl;
  xmlCatalogResolveURI         : function(URI: xmlCharPtr): xmlCharPtr; cdecl;
  xmlCatalogAdd                : function(&type, orig, replace: xmlCharPtr): Integer; cdecl;
  xmlCatalogRemove             : function(value: xmlCharPtr): Integer; cdecl;
  xmlParseCatalogFile          : function(filename: xmlCharPtr): xmlDocPtr; cdecl;
  xmlCatalogConvert            : function: Integer; cdecl;
  xmlCatalogFreeLocal          : procedure(catalogs: Pointer); cdecl;
  xmlCatalogAddLocal           : function (catalogs: Pointer; URL: xmlCharPtr): Pointer; cdecl;
  xmlCatalogLocalResolve       : function (catalogs: Pointer; pubID: xmlCharPtr; sysID: xmlCharPtr): xmlCharPtr; cdecl;
  xmlCatalogLocalResolveURI    : function(catalogs: Pointer; URI: xmlCharPtr): xmlCharPtr; cdecl;
  xmlCatalogSetDebug           : function (level: Integer): Integer; cdecl;
  xmlCatalogSetDefaults        : procedure(allow: xmlCatalogAllow) cdecl;
  xmlCatalogGetDefaults        : function: xmlCatalogAllow; cdecl;



{$endregion}

{$region 'uri.h'}

type
  xmlURIPtr = ^xmlURI;
  xmlURI = record end;

var
  xmlCreateURI                 : function: xmlURI; cdecl;
  xmlBuildURISafe              : function (URI, base: xmlCharPtr; var &out: xmlCharPtr): Integer; cdecl;
  xmlBuildURI                  : function (URI, base: xmlCharPtr): xmlCharPtr; cdecl;
  xmlBuildRelativeURISafe      : function (URI, base: xmlCharPtr; var &out: xmlCharPtr): Integer; cdecl;
  xmlBuildRelativeURI          : function (URI, base: xmlCharPtr): xmlCharPtr; cdecl;
  xmlParseURI                  : function (str: PUTF8Char): xmlURIPtr; cdecl;
  xmlParseURISafe              : function (str: PUTF8Char; var uri: xmlURIPtr): Integer; cdecl;
  xmlParseURIRaw               : function (str: PUTF8Char; raw: Integer): xmlURIPtr; cdecl;
  xmlParseURIReference         : function (uri: xmlURIPtr; str: PUTF8Char): Integer; cdecl;
  xmlSaveUri                   : function (uri: xmlURIPtr): xmlCharPtr; cdecl;
  xmlURIEscapeStr              : function (str, list: xmlCharPtr): xmlCharPtr; cdecl;
  xmlURIUnescapeString         : function (const str: PUTF8Char; len: Integer; target: PUTF8Char): PUTF8Char; cdecl;
  xmlNormalizeURIPath          : function (path: PUTF8Char): Integer; cdecl;
  xmlURIEscape                 : function (str: xmlCharPtr): xmlCharPtr; cdecl;
  xmlFreeURI                   : procedure(uri: xmlURIPtr); cdecl;
  xmlCanonicPath               : function (path: xmlCharPtr): xmlCharPtr; cdecl;
  xmlPathToURI                 : function (path: xmlCharPtr): xmlCharPtr; cdecl;

{$endregion}

{$region 'relaxng'}

type
  xmlRelaxNGPtr = ^xmlRelaxNG;
  xmlRelaxNG = record end;

  xmlRelaxNGParserCtxtPtr = ^xmlRelaxNGParserCtxt;
  xmlRelaxNGParserCtxt = record end;

  xmlRelaxNGValidCtxtPtr = ^xmlRelaxNGValidCtxt;
  xmlRelaxNGValidCtxt = record end;

{$endregion}

{$region 'xmlreader.h'}

type
  xmlTextReaderPtr = ^xmlTextReader;
  xmlTextReader = record end;

  xmlTextReaderLocatorPtr = Pointer;

  ///<summary>How severe an error callback is when the per-reader error callback API is used.</summary>
  xmlParserSeverities = (
    XML_PARSER_SEVERITY_VALIDITY_WARNING = 1,
    XML_PARSER_SEVERITY_VALIDITY_ERROR = 2,
    XML_PARSER_SEVERITY_WARNING = 3,
    XML_PARSER_SEVERITY_ERROR = 4
  );

  ///<summary>
  /// Some common options to use with xmlTextReaderSetParserProp, but it
  /// is better to use xmlParserOption and the xmlReaderNewxxx and
  /// xmlReaderForxxx APIs now.
  ///</summary>
  xmlParserProperties = (
    XML_PARSER_LOADDTD = 1,
    XML_PARSER_DEFAULTATTRS = 2,
    XML_PARSER_VALIDATE = 3,
    XML_PARSER_SUBST_ENTITIES = 4
  );

 ///<summary>Predefined constants for the different types of nodes.</summary>
  xmlReaderTypes = (
    XML_READER_TYPE_NONE = 0,
    XML_READER_TYPE_ELEMENT = 1,
    XML_READER_TYPE_ATTRIBUTE = 2,
    XML_READER_TYPE_TEXT = 3,
    XML_READER_TYPE_CDATA = 4,
    XML_READER_TYPE_ENTITY_REFERENCE = 5,
    XML_READER_TYPE_ENTITY = 6,
    XML_READER_TYPE_PROCESSING_INSTRUCTION = 7,
    XML_READER_TYPE_COMMENT = 8,
    XML_READER_TYPE_DOCUMENT = 9,
    XML_READER_TYPE_DOCUMENT_TYPE = 10,
    XML_READER_TYPE_DOCUMENT_FRAGMENT = 11,
    XML_READER_TYPE_NOTATION = 12,
    XML_READER_TYPE_WHITESPACE = 13,
    XML_READER_TYPE_SIGNIFICANT_WHITESPACE = 14,
    XML_READER_TYPE_END_ELEMENT = 15,
    XML_READER_TYPE_END_ENTITY = 16,
    XML_READER_TYPE_XML_DECLARATION = 17
  );

  ///<summary>Signature of an error callback from a reader parser</summary>
  ///<param name="arg"> the user argument</param>
  ///<param name="msg"> the message</param>
  ///<param name="severity"> the severity of the error</param>
  ///<param name="locator"> a locator indicating where the error occurred</param>
  xmlTextReaderErrorFunc = procedure (arg: Pointer; msg: PUTF8Char; severity: xmlParserSeverities; locator: xmlTextReaderLocatorPtr); cdecl;

var
  xmlNewTextReader             : function (input: xmlParserInputBufferPtr; URI: xmlCharPtr): xmlTextReaderPtr; cdecl;
  xmlNewTextReaderFilename     : function (URI: xmlCharPtr): xmlTextReaderPtr; cdecl;
  xmlFreeTextReader            : procedure(reader: xmlTextReaderPtr); cdecl;
  xmlTextReaderSetup           : function (reader: xmlTextReaderPtr; input: xmlParserInputBufferPtr; URL, encoding: xmlCharPtr; options: Integer): Integer; cdecl;
  xmlTextReaderSetMaxAmplification:procedure(reader: xmlTextReaderPtr; maxAmpl: Cardinal); cdecl;
  xmlTextReaderGetLastError    : function (reader: xmlTextReaderPtr): xmlErrorPtr; cdecl;
  xmlTextReaderRead            : function (reader: xmlTextReaderPtr): Integer; cdecl;
  xmlTextReaderReadInnerXml    : function (reader: xmlTextReaderPtr): xmlCharPtr; cdecl;
  xmlTextReaderReadOuterXml    : function (reader: xmlTextReaderPtr): xmlCharPtr; cdecl;
  xmlTextReaderReadString      : function (reader: xmlTextReaderPtr): xmlCharPtr; cdecl;
  xmlTextReaderReadAttributeValue:function(reader: xmlTextReaderPtr): Integer; cdecl;
  xmlTextReaderAttributeCount  : function (reader: xmlTextReaderPtr): Integer; cdecl;
  xmlTextReaderDepth           : function (reader: xmlTextReaderPtr): Integer; cdecl;
  xmlTextReaderHasAttributes   : function (reader: xmlTextReaderPtr): Integer; cdecl;
  xmlTextReaderHasValue        : function (reader: xmlTextReaderPtr): Integer; cdecl;
  xmlTextReaderIsDefault       : function (reader: xmlTextReaderPtr): Integer; cdecl;
  xmlTextReaderIsEmptyElement  : function (reader: xmlTextReaderPtr): Integer; cdecl;
  xmlTextReaderNodeType        : function (reader: xmlTextReaderPtr): Integer; cdecl;
  xmlTextReaderQuoteChar       : function (reader: xmlTextReaderPtr): Integer; cdecl;
  xmlTextReaderReadState       : function (reader: xmlTextReaderPtr): Integer; cdecl;
  xmlTextReaderIsNamespaceDecl : function (reader: xmlTextReaderPtr): Integer; cdecl;
  xmlTextReaderConstBaseUri    : function (reader: xmlTextReaderPtr): xmlCharPtr; cdecl;
  xmlTextReaderConstLocalName  : function (reader: xmlTextReaderPtr): xmlCharPtr; cdecl;
  xmlTextReaderConstName       : function (reader: xmlTextReaderPtr): xmlCharPtr; cdecl;
  xmlTextReaderConstNamespaceUri:function (reader: xmlTextReaderPtr): xmlCharPtr; cdecl;
  xmlTextReaderConstPrefix     : function (reader: xmlTextReaderPtr): xmlCharPtr; cdecl;
  xmlTextReaderConstXmlLang    : function (reader: xmlTextReaderPtr): xmlCharPtr; cdecl;
  xmlTextReaderConstString     : function (reader: xmlTextReaderPtr; str: xmlCharPtr): xmlCharPtr; cdecl;
  xmlTextReaderConstValue      : function (reader: xmlTextReaderPtr): xmlCharPtr; cdecl;
  xmlTextReaderBaseUri         : function (reader: xmlTextReaderPtr): xmlCharPtr; cdecl;
  xmlTextReaderLocalName       : function (reader: xmlTextReaderPtr): xmlCharPtr; cdecl;
  xmlTextReaderName            : function (reader: xmlTextReaderPtr): xmlCharPtr; cdecl;
  xmlTextReaderNamespaceUri    : function (reader: xmlTextReaderPtr): xmlCharPtr; cdecl;
  xmlTextReaderPrefix          : function (reader: xmlTextReaderPtr): xmlCharPtr; cdecl;
  xmlTextReaderXmlLang         : function (reader: xmlTextReaderPtr): xmlCharPtr; cdecl;
  xmlTextReaderValue           : function (reader: xmlTextReaderPtr): xmlCharPtr; cdecl;
  xmlTextReaderClose           : function (reader: xmlTextReaderPtr): Integer; cdecl;
  xmlTextReaderGetAttributeNo  : function (reader: xmlTextReaderPtr; no: Integer): xmlCharPtr; cdecl;
  xmlTextReaderGetAttribute    : function (reader: xmlTextReaderPtr; name: xmlCharPtr): xmlCharPtr; cdecl;
  xmlTextReaderGetAttributeNs  : function (reader: xmlTextReaderPtr; localName, namespaceURI: xmlCharPtr): xmlCharPtr; cdecl;
  xmlTextReaderGetRemainder    : function (reader: xmlTextReaderPtr): xmlParserInputBufferPtr; cdecl;
  xmlTextReaderLookupNamespace : function (reader: xmlTextReaderPtr; prefix: xmlCharPtr): xmlCharPtr; cdecl;
  xmlTextReaderMoveToAttributeNo:function (reader: xmlTextReaderPtr; no: Integer): Integer; cdecl;
  xmlTextReaderMoveToAttribute : function (reader: xmlTextReaderPtr; name: xmlCharPtr): Integer; cdecl;
  xmlTextReaderMoveToAttributeNs:function (reader: xmlTextReaderPtr; localName, namespaceURI: xmlCharPtr): Integer; cdecl;
  xmlTextReaderMoveToFirstAttribute: function(reader: xmlTextReaderPtr): Integer; cdecl;
  xmlTextReaderMoveToNextAttribute: function(reader: xmlTextReaderPtr): Integer; cdecl;
  xmlTextReaderMoveToElement   : function (reader: xmlTextReaderPtr): Integer; cdecl;
  xmlTextReaderNormalization   : function (reader: xmlTextReaderPtr): Integer; cdecl;
  xmlTextReaderConstEncoding   : function (reader: xmlTextReaderPtr): xmlCharPtr; cdecl;
  xmlTextReaderSetParserProp   : function (reader: xmlTextReaderPtr; prop, value: Integer): Integer; cdecl;
  xmlTextReaderGetParserProp   : function (reader: xmlTextReaderPtr; prop: Integer): Integer; cdecl;
  xmlTextReaderCurrentNode     : function (reader: xmlTextReaderPtr): xmlNodePtr; cdecl;
  xmlTextReaderGetParserLineNumber: function(reader: xmlTextReaderPtr): Integer; cdecl;
  xmlTextReaderGetParserColumnNumber: function(reader: xmlTextReaderPtr): Integer; cdecl;
  xmlTextReaderPreserve        : function (reader: xmlTextReaderPtr): xmlNodePtr; cdecl;
  xmlTextReaderPreservePattern : function (reader: xmlTextReaderPtr; pattern: xmlCharPtr; var namespaces: xmlCharPtr): Integer; cdecl;
  xmlTextReaderCurrentDoc      : function (reader: xmlTextReaderPtr): xmlNodePtr; cdecl;
  xmlTextReaderExpand          : function (reader: xmlTextReaderPtr): xmlNodePtr; cdecl;
  xmlTextReaderNext            : function (reader: xmlTextReaderPtr): Integer; cdecl;
  xmlTextReaderNextSibling     : function (reader: xmlTextReaderPtr): Integer; cdecl;
  xmlTextReaderIsValid         : function (reader: xmlTextReaderPtr): Integer; cdecl;
  xmlTextReaderRelaxNGValidate : function (reader: xmlTextReaderPtr; rng: xmlCharPtr): Integer; cdecl;
  xmlTextReaderRelaxNGValidateCtxt:function(reader: xmlTextReaderPtr; ctxt: xmlRelaxNGValidCtxtPtr; options: Integer): Integer; cdecl;
  xmlTextReaderRelaxNGSetSchema: function (reader: xmlTextReaderPtr; schema: xmlRelaxNGPtr): Integer; cdecl;
  xmlTextReaderSchemaValidate  : function (reader: xmlTextReaderPtr; xsd: PUTF8Char): Integer; cdecl;
  xmlTextReaderSchemaValidateCtxt:function(reader: xmlTextReaderPtr; ctxt: xmlSchemaValidCtxtPtr; options: Integer): Integer; cdecl;
  xmlTextReaderSetSchema       : function (reader: xmlTextReaderPtr; schema: xmlSchemaPtr): Integer; cdecl;
  xmlTextReaderConstXmlVersion : function (reader: xmlTextReaderPtr): xmlCharPtr; cdecl;
  xmlTextReaderStandalone      : function (reader: xmlTextReaderPtr): Integer; cdecl;
  xmlTextReaderByteConsumed    : function (reader: xmlTextReaderPtr): long; cdecl;

{ New more complete APIs for simpler creation and reuse of readers }

  xmlReaderWalker              : function (doc: xmlDocPtr): xmlTextReaderPtr; cdecl;
  xmlReaderForDoc              : function (cur, URL, encoding: xmlCharPtr; options: Integer): xmlTextReaderPtr; cdecl;
  xmlReaderForFile             : function (filename, encoding: xmlCharPtr; options: Integer): xmlTextReaderPtr; cdecl;
  xmlReaderForMemory           : function (buffer: xmlCharPtr; size: Integer; URL, encoding: Integer; options: Integer): xmlTextReaderPtr; cdecl;
  xmlReaderForFd               : function (fd: Integer; URL, encoding: xmlCharPtr; options: Integer): xmlTextReaderPtr; cdecl;
  xmlReaderForIO               : function (ioread: xmlInputReadCallback; ioclose: xmlInputCloseCallback; ioctx: Pointer; URL, encoding: xmlCharPtr; options: Integer): xmlTextReaderPtr; cdecl;
  xmlReaderNewWalker           : function (reader: xmlTextReaderPtr; doc: xmlDocPtr): Integer; cdecl;
  xmlReaderNewDoc              : function (reader: xmlTextReaderPtr; cur, URL, encoding: xmlCharPtr; options: Integer): Integer; cdecl;
  xmlReaderNewFile             : function (reader: xmlTextReaderPtr; char, encoding: xmlCharPtr; options: Integer): Integer; cdecl;
  xmlReaderNewMemory           : function (reader: xmlTextReaderPtr; char: xmlCharPtr; size: Integer; URL, encoding: xmlCharPtr; options: Integer): Integer; cdecl;
  xmlReaderNewFd               : function (reader: xmlTextReaderPtr; fd: Integer; URL, encoding: xmlCharPtr; options: Integer): Integer; cdecl;
  xmlReaderNewIO               : function (reader: xmlTextReaderPtr; ioread: xmlInputReadCallback; ioclose: xmlInputCloseCallback; ioctx: Pointer; URL, encoding: xmlCharPtr; options: Integer): Integer; cdecl;
  xmlTextReaderLocatorLineNumber:function (locator: xmlTextReaderLocatorPtr): Integer; cdecl;
  xmlTextReaderLocatorBaseURI  : function (locator: xmlTextReaderLocatorPtr): xmlCharPtr; cdecl;
  xmlTextReaderSetErrorHandler : procedure(reader: xmlTextReaderPtr; f: xmlTextReaderErrorFunc; arg: Pointer);cdecl;
  xmlTextReaderSetStructuredErrorHandler: procedure(reader: xmlTextReaderPtr; f: xmlStructuredErrorFunc; arg: Pointer);cdecl;
  xmlTextReaderGetErrorHandler : procedure(reader: xmlTextReaderPtr; var f: xmlTextReaderErrorFunc; var arg: Pointer);cdecl;
  xmlTextReaderSetResourceLoader:procedure(reader: xmlTextReaderPtr; loader: xmlResourceLoader; data: Pointer);cdecl;

{$endregion}

implementation

{$IFDEF MSWINDOWS}

function SafeLoadLibrary(const LibraryFileName: string): THandle;
var
  DllDir: string;
begin
  SetLength(DllDir, MAX_PATH);
  SetLength(DllDir, GetDllDirectory(MAX_PATH, Pointer(DllDir)));
  var LibPath := ExtractFilePath(LibraryFileName);
  if LibPath <> '' then
     SetDllDirectory(PChar(LibPath));
   try
     Result := System.SysUtils.SafeLoadLibrary(LibraryFileName);
   finally
     if LibPath <> '' then
     begin
       if DllDir = '' then
         SetDllDirectory(nil)
       else
         SetDllDirectory(PChar(DllDir));
     end;
   end;
end;

{$ENDIF}

{function GetProcAddress(hModule: THandle; const ProcName: string): Pointer;
begin
  Result := Winapi.Windows.GetProcAddress(hModule, PWideChar(ProcName));
  if not Assigned(Result) then
    WriteLn(ProcName);
end;}

{ LX2Lib }

class procedure LX2Lib.Initialize;
begin
  if Handle = 0 then
    Load;
end;

class procedure LX2Lib.Unload;
begin
  if Handle <> 0 then
  begin
    xmlCleanupParser;
    FreeLibrary(Handle);
    Handle := 0;
  end;
end;

class procedure LX2Lib.Load(const LibraryFileName: string);
begin
  if Handle <> 0 then
    Unload;

  Handle := SafeLoadLibrary(LibraryFileName);

  if Handle = 0 then
    RaiseLastOSError;

{$region 'load procs'}

  xmlACatalogAdd                  := GetProcAddress(Handle, 'xmlACatalogAdd');
  xmlACatalogRemove               := GetProcAddress(Handle, 'xmlACatalogRemove');
  xmlACatalogResolve              := GetProcAddress(Handle, 'xmlACatalogResolve');
  xmlACatalogResolvePublic        := GetProcAddress(Handle, 'xmlACatalogResolvePublic');
  xmlACatalogResolveSystem        := GetProcAddress(Handle, 'xmlACatalogResolveSystem');
  xmlACatalogResolveURI           := GetProcAddress(Handle, 'xmlACatalogResolveURI');
  xmlAddChild                     := GetProcAddress(Handle, 'xmlAddChild');
  xmlAddChildList                 := GetProcAddress(Handle, 'xmlAddChildList');
  xmlAddDocEntity                 := GetProcAddress(Handle, 'xmlAddDocEntity');
  xmlAddDtdEntity                 := GetProcAddress(Handle, 'xmlAddDtdEntity');
  xmlAddEncodingAlias             := GetProcAddress(Handle, 'xmlAddEncodingAlias');
  xmlAddEntity                    := GetProcAddress(Handle, 'xmlAddEntity');
  xmlAddID                        := GetProcAddress(Handle, 'xmlAddID');
  xmlAddIDSafe                    := GetProcAddress(Handle, 'xmlAddIDSafe');
  xmlAddNextSibling               := GetProcAddress(Handle, 'xmlAddNextSibling');
  xmlAddNotationDecl              := GetProcAddress(Handle, 'xmlAddNotationDecl');
  xmlAddPrevSibling               := GetProcAddress(Handle, 'xmlAddPrevSibling');
  xmlAddSibling                   := GetProcAddress(Handle, 'xmlAddSibling');
  xmlAllocOutputBuffer            := GetProcAddress(Handle, 'xmlAllocOutputBuffer');
  xmlAllocParserInputBuffer       := GetProcAddress(Handle, 'xmlAllocParserInputBuffer');
  xmlAttrSerializeTxtContent      := GetProcAddress(Handle, 'xmlAttrSerializeTxtContent');
  xmlBufContent                   := GetProcAddress(Handle, 'xmlBufContent');
  xmlBufEnd                       := GetProcAddress(Handle, 'xmlBufEnd');
  xmlBufferAdd                    := GetProcAddress(Handle, 'xmlBufferAdd');
  xmlBufferAddHead                := GetProcAddress(Handle, 'xmlBufferAddHead');
  xmlBufferCat                    := GetProcAddress(Handle, 'xmlBufferCat');
  xmlBufferCCat                   := GetProcAddress(Handle, 'xmlBufferCCat');
  xmlBufferContent                := GetProcAddress(Handle, 'xmlBufferContent');
  xmlBufferCreate                 := GetProcAddress(Handle, 'xmlBufferCreate');
  xmlBufferCreateSize             := GetProcAddress(Handle, 'xmlBufferCreateSize');
  xmlBufferCreateStatic           := GetProcAddress(Handle, 'xmlBufferCreateStatic');
  xmlBufferDetach                 := GetProcAddress(Handle, 'xmlBufferDetach');
  xmlBufferEmpty                  := GetProcAddress(Handle, 'xmlBufferEmpty');
  xmlBufferFree                   := GetProcAddress(Handle, 'xmlBufferFree');
  xmlBufferLength                 := GetProcAddress(Handle, 'xmlBufferLength');
  xmlBufferWriteQuotedString      := GetProcAddress(Handle, 'xmlBufferWriteQuotedString');
  xmlBufGetNodeContent            := GetProcAddress(Handle, 'xmlBufGetNodeContent');
  xmlBufNodeDump                  := GetProcAddress(Handle, 'xmlBufNodeDump');
  xmlBufUse                       := GetProcAddress(Handle, 'xmlBufUse');
  xmlBuildQName                   := GetProcAddress(Handle, 'xmlBuildQName');
  xmlBuildRelativeURI             := GetProcAddress(Handle, 'xmlBuildRelativeURI');
  xmlBuildRelativeURISafe         := GetProcAddress(Handle, 'xmlBuildRelativeURISafe');
  xmlBuildURI                     := GetProcAddress(Handle, 'xmlBuildURI');
  xmlBuildURISafe                 := GetProcAddress(Handle, 'xmlBuildURISafe');
  xmlC14NDocDumpMemory            := GetProcAddress(Handle, 'xmlC14NDocDumpMemory');
  xmlC14NDocSave                  := GetProcAddress(Handle, 'xmlC14NDocSave');
  xmlC14NDocSaveTo                := GetProcAddress(Handle, 'xmlC14NDocSaveTo');
  xmlCanonicPath                  := GetProcAddress(Handle, 'xmlCanonicPath');
  xmlCatalogAdd                   := GetProcAddress(Handle, 'xmlCatalogAdd');
  xmlCatalogAddLocal              := GetProcAddress(Handle, 'xmlCatalogAddLocal');
  xmlCatalogCleanup               := GetProcAddress(Handle, 'xmlCatalogCleanup');
  xmlCatalogConvert               := GetProcAddress(Handle, 'xmlCatalogConvert');
  xmlCatalogFreeLocal             := GetProcAddress(Handle, 'xmlCatalogFreeLocal');
  xmlCatalogGetDefaults           := GetProcAddress(Handle, 'xmlCatalogGetDefaults');
  xmlCatalogIsEmpty               := GetProcAddress(Handle, 'xmlCatalogIsEmpty');
  xmlCatalogLocalResolve          := GetProcAddress(Handle, 'xmlCatalogLocalResolve');
  xmlCatalogLocalResolveURI       := GetProcAddress(Handle, 'xmlCatalogLocalResolveURI');
  xmlCatalogRemove                := GetProcAddress(Handle, 'xmlCatalogRemove');
  xmlCatalogResolve               := GetProcAddress(Handle, 'xmlCatalogResolve');
  xmlCatalogResolvePublic         := GetProcAddress(Handle, 'xmlCatalogResolvePublic');
  xmlCatalogResolveSystem         := GetProcAddress(Handle, 'xmlCatalogResolveSystem');
  xmlCatalogResolveURI            := GetProcAddress(Handle, 'xmlCatalogResolveURI');
  xmlCatalogSetDebug              := GetProcAddress(Handle, 'xmlCatalogSetDebug');
  xmlCatalogSetDefaults           := GetProcAddress(Handle, 'xmlCatalogSetDefaults');
  xmlCharEncCloseFunc             := GetProcAddress(Handle, 'xmlCharEncCloseFunc');
  xmlCharEncInFunc                := GetProcAddress(Handle, 'xmlCharEncInFunc');
  xmlCharEncNewCustomHandler      := GetProcAddress(Handle, 'xmlCharEncNewCustomHandler');
  xmlCharEncOutFunc               := GetProcAddress(Handle, 'xmlCharEncOutFunc');
  xmlChildElementCount            := GetProcAddress(Handle, 'xmlChildElementCount');
  xmlCleanupEncodingAliases       := GetProcAddress(Handle, 'xmlCleanupEncodingAliases');
  xmlCleanupInputCallbacks        := GetProcAddress(Handle, 'xmlCleanupInputCallbacks');
  xmlCleanupOutputCallbacks       := GetProcAddress(Handle, 'xmlCleanupOutputCallbacks');
  xmlCleanupParser                := GetProcAddress(Handle, 'xmlCleanupParser');
  xmlClearNodeInfoSeq             := GetProcAddress(Handle, 'xmlClearNodeInfoSeq');
  xmlConvertSGMLCatalog           := GetProcAddress(Handle, 'xmlConvertSGMLCatalog');
  xmlCopyDoc                      := GetProcAddress(Handle, 'xmlCopyDoc');
  xmlCopyDtd                      := GetProcAddress(Handle, 'xmlCopyDtd');
  xmlCopyEntitiesTable            := GetProcAddress(Handle, 'xmlCopyEntitiesTable');
  xmlCopyError                    := GetProcAddress(Handle, 'xmlCopyError');
  xmlCopyNamespace                := GetProcAddress(Handle, 'xmlCopyNamespace');
  xmlCopyNamespaceList            := GetProcAddress(Handle, 'xmlCopyNamespaceList');
  xmlCopyProp                     := GetProcAddress(Handle, 'xmlCopyProp');
  xmlCopyPropList                 := GetProcAddress(Handle, 'xmlCopyPropList');
  xmlCreateCharEncodingHandler    := GetProcAddress(Handle, 'xmlCreateCharEncodingHandler');
  xmlCreateDocParserCtxt          := GetProcAddress(Handle, 'xmlCreateDocParserCtxt');
  xmlCreateEntitiesTable          := GetProcAddress(Handle, 'xmlCreateEntitiesTable');
  xmlCreateEntityParserCtxt       := GetProcAddress(Handle, 'xmlCreateEntityParserCtxt');
  xmlCreateFileParserCtxt         := GetProcAddress(Handle, 'xmlCreateFileParserCtxt');
  xmlCreateIntSubset              := GetProcAddress(Handle, 'xmlCreateIntSubset');
  xmlCreateIOParserCtxt           := GetProcAddress(Handle, 'xmlCreateIOParserCtxt');
  xmlCreateMemoryParserCtxt       := GetProcAddress(Handle, 'xmlCreateMemoryParserCtxt');
  xmlCreatePushParserCtxt         := GetProcAddress(Handle, 'xmlCreatePushParserCtxt');
  xmlCreateURI                    := GetProcAddress(Handle, 'xmlCreateURI');
  xmlCreateURLParserCtxt          := GetProcAddress(Handle, 'xmlCreateURLParserCtxt');
  xmlCtxtErrMemory                := GetProcAddress(Handle, 'xmlCtxtErrMemory');
  xmlCtxtGetCatalogs              := GetProcAddress(Handle, 'xmlCtxtGetCatalogs');
  xmlCtxtGetDeclaredEncoding      := GetProcAddress(Handle, 'xmlCtxtGetDeclaredEncoding');
  xmlCtxtGetDict                  := GetProcAddress(Handle, 'xmlCtxtGetDict');
  xmlCtxtGetLastError             := GetProcAddress(Handle, 'xmlCtxtGetLastError');
  xmlCtxtGetOptions               := GetProcAddress(Handle, 'xmlCtxtGetOptions');
  xmlCtxtGetPrivate               := GetProcAddress(Handle, 'xmlCtxtGetPrivate');
  xmlCtxtGetStandalone            := GetProcAddress(Handle, 'xmlCtxtGetStandalone');
  xmlCtxtGetStatus                := GetProcAddress(Handle, 'xmlCtxtGetStatus');
  xmlCtxtGetValidCtxt             := GetProcAddress(Handle, 'xmlCtxtGetValidCtxt');
  xmlCtxtGetVersion               := GetProcAddress(Handle, 'xmlCtxtGetVersion');
  xmlCtxtParseContent             := GetProcAddress(Handle, 'xmlCtxtParseContent');
  xmlCtxtParseDocument            := GetProcAddress(Handle, 'xmlCtxtParseDocument');
  xmlCtxtParseDtd                 := GetProcAddress(Handle, 'xmlCtxtParseDtd');
  xmlCtxtReadDoc                  := GetProcAddress(Handle, 'xmlCtxtReadDoc');
  xmlCtxtReadFd                   := GetProcAddress(Handle, 'xmlCtxtReadFd');
  xmlCtxtReadFile                 := GetProcAddress(Handle, 'xmlCtxtReadFile');
  xmlCtxtReadIO                   := GetProcAddress(Handle, 'xmlCtxtReadIO');
  xmlCtxtReset                    := GetProcAddress(Handle, 'xmlCtxtReset');
  xmlCtxtResetLastError           := GetProcAddress(Handle, 'xmlCtxtResetLastError');
  xmlCtxtResetPush                := GetProcAddress(Handle, 'xmlCtxtResetPush');
  xmlCtxtSetCatalogs              := GetProcAddress(Handle, 'xmlCtxtSetCatalogs');
  xmlCtxtSetCharEncConvImpl       := GetProcAddress(Handle, 'xmlCtxtSetCharEncConvImpl');
  xmlCtxtSetDict                  := GetProcAddress(Handle, 'xmlCtxtSetDict');
  xmlCtxtSetErrorHandler          := GetProcAddress(Handle, 'xmlCtxtSetErrorHandler');
  xmlCtxtSetMaxAmplification      := GetProcAddress(Handle, 'xmlCtxtSetMaxAmplification');
  xmlCtxtSetOptions               := GetProcAddress(Handle, 'xmlCtxtSetOptions');
  xmlCtxtSetPrivate               := GetProcAddress(Handle, 'xmlCtxtSetPrivate');
  xmlCtxtSetResourceLoader        := GetProcAddress(Handle, 'xmlCtxtSetResourceLoader');
  xmlCtxtUseOptions               := GetProcAddress(Handle, 'xmlCtxtUseOptions');
  xmlCtxtValidateDocument         := GetProcAddress(Handle, 'xmlCtxtValidateDocument');
  xmlCtxtValidateDtd              := GetProcAddress(Handle, 'xmlCtxtValidateDtd');
  xmlDelEncodingAlias             := GetProcAddress(Handle, 'xmlDelEncodingAlias');
  xmlDeregisterNodeDefault        := GetProcAddress(Handle, 'xmlDeregisterNodeDefault');
  xmlDetectCharEncoding           := GetProcAddress(Handle, 'xmlDetectCharEncoding');
  xmlDictCreate                   := GetProcAddress(Handle, 'xmlDictCreate');
  xmlDictCreateSub                := GetProcAddress(Handle, 'xmlDictCreateSub');
  xmlDictExists                   := GetProcAddress(Handle, 'xmlDictExists');
  xmlDictFree                     := GetProcAddress(Handle, 'xmlDictFree');
  xmlDictGetUsage                 := GetProcAddress(Handle, 'xmlDictGetUsage');
  xmlDictLookup                   := GetProcAddress(Handle, 'xmlDictLookup');
  xmlDictOwns                     := GetProcAddress(Handle, 'xmlDictOwns');
  xmlDictQLookup                  := GetProcAddress(Handle, 'xmlDictQLookup');
  xmlDictReference                := GetProcAddress(Handle, 'xmlDictReference');
  xmlDictSetLimit                 := GetProcAddress(Handle, 'xmlDictSetLimit');
  xmlDictSize                     := GetProcAddress(Handle, 'xmlDictSize');
  xmlDocCopyNode                  := GetProcAddress(Handle, 'xmlDocCopyNode');
  xmlDocCopyNodeList              := GetProcAddress(Handle, 'xmlDocCopyNodeList');
  xmlDocDumpFormatMemory          := GetProcAddress(Handle, 'xmlDocDumpFormatMemory');
  xmlDocDumpFormatMemoryEnc       := GetProcAddress(Handle, 'xmlDocDumpFormatMemoryEnc');
  xmlDocDumpMemory                := GetProcAddress(Handle, 'xmlDocDumpMemory');
  xmlDocDumpMemoryEnc             := GetProcAddress(Handle, 'xmlDocDumpMemoryEnc');
  xmlDocGetRootElement            := GetProcAddress(Handle, 'xmlDocGetRootElement');
  xmlDocSetRootElement            := GetProcAddress(Handle, 'xmlDocSetRootElement');
  xmlDOMWrapAdoptNode             := GetProcAddress(Handle, 'xmlDOMWrapAdoptNode');
  xmlDOMWrapCloneNode             := GetProcAddress(Handle, 'xmlDOMWrapCloneNode');
  xmlDOMWrapFreeCtxt              := GetProcAddress(Handle, 'xmlDOMWrapFreeCtxt');
  xmlDOMWrapNewCtxt               := GetProcAddress(Handle, 'xmlDOMWrapNewCtxt');
  xmlDOMWrapReconcileNamespaces   := GetProcAddress(Handle, 'xmlDOMWrapReconcileNamespaces');
  xmlDOMWrapRemoveNode            := GetProcAddress(Handle, 'xmlDOMWrapRemoveNode');
  xmlDumpEntitiesTable            := GetProcAddress(Handle, 'xmlDumpEntitiesTable');
  xmlDumpEntityDecl               := GetProcAddress(Handle, 'xmlDumpEntityDecl');
  xmlEncodeEntitiesReentrant      := GetProcAddress(Handle, 'xmlEncodeEntitiesReentrant');
  xmlEncodeSpecialChars           := GetProcAddress(Handle, 'xmlEncodeSpecialChars');
  xmlFindCharEncodingHandler      := GetProcAddress(Handle, 'xmlFindCharEncodingHandler');
  xmlFirstElementChild            := GetProcAddress(Handle, 'xmlFirstElementChild');
  xmlFreeCatalog                  := GetProcAddress(Handle, 'xmlFreeCatalog');
  xmlFreeDoc                      := GetProcAddress(Handle, 'xmlFreeDoc');
  xmlFreeDtd                      := GetProcAddress(Handle, 'xmlFreeDtd');
  xmlFreeEntitiesTable            := GetProcAddress(Handle, 'xmlFreeEntitiesTable');
  xmlFreeEntity                   := GetProcAddress(Handle, 'xmlFreeEntity');
  xmlFreeEnumeration              := GetProcAddress(Handle, 'xmlFreeEnumeration');
  xmlFreeIDTable                  := GetProcAddress(Handle, 'xmlFreeIDTable');
  xmlFreeInputStream              := GetProcAddress(Handle, 'xmlFreeInputStream');
  xmlFreeNode                     := GetProcAddress(Handle, 'xmlFreeNode');
  xmlFreeNodeList                 := GetProcAddress(Handle, 'xmlFreeNodeList');
  xmlFreeNs                       := GetProcAddress(Handle, 'xmlFreeNs');
  xmlFreeNsList                   := GetProcAddress(Handle, 'xmlFreeNsList');
  xmlFreeParserCtxt               := GetProcAddress(Handle, 'xmlFreeParserCtxt');
  xmlFreeParserInputBuffer        := GetProcAddress(Handle, 'xmlFreeParserInputBuffer');
  xmlFreeProp                     := GetProcAddress(Handle, 'xmlFreeProp');
  xmlFreePropList                 := GetProcAddress(Handle, 'xmlFreePropList');
  xmlFreeTextReader               := GetProcAddress(Handle, 'xmlFreeTextReader');
  xmlFreeURI                      := GetProcAddress(Handle, 'xmlFreeURI');
  xmlFreeValidCtxt                := GetProcAddress(Handle, 'xmlFreeValidCtxt');
  xmlGetCharEncodingHandler       := GetProcAddress(Handle, 'xmlGetCharEncodingHandler');
  xmlGetCharEncodingName          := GetProcAddress(Handle, 'xmlGetCharEncodingName');
  xmlGetDocCompressMode           := GetProcAddress(Handle, 'xmlGetDocCompressMode');
  xmlGetDocEntity                 := GetProcAddress(Handle, 'xmlGetDocEntity');
  xmlGetDtdAttrDesc               := GetProcAddress(Handle, 'xmlGetDtdAttrDesc');
  xmlGetDtdElementDesc            := GetProcAddress(Handle, 'xmlGetDtdElementDesc');
  xmlGetDtdEntity                 := GetProcAddress(Handle, 'xmlGetDtdEntity');
  xmlGetDtdNotationDesc           := GetProcAddress(Handle, 'xmlGetDtdNotationDesc');
  xmlGetDtdQAttrDesc              := GetProcAddress(Handle, 'xmlGetDtdQAttrDesc');
  xmlGetDtdQElementDesc           := GetProcAddress(Handle, 'xmlGetDtdQElementDesc');
  xmlGetEncodingAlias             := GetProcAddress(Handle, 'xmlGetEncodingAlias');
  xmlGetExternalEntityLoader      := GetProcAddress(Handle, 'xmlGetExternalEntityLoader');
  xmlGetID                        := GetProcAddress(Handle, 'xmlGetID');
  xmlGetIntSubset                 := GetProcAddress(Handle, 'xmlGetIntSubset');
  xmlGetLastChild                 := GetProcAddress(Handle, 'xmlGetLastChild');
  xmlGetLastError                 := GetProcAddress(Handle, 'xmlGetLastError');
  xmlGetLineNo                    := GetProcAddress(Handle, 'xmlGetLineNo');
  xmlGetNodePath                  := GetProcAddress(Handle, 'xmlGetNodePath');
  xmlGetNsList                    := GetProcAddress(Handle, 'xmlGetNsList');
  xmlGetNsListSafe                := GetProcAddress(Handle, 'xmlGetNsListSafe');
  xmlGetNsProp                    := GetProcAddress(Handle, 'xmlGetNsProp');
  xmlGetParameterEntity           := GetProcAddress(Handle, 'xmlGetParameterEntity');
  xmlGetPredefinedEntity          := GetProcAddress(Handle, 'xmlGetPredefinedEntity');
  xmlGetProp                      := GetProcAddress(Handle, 'xmlGetProp');
  xmlHasNsProp                    := GetProcAddress(Handle, 'xmlHasNsProp');
  xmlHasProp                      := GetProcAddress(Handle, 'xmlHasProp');
  xmlInitializeCatalog            := GetProcAddress(Handle, 'xmlInitializeCatalog');
  xmlInitNodeInfoSeq              := GetProcAddress(Handle, 'xmlInitNodeInfoSeq');
  xmlInputSetEncodingHandler      := GetProcAddress(Handle, 'xmlInputSetEncodingHandler');
  xmlIOParseDTD                   := GetProcAddress(Handle, 'xmlIOParseDTD');
  xmlIsBlankNode                  := GetProcAddress(Handle, 'xmlIsBlankNode');
  xmlIsID                         := GetProcAddress(Handle, 'xmlIsID');
  xmlIsMixedElement               := GetProcAddress(Handle, 'xmlIsMixedElement');
  xmlIsolat1ToUTF8                := GetProcAddress(Handle, 'xmlIsolat1ToUTF8');
  xmlIsXHTML                      := GetProcAddress(Handle, 'xmlIsXHTML');
  xmlLastElementChild             := GetProcAddress(Handle, 'xmlLastElementChild');
  xmlLoadACatalog                 := GetProcAddress(Handle, 'xmlLoadACatalog');
  xmlLoadCatalog                  := GetProcAddress(Handle, 'xmlLoadCatalog');
  xmlLoadCatalogs                 := GetProcAddress(Handle, 'xmlLoadCatalogs');
  xmlLoadExternalEntity           := GetProcAddress(Handle, 'xmlLoadExternalEntity');
  xmlLoadSGMLSuperCatalog         := GetProcAddress(Handle, 'xmlLoadSGMLSuperCatalog');
  xmlLookupCharEncodingHandler    := GetProcAddress(Handle, 'xmlLookupCharEncodingHandler');
  xmlMemFree                      := GetProcAddress(Handle, 'xmlMemFree');
  xmlMemGet                       := GetProcAddress(Handle, 'xmlMemGet');
  xmlMemMalloc                    := GetProcAddress(Handle, 'xmlMemMalloc');
  xmlMemoryStrdup                 := GetProcAddress(Handle, 'xmlMemoryStrdup');
  xmlMemRealloc                   := GetProcAddress(Handle, 'xmlMemRealloc');
  xmlMemSetup                     := GetProcAddress(Handle, 'xmlMemSetup');
  xmlMemUsed                      := GetProcAddress(Handle, 'xmlMemUsed');
  xmlNewCatalog                   := GetProcAddress(Handle, 'xmlNewCatalog');
  xmlNewCDataBlock                := GetProcAddress(Handle, 'xmlNewCDataBlock');
  xmlNewCharEncodingHandler       := GetProcAddress(Handle, 'xmlNewCharEncodingHandler');
  xmlNewCharRef                   := GetProcAddress(Handle, 'xmlNewCharRef');
  xmlNewChild                     := GetProcAddress(Handle, 'xmlNewChild');
  xmlNewDoc                       := GetProcAddress(Handle, 'xmlNewDoc');
  xmlNewDocComment                := GetProcAddress(Handle, 'xmlNewDocComment');
  xmlNewDocFragment               := GetProcAddress(Handle, 'xmlNewDocFragment');
  xmlNewDocNode                   := GetProcAddress(Handle, 'xmlNewDocNode');
  xmlNewDocNodeEatName            := GetProcAddress(Handle, 'xmlNewDocNodeEatName');
  xmlNewDocPI                     := GetProcAddress(Handle, 'xmlNewDocPI');
  xmlNewDocProp                   := GetProcAddress(Handle, 'xmlNewDocProp');
  xmlNewDocRawNode                := GetProcAddress(Handle, 'xmlNewDocRawNode');
  xmlNewDocText                   := GetProcAddress(Handle, 'xmlNewDocText');
  xmlNewDocTextLen                := GetProcAddress(Handle, 'xmlNewDocTextLen');
  xmlNewDtd                       := GetProcAddress(Handle, 'xmlNewDtd');
  xmlNewEntity                    := GetProcAddress(Handle, 'xmlNewEntity');
  xmlNewInputFromFd               := GetProcAddress(Handle, 'xmlNewInputFromFd');
  xmlNewInputFromFile             := GetProcAddress(Handle, 'xmlNewInputFromFile');
  xmlNewInputFromIO               := GetProcAddress(Handle, 'xmlNewInputFromIO');
  xmlNewInputFromMemory           := GetProcAddress(Handle, 'xmlNewInputFromMemory');
  xmlNewInputFromString           := GetProcAddress(Handle, 'xmlNewInputFromString');
  xmlNewInputFromUrl              := GetProcAddress(Handle, 'xmlNewInputFromUrl');
  xmlNewInputStream               := GetProcAddress(Handle, 'xmlNewInputStream');
  xmlNewIOInputStream             := GetProcAddress(Handle, 'xmlNewIOInputStream');
  xmlNewNs                        := GetProcAddress(Handle, 'xmlNewNs');
  xmlNewNsProp                    := GetProcAddress(Handle, 'xmlNewNsProp');
  xmlNewNsPropEatName             := GetProcAddress(Handle, 'xmlNewNsPropEatName');
  xmlNewParserCtxt                := GetProcAddress(Handle, 'xmlNewParserCtxt');
  xmlNewProp                      := GetProcAddress(Handle, 'xmlNewProp');
  xmlNewReference                 := GetProcAddress(Handle, 'xmlNewReference');
  xmlNewSAXParserCtxt             := GetProcAddress(Handle, 'xmlNewSAXParserCtxt');
  xmlNewStringInputStream         := GetProcAddress(Handle, 'xmlNewStringInputStream');
  xmlNewTextChild                 := GetProcAddress(Handle, 'xmlNewTextChild');
  xmlNewTextReader                := GetProcAddress(Handle, 'xmlNewTextReader');
  xmlNewTextReaderFilename        := GetProcAddress(Handle, 'xmlNewTextReaderFilename');
  xmlNewValidCtxt                 := GetProcAddress(Handle, 'xmlNewValidCtxt');
  xmlNextElementSibling           := GetProcAddress(Handle, 'xmlNextElementSibling');
  xmlNodeAddContent               := GetProcAddress(Handle, 'xmlNodeAddContent');
  xmlNodeAddContentLen            := GetProcAddress(Handle, 'xmlNodeAddContentLen');
  xmlNodeDump                     := GetProcAddress(Handle, 'xmlNodeDump');
  xmlNodeDumpOutput               := GetProcAddress(Handle, 'xmlNodeDumpOutput');
  xmlNodeGetAttrValue             := GetProcAddress(Handle, 'xmlNodeGetAttrValue');
  xmlNodeGetBase                  := GetProcAddress(Handle, 'xmlNodeGetBase');
  xmlNodeGetBaseSafe              := GetProcAddress(Handle, 'xmlNodeGetBaseSafe');
  xmlNodeGetContent               := GetProcAddress(Handle, 'xmlNodeGetContent');
  xmlNodeGetLang                  := GetProcAddress(Handle, 'xmlNodeGetLang');
  xmlNodeGetSpacePreserve         := GetProcAddress(Handle, 'xmlNodeGetSpacePreserve');
  xmlNodeIsText                   := GetProcAddress(Handle, 'xmlNodeIsText');
  xmlNodeListGetRawString         := GetProcAddress(Handle, 'xmlNodeListGetRawString');
  xmlNodeListGetString            := GetProcAddress(Handle, 'xmlNodeListGetString');
  xmlNodeSetBase                  := GetProcAddress(Handle, 'xmlNodeSetBase');
  xmlNodeSetContent               := GetProcAddress(Handle, 'xmlNodeSetContent');
  xmlNodeSetContentLen            := GetProcAddress(Handle, 'xmlNodeSetContentLen');
  xmlNodeSetLang                  := GetProcAddress(Handle, 'xmlNodeSetLang');
  xmlNodeSetName                  := GetProcAddress(Handle, 'xmlNodeSetName');
  xmlNodeSetSpacePreserve         := GetProcAddress(Handle, 'xmlNodeSetSpacePreserve');
  xmlNoNetExternalEntityLoader    := GetProcAddress(Handle, 'xmlNoNetExternalEntityLoader');
  xmlNormalizeURIPath             := GetProcAddress(Handle, 'xmlNormalizeURIPath');
  xmlOpenCharEncodingHandler      := GetProcAddress(Handle, 'xmlOpenCharEncodingHandler');
  xmlOutputBufferClose            := GetProcAddress(Handle, 'xmlOutputBufferClose');
  xmlOutputBufferCreateBuffer     := GetProcAddress(Handle, 'xmlOutputBufferCreateBuffer');
  xmlOutputBufferCreateFd         := GetProcAddress(Handle, 'xmlOutputBufferCreateFd');
  xmlOutputBufferCreateFilename   := GetProcAddress(Handle, 'xmlOutputBufferCreateFilename');
  xmlOutputBufferCreateFilenameDefault := GetProcAddress(Handle, 'xmlOutputBufferCreateFilenameDefault');
  xmlOutputBufferCreateIO         := GetProcAddress(Handle, 'xmlOutputBufferCreateIO');
  xmlOutputBufferFlush            := GetProcAddress(Handle, 'xmlOutputBufferFlush');
  xmlOutputBufferGetContent       := GetProcAddress(Handle, 'xmlOutputBufferGetContent');
  xmlOutputBufferGetSize          := GetProcAddress(Handle, 'xmlOutputBufferGetSize');
  xmlOutputBufferWrite            := GetProcAddress(Handle, 'xmlOutputBufferWrite');
  xmlOutputBufferWriteEscape      := GetProcAddress(Handle, 'xmlOutputBufferWriteEscape');
  xmlOutputBufferWriteString      := GetProcAddress(Handle, 'xmlOutputBufferWriteString');
  xmlParseBalancedChunkMemory     := GetProcAddress(Handle, 'xmlParseBalancedChunkMemory');
  xmlParseBalancedChunkMemoryRecover := GetProcAddress(Handle, 'xmlParseBalancedChunkMemoryRecover');
  xmlParseCatalogFile             := GetProcAddress(Handle, 'xmlParseCatalogFile');
  xmlParseCharEncoding            := GetProcAddress(Handle, 'xmlParseCharEncoding');
  xmlParseChunk                   := GetProcAddress(Handle, 'xmlParseChunk');
  xmlParseCtxtExternalEntity      := GetProcAddress(Handle, 'xmlParseCtxtExternalEntity');
  xmlParseDoc                     := GetProcAddress(Handle, 'xmlParseDoc');
  xmlParseDocument                := GetProcAddress(Handle, 'xmlParseDocument');
  xmlParseDTD                     := GetProcAddress(Handle, 'xmlParseDTD');
  xmlParseExtParsedEnt            := GetProcAddress(Handle, 'xmlParseExtParsedEnt');
  xmlParseFile                    := GetProcAddress(Handle, 'xmlParseFile');
  xmlParseInNodeContext           := GetProcAddress(Handle, 'xmlParseInNodeContext');
  xmlParseMemory                  := GetProcAddress(Handle, 'xmlParseMemory');
  xmlParserAddNodeInfo            := GetProcAddress(Handle, 'xmlParserAddNodeInfo');
  xmlParserFindNodeInfo           := GetProcAddress(Handle, 'xmlParserFindNodeInfo');
  xmlParserFindNodeInfoIndex      := GetProcAddress(Handle, 'xmlParserFindNodeInfoIndex');
  xmlParserGetDirectory           := GetProcAddress(Handle, 'xmlParserGetDirectory');
  xmlParserInputBufferCreateFd    := GetProcAddress(Handle, 'xmlParserInputBufferCreateFd');
  xmlParserInputBufferCreateFilename := GetProcAddress(Handle, 'xmlParserInputBufferCreateFilename');
  xmlParserInputBufferCreateIO    := GetProcAddress(Handle, 'xmlParserInputBufferCreateIO');
  xmlParserInputBufferCreateMem   := GetProcAddress(Handle, 'xmlParserInputBufferCreateMem');
  xmlParserInputBufferCreateStatic:= GetProcAddress(Handle, 'xmlParserInputBufferCreateStatic');
  xmlParserInputGrow              := GetProcAddress(Handle, 'xmlParserInputGrow');
  xmlParseURI                     := GetProcAddress(Handle, 'xmlParseURI');
  xmlParseURIRaw                  := GetProcAddress(Handle, 'xmlParseURIRaw');
  xmlParseURIReference            := GetProcAddress(Handle, 'xmlParseURIReference');
  xmlParseURISafe                 := GetProcAddress(Handle, 'xmlParseURISafe');
  xmlPathToURI                    := GetProcAddress(Handle, 'xmlPathToURI');
  xmlPopInputCallbacks            := GetProcAddress(Handle, 'xmlPopInputCallbacks');
  xmlPopOutputCallbacks           := GetProcAddress(Handle, 'xmlPopOutputCallbacks');
  xmlPreviousElementSibling       := GetProcAddress(Handle, 'xmlPreviousElementSibling');
  xmlReadDoc                      := GetProcAddress(Handle, 'xmlReadDoc');
  xmlReaderForDoc                 := GetProcAddress(Handle, 'xmlReaderForDoc');
  xmlReaderForFd                  := GetProcAddress(Handle, 'xmlReaderForFd');
  xmlReaderForFile                := GetProcAddress(Handle, 'xmlReaderForFile');
  xmlReaderForIO                  := GetProcAddress(Handle, 'xmlReaderForIO');
  xmlReaderForMemory              := GetProcAddress(Handle, 'xmlReaderForMemory');
  xmlReaderNewDoc                 := GetProcAddress(Handle, 'xmlReaderNewDoc');
  xmlReaderNewFd                  := GetProcAddress(Handle, 'xmlReaderNewFd');
  xmlReaderNewFile                := GetProcAddress(Handle, 'xmlReaderNewFile');
  xmlReaderNewIO                  := GetProcAddress(Handle, 'xmlReaderNewIO');
  xmlReaderNewMemory              := GetProcAddress(Handle, 'xmlReaderNewMemory');
  xmlReaderNewWalker              := GetProcAddress(Handle, 'xmlReaderNewWalker');
  xmlReaderWalker                 := GetProcAddress(Handle, 'xmlReaderWalker');
  xmlReadFd                       := GetProcAddress(Handle, 'xmlReadFd');
  xmlReadFile                     := GetProcAddress(Handle, 'xmlReadFile');
  xmlReadIO                       := GetProcAddress(Handle, 'xmlReadIO');
  xmlReadMemory                   := GetProcAddress(Handle, 'xmlReadMemory');
  xmlReconciliateNs               := GetProcAddress(Handle, 'xmlReconciliateNs');
  xmlRegisterDefaultInputCallbacks:= GetProcAddress(Handle, 'xmlRegisterDefaultInputCallbacks');
  xmlRegisterDefaultOutputCallbacks := GetProcAddress(Handle, 'xmlRegisterDefaultOutputCallbacks');
  xmlRegisterInputCallbacks       := GetProcAddress(Handle, 'xmlRegisterInputCallbacks');
  xmlRegisterOutputCallbacks      := GetProcAddress(Handle, 'xmlRegisterOutputCallbacks');
  xmlRemoveID                     := GetProcAddress(Handle, 'xmlRemoveID');
  xmlRemoveProp                   := GetProcAddress(Handle, 'xmlRemoveProp');
  xmlReplaceNode                  := GetProcAddress(Handle, 'xmlReplaceNode');
  xmlResetError                   := GetProcAddress(Handle, 'xmlResetError');
  xmlResetLastError               := GetProcAddress(Handle, 'xmlResetLastError');
  xmlSaveClose                    := GetProcAddress(Handle, 'xmlSaveClose');
  xmlSaveDoc                      := GetProcAddress(Handle, 'xmlSaveDoc');
  xmlSaveFile                     := GetProcAddress(Handle, 'xmlSaveFile');
  xmlSaveFileEnc                  := GetProcAddress(Handle, 'xmlSaveFileEnc');
  xmlSaveFinish                   := GetProcAddress(Handle, 'xmlSaveFinish');
  xmlSaveFlush                    := GetProcAddress(Handle, 'xmlSaveFlush');
  xmlSaveFormatFile               := GetProcAddress(Handle, 'xmlSaveFormatFile');
  xmlSaveFormatFileEnc            := GetProcAddress(Handle, 'xmlSaveFormatFileEnc');
  xmlSaveToBuffer                 := GetProcAddress(Handle, 'xmlSaveToBuffer');
  xmlSaveToFd                     := GetProcAddress(Handle, 'xmlSaveToFd');
  xmlSaveToFilename               := GetProcAddress(Handle, 'xmlSaveToFilename');
  xmlSaveToIO                     := GetProcAddress(Handle, 'xmlSaveToIO');
  xmlSaveTree                     := GetProcAddress(Handle, 'xmlSaveTree');
  xmlSaveUri                      := GetProcAddress(Handle, 'xmlSaveUri');
  xmlSAX2AttributeDecl            := GetProcAddress(Handle, 'xmlSAX2AttributeDecl');
  xmlSAX2CDataBlock               := GetProcAddress(Handle, 'xmlSAX2CDataBlock');
  xmlSAX2Characters               := GetProcAddress(Handle, 'xmlSAX2Characters');
  xmlSAX2Comment                  := GetProcAddress(Handle, 'xmlSAX2Comment');
  xmlSAX2ElementDecl              := GetProcAddress(Handle, 'xmlSAX2ElementDecl');
  xmlSAX2EndDocument              := GetProcAddress(Handle, 'xmlSAX2EndDocument');
  xmlSAX2EndElementNs             := GetProcAddress(Handle, 'xmlSAX2EndElementNs');
  xmlSAX2EntityDecl               := GetProcAddress(Handle, 'xmlSAX2EntityDecl');
  xmlSAX2ExternalSubset           := GetProcAddress(Handle, 'xmlSAX2ExternalSubset');
  xmlSAX2GetColumnNumber          := GetProcAddress(Handle, 'xmlSAX2GetColumnNumber');
  xmlSAX2GetEntity                := GetProcAddress(Handle, 'xmlSAX2GetEntity');
  xmlSAX2GetLineNumber            := GetProcAddress(Handle, 'xmlSAX2GetLineNumber');
  xmlSAX2GetParameterEntity       := GetProcAddress(Handle, 'xmlSAX2GetParameterEntity');
  xmlSAX2GetPublicId              := GetProcAddress(Handle, 'xmlSAX2GetPublicId');
  xmlSAX2GetSystemId              := GetProcAddress(Handle, 'xmlSAX2GetSystemId');
  xmlSAX2HasExternalSubset        := GetProcAddress(Handle, 'xmlSAX2HasExternalSubset');
  xmlSAX2HasInternalSubset        := GetProcAddress(Handle, 'xmlSAX2HasInternalSubset');
  xmlSAX2IgnorableWhitespace      := GetProcAddress(Handle, 'xmlSAX2IgnorableWhitespace');
  xmlSAX2InitDefaultSAXHandler    := GetProcAddress(Handle, 'xmlSAX2InitDefaultSAXHandler');
  xmlSAX2InitHtmlDefaultSAXHandler:= GetProcAddress(Handle, 'xmlSAX2InitHtmlDefaultSAXHandler');
  xmlSAX2InternalSubset           := GetProcAddress(Handle, 'xmlSAX2InternalSubset');
  xmlSAX2IsStandalone             := GetProcAddress(Handle, 'xmlSAX2IsStandalone');
  xmlSAX2NotationDecl             := GetProcAddress(Handle, 'xmlSAX2NotationDecl');
  xmlSAX2ProcessingInstruction    := GetProcAddress(Handle,'xmlSAX2ProcessingInstruction');
  xmlSAX2Reference                := GetProcAddress(Handle, 'xmlSAX2Reference');
  xmlSAX2ResolveEntity            := GetProcAddress(Handle, 'xmlSAX2ResolveEntity');
  xmlSAX2SetDocumentLocator       := GetProcAddress(Handle, 'xmlSAX2SetDocumentLocator');
  xmlSAX2StartDocument            := GetProcAddress(Handle, 'xmlSAX2StartDocument');
  xmlSAX2StartElementNs           := GetProcAddress(Handle, 'xmlSAX2StartElementNs');
  xmlSAX2UnparsedEntityDecl       := GetProcAddress(Handle, 'xmlSAX2UnparsedEntityDecl');
  xmlSAXDefaultVersion            := GetProcAddress(Handle, 'xmlSAXDefaultVersion');
  xmlSAXVersion                   := GetProcAddress(Handle, 'xmlSAXVersion');
  xmlSchemaDump                   := GetProcAddress(Handle, 'xmlSchemaDump');
  xmlSchemaFree                   := GetProcAddress(Handle, 'xmlSchemaFree');
  xmlSchemaFreeParserCtxt         := GetProcAddress(Handle, 'xmlSchemaFreeParserCtxt');
  xmlSchemaFreeValidCtxt          := GetProcAddress(Handle, 'xmlSchemaFreeValidCtxt');
  xmlSchemaGetParserErrors        := GetProcAddress(Handle, 'xmlSchemaGetParserErrors');
  xmlSchemaGetValidErrors         := GetProcAddress(Handle, 'xmlSchemaGetValidErrors');
  xmlSchemaInitTypes              := GetProcAddress(Handle, 'xmlSchemaInitTypes');
  xmlSchemaIsValid                := GetProcAddress(Handle, 'xmlSchemaIsValid');
  xmlSchemaNewDocParserCtxt       := GetProcAddress(Handle, 'xmlSchemaNewDocParserCtxt');
  xmlSchemaNewMemParserCtxt       := GetProcAddress(Handle, 'xmlSchemaNewMemParserCtxt');
  xmlSchemaNewParserCtxt          := GetProcAddress(Handle, 'xmlSchemaNewParserCtxt');
  xmlSchemaNewValidCtxt           := GetProcAddress(Handle, 'xmlSchemaNewValidCtxt');
  xmlSchemaParse                  := GetProcAddress(Handle, 'xmlSchemaParse');
  xmlSchemaSAXPlug                := GetProcAddress(Handle, 'xmlSchemaSAXPlug');
  xmlSchemaSAXUnplug              := GetProcAddress(Handle, 'xmlSchemaSAXUnplug');
  xmlSchemaSetParserErrors        := GetProcAddress(Handle, 'xmlSchemaSetParserErrors');
  xmlSchemaSetParserStructuredErrors := GetProcAddress(Handle, 'xmlSchemaSetParserStructuredErrors');
  xmlSchemaSetResourceLoader      := GetProcAddress(Handle, 'xmlSchemaSetResourceLoader');
  xmlSchemaSetValidErrors         := GetProcAddress(Handle, 'xmlSchemaSetValidErrors');
  xmlSchemaSetValidOptions        := GetProcAddress(Handle, 'xmlSchemaSetValidOptions');
  xmlSchemaSetValidStructuredErrors := GetProcAddress(Handle, 'xmlSchemaSetValidStructuredErrors');
  xmlSchemaValidateDoc            := GetProcAddress(Handle, 'xmlSchemaValidateDoc');
  xmlSchemaValidateFile           := GetProcAddress(Handle, 'xmlSchemaValidateFile');
  xmlSchemaValidateOneElement     := GetProcAddress(Handle, 'xmlSchemaValidateOneElement');
  xmlSchemaValidateSetFilename    := GetProcAddress(Handle, 'xmlSchemaValidateSetFilename');
  xmlSchemaValidateSetLocator     := GetProcAddress(Handle, 'xmlSchemaValidateSetLocator');
  xmlSchemaValidateStream         := GetProcAddress(Handle, 'xmlSchemaValidateStream');
  xmlSchemaValidCtxtGetOptions    := GetProcAddress(Handle, 'xmlSchemaValidCtxtGetOptions');
  xmlSchemaValidCtxtGetParserCtxt := GetProcAddress(Handle, 'xmlSchemaValidCtxtGetParserCtxt');
  xmlSearchNs                     := GetProcAddress(Handle, 'xmlSearchNs');
  xmlSearchNsByHref               := GetProcAddress(Handle, 'xmlSearchNsByHref');
  xmlSetDocCompressMode           := GetProcAddress(Handle, 'xmlSetDocCompressMode');
  xmlSetExternalEntityLoader      := GetProcAddress(Handle, 'xmlSetExternalEntityLoader');
  xmlSetNs                        := GetProcAddress(Handle, 'xmlSetNs');
  xmlSetNsProp                    := GetProcAddress(Handle, 'xmlSetNsProp');
  xmlSetProp                      := GetProcAddress(Handle, 'xmlSetProp');
  xmlSplitQName                   := GetProcAddress(Handle, 'xmlSplitQName');
  xmlSplitQName3                  := GetProcAddress(Handle, 'xmlSplitQName3');
  xmlStopParser                   := GetProcAddress(Handle, 'xmlStopParser');
  xmlSwitchEncoding               := GetProcAddress(Handle, 'xmlSwitchEncoding');
  xmlSwitchEncodingName           := GetProcAddress(Handle, 'xmlSwitchEncodingName');
  xmlSwitchToEncoding             := GetProcAddress(Handle, 'xmlSwitchToEncoding');
  xmlTextConcat                   := GetProcAddress(Handle, 'xmlTextConcat');
  xmlTextMerge                    := GetProcAddress(Handle, 'xmlTextMerge');
  xmlTextReaderAttributeCount     := GetProcAddress(Handle, 'xmlTextReaderAttributeCount');
  xmlTextReaderBaseUri            := GetProcAddress(Handle, 'xmlTextReaderBaseUri');
  xmlTextReaderByteConsumed       := GetProcAddress(Handle, 'xmlTextReaderByteConsumed');
  xmlTextReaderClose              := GetProcAddress(Handle, 'xmlTextReaderClose');
  xmlTextReaderConstBaseUri       := GetProcAddress(Handle, 'xmlTextReaderConstBaseUri');
  xmlTextReaderConstEncoding      := GetProcAddress(Handle, 'xmlTextReaderConstEncoding');
  xmlTextReaderConstLocalName     := GetProcAddress(Handle, 'xmlTextReaderConstLocalName');
  xmlTextReaderConstName          := GetProcAddress(Handle, 'xmlTextReaderConstName');
  xmlTextReaderConstNamespaceUri  := GetProcAddress(Handle, 'xmlTextReaderConstNamespaceUri');
  xmlTextReaderConstPrefix        := GetProcAddress(Handle, 'xmlTextReaderConstPrefix');
  xmlTextReaderConstString        := GetProcAddress(Handle, 'xmlTextReaderConstString');
  xmlTextReaderConstValue         := GetProcAddress(Handle, 'xmlTextReaderConstValue');
  xmlTextReaderConstXmlLang       := GetProcAddress(Handle, 'xmlTextReaderConstXmlLang');
  xmlTextReaderConstXmlVersion    := GetProcAddress(Handle, 'xmlTextReaderConstXmlVersion');
  xmlTextReaderCurrentDoc         := GetProcAddress(Handle, 'xmlTextReaderCurrentDoc');
  xmlTextReaderCurrentNode        := GetProcAddress(Handle, 'xmlTextReaderCurrentNode');
  xmlTextReaderDepth              := GetProcAddress(Handle, 'xmlTextReaderDepth');
  xmlTextReaderExpand             := GetProcAddress(Handle, 'xmlTextReaderExpand');
  xmlTextReaderGetAttribute       := GetProcAddress(Handle, 'xmlTextReaderGetAttribute');
  xmlTextReaderGetAttributeNo     := GetProcAddress(Handle, 'xmlTextReaderGetAttributeNo');
  xmlTextReaderGetAttributeNs     := GetProcAddress(Handle, 'xmlTextReaderGetAttributeNs');
  xmlTextReaderGetErrorHandler    := GetProcAddress(Handle, 'xmlTextReaderGetErrorHandler');
  xmlTextReaderGetLastError       := GetProcAddress(Handle, 'xmlTextReaderGetLastError');
  xmlTextReaderGetParserColumnNumber := GetProcAddress(Handle, 'xmlTextReaderGetParserColumnNumber');
  xmlTextReaderGetParserLineNumber:= GetProcAddress(Handle, 'xmlTextReaderGetParserLineNumber');
  xmlTextReaderGetParserProp      := GetProcAddress(Handle, 'xmlTextReaderGetParserProp');
  xmlTextReaderGetRemainder       := GetProcAddress(Handle, 'xmlTextReaderGetRemainder');
  xmlTextReaderHasAttributes      := GetProcAddress(Handle, 'xmlTextReaderHasAttributes');
  xmlTextReaderHasValue           := GetProcAddress(Handle, 'xmlTextReaderHasValue');
  xmlTextReaderIsDefault          := GetProcAddress(Handle, 'xmlTextReaderIsDefault');
  xmlTextReaderIsEmptyElement     := GetProcAddress(Handle, 'xmlTextReaderIsEmptyElement');
  xmlTextReaderIsNamespaceDecl    := GetProcAddress(Handle, 'xmlTextReaderIsNamespaceDecl');
  xmlTextReaderIsValid            := GetProcAddress(Handle, 'xmlTextReaderIsValid');
  xmlTextReaderLocalName          := GetProcAddress(Handle, 'xmlTextReaderLocalName');
  xmlTextReaderLocatorBaseURI     := GetProcAddress(Handle, 'xmlTextReaderLocatorBaseURI');
  xmlTextReaderLocatorLineNumber  := GetProcAddress(Handle, 'xmlTextReaderLocatorLineNumber');
  xmlTextReaderLookupNamespace    := GetProcAddress(Handle, 'xmlTextReaderLookupNamespace');
  xmlTextReaderMoveToAttribute    := GetProcAddress(Handle, 'xmlTextReaderMoveToAttribute');
  xmlTextReaderMoveToAttributeNo  := GetProcAddress(Handle, 'xmlTextReaderMoveToAttributeNo');
  xmlTextReaderMoveToAttributeNs  := GetProcAddress(Handle, 'xmlTextReaderMoveToAttributeNs');
  xmlTextReaderMoveToElement      := GetProcAddress(Handle, 'xmlTextReaderMoveToElement');
  xmlTextReaderMoveToFirstAttribute := GetProcAddress(Handle, 'xmlTextReaderMoveToFirstAttribute');
  xmlTextReaderMoveToNextAttribute:= GetProcAddress(Handle, 'xmlTextReaderMoveToNextAttribute');
  xmlTextReaderName               := GetProcAddress(Handle, 'xmlTextReaderName');
  xmlTextReaderNamespaceUri       := GetProcAddress(Handle, 'xmlTextReaderNamespaceUri');
  xmlTextReaderNext               := GetProcAddress(Handle, 'xmlTextReaderNext');
  xmlTextReaderNextSibling        := GetProcAddress(Handle, 'xmlTextReaderNextSibling');
  xmlTextReaderNodeType           := GetProcAddress(Handle, 'xmlTextReaderNodeType');
  xmlTextReaderNormalization      := GetProcAddress(Handle, 'xmlTextReaderNormalization');
  xmlTextReaderPrefix             := GetProcAddress(Handle, 'xmlTextReaderPrefix');
  xmlTextReaderPreserve           := GetProcAddress(Handle, 'xmlTextReaderPreserve');
  xmlTextReaderPreservePattern    := GetProcAddress(Handle, 'xmlTextReaderPreservePattern');
  xmlTextReaderQuoteChar          := GetProcAddress(Handle, 'xmlTextReaderQuoteChar');
  xmlTextReaderRead               := GetProcAddress(Handle, 'xmlTextReaderRead');
  xmlTextReaderReadAttributeValue := GetProcAddress(Handle, 'xmlTextReaderReadAttributeValue');
  xmlTextReaderReadInnerXml       := GetProcAddress(Handle, 'xmlTextReaderReadInnerXml');
  xmlTextReaderReadOuterXml       := GetProcAddress(Handle, 'xmlTextReaderReadOuterXml');
  xmlTextReaderReadState          := GetProcAddress(Handle, 'xmlTextReaderReadState');
  xmlTextReaderReadString         := GetProcAddress(Handle, 'xmlTextReaderReadString');
  xmlTextReaderRelaxNGSetSchema   := GetProcAddress(Handle, 'xmlTextReaderRelaxNGSetSchema');
  xmlTextReaderRelaxNGValidate    := GetProcAddress(Handle, 'xmlTextReaderRelaxNGValidate');
  xmlTextReaderRelaxNGValidateCtxt:= GetProcAddress(Handle, 'xmlTextReaderRelaxNGValidateCtxt');
  xmlTextReaderSchemaValidate     := GetProcAddress(Handle, 'xmlTextReaderSchemaValidate');
  xmlTextReaderSchemaValidateCtxt := GetProcAddress(Handle, 'xmlTextReaderSchemaValidateCtxt');
  xmlTextReaderSetErrorHandler    := GetProcAddress(Handle, 'xmlTextReaderSetErrorHandler');
  xmlTextReaderSetMaxAmplification:= GetProcAddress(Handle, 'xmlTextReaderSetMaxAmplification');
  xmlTextReaderSetParserProp      := GetProcAddress(Handle, 'xmlTextReaderSetParserProp');
  xmlTextReaderSetResourceLoader  := GetProcAddress(Handle, 'xmlTextReaderSetResourceLoader');
  xmlTextReaderSetSchema          := GetProcAddress(Handle, 'xmlTextReaderSetSchema');
  xmlTextReaderSetStructuredErrorHandler := GetProcAddress(Handle, 'xmlTextReaderSetStructuredErrorHandler');
  xmlTextReaderSetup              := GetProcAddress(Handle, 'xmlTextReaderSetup');
  xmlTextReaderStandalone         := GetProcAddress(Handle, 'xmlTextReaderStandalone');
  xmlTextReaderValue              := GetProcAddress(Handle, 'xmlTextReaderValue');
  xmlTextReaderXmlLang            := GetProcAddress(Handle, 'xmlTextReaderXmlLang');
  xmlUnlinkNode                   := GetProcAddress(Handle, 'xmlUnlinkNode');
  xmlUnsetNsProp                  := GetProcAddress(Handle, 'xmlUnsetNsProp');
  xmlUnsetProp                    := GetProcAddress(Handle, 'xmlUnsetProp');
  xmlURIEscape                    := GetProcAddress(Handle, 'xmlURIEscape');
  xmlURIEscapeStr                 := GetProcAddress(Handle, 'xmlURIEscapeStr');
  xmlURIUnescapeString            := GetProcAddress(Handle, 'xmlURIUnescapeString');
  xmlUTF8ToIsolat1                := GetProcAddress(Handle, 'xmlUTF8ToIsolat1');
  xmlValidateDtd                  := GetProcAddress(Handle, 'xmlValidateDtd');
  xmlValidateElement              := GetProcAddress(Handle, 'xmlValidateElement');
  xmlValidateName                 := GetProcAddress(Handle, 'xmlValidateName');
  xmlValidateNamesValue           := GetProcAddress(Handle, 'xmlValidateNamesValue');
  xmlValidateNameValue            := GetProcAddress(Handle, 'xmlValidateNameValue');
  xmlValidateNCName               := GetProcAddress(Handle, 'xmlValidateNCName');
  xmlValidateNMToken              := GetProcAddress(Handle, 'xmlValidateNMToken');
  xmlValidateNmtokensValue        := GetProcAddress(Handle, 'xmlValidateNmtokensValue');
  xmlValidateNmtokenValue         := GetProcAddress(Handle, 'xmlValidateNmtokenValue');
  xmlValidateQName                := GetProcAddress(Handle, 'xmlValidateQName');
  xmlValidGetPotentialChildren    := GetProcAddress(Handle, 'xmlValidGetPotentialChildren');
  xmlValidGetValidElements        := GetProcAddress(Handle, 'xmlValidGetValidElements');
  xmlXPathAddValues               := GetProcAddress(Handle, 'xmlXPathAddValues');
  xmlXPathBooleanFunction         := GetProcAddress(Handle, 'xmlXPathBooleanFunction');
  xmlXPathCastBooleanToNumber     := GetProcAddress(Handle, 'xmlXPathCastBooleanToNumber');
  xmlXPathCastBooleanToString     := GetProcAddress(Handle, 'xmlXPathCastBooleanToString');
  xmlXPathCastNodeSetToBoolean    := GetProcAddress(Handle, 'xmlXPathCastNodeSetToBoolean');
  xmlXPathCastNodeSetToNumber     := GetProcAddress(Handle, 'xmlXPathCastNodeSetToNumber');
  xmlXPathCastNodeSetToString     := GetProcAddress(Handle, 'xmlXPathCastNodeSetToString');
  xmlXPathCastNodeToNumber        := GetProcAddress(Handle, 'xmlXPathCastNodeToNumber');
  xmlXPathCastNodeToString        := GetProcAddress(Handle, 'xmlXPathCastNodeToString');
  xmlXPathCastNumberToBoolean     := GetProcAddress(Handle, 'xmlXPathCastNumberToBoolean');
  xmlXPathCastNumberToString      := GetProcAddress(Handle, 'xmlXPathCastNumberToString');
  xmlXPathCastStringToBoolean     := GetProcAddress(Handle, 'xmlXPathCastStringToBoolean');
  xmlXPathCastStringToNumber      := GetProcAddress(Handle, 'xmlXPathCastStringToNumber');
  xmlXPathCastToBoolean           := GetProcAddress(Handle, 'xmlXPathCastToBoolean');
  xmlXPathCastToNumber            := GetProcAddress(Handle, 'xmlXPathCastToNumber');
  xmlXPathCastToString            := GetProcAddress(Handle, 'xmlXPathCastToString');
  xmlXPathCeilingFunction         := GetProcAddress(Handle, 'xmlXPathCeilingFunction');
  xmlXPathCmpNodes                := GetProcAddress(Handle, 'xmlXPathCmpNodes');
  xmlXPathCompareValues           := GetProcAddress(Handle, 'xmlXPathCompareValues');
  xmlXPathCompile                 := GetProcAddress(Handle, 'xmlXPathCompile');
  xmlXPathCompiledEval            := GetProcAddress(Handle, 'xmlXPathCompiledEval');
  xmlXPathCompiledEvalToBoolean   := GetProcAddress(Handle, 'xmlXPathCompiledEvalToBoolean');
  xmlXPathConcatFunction          := GetProcAddress(Handle, 'xmlXPathConcatFunction');
  xmlXPathContainsFunction        := GetProcAddress(Handle, 'xmlXPathContainsFunction');
  xmlXPathContextSetCache         := GetProcAddress(Handle, 'xmlXPathContextSetCache');
  xmlXPathConvertBoolean          := GetProcAddress(Handle, 'xmlXPathConvertBoolean');
  xmlXPathConvertNumber           := GetProcAddress(Handle, 'xmlXPathConvertNumber');
  xmlXPathConvertString           := GetProcAddress(Handle, 'xmlXPathConvertString');
  xmlXPathCountFunction           := GetProcAddress(Handle, 'xmlXPathCountFunction');
  xmlXPathCtxtCompile             := GetProcAddress(Handle, 'xmlXPathCtxtCompile');
  xmlXPathDifference              := GetProcAddress(Handle, 'xmlXPathDifference');
  xmlXPathDistinct                := GetProcAddress(Handle, 'xmlXPathDistinct');
  xmlXPathDistinctSorted          := GetProcAddress(Handle, 'xmlXPathDistinctSorted');
  xmlXPathDivValues               := GetProcAddress(Handle, 'xmlXPathDivValues');
  xmlXPathEqualValues             := GetProcAddress(Handle, 'xmlXPathEqualValues');
  xmlXPathErr                     := GetProcAddress(Handle, 'xmlXPathErr');
  xmlXPathError                   := GetProcAddress(Handle, 'xmlXPatherror');
  xmlXPathEval                    := GetProcAddress(Handle, 'xmlXPathEval');
  xmlXPathEvalExpr                := GetProcAddress(Handle, 'xmlXPathEvalExpr');
  xmlXPathEvalExpression          := GetProcAddress(Handle, 'xmlXPathEvalExpression');
  xmlXPathEvalPredicate           := GetProcAddress(Handle, 'xmlXPathEvalPredicate');
  xmlXPathEvaluatePredicateResult :=GetProcAddress(Handle,'xmlXPathEvaluatePredicateResult');
  xmlXPathFalseFunction           := GetProcAddress(Handle, 'xmlXPathFalseFunction');
  xmlXPathFloorFunction           := GetProcAddress(Handle, 'xmlXPathFloorFunction');
  xmlXPathFreeCompExpr            := GetProcAddress(Handle, 'xmlXPathFreeCompExpr');
  xmlXPathFreeContext             := GetProcAddress(Handle, 'xmlXPathFreeContext');
  xmlXPathFreeNodeSet             := GetProcAddress(Handle, 'xmlXPathFreeNodeSet');
  xmlXPathFreeNodeSetList         := GetProcAddress(Handle, 'xmlXPathNodeSetCreate');
  xmlXPathFreeObject              := GetProcAddress(Handle, 'xmlXPathFreeObject');
  xmlXPathFreeParserContext       := GetProcAddress(Handle, 'xmlXPathFreeParserContext');
  xmlXPathFunctionLookup          := GetProcAddress(Handle, 'xmlXPathFunctionLookup');
  xmlXPathFunctionLookupNS        := GetProcAddress(Handle, 'xmlXPathFunctionLookupNS');
  xmlXPathHasSameNodes            := GetProcAddress(Handle, 'xmlXPathHasSameNodes');
  xmlXPathIdFunction              := GetProcAddress(Handle, 'xmlXPathIdFunction');
  xmlXPathIntersection            := GetProcAddress(Handle, 'xmlXPathIntersection');
  xmlXPathIsInf                   := GetProcAddress(Handle, 'xmlXPathIsInf');
  xmlXPathIsNaN                   := GetProcAddress(Handle, 'xmlXPathIsNaN');
  xmlXPathIsNodeType              := GetProcAddress(Handle, 'xmlXPathIsNodeType');
  xmlXPathLangFunction            := GetProcAddress(Handle, 'xmlXPathLangFunction');
  xmlXPathLastFunction            := GetProcAddress(Handle, 'xmlXPathLastFunction');
  xmlXPathLeading                 := GetProcAddress(Handle, 'xmlXPathLeading');
  xmlXPathLeadingSorted           := GetProcAddress(Handle, 'xmlXPathLeadingSorted');
  xmlXPathLocalNameFunction       := GetProcAddress(Handle, 'xmlXPathLocalNameFunction');
  xmlXPathModValues               := GetProcAddress(Handle, 'xmlXPathModValues');
  xmlXPathMultValues              := GetProcAddress(Handle, 'xmlXPathMultValues');
  xmlXPathNamespaceURIFunction    := GetProcAddress(Handle, 'xmlXPathNamespaceURIFunction');
  xmlXPathNewBoolean              := GetProcAddress(Handle, 'xmlXPathNewBoolean');
  xmlXPathNewContext              := GetProcAddress(Handle, 'xmlXPathNewContext');
  xmlXPathNewCString              := GetProcAddress(Handle, 'xmlXPathNewCString');
  xmlXPathNewFloat                := GetProcAddress(Handle, 'xmlXPathNewFloat');
  xmlXPathNewNodeSet              := GetProcAddress(Handle, 'xmlXPathNewNodeSet');
  xmlXPathNewNodeSetList          := GetProcAddress(Handle, 'xmlXPathNewNodeSetList');
  xmlXPathNewParserContext        := GetProcAddress(Handle, 'xmlXPathNewParserContext');
  xmlXPathNewString               := GetProcAddress(Handle, 'xmlXPathNewString');
  xmlXPathNewValueTree            := GetProcAddress(Handle, 'xmlXPathNewValueTree');
  xmlXPathNextAncestor            := GetProcAddress(Handle, 'xmlXPathNextAncestor');
  xmlXPathNextAncestorOrSelf      := GetProcAddress(Handle, 'xmlXPathNextAncestorOrSelf');
  xmlXPathNextAttribute           := GetProcAddress(Handle, 'xmlXPathNextAttribute');
  xmlXPathNextChild               := GetProcAddress(Handle, 'xmlXPathNextChild');
  xmlXPathNextDescendant          := GetProcAddress(Handle, 'xmlXPathNextDescendant');
  xmlXPathNextDescendantOrSelf    := GetProcAddress(Handle, 'xmlXPathNextDescendantOrSelf');
  xmlXPathNextFollowing           := GetProcAddress(Handle, 'xmlXPathNextFollowing');
  xmlXPathNextFollowingSibling    := GetProcAddress(Handle, 'xmlXPathNextFollowingSibling');
  xmlXPathNextNamespace           := GetProcAddress(Handle, 'xmlXPathNextNamespace');
  xmlXPathNextParent              := GetProcAddress(Handle, 'xmlXPathNextParent');
  xmlXPathNextPreceding           := GetProcAddress(Handle, 'xmlXPathNextPreceding');
  xmlXPathNextPrecedingSibling    := GetProcAddress(Handle, 'xmlXPathNextPrecedingSibling');
  xmlXPathNextSelf                := GetProcAddress(Handle, 'xmlXPathNextSelf');
  xmlXPathNodeEval                := GetProcAddress(Handle, 'xmlXPathNodeEval');
  xmlXPathNodeLeading             := GetProcAddress(Handle, 'xmlXPathNodeLeading');
  xmlXPathNodeLeadingSorted       := GetProcAddress(Handle, 'xmlXPathNodeLeadingSorted');
  xmlXPathNodeSetAdd              := GetProcAddress(Handle, 'xmlXPathNodeSetAdd');
  xmlXPathNodeSetAddNs            := GetProcAddress(Handle, 'xmlXPathNodeSetAddNs');
  xmlXPathNodeSetAddUnique        := GetProcAddress(Handle, 'xmlXPathNodeSetAddUnique');
  xmlXPathNodeSetContains         := GetProcAddress(Handle, 'xmlXPathNodeSetContains');
  xmlXPathNodeSetCreate           := GetProcAddress(Handle, 'xmlXPathNodeSetCreate');
  xmlXPathNodeSetDel              := GetProcAddress(Handle, 'xmlXPathNodeSetDel');
  xmlXPathNodeSetFreeNs           := GetProcAddress(Handle, 'xmlXPathNodeSetFreeNs');
  xmlXPathNodeSetMerge            := GetProcAddress(Handle, 'xmlXPathNodeSetMerge');
  xmlXPathNodeSetRemove           := GetProcAddress(Handle, 'xmlXPathNodeSetRemove');
  xmlXPathNodeSetSort             := GetProcAddress(Handle, 'xmlXPathNodeSetSort');
  xmlXPathNodeTrailing            := GetProcAddress(Handle, 'xmlXPathNodeTrailing');
  xmlXPathNodeTrailingSorted      := GetProcAddress(Handle, 'xmlXPathNodeTrailingSorted');
  xmlXPathNormalizeFunction       := GetProcAddress(Handle, 'xmlXPathNormalizeFunction');
  xmlXPathNotEqualValues          := GetProcAddress(Handle, 'xmlXPathNotEqualValues');
  xmlXPathNotFunction             := GetProcAddress(Handle, 'xmlXPathNotFunction');
  xmlXPathNsLookup                := GetProcAddress(Handle,'xmlXPathNsLookup');
  xmlXPathNumberFunction          := GetProcAddress(Handle, 'xmlXPathNumberFunction');
  xmlXPathObjectCopy              := GetProcAddress(Handle, 'xmlXPathObjectCopy');
  xmlXPathOrderDocElems           := GetProcAddress(Handle, 'xmlXPathOrderDocElems');
  xmlXPathParseName               := GetProcAddress(Handle, 'xmlXPathParseName');
  xmlXPathParseNCName             := GetProcAddress(Handle, 'xmlXPathParseNCName');
  xmlXPathPopBoolean              := GetProcAddress(Handle, 'xmlXPathPopBoolean');
  xmlXPathPopExternal             := GetProcAddress(Handle, 'xmlXPathPopExternal');
  xmlXPathPopNodeSet              := GetProcAddress(Handle, 'xmlXPathPopNodeSet');
  xmlXPathPopNumber               := GetProcAddress(Handle, 'xmlXPathPopNumber');
  xmlXPathPopString               := GetProcAddress(Handle, 'xmlXPathPopString');
  xmlXPathPositionFunction        := GetProcAddress(Handle, 'xmlXPathPositionFunction');
  xmlXPathRegisterAllFunctions    := GetProcAddress(Handle, 'xmlXPathRegisterAllFunctions');
  xmlXPathRegisteredFuncsCleanup  := GetProcAddress(Handle, 'xmlXPathRegisteredFuncsCleanup');
  xmlXPathRegisteredNsCleanup     := GetProcAddress(Handle, 'xmlXPathRegisteredNsCleanup');
  xmlXPathRegisteredVariablesCleanup := GetProcAddress(Handle, 'xmlXPathRegisteredVariablesCleanup');
  xmlXPathRegisterFunc            := GetProcAddress(Handle, 'xmlXPathRegisterFunc');
  xmlXPathRegisterFuncLookup      := GetProcAddress(Handle, 'xmlXPathRegisterFuncLookup');
  xmlXPathRegisterFuncNS          := GetProcAddress(Handle, 'xmlXPathRegisterFuncNS');
  xmlXPathRegisterNs              := GetProcAddress(Handle, 'xmlXPathRegisterNs');
  xmlXPathRegisterNs              := GetProcAddress(Handle, 'xmlXPathRegisterNs');
  xmlXPathRegisterVariable        := GetProcAddress(Handle, 'xmlXPathRegisterVariable');
  xmlXPathRegisterVariableLookup  :=GetProcAddress(Handle, 'xmlXPathRegisterVariableLookup');
  xmlXPathRegisterVariableNS      := GetProcAddress(Handle, 'xmlXPathRegisterVariableNS');
  xmlXPathRoot                    := GetProcAddress(Handle, 'xmlXPathRoot');
  xmlXPathRoundFunction           := GetProcAddress(Handle, 'xmlXPathRoundFunction');
  xmlXPathSetContextNode          := GetProcAddress(Handle, 'xmlXPathSetContextNode');
  xmlXPathSetErrorHandler         := GetProcAddress(Handle, 'xmlXPathSetErrorHandler');
  xmlXPathStartsWithFunction      := GetProcAddress(Handle, 'xmlXPathStartsWithFunction');
  xmlXPathStringEvalNumber        := GetProcAddress(Handle, 'xmlXPathStringEvalNumber');
  xmlXPathStringFunction          := GetProcAddress(Handle, 'xmlXPathStringFunction');
  xmlXPathStringLengthFunction    := GetProcAddress(Handle, 'xmlXPathStringLengthFunction');
  xmlXPathSubstringAfterFunction  := GetProcAddress(Handle, 'xmlXPathSubstringAfterFunction');
  xmlXPathSubstringBeforeFunction := GetProcAddress(Handle,'xmlXPathSubstringBeforeFunction');
  xmlXPathSubstringFunction       := GetProcAddress(Handle, 'xmlXPathSubstringFunction');
  xmlXPathSubValues               := GetProcAddress(Handle, 'xmlXPathSubValues');
  xmlXPathSumFunction             := GetProcAddress(Handle, 'xmlXPathSumFunction');
  xmlXPathTrailing                := GetProcAddress(Handle, 'xmlXPathTrailing');
  xmlXPathTrailingSorted          := GetProcAddress(Handle, 'xmlXPathTrailingSorted');
  xmlXPathTranslateFunction       := GetProcAddress(Handle, 'xmlXPathTranslateFunction');
  xmlXPathTrueFunction            := GetProcAddress(Handle, 'xmlXPathTrueFunction');
  xmlXPathValueFlipSign           := GetProcAddress(Handle, 'xmlXPathValueFlipSign');
  xmlXPathValuePop                := GetProcAddress(Handle, 'xmlXPathValuePop');
  xmlXPathValuePush               := GetProcAddress(Handle, 'xmlXPathValuePush');
  xmlXPathVariableLookup          := GetProcAddress(Handle, 'xmlXPathVariableLookup');
  xmlXPathVariableLookupNS        := GetProcAddress(Handle, 'xmlXPathVariableLookupNS');
  xmlXPathWrapCString             := GetProcAddress(Handle, 'xmlXPathWrapCString');
  xmlXPathWrapExternal            := GetProcAddress(Handle, 'xmlXPathWrapExternal');
  xmlXPathWrapNodeSet             := GetProcAddress(Handle, 'xmlXPathWrapNodeSet');
  xmlXPathWrapString              := GetProcAddress(Handle, 'xmlXPathWrapString');

{$endregion}

  xmlMemSetup(xmlMemFree, xmlMemMalloc, xmlMemRealloc, xmlMemoryStrdup);

  xmlMemGet(xmlFree, xmlMalloc, xmlRealloc, xmlStrdup);

  xmlSchemaInitTypes;
end;


initialization

finalization
  LX2Lib.Unload;

end.
