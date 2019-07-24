import low_layer
import constant
import fifo

const
  PIC_CTRL = 0x0043
  PIC_CNT0 = 0x0040

  MaxTimer = 500
  bufsize = 8

template sec*(n: int): auto =
  n * 100

template msec*(n: int): auto =
  n div 10

type
  TimerStatus = enum
    Unused
    Alloc
    Used
  Timer = object
    timeout*: int
    status: TimerStatus
    buf: array[bufsize, int8]
    fifo*: FIFO[int8]
    data: int8

  TimerCtrl = object
    count, next, size: int
    timers0: array[MaxTimer, Timer]
    timers: array[MaxTimer, ptr Timer]

proc alloc(this: var TimerCtrl): ptr Timer =
  for t in this.timers0.mitems:
    if t.status == Unused:
      t.status = Alloc
      return cast[ptr Timer](t.addr)
  return nil

proc free*(tp: ptr Timer) =
  tp.status = Unused

proc init*(this: var TimerCtrl) =
  this.count = 0
  this.next = high(int)
  for t in this.timers0.mitems:
    t.fifo.init(bufsize, cast[ptr int8](t.buf.addr))
    t.timeout = 0
    t.status = Unused
    t.data = 0

proc get*(this: TimerCtrl): int =
  this.count

proc set*(this: var TimerCtrl, timeout: int, data: int8): ptr Timer =
  let tp = this.alloc
  tp.timeout = timeout + this.count
  tp.data = data
  tp.status = Used
  let e = io_load_eflags()
  io_cli()
  var i = 0
  while i < this.size:
    if this.timers[i].timeout >= tp.timeout:
      break
    i.inc
  for j in countdown(this.size, i + 1):
    this.timers[j] = this.timers[j - 1]
  this.size.inc
  this.timers[i] = tp
  this.next = this.timers[0].timeout
  io_store_eflags(e)
  return tp

proc status*(this: var TimerCtrl): bool =
  this.count == MaxTimer


var tctrl*: TimerCtrl

proc init_pit*() =
  io_out8(PIC_CTRL, 0x34)
  io_out8(PIC_CNT0, 0x9c)
  io_out8(PIC_CNT0, 0x2e)

proc inthandler20(esp: ptr cint) {.exportc.} =
  io_out8(PIC0_OCW2, 0x60)
  tctrl.count.inc
  if tctrl.next > tctrl.count:
    return
  var i = 0  # number of timeout
  while i < tctrl.size:
    if tctrl.timers[i].timeout > tctrl.count:
      break
    tctrl.timers[i].status = Alloc
    tctrl.timers[i].fifo.put(tctrl.timers[i].data)
    i.inc

  tctrl.size -= i
  for j in 0 ..< tctrl.size:
    tctrl.timers[j] = tctrl.timers[i + j]

  if tctrl.size > 0:
    tctrl.next = tctrl.timers[0].timeout
  else:
    tctrl.next = high(int)

