# LGOS i386/loader meson.build file

loader_elf = executable('loader.elf',
                        ['init.S'],
                        link_args: ['-T',
                                    meson.current_source_dir() + '/loader.ld'],
                        link_depends: 'loader.ld')

loader_bin = custom_target('loader.bin',
                           command: ['objcopy', '-O', 'binary',
                                     '@INPUT@', '@OUTPUT@'],
                           input: loader_elf,
                           output: 'loader.bin')
