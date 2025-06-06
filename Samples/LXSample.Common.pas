unit LXSample.Common;

interface

uses
  System.SysUtils,
  System.Diagnostics;

procedure TestStart(const Name: string);
procedure TestEnd(Success: Boolean);

implementation

var
  Timer: TStopwatch;

procedure TestOut(const S: string);
const
  LineLen = 60;
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

procedure TestEnd(Success: Boolean);
begin
  Timer.Stop;

  if Success then
    TestOut('SUCCESS (' + Timer.ElapsedMilliseconds.ToString + 'ms)')
  else
    TestOut('ERROR');

  WriteLn;
end;

end.
