
# <low level functions>
proc io_hlt() =
  asm """
    hlt
  """

proc io_cli() =
  asm """
    cli
  """

proc io_sti() =
  asm """
    sti
  """

proc io_stihlt() =
  asm """
    sti
    hlt
  """

proc io_in8(port: int): int {.importc.}
proc io_in16(port: int): int {.importc.}
proc io_in32(port: int): int {.importc.}

proc io_out8(port: uint16, data: uint16) =
  # %1 expands to %dx because port is a uint16
  asm """
    outb %0, %1
  :
  : "a"(`data`), "Nd"(`port`)
  :
  """

proc io_out16(port: int, data: int) {.importc.}
proc io_out32(port: int, data: int) {.importc.}

proc io_load_eflags(): int {.importc.}
# proc io_load_eflags(): int =
#   let eflag = 0
#   asm """
#     pushfl
#     pop %%eax
#   : "=a"(eflag)
#   """
#   return eflag

proc io_store_eflags(eflags: int) {.importc.}

proc write_mem8(address: int, data: int) =
  cast[ptr int](address)[] = data
# </low level functions>

# <palette>
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
    io_out8(0x03c9, cast[uint16](rgb[rgb_index] shr 2))
    io_out8(0x03c9, cast[uint16](rgb[rgb_index + 1] shr 2))
    io_out8(0x03c9, cast[uint16](rgb[rgb_index + 2] shr 2))
    rgb_index = rgb_index + 3
  io_store_eflags(eflags)

proc init_palette() =
  set_palette(0, 15, table_rgb)
# </palette>

# <util>
# pointer index operator
proc `[]`[T](p: ptr T, index: uint): T =
  cast[ptr T](cast[uint](p) + index)[]
proc `[]=`[T](p: ptr T, index: uint, value: T) =
  cast[ptr T](cast[uint](p) + index)[] = value
# </util>

# <display>
const xsize = 320'u
const ysize = 200'u
# <util for display>
proc `[]`[T](p: ptr T, x, y: uint): T =
  p[x + y*xsize]
proc `[]=`[T](p: ptr T, x, y: uint, value: T) =
  p[x + y*xsize] = value
# </util for display>
proc boxfill8(vram: ptr cuchar, color: Color, x0, y0, x1, y1: uint) =
  for y in y0 .. y1:
    for x in x0 .. x1:
      vram[x, y] = cast[cuchar](color)
# </display>

proc MikanMain() {.exportc.} =
  init_palette()

  let vram = cast[ptr cuchar](0xa0000)
  boxfill8(vram, Color.dark_sky_blue , 0         , 0         , xsize - 1 , ysize - 29)
  boxfill8(vram, Color.grey          , 0         , ysize - 28, xsize - 1 , ysize - 28)
  boxfill8(vram, Color.white         , 0         , ysize - 27, xsize - 1 , ysize - 27)
  boxfill8(vram, Color.grey          , 0         , ysize - 26, xsize - 1 , ysize - 1 )

  boxfill8(vram, Color.white         , 3         , ysize - 24, 59        , ysize - 24)
  boxfill8(vram, Color.white         , 2         , ysize - 24, 2         , ysize - 4 )
  boxfill8(vram, Color.dark_grey     , 3         , ysize - 4 , 59        , ysize - 4 )
  boxfill8(vram, Color.dark_grey     , 59        , ysize - 23, 59        , ysize - 5 )
  boxfill8(vram, Color.black         , 2         , ysize - 3 , 59        , ysize - 3 )
  boxfill8(vram, Color.black         , 60        , ysize - 24, 60        , ysize - 3 )

  boxfill8(vram, Color.dark_grey     , xsize - 47, ysize - 24, xsize - 4 , ysize - 24)
  boxfill8(vram, Color.dark_grey     , xsize - 47, ysize - 23, xsize - 47, ysize - 4 )
  boxfill8(vram, Color.white         , xsize - 47, ysize - 3 , xsize - 4 , ysize - 3 )
  boxfill8(vram, Color.white         , xsize - 3 , ysize - 24, xsize - 3 , ysize - 3 )

  while true:
    io_hlt()


