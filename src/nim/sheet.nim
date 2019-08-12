import memory
import constant
import display
import util

const MaxSheets = 256
type
  UseFlag {.size: sizeof(bool).} = enum
    Unused
    Used

  VramMap = ArithmeticPtr[int16]
  Sheet* = object
    buf*: Vram
    bxsize, bysize: int
    vx0, vy0: int
    col_inv, height: int
    flags: UseFlag
    ctl: ptr SheetControl

  SheetControl = object
    vram: Vram
    map: VramMap
    xsize, ysize, top: int
    sheets: array[MaxSheets, ptr Sheet]
    sheets0: array[MaxSheets, Sheet]

proc bysize*(sht: ptr Sheet): int =
  sht.bysize
proc bxsize*(sht: ptr Sheet): int =
  sht.bxsize

proc createSheetControl*(m: MemoryManager, vram: Vram, xsize, ysize: int): ptr SheetControl =
  let ctl = cast[ptr SheetControl](m.alloc4k(cast[uint](sizeof(SheetControl))))
  if ctl.isNil:
    return nil
  ctl.map = cast[VramMap](m.alloc4k(cast[uint](xsize*ysize*sizeof(int16))))
  if cast[pointer](ctl.map).isNil:
    m.free4k(cast[uint](ctl), cast[uint](sizeof(SheetControl)))
    return nil
  ctl.vram = vram
  ctl.xsize = xsize
  ctl.ysize = ysize
  ctl.top = -1
  for sheet0 in ctl.sheets0.mitems:
    sheet0.flags = Unused
    sheet0.ctl = ctl
  return ctl

proc alloc*(ctl: ptr SheetControl): ptr Sheet =
  var sht: ptr Sheet
  for i in 0 ..< MaxSheets:
    if ctl.sheets0[i].flags == Unused:
      sht = ctl.sheets0[i].addr
      sht.flags = Used
      sht.height = -1
      return sht
  return nil

proc setbuf*(sht: ptr Sheet, buf: Vram, xsize, ysize: int) =
  sht.buf = buf
  sht.bxsize = xsize
  sht.bysize = ysize

proc refreshMap(ctl: ptr SheetControl, vx0, vy0, vx1, vy1, h0: int) =
  var map = ctl.map
  let
    vx0 = if vx0 < 0: 0 else: vx0
    vy0 = if vy0 < 0: 0 else: vy0
    vx1 = if vx1 > ctl.xsize: ctl.xsize else: vx1
    vy1 = if vy1 > ctl.ysize: ctl.ysize else: vy1

  for h in h0 .. ctl.top:
    let
      sht = ctl.sheets[h]
      sid = cast[int16](cast[int](sht) - cast[int](ctl.sheets0))
    var
      buf = sht.buf
      bx0 = vx0 - sht.vx0
      by0 = vy0 - sht.vy0
      bx1 = vx1 - sht.vx0
      by1 = vy1 - sht.vy0
    if bx0 < 0: bx0 = 0
    if by0 < 0: by0 = 0
    if bx1 > sht.bxsize: bx1 = sht.bxsize
    if by1 > sht.bysize: by1 = sht.bysize
    for by in by0 ..< by1:
      let vy = sht.vy0 + by
      for bx in bx0 ..< bx1:
        let vx = sht.vx0 + bx
        if buf[by*sht.bxsize + bx] != Color.invisible:
          map[vy * ctl.xsize + vx] = sid

