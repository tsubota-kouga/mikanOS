
include "../util/hankaku.nim"

include util
include low_layer
include palette
include display
include gdt_idt

proc MikanMain() {.exportc.} =

  const binfo = cast[ptr BootInfo](0x0ff0)

  init_gdtidt()
  init_palette()
  init_mouse_cursor8(Color.dark_grey)
  binfo[].init_screen()
  binfo[].putfont8_asc(9, 9, Color.white, "ABC 123")
  binfo[].putfont8_asc(8, 8, Color.black, "ABC 123")

  binfo[].putblock8_8(16, 16, 100, 100, mouse, 16'u)

  while true:
    io_hlt()

