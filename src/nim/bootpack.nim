
include "../../util/hankaku.nim"

include util
include low_layer

include palette
include display
include gdt_idt

const binfo = cast[ptr BootInfo](ADR_BOOTINFO)
include "int"  # require binfo

proc MikanMain() {.exportc.} =

  init_gdtidt()
  init_pic()
  io_sti()

  init_palette()
  binfo[].init_screen()
  init_mouse_cursor8(Color.dark_grey)
  binfo[].putblock8_8(16, 16, 100, 100, mouse, 16)

  io_out8(PIC0_IMR, 0xf9)
  io_out8(PIC1_IMR, 0xef)

  while true:
    io_hlt()

