include "../../util/hankaku.nim"
import constant

type Vram = distinct ptr cuchar

proc `[]`(vram: Vram, idx: int): cuchar =
  cast[ptr cuchar](cast[int](vram) + idx * sizeof(cuchar))[]
proc `[]=`(vram: Vram, idx: int, color: Color) =
  cast[ptr cuchar](cast[int](vram) + idx * sizeof(cuchar))[] = cast[cuchar](color)

type BootInfo* = object
  cyls, leds, vmode, reserve: cuchar
  scrnx*, scrny*: int16
  vram: Vram

proc `[]`*(this: ptr BootInfo, x, y: int): cuchar =
  this.vram[x + y * this.scrnx]
proc `[]=`*(this: ptr BootInfo, x, y:int, color: Color) =
  this.vram[x + y * this.scrnx] = color
proc boxfill8*(this: ptr BootInfo, color: Color, x0, y0, x1, y1: int) =
  for y in y0 .. y1:
    for x in x0 .. x1:
      this[x, y] = color

proc putfont8*(this: ptr BootInfo, x, y: int, color: Color, font: array[16, int8]) =
  for i in 0 ..< 16:
    let d = font[i]
    var mask = 0x80
    for j in 0 ..< 8:
      if(d and mask) != 0: this[x + j, y + i] = color
      mask = mask shr 1

proc putblock8_8*(this: ptr BootInfo, pxsize, pysize, px0, py0: int, buf: array[16, array[16, Color]]) =
  for x in 0 ..< len(buf):
    for y in 0 ..< len(buf[x]):
      this[px0 + x, py0 + y] = buf[y][x]

proc init_screen*(this: ptr BootInfo) =
  this.boxfill8(Color.dark_grey     , 0                , 0               , this.scrnx - 1 , this.scrny - 29)
  this.boxfill8(Color.grey          , 0                , this.scrny - 28, this.scrnx - 1 , this.scrny - 28)
  this.boxfill8(Color.white         , 0                , this.scrny - 27, this.scrnx - 1 , this.scrny - 27)
  this.boxfill8(Color.grey          , 0                , this.scrny - 26, this.scrnx - 1 , this.scrny - 1 )

  this.boxfill8(Color.white         , 3                , this.scrny - 24, 59              , this.scrny - 24)
  this.boxfill8(Color.white         , 2                , this.scrny - 24, 2               , this.scrny - 4 )
  this.boxfill8(Color.dark_grey     , 3                , this.scrny - 4 , 59              , this.scrny - 4 )
  this.boxfill8(Color.dark_grey     , 59               , this.scrny - 23, 59              , this.scrny - 5 )
  this.boxfill8(Color.black         , 2                , this.scrny - 3 , 59              , this.scrny - 3 )
  this.boxfill8(Color.black         , 60               , this.scrny - 24, 60              , this.scrny - 3 )

  this.boxfill8(Color.dark_grey     , this.scrnx - 47 , this.scrny - 24, this.scrnx - 4 , this.scrny - 24)
  this.boxfill8(Color.dark_grey     , this.scrnx - 47 , this.scrny - 23, this.scrnx - 47, this.scrny - 4 )
  this.boxfill8(Color.white         , this.scrnx - 47 , this.scrny - 3 , this.scrnx - 4 , this.scrny - 3 )
  this.boxfill8(Color.white         , this.scrnx - 3  , this.scrny - 24, this.scrnx - 3 , this.scrny - 3 )

proc putfont8_asc*(this: ptr BootInfo, x, y: int, color: Color, str: string or cstring) =
  var caret = x
  for c in str:
    this.putfont8(caret, y, color, fonts[ord(c)])
    caret = caret + 8

proc putfont8_asc*(this: ptr BootInfo, x, y: int, color: Color, ch: char) =
  this.putfont8(x, y, color, fonts[ord(ch)])

