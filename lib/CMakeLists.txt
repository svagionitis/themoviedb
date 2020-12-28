project(libtmdb VERSION 0.0.1)

# A C compiler is absolutely needed
enable_language(C)

include(GenerateExportHeader)
include(library_version)
include(deterministic_builds)
include(library_functions)

add_subdirectory(include)
add_subdirectory(src)
if (ENABLE_TESTS)
    add_subdirectory(test/external/unity)
    add_subdirectory(test)
endif ()
