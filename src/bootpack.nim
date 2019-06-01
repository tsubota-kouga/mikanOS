include "../util/hankaku.nim"
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

proc io_out16(port, data: int) {.importc.}
proc io_out32(port, data: int) {.importc.}

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

proc load_gdtr(limit, address: int) {.importc.}
proc load_idtr(limit, address: int) {.importc.}

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

# <display>
type Vram = distinct ptr cuchar

proc `[]`(vram: Vram, idx: uint): cuchar =
  cast[ptr cuchar](cast[uint](vram) + idx)[]
proc `[]=`(vram: Vram, idx: uint, color: Color) =
  cast[ptr cuchar](cast[uint](vram) + idx)[] = cast[cuchar](color)

type BootInfo = object
  cyls, leds, vmode, reserve: cuchar
  scrnx, scrny: uint16
  vram: Vram

proc `[]`(binfo: BootInfo, x, y: uint): cuchar =
  binfo.vram[x + y * binfo.scrnx]
proc `[]=`(binfo: BootInfo, x, y:uint, color: Color) =
  binfo.vram[x + y * binfo.scrnx] = color
proc boxfill8(binfo: BootInfo, color: Color, x0, y0, x1, y1: uint) =
  for y in y0 .. y1:
    for x in x0 .. x1:
      binfo[x, y] = color

proc putfont8(binfo: BootInfo, x, y: uint, color: Color, font: array[16, int8]) =
  for i in 0'u ..< 16:
    let d = font[i]
    if (d and 0x80) != 0: binfo[x + 0, y + i] = color
    if (d and 0x40) != 0: binfo[x + 1, y + i] = color
    if (d and 0x20) != 0: binfo[x + 2, y + i] = color
    if (d and 0x10) != 0: binfo[x + 3, y + i] = color
    if (d and 0x08) != 0: binfo[x + 4, y + i] = color
    if (d and 0x04) != 0: binfo[x + 5, y + i] = color
    if (d and 0x02) != 0: binfo[x + 6, y + i] = color
    if (d and 0x01) != 0: binfo[x + 7, y + i] = color

proc putblock8_8(binfo: BootInfo, pxsize, pysize, px0, py0: uint, buf: ptr cuchar, bxsize: int) =
  for x in 0 ..< bxsize:
    for y in 0 ..< bxsize:
      let c = cast[Color](cast[ptr cuchar]((cast[int](buf) + x * bxsize + y))[])
      binfo[px0 + cast[uint](x), py0 + cast[uint](y)] = c

proc init_screen(binfo: BootInfo) =
  binfo.boxfill8(Color.dark_grey     , 0                , 0               , binfo.scrnx - 1 , binfo.scrny - 29)
  binfo.boxfill8(Color.grey          , 0                , binfo.scrny - 28, binfo.scrnx - 1 , binfo.scrny - 28)
  binfo.boxfill8(Color.white         , 0                , binfo.scrny - 27, binfo.scrnx - 1 , binfo.scrny - 27)
  binfo.boxfill8(Color.grey          , 0                , binfo.scrny - 26, binfo.scrnx - 1 , binfo.scrny - 1 )

  binfo.boxfill8(Color.white         , 3                , binfo.scrny - 24, 59              , binfo.scrny - 24)
  binfo.boxfill8(Color.white         , 2                , binfo.scrny - 24, 2               , binfo.scrny - 4 )
  binfo.boxfill8(Color.dark_grey     , 3                , binfo.scrny - 4 , 59              , binfo.scrny - 4 )
  binfo.boxfill8(Color.dark_grey     , 59               , binfo.scrny - 23, 59              , binfo.scrny - 5 )
  binfo.boxfill8(Color.black         , 2                , binfo.scrny - 3 , 59              , binfo.scrny - 3 )
  binfo.boxfill8(Color.black         , 60               , binfo.scrny - 24, 60              , binfo.scrny - 3 )

  binfo.boxfill8(Color.dark_grey     , binfo.scrnx - 47 , binfo.scrny - 24, binfo.scrnx - 4 , binfo.scrny - 24)
  binfo.boxfill8(Color.dark_grey     , binfo.scrnx - 47 , binfo.scrny - 23, binfo.scrnx - 47, binfo.scrny - 4 )
  binfo.boxfill8(Color.white         , binfo.scrnx - 47 , binfo.scrny - 3 , binfo.scrnx - 4 , binfo.scrny - 3 )
  binfo.boxfill8(Color.white         , binfo.scrnx - 3  , binfo.scrny - 24, binfo.scrnx - 3 , binfo.scrny - 3 )
