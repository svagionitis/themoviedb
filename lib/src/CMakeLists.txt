include(compiler_options)

set(CURL_MINIMUM_VERSION "7.35.0")
set(JSON_C_MINIMUM_VERSION "0.11.99")

find_package(CURL ${CURL_MINIMUM_VERSION} REQUIRED)
find_package(Json-c ${JSON_C_MINIMUM_VERSION} REQUIRED)

set(CMAKE_C_VISIBILITY_PRESET hidden)
set(CMAKE_CXX_VISIBILITY_PRESET hidden)

include_directories(${CMAKE_SOURCE_DIR}/lib/include)

set(ATOMIC_TEST_C_SOURCE "
#include <stdatomic.h>
#include <stdint.h>
atomic_uint_fast64_t x;
atomic_uint_fast64_t y;
int main() {
    return (int)(x + y);
}")

include(GNUInstallDirs)
set(TMDB_INSTALL_INCLUDEDIR ${CMAKE_INSTALL_INCLUDEDIR}/tmdb)

# libatomic check - some arches need to link against libatomic.so, some don't
include(CheckCSourceCompiles)
include(CMakePushCheckState)
include(CheckLibraryExists)
cmake_push_check_state()
check_c_source_compiles("${ATOMIC_TEST_C_SOURCE}" HAVE_ATOMICS_WITHOUT_LIBATOMIC)
if(NOT HAVE_ATOMICS_WITHOUT_LIBATOMIC)
    check_library_exists(atomic __atomic_load_8 "" LIBATOMIC_EXISTS)
    if(LIBATOMIC_EXISTS)
        set(CMAKE_REQUIRED_LIBRARIES atomic)
        check_c_source_compiles("${ATOMIC_TEST_C_SOURCE}" HAVE_ATOMICS_WITH_LIBATOMIC)
    endif()
    if(HAVE_ATOMICS_WITH_LIBATOMIC)
        list(APPEND EXTRA_LIBRARIES atomic)
    else()
        message(FATAL_ERROR "Could not determine support for atomic operations.")
    endif()
endif()
cmake_pop_check_state()


# libtmdb.so
set(TARGET tmdb)

set(TMDB_SRC
    tmdb_api.c
    )

add_library(${TARGET} SHARED ${TMDB_SRC})
set_library_properties(${TARGET})
# compile definitions
set_property(TARGET ${TARGET} APPEND PROPERTY
             COMPILE_DEFINITIONS LOCALSTATEDIR=\"${CMAKE_INSTALL_FULL_LOCALSTATEDIR}/lib/${PROJECT_NAME}\"
             COMPILE_DEFINITIONS SYSCONFDIR=\"${CMAKE_INSTALL_FULL_SYSCONFDIR}\")

generate_export_header(${TARGET}
    EXPORT_MACRO_NAME TMDB_API
    NO_EXPORT_MACRO_NAME TMDB_NOAPI
    EXPORT_FILE_NAME ${TARGET}-visibility.h)
target_include_directories(${TARGET} PRIVATE ${CMAKE_CURRENT_BINARY_DIR}
                                             ${CURL_INCLUDE_DIRS}
                                             ${LIBGLIB_INCLUDE_DIRS}
                                     INTERFACE ${CMAKE_CURRENT_BINARY_DIR}
                                               ${CMAKE_SOURCE_DIR}/lib/include)
target_link_libraries(${TARGET} PRIVATE ${CURL_LIBRARIES}
                                        ${JSON-C_LIBRARIES}
                                        ${EXTRA_LIBRARIES}
                    )
install(TARGETS ${TARGET}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    COMPONENT libs
    NAMELINK_SKIP
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    COMPONENT dev
    PUBLIC_HEADER DESTINATION ${TMDB_INSTALL_INCLUDEDIR}
    PRIVATE_HEADER DESTINATION ${TMDB_INSTALL_INCLUDEDIR}
    COMPONENT dev
    )

if (${CMAKE_SYSTEM_NAME} MATCHES "Windows")
    # Install the dll as well for windows as
    # a runtime dependency
    install(TARGETS ${TARGET}
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        NAMELINK_SKIP
        RUNTIME DESTINATION ${CMAKE_INSTALL_LIBDIR}
        COMPONENT runtime_dependencies
        )

    find_runtime_dependency_libraries()

    # Install the runtime dependencies
    install(FILES
        ${RUNTIME_DEPENDENCY_LIBRARIES}
        DESTINATION ${CMAKE_INSTALL_LIBDIR}
        COMPONENT runtime_dependencies
        )

    # Copy the library dll where is needed for run-time
    add_custom_command (TARGET ${TARGET} POST_BUILD
                        COMMAND ${CMAKE_COMMAND} -E make_directory
                        "${CMAKE_BINARY_DIR}/integration-tests/$<1:$(Configuration)>/"
                        COMMAND ${CMAKE_COMMAND} -E copy
                        "${CMAKE_BINARY_DIR}/src/$<1:$(Configuration)>/${TARGET}.dll"
                        "${CMAKE_BINARY_DIR}/integration-tests/$<1:$(Configuration)>/"
                        DEPENDS "${CMAKE_BINARY_DIR}/src/$<1:$(Configuration)>/${TARGET}.dll"
                        COMMAND ${CMAKE_COMMAND} -E make_directory
                        "${CMAKE_BINARY_DIR}/examples/$<1:$(Configuration)>/"
                        COMMAND ${CMAKE_COMMAND} -E copy
                        "${CMAKE_BINARY_DIR}/src/$<1:$(Configuration)>/${TARGET}.dll"
                        "${CMAKE_BINARY_DIR}/examples/$<1:$(Configuration)>/"
                        DEPENDS "${CMAKE_BINARY_DIR}/src/$<1:$(Configuration)>/${TARGET}.dll")

endif ()
install(TARGETS ${TARGET}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    NAMELINK_ONLY
    COMPONENT dev
    )
install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}-visibility.h
    DESTINATION ${TMDB_INSTALL_INCLUDEDIR}
    COMPONENT dev
    )

