
    global io_hlt, io_cli, io_stihlt, io_sti
    global io_in8, io_in16, io_in32
    global io_out8, io_out16, io_out32
    global io_load_eflags, io_store_eflags
    global load_gdtr, load_idtr
    global asm_inthandler21, asm_inthandler27, asm_inthandler2c
    extern inthandler21, inthandler27, inthandler2c


io_hlt:
    hlt
    ret

io_cli:
    cli
    ret

io_stihlt:
    sti
    hlt
    ret

io_sti:
    sti
    ret

io_in8:
    mov edx, [esp+4]
    mov eax, 0
    in al, dx
    ret

io_in16:
    mov edx, [esp+4]
    mov eax, 0
    in ax, dx
    ret

io_in32:
    mov edx, [esp+4]
    in eax, dx
    ret

io_out8:
    mov edx, [esp+4]
    mov al, [esp+8]
    out dx, al
    ret

io_out16:
    mov edx, [esp+4]
    mov eax, [esp+8]
    out dx, ax
    ret

io_out32:
    mov edx, [esp+4]
    mov eax, [esp+8]
    out dx, eax
    ret

io_load_eflags:
    pushfd
    pop eax
    ret

io_store_eflags:
    mov eax, [esp+4]
    push eax
    popfd
    ret

load_gdtr:
    mov ax, [esp+4]
    mov [esp+6], ax
    lgdt [esp+6]
    ret

load_idtr:
    mov ax, [esp+4]
    mov [esp+6], ax
    lidt [esp+6]
    ret

asm_inthandler21:
    push es
    push ds
    pushad
    mov eax, esp
    push eax
    mov ax, ss
    mov ds, ax
    mov es, ax
    call inthandler21
    pop eax
    popad
    pop ds
    pop es
    iretd

asm_inthandler27:
    push es
    push ds
    pushad
    mov eax, esp
    push eax
    mov ax, ss
    mov ds, ax
    mov es, ax
    call inthandler27
    pop eax
    popad
    pop ds
    pop es
    iretd

asm_inthandler2c:
  push es
  push ds
  pushad
  mov eax, esp
  push eax
  mov ax, ss
  mov ds, ax
  mov es, ax
  call inthandler2c
  pop eax
  popad
  pop ds
  pop es
  iretd
