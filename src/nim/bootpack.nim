
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

const binfo = cast[ptr BootInfo](ADR_BOOTINFO)


proc MikanMain() {.exportc.} =
  init_gdtidt()
  init_pic()
  io_sti()

  io_out8(PIC0_IMR, 0xf9)
  io_out8(PIC1_IMR, 0xef)

  keyboard.init
  mouse.init(Color.dark_grey)

  var
    memtotal = memtest(0x00400000'u, 0xbfffffff'u)
    memorymanager = cast[ptr MemoryManager](MEMORY_ADDRESS)
  memorymanager.init()
  memorymanager.free(0x00001000'u, 0x0009e000'u)
  memorymanager.free(0x00400000'u, memtotal - 0x00400000'u)

  init_palette()
  binfo.init_screen
  binfo.putblock8_8(16, 16, mouse.x, mouse.y, mouse.shape)
  binfo.putasc8_format(0, 0, Color.white,
                       "memory: %dMB, free: %dKB",
                       memtotal div (1024'u*1024'u),
                       memorymanager.total div 1024'u)

  while true:
    io_cli()
    if keyboard.keyfifo.status + mouse.mousefifo.status == 0:
      io_stihlt()
    else:
      if keyboard.keyfifo.status != 0:  # for keyboard
        let data = keyboard.keyfifo.get
        io_sti()
        binfo.boxfill8(Color.black, 0, 16, 8*4 - 1, 32)
        binfo.putasc8_format(0, 16, Color.white, "%x", cast[int](data))
      elif mouse.mousefifo.status != 0:  # for mouse
        let data = mouse.mousefifo.get
        io_sti()
        let
          mx = mouse.x
          my = mouse.y
        if mouse.decode(data):
          binfo.boxfill8(Color.black, 0, 32, 8*4 - 1, 48)
          case mouse.button:
            of MouseButton.Left:
              binfo.putasc8(0, 32, Color.white, "L")
            of MouseButton.Right:
              binfo.putasc8(0, 32, Color.white, "R")
            of MouseButton.Center:
              binfo.putasc8(0, 32, Color.white, "C")
            of MouseButton.Others:
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