# libtmdb.pc
if (${CMAKE_SYSTEM_NAME} MATCHES "Linux")
    get_target_property(LIBRARY_NAME tmdb NAME)
    # We can't use get_target_property(PRIVATE_LIBS tmdb LINK_LIBRARIES)
    # here to get the list of link libraries as that returns the list
    # in CMake's format, including full paths etc., so we have to hard-code
    set(PRIVATE_REQUIRES "libcurl >= ${CURL_MINIMUM_VERSION} json-c >= ${LIBJSON_C_MINIMUM_VERSION}")
    configure_file("libtmdb.pc.in" "libtmdb.pc" @ONLY)
    # create a pkg-config file
    install(FILES
        ${CMAKE_CURRENT_BINARY_DIR}/libtmdb.pc
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig
        COMPONENT dev
        )
    unset(PRIVATE_LIBS)
    unset(LIBRARY_NAME)
endif ()

set(CPACK_PACKAGE_CONTACT "Contact Details")
set(CPACK_PACKAGE_VENDOR "Vendor Name")
set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}-1")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Libtmdb - An unofficial REST API consumer")
set(CPACK_PACKAGE_DESCRIPTION_FILE "${CMAKE_SOURCE_DIR}/README")
file(READ "${CPACK_PACKAGE_DESCRIPTION_FILE}" FULL_PACKAGE_DESCRIPTION)
set(CPACK_COMPONENT_libs_DESCRIPTION "${CPACK_PACKAGE_DESCRIPTION_SUMMARY} - client library\n ${FULL_PACKAGE_DESCRIPTION}")
set(CPACK_COMPONENT_dev_DESCRIPTION "${CPACK_PACKAGE_DESCRIPTION_SUMMARY} - development files\n ${FULL_PACKAGE_DESCRIPTION}")
if (${CMAKE_SYSTEM_NAME} MATCHES "Linux")
    set(CPACK_GENERATOR "DEB")

    get_target_property(LIBRARY_NAME tmdb NAME)
    find_program(DPKG_CMD dpkg)
    if(NOT DPKG_CMD)
      message(STATUS "Can not find dpkg in your path, default to i386.")
      set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE i386)
    endif()
    execute_process(COMMAND "${DPKG_CMD}" --print-architecture
      OUTPUT_VARIABLE CPACK_DEBIAN_PACKAGE_ARCHITECTURE
      OUTPUT_STRIP_TRAILING_WHITESPACE
      )

    set(CPACK_PACKAGE_NAME "lib${LIBRARY_NAME}")
    set(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}_${CPACK_PACKAGE_VERSION}_${CPACK_DEBIAN_PACKAGE_ARCHITECTURE}")
    set(CPACK_DEBIAN_PACKAGE_SECTION "libs")

    set(CPACK_DEB_COMPONENT_INSTALL ON)
    set(CPACK_DEBIAN_LIBS_PACKAGE_SHLIBDEPS ON)
    set(CPACK_DEBIAN_LIBS_PACKAGE_SECTION "libs")
    set(CPACK_DEBIAN_DEV_PACKAGE_DEPENDS "${CPACK_PACKAGE_NAME}-libs (<< ${CPACK_PACKAGE_VERSION}.1~), ${CPACK_PACKAGE_NAME}-libs (>= ${CPACK_PACKAGE_VERSION})")
    set(CPACK_DEBIAN_DEV_PACKAGE_SECTION "libdevel")
    # the deb generator expects a different name...
    set(CPACK_COMPONENT_LIBS_DESCRIPTION "${CPACK_COMPONENT_libs_DESCRIPTION}")
    set(CPACK_COMPONENT_DEV_DESCRIPTION "${CPACK_COMPONENT_dev_DESCRIPTION}")
