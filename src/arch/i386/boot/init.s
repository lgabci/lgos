# LGOS boot loader init asm file
.arch   i8086
.code16

.equ BIOSSEG, 0x7c0
.equ NEWSEG, 0x600

.equ TEXTSIZE, 0x200
.equ STACKEND, 0x400

.section .text

.globl _start
_start:
        cli                     # set stack
        movw    $NEWSEG, %ax
        movw    %ax, %ss
        movw    $STACKEND, %sp
        sti

        cld                     # clear direction flag

        movw    %ax, %ds        # set segment registers
        movw    %ax, %es

        movw    $0, %di         # copy running program, 0:7C00 -> 0:6000
        movw    $(BIOSSEG - NEWSEG) << 4, %si
        movw    $TEXTSIZE >> 1, %cx
rep     movsw
        ljmp    $NEWSEG, $1f

1:
        call    initvideo

        movw    $grtmsg, %si
        call    writestr




1:      hlt
        jmp 1b

.section .data

.ifdef BSTYPE_MBR
grtmsg: .string "MBR\r\n"
.endif

########################################
.include "inc.s"
########################################
