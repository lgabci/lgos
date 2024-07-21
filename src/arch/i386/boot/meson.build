# LGOS i386/boot meson.build file

boot_mbr_elf = executable('mbr.bin',
                          ['init.S'],
                          link_args: ['-T',
                                      meson.current_source_dir() + '/mbr.ld'],
                          link_depends: 'mbr.ld',
                          build_by_default: true)