# </display>
# <font>
proc putfont8_asc(binfo: BootInfo, x, y: uint, color: Color, str: string) {.noSideEffect.} =
  var caret = x
  for c in str:
    binfo.putfont8(caret, y, color, fonts[ord(c)])
    caret = caret + 8
# </font>
# <mouse>
const cursor: array[16, string] = [
  "*...............",
  "*o*.............",
  "*oo*............",
  "*ooo*...........",
  "*oooo*..........",
  "*ooooo*.........",
  "*oooooo*........",
  "*ooooooo*.......",
  "*ooooo*.........",
  "*oo*o*..........",
  "*o**oo*.........",
  "**..*oo*........",
  ".....**.........",
  "................",
  "................",
  "................",
]

{.emit: """
static unsigned char mouse[16][8] = {};
unsigned char* getmouse() { return mouse; }
""".}
proc getmouse(): ptr cuchar {.importc.}
let mouse: ptr cuchar = getmouse()
proc init_mouse_cursor8(backgroundcolor: Color) =
  for x in 0 ..< 16:
    for y in 0 ..< 16:
      if cursor[x][y] == '*':
        cast[ptr cuchar](cast[uint](mouse) + cast[uint](x + y*16))[] = cast[cuchar](Color.white)
      elif cursor[x][y] == 'o':
        cast[ptr cuchar](cast[uint](mouse) + cast[uint](x + y*16))[] = cast[cuchar](Color.black)
      elif cursor[x][y] == '.':
        cast[ptr cuchar](cast[uint](mouse) + cast[uint](x + y*16))[] = cast[cuchar](backgroundcolor)

# </mouse>
# <gdt/idt>
type
  SegmentDescripter = object
    limit_low, base_low: int16
    base_mid, access_right: char
    limit_high, base_high: char

  GateDescripter = object
    offset_low, selector: int16
    dw_count, access_right: char
    offset_high: int16

var
  gdt: ptr SegmentDescripter
  idt: ptr GateDescripter

proc set_segmdesc(sd: ptr SegmentDescripter, limit: uint, base, ar: int) =
  var
    limit = limit
    base = base
    ar = ar
  if limit > 0xfffff'u:
    ar = ar or 0x8000
    limit = limit div 0x1000
  sd.limit_low = cast[int16](limit and 0xffff)
  sd.base_low = cast[int16](base and 0xffff)
  sd.base_mid = cast[char]((base shr 16) and 0xff)
  sd.access_right = cast[char](ar and 0xff)
  sd.base_high = cast[char]((base shr 24) and 0xff)

proc set_gatedisc(gd: ptr GateDescripter, offset, selector, ar: int) =
  var
    offset = offset
    ar = ar
  gd.offset_low = cast[int16](offset and 0xffff)
  gd.selector = cast[int16](selector)
  gd.dw_count = cast[char]((ar shr 8) and 0xff)
  gd.access_right = cast[char](ar and 0xff)
  gd.offset_high = cast[int16]((offset shr 16) and 0xffff)

proc init_gdtidt() =
  gdt = cast[ptr SegmentDescripter](0x00270000)
  idt = cast[ptr GateDescripter](0x0026f800)
  for i in 0'u ..< 8192:
    set_segmdesc(cast[ptr SegmentDescripter](cast[uint](gdt) + i), 0, 0, 0)
  set_segmdesc(cast[ptr SegmentDescripter](cast[uint](gdt) + 1'u), 0xffffffff'u, 0x00000000, 0x4092)
  set_segmdesc(cast[ptr SegmentDescripter](cast[uint](gdt) + 2'u), 0x0007ffff'u, 0x00280000, 0x409a)
  load_gdtr(0xffff, 0x00270000)

  for i in 0'u ..< 256:
    set_gatedisc(cast[ptr GateDescripter](cast[uint](idt) + i), 0, 0, 0)
  load_idtr(0x7ff, 0x0026f800)

# </gdt/idt>

proc MikanMain() {.exportc.} =

  const binfo = cast[ptr BootInfo](0x0ff0)

  init_gdtidt()
  init_palette()
  init_mouse_cursor8(Color.dark_grey)
  binfo[].init_screen()
  binfo[].putfont8_asc(9, 9, Color.white, "ABC 123")
  binfo[].putfont8_asc(8, 8, Color.black, "ABC 123")

  binfo[].putblock8_8(16, 16, 100, 100, mouse, 16)

  while true:
    io_hlt()


