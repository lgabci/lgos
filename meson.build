# LGOS top meson file

project('lgos',
        'c',
        license: 'MIT',
        meson_version: '>=0.49.2',
        version: '0.0.1'
       )

assert(meson.is_cross_build(), 'Only cross builds enabled!')

objcopy = find_program('objcopy')

add_project_arguments(['-pedantic', '-Werror', '-Wall', '-Wextra',
                       '-Wa,--fatal-warnings'],
                      language: 'c'
                     )

add_project_link_arguments(['-Wl,--fatal-warnings'],
                           language: 'c'
                          )

subdir('src')
subdir('emu')
