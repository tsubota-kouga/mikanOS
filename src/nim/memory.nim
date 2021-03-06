import low_layer

const
  EFLAGS_AC_BIT = 0x00040000
  CR0_CACHE_DISABLE = 0x60000000

func memtest_sub*(head, tail: uint): uint =
  const
    pat0 = 0xaa55aa55'u
    pat1 = 0x55aa55aa'u
  var
    old: uint
    i = head
    p {.volatile.}: ptr uint
  while i <= tail:
    p = cast[ptr uint](i + 0xffc)
    old = p[]
    p[] = pat0
    p[] = p[] xor 0xffffffff'u
    if p[] != pat1:
      p[] = old
      break
    p[] = p[] xor 0xffffffff'u
    if p[] != pat0:
      p[] = old
      break
    p[] = old
    i += 0x1000
  return i

proc memtest*(head, tail: uint): uint =
  var
    flg486 = 0'i16
    eflg = cast[cint](io_load_eflags() or EFLAGS_AC_BIT)
  io_store_eflags(eflg)
  eflg = io_load_eflags()
  if((eflg and EFLAGS_AC_BIT) != 0):
    flg486 = 1
  eflg = eflg and not EFLAGS_AC_BIT
  io_store_eflags(eflg)
  if flg486 != 0:
    let cr0 = load_cr0() or CR0_CACHE_DISABLE
    store_cr0(cr0)
  result = memtest_sub(head, tail)
  if flg486 != 0:
    let cr0 = load_cr0() and not CR0_CACHE_DISABLE
    store_cr0(cr0)

const MEMORY_FREES = 4090

type
  FreeInfo = object
    address, size: uint
  MemoryManager* = ref object
    frees, maxfrees, lostsize, losts: uint
    freerealm: array[MEMORY_FREES, FreeInfo]

func init*(this: MemoryManager) =
  this.frees = 0
  this.maxfrees = 0
  this.lostsize = 0
  this.losts = 0

func total*(this: MemoryManager): uint =
  var t = 0'u
  for i in 0'u ..< this.frees:
    t += this.freerealm[i].size
  return t

proc alloc*(this: MemoryManager, size: uint): uint =
  for i in 0'u ..< this.frees:
    if this.freerealm[i].size >= size:
      let a = this.freerealm[i].address
      this.freerealm[i].address += size
      this.freerealm[i].size -= size
      if this.freerealm[i].size == 0:
        this.frees.dec
        for j in i ..< this.frees:
          this.freerealm[j] = this.freerealm[j + 1]
      return a
  return 0

proc free*(this: MemoryManager, address, size: uint): bool {.discardable.} =
  var i = 0'u
  while i < this.frees:
    if this.freerealm[i].address > address:
      break
    i.inc
  if i > 0'u:
    if this.freerealm[i - 1].address + this.freerealm[i - 1].size == address:
      this.freerealm[i - 1].size += size
      if i < this.frees:
        if address + size == this.freerealm[i].address:
          this.freerealm[i - 1].size += this.freerealm[i].size
          this.frees.dec
          for j in i ..< this.frees:
            this.freerealm[i] = this.freerealm[i + 1]
      return true
  if i < this.frees:
    if address + size == this.freerealm[i].address:
      this.freerealm[i].address = address
      this.freerealm[i].size += size
      return true
  if this.frees < MEMORY_FREES:
    for j in countdown(this.frees, i + 1):
      this.freerealm[j] = this.freerealm[j - 1]
    this.frees.inc
    if this.maxfrees < this.frees:
      this.maxfrees = this.frees
    this.freerealm[i].address = address
    this.freerealm[i].size = size
    return true
  this.losts.inc
  this.lostsize += size
  return false

proc alloc4k*(this: MemoryManager, size: uint): uint =
  let size = (size + 0xfff'u) and 0xfffff000'u
  return this.alloc(size)

proc free4k*(this: MemoryManager, address, size: uint): bool {.discardable.} =
  let size = (size + 0xfff'u) and 0xfffff000'u
  return this.free(address, size)

proc memmove(dest: pointer, src: pointer, n: csize): pointer {.exportc.} =
  if dest < src and dest < cast[pointer](cast[csize](src) + n):
    for i in countdown(n, 1):
      cast[ptr cuchar](cast[int](dest) + i*sizeof(cuchar))[] =
        cast[ptr cuchar](cast[int](src) + i*sizeof(cuchar))[]
  else:
    for i in 0 ..< n:
      cast[ptr cuchar](cast[int](dest) + i*sizeof(cuchar))[] =
        cast[ptr cuchar](cast[int](src) + i*sizeof(cuchar))[]
  return dest

# {.emit: """
# void *memmove(void *s1, const void *s2, size_t n)
# {
#     char       *p1 = (char *)s1;
#     const char *p2 = (const char *)s2;
#
#     if (p1 < p2  &&  p1 < p2 + n)
#         for (p1 += n, p1 += n; n > 0; n--)      /* 後ろからコピー */
#             *p1-- = *p2--;
#     else
#         for ( ; n > 0; n--)                     /* 前からコピー */
#             *p1++ = *p2++;
#     return (s1);
# }
#
# void *memset(void *s, int c, size_t n)
# {
#     const unsigned char uc = c;
#     unsigned char       *p = (unsigned char *)s;
#
#     while (n-- > 0)
#         *p++ = uc;
#
#     return (s);
# }
#
# void *memcpy(void *s1, const void *s2, size_t n)
# {
#     char        *p1 = (char *)s1;
#     const char  *p2 = (const char *)s2;
#
#     while (n-- > 0) {
#         *p1 = *p2;
#         p1++;
#         p2++;
#     }
#     return (s1);
# }
#
# """.}
#
