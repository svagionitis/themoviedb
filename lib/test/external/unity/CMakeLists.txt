project(unity)

find_path(UNITY_SRC_LOCATION
    NAMES src/unity.c
    HINTS ENV UNITY_SRC_ROOT
    PATHS "/usr/src/unity"
    NO_DEFAULT_PATH
    )

if (UNITY_SRC_LOCATION)
    set(UNITY_GIT_REPOSITORY "" CACHE INTERNAL "unity git repository")
    set(UNITY_GIT_TAG        "" CACHE INTERNAL "unity git tag")
else ()
    set(UNITY_GIT_REPOSITORY "https://github.com/ThrowTheSwitch/Unity.git" CACHE INTERNAL "unity git repository")
    set(UNITY_GIT_TAG        "master" CACHE INTERNAL "unity git tag")
    set(UNITY_SRC_LOCATION "${CMAKE_CURRENT_BINARY_DIR}/unity-src" CACHE INTERNAL "unity source location")
endif ()

configure_file(CMakeLists.txt.in unity-download/CMakeLists.txt)
execute_process(COMMAND ${CMAKE_COMMAND} -G "${CMAKE_GENERATOR}" .
  RESULT_VARIABLE result
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/unity-download )
if(result)
  message(FATAL_ERROR "CMake step for unity failed: ${result}")
endif()
execute_process(COMMAND ${CMAKE_COMMAND} --build .
  RESULT_VARIABLE result
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/unity-download )
if(result)
  message(FATAL_ERROR "Build step for unity failed: ${result}")
endif()

# Add Unity directly to our build. This defines the unity targets.
add_subdirectory(${UNITY_SRC_LOCATION}
                 ${CMAKE_CURRENT_BINARY_DIR}/unity-build
                 EXCLUDE_FROM_ALL)

# The unity targets carry header search path
# dependencies automatically when using CMake 2.8.11 or
# later. Otherwise we have to add them here ourselves.
if (CMAKE_VERSION VERSION_LESS 2.8.11)
  include_directories("${unity_SOURCE_DIR}/include")
endif()
