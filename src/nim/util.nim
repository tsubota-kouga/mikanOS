
proc `+`[T](ptrobj: ptr T, idx: int): ptr T =
  cast[ptr T](cast[int](ptrobj) + idx * sizeof(T))

proc num2hexstr[T: int or int8](cstr: ptr cstring, num: T) =
  var num = num
  var cnt = 0
  while num != 0:
    cnt = cnt + 1
    if 0 <= num - (num shr 4 shl 4) and num - (num shr 4 shl 4) <= 9:
      cstr[sizeof(T) - cnt] = cast[char](num - (num shr 4 shl 4) + ord('0'))
    else:
      cstr[sizeof(T) - cnt] = cast[char](num - (num shr 4 shl 4) + ord('A') - 0xa)
    num = num shr 4
