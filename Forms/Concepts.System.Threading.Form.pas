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

{$I Concepts.inc}

unit Concepts.System.Threading.Form;

{ Demonstration of the new Delphi XE7 - System.Threading unit, which is also
  sometimes referenced to as the 'Parallel Programming Library'. }

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.Actions,
  Vcl.ActnList, cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  dxorgchr;

type
  TfrmThreading = class(TForm)
    aclMain: TActionList;

    procedure FormCreate(Sender: TObject);
  end;

implementation

{$R *.dfm}

{$IFDEF DELPHIXE7UP}
uses
  System.Threading;
{$ENDIF}

procedure TfrmThreading.FormCreate(Sender: TObject);
{$IFDEF DELPHIXE7UP}
var
  T : TProc<Integer>;
{$ENDIF}
begin
  {$IFDEF DELPHIXE7UP}
  TParallel.For(1, 10, T);
  {$ENDIF}
end;

end.
