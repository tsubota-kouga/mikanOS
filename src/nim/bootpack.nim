
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
import int
import memory
import sheet
import window
from timer import tctrl
import timer

const binfo = cast[ptr BootInfo](ADR_BOOTINFO)

proc MikanMain() {.exportc.} =
  init_gdtidt()
  init_pic()
  init_pit()
  io_sti()

  io_out8(PIC0_IMR, 0xf8)
  io_out8(PIC1_IMR, 0xef)

  keyboard.init
  mouse.init(Color.invisible)
  tctrl.init
  let tp = tctrl.set(3.sec, 4'i8)
  let tp2 = tctrl.set(5.sec, 4'i8)

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

  shtback.init_screen(binfo.scrnx, binfo.scrny)

  shtwin.createWindow8(160, 52, "Timer")

  shtback.sheetSlide(0, 0)
  shtmouse.sheetSlide(mouse.x, mouse.y)
  shtwin.sheetSlide(80, 72)

  shtback.sheetUpdown(0)
  shtwin.sheetUpdown(1)
  shtmouse.sheetUpdown(2)

  shtback.putasc8_format(0, 0, Color.white, Color.black,
                         "memory: %dMB, free: %dKB",
                         memtotal div (1024'u*1024'u),
                         memorymanager.total div 1024'u)

  while true:
    shtwin.putasc8_format(40, 28, Color.black, Color.gray, "%d", tctrl.get)

    io_cli()
    if keyboard.fifo.status == Empty and
       mouse.fifo.status == Empty and
       tp.fifo.status == Empty and tp2.fifo.status == Empty:
      io_stihlt()
    else:
      if keyboard.fifo.status == Got:  # for keyboard
        let data = keyboard.fifo.get
        io_sti()
        shtback.putasc8_format(0, 16, Color.white, Color.black, "%4x", data)
      elif mouse.fifo.status == Got:  # for mouse
        let data = mouse.fifo.get
        io_sti()
        if mouse.decode(data):
          shtback.putasc8_format(0, 32, Color.white, Color.black, "[lcr]", 0)
          let b = mouse.buttons
          if MouseButton.Right in b:
            shtback.putasc8_format(24, 32, Color.white, Color.black, "R", 0)
          if MouseButton.Left in b:
            shtback.putasc8_format(8, 32, Color.white, Color.black, "L", 0)
          if MouseButton.Center in b:
            shtback.putasc8_format(16, 32, Color.white, Color.black, "C", 0)

          shtback.refresh(0, 32, 8*5, 48)
          if mouse.x < 0:
            mouse.x = 0
          elif cast[int](binfo.scrnx) - 1 < mouse.x:
            mouse.x = cast[int](binfo.scrnx) - 1
          if mouse.y < 0:
            mouse.y = 0
          elif cast[int](binfo.scrny) - 1 < mouse.y:
            mouse.y = cast[int](binfo.scrny) - 1
          shtback.putasc8_format(0, 48, Color.white, Color.black, "%3d, %3d", mouse.x, mouse.y)
          shtmouse.sheetSlide(mouse.x, mouse.y)
      elif tp.fifo.status == Got:
        let data = tp.fifo.get
        io_sti()
        shtback.putasc8_format(0, 64, Color.black, Color.invisible, "%d[sec]", 3)
        shtback.refresh(0, 64, 56, 80)
      elif tp2.fifo.status == Got:
        let data = tp2.fifo.get
        io_sti()
        shtback.putasc8_format(0, 80, Color.black, Color.invisible, "%d[sec]", 5)
        shtback.refresh(0, 80, 56, 96)

