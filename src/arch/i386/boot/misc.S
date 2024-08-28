/* LGOS i386 boot misc asm file */
.code16gcc
.arch i8086,nojumps

/* print error message and halt
   input: SI = pointer to error message, zero terminated string
   output: halt machine
   modified: AX, BX, SI, BP (BIOS bug)
*/
.global halt
halt:
        call    write_str
        cli
1:      hlt
        jmp     1b
