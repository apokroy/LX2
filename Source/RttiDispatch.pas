unit RttiDispatch;



interface

uses
  System.Types, System.TypInfo, System.Rtti, System.SysUtils, System.Variants;

{$region 'COM Stub'}
const
  GUID_NULL: TGUID = '{00000000-0000-0000-0000-000000000000}';

  VT_EMPTY           = 0;   { [V]   [P]  nothing                     }
  VT_NULL            = 1;   { [V]        SQL style Null              }
  VT_I2              = 2;   { [V][T][P]  2 byte signed int           }
  VT_I4              = 3;   { [V][T][P]  4 byte signed int           }
  VT_R4              = 4;   { [V][T][P]  4 byte real                 }
  VT_R8              = 5;   { [V][T][P]  8 byte real                 }
  VT_CY              = 6;   { [V][T][P]  currency                    }
  VT_DATE            = 7;   { [V][T][P]  date                        }
  VT_BSTR            = 8;   { [V][T][P]  binary string               }
  VT_DISPATCH        = 9;   { [V][T]     IDispatch FAR*              }
  VT_ERROR           = 10;  { [V][T]     SCODE                       }
  VT_BOOL            = 11;  { [V][T][P]  True=-1, False=0            }
  VT_VARIANT         = 12;  { [V][T][P]  VARIANT FAR*                }
  VT_UNKNOWN         = 13;  { [V][T]     IUnknown FAR*               }
  VT_DECIMAL         = 14;  { [V][T]   [S]  16 byte fixed point      }
  VT_I1              = 16;  {    [T]     signed char                 }
  VT_UI1             = 17;  {    [T]     unsigned char               }
  VT_UI2             = 18;  {    [T]     unsigned short              }
  VT_UI4             = 19;  {    [T]     unsigned long               }
  VT_I8              = 20;  {    [T][P]  signed 64-bit int           }
  VT_UI8             = 21;  {    [T]     unsigned 64-bit int         }
  VT_INT             = 22;  {    [T]     signed machine int          }
  VT_UINT            = 23;  {    [T]     unsigned machine int        }
  VT_VOID            = 24;  {    [T]     C style void                }
  VT_HRESULT         = 25;  {    [T]                                 }
  VT_PTR             = 26;  {    [T]     pointer type                }
  VT_SAFEARRAY       = 27;  {    [T]     (use VT_ARRAY in VARIANT)   }
  VT_CARRAY          = 28;  {    [T]     C style array               }
  VT_USERDEFINED     = 29;  {    [T]     user defined type          }
  VT_LPSTR           = 30;  {    [T][P]  null terminated string      }
  VT_LPWSTR          = 31;  {    [T][P]  wide null terminated string }
  VT_RECORD          = 36;  { [V]   [P][S]  user defined type        }
  VT_INT_PTR         = 37;  {    [T]     signed machine register size width }
  VT_UINT_PTR        = 38;  {    [T]     unsigned machine register size width }
  VT_FILETIME        = 64;  {       [P]  FILETIME                    }
  VT_BLOB            = 65;  {       [P]  Length prefixed bytes       }
  VT_STREAM          = 66;  {       [P]  Name of the stream follows  }
  VT_STORAGE         = 67;  {       [P]  Name of the storage follows }
  VT_STREAMED_OBJECT = 68;  {       [P]  Stream contains an object   }
  VT_STORED_OBJECT   = 69;  {       [P]  Storage contains an object  }
  VT_BLOB_OBJECT     = 70;  {       [P]  Blob contains an object     }
  VT_CF              = 71;  {       [P]  Clipboard format            }
  VT_CLSID           = 72;  {       [P]  A Class ID                  }
  VT_VERSIONED_STREAM= 73;  {       [P]  Stream with a GUID version  }
  VT_VECTOR        = $1000; {       [P]  simple counted array        }
  VT_ARRAY         = $2000; { [V]        SAFEARRAY*                  }
  VT_BYREF         = $4000; { [V]                                    }
  VT_RESERVED      = $8000;
  VT_ILLEGAL       = $ffff;
  VT_ILLEGALMASKED = $0fff;
  VT_TYPEMASK      = $0fff;

  DISPATCH_METHOD         = $1;
  DISPATCH_PROPERTYGET    = $2;
  DISPATCH_PROPERTYPUT    = $4;
  DISPATCH_PROPERTYPUTREF = $8;
  DISPATCH_CONSTRUCT      = $4000;

  DISPID_PROPERTYPUT = -3;

  DISP_E_MEMBERNOTFOUND = HRESULT($80020003);
  DISP_E_UNKNOWNNAME    = HRESULT($80020006);
  DISP_E_BADPARAMCOUNT  = HRESULT($8002000E);

