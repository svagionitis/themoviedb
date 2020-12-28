# useful function(s)
include (CheckIncludeFiles)

function(set_library_properties library)
  # Set properties that are normally required

  # Sanity check that needed variables have been assigned values.
  # (Note that ${library}_SOVERSION and ${library}_VERSION should be
  # assigned values in cmake/modules/plplot_version.cmake and LIB_DIR
  # should be assigned a value in cmake/modules/instdirs.cmake.)
  if (NOT(${library}_SOVERSION OR ${library}_VERSION))
    message(STATUS "${library}_SOVERSION: ${${library}_SOVERSION}")
    message(STATUS "${library}_VERSION: ${${library}_VERSION}")
    message(STATUS "LIB_DIR = ${LIB_DIR}")
    message(FATAL_ERROR "${library}_SOVERSION and/or ${library}_VERSION is not defined")
  endif ()

  set_target_properties(
    ${library}
    PROPERTIES
    SOVERSION ${${library}_SOVERSION}
    VERSION ${${library}_VERSION}
    POSITION_INDEPENDENT_CODE ON
    )
endfunction(set_library_properties library)
