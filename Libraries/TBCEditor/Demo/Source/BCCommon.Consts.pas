unit BCCommon.Consts;

interface

uses
  Winapi.Windows, System.Classes;

const
  CHR_ENTER = Chr(13) + Chr(10);
  CHR_DOUBLE_ENTER = CHR_ENTER + CHR_ENTER;

  BONECODE_URL = 'http://www.bonecode.com';
  DONATION_URL = 'https://www.paypal.com/fi/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=C8UTAHKHAFG8L';

  OUTPUT_FILE_SEPARATOR = '@#/%&';

  PARAM_NO_INI = '-noini';
  PARAM_NO_SKIN = '-noskin';

  ShortCuts: array[0..110] of TShortCut = (
    scNone,
    Byte('A') or scCtrl,
    Byte('B') or scCtrl,
    Byte('C') or scCtrl,
    Byte('D') or scCtrl,
    Byte('E') or scCtrl,
    Byte('F') or scCtrl,
    Byte('G') or scCtrl,
    Byte('H') or scCtrl,
    Byte('I') or scCtrl,
    Byte('J') or scCtrl,
    Byte('K') or scCtrl,
    Byte('L') or scCtrl,
    Byte('M') or scCtrl,
    Byte('N') or scCtrl,
    Byte('O') or scCtrl,
    Byte('P') or scCtrl,
    Byte('Q') or scCtrl,
    Byte('R') or scCtrl,
    Byte('S') or scCtrl,
    Byte('T') or scCtrl,
    Byte('U') or scCtrl,
    Byte('V') or scCtrl,
    Byte('W') or scCtrl,
    Byte('X') or scCtrl,
    Byte('Y') or scCtrl,
    Byte('Z') or scCtrl,
    Byte('A') or scCtrl or scAlt,
    Byte('B') or scCtrl or scAlt,
    Byte('C') or scCtrl or scAlt,
    Byte('D') or scCtrl or scAlt,
    Byte('E') or scCtrl or scAlt,
    Byte('F') or scCtrl or scAlt,
    Byte('G') or scCtrl or scAlt,
    Byte('H') or scCtrl or scAlt,
    Byte('I') or scCtrl or scAlt,
    Byte('J') or scCtrl or scAlt,
    Byte('K') or scCtrl or scAlt,
    Byte('L') or scCtrl or scAlt,
    Byte('M') or scCtrl or scAlt,
    Byte('N') or scCtrl or scAlt,
    Byte('O') or scCtrl or scAlt,
    Byte('P') or scCtrl or scAlt,
    Byte('Q') or scCtrl or scAlt,
    Byte('R') or scCtrl or scAlt,
    Byte('S') or scCtrl or scAlt,
    Byte('T') or scCtrl or scAlt,
    Byte('U') or scCtrl or scAlt,
    Byte('V') or scCtrl or scAlt,
    Byte('W') or scCtrl or scAlt,
    Byte('X') or scCtrl or scAlt,
    Byte('Y') or scCtrl or scAlt,
    Byte('Z') or scCtrl or scAlt,
    VK_F1,
    VK_F2,
    VK_F3,
    VK_F4,
    VK_F5,
    VK_F6,
    VK_F7,
    VK_F8,
    VK_F9,
    VK_F10,
    VK_F11,
    VK_F12,
    VK_F1 or scCtrl,
    VK_F2 or scCtrl,
    VK_F3 or scCtrl,
    VK_F4 or scCtrl,
    VK_F5 or scCtrl,
    VK_F6 or scCtrl,
    VK_F7 or scCtrl,
    VK_F8 or scCtrl,
    VK_F9 or scCtrl,
    VK_F10 or scCtrl,
    VK_F11 or scCtrl,
    VK_F12 or scCtrl,
    VK_F1 or scShift,
    VK_F2 or scShift,
    VK_F3 or scShift,
    VK_F4 or scShift,
    VK_F5 or scShift,
    VK_F6 or scShift,
    VK_F7 or scShift,
    VK_F8 or scShift,
    VK_F9 or scShift,
    VK_F10 or scShift,
    VK_F11 or scShift,
    VK_F12 or scShift,
    VK_F1 or scShift or scCtrl,
    VK_F2 or scShift or scCtrl,
    VK_F3 or scShift or scCtrl,
    VK_F4 or scShift or scCtrl,
    VK_F5 or scShift or scCtrl,
    VK_F6 or scShift or scCtrl,
    VK_F7 or scShift or scCtrl,
    VK_F8 or scShift or scCtrl,
    VK_F9 or scShift or scCtrl,
    VK_F10 or scShift or scCtrl,
    VK_F11 or scShift or scCtrl,
    VK_F12 or scShift or scCtrl,
    scCtrl or VK_RETURN,
    scCtrl or VK_SPACE,
    VK_INSERT,
    VK_INSERT or scShift,
    VK_INSERT or scCtrl,
    VK_DELETE,
    VK_DELETE or scShift,
    VK_DELETE or scCtrl,
    VK_BACK or scAlt,
    VK_BACK or scShift or scAlt);

    ToolbarItemsArray: array [1..42] of string = (
      'ActionFileNew',
      'ActionFileOpen',
      '-',
      'ActionFileSave',
      'ActionFileSaveAs',
      'ActionFileSaveAll',
      'ActionFileClose',
      'ActionFileCloseAll',
      '-',
      'ActionFilePrint',
      'ActionFilePrintPreview',
      '-',
      'ActionViewOpenDirectory',
      'ActionViewCloseDirectory',
      'ActionViewEditDirectory',
      '-',
      'ActionEditIndentIncrease',
      'ActionEditIndentDecrease',
      '-',
      'ActionEditSortAsc',
      'ActionEditSortDesc',
      '-',
      'ActionEditToggleCase',
      '-',
      'ActionEditUndo',
      'ActionEditRedo',
      '-',
      'ActionSearchSearchButton',
      'ActionSearchReplace',
      'ActionSearchFindInFiles',
      '-',
      'ActionViewWordWrap',
      'ActionViewLineNumbers',
      'ActionViewSpecialChars',
      'ActionViewSelectionMode',
      'ActionViewMinimap',
      'ActionViewSplit',
      '-',
      'ActionToolsCompareFiles',
      '-',
      'ActionDocumentInfo',
      'ActionDocumentViewInBrowser');

implementation

end.