proc refreshSub(ctl: ptr SheetControl, vx0, vy0, vx1, vy1, h0, h1: int) =
  var
    vram = ctl.vram
    map = ctl.map
  let
    vx0 = if vx0 < 0: 0 else: vx0
    vy0 = if vy0 < 0: 0 else: vy0
    vx1 = if vx1 > ctl.xsize: ctl.xsize else: vx1
    vy1 = if vy1 > ctl.ysize: ctl.ysize else: vy1

  for h in h0 .. h1:
    let
      sht = ctl.sheets[h]
      sid = cast[int16](cast[int](sht) - cast[int](ctl.sheets0))
    var
      buf = sht.buf
      bx0 = vx0 - sht.vx0
      by0 = vy0 - sht.vy0
      bx1 = vx1 - sht.vx0
      by1 = vy1 - sht.vy0
    if bx0 < 0: bx0 = 0
    if by0 < 0: by0 = 0
    if bx1 > sht.bxsize: bx1 = sht.bxsize
    if by1 > sht.bysize: by1 = sht.bysize
    for by in by0 ..< by1:
      let vy = sht.vy0 + by
      for bx in bx0 ..< bx1:
        let
          vx = sht.vx0 + bx
          c = buf[by * sht.bxsize + bx]
        if map[vy*ctl.xsize + vx] == sid:
          vram[vy*ctl.xsize + vx] = c


proc refresh*(sht: ptr Sheet, bx0, by0, bx1, by1: int) =
  if sht.height >= 0:
    sht.ctl.refreshSub(
      sht.vx0 + bx0,
      sht.vy0 + by0,
      sht.vx0 + bx1,
      sht.vy0 + by1,
      sht.height,
      sht.height
    )

proc sheetUpdown*(sht: ptr Sheet, height: int) =
  var
    old = sht.height
    height =
      if height > sht.ctl.top + 1:
        sht.ctl.top + 1
      elif height < -1:
        -1
      else:
        height

  sht.height = height
  if old > height:
    if height >= 0:
      for h in countdown(old, height + 1):
        sht.ctl.sheets[h] = sht.ctl.sheets[h - 1]
        sht.ctl.sheets[h].height = h
      sht.ctl.sheets[height] = sht
      sht.ctl.refreshMap(
        sht.vx0, sht.vy0,
        sht.vx0 + sht.bxsize, sht.vy0 + sht.bysize,
        height + 1)
      sht.ctl.refreshSub(
        sht.vx0, sht.vy0,
        sht.vx0 + sht.bxsize, sht.vy0 + sht.bysize,
        height + 1, old)
    else:
      if sht.ctl.top > old:
        for h in old ..< sht.ctl.top:
          sht.ctl.sheets[h] = sht.ctl.sheets[h + 1]
          sht.ctl.sheets[h].height = h
      sht.ctl.top.dec
      sht.ctl.refreshMap(
        sht.vx0, sht.vy0,
        sht.vx0 + sht.bxsize, sht.vy0 + sht.bysize,
        0
      )
      sht.ctl.refreshSub(
        sht.vx0, sht.vy0,
        sht.vx0 + sht.bxsize, sht.vy0 + sht.bysize,
        0, old - 1
      )
  elif old < height:
    if old >= 0:
      for h in old ..< height:
        sht.ctl.sheets[h] = sht.ctl.sheets[h + 1]
        sht.ctl.sheets[h].height = h
      sht.ctl.sheets[height] = sht
    else:
      for h in countdown(sht.ctl.top, height):
        sht.ctl.sheets[h + 1] = sht.ctl.sheets[h]
        sht.ctl.sheets[h + 1].height = h + 1
      sht.ctl.sheets[height] = sht
      sht.ctl.top.inc
    sht.ctl.refreshMap(
      sht.vx0, sht.vy0,
      sht.vx0 + sht.bxsize, sht.vy0 + sht.bysize,
      height
    )
    sht.ctl.refreshSub(
      sht.vx0, sht.vy0,
      sht.vx0 + sht.bxsize, sht.vy0 + sht.bysize,
      height, height
    )

proc sheetSlide*(sht: ptr Sheet, vx0, vy0: int) =
  var
    oldvx0 = sht.vx0
    oldvy0 = sht.vy0
  sht.vx0 = vx0
  sht.vy0 = vy0
  if sht.height >= 0:
    sht.ctl.refreshMap(
      oldvx0, oldvy0,
      oldvx0 + sht.bxsize, oldvy0 + sht.bysize,
      0
    )
    sht.ctl.refreshMap(
      vx0, vy0,
      vx0 + sht.bxsize, vy0 + sht.bysize,
      sht.height
    )
    sht.ctl.refreshSub(
      oldvx0, oldvy0,
      oldvx0 + sht.bxsize, oldvy0 + sht.bysize,
      0, sht.height - 1
    )
    sht.ctl.refreshSub(
      vx0, vy0,
      vx0 + sht.bxsize, vy0 + sht.bysize,
      sht.height, sht.height
    )

