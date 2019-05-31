; mikan-os

; bits 32
; .text
; .code32
BOTPAK equ 0x00280000                   ; where bootpack loaded
DSKCAC equ 0x00100000                   ; place of disk cache
DSKCAC0 equ 0x00008000                  ; place of disk cache (real mode)

CYLS equ 0x0ff0                         ; bootsector sets this
LEDS equ 0x0ff1
VMODE equ 0x0ff2                        ; bit colors
SCRNX equ 0x0ff4                        ; resolution x
SCRNY equ 0x0ff6                        ; resolution y
VRAM equ 0x0ff8                         ; start address of graphic buffer

    org 0xc200                          ; where to be read this program
    mov al, 0x13                        ; color
    mov ah, 0x00
    int 0x10
    mov byte [VMODE], 8                 ; record screen mode
    mov word [SCRNX], 320
    mov word [SCRNY], 200
    mov dword [VRAM], 0x000a0000

; get status of keyboard from bios

    mov ah, 0x02
    int 0x16                            ; keyboard-bios
    mov [LEDS], al

; disable interrupts for PIC
    mov al, 0xff
    out 0x21, al
    nop
    out 0xa1, al
    cli                                 ; disable interrupts on cpu level too

    call waitkbdout
    mov al, 0xd1
    out 0x64, al
    call waitkbdout
    mov al, 0xdf                        ; enable A20
    out 0x60, al
    call waitkbdout

; move into protect mode
    lgdt [gdtr0]                        ; sets provisional GDT
    mov eax, cr0
    and eax, 0x7fffffff                 ; mask bit31 to 0 to disable paging
    or eax, 0x00000001                  ; mask bit0 to 1 to move into protect mode
    mov cr0, eax
    jmp pipelineflush
pipelineflush:
    mov ax, 1*8                         ; random access segments 32bits
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

; transfer bootpack
    mov esi, bootpack                   ; src
    mov edi, BOTPAK                     ; dist
    mov ecx, 512*1024/4
    call memcpy

;transfer diskdata
    mov esi, 0x7c00                     ; src
    mov edi, DSKCAC                     ; dist
    mov ecx, 512/4
    call memcpy

; transfer others
    mov esi, DSKCAC0+512                ; src
    mov edi, DSKCAC+512                 ; dist
    mov ecx, 0
    mov cl, byte [CYLS]
    imul ecx, 512*18*2/4                ; converts cylinder number to its number of bytes
    sub ecx, 512/4
    call memcpy

; startup bootpack
    mov ebx, BOTPAK
    mov ecx, [ebx+16]
    add ecx, 3
    shr ecx, 2
    jz skip
    mov esi, [ebx+20]                        ; src
    add esi, ebx
    mov edi, [ebx+12]                   ; dist
    call memcpy

skip:
    mov esp, [ebx+12]                   ; init stack
    jmp dword 2*8:0x0000001b

waitkbdout:
    in al, 0x64
    and al, 0x02
    jnz waitkbdout
    ret

memcpy:
    mov eax, [esi]
    add esi, 4
    mov [edi], eax
    add edi, 4
    sub ecx, 1
    jnz memcpy
    ret

    alignb 16, db 0

gdt0:
    times 8 db 0                        ; null selector
    dw 0xffff, 0x0000, 0x9200, 0x00cf   ; random access segments 32bits
    dw 0xffff, 0x0000, 0x9a28, 0x0047   ; executable segments 32bits (for bootpack)

    dw 0

gdtr0:
    dw 8*3-1
    dd gdt0
    alignb 16, db 0

bootpack:

