{
  Copyright (C) 2013-2016 Tim Sinaeve tim.sinaeve@gmail.com

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
}

unit DDuce.DynamicRecord;

{$I DDuce.inc}

interface

uses
  System.SysUtils, System.Classes, System.Rtti,
  Data.DB;

{$REGION 'Documentation'}
{
  TRecord is a custom record type holding dynamically typed fields.
  It consosts of a set of key-value pairs which can be assigned from/to any
  object or record instance. In that respect it behaves more or less than a
  dynamic associative array commonly found in dynamically typed languages (e.g.
  tables in Lua and lists in Python).
  Extended RTTI is used to map the object or record properties to the field
  values of the record.

  TERMINOLOGY
    The name TRecord was chosen because it behaves as native pascal records when
    assigned to eachother. Rather than copying the reference (like classes and
    class interfaces) the data is copied.
    When assigning two TRecord variables to eachother the data is always copied
    as witch native record variables.
    A TRecord instance manages its own data (creation and destruction).

    If you rather have a reference to a set of values, you can use the
    IDynamicRecord interface, which is assignment compatible with TRecord
    variables. Mixed TRecord and IDynamicRecord assignments always result in
    a copy of the contained data.

  MAIN FEATURES:
    - No instrumentation code. Direct field access is possible.
    - No field initialisation required.
    - No boilerplate code. No Create/Try/Finally/Free blocks needed as
      memory management is done behind the scenes.
    - Easy assignment from and to object/record properties as well as other
      TRecord instances using dedicated 'From' methods.
    - Enumeration support (so we can use it in "for..in" statements) in D2006+
      thanks to IEnumerable support (TRecordEnumerator).
      Example:
        var
          R: TRecord;
          F: IDynamicField;
        begin
          R['First'] := 1;
          R['Second'] := 2;
          for F in R do
          begin
            ...
          end;
        end;
    - Delphi's TValue type is used as a typed value (with no unwanted implicit
      conversions like with Variant values). Once a value is assigned, the type
      of the value is fixed.
    - ToString/ToFloat/ToInteger/ToBoolean members can be used to force
      conversion into a specific target type, with the possiblity to pass a
      default value to return when conversion fails. Do note that the .As<type>
      members of TValue do not convert the type of the value.

    - The data can be accessed as a Variant (like field values of a dataset)
      through the Data member which is a custom variant type designed to
      access the field names through dynamic invocation. This means that fields
      can be accessed as they were declared as properties of type Variant.
    - The current record of a TDataSet can be assigned using one statement
      (FromDataSet).
    - Supports assignment from/to stringlists with key/value pairs (FromStrings/
      ToStrings).
    - AsDelimitedText/AsCommaText/AsVarArray methods.
    - A debug visualizer is available that shows the content of the record while
      debugging in the IDE.

  TRecord<T> allows typed access to contained data. In that respect it behaves
  as a managed object wrapper while remaining compatible with the basic
  instance type.
    - TRecord<T> can be assigned to T, but only if T was created. It will copy
      the values rather than exposing and assigning the reference.
    - The Data property is of type T.
    - The generic version does automatic instantiation of objects of type T.
    - A TRecord<T> instance is assignment compatible with TRecord,
      IDynamicRecord<T> and IDynamicRecord variables.
    - Does the same as Scoped instances

  Future enhancements:
    - TRecord<T>: add overloaded constructor with factory method (TFunc<T>).
      This allows more customized autoconstruction.
    - Add more events
    - Control/data binding support
    - track changes

  Remarks:
    - To be able to compile the generic version it was necessary to move some of
      the internal types from the implementation section to the interface
      section of the unit.

    - Interface types are now compiled with extra RTTI (IInvokable/$M+ compiler
      directive)

  References:
    To make TRecord really behave as a proper value type, there had to be a
    way to implement this copy on write behaviour (COW) on the managed
    interface variable (IDynamicRecord). Barry Kelly came to the rescue in his
    article where he explains how to implement user-defined copy-on-write
    data structures in Delphi. The magic happens in the MutableClone method,
    which makes a new copy if the reference count of the managed interface
    variable exceeds 1.
    A full explanation of this mechanism can be found on Barry's blog:

    http://blog.barrkel.com/2009/01/implementing-user-defined-copy-on-write.html

    TODO does not work yet when mixing generic and non generic instances.
      A notable side effect is that assignments from/to TRecord and
      IDynamicRecord variables cause copies to be made where in this case we
      want to have a reference.
      We tried to compensate for this by keeping a seperate reference count
      variable in the TRecord instance to keep track of any external user
      defined interface variables (IDynamicRecord) that reference the TRecord
      instance. This does not work yet.
}
{$ENDREGION}