proc sheetFree(sht: ptr Sheet) =
  if sht.height >= 0:
    sht.sheetUpdown(-1)
  sht.flags = Unused

proc putasc8*(sht: ptr Sheet, x, y: int, color, background_color: Color, c: char) =
  sht.buf.boxfill8(
    sht.bxsize,
    background_color,
    x, y,
    x + 7, y + 15
  )
  sht.buf.putfont8(
    sht.bxsize,
    x, y,
    color,
    fonts[c.ord]
  )
  sht.refresh(
    x, y,
    x + 8, y + 16
  )

proc putasc8_format*(sht: ptr Sheet, x, y: int, color, background_color: Color, str: string|cstring, args: varargs[SomeInteger]) =
  var
    caret = x
    i = 0
    argidx = 0
  while i < str.len:
    if str[i] == '%':
      var size = 0
      while i + 1 < str.len and '0' <= str[i + 1] and str[i + 1] <= '9':
        size = size*10 + str[i + 1].ord - '0'.ord
        i.inc
      if (i + 1) < str.len:
        case str[i + 1]:
          of '%':
            sht.putasc8(
              caret, y,
              color, background_color,
              '%'
            )
            i += 2
            caret += 8
          of 'd', 'x', 'o':
            let
              N =
                case str[i + 1]:
                  of 'd': 10
                  of 'x': 16
                  of 'o': 8
                  else: 10
              num = args[argidx]
            argidx.inc
            var
              numstr: array[80, char]
              cnt = numstr.num2str(num, N)
            for j in countdown(max(cnt, size) - 1, 0):
              if j < cnt:
                sht.putasc8(
                  caret, y,
                  color, background_color,
                  numstr[numstr.len - j - 1]
                )
              else:
                sht.putasc8(
                  caret, y,
                  color, background_color,
                  ' '
                )
              caret += 8
            i += 2
          else: # Error case
            discard
    else:
      sht.putasc8(caret, y, color, background_color, str[i])
      i.inc
      caret += 8

proc init_screen*(sht: ptr Sheet, xsize, ysize: int) =
  sht.buf.boxfill8(xsize, Color.dark_gray , 0          , 0         , xsize - 1 , ysize - 29)
  sht.buf.boxfill8(xsize, Color.gray      , 0          , ysize - 28, xsize - 1 , ysize - 28)
  sht.buf.boxfill8(xsize, Color.white     , 0          , ysize - 27, xsize - 1 , ysize - 27)
  sht.buf.boxfill8(xsize, Color.gray      , 0          , ysize - 26, xsize - 1 , ysize - 1 )

  sht.buf.boxfill8(xsize, Color.white     , 3          , ysize - 24, 59        , ysize - 24)
  sht.buf.boxfill8(xsize, Color.white     , 2          , ysize - 24, 2         , ysize - 4 )
  sht.buf.boxfill8(xsize, Color.dark_gray , 3          , ysize - 4 , 59        , ysize - 4 )
  sht.buf.boxfill8(xsize, Color.dark_gray , 59         , ysize - 23, 59        , ysize - 5 )
  sht.buf.boxfill8(xsize, Color.black     , 2          , ysize - 3 , 59        , ysize - 3 )
  sht.buf.boxfill8(xsize, Color.black     , 60         , ysize - 24, 60        , ysize - 3 )

  sht.buf.boxfill8(xsize, Color.dark_gray , xsize - 47 , ysize - 24, xsize - 4 , ysize - 24)
  sht.buf.boxfill8(xsize, Color.dark_gray , xsize - 47 , ysize - 23, xsize - 47, ysize - 4 )
  sht.buf.boxfill8(xsize, Color.white     , xsize - 47 , ysize - 3 , xsize - 4 , ysize - 3 )
  sht.buf.boxfill8(xsize, Color.white     , xsize - 3  , ysize - 24, xsize - 3 , ysize - 3 )

