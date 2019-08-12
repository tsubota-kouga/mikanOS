
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
import widget
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

  var
    buf: array[FifoSize, FifoType]
    fifo = createFifo(buf)

  keyboard.init(fifo.addr)
  mouse.init(fifo.addr)
  tctrl.init(fifo.addr)
  discard tctrl.set(1.s, (data: 1'u8, kind: FifoKind.Timer))
  discard tctrl.set(3.s, (data: 3'u8, kind: FifoKind.Timer))
  discard tctrl.set(5.s, (data: 5'u8, kind: FifoKind.Timer))

  var
    memorymanager = cast[MemoryManager](MEMORY_ADDRESS)
    memtotal = memtest(0x00400000'u, 0xbfffffff'u)
  memorymanager.init
  memorymanager.free(0x00001000'u, 0x0009e000'u)
  memorymanager.free(0x00400000'u, memtotal - 0x00400000'u)

  init_palette()
  var
    shtctl = memorymanager.createSheetControl(binfo.vram, binfo.scrnx, binfo.scrny)

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

  shtwin.createWindow8("Window")
  shtwin.createLineEdit8(8, 28, 144, 16, Color.white)

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

  var editCursor = 50
  while true:
    io_cli()
    if keyboard.fifo[].status == Empty and
       mouse.fifo[].status == Empty and
       tctrl.fifo[].status == Empty:
      io_stihlt()
    else:
      if fifo.status == Got:
        let (data, kind) = fifo.get
        io_sti()
        case kind:
          of FifoKind.Mouse:
            if mouse.decode(data, binfo):
              shtback.putasc8_format(0, 32, Color.white, Color.black, "[lcr]", 0)
              let b = mouse.buttons
              if MouseButton.Right in b:
                shtback.putasc8_format(24, 32, Color.white, Color.black, "R", 0)
                shtwin.sheetSlide(mouse.x - 80, mouse.y - 8)
              if MouseButton.Left in b:
                shtback.putasc8_format(8, 32, Color.white, Color.black, "L", 0)
              if MouseButton.Center in b:
                shtback.putasc8_format(16, 32, Color.white, Color.black, "C", 0)
              shtback.putasc8_format(0, 48, Color.white, Color.black, "%4d, %4d", mouse.x, mouse.y)
            shtmouse.sheetSlide(mouse.x, mouse.y)
          of FifoKind.Keyboard:
            if data == KeyCode.Backspace.ord:
              editCursor -= 8
              shtwin.putasc8(editCursor, 28, Color.black, Color.white, KeyTable[KeyCode.Space.ord])
            elif data < 0x80:
              shtwin.putasc8(editCursor, 28, Color.black, Color.white, KeyTable[data])
              editCursor += 8
            # shtwin.putasc8_format(40, 28, Color.black, Color.gray, $KeyCode(data), 0)
            shtback.putasc8_format(0, 16, Color.white, Color.black, "%4x", data)
          of FifoKind.Timer:
            # if data == 1:
            #   discard tctrl.set(1.s, (data: 1'u8, kind: FifoKind.Timer))
            #   shtwin.putasc8(editCursor, 28, Color.black, Color.black, ' ')

            shtback.putasc8_format(0, 64, Color.white, Color.black, "%d[sec]", data)

