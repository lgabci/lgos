/* LGOS boot loader mbr asm file */
.code16
.arch i8086,nojumps

/**
* \file mbr.S
* LGOS x86 boot mbr asm
*/

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

/** \brief mbr main function
*
* \par Modified registers
* \modregs{\a AX, \a BX, \a CX, \a DX, \a SI, \a BP <sub>(BIOS bug)</sub>},
* \modregs{flags, memory}
*
#void main() { }
*/
.globl main
main:
        call    getbootsec


// ----------------------------------------------------------
1:      hlt
        jmp     1b
// ----------------------------------------------------------


/** \brief get boot sector
*
* \details get boot sector LBA number from MBR active entry \n
* prints error message and halts on errors:
* - no active partition
* - multiple active partition
* - empty active partition type
*
* \param[out] AX LBA low 16 bits
* \param[out] DX LBA hight 16 bits
*
* \par Modified registers
* \modregs{AX, BX, CX, DX, SI, \a BP <sub>(BIOS bug)</sub>, flags, memory}
*
#void getbootsec(lba_h DX, lba_l AX) { }
*/
.globl getbootsec
getbootsec:
        movw    $mbr, %bx
        movw    $MBRCOUNT, %cx
        xorw    %si, %si

1:      testb   $MBRBOOT, MBRSTAT(%bx)
        jz      2f
        cmpb    $0, MBRPTYPE(%bx)
        je      3f

        incw    %si
        movw    MBRLBA(%bx), %ax
        movw    MBRLBA + 2(%bx), %dx

2:      addw    $MBRSIZE, %bx
        loop    1b

        cmpw    $1, %si
        jne     3f

        ret

3:      movw    $invstr, %si
        jmp     die

.section .data
invstr: .asciz "Invalid MBR.\r\n"

.section .mbr, "a", @progbits
mbr:    .space 4 * MBRSIZE
