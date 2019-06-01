
proc `+`[T](ptrobj: ptr T, idx: uint): ptr T =
  cast[ptr T](cast[uint](ptrobj) + idx)
