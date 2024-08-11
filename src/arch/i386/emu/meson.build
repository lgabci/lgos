# LGOS i386 emu meson.build file

hd_img = custom_target('hd.img',
                       build_by_default: true,
                       command: ['mkimg.sh', '@OUTPUT@', '100M', '@INPUT@'],
                       input: boot_mbr_bin,
                       output: 'hd.img')

emu = run_target('emu',
                 command: ['emu.sh', hd_img])
