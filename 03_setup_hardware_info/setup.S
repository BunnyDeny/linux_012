INITSEG  = 0x9000
SETUPSEG = 0x9020

.code16
.text
.globl _start_setup

_start_setup:
    movw %cs, %ax
    movw %ax, %ds
    movw %ax, %es

    /* print "setup is running" */
    movw $setup_msg, %si
    movb $0x0E, %ah
print_loop:
    lodsb
    testb %al, %al
    jz print_done
    int $0x10
    jmp print_loop
print_done:
    /* newline */
    movb $0x0D, %al
    int $0x10
    movb $0x0A, %al
    int $0x10

    /* ===== 获取硬件信息 ===== */

    /* 1. 获取光标位置，存入 0x90000 */
    movw $INITSEG, %ax
    movw %ax, %ds
    movb $0x03, %ah
    xor  %bh, %bh
    int  $0x10
    movw %dx, (0)

    /* 2. 获取扩展内存大小，存入 0x90002 */
    movb $0x88, %ah
    int  $0x15
    movw %ax, (2)

    /* 3. 获取显示模式，存入 0x90004~0x90007 */
    movb $0x0f, %ah
    int  $0x10
    movw %bx, (4)
    movw %ax, (6)

    /* 4. 获取显卡信息，存入 0x90008~0x9000D */
    movb $0x12, %ah
    movb $0x10, %bl
    int  $0x10
    movw %ax, (8)
    movw %bx, (10)
    movw %cx, (12)

    /* 5. 复制 hd0 参数表（16字节）到 0x90080 */
    movw $0x0000, %ax
    movw %ax, %ds
    ldsw (4 * 0x41), %si
    movw $INITSEG, %ax
    movw %ax, %es
    movw $0x0080, %di
    movw $0x10, %cx
    rep
    movsb

    /* 6. 复制 hd1 参数表（16字节）到 0x90090 */
    movw $0x0000, %ax
    movw %ax, %ds
    ldsw (4 * 0x46), %si
    movw $INITSEG, %ax
    movw %ax, %es
    movw $0x0090, %di
    movw $0x10, %cx
    rep
    movsb

    /* 7. 检测第二块硬盘是否存在 */
    movw $0x1500, %ax
    movb $0x81, %dl
    int  $0x13
    jc   no_disk1
    cmpb $3, %ah
    je   is_disk1
no_disk1:
    movw $INITSEG, %ax
    movw %ax, %es
    movw $0x0090, %di
    movw $0x10, %cx
    movw $0x00, %ax
    rep
    stosb
is_disk1:

    /* 打印 "hardware info saved" */
    movw %cs, %ax
    movw %ax, %ds
    movw $done_msg, %si
    movb $0x0E, %ah
print_done2:
    lodsb
    testb %al, %al
    jz halt
    int $0x10
    jmp print_done2

halt:
    jmp .

setup_msg:
    .ascii "setup is running"
    .byte 0

done_msg:
    .ascii "hardware info saved"
    .byte 0
