include "../../util/hankaku.nim"
import constant
import util

type Vram* = ArithmeticPtr[Color]

type BootInfo* = object
  cyls, leds, vmode, reserve: cuchar
  scrnx*, scrny*: int16
  vram*: Vram

proc `[]`*(this: ptr BootInfo, x, y: int): Color =
  this.vram[x + y * cast[int](this.scrnx)]
proc `[]=`*(this: ptr BootInfo, x, y:int, color: Color) =
  this.vram[x + y * cast[int](this.scrnx)] = color

proc boxfill8*(vram: Vram, xsize: int, color: Color, x0, y0, x1, y1: int) =
  for y in y0 .. y1:
    for x in x0 .. x1:
      if color != Color.invisible:
        vram[x + y * xsize] = color

proc putfont8*(vram: Vram, xsize, x, y: int, color: Color, font: array[16, int8]) =
  for i in 0 ..< 16:
    let d = font[i]
    var mask = 0x80
    for j in 0 ..< 8:
      if(d and mask) != 0: vram[x + j + (y + i)*xsize] = color
      mask = mask shr 1

proc putasc8*[T](vram: Vram, xsize, x, y: int, color: Color, str: T) =
  var caret = x
  for c in str:
    vram.putfont8(xsize, caret, y, color, fonts[c.ord])
    caret += 8

