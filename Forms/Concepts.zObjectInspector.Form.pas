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

unit Concepts.zObjectInspector.Form;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls,
  Vcl.ExtCtrls, Vcl.ButtonGroup, Vcl.StdCtrls,

  Concepts.Types.Contact,

  zObjInspector;

type
  TfrmzObjectInspector = class(TForm)
    pnlMain         : TPanel;
    splSplitter     : TSplitter;
    pnlLeft         : TPanel;
    cbxControls     : TComboBox;
    pnlRight        : TPanel;
    lblLabel        : TLabel;
    btnButton       : TButton;
    chkCheckBox     : TCheckBox;
    edtEdit         : TEdit;
    bgMain          : TButtonGroup;
    trbTrackBar     : TTrackBar;
    edtButtonedEdit : TButtonedEdit;
    sbrStatusBar    : TStatusBar;

    procedure cbxControlsChange(Sender: TObject);

  private
    FObjectInspector : TzObjectInspector;
    FObjectHost      : TzObjectHost;
    FContact         : TContact;

    function FObjectInspectorBeforeAddItem(
      Sender : TControl;
      PItem  : PPropItem
    ): Boolean;

  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

  end;

implementation

{$R *.dfm}

uses
  System.Rtti,

  DDuce.Logger,

  Concepts.Factories;

{$REGION 'construction and destruction'}
procedure TfrmzObjectInspector.AfterConstruction;
var
  I : Integer;
  C : TComponent;
begin
  inherited AfterConstruction;
  FContact := TConceptFactories.CreateRandomContact;
  FObjectInspector                  := TzObjectInspector.Create(Self);
  FObjectInspector.Parent           := pnlLeft;
  FObjectInspector.Align            := alClient;
  FObjectInspector.AlignWithMargins := True;
  FObjectInspector.Name             := 'FObjectInspector';
  FObjectInspector.OnBeforeAddItem  := FObjectInspectorBeforeAddItem;
  FObjectHost := TzObjectHost.Create;
  for I := 0 to ComponentCount - 1 do
  begin
    C := Components[I];
    FObjectHost.AddObject(C, C.Name);
    cbxControls.AddItem(Format('%s: %s', [C.Name, C.ClassName]), C);
  end;
  for I := 0 to bgMain.Images.Count - 1 do
    with bgMain.Items.Add do
      ImageIndex := I;
  FObjectHost.AddObject(FObjectInspector, 'ObjectInspector');
  FObjectInspector.Component := FObjectHost;
  FObjectInspector.SplitterPos := FObjectInspector.Width div 2;
  FObjectInspector.SortByCategory := False;
end;

procedure TfrmzObjectInspector.BeforeDestruction;
begin
  FContact.Free;
  cbxControls.Clear;
  if Assigned(FObjectHost) then
    FObjectHost.Free;
  inherited BeforeDestruction;
end;
{$ENDREGION}

{$REGION 'event handlers'}
function TfrmzObjectInspector.FObjectInspectorBeforeAddItem(Sender: TControl;
  PItem: PPropItem): Boolean;
begin
  Result := not (PItem.Prop.PropertyType is TRttiMethodType);
end;

procedure TfrmzObjectInspector.cbxControlsChange(Sender: TObject);
var
  CBX : TComboBox;
begin
  CBX := Sender as TComboBox;
  if CBX.ItemIndex > -1 then
  begin
    // this assignment will destroy the assigned ObjectHost object!!
    FObjectInspector.Component := CBX.Items.Objects[CBX.ItemIndex];
    FObjectHost := nil;
    FObjectInspector.SortByCategory := False;
  end;
end;
{$ENDREGION}

end.
