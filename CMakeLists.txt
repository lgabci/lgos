cmake_minimum_required(VERSION 3.31)

if(DEFINED ENV{ARCH})
  set(ARCH $ENV{ARCH})
else()
  set(ARCH i386)
endif()

set(CMAKE_TOOLCHAIN_FILE
  ${CMAKE_CURRENT_SOURCE_DIR}/src/arch/${ARCH}/toolchain.cmake)

project(lgos
  LANGUAGES
  C ASM
)

add_compile_options("$<$<COMPILE_LANGUAGE:C>:-Wall -Wextra -pedantic -Werror
-ffreestanding -O3>")
add_compile_options($<$<COMPILE_LANGUAGE:ASM>:-Wa,--fatal-warnings>)

add_link_options(-ffreestanding -nostdlib -nostdinc -Wl,--fatal-warnings)

add_subdirectory(src/arch/${ARCH})
