# LGOS i386 meson file

add_project_arguments(['-ffreestanding', '-O2', '-std=gnu99'],
                      language: 'c'
                     )

add_project_link_arguments(['-nostdlib', '-lgcc'],
                           language: 'c'
                          )

subdir('bootblock')
