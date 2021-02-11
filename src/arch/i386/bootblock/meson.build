# LGOS bootblock meson file

mbr = executable('mbr.elf',
                 ['mbr.s', 'video.s'],
                 link_depends: ['mbr.ld'],
                 c_args: ['-Wa,-I,' + meson.current_source_dir()],
                 link_args: ['-T', meson.current_source_dir() + '/mbr.ld']
                )

mbr_bin = custom_target('mbr.bin',
                        output: 'mbr.bin',
                        input: mbr,
                        command: [objcopy, '-O', 'binary', '@INPUT@',
                                  '@OUTPUT@'],
                        build_by_default: true
                       )
