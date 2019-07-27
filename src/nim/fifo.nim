
type
  Fifo*[T] = object
    buf: ptr T
    p, q, size, free: int
  Status* {.pure.} = enum
    Empty
    Got

proc createFifo*[N: static[int], T](buf: var array[N, T]): Fifo[T] =
  Fifo[T](
    size: N,
    buf: cast[ptr T](buf.addr),
    free: N,
    p: 0,
    q: 0
  )

proc put*[T](this: var Fifo[T], data: T): bool {.discardable.} =
  if this.free == 0:
    return false
  (cast[ptr T](cast[int](this.buf) + sizeof(T)*this.p))[] = data
  this.p.inc
  if this.p == this.size:
    this.p = 0
  this.free.dec
  return true

proc get*[T](this: var Fifo[T]): T =
  if this.free == this.size:  # empty buffer
    return cast[T](0)
  let data = (cast[ptr T](cast[int](this.buf) + sizeof(T)*this.q))[]
  this.q.inc
  if this.q == this.size:
    this.q = 0
  this.free.inc
  return data

proc status*[T](this: Fifo[T]): Status =
  return
    if this.size == this.free:
      Status.Empty
    else:
      Status.Got

