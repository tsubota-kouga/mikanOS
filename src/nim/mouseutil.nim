import fifo
import constant
import low_layer
from keyboardutil import wait_KBC_sendready
import display

const bufsize = 128
type
  MouseButton* {.pure size: sizeof(int8).} = enum
    Left
    Right
    Center
    Others

  MouseDecodePhase {.pure.} = enum
    GetData1 = 0
    GetData2 = 1
    GetData3Decode = 2
    Wait

  Mouse = object
    fifo*: ptr Fifo[FifoType]
    shape*: array[16, array[16, Color]]
    btnbuf*: array[3, FifoDataType]
    phase*: MouseDecodePhase
    binfo: ptr BootInfo
    btn, x, y: int

proc `px=`(this: var Mouse, x: int) =
  this.x =
    if x <= 0:
      0
    elif cast[int](this.binfo.scrnx) - 1 < x:
      cast[int](this.binfo.scrnx) - 1
    else:
      x
proc px*(this: Mouse): int {.inline.} =
  this.x
proc `py=`(this: var Mouse, y: int) {.inline.} =
  this.y =
    if y <= 0:
      0
    elif cast[int](this.binfo.scrny) - 1 < y:
      cast[int](this.binfo.scrny) - 1
    else:
      y
proc py*(this: Mouse): int {.inline.} =
  this.y
proc `button=`(this: var Mouse, b: int) {.inline.} =
  this.btn = b

proc button*(this: Mouse): set[MouseButton] {.inline.} =
  result = {}
  if (this.btn and 0x01) != 0:
    result.incl MouseButton.Left
  if (this.btn and 0x02) != 0:
    result.incl MouseButton.Right
  if (this.btn and 0x04) != 0:
    result.incl MouseButton.Center

proc `[]`*(this: Mouse, row, col: int): Color =
  return this.shape[row][col]

proc `[]=`*(this: var Mouse, row, col: int, color: Color) =
  this.shape[row][col] = color

proc enable(this: Mouse) =
  wait_KBC_sendready()
  io_out8(PORT_KEYCMD, KEYCMD_SENDTO_MOUSE)
  wait_KBC_sendready()
  io_out8(PORT_KEYDAT, MOUSECMD_ENABLE)

proc init*(this: var Mouse,
           fifoptr: ptr Fifo[FifoType],
           binfo: ptr BootInfo,
           backgroundcolor = Color.invisible) =
  this.fifo = fifoptr
  this.binfo = binfo
  const CURSOR = [
    "*...............",
    "*o*.............",
    "*oo*............",
    "*ooo*...........",
    "*oooo*..........",
    "*ooooo*.........",
    "*oooooo*........",
    "*ooooooo*.......",
    "*ooooo*.........",
    "*oo*o*..........",
    "*o**oo*.........",
    "**..*o*.........",
    ".....**.........",
    "................",
    "................",
    "................",
  ]
  for x in 0 ..< 16:
    for y in 0 ..< 16:
      if CURSOR[x][y] == '*':
        this[x, y] = Color.white
      elif CURSOR[x][y] == 'o':
        this[x, y] = Color.black
      elif CURSOR[x][y] == '.':
        this[x, y] = backgroundcolor
  this.phase = MouseDecodePhase.Wait
  this.px = 100
  this.py = 100
  this.enable()

proc decode*(this: var Mouse, data: FifoDataType): bool =
  case this.phase:
    of MouseDecodePhase.Wait:
      if data == 0xfa:
        this.phase = MouseDecodePhase.GetData1
    of MouseDecodePhase.GetData1:
      if (data and 0xc8) == 0x08:
        this.btnbuf[0] = data
        this.phase.inc
    of MouseDecodePhase.GetData2:
      this.btnbuf[1] = data
      this.phase.inc
    of MouseDecodePhase.GetData3Decode:
      this.btnbuf[2] = data

      this.button = cast[int](this.btnbuf[0]) and 0b111
      this.px =
        if (cast[int](this.btnbuf[0]) and 0b10000) != 0:
          this.px + (cast[int](this.btnbuf[1]) or 0xffffff00'i32)
        else:
          this.px + cast[int](this.btnbuf[1])
      this.py =
        if (cast[int](this.btnbuf[0]) and 0b100000) != 0:
          this.py - (cast[int](this.btnbuf[2]) or 0xffffff00'i32)
        else:
          this.py - cast[int](this.btnbuf[2])
      this.phase = MouseDecodePhase.GetData1
      return true
  return false

var mouse*: Mouse

proc inthandler2c(esp: ptr cint) {.exportc.} =
  io_out8(PIC1_OCW2, 0x64)
  io_out8(PIC0_OCW2, 0x62)
  let mousedata = (
    data: cast[FifoDataType](io_in8(PORT_KEYDAT)),
    kind: FifoKind.Mouse
  )
  mouse.fifo[].put(mousedata)

