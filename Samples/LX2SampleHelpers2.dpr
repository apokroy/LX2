program LX2SampleHelpers2;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Diagnostics,
  libxml2.API in '..\Source\libxml2.API.pas',
  libxslt.API in '..\Source\libxslt.API.pas',
  LX2.Helpers in '..\Source\LX2.Helpers.pas',
  LX2.Types in '..\Source\LX2.Types.pas',
  LX2SampleXML in 'LX2SampleXML.pas';

var
  Timer: TStopwatch;
  Result: xmlDocPtr;
begin
  try
    Timer := TStopwatch.Create;

    Timer.Start;
    WriteLn('------------------- LX2 Init (libxml2.dll or libxml2.so.16 must be in path) -------------------');

    LX2Lib.Initialize;

    WriteLn('------------------- SUCCESS (' + Timer.ElapsedMilliseconds.ToString + 'ms) -------------------');
    WriteLn('');

    WriteLn('------------------- LOAD XML -------------------');
    Timer.Reset;
    var Doc := xmlDoc.Create(TestTransformXML, DefaultParserOptions);
    if Doc = nil then
    begin
      WriteLn('------------------- ERROR -------------------');
      Doc.Free;
      ReadLn;
      Exit;
    end;
    WriteLn('------------------- SUCCESS (' + Timer.ElapsedMilliseconds.ToString + 'ms) -------------------');
    WriteLn('');

    WriteLn('------------------- LOAD XSD -------------------');
    Timer.Reset;
    var Style := xmlDoc.Create(TestTransformXSD, DefaultParserOptions);
    if Style = nil then
    begin
      WriteLn('------------------- ERROR -------------------');
      Style.Free;
      ReadLn;
      Exit;
    end;
    WriteLn('------------------- SUCCESS (' + Timer.ElapsedMilliseconds.ToString + 'ms) -------------------');
    WriteLn('');

    WriteLn('------------------- TRANSFORM -------------------');
    Timer.Reset;
    if Doc.Transform(Style, Result) then
    begin
      WriteLn('------------------- SUCCESS (' + Timer.ElapsedMilliseconds.ToString + 'ms) -------------------');
      WriteLn('');

      WriteLn(Result.Xml);
    end
    else
    begin
      WriteLn('------------------- ERROR (' + Timer.ElapsedMilliseconds.ToString + 'ms) -------------------');
      WriteLn('');
    end;

    Style.Free;
    Doc.Free;
    Result.Free;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  ReadLn;
end.
