program LX2SampleSAX1;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  {$IFDEF MSWINDOWS}
  FastMM4,
  {$ENDIF }
  System.SysUtils,
  libxml2.API in '..\Source\libxml2.API.pas',
  libxslt.API in '..\Source\libxslt.API.pas',
  LX2.SAX in '..\Source\LX2.SAX.pas',
  LX2.Types in '..\Source\LX2.Types.pas',
  LX2SampleXML in 'LX2SampleXML.pas',
  LXSample.Common in 'LXSample.Common.pas',
  RttiDispatch in '..\Source\RttiDispatch.pas';

type
  TSAXConsoleHandler = class(TSAXCustomContentHandler)
  private
    Indent: Integer;
    procedure WriteIndent;
  public
    procedure StartDocument; override;
    procedure EndDocument; override;
    procedure StartElement(const LocalName, Prefix, URI: string; const Namespaces: TSAXNamespaces; const Attributes: TSAXAttributes); override;
    procedure EndElement(const LocalName, Prefix, URI: string); override;
    procedure Characters(const Chars: string); override;
    procedure IgnorableWhitespace(const Chars: string); override;
    procedure ProcessingInstruction(const Target, Data: string); override;
  end;

{ TSAXConsoleHandler }

procedure TSAXConsoleHandler.Characters(const Chars: string);
begin
  WriteIndent;
  Write('- Chars: "');
  Write(Chars);
  WriteLn('"');
end;

procedure TSAXConsoleHandler.EndDocument;
begin
  Dec(Indent);
  WriteIndent;
  WriteLn('- End');
end;

procedure TSAXConsoleHandler.EndElement(const LocalName, Prefix, URI: string);
begin
  Dec(Indent);
  WriteIndent;
  Write('- End element: ');
  Write(LocalName);
  if Prefix <> '' then
  begin
    Write('  ');
    Write('Prefix: ' + Prefix);
  end;
  if URI <> '' then
  begin
    Write('  ');
    Write('URI: ' + URI);
  end;
  WriteLn;
end;

procedure TSAXConsoleHandler.IgnorableWhitespace(const Chars: string);
begin
  WriteIndent;
  Write('- IgnorableWhitespace: ');
  WriteLn(Chars);
end;

procedure TSAXConsoleHandler.ProcessingInstruction(const Target, Data: string);
begin
  WriteIndent;
  Write('- ProcessingInstruction Target: ');
  Write(Target);
  Write('  ');
  Write('Data:');
  WriteLn(Data);
end;

procedure TSAXConsoleHandler.StartDocument;
begin
  WriteIndent;
  WriteLn('- Start');
  Inc(Indent);
end;

procedure TSAXConsoleHandler.StartElement(const LocalName, Prefix, URI: string; const Namespaces: TSAXNamespaces; const Attributes: TSAXAttributes);
begin
  WriteIndent;
  Write('- Start element: ');
  Write(LocalName);
  if Prefix <> '' then
  begin
    Write('  ');
    Write('Prefix: ' + Prefix);
  end;
  if URI <> '' then
  begin
    Write('  ');
    WriteLn('URI: ' + URI);
  end;
  Inc(Indent);

  if Length(Namespaces) > 0 then
  begin
    WriteLn;
    Inc(Indent);
    WriteIndent;
    WriteLn('Namespaces:');
    for var Ns in Namespaces do
    begin
      WriteIndent;
      Write(Ns.Prefix);
      Write(': ');
      WriteLn(Ns.URI);
    end;
    Dec(Indent);
  end;

  if Length(Attributes) > 0 then
  begin
    WriteLn;
    Inc(Indent);
    WriteIndent;
    WriteLn('Attributes:');
    for var Attr in Attributes do
    begin
      WriteIndent;
      if Attr.Prefix <> '' then
      begin
        Write(Attr.Prefix);
        Write(':');
      end;
      Write(Attr.Name);
      if Attr.URI <> '' then
      begin
          Write(' URI: ');
        Write(Attr.URI);
      end;
      Write('  "');
      Write(Attr.Value);
      WriteLn('"');
    end;
    Dec(Indent);
  end
  else
    WriteLn;
end;

procedure TSAXConsoleHandler.WriteIndent;
begin
  Write(string.Create(#32, Indent * 2));
end;

procedure Test;
begin
  TestStart('SAX Parser');

  var Parser := TSAXParser.Create;
  try
    Parser.Handler := TSAXConsoleHandler.Create;
    Parser.PreserveWhitespaces := False;

    if not TestEnd(Parser.Parse(TestXml1)) then
    begin
      for var Error in Parser.Errors do
      begin
        Write(Error.Code);
        Write('  ');
        Write(Error.Text);
        Write('  ');
        Write(Error.Url);
        Write('  ');
        Write(Error.Line);
        Write('  ');
        Write(Error.Col);
        WriteLn;
      end;
    end;
    WriteLn;
  finally
    Parser.Free;
  end;
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