type
  PDispID = ^TDispID;
  TDispID = Longint;
  POleStr = PWideChar;

  PDispIDList = ^TDispIDList;
  TDispIDList = array[0..65535] of TDispID;

  TMemberID = TDispID;

  PMemberIDList = ^TMemberIDList;
  TMemberIDList = array[0..65535] of TMemberID;

  LONGLONG = Int64;
  {$EXTERNALSYM LONGLONG}

  {$EXTERNALSYM TOleDate}
  TOleDate = Double;
  POleDate = ^TOleDate;

  {$EXTERNALSYM TOleBool}
  TOleBool = WordBool;
  POleBool = ^TOleBool;

  PSafeArrayBound = ^TSafeArrayBound;
  {$EXTERNALSYM tagSAFEARRAYBOUND}
  tagSAFEARRAYBOUND = record
    cElements: LongWord;
    lLbound: Longint;
  end;
  TSafeArrayBound = tagSAFEARRAYBOUND;
  {$EXTERNALSYM SAFEARRAYBOUND}
  SAFEARRAYBOUND = TSafeArrayBound;

  PSafeArray = ^TSafeArray;
  {$EXTERNALSYM tagSAFEARRAY}
  tagSAFEARRAY = record
    cDims: Word;
    fFeatures: Word;
    cbElements: LongWord;
    cLocks: LongWord;
    pvData: Pointer;
    rgsabound: array[0..0] of TSafeArrayBound;
  end;
  TSafeArray = tagSAFEARRAY;
  {$EXTERNALSYM SAFEARRAY}
  SAFEARRAY = TSafeArray;

