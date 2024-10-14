# LGOS i386 emu meson.build file

hd_img = custom_target('hd.img',
                       command: ['mkimg.sh',
                                 '@OUTPUT@',
                                 '100M',
                                 boot_mbr_elf,
                                 boot_mbr_bin,
                                 boot_fat_elf,
                                 boot_fat_bin,
                                 loader_elf,
                                 loader_bin],
                       output: 'hd.img')

emu = run_target('emu',
                 command: ['emu.sh', hd_img])