elseif (${CMAKE_SYSTEM_NAME} MATCHES "Windows")
    # - Packaging using NSIS, see https://cmake.org/Wiki/CMake:CPackPackageGenerators#NSIS and
    #   https://cmake.org/Wiki/CMake:Component_Install_With_CPack
    #   License: Attribution 2.5 Generic
    #   Author : CMAKE
    set(CPACK_GENERATOR "NSIS")

    set(CPACK_PACKAGE_INSTALL_DIRECTORY "libtmdb")

    # Ask about uninstalling previous versions first
    set(CPACK_NSIS_ENABLE_UNINSTALL_BEFORE_INSTALL ON)

    get_target_property(LIBRARY_NAME tmdb NAME)
    set(CPACK_PACKAGE_NAME "${LIBRARY_NAME}")

    # Tell CPack all of the components to install. The "ALL"
    # refers to the fact that this is the set of components that
    # will be included when CPack is instructed to put everything
    # into the binary installer (the default behavior).
    set(CPACK_COMPONENTS_ALL libs dev runtime_dependencies)

    set(CPACK_COMPONENT_DEV_DISPLAY_NAME "Development files")
    set(CPACK_COMPONENT_DEV_DESCRIPTION "The necessary files needed for development which includes the header files and the library file.")
    set(CPACK_COMPONENT_RUNTIME_DEPENDENCIES_DISPLAY_NAME "Runtime dependencies files")
    set(CPACK_COMPONENT_RUNTIME_DEPENDENCIES_DESCRIPTION "The dependencies needed to run a libtmdb application.")

    # It doesn't make sense to install the headers without the libraries
    # (because you could never use the headers!), so make the headers component
    # depend on the libraries component.
    set(CPACK_COMPONENT_dev_DEPENDS libs)
elseif (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
endif ()
unset(FULL_PACKAGE_DESCRIPTION)
Include(CPack)