{$ALIGN 1}
  PDecimal = ^TDecimal;
  {$EXTERNALSYM tagDEC}
  tagDEC = record
    wReserved: Word;
    case Integer of
      0: (scale, sign: Byte; Hi32: Longint;
      case Integer of
        0: (Lo32, Mid32: Longint);
        1: (Lo64: LONGLONG));
      1: (signscale: Word);
  end;
  TDecimal = tagDEC;
  {$EXTERNALSYM DECIMAL}
  DECIMAL = TDecimal;
{$ALIGN ON}

  PVariantArg = ^TVariantArg;
  {$EXTERNALSYM tagVARIANT}
  tagVARIANT = record
    vt: TVarType;
    wReserved1: Word;
    wReserved2: Word;
    wReserved3: Word;
    case Integer of
      VT_UI1:                  (bVal: Byte);
      VT_I2:                   (iVal: Smallint);
      VT_I4:                   (lVal: Longint);
      VT_R4:                   (fltVal: Single);
      VT_R8:                   (dblVal: Double);
      VT_BOOL:                 (vbool: TOleBool);
      VT_ERROR:                (scode: HResult);
      VT_CY:                   (cyVal: Currency);
      VT_DATE:                 (date: TOleDate);
      VT_BSTR:                 (bstrVal: PWideChar{WideString});
      VT_UNKNOWN:              (unkVal: Pointer{IUnknown});
      VT_DISPATCH:             (dispVal: Pointer{IDispatch});
      VT_ARRAY:                (parray: PSafeArray);
      VT_BYREF or VT_UI1:      (pbVal: ^Byte);
      VT_BYREF or VT_I2:       (piVal: ^Smallint);
      VT_BYREF or VT_I4:       (plVal: ^Longint);
      VT_BYREF or VT_R4:       (pfltVal: ^Single);
      VT_BYREF or VT_R8:       (pdblVal: ^Double);
      VT_BYREF or VT_BOOL:     (pbool: ^TOleBool);
      VT_BYREF or VT_ERROR:    (pscode: ^HResult);
      VT_BYREF or VT_CY:       (pcyVal: ^Currency);
      VT_BYREF or VT_DATE:     (pdate: ^TOleDate);
      VT_BYREF or VT_BSTR:     (pbstrVal: ^WideString);
      VT_BYREF or VT_UNKNOWN:  (punkVal: ^IUnknown);
      VT_BYREF or VT_DISPATCH: (pdispVal: ^IDispatch);
      VT_BYREF or VT_ARRAY:    (pparray: ^PSafeArray);
      VT_BYREF or VT_VARIANT:  (pvarVal: PVariant);
      VT_BYREF:                (byRef: Pointer);
      VT_I1:                   (cVal: AnsiChar);
      VT_UI2:                  (uiVal: Word);
      VT_UI4:                  (ulVal: LongWord);
      VT_I8:                   (llVal : Int64);
      VT_UI8:                  (ullVal : UInt64);
      VT_INT:                  (intVal: Integer);
      VT_UINT:                 (uintVal: LongWord);
      VT_BYREF or VT_DECIMAL:  (pdecVal: PDecimal);
      VT_BYREF or VT_I1:       (pcVal: PAnsiChar);
      VT_BYREF or VT_UI2:      (puiVal: PWord);
      VT_BYREF or VT_UI4:      (pulVal: PInteger);
      VT_BYREF or VT_INT:      (pintVal: PInteger);
      VT_BYREF or VT_UINT:     (puintVal: PLongWord);
      VT_BYREF or VT_I8:       (pllVal : ^Int64);
      VT_BYREF or VT_UI8:      (pullVal : ^UInt64);
      VT_RECORD:               (pvRecord : Pointer;
                                pRecInfo : Pointer);
  end;

  TVariantArg = tagVARIANT;
  PVariantArgList = ^TVariantArgList;
  TVariantArgList = array[0..65535] of TVariantArg;

  PDispParams = ^TDispParams;
  TDispParams = record
    rgvarg: PVariantArgList;
    rgdispidNamedArgs: PDispIDList;
    cArgs: Longint;
    cNamedArgs: Longint;
  end;

  PExcepInfo = ^TExcepInfo;

  TFNDeferredFillIn = function(ExInfo: PExcepInfo): HResult stdcall;

  TExcepInfo = record
    wCode: Word;
    wReserved: Word;
    bstrSource: WideString;
    bstrDescription: WideString;
    bstrHelpFile: WideString;
    dwHelpContext: Longint;
    pvReserved: Pointer;
    pfnDeferredFillIn: TFNDeferredFillIn;
    scode: HResult;
  end;

{$endregion}

{$M+}
  IDispatchInvokable = interface(IDispatch)
    ['{31BC8AB1-DD02-46FA-8CAA-E436F355C866}']
  end;

  TDispatchInvokable = class(TInterfacedObject, IDispatch, IDispatchInvokable)
  protected type
    TRttiInfo = record
      Name: string;
      Method: TRttiMethod;
      Prop: TRttiProperty;
      IndexedProp: TRttiIndexedProperty;
    end;

    PClassRtti = ^TClassRtti;
    TClassRtti = record
      ClassType: TClass;
      Members: TArray<TRttiInfo>;
      Next: PClassRtti;
    end;

    class var RttiContext: TRttiContext;
    class var RttiList: PClassRtti;
    class var RttiLock: TObject;
    class constructor Create;
    class destructor Destroy;
  protected
    Rtti: PClassRtti;
  protected
    procedure InitRtti;
  protected
    function  GetTypeInfoCount(out Count: Integer): HResult; stdcall;
    function  GetTypeInfo(Index, LocaleID: Integer; out TypeInfo): HResult; stdcall;
    function  GetIDsOfNames(const IID: TGUID; Names: Pointer; NameCount, LocaleID: Integer; DispIDs: Pointer): HResult; stdcall;
    function  Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer; Flags: Word; var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult; stdcall;
  end;
{$M-}

resourcestring
  SVarNotObject = 'Variant does not reference an dispatch object';
  SNoMethod = 'Method ''%s'' not supported by dispatch object';

implementation

uses
  System.AnsiStrings;

