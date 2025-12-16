# LGOS main meson.build file

project('lgos',
        'c',
        default_options: ['buildtype=release',
                          'warning_level=everything',
                          'werror=true',
                          'b_asneeded=false'],
        meson_version: '>=1.7.0',
        version: files('lgos_version.txt'))

compiler = meson.get_compiler('c')
compiler_args = compiler.get_supported_arguments(['-pedantic',
                                                  '-ffreestanding',
                                                  '-Wa,--fatal-warnings'],
                                                 checked: 'require')

if not compiler.has_multi_link_arguments(['-nostdlib', '--entry=main'])
  error('Compiler for C does not support "-nostdlib"')
endif

if not compiler.has_link_argument('-Wl,--fatal-warnings')
  error('Compiler for C does not support "-Wl,--fatal-warnings"')
endif

add_project_arguments(compiler_args,
                      language: 'c')

add_project_link_arguments(['-nostdlib',
                            '-Wl,--fatal-warnings'],
                           language: 'c')

arch = host_machine.cpu()
subdir('src' / 'arch' / arch)
subdir('doc')
