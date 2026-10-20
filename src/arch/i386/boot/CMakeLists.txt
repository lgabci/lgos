# i386 boot CMake file

add_compile_options(-m16)

# common obj files
add_library(common_lib
  OBJECT
  misc.S
  disk.S
  video.S
)

# MBR
add_library(mbr_init_lib OBJECT init.S)
target_compile_definitions(mbr_init_lib PRIVATE BS_TARGET=0)

add_executable(mbr.elf
  $<TARGET_OBJECTS:mbr_init_lib>
  mbr.S
  $<TARGET_OBJECTS:common_lib>
)
target_link_options(mbr.elf PRIVATE -T ${CMAKE_CURRENT_SOURCE_DIR}/mbr.ld)

# FAT boot sector
add_library(fat_init_lib OBJECT init.S)
target_compile_definitions(fat_init_lib PRIVATE BS_TARGET=1)

add_executable(fat.elf
  $<TARGET_OBJECTS:fat_init_lib>
  fat.S
  $<TARGET_OBJECTS:common_lib>
)
target_link_options(fat.elf PRIVATE -T ${CMAKE_CURRENT_SOURCE_DIR}/fat.ld)

# Ext2 boot sector
add_library(ext2_init_lib OBJECT init.S)
target_compile_definitions(ext2_init_lib PRIVATE BS_TARGET=2)

add_executable(ext2.elf
  $<TARGET_OBJECTS:ext2_init_lib>
  ext2.S
  $<TARGET_OBJECTS:common_lib>
)
target_link_options(ext2.elf PRIVATE -T ${CMAKE_CURRENT_SOURCE_DIR}/ext2.ld)
