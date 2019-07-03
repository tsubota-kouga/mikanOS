
const
  FLAGS_OVERRUN = 0x0001

type FIFO* = object
  buf: ptr cuchar
  p, q, size, free, flags: cint

proc init*(fifo: var FIFO, size: cint, buf: ptr cuchar) =
  fifo.size = size
  fifo.buf = buf
  fifo.free = size
  fifo.flags = 0
  fifo.p = 0
  fifo.q = 0

proc put*(fifo: var FIFO, data: cuchar): cint {.discardable.} =
  if fifo.free == 0:
    fifo.flags = fifo.flags or FLAGS_OVERRUN
    return -1
  (cast[ptr cuchar](cast[cint](fifo.buf) + sizeof(cuchar)*fifo.p))[] = data
  fifo.p.inc
  if fifo.p == fifo.size:
    fifo.p = 0
  fifo.free.dec
  return 0

proc get*(fifo: var FIFO): cuchar =
  if fifo.free == fifo.size:  # empty buffer
    return cast[cuchar](0)
  let data = (cast[ptr cuchar](cast[cint](fifo.buf) + sizeof(cuchar)*fifo.q))[]
  fifo.q.inc
  if fifo.q == fifo.size:
    fifo.q = 0
  fifo.free.inc
  return data

proc status*(fifo: var FIFO): cint =
  return fifo.size - fifo.free

