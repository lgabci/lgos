# i386 emulator CMake file

if(!${CMAKE_READELF})
  message(FATAL_ERROR "No readelf found.")
endif()

set(sector_size 512)

set(img_hdd_ext2 "hdd_ext2.img")
set(img_hdd_fat "hdd_fat.img")

add_custom_command(
  OUTPUT ${img_hdd_ext2}
  COMMAND "${CMAKE_CURRENT_SOURCE_DIR}/mkimg.sh"
  ${img_hdd_ext2} Ext2 $<TARGET_FILE:mbr.elf> $<TARGET_FILE:ext2.elf>
  DEPENDS mkimg.sh mbr.elf ext2.elf
  COMMENT "Create HDD Ext2 image file ..."
)

add_custom_command(
  OUTPUT ${img_hdd_fat}
  COMMAND "${CMAKE_CURRENT_SOURCE_DIR}/mkimg.sh"
  ${img_hdd_fat} FAT $<TARGET_FILE:mbr.elf> $<TARGET_FILE:fat.elf>
  DEPENDS mkimg.sh mbr.elf fat.elf
  COMMENT "Create HDD FAT image file ..."
)

add_custom_target(emu_hd_ext2
  COMMAND "${CMAKE_CURRENT_SOURCE_DIR}/emu.sh" "hd" ${img_hdd_ext2}
  DEPENDS ${img_hdd_ext2}
  COMMENT "Running emulator on HDD Ext2 image ..."
)

add_custom_target(emu_hd_fat ALL
  COMMAND "${CMAKE_CURRENT_SOURCE_DIR}/emu.sh" "hd" ${img_hdd_fat}
  DEPENDS ${img_hdd_fat}
  COMMENT "Running emulator on HDD FAT image ..."
)