function ValueFromVariant(const Value: TVarData; const Typ: TRttiType): TValue;
begin
  case Value.VType of
    varEmpty:    Result := TValue.From<Variant>(Unassigned);
    varNull:     Result := TValue.From<Variant>(Null);
    varBoolean:  Result := Value.VBoolean;
    varShortInt: Result := TValue.From(Value.VShortInt);
    varSmallint: Result := TValue.From(Value.VSmallInt);
    varInteger:  Result := TValue.From(Value.VInteger);
    varSingle:   Result := Value.VSingle;
    varDouble:   Result := Value.VDouble;
    varCurrency: Result := Value.VCurrency;
    varDate:     Result := TValue.From<TDateTime>(Value.VDate);
    varOleStr:   Result := TValue.From<WideString>(WideString(Pointer(Value.VOleStr)));
    varDispatch: Result := TValue.From<IDispatch>(IDispatch(Value.VDispatch));
    varError:    Result := TValue.From<HRESULT>(Value.VError);
    varUnknown:  Result := TValue.From<IInterface>(IInterface(Value.VUnknown));
    varByte:     Result := TValue.From(Value.VByte);
    varWord:     Result := TValue.From(Value.VWord);
    varUInt32:   Result := TValue.From(Value.VUInt32);
    varInt64:    Result := Value.VInt64;
    varUInt64:   Result := Value.VUInt64;
    varString:   Result := TValue.From<RawByteString>(RawByteString(Value.VString));
    varUString:  Result := UnicodeString(Value.VUString);

    varByRef or varEmpty:    Result := TValue.From<Variant>(Unassigned);
    varByRef or varNull:     Result := TValue.From<Variant>(Null);
    varByRef or varBoolean:  Result := PBoolean(Value.VPointer)^;
    varByRef or varShortInt: Result := TValue.From(PShortInt(Value.VPointer)^);
    varByRef or varSmallint: Result := TValue.From(PSmallInt(Value.VPointer)^);
    varByRef or varInteger:  Result := TValue.From(PInteger(Value.VPointer)^);
    varByRef or varSingle:   Result := PSingle(Value.VPointer)^;
    varByRef or varDouble:   Result := PDouble(Value.VPointer)^;
    varByRef or varCurrency: Result := PCurrency(Value.VPointer)^;
    varByRef or varDate:     Result := TValue.From<TDateTime>(PDateTime(Value.VPointer)^);
    varByRef or varOleStr:   Result := TValue.From<WideString>(WideString(Pointer(Value.VPointer^)));
    varByRef or varDispatch: Result := TValue.From<IDispatch>(IDispatch(Value.VPointer^));
    varByRef or varError:    Result := TValue.From<HRESULT>(PInteger(Value.VPointer)^);
    varByRef or varUnknown:  Result := TValue.From<IInterface>(IInterface(Pointer(Value.VPointer^)));
    varByRef or varByte:     Result := TValue.From(PByte(Value.VPointer)^);
    varByRef or varWord:     Result := TValue.From(PWord(Value.VPointer)^);
    varByRef or varUInt32:   Result := TValue.From(PCardinal(Value.VPointer)^);
    varByRef or varInt64:    Result := PInt64(Value.VPointer)^;
    varByRef or varUInt64:   Result := PUInt64(Value.VPointer)^;
    varByRef or varString:   Result := TValue.From<RawByteString>(RawByteString(Pointer(Value.VPointer^)));
    varByRef or varUString:  Result := UnicodeString(Pointer(Value.VPointer^));
  end;
  Result := Result.Cast(Typ.Handle);
end;

{ TDispatchInvokable }

class constructor TDispatchInvokable.Create;
begin
  RttiContext := TRttiContext.Create;
  RttiList := nil;
  RttiLock := TObject.Create;
end;

class destructor TDispatchInvokable.Destroy;
begin
  var Rtti := RttiList;
  RttiList := nil;
  while Rtti <> nil do
  begin
    var Temp := Rtti;
    Rtti := Rtti.Next;
    Finalize(Temp^);
    FreeMem(Temp);
  end;
  FreeAndNil(RttiLock);
end;

procedure TDispatchInvokable.InitRtti;
var
  Info: TRttiInfo;
