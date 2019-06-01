
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
    set_segmdesc(gdt + i, 0, 0, 0)
  set_segmdesc(gdt + 1'u, 0xffffffff'u, 0x00000000, 0x4092)
  set_segmdesc(gdt + 2'u, 0x0007ffff'u, 0x00280000, 0x409a)
  load_gdtr(0xffff, 0x00270000)

  for i in 0'u ..< 256:
    set_gatedisc(idt + i, 0, 0, 0)
  load_idtr(0x7ff, 0x0026f800)

