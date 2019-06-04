
const ADR_BOOTINFO = 0x0ff0

type Vram = distinct ptr cuchar

proc `[]`(vram: Vram, idx: int): cuchar =
  cast[ptr cuchar](cast[int](vram) + idx * sizeof(cuchar))[]
proc `[]=`(vram: Vram, idx: int, color: Color) =
  cast[ptr cuchar](cast[int](vram) + idx * sizeof(cuchar))[] = cast[cuchar](color)

type BootInfo = object
  cyls, leds, vmode, reserve: cuchar
  scrnx, scrny: int16
  vram: Vram

proc `[]`(binfo: BootInfo, x, y: int): cuchar =
  binfo.vram[x + y * binfo.scrnx]
proc `[]=`(binfo: BootInfo, x, y:int, color: Color) =
  binfo.vram[x + y * binfo.scrnx] = color
proc boxfill8(binfo: BootInfo, color: Color, x0, y0, x1, y1: int) =
  for y in y0 .. y1:
    for x in x0 .. x1:
      binfo[x, y] = color

proc putfont8(binfo: BootInfo, x, y: int, color: Color, font: array[16, int8]) =
  for i in 0 ..< 16:
    let d = font[i]
    var mask = 0x80
    for j in 0 ..< 8:
      if(d and mask) != 0: binfo[x + j, y + i] = color
      mask = mask shr 1

proc putblock8_8(binfo: BootInfo, pxsize, pysize, px0, py0: int, buf: ptr cuchar, bxsize: int) =
  for x in 0 ..< bxsize:
    for y in 0 ..< bxsize:
      binfo[px0 + x, py0 + y] = cast[Color]((buf + (x * bxsize + y))[])

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

proc putfont8_asc(binfo: BootInfo, x, y: int, color: Color, str: string) {.noSideEffect.} =
  var caret = x
  for c in str:
    binfo.putfont8(caret, y, color, fonts[ord(c)])
    caret = caret + 8

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
  "**..*o*.........",
  ".....**.........",
  "................",
  "................",
  "................",
]

{.emit: """
static unsigned char mouse[16][16] = {};
unsigned char* getmouse() { return mouse; }
""".}
proc getmouse(): ptr cuchar {.importc.}
let mouse: ptr cuchar = getmouse()
proc init_mouse_cursor8(backgroundcolor: Color) =
  for x in 0 ..< 16:
    for y in 0 ..< 16:
      if cursor[x][y] == '*':
        (mouse + cast[int](x + y*16))[] = cast[cuchar](Color.white)
      elif cursor[x][y] == 'o':
        (mouse + cast[int](x + y*16))[] = cast[cuchar](Color.black)
      elif cursor[x][y] == '.':
        (mouse + cast[int](x + y*16))[] = cast[cuchar](backgroundcolor)

