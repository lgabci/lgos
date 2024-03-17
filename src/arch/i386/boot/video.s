# LGOS video asm file
.arch   i8086
.code16

.equ    INTVID, 0x10

.equ    GETVIDMODE, 0x0f        # get current video mode
.equ    WRITECHR, 0x0e          # teletype output

.section .text

### get current video page
        ## current video page number --> vidpage
        ## modified registers: AX, BH
.globl initvideo
initvideo:
        movb    $GETVIDMODE, %ah
        int     $INTVID
        movb    %bh, vidpage
        ret

### write character, teletype output
        ## input:
        ## AL = character to write
        ## modified registers: AX, BX, BP (BIOS bug)
.globl writechr
writechr:
        movb    $WRITECHR, %ah
        movb    vidpage, %bh
        int     $INTVID
        ret

### write zero terminated string
        ## input: SI = pointer to string
        ## modified registers: AX, BX, SI, BP (BIOS bug)
.globl writestr
writestr:
        lodsb
        testb   %al, %al
        je      1f
        call    writechr
        jmp     writestr
1:
        ret

.section bss

.lcomm  vidpage, 1
