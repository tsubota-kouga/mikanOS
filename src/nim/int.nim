import fifo
import low_layer
import constant

var keyfifo*: FIFO
var keybuf*: array[32, cuchar]

var mousefifo*: FIFO
var mousebuf*: array[128, cuchar]

proc init_pic*() =
  io_out8(PIC0_IMR, 0xff)  # prohibit interrupt
  io_out8(PIC1_IMR, 0xff)  # prohibit interrupt

  io_out8(PIC0_ICW1, 0x11)  # edge trigger mode
  io_out8(PIC0_ICW2, 0x20)  # catch IRQ0-7 with INT20-27
  io_out8(PIC0_ICW3, 1 shl 2)  # PIC1 is connected with IRQ2
  io_out8(PIC0_ICW4, 0x01)  # non buffer mode

  io_out8(PIC1_ICW1, 0x11)  #edge trigger mode
  io_out8(PIC1_ICW2, 0x28)  # catch IRQ0-7 with INT20-27
  io_out8(PIC1_ICW3, 2)  # PIC1 is connected with IRQ2
  io_out8(PIC1_ICW4, 0x01)  # non buffer mode

  io_out8(PIC0_IMR, 0xfb)  # only PIC1
  io_out8(PIC1_IMR, 0xff)  # prohibit all interrupt

proc inthandler21(esp: ptr cint) {.exportc.} =
  io_out8(PIC0_OCW2, 0x61)
  let data = cast[cuchar](io_in8(PORT_KEYDAT))
  keyfifo.put(data)

proc inthandler2c(esp: ptr cint) {.exportc.} =
  io_out8(PIC1_OCW2, 0x64)
  io_out8(PIC0_OCW2, 0x62)
  let data = cast[cuchar](io_in8(PORT_KEYDAT))
  mousefifo.put(data)

proc inthandler27(esp: ptr cint) {.exportc.} =
  io_out8(PIC0_OCW2, 0x67)

