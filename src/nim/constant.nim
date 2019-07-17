
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

