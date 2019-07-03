
proc `+`*[T: untyped, U: int or int8 or cint](ptrobj: ptr T, idx: U): ptr T =
  cast[ptr T](cast[U](ptrobj) + idx * sizeof(T))

proc num2hexstr*[T](cstr: var cstring, size: int or cint, num: T) =
  var num = num
  var cnt = 0
  while num != 0:
    cnt.inc
    let n = num - (num shr 4 shl 4)
    if cast[T](0) <= n and n <= cast[T](9):
      cstr[size - cnt] = cast[cuchar](n + ord('0'))
    else:
      cstr[size - cnt] = cast[cuchar](n + ord('A') - 0xa)
    num = num shr 4

