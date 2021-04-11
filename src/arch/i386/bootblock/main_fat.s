.arch i8086
.code16

/**
 * @file main_fat.s
 * @brief i386 bootblock, FAT
 *
 * Steps:
 */

/**
 * @brief i386 FAT boot sector main function
 *
 * i386 main
 *
 # void main(void) {
 */
.globl main
main:
        movw    $0xb800, %ax
        movw    %ax, %ds
        movb    $'X', 0
        movb    $3, 1
1:      cli
        hlt
        jmp     1b

