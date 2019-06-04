
const table_rgb: array[16*3, uint8] = [
  0x00'u8, 0x00'u8, 0x00'u8,  # black
  0xff'u8, 0x00'u8, 0x00'u8,  # light red
  0x00'u8, 0xff'u8, 0x00'u8,  # light green
  0xff'u8, 0xff'u8, 0x00'u8,  # light yellow
  0x00'u8, 0x00'u8, 0xff'u8,  # light blue
  0xff'u8, 0x00'u8, 0xff'u8,  # light purple
  0x00'u8, 0xff'u8, 0xff'u8,  # sky blue
  0xff'u8, 0xff'u8, 0xff'u8,  # white
  0xc6'u8, 0xc6'u8, 0xc6'u8,  # grey
  0x84'u8, 0x00'u8, 0x00'u8,  # dark red
  0x00'u8, 0x84'u8, 0x00'u8,  # dark green
  0x84'u8, 0x84'u8, 0x00'u8,  # dark yellow
  0x00'u8, 0x00'u8, 0x84'u8,  # dark blue
  0x84'u8, 0x00'u8, 0x84'u8,  # dark purple
  0x00'u8, 0x84'u8, 0x84'u8,  # dark sky blue
  0x84'u8, 0x84'u8, 0x84'u8   # dark grey
  ]

type Color {.pure.} = enum
  black
  light_red
  light_green
  light_yellow
  light_blue
  light_purple
  sky_blue
  white
  grey
  dark_red
  dark_green
  dark_yellow
  dark_blue
  dark_purple
  dark_sky_blue
  dark_grey

proc set_palette(head, tail: int, rgb: array[16*3, uint8]) =
  let eflags = io_load_eflags()
  io_cli()
  io_out8(0x03c8, cast[uint16](head))
  var rgb_index = 0
  for i in head .. tail:
    for j in 0 ..< 3:
      io_out8(0x03c9, cast[uint16](rgb[rgb_index + j] shr 2))
    rgb_index = rgb_index + 3

  io_store_eflags(eflags)

proc init_palette() =
  set_palette(0, 15, table_rgb)
