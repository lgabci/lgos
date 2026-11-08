# LGOS doc CMake file

find_package(Doxygen)
if(DOXYGEN_FOUND)
  find_file(DOXYFILE
    NAMES doxygen.conf
    PATHS "${CMAKE_CURRENT_SOURCE_DIR}/../../doxygen"
    DOC "Find Doxygen config file."
  )

  if(DOXYFILE)
    get_filename_component(DOXYFILE_DIR ${DOXYFILE} DIRECTORY)

    file(GLOB_RECURSE ALL_SOURCE_FILES
      "${PROJECT_SOURCE_DIR}/src/*.c"
      "${PROJECT_SOURCE_DIR}/src/*.h"
      "${PROJECT_SOURCE_DIR}/src/*.S"
    )

    set(DOXYGEN_INDEX_FILE "${CMAKE_CURRENT_BINARY_DIR}/index.html")

    add_custom_command(
      OUTPUT "${DOXYGEN_INDEX_FILE}"
      COMMAND ${CMAKE_COMMAND} -E env
      PROJECT_NAME=${PROJECT_NAME}
      INPUT=${PROJECT_SOURCE_DIR}
      OUTPUT_DIRECTORY=${CMAKE_BINARY_DIR}
      "${DOXYGEN_EXECUTABLE}" "${DOXYFILE}"
      DEPENDS
      "${DOXYFILE}" ${ALL_SOURCE_FILES}
      WORKING_DIRECTORY ${DOXYFILE_DIR}
      VERBATIM
    )

    add_custom_target(doc DEPENDS "${DOXYGEN_INDEX_FILE}")
  else()
    message(WARNING "Doxygen config file not found.")
  endif()
else()
  message(STATUS "Doxygen not found, doc target did not created.")
endif()
