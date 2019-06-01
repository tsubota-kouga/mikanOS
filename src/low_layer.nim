
proc io_hlt() =
  asm """
    hlt
  """

proc io_cli() =
  asm """
    cli
  """

proc io_sti() =
  asm """
    sti
  """

proc io_stihlt() =
  asm """
    sti
    hlt
  """

proc io_in8(port: int): int {.importc.}
proc io_in16(port: int): int {.importc.}
proc io_in32(port: int): int {.importc.}

proc io_out8(port: uint16, data: uint16) =
  # %1 expands to %dx because port is a uint16
  asm """
    outb %0, %1
  :
  : "a"(`data`), "Nd"(`port`)
  :
  """

proc io_out16(port, data: int) {.importc.}
proc io_out32(port, data: int) {.importc.}

proc io_load_eflags(): int {.importc.}
# proc io_load_eflags(): int =
#   let eflag = 0
#   asm """
#     pushfl
#     pop %%eax
#   : "=a"(eflag)
#   """
#   return eflag

proc io_store_eflags(eflags: int) {.importc.}

proc load_gdtr(limit, address: int) {.importc.}
proc load_idtr(limit, address: int) {.importc.}

