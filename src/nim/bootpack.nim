
import util
import constant
import low_layer
import palette

import display
import gdt_idt
import fifo
from keyboardutil import keyboard
import keyboardutil
from mouseutil import mouse
import mouseutil
from int import init_pic
import memory
import sheet
import window

const binfo = cast[ptr BootInfo](ADR_BOOTINFO)

proc MikanMain() {.exportc.} =
  init_gdtidt()
  init_pic()
  io_sti()

  io_out8(PIC0_IMR, 0xf9)
  io_out8(PIC1_IMR, 0xef)

  keyboard.init
  mouse.init(Color.invisible)

  var
    memorymanager = cast[ptr MemoryManager](MEMORY_ADDRESS)
    memtotal = memtest(0x00400000'u, 0xbfffffff'u)
  memorymanager.init()
  memorymanager.free(0x00001000'u, 0x0009e000'u)
  memorymanager.free(0x00400000'u, memtotal - 0x00400000'u)

  init_palette()
  var
    shtctl = createSheetControl(memorymanager, binfo.vram, binfo.scrnx, binfo.scrny)

    shtback = shtctl.alloc()
    shtmouse = shtctl.alloc()
    shtwin = shtctl.alloc()

  let
    bufwin = cast[Vram](memorymanager.alloc4k(160'u*52'u))
    bufback = cast[Vram](memorymanager.alloc4k(cast[uint](cast[int](binfo.scrnx)*cast[int](binfo.scrny))))

  shtback.setbuf(bufback, binfo.scrnx, binfo.scrny)
  shtmouse.setbuf(cast[Vram](mouse.shape.addr), 16, 16)
  shtwin.setbuf(bufwin, 160, 52)

  bufback.init_screen(binfo.scrnx, binfo.scrny)

  bufwin.createWindow8(160, 52, "Counter")

  shtback.sheetSlide(0, 0)
  shtmouse.sheetSlide(mouse.x, mouse.y)
  shtwin.sheetSlide(80, 72)

  shtback.sheetUpdown(0)
  shtwin.sheetUpdown(1)
  shtmouse.sheetUpdown(2)

  bufback.putasc8_format(binfo.scrnx, 0, 0, Color.white,
                       "memory: %dMB, free: %dKB",
                       memtotal div (1024'u*1024'u),
                       memorymanager.total div 1024'u)
  shtback.refresh(0, 0, binfo.scrnx, 48)

  var counter = 0

  while true:
    counter.inc
    bufwin.boxfill8(160, Color.gray, 40, 28, 119, 43)
    bufwin.putasc8_format(160, 40, 28, Color.black, "%d", counter)
    shtwin.refresh(40, 28, 120, 44)

    io_cli()
    if keyboard.keyfifo.status + mouse.mousefifo.status == 0:
      # io_stihlt()
      io_sti()
    else:
      if keyboard.keyfifo.status != 0:  # for keyboard
        let data = keyboard.keyfifo.get
        io_sti()
        bufback.boxfill8(binfo.scrnx, Color.black, 0, 16, 8*4 - 1, 31)
        bufback.putasc8_format(binfo.scrnx, 0, 16, Color.white, "%x", cast[int](data))
        shtback.refresh(0, 16, 8*4, 32)
      elif mouse.mousefifo.status != 0:  # for mouse
        let data = mouse.mousefifo.get
        io_sti()
        if mouse.decode(data):
          bufback.boxfill8(binfo.scrnx, Color.black, 0, 32, 8*5 - 1, 47)
          bufback.putasc8(binfo.scrnx, 0, 32, Color.white, "[lcr]")
          let b = mouse.buttons
          if MouseButton.Right in b:
            bufback.putasc8(binfo.scrnx, 24, 32, Color.black, "r")
            bufback.putasc8(binfo.scrnx, 24, 32, Color.white, "R")
          if MouseButton.Left in b:
            bufback.putasc8(binfo.scrnx, 8, 32, Color.black, "l")
            bufback.putasc8(binfo.scrnx, 8, 32, Color.white, "L")
          if MouseButton.Center in b:
            bufback.putasc8(binfo.scrnx, 16, 32, Color.black, "c")
            bufback.putasc8(binfo.scrnx, 16, 32, Color.white, "C")

          shtback.refresh(0, 32, 8*5, 48)
          if mouse.x < 0:
            mouse.x = 0
          elif cast[int](binfo.scrnx) - 1 < mouse.x:
            mouse.x = cast[int](binfo.scrnx) - 1
          if mouse.y < 0:
            mouse.y = 0
          elif cast[int](binfo.scrny) - 1 < mouse.y:
            mouse.y = cast[int](binfo.scrny) - 1
          bufback.boxfill8(binfo.scrnx, Color.black, 0, 48, 8*10 - 1, 64 - 1)
          bufback.putasc8_format(binfo.scrnx, 0, 48, Color.white, "%d, %d", mouse.x, mouse.y)
          shtback.refresh(0, 48, 8*10, 64)

          shtmouse.sheetSlide(mouse.x, mouse.y)

