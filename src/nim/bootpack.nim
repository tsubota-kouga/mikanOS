
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

const binfo = cast[ptr BootInfo](ADR_BOOTINFO)

const
  EFLAGS_AC_BIT = 0x00040000
  CR0_CACHE_DISABLE = 0x60000000

func memtest_sub(head, tail: uint): uint =
  const
    pat0 = 0xaa55aa55'u
    pat1 = 0x55aa55aa'u
  var
    old: uint
    i = head
    p {.volatile.}: ptr uint
  while i <= tail:
    p = cast[ptr uint](i + 0xffc)
    old = p[]
    p[] = pat0
    p[] = p[] xor 0xffffffff'u
    if p[] != pat1:
      p[] = old
      break
    p[] = p[] xor 0xffffffff'u
    if p[] != pat0:
      p[] = old
      break
    p[] = old
    i += 0x1000
  return i

proc memtest(head, tail: uint): uint =
  var
    flg486: int16 = 0
    eflg = cast[cint](io_load_eflags() or EFLAGS_AC_BIT)
    cr0: cint
    i: uint
  io_store_eflags(eflg)
  eflg = io_load_eflags()
  if((eflg and EFLAGS_AC_BIT) != 0):
    flg486 = 1
  eflg = eflg and not EFLAGS_AC_BIT
  io_store_eflags(eflg)
  if flg486 != 0:
    cr0 = load_cr0()
    cr0 = cr0 or CR0_CACHE_DISABLE
    store_cr0(cr0)
  i = memtest_sub(head, tail)
  if flg486 != 0:
    cr0 = load_cr0()
    cr0 = cr0 and not CR0_CACHE_DISABLE
    store_cr0(cr0)
  return i

const
  MEMORY_FREES = 4090
  MEMORY_ADDRESS = 0x003c0000

type
  FreeInfo = object
    address, size: uint
  MemoryManager = object
    frees, maxfrees, lostsize, losts: uint
    freerealm: array[MEMORY_FREES, FreeInfo]

func init(this: ptr MemoryManager) =
  this.frees = 0
  this.maxfrees = 0
  this.lostsize = 0
  this.losts = 0

func total(this: ptr MemoryManager): uint =
  var t = 0'u
  for i in 0'u ..< this.frees:
    t += this.freerealm[i].size
  return t

proc alloc(this: ptr MemoryManager, size: uint): uint =
  for i in 0'u ..< this.frees:
    if this.freerealm[i].size >= size:
      let a = this.freerealm[i].address
      this.freerealm[i].address += size
      this.freerealm[i].size -= size
      if this.freerealm[i].size == 0:
        this.frees.dec
        for j in i ..< this.frees:
          this.freerealm[i] = this.freerealm[i + 1]
      return a
  return 0

proc free(this: ptr MemoryManager, address, size: uint): int {.discardable.} =
  var i = 0'u
  while i < this.frees:
    if this.freerealm[i].address > address:
      break
    i.inc
  if i > 0'u:
    if this.freerealm[i - 1].address + this.freerealm[i - 1].size == address:
      this.freerealm[i - 1].size += size
      if i < this.frees:
        if address + size == this.freerealm[i].address:
          this.freerealm[i - 1].size += this.freerealm[i].size
          this.frees.dec
          for j in i ..< this.frees:
            this.freerealm[i] = this.freerealm[i + 1]
      return 0
  if i < this.frees:
    if address + size == this.freerealm[i].address:
      this.freerealm[i].address = address
      this.freerealm[i].size += size
      return 0
  if this.frees < MEMORY_FREES:
    for j in countdown(this.frees, i + 1):
      this.freerealm[j] = this.freerealm[j - 1]
    this.frees.inc
    if this.maxfrees < this.frees:
      this.maxfrees = this.frees
    this.freerealm[i].address = address
    this.freerealm[i].size = size
    return 0
  this.losts.inc
  this.lostsize += size
  return -1


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


  var cstr: cstring = "    "
  cstr.num2hexstr(4, memtotal div (1024'u*1024'u))
  binfo.putfont8_asc(0, 0, Color.white, cstr)

  var cstr2: cstring = "    "
  cstr2.num2hexstr(4, memorymanager.total div 1024'u)
  binfo.putfont8_asc(16*4, 0, Color.white, cstr2)

  while true:
    io_cli()
    if keyboard.keyfifo.status + mouse.mousefifo.status == 0:
      io_stihlt()
    else:
      if keyboard.keyfifo.status != 0:  # for keyboard
        let data = keyboard.keyfifo.get
        io_sti()
        var cstr: cstring = "    "  # size: 4
        cstr.num2hexstr(4, cast[int](data))
        binfo.boxfill8(Color.black, 0, 16, 8*4 - 1, 32)
        binfo.putfont8_asc(0, 16, Color.white, cstr)
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
              binfo.putfont8_asc(0, 32, Color.white, "L")
            of MouseButton.Right:
              binfo.putfont8_asc(0, 32, Color.white, "R")
            of MouseButton.Center:
              binfo.putfont8_asc(0, 32, Color.white, "C")
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

          # for i in 0 .. 2:
          #   var cstr: cstring = "    "  # size: 4
          #   cstr.num2hexstr(4, cast[int](mouse_dbuf[i]))
          #   binfo.boxfill8(Color.black, 0, 32*(i + 1), 8*4 - 1, 48*(i + 1))
          #   binfo.putfont8_asc(0, 32*(i + 1), Color.white, cstr)


