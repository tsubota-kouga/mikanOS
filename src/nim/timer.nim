
import low_layer
import constant
import fifo

const
  PIC_CTRL = 0x0043
  PIC_CNT0 = 0x0040

  MaxTimer = 500

template s*(n: int): auto =
  n * 100

template ms*(n: int): auto =
  when n mod 10 != 0:
    {.warning: "`ms` cannot use the one's place".}
  n div 10

type
  TimerStatus {.pure.} = enum
    Unused
    Alloc
    Used
  Timer*[T] = object
    next: ptr Timer[T]
    timeout*: int
    status: TimerStatus
    fifo*: ptr FIFO[T]
    data: T

  TimerCtrl[T] = object
    count, next: int
    timers0: array[MaxTimer, Timer[T]]
    t0: ptr Timer[T]
    fifo*: ptr Fifo[T]

proc alloc*[T](this: var TimerCtrl[T]): ptr Timer[T] =
  for t in this.timers0.mitems:
    if t.status == TimerStatus.Unused:
      t.status = TimerStatus.Alloc
      return t.addr
  return nil

proc alloc*[T](this: var TimerCtrl[T], timeout: int, data: T): ptr Timer[T] =
  let tp = this.alloc
  if tp.isNil:
    return nil
  tp.timeout = timeout + this.count
  tp.data = data
  tp.status = TimerStatus.Used
  let e = io_load_eflags()
  io_cli()
  var t = this.t0
  if tp.timeout <= t.timeout:
    this.t0 = tp
    tp.next = t
    this.next = tp.timeout
    io_store_eflags(e)
    return tp
  var s = t
  while true:
    s = t
    t = t.next
    if tp.timeout <= t.timeout:
      s.next = tp
      tp.next = t
      io_store_eflags(e)
      return tp

proc set*[T](this: var TimerCtrl[T], timeout: int, data: T): bool =
  not this.alloc(timeout, data).isNil

proc free*(tp: ptr Timer) =
  tp.status = TimerStatus.Unused

proc init*[T](this: var TimerCtrl[T], fifoptr: ptr Fifo[T]) =
  this.count = 0
  this.next = high(int)
  this.fifo = fifoptr
  for t in this.timers0.mitems:
    t.fifo = this.fifo
    t.timeout = 0
    t.status = TimerStatus.Unused
    t.data = cast[T](0)
  let t = this.alloc
  t.timeout = high(int)
  t.status = TimerStatus.Used
  t.next = nil
  this.t0 = t
  this.next = high(int)

proc count*(this: TimerCtrl): int =
  this.count

var tctrl*: TimerCtrl[FifoType]

proc init_pit*() =
  io_out8(PIC_CTRL, 0x34)
  io_out8(PIC_CNT0, 0x9c)
  io_out8(PIC_CNT0, 0x2e)


type
  MultiTask = object
    tr: cint

proc init*(this: var MultiTask) =
  discard tctrl.set(20.ms, (data: 20'u8, kind: FifoKind.MultiTaskTimer))
  this.tr = 3 * 8

proc switch*(this: var MultiTask) =
  if this.tr == 3 * 8:
    this.tr = 4 * 8
  else:
    this.tr = 3 * 8
  discard tctrl.set(20.ms, (data: 20'u8, kind: FifoKind.MultiTaskTimer))
  farjmp(0, this.tr)

var mtask*: MultiTask

proc inthandler20(esp: ptr cint) {.exportc.} =
  io_out8(PIC0_OCW2, 0x60)
  tctrl.count.inc
  if tctrl.next > tctrl.count:
    return
  var
    timer = tctrl.t0
    switch_task = false
  while true:
    if timer.timeout > tctrl.count:
      break
    # time out
    timer.status = TimerStatus.Unused
    if timer.data.kind == FifoKind.MultiTaskTimer:
      switch_task = true
    else:
      timer.fifo[].put(timer.data)
    timer = timer.next
  tctrl.t0 = timer
  tctrl.next = tctrl.t0.timeout
  if switch_task:
    mtask.switch()