type
  IDynamicRecord = interface;
  IDynamicField  = interface;
  {$M+}
  IDynamicRecord<T: class, constructor> = interface;
  {$M-}

  TRecordEnumerator = record
  strict private
    FIndex  : Integer;
    FRecord : IDynamicRecord;
  public
    constructor Create(ARecord: IDynamicRecord);

    function GetCurrent: IDynamicField;
    function MoveNext: Boolean;
    property Current: IDynamicField
      read GetCurrent;
  end;

  TRecord = record
  private
    FDynamicRecord : IDynamicRecord;
    FRecRefCount   : Integer;

    function GetItemValue(const AName: string): TValue;
    procedure SetItemValue(const AName: string; const AValue: TValue);
    function GetItem(Index: Integer): IDynamicField;
    function GetData: Variant;
    function GetDynamicRecord: IDynamicRecord;
    function GetCount: Integer;
    function GetField(const AName: string): IDynamicField;

    function MutableClone: IDynamicRecord;
    function GetInternalRefCount: Integer;

    property DynamicRecord: IDynamicRecord
      read GetDynamicRecord;

  public
    constructor Create(
      const AInstance         : TValue;
      const AAssignProperties : Boolean = True;
      const AAssignFields     : Boolean = False
    ); overload;
    constructor Create(
      const AInstance         : TValue;
      const AAssignProperties : Boolean;
      const AAssignFields     : Boolean;
      const AAssignNulls      : Boolean;
      const ANames            : array of string
    ); overload;
    constructor Create(const ARecord: TRecord); overload;
    class function Create: TRecord; overload; static;

    class function CreateDynamicRecord: IDynamicRecord; static;

    function ToVarArray(const AFieldNames : string = '') : Variant;
    function ToCommaText(const AFieldNames : string) : string; overload;
    function ToCommaText : string; overload;
    function ToDelimitedText(
      const AFieldNames  : string;
      const ADelimiter   : string;
            AQuoteValues : Boolean = False;
            AQuoteChar   : Char = '"'
    ): string; overload;
    function ToDelimitedText(
      const ADelimiter   : string;
            AQuoteValues : Boolean = False;
            AQuoteChar   : Char = '"'
    ): string; overload;

    procedure Assign(ADynamicRecord: IDynamicRecord); overload;
    procedure Assign(
      const ARecord : TRecord;
      const ANames  : array of string
    ); overload;

    procedure AssignTo<T>(AInstance: T); overload;
    procedure AssignTo(AInstance: TValue); overload;
    procedure AssignTo(
      const AValue            : TValue;
      const AAssignProperties : Boolean;
      const AAssignFields     : Boolean;
      const AAssignNulls      : Boolean;
      const ANames            : array of string
    ); overload;
    procedure AssignTo(
      const AValue            : TValue;
      const AAssignProperties : Boolean = True;
      const AAssignFields     : Boolean = False;
      const AAssignNulls      : Boolean = False
    ); overload;

    procedure AssignProperty(
      const AInstance     : TValue;
      const APropertyName : string;
      const AFieldName    : string = '';
      const AAssignNulls  : Boolean = False
    ); overload;
    procedure AssignProperty(
      const AInstance     : TValue;
      const APropertyName : string;
      const AAssignNulls  : Boolean
    ); overload;

    procedure From<T>(
      const AValue            : T;
      const AAssignProperties : Boolean = True;
      const AAssignFields     : Boolean = False;
      const AAssignNulls      : Boolean = False
    ); overload;
    procedure From<T>(
      const AValue            : T;
      const AAssignProperties : Boolean;
      const AAssignFields     : Boolean;
      const AAssignNulls      : Boolean;
      const ANames            : array of string
    ); overload;
    procedure From(
      const AInstance         : TValue;
      const AAssignProperties : Boolean;
      const AAssignFields     : Boolean;
      const AAssignNulls      : Boolean;
      const ANames            : array of string
    ); overload;

    procedure FromDataSet(
            ADataSet     : TDataSet;
      const AAssignNulls : Boolean = False
    );
    procedure FromStrings(AStrings: TStrings);

    procedure ToStrings(AStrings: TStrings);

    function ContainsField(const AName: string): Boolean;
    function DeleteField(const AName: string): Boolean;
    function IsEmpty: Boolean;

    { IEnumerable }
    function GetEnumerator: TRecordEnumerator;

    procedure Clear;

    property Values[const AName : string]: TValue
      read GetItemValue write SetItemValue; default;

    property Items[AIndex: Integer]: IDynamicField
      read GetItem;

    property Fields[const AName: string]: IDynamicField
      read GetField;

    // conversion methods
    // these may be unnecessary when using TValue type conversion helpers in
    // Spring.pas
    function ToString(AAlignValues: Boolean = True): string; overload;
    function ToString(
      const AName         : string;
      const ADefaultValue : string = ''
    ): string; overload;
    function ToFloat(
      const AName         : string;
      const ADefaultValue : Double = 0.0
    ): Double;
    function ToInteger(
      const AName         : string;
      const ADefaultValue : Integer = 0
    ): Integer;
    function ToBoolean(
      const AName         : string;
      const ADefaultValue : Boolean = False
    ): Boolean;

    { True if the string representation of the value is an empty string. }
    function IsBlank(const AName: string): Boolean;

    { Makes access to all field values possible through dynamic invocation. }
    property Data: Variant
      read GetData;

    { Fieldcount. }
    property Count: Integer
      read GetCount;

    property RefCount: Integer
      read FRecRefCount;

    property InternalRefCount: Integer
      read GetInternalRefCount;

    { Implicit cast to our specialized invokable variant. }
    class operator Implicit(const ASource: TRecord): Variant;
    { This cast creates a IDynamicRecord reference if needed. }
    class operator Implicit(const ASource: TRecord): IDynamicRecord;
    class operator Implicit(const ASource: IDynamicRecord): TRecord;
    //class operator Implicit(const ASource: TValue): TRecord;
  end;

  { TRecord<T> manages a IDynamicRecord<T> instance. The data is stored in the
    provided class type. }

    { TODO: Items property }

  TRecord<T: class, constructor> = record
  private
    FDynamicRecord : IDynamicRecord<T>;
    FSaveProc      : TProc;
    FLoadProc      : TProc;

    function GetItemValue(const AName: string): TValue;
    procedure SetItemValue(const AName: string; const AValue: TValue);
    function GetData: T;
    function GetCount: Integer;
    function GetDynamicRecord: IDynamicRecord<T>;

    function MutableClone: IDynamicRecord<T>;

    property DynamicRecord: IDynamicRecord<T>
      read GetDynamicRecord;

  public
    constructor Create(
      const AInstance         : TValue;
      const AAssignProperties : Boolean = True;
      const AAssignFields     : Boolean = False
    ); overload;
    procedure Create(
      const AInstance : TValue;
      const ANames    : array of string
    ); overload;
    constructor Create(
      const AInstance         : TValue;
      const AAssignProperties : Boolean;
      const AAssignFields     : Boolean;
      const AAssignNulls      : Boolean;
      const ANames            : array of string
    ); overload;
    constructor Create(const ARecord: TRecord<T>); overload;
    constructor Create(AInstance: T); overload;
    constructor Create(const ADataFactory: TFunc<T>); overload;

    class function Create: TRecord<T>; overload; static;

    class function CreateDynamicRecord: IDynamicRecord<T>; overload; static;
    class function CreateDynamicRecord(
      AInstance: T
    ): IDynamicRecord<T>; overload; static;
    class function CreateDynamicRecord(
      const ADataFactory: TFunc<T>
    ): IDynamicRecord<T>; overload; static;

    function ToVarArray(const AFieldNames : string = '') : Variant;
    function ToCommaText(const AFieldNames : string) : string; overload;
    function ToCommaText : string; overload;
    function ToDelimitedText(
      const AFieldNames  : string;
      const ADelimiter   : string;
            AQuoteValues : Boolean = False;
            AQuoteChar   : Char = '"'
    ): string; overload;
    function ToDelimitedText(
      const ADelimiter   : string;
            AQuoteValues : Boolean = False;
            AQuoteChar   : Char = '"'
    ): string; overload;

    procedure Assign(const ARecord : TRecord); overload;
    procedure Assign(ASource: T); overload;

    procedure AssignTo(AInstance: TValue); overload;
    procedure AssignTo(
      const AInstance : TValue;
      const ANames    : array of string
    ); overload;
    procedure AssignProperty(
      const AInstance     : TValue;
      const APropertyName : string;
      const AFieldName    : string = '';
      const AAssignNulls  : Boolean = False
    ); overload;
    procedure AssignProperty(
      const AInstance     : TValue;
      const APropertyName : string;
      const AAssignNulls  : Boolean
    ); overload;

    procedure From(const Value: T);
    procedure FromDataSet(
            ADataSet     : TDataSet;
      const AAssignNulls : Boolean = False
    );

    procedure FromStrings(AStrings: TStrings);
    procedure ToStrings(AStrings: TStrings);

    function ContainsField(const AName: string): Boolean;
    function IsEmpty: Boolean;

    { IEnumerable }
    function GetEnumerator: TRecordEnumerator;

    procedure Clear;

    property Values[const AName : string]: TValue
      read GetItemValue write SetItemValue; default;

    // conversion methods
    function ToString(AAlignValues: Boolean = True): string; overload;
    function ToString(
      const AName         : string;
      const ADefaultValue : string = ''
    ): string; overload;
    function ToFloat(
      const AName         : string;
      const ADefaultValue : Double = 0.0
    ): Double;
    function ToInteger(
      const AName         : string;
      const ADefaultValue : Integer = 0
    ): Integer;
    function ToBoolean(
      const AName         : string;
      const ADefaultValue : Boolean = False
    ): Boolean;
    function IsBlank(const AName: string): Boolean;

    property Data: T
      read GetData;

    { Fieldcount. }
    property Count: Integer
      read GetCount;

    { User specified Load procedure (anonymous method). }
    property LoadProc: TProc
      read FLoadProc write FLoadProc;

    { User specified Save procedure (anonymous method). }
    property SaveProc: TProc
      read FSaveProc write FSaveProc;

    class operator Implicit(const ASource: TRecord): TRecord<T>;
    class operator Implicit(const ASource: TRecord<T>): TRecord;
    class operator Implicit(const ASource: TRecord<T>): IDynamicRecord;
    class operator Implicit(const ASource: TRecord<T>): IDynamicRecord<T>;
  end;

  IDynamicField = interface(IInvokable)
  ['{74D23797-BE4C-464A-BEF5-011BE159C8A9}']
    function GetName: string;
    procedure SetName(const AValue: string);
    function GetValue: TValue;
    procedure SetValue(const AValue: TValue);

    function ToString: string;

    property Name: string
      read GetName write SetName;

    property Value : TValue
      read GetValue write SetValue;
  end;

  IDynamicRecord = interface(IInvokable)
  ['{E3B57B88-1DB5-4663-8621-EE235233A114}']
    function GetItem(Index: Integer): IDynamicField;
    function GetField(const AName: string): IDynamicField;
    function GetItemValue(const AName: string): TValue;
    procedure SetItemValue(const AName: string; const AValue: TValue);
    function GetData: Variant;
    function GetCount: Integer;
    function GetRefCount: Integer;

    function GetEnumerator: TRecordEnumerator;

    function ContainsField(const AName: string): Boolean;
    function DeleteField(const AName: string): Boolean;
    function IsEmpty: Boolean;
    procedure Clear;

    procedure Assign(ASource: IDynamicRecord); overload;
    procedure Assign(const ASource: TRecord); overload;

    procedure AssignTo(AInstance: TValue); overload;
    procedure AssignTo(
      const AInstance         : TValue;
      const AAssignProperties : Boolean;
      const AAssignFields     : Boolean;
      const AAssignNulls      : Boolean;
      const ANames            : array of string
    ); overload;
    procedure AssignTo(
      const AInstance : TValue;
      const ANames    : array of string
    ); overload;

