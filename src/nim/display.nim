include "../../util/hankaku.nim"
import constant
import util

type Vram* = ArithmeticPtr[Color]

type BootInfo* = object
  cyls, leds, vmode, reserve: cuchar
  scrnx*, scrny*: int16
  vram*: Vram

proc `[]`*(this: ptr BootInfo, x, y: int): Color =
  this.vram[x + y * this.scrnx]
proc `[]=`*(this: ptr BootInfo, x, y:int, color: Color) =
  this.vram[x + y * this.scrnx] = color

proc boxfill8*(vram: Vram, xsize: int, color: Color, x0, y0, x1, y1: int) =
  for y in y0 .. y1:
    for x in x0 .. x1:
      vram[x + y*xsize] = color

proc boxfill8*(this: ptr BootInfo, color: Color, x0, y0, x1, y1: int) =
  this.vram.boxfill8(this.scrnx, color, x0, y0, x1, y1)

proc putfont8*(vram: Vram, xsize, x, y: int, color: Color, font: array[16, int8]) =
  for i in 0 ..< 16:
    let d = font[i]
    var mask = 0x80
    for j in 0 ..< 8:
      if(d and mask) != 0: vram[x + j + (y + i)*xsize] = color
      mask = mask shr 1

proc putfont8*(this: ptr BootInfo, x, y: int, color: Color, font: array[16, int8]) =
  this.vram.putfont8(this.scrnx, x, y, color, font)

proc putblock8_8*(this: ptr BootInfo, pxsize, pysize, px0, py0: int, buf: array[16, array[16, Color]]) =
  for x in 0 ..< len(buf):
    for y in 0 ..< len(buf[x]):
      this[px0 + x, py0 + y] = buf[y][x]

proc init_screen*(vram: Vram, xsize, ysize: int) =
  vram.boxfill8(xsize, Color.dark_gray     , 0          , 0         , xsize - 1 , ysize - 29)
  vram.boxfill8(xsize, Color.gray          , 0          , ysize - 28, xsize - 1 , ysize - 28)
  vram.boxfill8(xsize, Color.white         , 0          , ysize - 27, xsize - 1 , ysize - 27)
  vram.boxfill8(xsize, Color.gray          , 0          , ysize - 26, xsize - 1 , ysize - 1 )

  vram.boxfill8(xsize, Color.white         , 3          , ysize - 24, 59        , ysize - 24)
  vram.boxfill8(xsize, Color.white         , 2          , ysize - 24, 2         , ysize - 4 )
  vram.boxfill8(xsize, Color.dark_gray     , 3          , ysize - 4 , 59        , ysize - 4 )
  vram.boxfill8(xsize, Color.dark_gray     , 59         , ysize - 23, 59        , ysize - 5 )
  vram.boxfill8(xsize, Color.black         , 2          , ysize - 3 , 59        , ysize - 3 )
  vram.boxfill8(xsize, Color.black         , 60         , ysize - 24, 60        , ysize - 3 )

  vram.boxfill8(xsize, Color.dark_gray     , xsize - 47 , ysize - 24, xsize - 4 , ysize - 24)
  vram.boxfill8(xsize, Color.dark_gray     , xsize - 47 , ysize - 23, xsize - 47, ysize - 4 )
  vram.boxfill8(xsize, Color.white         , xsize - 47 , ysize - 3 , xsize - 4 , ysize - 3 )
  vram.boxfill8(xsize, Color.white         , xsize - 3  , ysize - 24, xsize - 3 , ysize - 3 )

proc init_screen*(this: ptr BootInfo) =
  this.vram.init_screen(this.scrnx, this.scrny)

proc putasc8*[T](vram: Vram, xsize, x, y: int, color: Color, str: T) =
  var caret = x
  for c in str:
    vram.putfont8(xsize, caret, y, color, fonts[c.ord])
    caret += 8

proc putasc8*[T](this: ptr BootInfo, x, y: int, color: Color, str: T) =
  this.vram.putasc8(this.scrnx, x, y, color, str)

proc putasc8*(this: ptr BootInfo, x, y: int, color: Color, ch: char) =
  this.putfont8(x, y, color, fonts[ch.ord])

proc putasc8_format*[T, I](vram: Vram, xsize, x, y: int, color: Color, str: T, args: varargs[I]) =
  var
    caret = x
    i = 0
    argidx = 0
  while i < str.len:
    if str[i] == '%':
      if (i + 1) < str.len:
        case str[i + 1]:
          of '%':
            vram.putfont8(xsize, caret, y, color, fonts['%'.ord])
            i += 2
            caret += 8
          of 'd', 'x', 'o':
            let N =
              case str[i + 1]:
                of 'd': 10
                of 'x': 16
                of 'o': 8
                else: 10
            let num = args[argidx]
            argidx.inc
            var numstr: array[80, char]
            let cnt = numstr.num2str(num, N)

            for j in countdown(cnt - 1, 0):
              vram.putfont8(xsize, caret, y, color, fonts[numstr[numstr.len - j - 1].ord])
              caret += 8
            i += 2
            caret += 8
          else: # Error case
            discard
    else:
      vram.putfont8(xsize, caret, y, color, fonts[str[i].ord])
      i.inc
      caret += 8

proc putasc8_format*[T, I](this: ptr BootInfo, x, y: int, color: Color, str: T, args: varargs[I]) =
  this.vram.putasc8_format(this.scrnx, x, y, color, str, args)
