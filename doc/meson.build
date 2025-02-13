# LGOS i386/loader meson.build file

doxygen = find_program('doxygen')
fs = import('fs')

flist = run_command('find',
                    meson.project_source_root() /
                      'src', '-name', '*.[chS]',
                    capture: true,
                    check:true)
all_srcs = flist.stdout().strip().split('\n')

doc = custom_target('doc',
                    command: [doxygen,
                              fs.parent(meson.project_source_root()) /
                                'doxygen' / 'doxygen.conf'],
                    env: ['DOXY_ROOT=' +
                            fs.parent(meson.project_source_root()) /
                            'doxygen',
                          'PROJECT_NAME=' + meson.project_name(),
                          'INPUT=' + meson.project_source_root(),
                          'OUTPUT_DIRECTORY=' +
                            fs.parent(meson.current_build_dir())],
                    input: all_srcs,
                    output: 'index.html')
