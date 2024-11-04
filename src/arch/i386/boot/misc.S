/* LGOS i386 boot misc asm file */
.code16
.arch i8086,nojumps

/* print error message and halt
   input: SI = pointer to error message, zero terminated string
   output: halt machine
   modified: AX, BX, SI, BP (BIOS bug)
*/
.global halt
halt:
        callw   write_str
1:      hlt
        jmp     1b
