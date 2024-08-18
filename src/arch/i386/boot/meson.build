# LGOS i386/boot meson.build file

boot_mbr_elf = executable('mbr.elf',
                          ['init.S', 'mbr.S', 'video.S'],
                          link_args: ['-T',
                                      meson.current_source_dir() + '/mbr.ld'],
                          link_depends: 'mbr.ld',
                          build_by_default: true)

boot_mbr_bin = custom_target('mbr.bin',
                             build_by_default: true,
                             command: ['objcopy', '-O', 'binary',
                                       '@INPUT@', '@OUTPUT@'],
                             input: boot_mbr_elf,
                             output: 'mbr.bin')
