{
  Evaluator of simple location paths: element names separated by `/` and `//`, no
  predicates, no axes, no attributes. It returns the first node of the XPath result in
  document order without building an XPath context.

  The context rules are those of XPath: a relative path (`a/b`) starts at the children of
  the context node, an absolute one (`/a/b`, `//a`) at the document of the context node,
  whatever node the query was issued on.

  One deliberate difference from XPath 1.0: a step without a prefix matches an element
  of that local name in any namespace, and a prefixed step compares the prefix as written
  in the document, not the namespace it is bound to.
}

unit LX2.XPATH;

interface

uses
  System.SysUtils, libxml2.API, LX2.Helpers;

type
  // A step points into the query text and does not own its characters.
  TXPathStep = record
    Descendant: Boolean;
    Name: xmlCharPtr;
    NameLen: NativeInt;
    Prefix: xmlCharPtr;
    PrefixLen: NativeInt;
  end;

  TXPathSteps = TArray<TXPathStep>;

  TXPathQuery = record
  private
    FQuery: Utf8String;
    FAbsolute: Boolean;
    FSteps: TXPathSteps;
    procedure Parse; overload;
    function  Cmp(Node: xmlNodePtr; const Step: TXPathStep): Boolean; inline;
    function  MatchUp(Node, Context: xmlNodePtr; Index, First: NativeInt): Boolean;
    function  SelectFrom(Context: xmlNodePtr; Index: NativeInt): xmlNodePtr;
  public
    class function Parse(const Query: Utf8String): TXPathQuery; overload; static;
    class function IsSimple(const Query: Utf8String): Boolean; static;
    function  Select(Node: xmlNodePtr): xmlNodePtr;
  end;

implementation

{ TXPathQuery }

// A path that ends with `/` (`/` alone selects the document) has no last step to match and is
// left to libxml2 together with everything that is not a plain chain of names.
class function TXPathQuery.IsSimple(const Query: Utf8String): Boolean;
var
  Ch: xmlCharPtr;
