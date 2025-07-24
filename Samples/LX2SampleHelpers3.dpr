program LX2SampleHelpers3;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  {$IFDEF MSWINDOWS}
  FastMM4,
  {$ENDIF }
  System.SysUtils,
  libxml2.API in '..\Source\libxml2.API.pas',
  libxslt.API in '..\Source\libxslt.API.pas',
  LX2.Helpers in '..\Source\LX2.Helpers.pas',
  LX2.Types in '..\Source\LX2.Types.pas',
  LX2.DOM in '..\Source\LX2.DOM.pas',
  LX2.DOM.Classes in '..\Source\LX2.DOM.Classes.pas',
  LX2SampleXML in 'LX2SampleXML.pas',
  LXSample.Common in 'LXSample.Common.pas',
  RttiDispatch in '..\Source\RttiDispatch.pas';

var
  Indent: Integer = 0;

  procedure Traverse(Node: xmlNodePtr);
  begin
    Write(string.Create(' ', Indent * 2));

    Write(Node.NodeName);
    Write(': ');
    WriteLn(Node.Value);

    Inc(Indent);
    var Child := Node.FirstChild;
    while Child <> nil do
    begin
      Traverse(Child);
      Child := Child.NextSibling;
    end;
    Dec(Indent);
  end;

begin
  try
    StartTests;

    TestStart('LOAD FROM STRING');
    var Doc := xmlDoc.Create(TestXml1, DefaultParserOptions);
    if not TestEnd(Doc <> nil) then
    begin
      ReadLn;
      Exit;
    end;

    TestStart('TRAVERSE NODES');

    Traverse(xmlNodePtr(Doc));

    TestEnd(True);

    Doc.Free;

    EndTests;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

  WriteLn('Press Enter to exit');
  ReadLn;
end.
