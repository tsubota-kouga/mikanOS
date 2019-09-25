
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
from timer import tctrl, mtask
import timer

const binfo = cast[ptr BootInfo](ADR_BOOTINFO)

type
  TaskStatusSegment = object
    backlink, esp0, ss0, esp1, ss1, esp2, ss2, cr3: int32
    eip, eflags, eax, ecx, edx, ebx, esp, ebp, esi, edi: int32
    es, cs, ss, ds, fs, gs: int32
    ldtr, iomap: int32

var count = 0
proc task_b_main(shtback: ptr Sheet) =
  while true:
    count.inc
    shtback.putasc8_format(0, 100, Color.white, Color.black, "%d", count)
    # io_cli()
    if tctrl.fifo[].status == Empty:
      discard
      # io_stihlt()
    else:
      discard
      # io_sti()

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
  mouse.init(fifo.addr, binfo)
  tctrl.init(fifo.addr)
  discard tctrl.set(1.s, (data: 1'u8, kind: FifoKind.Timer))
  discard tctrl.set(3.s, (data: 3'u8, kind: FifoKind.Timer))

  var
    memorymanager = cast[MemoryManager](MEMORY_ADDRESS)
    memtotal = memtest(0x0040_0000'u, 0xbfff_ffff'u)
  memorymanager.init
  memorymanager.free(0x0000_1000'u, 0x0009_e000'u)
  memorymanager.free(0x0040_0000'u, memtotal - 0x0040_0000'u)

  const
    gdt = cast[ptr SegmentDescripter](ADR_GDT)
  var
    tss_a = TaskStatusSegment(iomap: 0x4000_0000)
    tss_b = TaskStatusSegment(
              iomap: 0x4000_0000,
              eip: cast[int32](task_b_main),
              eflags: 0x0000_0202,
              esp: cast[int32](memorymanager.alloc4k(64*1024) + 64*1024),
              es: 1*8, cs: 2*8, ss: 1*8, ds: 1*8, fs: 1*8, gs: 1*8,
              )
    task_b_esp = memorymanager.alloc4k(64*1024 - 8)
  (gdt + 3).set(103, cast[cint](tss_a.addr), 0x0089)
  (gdt + 4).set(103, cast[cint](tss_b.addr), 0x0089)
  load_tr(3 * 8)

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
  shtmouse.sheetSlide(mouse.px, mouse.py)
  shtwin.sheetSlide(80, 72)

  shtback.sheetUpdown(0)
  shtwin.sheetUpdown(1)
  shtmouse.sheetUpdown(2)

  shtback.putasc8_format(0, 0, Color.white, Color.black,
                         "memory: %dMB, free: %dKB",
                         memtotal div (1024'u*1024'u),
                         memorymanager.total div 1024'u)
  mtask.init()
  cast[ptr pointer](task_b_esp + 4)[] = shtback

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
        shtback.putasc8_format(0, 64, Color.white, Color.black, "%d", fifo.freesize)
        case kind:
          of FifoKind.Mouse:
            if mouse.decode(data):
              shtback.putasc8_format(0, 32, Color.white, Color.black, "[lcr]", 0)
              let b = mouse.button
              if MouseButton.Right in b:
                shtback.putasc8_format(24, 32, Color.white, Color.black, "R", 0)
                shtwin.sheetSlide(mouse.px - 80, mouse.py - 8)
              if MouseButton.Left in b:
                shtback.putasc8_format(8, 32, Color.white, Color.black, "L", 0)
              if MouseButton.Center in b:
                shtback.putasc8_format(16, 32, Color.white, Color.black, "C", 0)
              shtback.putasc8_format(0, 48, Color.white, Color.black, "%4d, %4d", mouse.px, mouse.py)
              shtmouse.sheetSlide(mouse.px, mouse.py)
          of FifoKind.Keyboard:
            if data == KeyCode.Backspace.ord:
              editCursor -= 8
              shtwin.putasc8(editCursor, 28, Color.black, Color.white, KeyTable[KeyCode.Space.ord])
            elif data < 0x80:
              shtwin.putasc8(editCursor, 28, Color.black, Color.white, KeyTable[data])
              editCursor += 8
            shtback.putasc8_format(0, 16, Color.white, Color.black, "%4x", data)
          of FifoKind.Timer:
            discard
          else:
            discard
          # of FifoKind.MultiTaskTimer:
          #   cast[ptr pointer](task_b_esp + 4)[] = shtback
          #   discard tctrl.set(20.ms, (data: 20'u8, kind: FifoKind.MultiTaskTimer))
          #   farjmp(0, 4 * 8)

