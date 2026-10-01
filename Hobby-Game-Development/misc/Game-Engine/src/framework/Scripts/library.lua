_colors = {
    primary = 10,
    secondary = 9,
    tertiary = 22,
}

_keys = {
    Back     = 8,  -- BACKSPACE key
    Tab      = 9,  -- TAB key
    Enter    = 13, -- ENTER key
    CapsLock = 20, -- CAPS LOCK key
    Escape   = 27, -- ESC key
    Space    = 32, -- SPACEBAR key
    PageUp   = 33, -- PAGE UP key
    PageDown = 34, -- PAGE DOWN key
    End      = 35, -- END key
    Home     = 36, -- HOME key
    Left     = 37, -- LEFT ARROW key
    Up       = 38, -- UP ARROW key
    Right    = 39, -- RIGHT ARROW key
    Down     = 40,  -- DOWN ARROW key
    Select      = 41,  -- SELECT key
    Print       = 42,  -- PRINT key
    Execute     = 43,  -- EXECUTE key
    PrintScreen = 44,  -- PRINT SCREEN key
    Insert      = 45,  -- INS key
    Delete      = 46,  -- DEL key
    Help        = 47,  -- HELP key
    D0          = 48,  -- '0' key (can vary by keyboard)
    D1          = 49,  -- '1' key (can vary by keyboard)
    D2          = 50,  -- '2' key (can vary by keyboard)
    D3          = 51,  -- '3' key (can vary by keyboard)
    D4          = 52,  -- '4' key (can vary by keyboard)
    D5          = 53,  -- '5' key (can vary by keyboard)
    D6          = 54,  -- '6' key (can vary by keyboard)
    D7          = 55,  -- '7' key (can vary by keyboard)
    D8          = 56,  -- '8' key (can vary by keyboard)
    D9          = 57,  -- '9' key (can vary by keyboard)
    A = 65, -- A key
    B = 66, -- B key
    C = 67, -- C key
    D = 68, -- D key
    E = 69, -- E key
    F = 70, -- F key
    G = 71, -- G key
    H = 72, -- H key
    I = 73, -- I key
    J = 74, -- J key
    K = 75, -- K key
    L = 76, -- L key
    M = 77, -- M key
    N = 78, -- N key
    O = 79, -- O key
    P = 80, -- P key
    Q = 81, -- Q key
    R = 82, -- R key
    S = 83, -- S key
    T = 84, -- T key
    U = 85, -- U key
    V = 86, -- V key
    W = 87, -- W key
    X = 88, -- X key
    Y = 89, -- Y key
    Z = 90, -- Z key
    LeftWindows  = 91,  -- Left Windows key
    RightWindows = 92,  -- Right Windows key
    Apps         = 93,  -- Applications key
    Sleep        = 95,  -- Computer Sleep key
    NumPad0     = 96,  -- Numeric keypad 0 key
    NumPad1     = 97,  -- Numeric keypad 1 key
    NumPad2     = 98,  -- Numeric keypad 2 key
    NumPad3     = 99,  -- Numeric keypad 3 key
    NumPad4     = 100, -- Numeric keypad 4 key
    NumPad5     = 101, -- Numeric keypad 5 key
    NumPad6     = 102, -- Numeric keypad 6 key
    NumPad7     = 103, -- Numeric keypad 7 key
    NumPad8     = 104, -- Numeric keypad 8 key
    NumPad9     = 105, -- Numeric keypad 9 key
    Multiply    = 106, -- Multiply key
    Add         = 107, -- Add key
    Separator   = 108, -- Separator key
    Subtract    = 109, -- Subtract key
    Decimal     = 110, -- Decimal key
    Divide      = 111, -- Divide key
    F1          = 112, -- F1 key
    F2          = 113, -- F2 key
    F3          = 114, -- F3 key
    F4          = 115, -- F4 key
    F5          = 116, -- F5 key
    F6          = 117, -- F6 key
    F7          = 118, -- F7 key
    F8          = 119, -- F8 key
    F9          = 120, -- F9 key
    F10         = 121, -- F10 key
    F11         = 122, -- F11 key
    F12         = 123, -- F12 key
    F13         = 124, -- F13 key
    F14         = 125, -- F14 key
    F15         = 126, -- F15 key
    F16         = 127, -- F16 key
    F17         = 128, -- F17 key
    F18         = 129, -- F18 key
    F19         = 130, -- F19 key
    F20         = 131, -- F20 key
    F21         = 132, -- F21 key
    F22         = 133, -- F22 key
    F23         = 134, -- F23 key
    F24         = 135, -- F24 key
    NumLock            = 144, -- NUM LOCK key
    Scroll             = 145, -- SCROLL LOCK key
    LeftShift          = 160, -- Left SHIFT key
    RightShift         = 161, -- Right SHIFT key
    LeftControl        = 162, -- Left CONTROL key
    RightControl       = 163, -- Right CONTROL key
    LeftAlt            = 164, -- Left ALT key
    RightAlt           = 165, -- Right ALT key
    BrowserBack        = 166, -- Browser Back key
    BrowserForward     = 167, -- Browser Forward key
    BrowserRefresh     = 168, -- Browser Refresh key
    BrowserStop        = 169, -- Browser Stop key
    BrowserSearch      = 170, -- Browser Search key
    BrowserFavorites   = 171, -- Browser Favorites key
    BrowserHome        = 172, -- Browser Start and Home key
    VolumeMute         = 173, -- Volume Mute key
    VolumeDown         = 174, -- Volume Down key
    VolumeUp           = 175, -- Volume Up key
    MediaNextTrack     = 176, -- Next Track key
    MediaPreviousTrack = 177, -- Previous Track key
    MediaStop          = 178, -- Stop Media key
    MediaPlayPause     = 179, -- Play/Pause Media key
    LaunchMail         = 180, -- Start Mail key
    SelectMedia        = 181, -- Select Media key
    LaunchApplication1 = 182, -- Start Application 1 key
    LaunchApplication2 = 183, -- Start Application 2 key
    OemSemicolon       = 186, -- OEM Semicolon key (;:)
    OemPlus            = 187, -- '+' key
    OemComma           = 188, -- ',' key
    OemMinus           = 189, -- '-' key
    OemPeriod          = 190, -- '.' key
    OemQuestion        = 191, -- OEM question mark key (/)
    OemTilde           = 192, -- OEM tilde key (~`)
    OemOpenBrackets    = 219, -- OEM open bracket key ([)
    OemPipe            = 220, -- OEM pipe key (\|)
    OemCloseBrackets   = 221, -- OEM close bracket key (])
    OemQuotes          = 222, -- OEM quote key ('")
    Oem8               = 223, -- Miscellaneous OEM key
    OemBackslash       = 226, -- OEM backslash / angle bracket key
    ProcessKey         = 229, -- IME PROCESS key
    Attn               = 246, -- Attn key
    Crsel              = 247, -- CrSel key
    Exsel              = 248, -- ExSel key
    EraseEof           = 249, -- Erase EOF key
    Play               = 250, -- Play key
    Zoom               = 251, -- Zoom key
    Pa1                = 253, -- PA1 key
    OemClear           = 254, -- CLEAR key
    ChatPadGreen       = 202, -- Green ChatPad key
    ChatPadOrange      = 203, -- Orange ChatPad key
    Pause              = 19,  -- PAUSE key
    ImeConvert         = 28,  -- IME Convert key
    ImeNoConvert       = 29,  -- IME NoConvert key
    Kana               = 21,  -- Kana key (Japanese)
    Kanji              = 25,  -- Kanji key (Japanese)
    OemCopy            = 242, -- OEM Copy key
    OemAuto            = 243, -- OEM Auto key
    OemEnlW            = 244 -- OEM Enlarge Window key
}

_keyboard = {
    -- Digits
    ['0'] = _keys.D0,
    ['1'] = _keys.D1,
    ['2'] = _keys.D2,
    ['3'] = _keys.D3,
    ['4'] = _keys.D4,
    ['5'] = _keys.D5,
    ['6'] = _keys.D6,
    ['7'] = _keys.D7,
    ['8'] = _keys.D8,
    ['9'] = _keys.D9,

    -- Letters (case handled by Shift)
    ['A'] = _keys.A, ['a'] = _keys.A,
    ['B'] = _keys.B, ['b'] = _keys.B,
    ['C'] = _keys.C, ['c'] = _keys.C,
    ['D'] = _keys.D, ['d'] = _keys.D,
    ['E'] = _keys.E, ['e'] = _keys.E,
    ['F'] = _keys.F, ['f'] = _keys.F,
    ['G'] = _keys.G, ['g'] = _keys.G,
    ['H'] = _keys.H, ['h'] = _keys.H,
    ['I'] = _keys.I, ['i'] = _keys.I,
    ['J'] = _keys.J, ['j'] = _keys.J,
    ['K'] = _keys.K, ['k'] = _keys.K,
    ['L'] = _keys.L, ['l'] = _keys.L,
    ['M'] = _keys.M, ['m'] = _keys.M,
    ['N'] = _keys.N, ['n'] = _keys.N,
    ['O'] = _keys.O, ['o'] = _keys.O,
    ['P'] = _keys.P, ['p'] = _keys.P,
    ['Q'] = _keys.Q, ['q'] = _keys.Q,
    ['R'] = _keys.R, ['r'] = _keys.R,
    ['S'] = _keys.S, ['s'] = _keys.S,
    ['T'] = _keys.T, ['t'] = _keys.T,
    ['U'] = _keys.U, ['u'] = _keys.U,
    ['V'] = _keys.V, ['v'] = _keys.V,
    ['W'] = _keys.W, ['w'] = _keys.W,
    ['X'] = _keys.X, ['x'] = _keys.X,
    ['Y'] = _keys.Y, ['y'] = _keys.Y,
    ['Z'] = _keys.Z, ['z'] = _keys.Z,

    -- Punctuation / symbols
    [','] = _keys.OemComma,
    ['.'] = _keys.OemPeriod,
    [';'] = _keys.OemSemicolon,
    [':'] = _keys.OemSemicolon, -- shift
    ['['] = _keys.OemOpenBrackets,
    [']'] = _keys.OemCloseBrackets,
    ['{'] = _keys.OemOpenBrackets, -- shift
    ['}'] = _keys.OemCloseBrackets, -- shift
    ['|'] = _keys.OemPipe,
    ['\\'] = _keys.OemPipe,
    ['"'] = _keys.OemQuotes,
    ["'"] = _keys.OemQuotes,
    ['+'] = _keys.OemPlus,
    ['='] = _keys.OemPlus,
    ['-'] = _keys.OemMinus,
    ['_'] = _keys.OemMinus,
    ['*'] = _keys.Multiply,
    ['/'] = _keys.OemQuestion,
    ['?'] = _keys.OemQuestion,
    ['<'] = _keys.OemBackslash,
    ['>'] = _keys.OemBackslash,
    ['~'] = _keys.OemTilde,

    -- Space
    [' '] = _keys.Space,
}

_playerindex = {
    One = 0,
    Two = 1,
    Three = 2,
    Four = 3
}

_gamepadbuttons = {
    None = 0,
    DPadUp = 1,
    DPadDown = 2,
    DPadLeft = 4,
    DPadRight = 8,
    Start = 0x10,
    Back = 0x20,
    LeftStick = 0x40,
    RightStick = 0x80,
    LeftShoulder = 0x100,
    RightShoulder = 0x200,
    BigButton = 0x800,
    A = 0x1000,
    B = 0x2000,
    X = 0x4000,
    Y = 0x8000,
    RightTrigger = 0x400000,
    LeftTrigger = 0x800000,
    RightThumbstickUp = 0x1000000,
    RightThumbstickDown = 0x2000000,
    RightThumbstickRight = 0x4000000,
    RightThumbstickLeft = 0x8000000,
    LeftThumbstickUp = 0x10000000,
    LeftThumbstickDown = 0x20000000,
    LeftThumbstickRight = 0x40000000,
    LeftThumbstickLeft = 0x200000,
}

-- Table functions

function add(t, v, i)
  assert(type(t) == "table", "add: first argument must be a table")
  if v == nil then return nil end
  if i ~= nil then
    table.insert(t, i, v)
  else
    t[#t + 1] = v
  end
  return v
end

function del(t, v)
  assert(type(t) == "table", "del: first argument must be a table")
  for i = 1, #t do
    if t[i] == v then
      table.remove(t, i)
      t.__del_i = i
      return v
    end
  end
end

function all(t)
  assert(type(t) == "table", "all: first argument must be a table")
  local i = 0
  return function()
    if t.__del_i then
      if t.__del_i <= i then i = i - 1 end
      t.__del_i = nil
    end

    i = i + 1
    return t[i]
  end
end

function foreach(t, f)
  assert(type(t) == "table", "foreach: first argument must be a table")
  assert(type(f) == "function", "foreach: second argument must be a function")

  for i = 1, #t do
    f(t[i])
  end
end

-- Math functions

function flr(x)
    return math.floor(x)
end

function clamp(low, b, high)
    return math.min(math.max(b, low), high)
end

function min(low, b)
    return math.min(low,b)
end

function max(b, high)
    return math.max(b,high)
end

function abs(a)
    return math.abs(a)
end

function mid(x, a, b)
  -- ensure a <= b
  if a > b then a, b = b, a end
  if x < a then return a end
  if x > b then return b end
  return x
end