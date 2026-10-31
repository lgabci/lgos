# i386 emulator CMake file

add_custom_command(
  OUTPUT a.txt
  COMMAND echo alma >a.txt
  COMMENT "Creating emulator image file ..."
)

add_custom_target(generate_emu_files ALL DEPENDS a.txt)
