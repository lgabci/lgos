# LGOS i386 emu meson.build file

hd_fat_img = custom_target('hd_fat.img',
                           command: ['mkimg.sh',
                                     '@OUTPUT@',
                                     'FAT',
                                     '100M',
                                     boot_mbr_elf,
                                     boot_mbr_bin,
                                     boot_fat_elf,
                                     boot_fat_bin,
                                     loader_elf,
                                     loader_bin],
                           output: 'hd_fat.img')

hd_ext2_img = custom_target('hd_ext2.img',
                            command: ['mkimg.sh',
                                      '@OUTPUT@',
                                      'Ext2',
                                      '100M',
                                      boot_mbr_elf,
                                      boot_mbr_bin,
                                      boot_ext2_elf,
                                      boot_ext2_bin,
                                      loader_elf,
                                      loader_bin],
                            output: 'hd_ext2.img')

emu = run_target('emu',
                 command: ['emu.sh', hd_ext2_img])
