# LGOS loader meson file

loader = executable('main_loader.elf',
                    ['main_loader.s'],
                    link_depends: 'main_loader.ld',
                    c_args: ['-Wa,-I,' + meson.current_source_dir()],
                    link_args: ['-T', meson.current_source_dir() +
                                      '/main_loader.ld'],
                   )

loader_bin = custom_target('main_loader.bin',
                           output: 'main_loader.bin',
                           input: loader,
                           command: [objcopy, '-O', 'binary', '@INPUT@',
                                     '@OUTPUT@'],
                           build_by_default: true
                          )
