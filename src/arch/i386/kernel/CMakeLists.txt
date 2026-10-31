# i386 kernel CMake file

add_compile_options(-m32)

add_executable(kernel.elf
  init.S
)
target_link_options(kernel.elf PRIVATE
  -T ${CMAKE_CURRENT_SOURCE_DIR}/kernel.ld)
