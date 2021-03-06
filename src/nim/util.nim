
type ArithmeticPtr*[T] = distinct ptr T

proc `[]`*[T](p: ArithmeticPtr[T], idx: int): T =
  cast[ptr T](cast[int](p) + idx * sizeof(T))[]
proc `[]=`*[T](p: ArithmeticPtr[T], idx: int, v: T) =
  cast[ptr T](cast[int](p) + idx * sizeof(T))[] = v
proc `+`*[T](p: ArithmeticPtr[T], idx: int): ptr T =
  cast[ptr T](cast[int](p) + idx*sizeof(T))

proc `+`*[T](p: ptr T, idx: int): ptr T =
  cast[ptr T](cast[int](p) + idx * sizeof(T))
proc num2hexstr*[T](cstr: var cstring, size: int or cint, num: T) {.deprecated.} =
  var num = num
  var cnt = 0
  while num != 0:
    cnt.inc
    let n = num - (num and cast[T](not 0xf))
    if cast[T](0) <= n and n <= cast[T](9):
      cstr[size - cnt] = cast[cuchar](n + ord('0'))
    else:
      cstr[size - cnt] = cast[cuchar](n + ord('A') - 0xa)
    num = num shr 4

proc num2hexstr*[N: static[int], T](a: var array[N, cuchar], num: T) {.deprecated.} =
  var num = num
  var cnt = 0
  while num != 0:
    cnt.inc
    let n = num - (num and cast[T](not 0xf))
    if cast[T](0) <= n and n <= cast[T](9):
      a[N - cnt] = cast[cuchar](n + ord('0'))
    else:
      a[N - cnt] = cast[cuchar](n + ord('A') - 0xa)
    num = num shr 4

proc num2str*[S: static[int], T: SomeInteger](a: var array[S, cuchar], num: T, N: int=10): int {.discardable.} =
  ## @Return:
  ##    number of digits
  var
    negative = T is SomeSignedInt and num < 0
    num =
      when T is SomeSignedInt:
        num.abs
      else:
        num
    cnt = 0
  while num != cast[T](0):
    cnt.inc
    let n = num - ((num div cast[T](N)) * cast[T](N))
    if cast[T](0) <= n and n <= cast[T](9):
      a[S - cnt] = cast[cuchar](n + ord('0'))
    else:
      a[S - cnt] = cast[cuchar](n + ord('A') - 0xa)
    num = num div cast[T](N)
  if cnt == 0:
    cnt.inc
    a[S - cnt] = '0'
  if negative:
    cnt.inc
    a[S - cnt] = '-'
  return cnt

