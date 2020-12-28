# See https://reproducible-builds.org/docs/source-date-epoch/
if (DEFINED ENV{SOURCE_DATE_EPOCH})
    add_definitions(-DLIBTHEMOVIEDB_COMPILATION_DATE=$ENV{SOURCE_DATE_EPOCH})
else ()
    if ("${CMAKE_VERSION}" VERSION_LESS "3.6.0")
        if (NOT MSVC)
            execute_process(COMMAND date "+%s"
                            OUTPUT_VARIABLE CURRENT_EPOCH
                            OUTPUT_STRIP_TRAILING_WHITESPACE)
        else ()
            message(FATAL_ERROR "Please upgrade CMake from ${CMAKE_VERSION} to 3.6.0 or above")
        endif ()
    else ()
        string(TIMESTAMP CURRENT_EPOCH "%s" UTC)
    endif ()
    add_definitions(-DLIBTHEMOVIEDB_COMPILATION_DATE=${CURRENT_EPOCH})
endif ()
