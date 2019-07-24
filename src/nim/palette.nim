import low_layer
from constant import table_rgb

proc set_palette(head, tail: int, rgb: array[16*3, uint8]) =
  let eflags = io_load_eflags()
  io_cli()
  io_out8(0x03c8, cast[uint16](head))
  var rgb_index = 0
  for i in head .. tail:
    for j in 0 ..< 3:
      io_out8(0x03c9, cast[uint16](rgb[rgb_index + j] shr 2))
    rgb_index += 3

  io_store_eflags(eflags)

proc init_palette*() =
  set_palette(0, 15, table_rgb)

