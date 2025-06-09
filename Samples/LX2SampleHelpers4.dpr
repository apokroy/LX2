program LX2SampleHelpers4;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  msxmlIntf,
  Winapi.msxml,
  Comobj,
  libxml2.API in '..\Source\libxml2.API.pas',
  libxslt.API in '..\Source\libxslt.API.pas',
  LX2.Helpers in '..\Source\LX2.Helpers.pas',
  LX2.Types in '..\Source\LX2.Types.pas',
  LX2SampleXML in 'LX2SampleXML.pas',
  LXSample.Common in 'LXSample.Common.pas';

const
  defNs = 'http://sample/default';
  tstNs = 'http://sample/test';
var
  node: xmlNodePtr;
begin
   try
    TestStart('LX2 Init');
    LX2Lib.Initialize;
    TestEnd(True);

    TestStart('Create doc');
    var doc := xmlDoc.Create;
    TestEnd(doc <> nil);

    TestStart('Create root');
    var root := doc.CreateElement('root');
    TestEnd(root <> nil);

    TestStart('Set root attribute');
    root.Attribute['greeting'] := 'Hello';
    TestEnd(root.Attribute['greeting'] = 'Hello');

    TestStart('Set default namespace via attribute');
    root.SetAttribute('xmlns', defNs);
    TestEnd(root.ns.href = defNs);

    TestStart('Set namespace via attribute');
    root.SetAttribute('xmlns:tst', tstNs);
    TestEnd(root.ns.href = defNs);

    TestStart('Add child with prefix');
    node := root.AddChild('tst:prefix_child');
    TestEnd(node.ns.href = tstNs);

    TestStart('Add child without ns');
    node := root.AddChild('child');
    TestEnd(node.ns = nil);

    TestStart('AddChild with default ns');
    node := root.AddChildNs('def_child', defNs);
    TestEnd(node.ns.href = defNs);

    TestStart('AddChild with non default ns');
    node := root.AddChildNs('tst_child', tstNs);
    TestEnd(node.ns.href = tstNs);

    TestStart('SetAttributeNs');
    node.SetAttributeNs(defNs, 'defNSwithNonDef', 'value');
    node.SetAttributeNs(tstNs, 'tstNSwithDef', 'value');
    TestEnd(node.ns.href = tstNs);

    TestStart('HasAttribute');
    TestEnd(node.HasAttributeNs(defNs, 'defNSwithNonDef'));

    TestStart('CreateElementNs');
    node := doc.CreateElementNs(tstNs, 'child_ns');
    root.AppendChild(node);
    TestEnd(node.ns.href = tstNs);

    doc.documentElement := root;
    WriteLn(doc.Xml);

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

  WriteLn('Press Enter to exit');
  ReadLn;
end.
