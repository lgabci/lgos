# LGOS i386 emu meson.build file

hd_img = custom_target('hd.img',
                       command: ['mkimg.sh',
                                 '@OUTPUT@',
                                 '100M',
                                 boot_mbr_elf,
                                '@INPUT@',
                                loader_elf,
                                loader_bin],
                       input: boot_mbr_bin,
                       output: 'hd.img')

emu = run_target('emu',
                 command: ['emu.sh', hd_img])
