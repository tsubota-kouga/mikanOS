import constant
import low_layer
import util

type
  SegmentDescripter = object
    limit_low, base_low: int16
    base_mid, access_right: cuchar
    limit_high, base_high: cuchar

  GateDescripter = object
    offset_low, selector: int16
    dw_count, access_right: cuchar
    offset_high: int16

proc asm_inthandler21() {.importc.}
proc asm_inthandler27() {.importc.}
proc asm_inthandler2c() {.importc.}

proc set(sd: ptr SegmentDescripter, limit, base, ar: cint)
proc set(gd: ptr GateDescripter, offset, selector, ar: cint)

proc init_gdtidt*() =
  const
    gdt = cast[ptr SegmentDescripter](ADR_GDT)
    idt = cast[ptr GateDescripter](ADR_IDT)
  for i in 0 .. LIMIT_GDT div 8:
    (gdt + i).set(0, 0, 0)
  (gdt + 1).set(0xffffffff'i32, 0x00000000, AR_DATA32_RW)
  (gdt + 2).set(LIMIT_BOTPAK, ADR_BOTPAK, AR_CODE32_ER)
  load_gdtr(LIMIT_GDT, ADR_GDT)

  for i in 0 .. LIMIT_IDT div 8:
    (idt + i).set(0, 0, 0)
  load_idtr(LIMIT_IDT, ADR_IDT)

  (idt + 0x21).set(cast[cint](asm_inthandler21), 2 shl 3, AR_INTGATE32)
  (idt + 0x27).set(cast[cint](asm_inthandler27), 2 shl 3, AR_INTGATE32)
  (idt + 0x2c).set(cast[cint](asm_inthandler2c), 2 shl 3, AR_INTGATE32)

proc set(sd: ptr SegmentDescripter, limit, base, ar: cint) =
  var
    limit = limit
    ar = ar
  if limit > 0xfffff:
    ar = ar or 0x8000
    limit = limit div 0x1000
  sd.limit_low = cast[int16](limit and 0xffff)
  sd.base_low = cast[int16](base and 0xffff)
  sd.base_mid = cast[cuchar]((base shr 16) and 0xff)
  sd.access_right = cast[cuchar](ar and 0xff)
  sd.limit_high = cast[cuchar](((limit shr 16) and 0x0f) or ((ar shr 8) and 0xf0))
  sd.base_high = cast[cuchar]((base shr 24) and 0xff)

proc set(gd: ptr GateDescripter, offset, selector, ar: cint) =
  gd.offset_low = cast[int16](offset and 0xffff)
  gd.selector = cast[int16](selector)
  gd.dw_count = cast[cuchar]((ar shr 8) and 0xff)
  gd.access_right = cast[cuchar](ar and 0xff)
  gd.offset_high = cast[int16]((offset shr 16) and 0xffff)

