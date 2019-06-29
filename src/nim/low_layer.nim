
proc io_hlt*() {.asmNoStackFrame exportc.} =
  asm """
    hlt
    ret
  """

proc io_cli*() {.asmNoStackFrame exportc.} =
  asm """
    cli
    ret
  """

proc io_sti*() {.asmNoStackFrame exportc.} =
  asm """
    sti
    ret
  """

proc io_stihlt*() {.asmNoStackFrame exportc.} =
  asm """
    sti
    hlt
    ret
  """

proc io_in8*(port: cint): cint {.asmNoStackFrame exportc.} =
  asm """
    movl 4(%esp), %edx
    movl $0, %eax
    inb %dx, %al
    ret
  """
proc io_in16*(port: cint): cint {.asmNoStackFrame exportc.} =
  asm """
    movl 4(%esp), %edx
    movl $0, %eax
    inw %dx, %ax
    ret
  """
proc io_in32*(port: cint): cint {.asmNoStackFrame exportc.} =
  asm """
    movl 4(%esp), %edx
    inl %dx, %eax
    ret
  """

proc io_out8*(port: uint16, data: uint16) {.asmNoStackFrame exportc.} =
  asm """
    movl 4(%esp), %edx
    movb 8(%esp), %al
    outb %al, %dx
    ret
  """

proc io_out16*(port, data: cint) {.asmNoStackFrame exportc.} =
  asm """
    movl 4(%esp), %edx
    movl 8(%esp), %eax
    outw %ax, %dx
    ret
  """

proc io_out32*(port, data: cint) {.asmNoStackFrame exportc.} =
  asm """
    movl 4(%esp), %edx
    movl 8(%esp), %eax
    outl %eax, %dx
    ret
  """

proc io_load_eflags*(): cint {.asmNoStackFrame exportc.} =
  asm """
    pushfl
    pop %eax
    ret
  """

proc io_store_eflags*(eflags: cint) {.asmNoStackFrame exportc.} =
  asm """
    movl 4(%esp), %eax
    push %eax
    popf
    ret
  """

proc load_gdtr*(limit, address: cint) {.asmNoStackFrame exportc.} =
  asm """
    mov 4(%esp), %ax #limit
    mov %ax, 6(%esp)
    lgdt 6(%esp)
    ret
  """
proc load_idtr*(limit, address: cint) {.asmNoStackFrame exportc.} =
  asm """
    mov 4(%esp), %ax #limit
    mov %ax, 6(%esp)
    lidt 6(%esp)
    ret
  """

