import memory
import constant
import display

const MaxSheets = 256
type
  UseFlag = enum
    Unused = false
    Used

  Sheet = object
    buf: Vram
    bxsize, bysize: int
    vx0, vy0: int
    col_inv, height: int
    flags: UseFlag

  SheetControl = object
    vram: Vram
    xsize, ysize, top: int
    sheets: array[MaxSheets, ptr Sheet]
    sheets0: array[MaxSheets, Sheet]

proc createSheetControl*(m: ptr MemoryManager, vram: Vram, xsize, ysize: int): ptr SheetControl =
  let ctl = cast[ptr SheetControl](m.alloc4k(cast[uint](sizeof(SheetControl))))
  if cast[int](ctl) == 0:
    return ctl
  ctl.vram = vram
  ctl.xsize = xsize
  ctl.ysize = ysize
  ctl.top = -1
  for i in 0 .. MaxSheets:
    ctl.sheets0[i].flags = Unused
  return ctl

proc alloc*(ctl: ptr SheetControl): ptr Sheet =
  var sht: ptr Sheet
  for i in 0 .. MaxSheets:
    if ctl.sheets0[i].flags == Unused:
      sht = cast[ptr Sheet](cast[int](ctl.sheets0.addr) + i*sizeof(Sheet))
      sht.flags = Used
      sht.height = -1
      return sht
  return cast[ptr Sheet](0)

proc setbuf*(sht: ptr Sheet, buf: Vram, xsize, ysize: int) =
  sht.buf = buf
  sht.bxsize = xsize
  sht.bysize = ysize

proc refreshSub(ctl: ptr SheetControl, vx0, vy0, vx1, vy1: int) =
  var vram = ctl.vram
  for h in 0 .. ctl.top:
    let
      sht = ctl.sheets[h]
    var
      bx0 = vx0 - sht.vx0
      by0 = vy0 - sht.vy0
      bx1 = vx1 - sht.vx0
      by1 = vy1 - sht.vy0
    if bx0 < 0: bx0 = 0
    if by0 < 0: by0 = 0
    if bx1 > sht.bxsize: bx1 = sht.bxsize
    if by1 > sht.bysize: by1 = sht.bysize
    var buf = sht.buf
    for by in by0 ..< by1:
      let vy = sht.vy0 + by
      for bx in bx0 ..< bx1:
        let
          vx = sht.vx0 + bx
          c = buf[by * sht.bxsize + bx]
        if cast[Color](c) != Color.invisible:
          vram[vy * ctl.xsize + vx] = cast[Color](c)


proc refresh*(ctl: ptr SheetControl, sht: ptr Sheet, bx0, by0, bx1, by1: int) =
  if sht.height >= 0:
    ctl.refreshSub(sht.vx0 + bx0, sht.vy0 + by0, sht.vx0 + bx1, sht.vy0 + by1)

proc sheetUpdown*(ctl: ptr SheetControl, sht: ptr Sheet, height: int) =
  var
    old = sht.height
    height = height

  if height > ctl.top + 1:
    height = ctl.top + 1
  if height < -1:
    height = -1
  sht.height = height
  if old > height:
    if height >= 0:
      for h in countdown(old, height + 1):
        ctl.sheets[h] = ctl.sheets[h - 1]
        ctl.sheets[h].height = h
      ctl.sheets[height] = sht
    else:
      if ctl.top > old:
        for h in old ..< ctl.top:
          ctl.sheets[h] = ctl.sheets[h + 1]
          ctl.sheets[h].height = h
      ctl.top.dec
    ctl.refreshSub(sht.vx0, sht.vy0, sht.vx0 + sht.bxsize, sht.vy0 + sht.bysize)
  elif old < height:
    if old >= 0:
      for h in old ..< height:
        ctl.sheets[h] = ctl.sheets[h + 1]
        ctl.sheets[h].height = h
      ctl.sheets[height] = sht
    else:
      for h in countdown(ctl.top, height):
        ctl.sheets[h + 1] = ctl.sheets[h]
        ctl.sheets[h + 1].height = h + 1
      ctl.sheets[height] = sht
      ctl.top.inc
    ctl.refreshSub(sht.vx0, sht.vy0, sht.vx0 + sht.bxsize, sht.vy0 + sht.bysize)

proc sheetSlide*(ctl: ptr SheetControl, sht: ptr Sheet, vx0, vy0: int) =
  var
    oldvx0 = sht.vx0
    oldvy0 = sht.vy0
  sht.vx0 = vx0
  sht.vy0 = vy0
  if sht.height >= 0:
    ctl.refreshSub(oldvx0, oldvy0, oldvx0 + sht.bxsize, oldvy0 + sht.bysize)
    ctl.refreshSub(vx0, vy0, vx0 + sht.bxsize, vy0 + sht.bysize)

proc sheetFree(ctl: ptr SheetControl, sht: ptr Sheet) =
  if sht.height >= 0:
    sheetUpdown(ctl, sht, -1)
  sht.flags = Unused

