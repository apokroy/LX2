program LX2SampleHelpers2;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  libxml2.API in '..\Source\libxml2.API.pas',
  libxslt.API in '..\Source\libxslt.API.pas',
  LX2.Helpers in '..\Source\LX2.Helpers.pas',
  LX2.Types in '..\Source\LX2.Types.pas',
  LX2SampleXML in 'LX2SampleXML.pas',
  LXSample.Common in 'LXSample.Common.pas';

var
  Result: xmlDocPtr;
begin
  try
    StartTests;

    TestStart('LOAD XML');

    var Doc := xmlDoc.Create(TestTransformXML, DefaultParserOptions);
    if not TestEnd(Doc <> nil) then
    begin
      ReadLn;
      Exit;
    end;

    TestStart('LOAD XSD');
    var Style := xmlDoc.Create(TestTransformXSD, DefaultParserOptions);
    if not TestEnd(Style <> nil) then
    begin
      ReadLn;
      Exit;
    end;

    TestStart('TRANSFORM');
    if TestEnd(Doc.Transform(Style, Result)) then
      WriteLn(Result.ToString(True));

    Style.Free;
    Result.Free;
    Doc.Free;

    EndTests;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

  WriteLn('Press Enter to exit');
  ReadLn;
end.
