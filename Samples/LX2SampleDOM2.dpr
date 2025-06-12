program LX2SampleDOM2;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
{  msxmlIntf,
  Winapi.msxml,
  Comobj,}
  libxml2.API in '..\Source\libxml2.API.pas',
  libxslt.API in '..\Source\libxslt.API.pas',
  LX2.Helpers in '..\Source\LX2.Helpers.pas',
  LX2.Types in '..\Source\LX2.Types.pas',
  LX2.DOM.Classes in '..\Source\LX2.DOM.Classes.pas',
  LX2.DOM in '..\Source\LX2.DOM.pas',
  LX2SampleXML in 'LX2SampleXML.pas',
  LXSample.Common in 'LXSample.Common.pas';

procedure Test;
begin
{  CoInitializeEx(nil, 0);
  var d := CoDOMDocument60.Create;
  d.loadXML(TestXml1);
  WriteLn(d.parseError.reason);
  WriteLn(d.DocumentElement.SelectNodes('//Tests/Test').length);}

  var Doc := CoCreateXMLDocument;

  Doc.LoadXML(TestXml1);

  TestStart('SelectNodes');
  var XNodes := Doc.DocumentElement.SelectNodes('//Tests/Test');
  TestEnd(XNodes.Length = 6);

  TestStart('GetElementsByTagName');
  var Elems := Doc.DocumentElement.GetElementsByTagName('tst:Test');
  TestEnd(Elems.Length = 1);

  TestStart('Is Lists Live?');
  Doc.DocumentElement.AddChild('tst:Test', 'Added Test');
  TestEnd(Elems.Length = 2);

  TestStart('Attributes (NamedNodeMap)');
  var Attrs := Doc.DocumentElement.Attributes;
  TestEnd(Attrs.Length = 1);

  TestStart('Is NamedNodeMap Live?');
  Attrs.SetNamedItem(Doc.CreateAttribute('NewAttr')).NodeValue := 'New Attr Added';
  TestEnd(Attrs.Length = 2);

  WriteLn(Doc.ToString(True));

  doc := nil;
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
