# i386 emulator CMake file

set(img_hdd "hdd.img")

add_custom_command(
  OUTPUT ${img_hdd}
  COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/mkimg.sh
  ARGS ${img_hdd} $<TARGET_FILE:mbr.elf>
  DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/mkimg.sh $<TARGET_FILE:mbr.elf>
  COMMENT "Creating emulator HD image file ..."
)

add_custom_target(emu_hd ALL
  COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/emu.sh "hd" ${img_hdd}
  DEPENDS ${img_hdd}
  COMMENT "Running emulator HD ..."
)
