# LGOS bootblock meson file

mbr = executable('main_mbr.elf',
                 ['main_mbr.s', 'common.s', 'video.s'],
                 link_depends: 'main_mbr.ld',
                 c_args: ['-Wa,-I,' + meson.current_source_dir()],
                 link_args: ['-T', meson.current_source_dir() +
                                   '/main_mbr.ld'],
                )

mbr_bin = custom_target('main_mbr.bin',
                        output: 'main_mbr.bin',
                        input: mbr,
                        command: [objcopy, '-O', 'binary', '@INPUT@',
                                  '@OUTPUT@'],
                        build_by_default: true
                       )
