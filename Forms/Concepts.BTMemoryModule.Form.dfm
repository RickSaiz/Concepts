object frmBTMemoryModule: TfrmBTMemoryModule
  Left = 0
  Top = 0
  Caption = 'BTMemoryModule'
  ClientHeight = 41
  ClientWidth = 236
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object btnExecuteFromDLL: TButton
    Left = 8
    Top = 8
    Width = 129
    Height = 25
    Action = actExecuteFromDLL
    TabOrder = 0
  end
  object aclMain: TActionList
    Left = 168
    Top = 65528
    object actExecuteFromDLL: TAction
      Caption = 'Execute DLL from file'
      OnExecute = actExecuteFromDLLExecute
    end
  end
end
