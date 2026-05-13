SETUPLEN = 4
BOOTSEG = 0x7c0
INITSEG = 0x9000
SETUPSEG = 0x9020
SYSSEG = 0x1000
SYSSIZE = 0x3000
ENDSEG = SYSSEG + SYSSIZE
ROOT_DEV = 0x000

.code16
.text
.global _start
_start:
    jmpl $BOOTSEG, $start2

start2:
    movw $BOOTSEG, %ax
    movw %ax, %ds
    movw $INITSEG, %ax
    movw %ax, %es
    movw $256, %cx
    subw %si, %si
    subw %di, %di

    rep
    movsw

    jmpl $INITSEG, $go

go:
    movw %cs, %ax
    movw %ax, %ds
    movw %ax, %es
    movw %ax, %ss
    movw $0xFF00, %sp

load_setup:
    movw $0x0000, %dx
    movw $0x0002, %cx
    movw $0x0200, %bx
    movb $SETUPLEN, %al
    movb $0x02, %ah
    int $0x13
    jnc ok_load_setup
    movw $0x0000, %dx
    movw $0x0000, %ax
    int $0x13
    jmp load_setup

ok_load_setup:
    movw $msg, %si
    movb $0x0E, %ah
print_loop:
    lodsb
    testb %al, %al
    jz print_done
    int $0x10
    jmp print_loop
print_done:
    /* 输出回车换行 */
    movb $0x0D, %al
    int $0x10
    movb $0x0A, %al
    int $0x10

    jmpl $SETUPSEG, $0

msg:
    .ascii "Setup has been loaded"
    .byte 0

.org 508
root_dev:
    .word ROOT_DEV
boot_flag:
    .word 0xaa55
