import low_layer
import constant
import fifo

const
  PIC_CTRL = 0x0043
  PIC_CNT0 = 0x0040

  bufsize = 8

type timerCtrl = object
  count: int
  timeout: int
  buf: array[bufsize, int8]
  fifo*: FIFO[int8]
  data: int8

proc init*(this: var timerCtrl) =
  this.count = 0
  this.fifo.init(bufsize, cast[ptr int8](this.buf.addr))

proc get*(this: timerCtrl): int =
  this.count

proc set*(this: var timerCtrl, timeout: int, data: int8) =
  let eflags = io_load_eflags()
  io_cli()
  this.timeout = timeout
  this.data = data
  io_store_eflags(eflags)

var tctrl*: timerCtrl

proc init_pit*() =
  io_out8(PIC_CTRL, 0x34)
  io_out8(PIC_CNT0, 0x9c)
  io_out8(PIC_CNT0, 0x2e)

proc inthandler20(esp: ptr cint) {.exportc.} =
  io_out8(PIC0_OCW2, 0x60)
  tctrl.count.inc
  if tctrl.timeout > 0:
    tctrl.timeout.dec
    if tctrl.timeout == 0:
      tctrl.fifo.put(tctrl.data)

