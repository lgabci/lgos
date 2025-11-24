# LGOS i386/boot meson.build file

boot_mbr_elf = executable('mbr.elf',
                          ['init.S', 'mbr.S', 'video.S', 'disk.S', 'misc.S'],
                          c_args: ['-Wa,--defsym,MBR=1'],
                          link_args: ['-T',
                                      meson.current_source_dir() + '/mbr.ld'],
                          link_depends: 'mbr.ld')

boot_fat_elf = executable('fat.elf',
                          ['init.S', 'load.S', 'video.S', 'disk.S', 'misc.S'],
                          c_args: ['-Wa,--defsym,FAT=1'],
                          link_args: ['-T',
                                      meson.current_source_dir() + '/fat.ld'],
                          link_depends: 'fat.ld')

boot_ext2_elf = executable('ext2.elf',
                           ['init.S', 'load.S', 'video.S', 'disk.S', 'misc.S'],
                           c_args: ['-Wa,--defsym,EXT2=1'],
                           link_args: ['-T',
                                       meson.current_source_dir() + '/ext2.ld'],
                           link_depends: 'ext2.ld')
