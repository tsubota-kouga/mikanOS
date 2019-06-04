
const
  ADR_IDT = 0x0026f800
  LIMIT_IDT = 0x000007ff
  ADR_GDT = 0x00270000
  LIMIT_GDT = 0x0000ffff
  ADR_BOTPAK = 0x00280000
  LIMIT_BOTPAK = 0x0007ffff
  AR_DATA32_RW = 0x4092
  AR_CODE32_ER = 0x409a
  AR_INTGATE32 = 0x008e

type
  SegmentDescripter = object
    limit_low, base_low: int16
    base_mid, access_right: cuchar
    limit_high, base_high: cuchar

  GateDescripter = object
    offset_low, selector: int16
    dw_count, access_right: cuchar
    offset_high: int16

var
  gdt: ptr SegmentDescripter
  idt: ptr GateDescripter

proc asm_inthandler21() =
  asm """
    pushw %es
    pushw %ds
    pusha
    movl %esp, %eax
    pushl %eax
    movw %ss, %ax
    movw %ax, %ds
    movw %ax, %es
    call inthandler21
    popl %eax
    popa
    popw %ds
    popw %es
    iret
  """
proc asm_inthandler27() =
  asm """
    pushw %es
    pushw %ds
    pusha
    movl %esp, %eax
    pushl %eax
    movw %ss, %ax
    movw %ax, %ds
    movw %ax, %es
    call inthandler27
    popl %eax
    popa
    popw %ds
    popw %es
    iret
  """

proc asm_inthandler2c() =
  asm """
    pushw %es
    pushw %ds
    pusha
    movl %esp, %eax
    pushl %eax
    movw %ss, %ax
    movw %ax, %ds
    movw %ax, %es
    call inthandler2c
    popl %eax
    popa
    popw %ds
    popw %es
    iret
  """


proc set_segmdesc(sd: ptr SegmentDescripter, limit: int, base, ar: int) =
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

proc set_gatedesc(gd: ptr GateDescripter, offset, selector, ar: int) =
  gd.offset_low = cast[int16](offset and 0xffff)
  gd.selector = cast[int16](selector)
  gd.dw_count = cast[cuchar]((ar shr 8) and 0xff)
  gd.access_right = cast[cuchar](ar and 0xff)
  gd.offset_high = cast[int16]((offset shr 16) and 0xffff)

proc init_gdtidt() =
  gdt = cast[ptr SegmentDescripter](ADR_GDT)
  idt = cast[ptr GateDescripter](ADR_IDT)
  for i in 0 .. LIMIT_GDT div 8:
    set_segmdesc(gdt + i, 0, 0, 0)
  set_segmdesc(gdt + 1, 0xffffffff'i32, 0x00000000, AR_DATA32_RW)
  set_segmdesc(gdt + 2, LIMIT_BOTPAK, ADR_BOTPAK, AR_CODE32_ER)
  load_gdtr(LIMIT_GDT, ADR_GDT)

  for i in 0 .. LIMIT_IDT div 8:
    set_gatedesc(idt + i, 0, 0, 0)
  load_idtr(LIMIT_IDT, ADR_IDT)

  set_gatedesc(idt + 0x21, cast[int](asm_inthandler21), 2 shl 3, AR_INTGATE32)
  set_gatedesc(idt + 0x27, cast[int](asm_inthandler27), 2 shl 3, AR_INTGATE32)
  set_gatedesc(idt + 0x2c, cast[int](asm_inthandler2c), 2 shl 3, AR_INTGATE32)

