/* LGOS boot loader init asm file */
.code16gcc
.arch i8086

#define MBRCOUNT        4
#define MBRBOOT         0x80

#define MBRSTAT         0x00
#define MBRFHEAD        0x01
#define MBRFSEC         0x02
#define MBRFCYL         0x03
#define MBRPTYPE        0x04
#define MBRLHEAD        0x05
#define MBRLSEC         0x06
#define MBRLCYL         0x07
#define MBRLBA          0x08
#define MBRNUMSEC       0x0c
#define MBRSIZE         0x10

.section .text

.globl getbootsec
getbootsec:
        movw    $mbr, %bx
        movw    $MBRCOUNT, %cx
        xorw    %si, %si

1:      testb   $MBRBOOT, MBRSTAT(%bx)
        jz      2f
        cmpb    $0, MBRPTYPE(%bx)
        jz      2f

        incw    %si
        movw    MBRLBA(%bx), %ax
        movw    MBRLBA + 2(%bx), %dx

2:      addw    $MBRSIZE, %bx
        loop    1b

        ret

.section .mbr, "a", @progbits
mbr:    .space 4 * MBRSIZE
