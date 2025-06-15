program LX2SampleHelpers1;

/// Parse XML & Canonicalize string using helpers

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
  LX2SampleXML in 'LX2SampleXML.pas',
  LXSample.Common in 'LXSample.Common.pas';

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

    TestStart('FORMATTED OUTPUT');

    WriteLn(Doc.ToString(True));

    TestEnd(True);

    TestStart('NON FORMATTED');

    WriteLn(Doc.ToString(False));

    TestEnd(True);

    TestStart('C14N');

    var C14NDoc := Doc.Canonicalize;

    if TestEnd(C14NDoc <> nil) then
    begin
      WriteLn(C14NDoc.Xml);
      TestEnd(True);
    end;

    Doc.Free;

    EndTests;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

  WriteLn('Press Enter to exit');
  ReadLn;
end.
