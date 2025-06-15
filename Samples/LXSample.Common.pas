unit LXSample.Common;

interface

uses
  System.SysUtils,
  System.Diagnostics;

procedure TestStart(const Name: string);
function  TestEnd(Success: Boolean): Boolean;
procedure StartTests;
procedure EndTests;

implementation

uses
  libxml2.API, libxslt.API;

var
  Timer: TStopwatch;
  MemUsedBefore: NativeUInt;

procedure StartTests;
begin
  TestStart('LX2 Init');
  LX2Lib.Initialize;
  XSLTLib.Initialize;
  TestEnd(True);



  MemUsedBefore := xmlMemUsed;
end;

procedure EndTests;
begin
  TestStart('Memory leak');
  if xmlMemUsed > MemUsedBefore then
  begin
    Write('Mem used: ');
    WriteLn(xmlMemUsed);
    Write('Mem leaked: ');
    WriteLn(xmlMemUsed - MemUsedBefore);
    TestEnd(False);
  end
  else
    TestEnd(True);

  WriteLn('Cleanup libxml...');
  xmlCleanupParser;
  WriteLn('Cleanup libxslt...');
  xsltCleanupGlobals;
  Write('Mem used: ');
  WriteLn(xmlMemUsed);
end;

procedure TestOut(const S: string);
const
  LineLen = 80;
begin
  var L := LineLen - Length(S);
  if L > 1 then
  begin
    if Odd(L) then
    begin
      Write(string.Create('-', L div 2));
      Write(S);
      Write(' ');
      WriteLn(string.Create('-', L div 2));
    end
    else
    begin
      Write(string.Create('-', L div 2));
      Write(S);
      WriteLn(string.Create('-', L div 2));
    end;
  end
  else
    WriteLn(S);
end;

procedure TestStart(const Name: string);
begin
  TestOut(Name);
  Timer := TStopwatch.StartNew;
end;

function  TestEnd(Success: Boolean): Boolean;
begin
  Timer.Stop;

  if Success then
    TestOut('SUCCESS (' + Timer.ElapsedMilliseconds.ToString + 'ms)')
  else
    TestOut('ERROR');

  WriteLn;

  Result := Success;
end;

end.
