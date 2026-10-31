# i386 loader CMake file

add_compile_options(-m16)

add_executable(loader.elf
  init.S
)
target_link_options(loader.elf PRIVATE -T ${CMAKE_CURRENT_SOURCE_DIR}/loader.ld)
