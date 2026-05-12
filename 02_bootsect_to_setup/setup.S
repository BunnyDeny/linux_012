.code16
.text
.globl _start_setup

_start_setup:
    movw %cs, %ax
    movw %ax, %ds
    movw %ax, %es

    movw $setup_msg, %si
    movb $0x0E, %ah
setup_print_loop:
    lodsb
    testb %al, %al
    jz setup_print_done
    int $0x10
    jmp setup_print_loop
setup_print_done:

    jmp .

setup_msg:
    .ascii "setup is running"
    .byte 0
