program LX2SampleDOM2;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  {$IFDEF MSWINDOWS}
  FastMM4,
  {$ENDIF }
  System.SysUtils,
  System.Classes,
  System.Diagnostics,
  System.Generics.Collections,
  libxml2.API in '..\Source\libxml2.API.pas',
  libxslt.API in '..\Source\libxslt.API.pas',
  LX2.Helpers in '..\Source\LX2.Helpers.pas',
  LX2.Types in '..\Source\LX2.Types.pas',
  LX2.DOM.Classes in '..\Source\LX2.DOM.Classes.pas',
  LX2.DOM in '..\Source\LX2.DOM.pas',
  LX2SampleXML in 'LX2SampleXML.pas',
  LXSample.Common in 'LXSample.Common.pas',
  RttiDispatch in '..\Source\RttiDispatch.pas',
  LX2.XPATH in '..\Source\LX2.XPATH.pas';

procedure Traverse(const Node: IXmlElement);
begin
  var Child := Node.FirstElementChild;
  while Child <> nil do
  begin
    Child := Child.NextElementSibling;
  end;
end;

type
  TXmlSchemaSet = class
  private
  protected
  public
    constructor Create;
    destructor Destroy; override;  
  end;

{ TXmlSchemaSet }

constructor TXmlSchemaSet.Create;
begin
  inherited Create;
end;

destructor TXmlSchemaSet.Destroy;
begin
  inherited;
end;

procedure Test;

  function Add(Schemas: IXMLSchemaCollection; const FileName: string): IXMLDocument;
  begin
    Result := CoCreateXMLDocument;
    Result.Load(FileName);
    Schemas.Add(Result.DocumentElement.GetAttribute('targetNamespace'), Result);
  end;

const
  Xml: Utf8String =
'''
<?xml version="1.0" encoding="utf-8"?>
<a:Root xmlns:a="1123213">
</a:Root>
''';
var
  Attrs: IXMLAttributes;
  S: string;
  Node, Sig: IXmlElement;
begin
  var Doc := CoCreateXMLDocument;
  Doc.LoadXML(Xml);

  Node := Doc.DocumentElement;

  Sig := Node.AddChildNs('SigValue', 'dsig:urn:cbr-ru:dsig:v1.1');

  WriteLn(Doc.Xml);

end;

begin
   try
    StartTests;

    Test;

    EndTests;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

  WriteLn('Press Enter to exit');
  ReadLn;
end.
