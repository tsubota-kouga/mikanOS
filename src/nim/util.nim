
proc `+`[T](ptrobj: ptr T, idx: int): ptr T =
  cast[ptr T](cast[int](ptrobj) + idx * sizeof(T))
