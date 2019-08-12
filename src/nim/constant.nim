import util

const
  ADR_IDT* = 0x0026f800
  LIMIT_IDT* = 0x000007ff
  ADR_GDT* = 0x00270000
  LIMIT_GDT* = 0x0000ffff
  ADR_BOTPAK* = 0x00280000
  LIMIT_BOTPAK* = 0x0007ffff
  AR_DATA32_RW* = 0x4092
  AR_CODE32_ER* = 0x409a
  AR_INTGATE32* = 0x008e

  ADR_BOOTINFO* = 0x0ff0

  PIC0_ICW1* = 0x0020
  PIC0_OCW2* = 0x0020
  PIC0_IMR* = 0x0021
  PIC0_ICW2* = 0x0021
  PIC0_ICW3* = 0x0021
  PIC0_ICW4* = 0x0021
  PIC1_ICW1* = 0x00a0
  PIC1_OCW2* = 0x00a0
  PIC1_IMR* = 0x00a1
  PIC1_ICW2* = 0x00a1
  PIC1_ICW3* = 0x00a1
  PIC1_ICW4* = 0x00a1

  PORT_KEYDAT* = 0x0060
  PORT_KEYSTA* = 0x0064
  PORT_KEYCMD* = 0x0064
  KEYSTA_SEND_NOTREADY* = 0x02
  KEYCMD_WRITE_MODE* = 0x60
  KBC_MODE* = 0x47

  KEYCMD_SENDTO_MOUSE* = 0xd4
  MOUSECMD_ENABLE* = 0xf4

  MEMORY_ADDRESS* = 0x003c0000

  table_rgb*: array[16*3, uint8] = [
    0x00'u8, 0x00'u8, 0x00'u8,  # black
    0xff'u8, 0x00'u8, 0x00'u8,  # light red
    0x00'u8, 0xff'u8, 0x00'u8,  # light green
    0xff'u8, 0xff'u8, 0x00'u8,  # light yellow
    0x00'u8, 0x00'u8, 0xff'u8,  # light blue
    0xff'u8, 0x00'u8, 0xff'u8,  # light purple
    0x00'u8, 0xff'u8, 0xff'u8,  # sky blue
    0xff'u8, 0xff'u8, 0xff'u8,  # white
    0xc6'u8, 0xc6'u8, 0xc6'u8,  # gray
    0x84'u8, 0x00'u8, 0x00'u8,  # dark red
    0x00'u8, 0x84'u8, 0x00'u8,  # dark green
    0x84'u8, 0x84'u8, 0x00'u8,  # dark yellow
    0x00'u8, 0x00'u8, 0x84'u8,  # dark blue
    0x84'u8, 0x00'u8, 0x84'u8,  # dark purple
    0x00'u8, 0x84'u8, 0x84'u8,  # dark sky blue
    0x84'u8, 0x84'u8, 0x84'u8   # dark gray
    ]

type Color* {.pure.} = enum
  black
  light_red
  light_green
  light_yellow
  light_blue
  light_purple
  sky_blue
  white
  gray
  dark_red
  dark_green
  dark_yellow
  dark_blue
  dark_purple
  dark_sky_blue
  dark_gray
  invisible

type
  FifoKind* {.pure.} = enum
    Keyboard
    Mouse
    Timer

  FifoDataType* = uint8
  FifoType* = tuple
    data: FifoDataType
    kind: FifoKind

const FifoSize* = 500

type KeyCode* {.pure.} = enum
  Esc = (0x01, "")
  Num_1 = "1"
  Num_2 = "2"
  Num_3 = "3"
  Num_4 = "4"
  Num_5 = "5"
  Num_6 = "6"
  Num_7 = "7"
  Num_8 = "8"
  Num_9 = "9"
  Num_0 = "0"
  Minus = "-"
  Caret = "^"
  BackSpace = ""
  Tab = ""
  Q = "q"
  W = "w"
  E = "e"
  R = "r"
  T = "t"
  Y = "y"
  U = "u"
  I = "i"
  O = "o"
  P = "p"
  AtSign = "@"
  LeftBracket = "]"
  Enter = ""
  LeftCtrl = ""
  A = "a"
  S = "s"
  D = "d"
  F = "f"
  G = "g"
  H = "h"
  J = "j"
  K = "k"
  L = "l"
  Semicolon = ";"
  Colon = ":"
  ZenkakuHankaku = ""
  LeftShift = ""
  RightBracket = "]"
  Z = "z"
  X = "x"
  C = "c"
  V = "v"
  B = "b"
  N = "n"
  M = "m"
  Comma = ","
  Dot = "."
  Slash = "/"
  RightShift = ""
  kNumAsterisk = "*"
  LeftAlt = ""
  Space = " "
  CapsLock = ""
  F1 = ""
  F2 = ""
  F3 = ""
  F4 = ""
  F5 = ""
  F6 = ""
  F7 = ""
  F8 = ""
  F9 = ""
  F10 = ""
  NumLock = ""
  ScrollLock = ""
  kNum_7 = "7"
  kNum_8 = "8"
  kNum_9 = "9"
  kNumMinus = "-"
  kNum_4 = "4"
  kNum_5 = "5"
  kNum_6 = "6"
  kNumPlus = "-"
  kNum_1 = "1"
  kNum_2 = "2"
  kNum_3 = "3"
  kNum_0 = "0"
  kNum_Dot = "."
  SysReq = ""
  F11 = (0x57, "")
  F12 = ""
  Hiragana = (0x70, "")
  Underscore = (0x73, "")
  Henkan = (0x79, "")
  Muhenkan = (0x7B, "")
  Backslash = (0x7D, "")

const KeyTable* = [
  '\0', '\0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0',
  '-', '^', '\0', '\0', 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P',
  '@', '[', '\0', '\0', 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L',
  ';', ':', '\0', '\0', ']', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', ',', '.', '/',
  '\0', '*', '\0', ' ', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0',
  '\0', '\0', '\0', '\0', '7', '8', '9', '-', '4', '5', '6', '+', '1', '2', '3', '0', '.'
]
