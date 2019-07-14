import fifo
import constant
import low_layer
from keyboardutil import wait_KBC_sendready

const bufsize = 128
type
  MouseButton* {.pure size: sizeof(int8).} = enum
    Left
    Right
    Center
    Others

  Mouse = object
    mousefifo*: FIFO
    mousebuf*: array[bufsize, cuchar]
    shape*: array[16, array[16, Color]]
    buf*: array[3, cuchar]
    phase*: int
    btn, x*, y*: int

var mouse*: Mouse

func `[]`*(this: Mouse, row, col: int): Color =
  return this.shape[row][col]

proc `[]=`*(this: var Mouse, row, col: int, color: Color) =
  this.shape[row][col] = color

proc enable_mouse() =
  wait_KBC_sendready()
  io_out8(PORT_KEYCMD, KEYCMD_SENDTO_MOUSE)
  wait_KBC_sendready()
  io_out8(PORT_KEYDAT, MOUSECMD_ENABLE)

proc init*(this: var Mouse, backgroundcolor: Color) =
  this.mousefifo.init(bufsize, cast[ptr cuchar](this.mousebuf.addr))
  const CURSOR: array[16, string] = [
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
  this.phase = 0
  this.x = 100
  this.y = 100
  enable_mouse()

proc decode*(this: var Mouse, data: cuchar): bool =
  case this.phase:
    of 0:
      this.phase = 1
    of 1, 2:
      this.buf[this.phase - 1] = data
      this.phase += 1
    of 3:
      this.buf[2] = data
      this.btn = cast[int](this.buf[0]) and 0x07
      this.x =
        if (cast[int](this.buf[0]) and 0x10) != 0:
          (cast[int](this.buf[1]) or 0xffffff00'i32) + this.x
        else:
          cast[int](this.buf[1]) + this.x
      this.y =
        if (cast[int](this.buf[0]) and 0x20) != 0:
          -(cast[int](this.buf[2]) or 0xffffff00'i32) + this.y
        else:
          -cast[int](this.buf[2]) + this.y
      this.phase = 1
      return true
    else:
      discard
  return false

func button*(this: Mouse): MouseButton {.deprecated.} =
  if (this.btn and 0x01) != 0:
    return MouseButton.Left
  elif (this.btn and 0x02) != 0:
    return MouseButton.Right
  elif (this.btn and 0x04) != 0:
    return MouseButton.Center
  else:
    return MouseButton.Others

func buttons*(this: Mouse): set[MouseButton] =
  result = {}
  if (this.btn and 0x01) != 0:
    result.incl MouseButton.Left
  if (this.btn and 0x02) != 0:
    result.incl MouseButton.Right
  if (this.btn and 0x04) != 0:
    result.incl MouseButton.Center

proc inthandler2c(esp: ptr cint) {.exportc.} =
  io_out8(PIC1_OCW2, 0x64)
  io_out8(PIC0_OCW2, 0x62)
  let data = cast[cuchar](io_in8(PORT_KEYDAT))
  mouse.mousefifo.put(data)

