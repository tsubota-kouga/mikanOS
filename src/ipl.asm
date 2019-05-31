; mikan-os-ipl
; bits 32
; .text
; .code32
CYLS equ 10

    org 0x7c00                 ; where to be read this program
; for FAT12 format
    jmp entry
    db 0x90
    db "MIKANIPL"               ; name of bootsector
    dw 512                      ; size of one sector (must be 512)
    db 1                        ; size of cluster (must be 1)
    dw 1                        ; start of FAT (normally 1)
    db 2                        ; number of FAT (must be 2)
    dw 224                      ; size of / (normally 224)
    dw 2880                     ; size of drive (must be 2880)
    db 0xf0                     ; type of media (must be 0xf0)
    dw 9                        ; length of FAT (must be 9 sector)
    dw 18                       ; number of sector on one track (must be 18)
    dw 2                        ; number of head (must be 2)
    dd 0                        ; here, do not use partition
    dd 2880                     ; AGAIN: size of drive (must be 2880)
    db 0x00, 0x00, 0x29
    dd 0xffffffff
    db "MIKAN-OS   "            ; name of disk (11 bytes)
    db "FAT12   "               ; name of format (8 bytes)
    times 18  db  0

entry:
    mov ax, 0
    mov ss, ax
    mov sp, 0x7c00
    mov ds, ax

; load disk
    mov ax, 0x0820
    mov es, ax
    mov ch, 0                   ; cylinder0
    mov dh, 0                   ; head0
    mov cl, 2                   ; sector2

readloop:
    mov si, 0

retry:
    mov ah, 0x02                ; read disk
    mov al, 1                   ; sector1
    mov bx, 0
    mov dl, 0x00                ; A drive
    int 0x13                    ; call disk-bios
    jnc next                    ; success read disk

    add si, 1
    cmp si, 5                   ; max 5 times
    jae error
    mov ah, 0x00
    mov dl, 0x00                ; A drive
    int 0x13                    ; call disk-bios
    jmp retry

next:
    mov ax, es
    add ax, 0x0020
    mov es, ax
    add cl, 1
    cmp cl, 18
    jbe readloop
    mov cl, 1
    add dh, 1
    cmp dh, 2
    jb readloop
    mov dh, 0
    add ch, 1
    cmp ch, CYLS
    jb readloop

; start mikan-os
    mov [0x0ff0], ch            ; record how far ipl read
    jmp 0xc200

error:
    mov si, msg

putloop:
    mov al, [si]
    add si, 1
    cmp al, 0
    je fin
    mov ah, 0x0e                ; display one char
    mov bx, 15                  ; color code
    int 0x10                    ; call video-bios
    jmp putloop

fin:
    hlt
    jmp fin

msg:
    db 0x0a, 0x0a               ; two \n
    db "load error"
    db 0x0a                     ; \n
    db 0

    times 0x7dfe-0x7c00-($-$$) db 0     ; fill with 0 from $ to 0x001fe

    db 0x55, 0xaa
