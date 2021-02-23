# LGOS bootblock meson file

mbr = executable('main_mbr.elf',
                 ['main_mbr.s', 'common.s', 'video.s', 'disk.s'],
                 link_depends: 'main_mbr.ld',
                 c_args: ['-Wa,-I,' + meson.current_source_dir()],
                 link_args: ['-T', meson.current_source_dir() +
                                   '/main_mbr.ld'],
                )
