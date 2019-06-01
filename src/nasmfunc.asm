
    global io_in8, io_in16, io_in32
    global io_out16, io_out32
    global io_load_eflags, io_store_eflags
    global load_gdtr, load_idtr

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