//    procedure From<T>(
//      const AInstance         : T;
//      const AAssignProperties : Boolean;
//      const AAssignFields     : Boolean;
//      const AAssignNulls      : Boolean;
//      const ANames            : array of string
//    );
    procedure From(
      const AInstance         : TValue;
      const AAssignProperties : Boolean;
      const AAssignFields     : Boolean;
      const AAssignNulls      : Boolean;
      const ANames            : array of string
    );

    procedure AssignProperty(
      const AInstance     : TValue;
      const APropertyName : string;
      const AFieldName    : string = '';
      const AAssignNulls  : Boolean = False
    ); overload;
    procedure AssignProperty(
      const AInstance     : TValue;
      const APropertyName : string;
      const AAssignNulls  : Boolean
    ); overload;

    function ToCommaText : string; overload;
    function ToCommaText(const AFieldNames : string) : string; overload;
    function ToDelimitedText(
      const AFieldNames  : string;
      const ADelimiter   : string;
            AQuoteValues : Boolean = False;
            AQuoteChar   : Char = '"'
    ): string; overload;
    function ToDelimitedText(
      const ADelimiter   : string;
            AQuoteValues : Boolean = False;
            AQuoteChar   : Char = '"'
    ): string; overload;
    function ToVarArray(const AFieldNames : string = '') : Variant;

    procedure FromDataSet(
            ADataSet     : TDataSet;
      const AAssignNulls : Boolean = False
    );
    procedure FromStrings(AStrings: TStrings);

    procedure ToStrings(AStrings: TStrings);

    { Returns the content as a readable string }
    function ToString(AAlignValues: Boolean = True): string; overload;

    { Conversion methods. When conversion fails the default value is returned. }
    function ToString(
      const AName         : string;
      const ADefaultValue : string = ''
    ): string; overload;
    function ToFloat(
      const AName         : string;
      const ADefaultValue : Double = 0.0
    ): Double;
    function ToInteger(
      const AName         : string;
      const ADefaultValue : Integer = 0
    ): Integer;
    function ToBoolean(
      const AName         : string;
      const ADefaultValue : Boolean = False
    ): Boolean;

    property Values[const AName : string]: TValue
      read GetItemValue write SetItemValue; default;

    property Items[AIndex: Integer]: IDynamicField
      read GetItem;

    property Fields[const AName: string]: IDynamicField
      read GetField;

    property Data: Variant
      read GetData;

    property Count: Integer
      read GetCount;

    property RefCount: Integer
      read GetRefCount;
  end;

  IDynamicRecord<T: class, constructor> = interface(IDynamicRecord)
  ['{98AD898F-552C-4B08-B5E9-B9C481153407}']
    function GetData: T;
    procedure SetData(AValue: T);
    function GetDataFactory: TFunc<T>;
    procedure SetDataFactory(const ADataFactory : TFunc<T>);

    procedure Assign(AInstance: T); overload;
    procedure Assign(ASource: IDynamicRecord<T>); overload;

    property Data: T
      read GetData write SetData;

    property DataFactory: TFunc<T>
      read GetDataFactory write SetDataFactory;
  end;

  { TDynamicField holds the Name/Value pair representation of a Field. }
  { non reference counted as it is by default managed by the owning collection.}

  TDynamicField = class(TCollectionItem, IDynamicField)
  strict private
    FName  : string;
    FValue : TValue;

    function GetName: string;
    procedure SetName(const AValue: string);
    function GetValue: TValue;
    procedure SetValue(const AValue: TValue);

    { IInterface }
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;

  public
    procedure Assign(Source: TPersistent); override;
    function ToString: string; override;

    { Fieldname used as key in the TDynamicRecord collection }
    property Name: string
      read GetName write SetName;

    { Dynamic typed field value. }
    property Value : TValue
      read GetValue write SetValue;
  end;

  TDynamicField<T: class, constructor> = class(
    TDynamicField, IDynamicField
  )
  strict private
    FName     : string;
    FRefCount : Integer;

    function GetName: string;
    procedure SetName(const AValue: string);
    function GetValue: TValue;
    procedure SetValue(const AValue: TValue);

    { IInterface }
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;

  public
    procedure BeforeDestruction; override;

    { Fieldname used as key in the TDynamicRecord collection }
    property Name: string
      read GetName write SetName;

    { Dynamic typed field value. }
    property Value : TValue
      read GetValue write SetValue;
  end;

  { TDynamicRecord is a collection used as the storage of the contained data.}

  TDynamicRecord = class(TCollection, IDynamicRecord)
  strict private
    FRttiContext : TRttiContext;
    FOnChanged   : TNotifyEvent;
    FRefCount    : Integer;

    { IInterface }
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;

    function GetData: Variant;
    function GetRefCount: Integer;

  protected
    function GetCount: Integer; reintroduce; virtual;
    function GetField(const AName: string): IDynamicField; virtual;
    function GetItem(Index: Integer): IDynamicField; virtual;
    function GetItemValue(const AName: string): TValue; virtual;
    procedure SetItemValue(const AName: string; const AValue: TValue); virtual;

    procedure Update(AItem: TCollectionItem); override;
    procedure SetItemName(Item: TCollectionItem); override;

    function Add: IDynamicField;
    function Insert(Index: Integer): IDynamicField;

    procedure Assign(
      AInstance : IDynamicRecord
    ); reintroduce; overload;

    procedure Assign(
      const ARecord : TRecord
    ); reintroduce; overload;

    procedure AssignTo(Dest: TPersistent); overload; override;
    procedure AssignTo(AInstance: TValue); reintroduce; overload;
    procedure AssignTo(
      const AInstance : TValue;
      const ANames    : array of string
    ); reintroduce; overload;
    procedure AssignTo(
      const AInstance         : TValue;
      const AAssignProperties : Boolean;
      const AAssignFields     : Boolean;
      const AAssignNulls      : Boolean;
      const ANames            : array of string
    ); reintroduce; overload;

    procedure From(
      const AInstance         : TValue;
      const AAssignProperties : Boolean;
      const AAssignFields     : Boolean;
      const AAssignNulls      : Boolean;
      const ANames            : array of string
    );

    procedure FromDataSet(
            ADataSet     : TDataSet;
      const AAssignNulls : Boolean = False
    );
    procedure FromStrings(AStrings: TStrings);
    procedure ToStrings(AStrings: TStrings);

    procedure AssignProperty(
      const AInstance     : TValue;
      const APropertyName : string;
      const AFieldName    : string = '';
      const AAssignNulls  : Boolean = False
    ); overload;

    procedure AssignProperty(
      const AInstance     : TValue;
      const APropertyName : string;
      const AAssignNulls  : Boolean
    ); overload;

    function ContainsField(const AName: string): Boolean;
    function DeleteField(const AName: string): Boolean;
    function IsEmpty: Boolean;

    function IndexOf(const AName: string): Integer; virtual;
    function FindItemID(ID: Integer): IDynamicField;
    function Find(const AName: string): IDynamicField;

    function ToVarArray(const AFieldNames : string = '') : Variant;
    function ToCommaText(const AFieldNames : string) : string; overload;
    function ToCommaText : string; overload;
    function ToDelimitedText(
      const AFieldNames  : string;
      const ADelimiter   : string;
            AQuoteValues : Boolean = False;
            AQuoteChar   : Char = '"'
    ): string; overload;
    function ToDelimitedText(
      const ADelimiter   : string;
            AQuoteValues : Boolean = False;
            AQuoteChar   : Char = '"'
    ): string; overload;

    // value convert routines
    function ToString(
      const AName         : string;
      const ADefaultValue : string = ''
    ): string; reintroduce; overload;
    function ToInteger(
      const AName         : string;
      const ADefaultValue : Integer = 0
    ): Integer;
    function ToBoolean(
      const AName         : string;
      const ADefaultValue : Boolean = False
    ): Boolean;
    function ToFloat(
      const AName         : string;
      const ADefaultValue : Double = 0.0
    ): Double;

    property RttiContext: TRttiContext
      read FRttiContext;

    property Fields[const AName: string]: IDynamicField
      read GetField;

    { Provides indexed access to the list of collection items. }
    property Items[AIndex: Integer]: IDynamicField
      read GetItem;

    { Returns the item values for a given key (Name). }
    property Values[const AName : string]: TValue
      read GetItemValue write SetItemValue; default;

    property OnChanged: TNotifyEvent
      read FOnChanged write FOnChanged;

    { Dynamic record instance represented by our custom variant type. }
    property Data: Variant
      read GetData;

    property Count: Integer
      read GetCount;

    //procedure From<T>(const Value: T);
  protected
    property RefCount: Integer
      read GetRefCount;

  public
    constructor Create; overload; virtual;
    constructor Create(const AFieldNames : string); overload;

    function GetEnumerator: TRecordEnumerator;

    function ToString(AAlignValues: Boolean): string; reintroduce; overload; virtual;
    function ToString: string; overload; override;
  end;

  TDynamicRecord<T: class, constructor> = class(
    TDynamicRecord, IDynamicRecord, IDynamicRecord<T>)
  strict private
    FData        : T;
    FDataFactory : TFunc<T>;

  protected
    function GetCount: Integer; override;
    function GetData: T;
    procedure SetData(AValue: T);
    function GetDataFactory: TFunc<T>;
    procedure SetDataFactory(const Value: TFunc<T>);
    function GetItem(Index: Integer): IDynamicField; override;
    function GetItemValue(const AName: string): TValue; override;
    procedure SetItemValue(const AName: string; const AValue: TValue); override;

  public
    function ToString(AAlignValues: Boolean): string; overload; override;

    constructor Create; overload; override;
    constructor Create(AInstance: T); reintroduce; overload;
    constructor Create(ASource: IDynamicRecord<T>); overload;

    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    procedure Assign(AInstance: T); overload;
    procedure Assign(ASource: IDynamicRecord<T>); overload;

    { Wrapped instance of type T }
    property Data: T
      read GetData write SetData;

    property DataFactory: TFunc<T>
      read GetDataFactory write SetDataFactory;
  end;

implementation

uses
  System.TypInfo, System.Variants, System.Math, System.StrUtils,
  System.Generics.Collections,
  WinApi.Windows;

resourcestring
  SFieldNotFound        = 'Record does not contain a field with name %s';
  SValueCannotBeRead    = 'Value of %s could not be read';
  SValueConversionError =
    'Error while trying to convert value of (%s) with type (%s)';
  SParamIsNotRecordOrInstanceType =
    'AInstance is not a record or instance type!';
  SPropertyNotFound = 'Property %s not found! (%s)';
  SArgumentTypeNotSupported =
    'The argument type of AssignTo is not supported';

var
  FContext: TRttiContext;

{ A custom variant type that implements the mapping from the property names to
  the record instance. }
type
  TVarDataRecordType = class(TInvokeableVariantType)
  private
  type
    { Our customized layout of the variant's record data. We only need a
      reference to the TDynamicRecord instance. }
    TVarDataRecordData = packed record
      VType         : TVarType;
      Reserved1     : Word;
      Reserved2     : Word;
      Reserved3     : Word;
      DynamicRecord : TDynamicRecord;
      Reserved4     : NativeInt;
    end;

  class var
    { The instance of the custom variant type. The data of the custom variant is
      stored in a TVarData record (which is common to all variants),
      but the methods and properties are implemented in this class instance. }
    FVarDataRecordType : TVarDataRecordType;

  protected
    function FixupIdent(const AText: string): string; override;

  public
    procedure Clear(var V: TVarData); override;
    procedure Copy(
      var   Dest     : TVarData;
      const Source   : TVarData;
      const Indirect : Boolean
    ); override;
    function GetProperty(
      var   Dest : TVarData;
      const V    : TVarData;
      const Name : string
    ): Boolean; override;
    function SetProperty(
      const V      : TVarData;
      const Name   : string;
      const AValue : TVarData
    ): Boolean; override;

    class constructor Create;
    class destructor Destroy;

    class property VarDataRecordType : TVarDataRecordType
      read FVarDataRecordType;
  end;

{$REGION 'non-interfaced routines'}
function WordCount(const AString: string; const AWordDelims: TSysCharSet)
  : Integer;
var
  N: Integer;
  I: Integer;
begin
  Result := 0;
  I := 1;
  N := Length(AString);
  while I <= N do
  begin
    while (I <= N) and CharInSet(AString[I], AWordDelims) do
      Inc(I);
    if I <= N then
      Inc(Result);
    while (I <= N) and not CharInSet(AString[I], AWordDelims) do
      Inc(I);
  end;
end;

function WordPosition(const AIndex: Integer; const AString: string;
  const AWordDelims: TSysCharSet): Integer;
var
  N: Integer;
  I: Integer;
begin
  N := 0;
  I := 1;
  Result := 0;
  while (I <= Length(AString)) and (N <> AIndex) do
  begin
  { skip over delimiters }
    while (I <= Length(AString)) and CharInSet(AString[I], AWordDelims) do
      Inc(I);
  { if we're not beyond end of S, we're at the start of a word }
    if I <= Length(AString) then
      Inc(N);
  { if not finished, find the end of the current word }
    if N <> AIndex then
      while (I <= Length(AString)) and not CharInSet(AString[I], AWordDelims) do
        Inc(I)
    else
      Result := I;
  end;
end;

function ExtractWord(const AIndex: Integer; const AString: string;
  const AWordDelims: TSysCharSet): string;
var
  I: Integer;
  N: Integer;
