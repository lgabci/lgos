/* LGOS boot loader misc asm file */
.code16
.arch i8086,nojumps

/**
* \file misc.S
* LGOS x86 boot misc asm
*/

.section .text

/** \brief die
*
* \details prints an error message and halts computer
*
* \param str error message
*
* \par Modified registers
* \modregs{AX, BH, SI, BP (BIOS bug), flags, memory}
*
#void die(char * str) { }
*/
.globl die
die:    call    print
        cli
1:      hlt
        jmp     1b