begin
  Ch := Pointer(Query);
  if Ch = nil then
    Exit(False);

  while Ch^ <> #0 do
  begin
    if Ch^ in ['(', ')', '[', ']', '<', '>', '{', '}', '*', '+', '.', '|', '@', '=', '?', '$'] then
      Exit(False)
    else if (Ch^ = ':') and ((Ch + 1)^ = ':') then
      Exit(False);

    Inc(Ch);
  end;

  repeat
    Dec(Ch);
  until (Ch = Pointer(Query)) or (Ch^ > #32);
  Result := Ch^ <> '/';
end;

function NameEquals(Value, Name: xmlCharPtr; NameLen: NativeInt): Boolean; inline;
begin
  if Value = nil then
    Exit(False);

  for var I := 0 to NameLen - 1 do
    if Value[I] <> Name[I] then
      Exit(False);
  Result := Value[NameLen] = #0;
end;

// Only elements can match a step: a document node has no `ns` field at all, and its name is
// nil when the document was parsed from memory.
function TXPathQuery.Cmp(Node: xmlNodePtr; const Step: TXPathStep): Boolean;
begin
  Result := (Node.&type = XML_ELEMENT_NODE) and NameEquals(Node.name, Step.Name, Step.NameLen);
  if Result and (Step.Prefix <> nil) then
    Result := (Node.ns <> nil) and NameEquals(Node.ns.prefix, Step.Prefix, Step.PrefixLen);
end;

class function TXPathQuery.Parse(const Query: Utf8String): TXPathQuery;
begin
  Result.FQuery := Query;
  Result.Parse;
end;

procedure TXPathQuery.Parse;
var
  Cur, Start: xmlCharPtr;
  Step: TXPathStep;
begin
  FSteps := [];
  FAbsolute := False;
  Cur := Pointer(FQuery);
  if Cur = nil then
    Exit;

  while Cur^ <> #0 do
  begin
    while (Cur^ <= #32) and (Cur^ <> #0) do
      Inc(Cur);
    if Cur^ = #0 then
      Break;

    Step.Descendant := False;
    if Cur^ = '/' then
    begin
      if Length(FSteps) = 0 then
        FAbsolute := True;
      Inc(Cur);
      if Cur^ = '/' then
      begin
        Inc(Cur);
        Step.Descendant := True;
      end;
      while (Cur^ <= #32) and (Cur^ <> #0) do
        Inc(Cur);
    end;

    // Bytes of a multibyte UTF-8 character are all above #127, so a byte-wise scan never
    // stops inside one.
    Start := Cur;
    Step.Prefix := nil;
    Step.PrefixLen := 0;
    while (Cur^ > #32) and (Cur^ <> '/') do
    begin
      if (Cur^ = ':') and (Step.Prefix = nil) then
      begin
        Step.Prefix := Start;
        Step.PrefixLen := Cur - Start;
        Start := Cur + 1;
      end;
      Inc(Cur);
    end;
    Step.Name := Start;
    Step.NameLen := Cur - Start;
    FSteps := FSteps + [Step];
  end;
end;

function TXPathQuery.Select(Node: xmlNodePtr): xmlNodePtr;
begin
  if (Node = nil) or (Length(FSteps) = 0) then
    Exit(nil);

  if FAbsolute and not (Node.&type in [XML_DOCUMENT_NODE, XML_HTML_DOCUMENT_NODE]) then
  begin
    Node := xmlNodePtr(Node.doc);
    if Node = nil then
      Exit(nil);
  end;

  Result := SelectFrom(Node, 0);
end;

// Steps up to the first `//` are walked forward over children. From a `//` step on, the
// subtree of Context is scanned in document order and every element that fits the last step
// is checked backwards against its ancestors: that is what makes the answer the first node
// in document order, which a forward search by steps does not give (in
// `<a><a><b/></a><b/></a>` the first `//a/b` is the inner one).
function TXPathQuery.SelectFrom(Context: xmlNodePtr; Index: NativeInt): xmlNodePtr;
begin
  var Last := High(FSteps);

  if not FSteps[Index].Descendant then
  begin
    var Child := Context.FirstElementChild;
    while Child <> nil do
    begin
      if Cmp(Child, FSteps[Index]) then
      begin
        if Index = Last then
          Exit(Child);
        Result := SelectFrom(Child, Index + 1);
        if Result <> nil then
          Exit;
      end;
      Child := Child.NextElementSibling;
    end;
    Exit(nil);
  end;

  var Node := Context.FirstElementChild;
  while Node <> nil do
  begin
    if Cmp(Node, FSteps[Last]) and MatchUp(Node, Context, Last, Index) then
      Exit(Node);

    var Next := Node.FirstElementChild;
    while Next = nil do
    begin
      Next := Node.NextElementSibling;
      if Next <> nil then
        Break;
      Node := Node.parent;
      if (Node = nil) or (Node = Context) then
        Exit(nil);
    end;
    Node := Next;
  end;
  Result := nil;
end;

// Node already fits step Index. Steps First..Index - 1 have to fit its ancestors below
// Context; step First is a `//` step, so any depth under Context suits it.
function TXPathQuery.MatchUp(Node, Context: xmlNodePtr; Index, First: NativeInt): Boolean;
begin
  if Index = First then
    Exit(True);

  var Parent := Node.parent;
  if FSteps[Index].Descendant then
  begin
    while (Parent <> nil) and (Parent <> Context) do
    begin
      if Cmp(Parent, FSteps[Index - 1]) and MatchUp(Parent, Context, Index - 1, First) then
        Exit(True);
      Parent := Parent.parent;
    end;
    Result := False;
  end
  else
    Result := (Parent <> nil) and (Parent <> Context) and Cmp(Parent, FSteps[Index - 1]) and
      MatchUp(Parent, Context, Index - 1, First);
end;

end.