begin
  N := 0;
  I := WordPosition(AIndex, AString, AWordDelims);
  if I <> 0 then
  begin
    { find the end of the current word }
    while (I <= Length(AString)) and not CharInSet(AString[I], AWordDelims) do
    begin
    { add the I'th character to result }
      Inc(N);
      SetLength(Result, N);
      Result[N] := AString[I];
      Inc(I);
    end;
  end;
  SetLength(Result, N);
end;

{ TODO: use Spring routine }

function ExtractGenericArguments(ATypeInfo: PTypeInfo): string;
var
  i: Integer;
  Name: string;
begin
  Name := string(ATypeInfo.Name);
  i := Pos('<', Name);
  if i > 0 then
  begin
    Result := Copy(Name, Succ(i), Length(Name) - Succ(i));
  end
  else
  begin
    Result := ''
  end;
end;

function IsGenericTypeOf(ATypeInfo: PTypeInfo;
  const ABaseTypeName: string): Boolean;
var
  Name: string;
begin
  Name := string(ATypeInfo.Name);
  Result := (Copy(Name, 1, Succ(Length(ABaseTypeName))) = (ABaseTypeName + '<'))
    and (Copy(Name, Length(Name), 1) = '>');
end;

function TryGetUnderlyingTypeName(ATypeInfo: PTypeInfo;
  out InnerTypeName: string): Boolean;
begin
  if (ATypeInfo = nil) or (ATypeInfo.Kind <> tkRecord) then
  begin
    Exit(False);
  end;
  if IsGenericTypeOf(ATypeInfo,'Nullable')
    or IsGenericTypeOf(ATypeInfo,'NotNullable') then
  begin
    Result := True;
    InnerTypeName := ExtractGenericArguments(ATypeInfo);
  end
  else
  begin
    Exit(False);
  end;
end;

function TryGetUnderlyingTypeInfo(ATypeInfo: PTypeInfo;
  out AInnerTypeInfo: PTypeInfo): Boolean;
var
  InnerTypeName : string;
  RttiType      : TRttiType;
begin
  Result := TryGetUnderlyingTypeName(ATypeInfo, InnerTypeName);
  if Result then
  begin
    RttiType := FContext.FindType(InnerTypeName);
    if RttiType <> nil then
      AInnerTypeInfo := RttiType.Handle
    else
      AInnerTypeInfo := nil;
    Result := AInnerTypeInfo <> nil;
  end;
end;

function TryGetUnderlyingValue(const AValue: TValue; out AInnerValue: TValue)
  : Boolean;
var
  T : TRttiType;
  F : TRttiField;
  H : TRttiField;
  V : TValue;
begin
  T := FContext.GetType(AValue.TypeInfo);
  F := T.GetField('FValue');
  H := T.GetField('FHasValue');

  if Assigned(F) and Assigned(H) then
  begin
    V := H.GetValue(AValue.GetReferenceToRawData);
    if (V.IsOrdinal and V.AsBoolean) or (V.AsString <> '') then
      AInnerValue := F.GetValue(AValue.GetReferenceToRawData)
    else
      AInnerValue := TValue.Empty;
    Result := True;
  end
  else
  begin
    AInnerValue := AValue;
    Result := False;
  end;
end;

function TrySetUnderlyingValue(var AValue: TValue; const AInnerValue: TValue)
  : Boolean;
var
  T : TRttiType;
  F : TRttiField;
  H : TRttiField;
  A : TRttiField;
begin
  T := FContext.GetType(AValue.TypeInfo);
  F := T.GetField('FValue');
  H := T.GetField('FHasValue');
  A := T.GetField('FAddr');
  Result := False;
  if Assigned(F) then // Spring Nullable
  begin
    try
      F.SetValue(AValue.GetReferenceToRawData, AInnerValue);
    except
      // do nothing
    end;
    Result := True;
  end
  else
  begin
    F.SetValue(AValue.GetReferenceToRawData, TValue.Empty);
  end;
  if Assigned(H) and Assigned(A) and Result then
  begin
    H.SetValue(AValue.GetReferenceToRawData, True);
    A.SetValue(AValue.GetReferenceToRawData, '');
  end;
end;
{$ENDREGION}

{$REGION 'TVarDataRecordType'}
{$REGION 'construction and destruction'}
class constructor TVarDataRecordType.Create;
begin
  FVarDataRecordType := TVarDataRecordType.Create;
end;

class destructor TVarDataRecordType.Destroy;
begin
 FreeAndNil(FVarDataRecordType);
end;
{$ENDREGION}

{$REGION 'public methods'}
procedure TVarDataRecordType.Clear(var V: TVarData);
begin
  { We are only holding a referece to a TDynamicRecord instance and we are
    not supposed to destroy it here. }
  SimplisticClear(V);
end;

procedure TVarDataRecordType.Copy(var Dest: TVarData; const Source: TVarData;
  const Indirect: Boolean);
begin
  { We are only holding a referece to a TDynamicRecord instance that can simply
    be copied here. }
  SimplisticCopy(Dest, Source, Indirect);
end;

function TVarDataRecordType.FixupIdent(const AText: string): string;
begin
  Result := AText;
end;

function TVarDataRecordType.GetProperty(var Dest: TVarData; const V: TVarData;
  const Name: string): Boolean;
begin
  Result := True;
  try
    Variant(Dest) := TVarDataRecordData(V).DynamicRecord[Name].AsVariant;
  except
    raise Exception.CreateFmt(SValueCannotBeRead, [Name]);
  end;
end;

function TVarDataRecordType.SetProperty(const V: TVarData; const Name: string;
  const AValue: TVarData): Boolean;
var
  U: TValue;
begin
  Result := True;
  if (AValue.VType and varByRef) <> 0 then
  begin
    { Parameter sent by reference }
    case (AValue.VType and not varByRef) of
      varSmallint : U := TValue.From(PSmallInt(AValue.VPointer)^);
      varInteger  : U := TValue.From(PInteger(AValue.VPointer)^);
      varSingle   : U := TValue.From(PSingle(AValue.VPointer)^);
      varDouble   : U := TValue.From(PDouble(AValue.VPointer)^);
      varCurrency : U := TValue.From(PCurrency(AValue.VPointer)^);
      varDate     : U := TValue.From(PDateTime(AValue.VPointer)^);
      varOleStr   : U := TValue.From(WideString(PPWideChar(AValue.VPointer)^));
      varBoolean  : U := TValue.From(PBoolean(AValue.VPointer)^);
      varShortInt : U := TValue.From(PShortInt(AValue.VPointer)^);
      varByte     : U := TValue.From(PByte(AValue.VPointer)^);
      varWord     : U := TValue.From(PWord(AValue.VPointer)^);
      varLongWord : U := TValue.From(PLongWord(AValue.VPointer)^);
      varInt64    : U := TValue.From(PInt64(AValue.VPointer)^);
      varUInt64   : U := TValue.From(PUint64(AValue.VPointer)^);
      varString   : U := TValue.From(PRawByteString(AValue.VPointer)^);
      varUString  : U := TValue.From(PUnicodeString(AValue.VPointer)^);
      varVariant  : U := TValue.FromVariant(Variant(PVarData(AValue.VPointer)^));
      else
        Result := False;
    end;
  end
  else
  begin
    try
      U := TValue.FromVariant(Variant(AValue));
    except
      Result := False;
    end;
  end;
  TVarDataRecordData(V).DynamicRecord[Name] := U;
  if not Result then
    raise Exception.CreateFmt(SValueConversionError, [Name, VarTypeAsText(AValue.VType)]);
end;
{$ENDREGION}
{$ENDREGION}

{$REGION 'TDynamicRecord'}
{$REGION 'construction and destruction'}
constructor TDynamicRecord.Create;
begin
  inherited Create(TDynamicField);
end;

{ Creates a list of fields for the given comma seperated list of key names. }

constructor TDynamicRecord.Create(const AFieldNames: string);
var
  SL : TStringList;
  I  : Integer;
begin
  inherited Create(TDynamicField);
  SL := TStringList.Create;
  try
    SL.CommaText := AFieldNames;
    for I := 0 to SL.Count - 1 do
      Values[SL[I]] := TValue.Empty;
  finally
    SL.Free;
  end;
end;
{$ENDREGION}

{$REGION 'property access methods'}
function TDynamicRecord.GetCount: Integer;
begin
  Result := inherited Count;
end;

function TDynamicRecord.GetData: Variant;
begin
  VarClear(Result);
  TVarDataRecordType.TVarDataRecordData(Result).VType :=
    TVarDataRecordType.VarDataRecordType.VarType;
  TVarDataRecordType.TVarDataRecordData(Result).DynamicRecord := Self;
end;

function TDynamicRecord.GetField(const AName: string): IDynamicField;
begin
  Result := Find(AName);
end;

function TDynamicRecord.GetItem(Index: Integer): IDynamicField;
begin
  Result := inherited Items[Index] as TDynamicField;
end;

function TDynamicRecord.GetItemValue(const AName: string): TValue;
var
  P : IDynamicField;
begin
  Result := TValue.Empty;
  P := Find(AName);
  if Assigned(P) then
    Result := P.Value
  else
    Result := TValue.Empty;
end;

function TDynamicRecord.GetRefCount: Integer;
begin
  Result := FRefCount;
end;

procedure TDynamicRecord.SetItemValue(const AName: string; const AValue: TValue);
var
  P : IDynamicField;
begin
  P := Find(AName);
  if Assigned(P) then
    P.Value := AValue
  else
  begin
    P := Add;
    P.Name  := AName;
    P.Value := AValue;
  end;
end;

function TDynamicRecord.ToBoolean(const AName: string;
  const ADefaultValue: Boolean): Boolean;
var
  V: TValue;
begin
  V := Values[AName];
  if not V.TryAsType<Boolean>(Result) then
    Result := ADefaultValue;
end;

function TDynamicRecord.ToFloat(const AName: string;
  const ADefaultValue: Double): Double;
var
  V: TValue;
begin
  V := Values[AName];
  if not V.TryAsType<Double>(Result) then
    Result := ADefaultValue;
end;

// convert string to Integer does not work yet!

function TDynamicRecord.ToInteger(const AName: string; const
  ADefaultValue: Integer): Integer;
var
  V : TValue;
  R : Int64;
  S : string;
begin
  V := Values[AName];
  if V.TryAsOrdinal(R) then // Boolean
    Result := R
  else if V.TryAsType<Int64>(R) then
    Result := R
  else
  begin
    S := V.ToString;
    Result := StrToIntDef(S, ADefaultValue);
  end
end;

function TDynamicRecord.ToString: string;
begin
  Result := ToString(True);
end;

function TDynamicRecord.ToString(const AName: string;
  const ADefaultValue: string = ''): string;
var
  V: TValue;
begin
  V := Values[AName];
  if V.IsEmpty then
    Result := ADefaultValue
  else
    try
      Result := V.ToString;
    except
      Result := ADefaultValue
    end;
end;
{$ENDREGION}

{$REGION 'protected methods'}
function TDynamicRecord.GetEnumerator: TRecordEnumerator;
begin
  Result := TRecordEnumerator.Create(Self);
end;

{ Overridden method from TCollection to make any necessary changes when the
  items in the collection change. This method is called automatically when an
  update is issued.
  Item = Item that changed. If the Item parameter is nil, then the change
         affects more than one item in the collection. }

procedure TDynamicRecord.Update(AItem: TCollectionItem);
begin
// Make necessary adjustments when items in the collection change.
// Update gets called from TCollection.Changed.
  if Assigned(FOnChanged) then
    FOnChanged(Self);
end;

{ Constructs a unique itemn ame for a new collection-item.
  The Insert method calls SetItemName to initialize the Name property of items
  when it inserts them into the collection. This overridden version provides
  collection items with default names. }

procedure TDynamicRecord.SetItemName(Item: TCollectionItem);
begin
  TDynamicField(Item).Name :=
    Copy(Item.ClassName, 2, Length(Item.ClassName)) + IntToStr(Item.ID + 1);
end;

function TDynamicRecord.ContainsField(const AName: string): Boolean;
begin
  Result := IndexOf(AName) <> -1;
end;

function TDynamicRecord.DeleteField(const AName: string): Boolean;
var
  N: Integer;
begin
  N := IndexOf(AName);
  if N <> -1 then
  begin
    Delete(N);
    Result := True;
  end
  else
    Result := False;
end;
{$ENDREGION}

{$REGION 'public methods'}
{$REGION 'assignment methods'}
procedure TDynamicRecord.Assign(AInstance: IDynamicRecord);
var
  F : IDynamicField;
  I : Integer;
begin
  for I := 0 to AInstance.Count - 1 do
  begin
    F := AInstance.Items[I];
    Values[F.Name] := F.Value;
  end;
end;

procedure TDynamicRecord.Assign(const ARecord: TRecord);
begin
  Assign(ARecord.DynamicRecord);
end;

{ Assigns a property value of a given instance to a field of the dynamic record.
  If the fieldname is not specified, the same name as the source property will
  be used. }

procedure TDynamicRecord.AssignProperty(const AInstance: TValue; const APropertyName,
  AFieldName: string; const AAssignNulls: Boolean);
var
  T : TRttiType;
  P : TRttiProperty;
  V : TValue;
  V1: TValue;
  V2: TValue;
  S : string;
begin
  T := FRttiContext.GetType(AInstance.TypeInfo);
  P := T.GetProperty(APropertyName);
  S := IfThen(AFieldName = '', APropertyName, AFieldName);
  if Assigned(P) then
  begin
    if T.IsInstance then // An object instance
    begin
      V := P.GetValue(AInstance.AsObject);
      if V.Kind = tkRecord then
      begin
        TryGetUnderlyingValue(V, V1);
        V2 := V1;
      end
      else
        V2 := V;
    end
    else if T.IsRecord then
    begin
      V := P.GetValue(AInstance.GetReferenceToRawData);
      if V.Kind = tkRecord then
      begin
        TryGetUnderlyingValue(V, V1);
        V2 := V1;
      end
      else
        V2 := V;
    end
    else
      raise Exception.Create(SParamIsNotRecordOrInstanceType);
  end
  else // TODO: more info about the instance
    raise Exception.CreateFmt(SPropertyNotFound,
      [APropertyName, AInstance.ToString]);

  if (V2.IsEmpty and AAssignNulls) or (not V2.IsEmpty) then
  begin
    Values[S] := V2;
  end;
end;

procedure TDynamicRecord.AssignProperty(const AInstance: TValue;
  const APropertyName: string; const AAssignNulls: Boolean);
begin
  AssignProperty(AInstance, APropertyName, '', AAssignNulls);
end;

procedure TDynamicRecord.AssignTo(const AInstance: TValue;
  const ANames: array of string);
var
  T    : TRttiType;
  P    : TRttiProperty;
  V    : TValue;
  List : TList<string>;
begin
  T := FRttiContext.GetType(AInstance.TypeInfo);
  List := TList<string>.Create;
  try
    List.AddRange(ANames);
    for P in T.GetProperties do
    begin
      if (List.Count = 0) or List.Contains(P.Name) then
      begin
        if P.IsWritable then
        begin
          if T.IsInstance then // An object instance
          begin
            if ContainsField(P.Name) then
            begin
              V := P.GetValue(AInstance.AsObject);
              if V.Kind = tkRecord then
              begin
                TrySetUnderlyingValue(V, Values[P.Name]);
              end
              else
              begin
                V := Values[P.Name];
              end;
              P.SetValue(AInstance.AsObject, V);
            end;
          end
          else if T.IsRecord then
          begin
            if ContainsField(P.Name) then
            begin
              V := P.GetValue(AInstance.GetReferenceToRawData);
              if V.Kind = tkRecord then
              begin
                TrySetUnderlyingValue(V, Values[P.Name]);
              end
              else
              begin
                V := Values[P.Name];
              end;
              P.SetValue(AInstance.GetReferenceToRawData, V);
            end;
          end
          else
            raise Exception.Create('The argument type of AssignTo is not supported.');
        end;
      end;
    end;
  finally
    List.Free;
  end;
end;

procedure TDynamicRecord.AssignTo(const AInstance: TValue;
  const AAssignProperties, AAssignFields, AAssignNulls: Boolean;
  const ANames: array of string);
begin
// TODO
end;

{ Assigns the record values to the corresponding (writable) properties of the
  given instance (record or object). }

procedure TDynamicRecord.AssignTo(AInstance: TValue);
var
  T: TRttiType;
  P: TRttiProperty;
  V: TValue;
begin
  T := FRttiContext.GetType(AInstance.TypeInfo);
  // GetProperties only works for class properties! (bug in TRttiType.GetProperties))
  for P in T.GetProperties do
  begin
    if P.IsWritable then
    begin
      if T.IsInstance then // An object instance
      begin
        if ContainsField(P.Name) then
        begin
          V := P.GetValue(AInstance.AsObject);  // raises exception when Variant = Null
          if V.Kind = tkRecord then
          begin
            TrySetUnderlyingValue(V, Values[P.Name]);
          end
          else
          begin
            V := Values[P.Name];
          end;
          if not V.IsEmpty then
            P.SetValue(AInstance.AsObject, V);
        end;
      end
      else if T.IsRecord then
      begin
        if ContainsField(P.Name) then
        begin
          V := P.GetValue(AInstance.GetReferenceToRawData);
          if V.Kind = tkRecord then
          begin
            TrySetUnderlyingValue(V, Values[P.Name]);
          end
          else
          begin
            V := Values[P.Name];
          end;
          if not V.IsEmpty then
            P.SetValue(AInstance.GetReferenceToRawData, V);
        end;
      end
      else
        raise Exception.Create(SArgumentTypeNotSupported);
    end;
  end;
end;

procedure TDynamicRecord.AssignTo(Dest: TPersistent);
begin
  AssignTo(TValue.From<TPersistent>(Dest));
end;
{$ENDREGION}

{$REGION 'TCollection methods'}
function TDynamicRecord.Add: IDynamicField;
begin
  Result := inherited Add as TDynamicField;
end;

{ Inserts a new field instance to the collection before position specified
  with Index }

function TDynamicRecord.Insert(Index: Integer): IDynamicField;
begin
  Result := inherited Insert(Index) as TDynamicField;
end;

function TDynamicRecord.IsEmpty: Boolean;
begin
  Result := Count = 0;
end;

function TDynamicRecord.IndexOf(const AName: string): Integer;
begin
  for Result := 0 to Pred(Count) do
    if AnsiCompareText((Items[Result]).Name, AName) = 0 then
      Exit;
  Result := -1;
end;

{ The FindItemID method returns the item in the collection whose ID property
  is passed to it as a parameter. If no item has the specified ID, FindItemID
  returns nil. }

function TDynamicRecord.FindItemID(ID: Integer): IDynamicField;
begin
  Result := inherited FindItemID(ID) as TDynamicField;
end;

{ Creates an instance with data extracted using RTTI from the given TValue
  argument.  }
procedure TDynamicRecord.From(const AInstance: TValue; const AAssignProperties,
  AAssignFields, AAssignNulls: Boolean; const ANames: array of string);
var
  P             : TRttiProperty;
  F             : TRttiField;
  V             : TValue;
  V2            : TValue;
  ExcludedTypes : TTypeKinds;
  List          : TList<string>;
begin
  if not AInstance.IsEmpty then
  begin
    Clear;
    ExcludedTypes := [
      tkClassRef, tkMethod, tkInterface, tkPointer, tkUnknown, tkArray,
      tkDynArray, tkClass, tkProcedure
    ];
    List := TList<string>.Create;
    try
      List.AddRange(ANames);
      if AAssignProperties then
      begin
        for P in FRttiContext.GetType(AInstance.TypeInfo).GetProperties do
        begin
          if (List.Count = 0) or List.Contains(P.Name) then
          begin
            if not (P.PropertyType.TypeKind in ExcludedTypes) and P.IsReadable then
            begin
              if AInstance.IsObject then
                V := P.GetValue(AInstance.AsObject)
              else
                V := P.GetValue(AInstance.GetReferenceToRawData);
              if V.Kind = tkRecord then
              begin
                if TryGetUnderlyingValue(V, V2) then
                begin
                  if AAssignNulls or (not AAssignNulls and not V2.IsEmpty) then
                    Values[P.Name] := V2;
                end
                else
                begin
                 // raise Exception.Create('TryGetUnderlyingValue failed.');
                end;
              end
              else
              begin
                if AAssignNulls or (not AAssignNulls and not V.IsEmpty) then
                  Values[P.Name] := V;
              end;
            end;
          end;
        end;
      end;
      if AAssignFields then
      begin
        for F in FRttiContext.GetType(AInstance.TypeInfo).GetFields do
        begin
          if (List.Count = 0) or List.Contains(F.Name) then
          begin
            if not (F.FieldType.TypeKind in ExcludedTypes) then
            begin
              if AInstance.IsObject then
                V := F.GetValue(AInstance.AsObject)
              else
                V := F.GetValue(AInstance.GetReferenceToRawData);

              if V.Kind = tkRecord then
              begin
                if TryGetUnderlyingValue(V, V2) then
                  Values[F.Name] := V2;
              end
              else
                Values[F.Name] := V
            end;
          end;
        end;
      end;
    finally
      FreeAndNil(List);
    end;
  end; // if not AInstance.IsEmpty then
end;

procedure TDynamicRecord.FromDataSet(ADataSet: TDataSet;
  const AAssignNulls: Boolean);
var
  F: TField;
begin
  if Assigned(ADataSet) and ADataSet.Active and not ADataSet.IsEmpty then
  begin
    Clear;
    for F in ADataSet.Fields do
    begin
      if (not F.IsNull) or (F.IsNull and AAssignNulls) then
        Values[F.FieldName] := TValue.FromVariant(F.Value);
    end;
  end;
end;

{ Assigns from a TStrings instance holding name/value pairs. }

procedure TDynamicRecord.FromStrings(AStrings: TStrings);
var
  I: Integer;
begin
  for I := 0 to AStrings.Count - 1 do
  begin
    Values[AStrings.Names[I]] := AStrings.ValueFromIndex[I];
  end;
end;

{ Assigns to a TStrings instance holding name/value pairs.
  Remark: fields with empty values will not be added to the stringlist (this
  is inherent to Delphi's implementation of TStrings. }

procedure TDynamicRecord.ToStrings(AStrings: TStrings);
var
  I: Integer;
  S: string;
begin
  AStrings.Clear;
  for I := 0 to Count - 1 do
  begin
    S := ToString(Items[I].Name);
    if S = #0 then
      S := '';
    AStrings.Values[Items[I].Name] := S;
  end;
end;

{ Finds a field with a given name. Returns nil if no field is found. }

function TDynamicRecord.Find(const AName: string): IDynamicField;
var
  I : Integer;
begin
  I := IndexOf(AName);
  if I < 0 then
    Result := nil
  else
    Result := Items[I];
end;
{$ENDREGION}

{$REGION 'IInterface support'}
function TDynamicRecord._AddRef: Integer;
begin
  Result := InterlockedIncrement(FRefCount);
end;

function TDynamicRecord._Release: Integer;
begin
  Result := InterlockedDecrement(FRefCount);
  if Result = 0 then
    Destroy;
end;

function TDynamicRecord.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;
{$ENDREGION}

{$REGION 'data transformation routines'}
{ Returns a comma seperated string of values for the given list of comma
  seperated fieldnames. }

function TDynamicRecord.ToCommaText(const AFieldNames: string): string;
var
  I : Integer;
  N : Integer;
  S : string;
begin
  N := WordCount(AFieldNames, [',']);
  for I := 0 to N - 1 do
  begin
    S := Values[ExtractWord(I + 1, AFieldNames, [','])].ToString;
    if I > 0 then
      Result := Result + ',' + S
    else
      Result := S;
  end;
end;

{ Returns a comma seperated string of all fieldvalues. }

function TDynamicRecord.ToCommaText: string;
var
  I : Integer;
  S : string;
begin
  for I := 0 to Count - 1 do
  begin
    S := VarToStrDef(Items[I].Value.ToString, '');
    if I > 0 then
      Result := Result + ',' + S
    else
      Result := S;
  end;
end;

function TDynamicRecord.ToDelimitedText(const AFieldNames, ADelimiter: string;
  AQuoteValues: Boolean; AQuoteChar: Char): string;
var
  I : Integer;
  N : Integer;
  S : string;
begin
  N := WordCount(AFieldNames, [',']);
  for I := 0 to N - 1 do
  begin
    S := Values[ExtractWord(I + 1, AFieldNames, [','])].ToString;
    if AQuoteValues then
      S := AnsiQuotedStr(S, AQuoteChar);
    if I > 0 then
      Result := Result + ADelimiter + S
    else
      Result := S;
  end;
end;

function TDynamicRecord.ToDelimitedText(const ADelimiter: string;
  AQuoteValues: Boolean; AQuoteChar: Char): string;
var
  I : Integer;
  S : string;
begin
  for I := 0 to Count - 1 do
  begin
    S := Items[I].Value.ToString;
    if AQuoteValues then
      S := AnsiQuotedStr(S, AQuoteChar);
    if I > 0 then
      Result := Result + ADelimiter + S
    else
      Result := S;
  end;
end;

{ Returns for the given list of key names the corresponding values as a Variant
  array.

  AFieldNames
    Comma seperated list of key names.

  Result
    Variant array with the corresponding values.
}

function TDynamicRecord.ToVarArray(const AFieldNames: string): Variant;
var
  VA : array of Variant;
  I  : Integer;
  N  : Integer;
begin
  if AFieldNames = '' then
  begin
    SetLength(VA, Count);
    for I := 0 to Count - 1 do
    begin
      if Items[I].Value.IsType<Boolean> then
        VA[I] := Items[I].Value.AsBoolean
      else
        VA[I] := Items[I].Value.AsVariant;
    end;
  end
  else
  begin
    N := WordCount(AFieldNames, [',']);
    SetLength(VA, N);
    for I := 0 to N - 1 do
      VA[I] := Values[ExtractWord(I + 1, AFieldNames, [','])].AsVariant;
  end;
  Result := VarArrayOf(VA);
end;

function TDynamicRecord.ToString(AAlignValues: Boolean): string;
var
  I  : Integer;
  N  : Integer;
  L  : Integer;
  S  : string;
  T  : string;
  SL : TStringList;
begin
  N := 0;
  SL := TStringList.Create;
  try
    if AAlignValues then
    begin
      for I := 0 to Count - 1 do
      begin
        L := Length(Items[I].Name);
        N := IfThen(L > N, L, N);
      end;
    end;
    for I := 0 to Count - 1 do
    begin
      if AAlignValues then
      begin
        T := Items[I].Value.ToString;
        if T = #0 then
          T := '';
        S := Format('%-*s = %s', [N, Items[I].Name, T])
      end
      else
        S := Items[I].ToString;
      SL.Add(S);
    end;
    Result := Trim(SL.Text);
  finally
    SL.Free;
  end;
end;
{$ENDREGION}
{$ENDREGION}
{$ENDREGION}

{$REGION 'TDynamicField'}
{$REGION 'property access methods'}
function TDynamicField.GetName: string;
begin
  Result := FName;
end;

procedure TDynamicField.SetName(const AValue: string);
begin
  if AValue <> Name then
  begin
    Changed(False);
    FName := AValue;
  end;
end;

function TDynamicField.GetValue: TValue;
begin
  Result := FValue;
end;

procedure TDynamicField.SetValue(const AValue: TValue);
begin
  if AValue.ToString <> FValue.ToString then
  begin
    Changed(False);
    FValue := AValue;
  end;
end;
{$ENDREGION}

{$REGION 'public methods'}
procedure TDynamicField.Assign(Source: TPersistent);
var
  DF : TDynamicField;
begin
 if (Source <> Self) and (Source is TDynamicField) then
 begin
   if Assigned(Collection) then
     Collection.BeginUpdate;
   DF := TDynamicField(Source);
   try
     Value       := DF.Value;
     Name        := DF.Name;
     DisplayName := DF.DisplayName;
   finally
     if Assigned(Collection) then
       Collection.EndUpdate;
   end;
 end
 else
   inherited Assign(Source);
end;

function TDynamicField.ToString: string;
var
  S: string;
begin
  if Value.ToString <> #0 then // Char values are initialized to #0
    S := Value.ToString
  else
    S := '';
  Result := Format('%s = %s', [Name, S])
end;

{$REGION 'IInterface support'}
function TDynamicField.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  Result := E_NOINTERFACE;
end;

function TDynamicField._AddRef: Integer;
begin
  Result := -1;
end;

function TDynamicField._Release: Integer;
begin
  Result := -1;
end;
{$ENDREGION}
{$ENDREGION}
{$ENDREGION}

{$REGION 'TRecord'}
{$REGION 'construction and destruction'}
class function TRecord.Create: TRecord;
begin
  // can be used as a fake parameterless constructor
end;

constructor TRecord.Create(const AInstance: TValue; const AAssignProperties,
  AAssignFields: Boolean);
begin
  if AInstance.IsObject and (AInstance.AsObject is TDataSet) then
    FromDataSet(TDataSet(AInstance.AsObject))
  else
    DynamicRecord.From(AInstance, AAssignProperties, AAssignFields, False, []);
end;

constructor TRecord.Create(const AInstance: TValue; const AAssignProperties,
  AAssignFields, AAssignNulls: Boolean; const ANames: array of string);
begin
  DynamicRecord.From(AInstance, AAssignProperties, AAssignFields, AAssignNulls, ANames);
end;

constructor TRecord.Create(const ARecord: TRecord);
begin
  Assign(ARecord);
end;

class function TRecord.CreateDynamicRecord: IDynamicRecord;
begin
  Result := TDynamicRecord.Create;
end;
{$ENDREGION}

{$REGION 'property access methods'}
function TRecord.GetCount: Integer;
begin
  Result := DynamicRecord.Count;
end;

function TRecord.GetData: Variant;
begin
  FDynamicRecord := MutableClone;
  Result := DynamicRecord.Data;
end;

function TRecord.GetDynamicRecord: IDynamicRecord;
begin
  if not Assigned(FDynamicRecord) then
  begin
    FDynamicRecord := TDynamicRecord.Create;
    FRecRefCount := 0;
  end;
  Result := FDynamicRecord;
end;

function TRecord.GetEnumerator: TRecordEnumerator;
begin
  Result := TRecordEnumerator.Create(DynamicRecord);
end;

function TRecord.GetField(const AName: string): IDynamicField;
begin
  Result := DynamicRecord.Fields[AName];
end;

function TRecord.GetInternalRefCount: Integer;
begin
  Result := FDynamicRecord.RefCount;
end;

function TRecord.GetItem(Index: Integer): IDynamicField;
begin
  Result := DynamicRecord.Items[Index];
end;

function TRecord.GetItemValue(const AName: string): TValue;
begin
  Result := DynamicRecord.Values[AName];
end;

procedure TRecord.SetItemValue(const AName: string; const AValue: TValue);
begin
  FDynamicRecord := MutableClone;
  FDynamicRecord.Values[AName] := AValue;
end;
{$ENDREGION}

{$REGION 'operator overloads'}
class operator TRecord.Implicit(const ASource: IDynamicRecord): TRecord;
begin
  Result.Assign(ASource);
end;

class operator TRecord.Implicit(const ASource: TRecord): Variant;
begin
  Result := ASource.Data;
end;

class operator TRecord.Implicit(const ASource: TRecord): IDynamicRecord;
begin
  if not Assigned(Result) then
    Result := ASource.CreateDynamicRecord;
  Result.Assign(ASource);
end;
{$ENDREGION}

{$REGION 'public methods'}
procedure TRecord.AssignProperty(const AInstance: TValue; const APropertyName,
  AFieldName: string; const AAssignNulls: Boolean);
begin
  DynamicRecord.AssignProperty(
    AInstance, APropertyName, AFieldName, AAssignNulls
  );
end;

function TRecord.ToCommaText: string;
begin
  Result := DynamicRecord.ToCommaText;
end;

function TRecord.ToCommaText(const AFieldNames: string): string;
begin
  Result := DynamicRecord.ToCommaText(AFieldNames);
end;

function TRecord.ToDelimitedText(const AFieldNames, ADelimiter: string;
  AQuoteValues: Boolean; AQuoteChar: Char): string;
begin
  Result := DynamicRecord.ToDelimitedText(
    AFieldNames, ADelimiter, AQuoteValues, AQuoteChar
  );
end;

function TRecord.ToDelimitedText(const ADelimiter: string;
  AQuoteValues: Boolean; AQuoteChar: Char): string;
begin
  Result := DynamicRecord.ToDelimitedText(ADelimiter, AQuoteValues, AQuoteChar);
end;

procedure TRecord.Assign(const ARecord: TRecord; const ANames: array of string);
var
  F : IDynamicField;
  S : string;
begin
  Clear;
  if Length(ANames) = 0 then // assign all fields
  begin
    for F in ARecord do
      Values[F.Name] := F.Value;
  end
  else
  begin
    for S in ANames do
    begin
      if not ARecord.ContainsField(S) then
        raise Exception.CreateFmt(SFieldNotFound, [S]);
      Values[S] := ARecord[S];
    end;
  end;
end;

procedure TRecord.Assign(ADynamicRecord: IDynamicRecord);
begin
  DynamicRecord.Assign(ADynamicRecord);
end;

procedure TRecord.AssignProperty(const AInstance: TValue;
  const APropertyName: string; const AAssignNulls: Boolean);
begin
  AssignProperty(AInstance, APropertyName, '', AAssignNulls);
end;

//procedure TRecord.AssignTo(const AInstance: TValue;
//  const ANames: array of string);
//begin
//  DynamicRecord.AssignTo(AInstance, ANames);
//end;

procedure TRecord.AssignTo(const AValue: TValue; const AAssignProperties,
  AAssignFields, AAssignNulls: Boolean; const ANames: array of string);
begin
  DynamicRecord.AssignTo(
    AValue,
    AAssignProperties,
    AAssignFields,
    AAssignNulls,
    ANames
  );
end;

procedure TRecord.AssignTo(const AValue: TValue; const AAssignProperties,
  AAssignFields, AAssignNulls: Boolean);
begin
  DynamicRecord.AssignTo(
    AValue,
    AAssignProperties,
    AAssignFields,
    AAssignNulls,
    []
  );
end;

procedure TRecord.AssignTo<T>(AInstance: T);
begin
  DynamicRecord.AssignTo(TValue.From<T>(AInstance));
end;

procedure TRecord.AssignTo(AInstance: TValue);
begin
  DynamicRecord.AssignTo(AInstance);
end;

function TRecord.ToVarArray(const AFieldNames: string): Variant;
begin
  Result := DynamicRecord.ToVarArray(AFieldNames);
end;

procedure TRecord.Clear;
begin
  DynamicRecord.Clear;
end;

function TRecord.ContainsField(const AName: string): Boolean;
begin
  Result := DynamicRecord.ContainsField(AName);
end;

function TRecord.DeleteField(const AName: string): Boolean;
begin
  Result := DynamicRecord.DeleteField(AName);
end;

procedure TRecord.From(const AInstance: TValue; const AAssignProperties,
  AAssignFields, AAssignNulls: Boolean; const ANames: array of string);
begin
  DynamicRecord.From(AInstance, AAssignProperties, AAssignFields, AAssignNulls, ANames);
end;

procedure TRecord.From<T>(const AValue: T; const AAssignProperties,
  AAssignFields, AAssignNulls: Boolean);
begin
  DynamicRecord.From(
    TValue.From<T>(AValue),
    AAssignProperties,
    AAssignFields,
    AAssignNulls,
    []
  );
end;

procedure TRecord.From<T>(const AValue: T; const AAssignProperties,
  AAssignFields, AAssignNulls: Boolean; const ANames: array of string);
begin
  DynamicRecord.From(
    TValue.From<T>(AValue),
    AAssignProperties,
    AAssignFields,
    AAssignNulls,
    ANames
  );
end;

{ Makes a copy of the current record of a given dataset by assigning each field
  value of the dataset to a dynamic record field. }

procedure TRecord.FromDataSet(ADataSet: TDataSet; const AAssignNulls: Boolean);
begin
  DynamicRecord.FromDataSet(ADataSet, AAssignNulls);
end;

procedure TRecord.FromStrings(AStrings: TStrings);
begin
  DynamicRecord.FromStrings(AStrings);
end;

function TRecord.IsBlank(const AName: string): Boolean;
var
  TV : TValue;
  V  : Variant;
begin
  if ContainsField(AName) then
  begin
    TV := Values[AName];
    if TV.IsEmpty then
      Result := True
    else if TV.IsType<string> then
    begin
      Result := TV.ToString = '';
    end
    else if TV.IsType<Variant> then
    begin
      V := TV.AsVariant;
      Result := VarIsClear(V) or VarIsNull(V) or VarIsEmpty(V)
        {or VarIsEmptyParam(V)}; // Does not work! Returns not True when
                                 // EmptyParam is passed as a value to a TValue
    end
    else
      Result := False;
  end
  else
  begin
    Result := True;
  end;
end;

function TRecord.IsEmpty: Boolean;
begin
  Result := DynamicRecord.IsEmpty;
end;

{ String representation of the record in the form:
     <Fieldname> = <Fieldvalue>   }

function TRecord.ToString(AAlignValues: Boolean): string;
begin
  Result := DynamicRecord.ToString(AAlignValues);
end;

function TRecord.MutableClone: IDynamicRecord;
var
  N : Integer;
begin
  if not Assigned(FDynamicRecord) then
  begin
    FDynamicRecord := TDynamicRecord.Create;
    FRecRefCount := 0;
    Exit(FDynamicRecord);
  end
  else
  begin
    if FRecRefCount > 0 then
    begin
      Result := FDynamicRecord;
    end
    else
    begin
      N := TDynamicRecord(FDynamicRecord).RefCount;
      if N > 0 then
      begin // create clone
        Result := TDynamicRecord.Create;
        Result.Assign(FDynamicRecord);
        FRecRefCount := 0;
      end
    end;
  end;
end;

function TRecord.ToString(const AName, ADefaultValue: string): string;
begin
  Result := DynamicRecord.ToString(AName, ADefaultValue);
end;

procedure TRecord.ToStrings(AStrings: TStrings);
begin
  DynamicRecord.ToStrings(AStrings);
end;

function TRecord.ToBoolean(const AName: string;
  const ADefaultValue: Boolean): Boolean;
begin
  Result := DynamicRecord.ToBoolean(AName, ADefaultValue);
end;

function TRecord.ToFloat(const AName: string;
  const ADefaultValue: Double): Double;
begin
  Result := DynamicRecord.ToFloat(AName, ADefaultValue);
end;

function TRecord.ToInteger(const AName: string;
  const ADefaultValue: Integer): Integer;
begin
  Result := DynamicRecord.ToInteger(AName, ADefaultValue);
end;
{$ENDREGION}

{$REGION 'TRecordEnumerator'}
{$REGION 'construction and destruction'}
constructor TRecordEnumerator.Create(ARecord: IDynamicRecord);
begin
  FIndex  := -1;
  FRecord := ARecord;
end;
{$ENDREGION}

{$REGION 'public methods'}
function TRecordEnumerator.GetCurrent: IDynamicField;
begin
  Result := FRecord.Items[FIndex];
end;

function TRecordEnumerator.MoveNext: Boolean;
begin
  Result := FIndex < FRecord.Count - 1;
  if Result then
    Inc(FIndex);
end;
{$ENDREGION}
{$ENDREGION}
{$ENDREGION}

{$REGION 'TDynamicRecord<T>'}
{$REGION 'construction and destruction'}
constructor TDynamicRecord<T>.Create;
begin
  inherited Create(TDynamicField<T>);
end;

procedure TDynamicRecord<T>.AfterConstruction;
begin
  inherited AfterConstruction;
  FDataFactory := function: T
  begin
    Result := T.Create; // default constructor
  end;
end;

procedure TDynamicRecord<T>.BeforeDestruction;
begin
  if Assigned(FData) then
    FreeAndNil(FData);
  inherited BeforeDestruction;
end;

constructor TDynamicRecord<T>.Create(AInstance: T);
begin
  inherited Create(TDynamicField<T>);
  Data := AInstance;
end;

constructor TDynamicRecord<T>.Create(ASource: IDynamicRecord<T>);
begin
  inherited Create(TDynamicField<T>);
  Assign(ASource.Data);
end;
{$ENDREGION}

{$REGION 'property access methods'}
function TDynamicRecord<T>.GetCount: Integer;
begin
  Result := Length(RttiContext.GetType(TypeInfo(T)).GetProperties);
end;

function TDynamicRecord<T>.GetData: T;
begin
  if not Assigned(FData) and Assigned(FDataFactory) then
    FData := FDataFactory();
  Result := FData;
end;

procedure TDynamicRecord<T>.SetData(AValue: T);
begin
  if AValue <> Data then
  begin
    From(AValue, True, True, True, []);
  end;
end;

{ Creates an IDynamicField instance on the fly which wraps the actual value. }
function TDynamicRecord<T>.GetItem(Index: Integer): IDynamicField;
var
  P: TRttiProperty;
begin
  Result := TDynamicField<T>.Create(Self);
  P := RttiContext.GetType(TypeInfo(T)).GetProperties[Index];
  Result.Name := P.Name;
  if Assigned(Data) then
    Result.Value := P.GetValue(TObject(Data))
  else
    Result.Value := TValue.Empty;
end;

{ Creates an TValue instance on the fly which wraps the actual value. }
function TDynamicRecord<T>.GetItemValue(const AName: string): TValue;
var
  V         : TValue;
  LType     : TRttiType;
  LProperty : TRttiProperty;
begin
  try
    LType := RttiContext.GetType(TObject(Data).ClassInfo);
    if Assigned(LType) then
    begin
      LProperty :=  LType.GetProperty(AName);
      if Assigned(LProperty) then
        Result := LProperty.GetValue(TObject(Data));
    end;
  except
    Result := TValue.Empty;
  end;
end;

procedure TDynamicRecord<T>.SetItemValue(const AName: string; const AValue: TValue);
var
  V         : TValue;
  LType     : TRttiType;
  LProperty : TRttiProperty;
begin
  LType := RttiContext.GetType(TObject(Data).ClassInfo);
  if Assigned(LType) then
  begin
    LProperty :=  LType.GetProperty(AName);
    if Assigned(LProperty) then
      LProperty.SetValue(TObject(Data), AValue);
  end;
end;

function TDynamicRecord<T>.GetDataFactory: TFunc<T>;
begin
  Result := FDataFactory;
end;

procedure TDynamicRecord<T>.SetDataFactory(const Value: TFunc<T>);
begin
  FDataFactory := Value;
end;
{$ENDREGION}

{$REGION 'public methods'}
procedure TDynamicRecord<T>.Assign(AInstance: T);
begin
  From(AInstance, True, False, False, []);
end;

procedure TDynamicRecord<T>.Assign(ASource: IDynamicRecord<T>);
begin
  Assign(ASource.Data);
end;

function TDynamicRecord<T>.ToString(AAlignValues: Boolean): string;
var
  I  : Integer;
  N  : Integer;
  L  : Integer;
  S  : string;
  U  : string;
  SL : TStringList;
begin
  N := 0;
  SL := TStringList.Create;
  try
    N := 30;
    for I := 0 to Count - 1 do
    begin
      if AAlignValues then
      begin
        S := RttiContext.GetType(TypeInfo(T)).GetProperties[I].Name;
        U := GetItemValue(S).ToString;
        if U = #0 then
          U := '';
        S := Format('%-*s = %s', [N, S, U])
      end
      else
        S := Items[I].ToString;
      SL.Add(S);
    end;
    Result := Trim(SL.Text);
  finally
    SL.Free;
  end;
end;
{$ENDREGION}
{$ENDREGION}

{$REGION 'TDynamicField<T>'}
{$REGION 'construction and destruction'}
procedure TDynamicField<T>.BeforeDestruction;
begin
  Collection := nil;
  inherited BeforeDestruction;
end;
{$ENDREGION}

{$REGION 'property access methods'}
function TDynamicField<T>.GetName: string;
begin
  Result := FName;
end;

procedure TDynamicField<T>.SetName(const AValue: string);
begin
  FName := AValue;
end;

function TDynamicField<T>.GetValue: TValue;
var
  DR : IDynamicRecord<T>;
begin
  if Supports(Collection, IDynamicRecord<T>, DR) then
  begin
    Result := DR.Values[Name]
  end
  else
    Result := TValue.Empty;
end;

procedure TDynamicField<T>.SetValue(const AValue: TValue);
var
  DR : IDynamicRecord;
begin
  if Supports(Collection, IDynamicRecord, DR) then
    DR.Values[Name] :=  AValue;
end;
{$ENDREGION}

{$REGION 'protected methods'}
function TDynamicField<T>.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

function TDynamicField<T>._AddRef: Integer;
begin
  Result := InterlockedIncrement(FRefCount);
end;

function TDynamicField<T>._Release: Integer;
begin
  Result := InterlockedDecrement(FRefCount);
  if Result = 0 then
    Destroy;
end;
{$ENDREGION}
{$ENDREGION}

{$REGION 'TRecord<T>'}
{$REGION 'construction and destruction'}
class function TRecord<T>.Create: TRecord<T>;
begin
  // fake constructor that can be used to assign a new instance to a variable.
end;

constructor TRecord<T>.Create(const ADataFactory: TFunc<T>);
begin
  DynamicRecord.Data := ADataFactory();
end;

constructor TRecord<T>.Create(const AInstance: TValue; const AAssignProperties,
  AAssignFields, AAssignNulls: Boolean; const ANames: array of string);
begin
  DynamicRecord.From(
    AInstance,
    AAssignProperties,
    AAssignFields,
    AAssignNulls,
    ANames
  );
end;

constructor TRecord<T>.Create(const AInstance: TValue; const AAssignProperties,
  AAssignFields: Boolean);
begin
  DynamicRecord.From(
    AInstance,
    AAssignProperties,
    AAssignFields,
    True,
    []
  );
end;

procedure TRecord<T>.Create(const AInstance: TValue;
  const ANames: array of string);
begin
  DynamicRecord.From(
    AInstance,
    True,
    False,
    False,
    ANames
  );
end;

constructor TRecord<T>.Create(AInstance: T);
begin
  DynamicRecord.From(AInstance, True, False, True, []);
end;

constructor TRecord<T>.Create(const ARecord: TRecord<T>);
begin
  Assign(ARecord);
end;

class function TRecord<T>.CreateDynamicRecord(
  const ADataFactory: TFunc<T>): IDynamicRecord<T>;
begin
  Result := TDynamicRecord<T>.Create;
  Result.Data := ADataFactory;
end;

class function TRecord<T>.CreateDynamicRecord(AInstance: T): IDynamicRecord<T>;
begin
  Result := TDynamicRecord<T>.Create;
  Result.Assign(AInstance);
end;

class function TRecord<T>.CreateDynamicRecord: IDynamicRecord<T>;
begin
  Result := TDynamicRecord<T>.Create;
end;
{$ENDREGION}

{$REGION 'property access methods'}
function TRecord<T>.GetCount: Integer;
begin
  Result := DynamicRecord.Count;
end;

function TRecord<T>.GetData: T;
begin
  FDynamicRecord := MutableClone;
  Result := DynamicRecord.Data;
end;

function TRecord<T>.GetDynamicRecord: IDynamicRecord<T>;
begin
  if not Assigned(FDynamicRecord) then
    FDynamicRecord := TDynamicRecord<T>.Create;
  Result := FDynamicRecord;
end;

function TRecord<T>.GetEnumerator: TRecordEnumerator;
begin
  Result := TRecordEnumerator.Create(Self);
end;

function TRecord<T>.GetItemValue(const AName: string): TValue;
begin
  Result := DynamicRecord.Values[AName];
end;

procedure TRecord<T>.SetItemValue(const AName: string; const AValue: TValue);
begin
  FDynamicRecord := MutableClone;
  DynamicRecord.Values[AName] := AValue;
end;
{$ENDREGION}

{$REGION 'operator overloads'}
class operator TRecord<T>.Implicit(const ASource: TRecord<T>): IDynamicRecord;
begin
  if not Assigned(Result) then
    Result := TDynamicRecord.Create;
  Result.Assign(ASource.DynamicRecord);
end;

class operator TRecord<T>.Implicit(const ASource: TRecord<T>): IDynamicRecord<T>;
begin
  if not Assigned(Result) then
    Result := TDynamicRecord<T>.Create;
  Result.Assign(ASource.Data);
end;

class operator TRecord<T>.Implicit(const ASource: TRecord<T>): TRecord;
begin
  Result.From<T>(ASource.Data);
end;

class operator TRecord<T>.Implicit(const ASource: TRecord): TRecord<T>;
begin
  Result.Assign(ASource);
end;
{$ENDREGION}

{$REGION 'public methods'}
function TRecord<T>.ToCommaText: string;
begin
  Result := DynamicRecord.ToCommaText;
end;

function TRecord<T>.ToCommaText(const AFieldNames: string): string;
begin
  Result := DynamicRecord.ToCommaText(AFieldNames);
end;

function TRecord<T>.ToDelimitedText(const ADelimiter: string;
  AQuoteValues: Boolean; AQuoteChar: Char): string;
begin
  Result := DynamicRecord.ToDelimitedText(ADelimiter, AQuoteValues, AQuoteChar);
end;

function TRecord<T>.ToDelimitedText(const AFieldNames, ADelimiter: string;
  AQuoteValues: Boolean; AQuoteChar: Char): string;
begin
  Result := DynamicRecord.ToDelimitedText(
    AFieldNames, ADelimiter, AQuoteValues, AQuoteChar
  );
end;

procedure TRecord<T>.Assign(const ARecord: TRecord);
begin
  DynamicRecord.Assign(ARecord);
end;

procedure TRecord<T>.Assign(ASource: T);
begin
  DynamicRecord.Assign(ASource);
end;

procedure TRecord<T>.AssignProperty(const AInstance: TValue;
  const APropertyName, AFieldName: string; const AAssignNulls: Boolean);
begin
  DynamicRecord.AssignProperty(
    AInstance, APropertyName, AFieldName, AAssignNulls
  );
end;

procedure TRecord<T>.AssignProperty(const AInstance: TValue;
  const APropertyName: string; const AAssignNulls: Boolean);
begin
  DynamicRecord.AssignProperty(AInstance, APropertyName, AAssignNulls);
end;

procedure TRecord<T>.AssignTo(const AInstance: TValue;
  const ANames: array of string);
begin
  DynamicRecord.AssignTo(AInstance, ANames);
end;

procedure TRecord<T>.AssignTo(AInstance: TValue);
begin
  DynamicRecord.AssignTo(AInstance);
end;

function TRecord<T>.ToVarArray(const AFieldNames: string): Variant;
begin
  Result := DynamicRecord.ToVarArray(AFieldNames);
end;

procedure TRecord<T>.Clear;
begin
  DynamicRecord.Clear;
end;

function TRecord<T>.ContainsField(const AName: string): Boolean;
begin
  Result := DynamicRecord.ContainsField(AName);
end;

procedure TRecord<T>.From(const Value: T);
begin
  FDynamicRecord.From(TValue.From<T>(Value), True, False, False, []);
end;

procedure TRecord<T>.FromDataSet(ADataSet: TDataSet;
  const AAssignNulls: Boolean);
begin
  FDynamicRecord.FromDataSet(ADataSet, AAssignNulls);
end;

procedure TRecord<T>.FromStrings(AStrings: TStrings);
begin
  FDynamicRecord.FromStrings(AStrings);
end;

function TRecord<T>.IsBlank(const AName: string): Boolean;
begin
  Result := IsEmpty or (ToString(AName) = '');
end;

function TRecord<T>.IsEmpty: Boolean;
begin
  Result := DynamicRecord.IsEmpty;
end;

function TRecord<T>.MutableClone: IDynamicRecord<T>;
begin
  if not Assigned(FDynamicRecord) then
  begin
    FDynamicRecord := TDynamicRecord<T>.Create;
    Result := FDynamicRecord;
  end
  else if TDynamicRecord<T>(FDynamicRecord).RefCount > 0 then
  begin
    Result := TDynamicRecord<T>.Create;
    Result.Assign(FDynamicRecord);
  end;
end;

function TRecord<T>.ToBoolean(const AName: string;
  const ADefaultValue: Boolean): Boolean;
begin
  Result := DynamicRecord.ToBoolean(AName, ADefaultValue);
end;

function TRecord<T>.ToFloat(const AName: string;
  const ADefaultValue: Double): Double;
begin
  Result := DynamicRecord.ToFloat(AName, ADefaultValue);
end;

function TRecord<T>.ToInteger(const AName: string;
  const ADefaultValue: Integer): Integer;
begin
  Result := DynamicRecord.ToInteger(AName, ADefaultValue);
end;

function TRecord<T>.ToString(const AName, ADefaultValue: string): string;
begin
  Result := DynamicRecord.ToString(AName, ADefaultValue);
end;

function TRecord<T>.ToString(AAlignValues: Boolean): string;
begin
  Result := DynamicRecord.ToString(AAlignValues);
end;

procedure TRecord<T>.ToStrings(AStrings: TStrings);
begin
  DynamicRecord.ToStrings(AStrings);
end;
{$ENDREGION}
{$ENDREGION}
end.
