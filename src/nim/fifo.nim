
const
  FLAGS_OVERRUN = 0x0001

type FIFO*[T] = object
  buf: ptr T
  p, q, size, free, flags: int

proc init*[T](this: var FIFO[T], size: int, buf: ptr T) =
  this.size = size
  this.buf = buf
  this.free = size
  this.flags = 0
  this.p = 0
  this.q = 0

proc put*[T](this: var FIFO[T], data: T): int {.discardable.} =
  if this.free == 0:
    this.flags = this.flags or FLAGS_OVERRUN
    return -1
  (cast[ptr T](cast[int](this.buf) + sizeof(T)*this.p))[] = data
  this.p.inc
  if this.p == this.size:
    this.p = 0
  this.free.dec
  return 0

proc get*[T](this: var FIFO[T]): T =
  if this.free == this.size:  # empty buffer
    return cast[T](0)
  let data = (cast[ptr T](cast[int](this.buf) + sizeof(T)*this.q))[]
  this.q.inc
  if this.q == this.size:
    this.q = 0
  this.free.inc
  return data

proc status*[T](this: FIFO[T]): int =
  return this.size - this.free

