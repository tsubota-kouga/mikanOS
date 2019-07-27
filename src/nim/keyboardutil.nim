import fifo
import low_layer
import constant
import util

proc wait_KBC_sendready*() =
  while true:
    if (io_in8(PORT_KEYSTA) and KEYSTA_SEND_NOTREADY) == 0:
      break

const bufsize = 32
type
  Keyboard = object
    fifo*: Fifo[uint8]
    keybuf*: array[bufsize, uint8]

var keyboard*: Keyboard

proc init_keyboard() =
  wait_KBC_sendready()
  io_out8(PORT_KEYCMD, KEYCMD_WRITE_MODE)
  wait_KBC_sendready()
  io_out8(PORT_KEYDAT, KBC_MODE)

proc init*(this: var Keyboard) =
  this.fifo.init(bufsize, cast[ptr uint8](this.keybuf.addr))
  init_keyboard()


proc inthandler21(esp: ptr cint) {.exportc.} =
  io_out8(PIC0_OCW2, 0x61)
  let data = cast[uint8](io_in8(PORT_KEYDAT))
  keyboard.fifo.put(data)

