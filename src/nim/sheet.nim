import memory
import constant
import display
import util

const MaxSheets = 256
type
  UseFlag {.size: sizeof(bool).} = enum
    Unused
    Used

  VramMap = ArithmeticPtr[int8]
  Sheet = object
    buf: Vram
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

proc createSheetControl*(m: ptr MemoryManager, vram: Vram, xsize, ysize: int): ptr SheetControl =
  let ctl = cast[ptr SheetControl](m.alloc4k(cast[uint](sizeof(SheetControl))))
  if ctl == nil:
    return nil
  ctl.map = cast[VramMap](m.alloc4k(cast[uint](xsize*ysize*sizeof(int8))))
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
  # for i in 0 .. MaxSheets:
  #   ctl.sheets0[i].flags = Unused
  #   ctl.sheets0[i].ctl = ctl
  return ctl

proc alloc*(ctl: ptr SheetControl): ptr Sheet =
  var sht: ptr Sheet
  for i in 0 .. MaxSheets:
    if ctl.sheets0[i].flags == Unused:
      sht = cast[ptr Sheet](ctl.sheets0[i].addr)
      sht.flags = Used
      sht.height = -1
      return sht
  return nil

proc setbuf*(sht: ptr Sheet, buf: Vram, xsize, ysize: int) =
  sht.buf = buf
  sht.bxsize = xsize
  sht.bysize = ysize

# proc `[]`(p: ptr int8, idx: int): int8 =
#   cast[ptr int8](cast[int](p) + idx*sizeof(int8))[]
# proc `[]=`(p: ptr int8, idx: int, i: int8) =
#   cast[ptr int8](cast[int](p) + idx*sizeof(int8))[] = i

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
      sid = cast[int8](cast[int](sht) - cast[int](ctl.sheets0))
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
      sid = cast[int8](cast[int](sht) - cast[int](ctl.sheets0))
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
    sht.ctl.refreshSub(sht.vx0 + bx0, sht.vy0 + by0, sht.vx0 + bx1, sht.vy0 + by1, sht.height, sht.height)

proc sheetUpdown*(sht: ptr Sheet, height: int) =
  var
    old = sht.height
    height = height

  if height > sht.ctl.top + 1:
    height = sht.ctl.top + 1
  if height < -1:
    height = -1
  sht.height = height
  if old > height:
    if height >= 0:
      for h in countdown(old, height + 1):
        sht.ctl.sheets[h] = sht.ctl.sheets[h - 1]
        sht.ctl.sheets[h].height = h
      sht.ctl.sheets[height] = sht
      sht.ctl.refreshMap(sht.vx0, sht.vy0, sht.vx0 + sht.bxsize, sht.vy0 + sht.bysize, height + 1)
      sht.ctl.refreshSub(sht.vx0, sht.vy0, sht.vx0 + sht.bxsize, sht.vy0 + sht.bysize, height + 1, old)
    else:
      if sht.ctl.top > old:
        for h in old ..< sht.ctl.top:
          sht.ctl.sheets[h] = sht.ctl.sheets[h + 1]
          sht.ctl.sheets[h].height = h
      sht.ctl.top.dec
      sht.ctl.refreshMap(sht.vx0, sht.vy0, sht.vx0 + sht.bxsize, sht.vy0 + sht.bysize, 0)
      sht.ctl.refreshSub(sht.vx0, sht.vy0, sht.vx0 + sht.bxsize, sht.vy0 + sht.bysize, 0, old - 1)
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
    sht.ctl.refreshMap(sht.vx0, sht.vy0, sht.vx0 + sht.bxsize, sht.vy0 + sht.bysize, height)
    sht.ctl.refreshSub(sht.vx0, sht.vy0, sht.vx0 + sht.bxsize, sht.vy0 + sht.bysize, height, height)

proc sheetSlide*(sht: ptr Sheet, vx0, vy0: int) =
  var
    oldvx0 = sht.vx0
    oldvy0 = sht.vy0
  sht.vx0 = vx0
  sht.vy0 = vy0
  if sht.height >= 0:
    sht.ctl.refreshMap(oldvx0, oldvy0, oldvx0 + sht.bxsize, oldvy0 + sht.bysize, 0)
    sht.ctl.refreshMap(vx0, vy0, vx0 + sht.bxsize, vy0 + sht.bysize, sht.height)
    sht.ctl.refreshSub(oldvx0, oldvy0, oldvx0 + sht.bxsize, oldvy0 + sht.bysize, 0, sht.height - 1)
    sht.ctl.refreshSub(vx0, vy0, vx0 + sht.bxsize, vy0 + sht.bysize, sht.height, sht.height)

proc sheetFree(sht: ptr Sheet) =
  if sht.height >= 0:
    sht.sheetUpdown(-1)
  sht.flags = Unused

