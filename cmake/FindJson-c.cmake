# FindJson-c
# ----------------
#
# Try to find the libjson-c library
#
# Once done this will define
#
#   JSON-C_FOUND - If false, do not try to use libjson-c
#   JSON-C_INCLUDE_DIRS - where to find json.h, etc.
#   JSON-C_LIBRARIES - the libraries to link against to use libjson-c
#   JSON-C_VERSION_MAJOR - the major version of libjson-c found
#   JSON-C_VERSION_MINOR - the minor version of libjson-c found
#   JSON-C_VERSION_PATCH - the patchlevel version of libjson-c found
#   JSON-C_VERSION_STRING - the version of libjson-c found in the format major.minor.patch

include(FindPkgConfig)
pkg_check_modules(_JSONC json-c QUIET)

if (WIN32)
    set(_x86 "(x86)")
    set(_JSON_C_WINDOWS_INC_PATHS "$ENV{ProgramFiles}/json-c-Win32/include"
                                  "$ENV{ProgramFiles} ${_x86}/json-c-Win32/include"
    )
    set(_JSON_C_WINDOWS_LIB_PATHS "$ENV{ProgramFiles}/json-c-Win32/lib"
                                  "$ENV{ProgramFiles} ${_x86}/json-c-Win32/lib"
    )
    unset(_x86)
endif ()

find_path(JSON-C_INCLUDE_DIR
    NAMES json.h
    HINTS ${_JSONC_INCLUDEDIR}
    PATH_SUFFIXES json-c
    PATHS ${_JSON_C_WINDOWS_INC_PATHS}
    )
find_library(JSON-C_LIBRARY
    NAMES json-c
    HINTS ${_JSONC_LIBDIR}
    PATHS ${_JSON_C_WINDOWS_LIB_PATHS}
    )

unset(_JSON_C_WINDOWS_INC_PATHS)
unset(_JSON_C_WINDOWS_LIB_PATHS)

if (JSON-C_INCLUDE_DIR AND EXISTS "${JSON-C_INCLUDE_DIR}/json_c_version.h")
    file(STRINGS "${JSON-C_INCLUDE_DIR}/json_c_version.h" JSONC_HEADER_CONTENTS REGEX ".*#define[ \t]+JSON_C_(MAJOR|MINOR|MICRO)_VERSION[ \t]+[0-9]+")

    string(REGEX REPLACE ".*#define[ \t]+JSON_C_MAJOR_VERSION[ \t]+([0-9]+).*" "\\1" JSON-C_VERSION_MAJOR "${JSONC_HEADER_CONTENTS}")
    string(REGEX REPLACE ".*#define[ \t]+JSON_C_MINOR_VERSION[ \t]+([0-9]+).*" "\\1" JSON-C_VERSION_MINOR "${JSONC_HEADER_CONTENTS}")
    string(REGEX REPLACE ".*#define[ \t]+JSON_C_MICRO_VERSION[ \t]+([0-9]+).*" "\\1" JSON-C_VERSION_PATCH "${JSONC_HEADER_CONTENTS}")

    set(JSON-C_VERSION_STRING "${JSON-C_VERSION_MAJOR}.${JSON-C_VERSION_MINOR}.${JSON-C_VERSION_PATCH}")
    unset(JSONC_HEADER_CONTENTS)
endif ()

# handle the QUIETLY and REQUIRED arguments and set Json-c_FOUND to TRUE if
# all listed variables are TRUE
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Json-c
                                  REQUIRED_VARS JSON-C_LIBRARY JSON-C_INCLUDE_DIR
                                  VERSION_VAR JSON-C_VERSION_STRING)

if (JSON-C_FOUND)
    # Compatibility for all the ways of writing these variables
    set(JSON-C_INCLUDE_DIRS ${JSON-C_INCLUDE_DIR})
    set(JSON-C_LIBRARIES ${JSON-C_LIBRARY})

    if (NOT TARGET Json-c::Json-c)
        add_library(Json-c::Json-c UNKNOWN IMPORTED)
        set_target_properties(Json-c::Json-c PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${JSON-C_INCLUDE_DIRS}"
            IMPORTED_LINK_INTERFACE_LANGUAGES "C"
            IMPORTED_LOCATION "${JSON-C_LIBRARIES}"
        )
    endif ()
endif ()

mark_as_advanced(JSON-C_INCLUDE_DIR JSON-C_LIBRARY)
