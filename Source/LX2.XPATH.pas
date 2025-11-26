{
  Simple XPath engine to support expressions that igonores element namespaces.
}

unit LX2.XPATH;

interface

uses
  System.SysUtils, libxml2.API, LX2.Helpers;

type
  PXPathStep = ^TXPathStep;
  TXPathStep = record
    Descendant: Boolean;
    Name: PUTF8Char;
    Prefix: PUTF8Char;
    Selector: PUTF8Char;
    Next: PXPathStep;
    procedure Parse;
  end;

  TXPathSteps = TArray<TXPathStep>;

  TXPathQuery = record
  private
    FQuery: Utf8String;
    FSteps: TXPathSteps;
    procedure Parse; overload;
    function  Cmp(Node: xmlNodePtr; Step: PXPathStep): Boolean; inline;
    function  SelectNode(Node: xmlNodePtr; Step: PXPathStep): xmlNodePtr;
    function  Traverse(Parent: xmlNodePtr; Step: PXPathStep): xmlNodePtr;
    function SelectNodes(Parent: xmlNodePtr; Step: PXPathStep): xmlNodePtr;
  public
    class function Parse(const Query: Utf8String): TXPathQuery; overload; static;
    class function IsSimple(const Query: Utf8String): Boolean; static;
    function Select(Node: xmlNodePtr): xmlNodePtr;
  end;

implementation

{ TXPathQuery }

class function TXPathQuery.IsSimple(const Query: Utf8String): Boolean;
var
  Ch: PUTF8Char;
begin
  Ch := Pointer(Query);
  while Ch^ <> #0 do
  begin
    if Ch^ in ['(', ')', '[', ']', '<', '>', '{', '}', '*', '+', '.', '|', '@', '=', '?', '$'] then
      Exit(False)
    else if (Ch^ = ':') and ((Ch + 1)^ = ':') then
      Exit(False);

    Inc(Ch);
  end;
  Result := True;
end;

function TXPathQuery.Cmp(Node: xmlNodePtr; Step: PXPathStep): Boolean;
begin
  Result := StrComp(Node.name, Step.Name) = 0;
  if Result and (Step.Prefix <> nil) then
    Result := (Node.ns <> nil) and (StrComp(Node.ns.prefix, Step.Prefix) = 0);
end;

class function TXPathQuery.Parse(const Query: Utf8String): TXPathQuery;
begin
  Result.FQuery := Query;
  Result.Parse;
end;

procedure TXPathQuery.Parse;
var
  Cur:  PUTF8Char;
  Step: TXPathStep;
begin
  FSteps := [];
  Cur := Pointer(FQuery);
  while Cur^ <> #0 do
  begin
    while (Cur^ <= #32) and (Cur^ > #0) do
      Inc(Cur);
    if Cur^ = #0 then
      Exit;

    Step.Descendant := False;
    if Cur^ = '/' then
    begin
      Cur^ := #0;
      Inc(Cur);
      if Cur^ = '/' then
      begin
        Cur^ := #0;
        Inc(Cur);
        Step.Descendant := True;
      end;
    end;
    Step.Selector := Cur;
    FSteps := FSteps + [Step];

    while (Cur^ > #32) and (Cur^ <> '/') do
      Inc(Cur);
  end;
  for var I := Low(FSteps) to High(FSteps) - 1 do
  begin
    FSteps[I].Parse;
    FSteps[I].Next := @FSteps[I + 1];
  end;
  FSteps[High(FSteps)].Parse;
  FSteps[High(FSteps)].Next := nil;
end;

function TXPathQuery.Select(Node: xmlNodePtr): xmlNodePtr;
begin
  if Length(FSteps) = 0 then
    Exit(nil);

  Result := SelectNode(Node, @FSteps[0]);
end;

function TXPathQuery.SelectNode(Node: xmlNodePtr; Step: PXPathStep): xmlNodePtr;
begin
  if Step.Descendant then
  begin
    Result := Traverse(Node, Step);
  end
  else
  begin
    if not Cmp(Node, Step) then
      Exit(nil);
    if Step.Next = nil then
      Exit(Node);
    Result := SelectNodes(Node, Step.Next);
  end;
end;

function TXPathQuery.SelectNodes(Parent: xmlNodePtr; Step: PXPathStep): xmlNodePtr;
begin
  if Step.Descendant then
  begin
    Result := Traverse(Parent, Step);
  end
  else
  begin
    var Child := Parent.FirstElementChild;
    while Child <> nil do
    begin
      if Cmp(Child, Step) then
      begin
        if Step.Next = nil then
          Exit(Child);
        Result := SelectNodes(Child, Step.Next);
        if Result <> nil then
          Exit;
      end;
      Child := Child.NextElementSibling;
    end;
    Result := nil;
  end;
end;

function TXPathQuery.Traverse(Parent: xmlNodePtr; Step: PXPathStep): xmlNodePtr;
begin
  var Child := Parent.FirstElementChild;
  while Child <> nil do
  begin
    if Cmp(Child, Step) then
    begin
      if Step.Next = nil then
        Exit(Child);
      Result := SelectNodes(Child, Step.Next);
      if Result <> nil then
        Exit;
    end
    else
    begin
      Result := Traverse(Child, Step);
      if Result <> nil then
        Exit;
    end;

    Child := Child.NextElementSibling;
  end;
  Result := nil;
end;

{ TXPathStep }

procedure TXPathStep.Parse;

  procedure Trim(var S: PUTF8Char);
  begin
    while S^ <= #32 do
      Inc(S);
    var Ch := S;
    while Ch^ <> #0 do
    begin
      if Ch^ <= #32 then
        Ch^ := #0;
      Inc(Ch);
    end;
  end;

begin
  Name := Selector;
  Prefix := nil;
  var P := Selector;
  while P^ <> #0 do
  begin
    if P^ = ':' then
    begin
      Prefix := Selector;
      Name := P + 1;
      P^ := #0;
      Trim(Prefix);
    end;
    Inc(P);
  end;
  Trim(Name);
end;

end.