begin
  if Rtti <> nil then
    Exit;

  TMonitor.Enter(RttiLock);
  try
    Rtti := RttiList;
    while Rtti <> nil do
    begin
      if Rtti.ClassType = ClassType then
        Break;
      Rtti := Rtti.Next;
    end;

    if Rtti = nil then
    begin
      GetMem(Rtti, SizeOf(Rtti^));
      Initialize(Rtti^);
      Rtti.ClassType := ClassType;
      Rtti.Next := RttiList;
      RttiList := Rtti;
    end;

    var Typ := RttiContext.GetType(ClassType) as TRttiInstanceType;
    var Intrfs := Typ.GetImplementedInterfaces;
    for var I := Low(Intrfs) to High(Intrfs) do
    begin
      var Methods := Intrfs[I].GetDeclaredMethods;
      for var Method in Methods do
      begin
        Info.Name := Method.Name;
        Info.Method := Typ.GetMethod(Method.Name);
        Info.Prop := nil;
        Info.IndexedProp := nil;
        Rtti.Members := Rtti.Members + [Info];
      end;
    end;

    while Typ <> nil do
    begin
      var Props := Typ.GetDeclaredProperties;
      for var Prop in Props do
      begin
        Info.Name := Prop.Name;
        Info.Method := nil;
        Info.IndexedProp := nil;
        Info.Prop := Prop;
        Rtti.Members := Rtti.Members + [Info];
      end;

      var IndexedProps := Typ.GetDeclaredIndexedProperties;
      for var Prop in IndexedProps do
      begin
        Info.Name := Prop.Name;
        Info.Method := nil;
        Info.Prop := nil;
        Info.IndexedProp := Prop;
        Rtti.Members := Rtti.Members + [Info];
      end;

      Typ := Typ.BaseType;
    end;
  finally
    TMonitor.Exit(RttiLock);
  end;
end;

function TDispatchInvokable.GetTypeInfo(Index, LocaleID: Integer; out TypeInfo): HResult;
begin
  Result := E_NOTIMPL;
end;

function TDispatchInvokable.GetTypeInfoCount(out Count: Integer): HResult;
begin
  Count := 0;
  Result := S_OK;
end;

function TDispatchInvokable.GetIDsOfNames(const IID: TGUID; Names: Pointer; NameCount, LocaleID: Integer; DispIDs: Pointer): HResult;
var
  Name: PWideString absolute Names;
  Index: PDispID absolute DispIDs;
begin
  InitRtti;
  for var I := Low(Rtti.Members) to High(Rtti.Members) do
    if AnsiSameText(Rtti.Members[I].Name, string(Name^)) then
    begin
      Index^ := I;
      Exit(S_OK);
    end;
  Result := DISP_E_MEMBERNOTFOUND;
end;

function TDispatchInvokable.Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer; Flags: Word; var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult;
type
  PArgs = ^TArgs;
  TArgs = array[0..65535] of Variant;
var
  DispParams: TDispParams absolute Params;
  Res: PVariant absolute VarResult;
  Args: TArray<TValue>;
  Method: TRttiMethod;
  Info: TRttiInfo;
  Disp: Pointer;
