include "../../util/hankaku.nim"
import constant
import options

type Vram = distinct ptr cuchar

proc `[]`(vram: Vram, idx: int): cuchar =
  cast[ptr cuchar](cast[int](vram) + idx * sizeof(cuchar))[]
proc `[]=`(vram: Vram, idx: int, color: Color) =
  cast[ptr cuchar](cast[int](vram) + idx * sizeof(cuchar))[] = cast[cuchar](color)

type BootInfo* = object
  cyls, leds, vmode, reserve: cuchar
  scrnx*, scrny*: int16
  vram: Vram

proc `[]`*(binfo: ptr BootInfo, x, y: int): cuchar =
  binfo[].vram[x + y * binfo.scrnx]
proc `[]=`*(binfo: ptr BootInfo, x, y:int, color: Color) =
  binfo[].vram[x + y * binfo.scrnx] = color
proc boxfill8*(binfo: ptr BootInfo, color: Color, x0, y0, x1, y1: int) =
  for y in y0 .. y1:
    for x in x0 .. x1:
      binfo[x, y] = color

proc putfont8*(binfo: ptr BootInfo, x, y: int, color: Color, font: array[16, int8]) =
  for i in 0 ..< 16:
    let d = font[i]
    var mask = 0x80
    for j in 0 ..< 8:
      if(d and mask) != 0: binfo[x + j, y + i] = color
      mask = mask shr 1

proc putblock8_8*(binfo: ptr BootInfo, pxsize, pysize, px0, py0: int, buf: array[16, array[16, Color]]) =
  for x in 0 ..< len(buf):
    for y in 0 ..< len(buf[x]):
      binfo[px0 + x, py0 + y] = buf[y][x]

proc init_screen*(binfo: ptr BootInfo) =
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

proc putfont8_asc*(binfo: ptr BootInfo, x, y: int, color: Color, str: string or cstring) {.noSideEffect.} =
  var caret = x
  for c in str:
    binfo.putfont8(caret, y, color, fonts[ord(c)])
    caret = caret + 8

proc putfont8_asc*(binfo: ptr BootInfo, x, y: int, color: Color, ch: char) {.noSideEffect.} =
  binfo.putfont8(x, y, color, fonts[ord(ch)])

type
  Button* {.pure.} = enum
    Left
    Right
    Center
    Others

  Mouse* = object
    shape*: array[16, array[16, Color]]
    buf*: array[3, cuchar]
    phase*: int
    btn, x*, y*: int

proc `[]`*(mouse: Mouse, row, col: int): Color =
  return mouse.shape[row][col]

proc `[]=`*(mouse: var Mouse, row, col: int, color: Color) =
  mouse.shape[row][col] = color

proc init*(mouse: var Mouse, backgroundcolor: Color) =
  const CURSOR: array[16, string] = [
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
  for x in 0 ..< 16:
    for y in 0 ..< 16:
      if CURSOR[x][y] == '*':
        mouse[x, y] = Color.white
      elif CURSOR[x][y] == 'o':
        mouse[x, y] = Color.black
      elif CURSOR[x][y] == '.':
        mouse[x, y] = backgroundcolor
  mouse.phase = 0

proc decode*(mouse: var Mouse, data: cuchar): bool =
  case mouse.phase:
    of 0:
      mouse.phase = 1
    of 1, 2:
      mouse.buf[mouse.phase - 1] = data
      mouse.phase.inc
    of 3:
      mouse.buf[2] = data
      mouse.btn = cast[int](mouse.buf[0]) and 0x07
      mouse.x =
        if (cast[int](mouse.buf[0]) and 0x10) != 0:
          (cast[int](mouse.buf[1]) or 0xffffff00'i32) + mouse.x
        else:
          cast[int](mouse.buf[1]) + mouse.x
      mouse.y =
        if (cast[int](mouse.buf[0]) and 0x20) != 0:
          -(cast[int](mouse.buf[2]) or 0xffffff00'i32) + mouse.y
        else:
          -cast[int](mouse.buf[2]) + mouse.y
      mouse.phase = 1
      return true
    else:
      discard
  return false

proc button*(mouse: Mouse): Button =
  if (mouse.btn and 0x01) != 0:
    return Button.Left
  elif (mouse.btn and 0x02) != 0:
    return Button.Right
  elif (mouse.btn and 0x04) != 0:
    return Button.Center
  else:
    return Button.Others

