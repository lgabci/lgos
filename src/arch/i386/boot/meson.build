# LGOS i386/boot meson.build file

boot_mbr_elf = executable('mbr.elf',
                          ['init.S', 'mbr.S', 'video.S', 'disk.S', 'misc.S'],
                          c_args: ['-Wa,--defsym,MBR=1'],
                          link_args: ['-T', files('mbr.ld')[0].full_path()],
                          link_depends: 'mbr.ld')

boot_mbr_bin = custom_target('mbr.bin',
                             command: ['objcopy', '-O', 'binary',
                                       '@INPUT@', '@OUTPUT@'],
                             input: boot_mbr_elf,
                             output: 'mbr.bin')

boot_fat_map = meson.current_build_dir() / 'fat.map'
boot_fat_elf = executable('fat.elf',
                          ['init.S', 'load.S', 'video.S', 'disk.S', 'misc.S'],
                          c_args: ['-Wa,--defsym,FAT=1'],
                          extra_files: [boot_fat_map],
                          link_args: ['-T', files('fat.ld')[0].full_path(),
                                      '-Wl,-Map=' + boot_fat_map],
                          link_depends: 'fat.ld')

boot_fat_bin = custom_target('fat.bin',
                             command: ['objcopy', '-O', 'binary',
                                       '@INPUT@', '@OUTPUT@'],
                             input: boot_fat_elf,
                             output: 'fat.bin')

boot_ext2_elf = executable('ext2.elf',
                           ['init.S', 'load.S', 'video.S', 'disk.S', 'misc.S'],
                           c_args: ['-Wa,--defsym,EXT2=1'],
                           link_args: ['-T', files('ext2.ld')[0].full_path()],
                           link_depends: 'ext2.ld')

boot_ext2_bin = custom_target('ext2.bin',
                              command: ['objcopy', '-O', 'binary',
                                        '@INPUT@', '@OUTPUT@'],
                              input: boot_ext2_elf,
                              output: 'ext2.bin')
