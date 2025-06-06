program LX2SampleHelpers1;

/// Parse XML & Canonicalize string using helpers

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
begin
  try
    Timer := TStopwatch.Create;

    Timer.Start;
    WriteLn('------------------- LX2 Init (libxml2.dll or libxml2.so.16 must be in path) -------------------');

    LX2Lib.Initialize;

    WriteLn('------------------- SUCCESS (' + Timer.ElapsedMilliseconds.ToString + 'ms) -------------------');
    WriteLn('');



    WriteLn('------------------- LOAD FROM STRING -------------------');

    Timer.Reset;
    var Doc := xmlDoc.Create(TestXml1, DefaultParserOptions);
    WriteLn('------------------- SUCCESS (' + Timer.ElapsedMilliseconds.ToString + 'ms) -------------------');
    WriteLn('');

    if Doc = nil then
    begin
      WriteLn('------------------- ERROR -------------------');
      ReadLn;
      Exit;
    end
    else
    begin
      WriteLn('------------------- FORMATTED OUTPUT -------------------');
      Timer.Reset;

      WriteLn(Doc.ToString(True));

      WriteLn('------------------- SUCCESS (' + Timer.ElapsedMilliseconds.ToString + 'ms) -------------------');
      WriteLn('');

      WriteLn('------------------- NON FORMATTED -------------------');
      Timer.Reset;

      WriteLn(Doc.ToString(False));

      WriteLn('------------------- SUCCESS (' + Timer.ElapsedMilliseconds.ToString + 'ms) -------------------');
      WriteLn('');
    end;

    WriteLn('------------------- C14N -------------------');

    Timer.Reset;

    var C14NDoc := Doc.Canonicalize;

    if C14NDoc = nil then
      WriteLn('------------------- ERROR -------------------')
    else
    begin
      WriteLn(C14NDoc.Xml);
      WriteLn('------------------- SUCCESS (' + Timer.ElapsedMilliseconds.ToString + 'ms) -------------------');
      WriteLn('');
    end;

    Doc.Free;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  ReadLn;
end.
