# LGOS doc CMake file

add_custom_command(OUTPUT index.html
  COMMAND mkdoc.sh
  DEPENDS mkdoc.sh
  COMMENT "Generating HTML code documentation ..."
)
