# emulator meson file

emuimg = find_program('emuimg.sh')
emu = find_program('emu.sh')

hddfat_img = custom_target('hddfat.img',
                           output: 'hddfat.img',
                           input: [mbr_elf, fat_elf, loader_bin],
                           command: [emuimg, '@OUTPUT@', '@INPUT@',
                                     '@CURRENT_SOURCE_DIR@']
                          )

emu = run_target('emu',
                 command: [emu, hddfat_img]
                )
