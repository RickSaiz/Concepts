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

unit DDuce.Logger.Channels.WinIPC;

//{$I DDuce.inc}

interface

uses
  System.Classes, System.SysUtils,

  DDuce.WinIPC.Client,
  DDuce.Logger.Interfaces, DDuce.Logger.Channels.Base;

type
  TWinIPCChannel = class(TCustomLogChannel)
  strict private
    FClient       : TWinIPCClient; // sends to the server
    FBuffer       : TMemoryStream;
    FClearMessage : TLogMessage; // needs to move to logger!

  strict protected
    function GetConnected: Boolean; override;

  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;    

    function Connect: Boolean; override;
    function Disconnect: Boolean; override;

    function Write(const AMsg: TLogMessage): Boolean; override;
  end;

implementation

{$REGION 'construction and destruction'}
procedure TWinIPCChannel.AfterConstruction;
begin
  inherited AfterConstruction;
  FClearMessage.MsgType := Integer(lmtClear);
  FClearMessage.MsgText := '';
  FClearMessage.MsgTime := Now;
  FClearMessage.Data    := nil;
  FBuffer := TMemoryStream.Create;
  FClient := TWinIPCClient.Create;
  FClient.Connect;
end;

procedure TWinIPCChannel.BeforeDestruction;
begin
  FClient.Free;
  FBuffer.Free;
  inherited BeforeDestruction;
end;
{$ENDREGION}

{$REGION 'property access methods'}
function TWinIPCChannel.GetConnected: Boolean;
begin
  Result := FClient.Connected;
end;
{$ENDREGION}

{$REGION 'public methods'}
function TWinIPCChannel.Connect: Boolean;
begin
  Result := FClient.Connect;
  Connected := True;
end;

function TWinIPCChannel.Disconnect: Boolean;
begin
  FClient.Connected := False;
  Result := True;
end;

function TWinIPCChannel.Write(const AMsg: TLogMessage): Boolean;
const
  ZeroBuf: Integer = 0;
var
  TextSize : Integer;
  DataSize : Integer;
begin
  if Active then
  begin
    if not Connected then
      Connect;
    if Connected then
    begin
      TextSize := Length(AMsg.MsgText);
      FBuffer.Seek(0, soFromBeginning);
      FBuffer.WriteBuffer(AMsg.MsgType, SizeOf(Integer));
      FBuffer.WriteBuffer(AMsg.MsgTime, SizeOf(TDateTime));
      FBuffer.WriteBuffer(TextSize, SizeOf(Integer));
      FBuffer.WriteBuffer(AMsg.MsgText[1], TextSize);
      if AMsg.Data <> nil then
      begin
        DataSize := AMsg.Data.Size;
        FBuffer.WriteBuffer(DataSize, SizeOf(Integer));
        AMsg.Data.Position := 0;
        FBuffer.CopyFrom(AMsg.Data, DataSize);
      end
      else
        FBuffer.WriteBuffer(ZeroBuf, SizeOf(Integer)); // necessary?
      FClient.SendStream(FBuffer);
      Result := True;
    end
    else
    begin
      Result := False;
    end;
  end
  else
  begin
    Result := False;
  end;
end;
{$ENDREGION}

end.
