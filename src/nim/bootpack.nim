
import util
import constant
import low_layer
import palette

import display
import gdt_idt
import fifo

from int import keyfifo, keybuf, mousefifo, mousebuf
from int import init_pic
const binfo = cast[ptr BootInfo](ADR_BOOTINFO)

var mouse: Mouse

proc wait_KBC_sendready() =
  while true:
    if (io_in8(PORT_KEYSTA) and KEYSTA_SEND_NOTREADY) == 0:
      break

proc init_keyboard() =
  wait_KBC_sendready()
  io_out8(PORT_KEYCMD, KEYCMD_WRITE_MODE)
  wait_KBC_sendready()
  io_out8(PORT_KEYDAT, KBC_MODE)

proc enable_mouse() =
  wait_KBC_sendready()
  io_out8(PORT_KEYCMD, KEYCMD_SENDTO_MOUSE)
  wait_KBC_sendready()
  io_out8(PORT_KEYDAT, MOUSECMD_ENABLE)

proc MikanMain() {.exportc.} =
  init_gdtidt()
  init_pic()
  io_sti()

  keyfifo.init(32, cast[ptr cuchar](keybuf.addr))
  mousefifo.init(128, cast[ptr cuchar](mousebuf.addr))
  io_out8(PIC0_IMR, 0xf9)
  io_out8(PIC1_IMR, 0xef)

  init_keyboard()
  init_palette()
  binfo.init_screen
  mouse.init(Color.dark_grey)
  binfo.putblock8_8(16, 16, mouse.x, mouse.y, mouse.shape)

  enable_mouse()

  while true:
    io_cli()
    if keyfifo.status + mousefifo.status == 0:
      io_stihlt()
    else:
      if keyfifo.status != 0:  # for keyboard
        let data = keyfifo.get
        io_sti()
        var cstr: cstring = "    "  # size: 4
        cstr.num2hexstr(4, data)
        binfo.boxfill8(Color.black, 0, 16, 8*4 - 1, 32)
        binfo.putfont8_asc(0, 16, Color.white, cstr)
      elif mousefifo.status != 0:  # for mouse
        let data = mousefifo.get
        io_sti()
        let
          mx = mouse.x
          my = mouse.y
        if mouse.decode(cast[cuchar](data)):
          binfo.boxfill8(Color.black, 0, 32, 8*4 - 1, 48)
          case mouse.button:
            of Button.Left:
              binfo.putfont8_asc(0, 32, Color.white, "L")
            of Button.Right:
              binfo.putfont8_asc(0, 32, Color.white, "R")
            of Button.Center:
              binfo.putfont8_asc(0, 32, Color.white, "C")
            of Button.Others:
              discard
          if mouse.x < 0:
            mouse.x = 0
          elif cast[int](binfo.scrnx) - 16 < mouse.x:
            mouse.x = cast[int](binfo.scrnx) - 16
          if mouse.y < 0:
            mouse.y = 0
          elif cast[int](binfo.scrny) - 16 < mouse.y:
            mouse.y = cast[int](binfo.scrny) - 16
          binfo.boxfill8(Color.dark_grey, mx, my, mx + 15, my + 15)
          binfo.putblock8_8(16, 16, mouse.x, mouse.y, mouse.shape)

          # for i in 0 .. 2:
          #   var cstr: cstring = "    "  # size: 4
          #   cstr.num2hexstr(4, cast[int](mouse_dbuf[i]))
          #   binfo.boxfill8(Color.black, 0, 32*(i + 1), 8*4 - 1, 48*(i + 1))
          #   binfo.putfont8_asc(0, 32*(i + 1), Color.white, cstr)


