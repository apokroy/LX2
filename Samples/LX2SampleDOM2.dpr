program LX2SampleDOM2;

{$APPTYPE CONSOLE}

{$R *.res}

uses
{$IFDEF MSWINDOWS}
  FastMM4,
{$ENDIF}
  System.SysUtils,
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
  TestEnd(Attrs.Length = 2);

  TestStart('Add namespace');
  var Ns := Doc.CreateAttribute('xmlns:sample');
  Ns.NodeValue := 'http://sample.com/attrs';
  Attrs.SetNamedItem(Ns);
  TestEnd(Attrs.GetNamedItem('xmlns:sample').NodeValue = 'http://sample.com/attrs');

  TestStart('Is NamedNodeMap Live?');
  Attrs.SetNamedItem(Doc.CreateAttribute('NewAttr')).NodeValue := '<Escaped value>';
  TestEnd(Attrs.Length = 4);

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
