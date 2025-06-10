program LX2SampleDOM1;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  libxml2.API,
  libxslt.API,
  LX2.DOM,
  LX2.DOM.Classes,
  LX2SampleXML in 'LX2SampleXML.pas',
  LXSample.Common in 'LXSample.Common.pas';


procedure Test;
var
  Doc: IXMLDocument;
begin
  TestStart('Create doc');
  Doc := TXMLDocument.Create;
  TestEnd(doc <> nil);

  TestStart('load XML');
  TestEnd(Doc.LoadXML(TestXml1));

  TestStart('Append child');
  var Child := Doc.CreateElement('test2');
  Doc.DocumentElement.AppendChild(Child);
  TestEnd(Child.AddChild('ChildChild', 'привет') <> nil);

  Child.SetAttribute('Hello', 'World');

  TestStart('Remove child');
  TestEnd(Doc.DocumentElement.RemoveChild(Doc.DocumentElement.FirstChild) <> nil);

  WriteLn(Doc.ToString(True));

  TestStart('Create unlinked node, success if unreleased = 0');
  Doc.CreateDocumentFragment;

  doc := nil;
end;

begin
  try
    StartTests;

    Test;

    EndTests;

    Write('Unreleased objects: ');
    WriteLn(NodeObjectCount);
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

  WriteLn('Press Enter to exit');
  ReadLn;

end.
