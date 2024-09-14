# LGOS i386/boot meson.build file

boot_mbr_elf = executable('mbr.elf',
                          ['init.S', 'mbr.S', 'video.S', 'disk.S', 'misc.S'],
                          link_args: ['-T',
                                      meson.current_source_dir() + '/mbr.ld'],
                          link_depends: 'mbr.ld')

boot_mbr_bin = custom_target('mbr.bin',
                             command: ['objcopy', '-O', 'binary',
                                       '@INPUT@', '@OUTPUT@'],
                             input: boot_mbr_elf,
                             output: 'mbr.bin')