begin
  Info := Rtti.Members[DispID];

  Method := nil;
  if Flags and (DISPATCH_PROPERTYPUT or DISPATCH_PROPERTYPUTREF) <> 0 then
  begin
    if Info.Prop <> nil then
    begin
      Info.Prop.SetValue(Self, ValueFromVariant(TVarData(DispParams.rgvarg[0]), Info.Prop.PropertyType));
      Exit(S_OK);
    end;

    if Info.IndexedProp <> nil then
      Method := Info.IndexedProp.WriteMethod
    else
      Method := nil;
  end
  else if (Flags and DISPATCH_PROPERTYGET) <> 0 then
  begin
    if Info.Prop <> nil then
    begin
      Res^ := Info.Prop.GetValue(Self).AsVariant;
      Exit(S_OK);
    end;

    if Info.IndexedProp <> nil then
      Method := Info.IndexedProp.ReadMethod
    else if (Flags and DISPATCH_METHOD) <> 0 then
      Method := Info.Method
    else
      Method := nil;
  end
  else if Info.Method = nil then
  begin
    if Info.Prop <> nil then
    begin
      var Value := Info.Prop.GetValue(Self);
      if Res <> nil then
        Res^ := Value.AsVariant;
    end
    else if Info.IndexedProp <> nil then
      Method := Info.IndexedProp.ReadMethod
    else
      Method := nil;
  end
  else
    Method := Info.Method;

  if Method = nil then
  begin
    PExcepInfo(ExcepInfo).bstrSource := 'RTTI Invoke';
    PExcepInfo(ExcepInfo).bstrDescription := 'Method not found';
    Exit(DISP_E_MEMBERNOTFOUND);
  end;

  var Pars := Method.GetParameters;
  if Length(Pars) <> DispParams.cArgs then
  begin
    PExcepInfo(ExcepInfo).bstrSource := 'RTTI Invoke';
    PExcepInfo(ExcepInfo).bstrDescription := 'Wrong parameter count for ' + Method.Name;
    Exit(DISP_E_BADPARAMCOUNT);
  end;

  SetLength(Args, DispParams.cArgs);
  for var I := 0 to DispParams.cArgs - 1 do
    Args[I] := ValueFromVariant(TVarData(DispParams.rgvarg[DispParams.cArgs - I - 1]), Pars[I].ParamType);

  var Value := Method.Invoke(Self, Args);
  if Res <> nil then
  begin
    Res^ := Value.AsVariant;
    if PVarData(Res).VType = varUnknown then
    begin
      if Supports(IUnknown(PVarData(Res).VUnknown), IDispatch, Disp) then
        Res^ := IDispatch(Disp);
    end
    else if PVarData(Res).VType = (varUnknown or varByRef) then
    begin
      if Supports(IUnknown(PVarData(Res).VPointer^), IDispatch, Disp) then
        Res^ := IDispatch(Disp);
    end;
  end;

  for var I := 0 to DispParams.cArgs - 1 do
    Variant(TVarData(DispParams.rgvarg[I])) := Args[DispParams.cArgs - I - 1].AsVariant;

  Result := S_OK;
end;

procedure GetIDsOfNames(const Dispatch: IDispatch; Names: PAnsiChar; NameCount: Integer; DispIDs: PDispIDList); overload;
var
  WideNames: array of WideString;
  I: Integer;
  Src: PAnsiChar;
  Temp: HResult;
begin
  SetLength(WideNames, NameCount);
  Src := Names;
  for I := 0 to NameCount-1 do
  begin
    if I = 0 then
      WideNames[I] := UTF8ToWideString(Src)
    else
      WideNames[NameCount-I] := UTF8ToWideString(Src);
    Inc(Src, System.AnsiStrings.StrLen(Src)+1);
  end;
  Temp := Dispatch.GetIDsOfNames(GUID_NULL, WideNames, NameCount, 0, DispIDs);
  if Temp = Integer(DISP_E_MEMBERNOTFOUND) then
    raise Exception.CreateResFmt(@SNoMethod, [Names]);
end;

procedure DispatchInvoke(const Dispatch: IDispatch; CallDesc: PCallDesc; DispIDs: PDispIDList; Params: Pointer; Result: PVariant);
var
  I, DispID, InvKind, LArgCount: Integer;
  DispParams: TDispParams;
  ExcepInfo: TExcepInfo;
  VarParams: TVarDataArray;
  Status: HRESULT;
  Strings: TStringRefList;
