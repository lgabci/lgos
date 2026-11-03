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
* prints an error message and halts computer
*
* \param str error message
*
* \par Modified registers
* \c AX, \c BH, \c SI, \c flags, \c memory
*
#void die(char * str) { }
*/
.globl die
die:    call    print
        cli
1:      hlt
        jmp     1b
