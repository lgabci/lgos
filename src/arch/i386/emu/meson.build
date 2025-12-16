# LGOS i386 emu meson.build file

hd_ext2_img = custom_target('hd_ext2.img',
                            command: ['mkimg.sh',
                                      '@OUTPUT@',
                                      'hd',
                                      '100M',
                                      '2048',
                                      '20480',
                                      'Ext2',
                                      boot_mbr_elf,
                                      boot_ext2_elf,
                                      loader_elf],
                            output:  'hd_ext2.img')

hd_fat_img = custom_target('hd_fat.img',
                           command: ['mkimg.sh',
                                     '@OUTPUT@',
                                     'hd',
                                     '100M',
                                     '2048',
                                     '20480',
                                     'FAT',
                                     boot_mbr_elf,
                                     boot_fat_elf,
                                     loader_elf],
                           output:  'hd_fat.img')

hd_big_fat_img = custom_target('hd_big_fat.img',
                               command: ['mkimg.sh',
                                         '@OUTPUT@',
                                         'hd',
                                         '1G',
                                         '2048',
                                         '2000000',
                                         'FAT',
                                         boot_mbr_elf,
                                         boot_fat_elf,
                                         loader_elf],
                               output:  'hd_big_fat.img')

fd_ext2_img = custom_target('fd_ext2.img',
                            command: ['mkimg.sh',
                                      '@OUTPUT@',
                                      'fd',
                                      '1440K',
                                      '',
                                      '',
                                      'Ext2',
                                      '',
                                      boot_ext2_elf,
                                      loader_elf],
                            output:  'fd_ext2.img')

fd_fat_img = custom_target('fd_fat.img',
                           command: ['mkimg.sh',
                                     '@OUTPUT@',
                                     'fd',
                                     '1440K',
                                     '',
                                     '',
                                     'FAT',
                                     '',
                                     boot_fat_elf,
                                     loader_elf],
                           output:  'fd_fat.img')

fds_ext2_img = custom_target('fds_ext2.img',
                             command: ['mkimg.sh',
                                       '@OUTPUT@',
                                       'fd',
                                       '160K',
                                       '',
                                       '',
                                       'Ext2',
                                       '',
                                       boot_ext2_elf,
                                       loader_elf],
                             output:  'fds_ext2.img')

fds_fat_img = custom_target('fds_fat.img',
                            command: ['mkimg.sh',
                                      '@OUTPUT@',
                                      'fd',
                                      '160K',
                                      '',
                                      '',
                                      'FAT',
                                      '',
                                      boot_fat_elf,
                                      loader_elf],
                            output:  'fds_fat.img')

emu_hd_ext2 = run_target('emu_hd_ext2',
                         command: ['emu.sh', 'hd', hd_ext2_img])

emu_hd_fat = run_target('emu_hd_fat',
                        command: ['emu.sh', 'hd', hd_fat_img])

emu_hd_big_fat = run_target('emu_hd_big_fat',
                            command: ['emu.sh', 'hd', hd_big_fat_img])

emu_fd_ext2 = run_target('emu_fd_ext2',
                         command: ['emu.sh', 'fd', fd_ext2_img])

emu_fd_fat = run_target('emu_fd_fat',
                        command: ['emu.sh', 'fd', fd_fat_img])

emu_fds_ext2 = run_target('emu_fds_ext2',
                          command: ['emu.sh', 'fd', fds_ext2_img])

emu_fds_fat = run_target('emu_fds_fat',
                         command: ['emu.sh', 'fd', fds_fat_img])