begin
  LArgCount := CallDesc^.ArgCount;
  if LArgCount > 0 then
  begin
    SetLength(Strings, LArgCount);
    VarParams := GetDispatchInvokeArgs(CallDesc, Params, Strings, false);
  end;
  try
    DispParams.cArgs := LArgCount;
    if LArgCount > 0 then
      DispParams.rgvarg := @VarParams[0]
    else
      DispParams.rgvarg := nil;
    if CallDesc^.NamedArgCount > 0 then
      DispParams.rgdispidNamedArgs := @DispIDs[1]
    else
      DispParams.rgdispidNamedArgs := nil;
    DispParams.cNamedArgs := CallDesc^.NamedArgCount;
    DispID := DispIDs[0];
    InvKind := CallDesc^.CallType;
    if InvKind = DISPATCH_PROPERTYPUT then
    begin
      if ((VarParams[0].VType and varTypeMask) = varDispatch) or
          ((VarParams[0].VType and varTypeMask) = varUnknown) then
        InvKind := DISPATCH_PROPERTYPUTREF or DISPATCH_PROPERTYPUT;
      DispIDs[0] := DISPID_PROPERTYPUT;
      DispParams.rgdispidNamedArgs := @DispIDs[0];
      Inc(DispParams.cNamedArgs);
    end
    else if (InvKind = DISPATCH_METHOD) and (CallDesc^.ArgCount = 0) and (Result <> nil) then
        InvKind := DISPATCH_METHOD or DISPATCH_PROPERTYGET
    else if (InvKind = DISPATCH_PROPERTYGET) and (CallDesc^.ArgCount <> 0) then
        InvKind := DISPATCH_METHOD or DISPATCH_PROPERTYGET;

    FillChar(ExcepInfo, SizeOf(ExcepInfo), 0);
    Status := Dispatch.Invoke(DispID, GUID_NULL, 0, InvKind, DispParams,
                              Result, @ExcepInfo, nil);
    if Status <> 0 then
      raise Exception.Create(ExcepInfo.bstrDescription);
  finally
    FinalizeDispatchInvokeArgs(CallDesc, VarParams, false);
  end;

  for I := 0 to Length(Strings) -1 do
  begin
    if Pointer(Strings[I].Wide) = nil then
      Break;
    if Strings[I].Ansi <> nil then
      Strings[I].Ansi^ := AnsiString(Strings[I].Wide)
    else if Strings[I].Unicode <> nil then
      Strings[I].Unicode^ := UnicodeString(Strings[I].Wide)
  end;
end;

procedure DispProc(Result: PVariant; const Instance: Variant; CallDesc: PCallDesc; Params: Pointer); cdecl;

  procedure RaiseException;
  begin
    raise Exception.CreateRes(@SVarNotObject);
  end;

var
  Dispatch: Pointer;
  DispIDs: array[0..MaxDispArgs - 1] of Integer;
begin
  if TVarData(Instance).VType = varDispatch then
    Dispatch := TVarData(Instance).VDispatch
  else if TVarData(Instance).VType = (varDispatch or varByRef) then
    Dispatch := Pointer(TVarData(Instance).VPointer^)
  else if TVarData(Instance).VType = varUnknown then
  begin
    if not Supports(IUnknown(TVarData(Instance).VUnknown), IDispatch, Dispatch) then
      RaiseException;
  end
  else if TVarData(Instance).VType = (varUnknown or varByRef) then
  begin
    if not Supports(IUnknown(Pointer(TVarData(Instance).VUnknown^)), IDispatch, Dispatch) then
      RaiseException;
  end
  else
    RaiseException;

  GetIDsOfNames(IDispatch(Dispatch), PAnsiChar(@CallDesc^.ArgTypes[CallDesc^.ArgCount]), CallDesc^.NamedArgCount + 1, @DispIDs);
  if Result <> nil then VarClear(Result^);
  DispatchInvoke(IDispatch(Dispatch), CallDesc, @DispIDs, Params, Result);
end;

function PeekU8(P: PByte): Byte; inline;
begin
  Result := PByte(P)^;
end;

function ReadU8(var P: PByte): Byte; inline;
begin
  Result := PeekU8(P);
  Inc(P, SizeOf(Result));
end;

function ReadShortString(var P: PByte): string;
var
  len: Integer;
begin
  Result := UTF8IdentToString(PShortString(P));
  len := ReadU8(P);
  Inc(P, len);
end;

function UnitExists(const Name: string): Boolean;
begin
  var M := LibModuleList;
  while M <> nil do
  begin
    var P := PByte(M.TypeInfo.UnitNames);
    for var I := 0 to M.TypeInfo.UnitCount - 1 do
    begin
      var UnitName := ReadShortString(P);
      if UnitName = Name then
        Exit(True);
    end;
    M := M.Next;
  end;
  Result := False;
end;

initialization
  if not UnitExists('System.Win.ComObj') then
    VarDispProc := DispProc;
end.
