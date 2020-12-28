# Global compiler options (C standard used)
if ("${CMAKE_VERSION}" VERSION_LESS "3.1.0")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=gnu11")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
else ()
    set(CMAKE_C_STANDARD 11)
    set(CMAKE_C_STANDARD_REQUIRED on)
    set(CMAKE_C_EXTENSIONS on)

    set(CMAKE_CXX_STANDARD 11)
    set(CMAKE_CXX_STANDARD_REQUIRED on)
    set(CMAKE_CXX_EXTENSIONS off)
endif ()

# Global compiler options (static analysis)
include (CheckCCompilerFlag)
set(CMAKE_C_FLAGS_analysis "")
set(CMAKE_C_ONLY_FLAGS_analysis "")
if (CMAKE_C_COMPILER_ID STREQUAL "GNU" OR CMAKE_C_COMPILER_ID STREQUAL "Clang")
    set(CMAKE_C_FLAGS_analysis "-Werror -Wall -Wextra")
    set(CMAKE_C_FLAGS_analysis "${CMAKE_C_FLAGS_analysis} -Wformat=2")
    set(CMAKE_C_FLAGS_analysis "${CMAKE_C_FLAGS_analysis} -Wswitch-default -Wswitch-enum")
    if (CMAKE_C_COMPILER_ID STREQUAL "GNU")
        # Clang doesn't understand these
        set(CMAKE_C_FLAGS_analysis "${CMAKE_C_FLAGS_analysis} -Wsuggest-attribute=pure -Wsuggest-attribute=const -Wsuggest-attribute=noreturn -Wsuggest-attribute=format")
        set(CMAKE_C_FLAGS_analysis "${CMAKE_C_FLAGS_analysis} -Wtrampolines")
    endif ()
    set(CMAKE_C_FLAGS_analysis "${CMAKE_C_FLAGS_analysis} -Wconversion -Wcast-align -fno-common")
    set(CMAKE_C_FLAGS_analysis "${CMAKE_C_FLAGS_analysis} -Wcast-qual")
    set(CMAKE_C_FLAGS_analysis "${CMAKE_C_FLAGS_analysis} -Wmissing-declarations")
    set(CMAKE_C_FLAGS_analysis "${CMAKE_C_FLAGS_analysis} -Wpointer-arith")
    set(CMAKE_C_FLAGS_analysis "${CMAKE_C_FLAGS_analysis} -Wshadow")
    set(CMAKE_C_FLAGS_analysis "${CMAKE_C_FLAGS_analysis} -Wwrite-strings")
    # compiler flags not valid for C++
    set(CMAKE_C_ONLY_FLAGS_analysis "${CMAKE_C_ONLY_FLAGS_analysis} -Wdeclaration-after-statement")
    set(CMAKE_C_ONLY_FLAGS_analysis "${CMAKE_C_ONLY_FLAGS_analysis} -Wmissing-prototypes")
    set(CMAKE_C_ONLY_FLAGS_analysis "${CMAKE_C_ONLY_FLAGS_analysis} -Wstrict-prototypes")
    check_c_compiler_flag("-Wdocumentation" _WDOCUMENTATION)
    if (_WDOCUMENTATION)
        set(CMAKE_C_FLAGS_analysis "${CMAKE_C_FLAGS_analysis} -Wdocumentation")
    endif ()
    check_c_compiler_flag("-Wduplicated-cond" _WDUPLICATED_COND)
    if (_WDUPLICATED_COND)
        set(CMAKE_C_FLAGS_analysis "${CMAKE_C_FLAGS_analysis} -Wduplicated-cond")
    else ()
        if (CMAKE_C_COMPILER_ID STREQUAL "GNU")
            set(COMPILER_TOO_OLD 1)
        endif ()
    endif ()
    check_c_compiler_flag("-Wnull-dereference" _WNULL_DEREFERENCE)
    if (_WNULL_DEREFERENCE)
        set(CMAKE_C_FLAGS_analysis "${CMAKE_C_FLAGS_analysis} -Wnull-dereference")
    else ()
        if (CMAKE_C_COMPILER_ID STREQUAL "GNU")
            set(COMPILER_TOO_OLD 1)
        endif ()
    endif ()
    unset (_WDOCUMENTATION)
    unset (_WDUPLICATED_COND)
    unset (_WNULL_DEREFERENCE)
elseif (MSVC)
    # A variable to enable/disable inline functionality of stdio functions.
    set(NO_CRT_STDIO_INLINE OFF)

    # The structure timespec is defined in pthread.h. We need to define
    # the HAVE_STRUCT_TIMESPEC in order not to use that one
    set(CMAKE_C_FLAGS_analysis "/W4 /Wall /GS /analyze -DHAVE_STRUCT_TIMESPEC")

    # Fixes issue of macro redefinition because of incompatibility between
    # winsock.h and WinSock2.h. This usually occurs when something has included
    # Windows.h (which includes winsock.h) before WinSock2.h
    set(CMAKE_C_FLAGS_analysis "${CMAKE_C_FLAGS_analysis} -DWIN32_LEAN_AND_MEAN")

    # Include function typedefs for WinSock API. Fixes the following warnings
    # warning C4574: 'INCL_WINSOCK_API_TYPEDEFS' is defined to be '0'
    set(CMAKE_C_FLAGS_analysis "${CMAKE_C_FLAGS_analysis} -DINCL_WINSOCK_API_TYPEDEFS=1")

    # In the latest version of MSVC 1900 the stdio functions are defined
    # as inline which causes warning C4710 that the stdio functions are
    # not inlined. To disable these warnings, we disable the inline definition
    # of those functions.
    if (MSVC_VERSION EQUAL 1900)
        set(CMAKE_C_FLAGS_analysis "${CMAKE_C_FLAGS_analysis} -D_NO_CRT_STDIO_INLINE")
        set(NO_CRT_STDIO_INLINE ON)
    endif()
endif ()
# debug flags / options
set(SANITIZER "address" CACHE STRING "Sanitizer to use in debug builds (address | thread) (default: address)")
if (CMAKE_C_COMPILER_ID STREQUAL "GNU" OR CMAKE_C_COMPILER_ID STREQUAL "Clang")
    # No optimisation (-O0 or not specified) doesn't generate any warnings when
    # using gcc, which is cmake's default, so set a minimum level.
    # Also, -g3 -ggdb3 includes more debug info than the standard -g, which
    # corresponds to -g2. This adds specific gdb extensions, and level 3 adds
    # macro definitions.
    # https://cmake.org/cmake/help/v3.4/variable/CMAKE_LANG_COMPILER_ID.html
    if (CMAKE_C_COMPILER_ID STREQUAL "GNU")
        set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -Og")
    elseif (CMAKE_C_COMPILER_ID STREQUAL "Clang")
        # Clang doesn't support -Og
        set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -O1")
    endif ()
    set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -g3 -ggdb")

    if (CMAKE_C_COMPILER_ID STREQUAL "GNU" AND CMAKE_CXX_COMPILER_VERSION VERSION_LESS "4.9")
        set(COMPILER_IS_TOO_OLD 1)
    elseif (CMAKE_C_COMPILER_ID STREQUAL "Clang")
        # https://clang.llvm.org/docs/AddressSanitizer.html
        # https://clang.llvm.org/docs/MemorySanitizer.html
        #     When linking shared libraries, the AddressSanitizer run-time
        #     is not linked, so -Wl,-z,defs may cause link errors (don’t
        #     use it with AddressSanitizer).
        # We need to disable --no-undefined for debug builds, and we need
        # to make sure that all binaries are linked with the sanitizers, too.
        message(AUTHOR_WARNING "Sanitizers are disabled when using clang, please fix!")
    else ()
        include(CMakePushCheckState)
        foreach (_san IN ITEMS "${SANITIZER}" "leak" "undefined")
            cmake_push_check_state()
            # need to add -Werror, as CMake doesn't treat the warning
            #     cc1: warning: -fsanitize=address and -fsanitize=kernel-address are not supported for this target
            #     cc1: warning: -fsanitize=address not supported for this target
            # in its regex search in CMakeCheckCompilerFlagCommonPatterns.cmake
            list(APPEND CMAKE_REQUIRED_FLAGS "-Werror -fsanitize=${_san}")
            check_c_source_compiles("int main(int argc, char *argv[]) { return 0; }" _FSANITIZE_${_san})
            if (_FSANITIZE_${_san})
                set(FSANITIZE_FLAGS "${FSANITIZE_FLAGS} -fsanitize=${_san}")
            endif ()
            cmake_pop_check_state()
        endforeach ()
    endif ()
endif ()

# See https://www.owasp.org/index.php/C-Based_Toolchain_Hardening
#     https://fedoraproject.org/wiki/Security_Features?rd=Security/Features
#     https://wiki.debian.org/Hardening
#     https://wiki.debian.org/HardeningWalkthrough
#     https://wiki.debian.org/ReleaseGoals/SecurityHardeningBuildFlags
option(FORTIFY_SOURCES "Option to build with various fortification flags" ON)
option(FORTIFY_SOURCES_NO_DLOPEN "dlopen() cannot be used on the library (only respected if FORTIFY_SOURCES is ON)" OFF)
set(CMAKE_C_FLAGS_fortify "")
if (FORTIFY_SOURCES)
    if (CMAKE_C_COMPILER_ID STREQUAL "GNU" OR CMAKE_C_COMPILER_ID STREQUAL "Clang")
        # dpkg-buildflags --get CPPFLAGS
        check_c_compiler_flag("-Wdate-time" _WDATE_TIME)
        if (_WDATE_TIME)
            set(CMAKE_C_FLAGS_fortify "-Wdate-time")
        else ()
            set(COMPILER_TOO_OLD 1)
        endif ()
        unset (_WDATE_TIME)
        add_definitions(-D_FORTIFY_SOURCE=2)
        # dpkg-buildflags --get CFLAGS
        check_c_compiler_flag("-fstack-protector-strong" _FSTACK_PROTECTOR_STRONG)
        if (_FSTACK_PROTECTOR_STRONG)
            set(CMAKE_C_FLAGS_fortify "${CMAKE_C_FLAGS_fortify} -fstack-protector-strong")
        else ()
            set(CMAKE_C_FLAGS_fortify "${CMAKE_C_FLAGS_fortify} -fstack-protector --param=ssp-buffer-size=4")
        endif ()
        unset(_FSTACK_PROTECTOR_STRONG)
        # dpkg-buildflags --get LDFLAGS
        set(library_link_flags "-Wl,-z,relro")
        # additional recommended flags
        set(library_link_flags "${library_link_flags} -Wl,-z,noexecstack -Wl,-z,noexecheap -Wl,-z,now")
        set(library_link_flags "${library_link_flags} -Wl,-z,nodump")
        set(library_link_flags "${library_link_flags} -Wl,--exclude-libs,ALL")
        if (FORTIFY_SOURCES_NO_DLOPEN)
            set(library_link_flags "${library_link_flags} -Wl,-z,nodlopen")
        endif ()

        set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--no-undefined")

        set(CMAKE_EXE_C_FLAGS_fortify "-fPIE")
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -pie")
    elseif (MSVC)
        set(library_link_flags "/dynamicbase /NXCOMPAT /SafeSEH")

        # If the NO_CRT_STDIO_INLINE is enabled, there are some linking errors,
        # unresolved external symbol. In order to resolve them, need to add the
        # legacy_stdio_definitions.lib.
        # See https://msdn.microsoft.com/en-us/library/bb531344.aspx
        if (NO_CRT_STDIO_INLINE AND MSVC_VERSION EQUAL 1900)
            set(library_link_flags "${library_link_flags} legacy_stdio_definitions.lib")
        endif()
    endif ()
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${library_link_flags}")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${library_link_flags}")
    unset(library_link_flags)
endif ()

if (COMPILER_TOO_OLD)
    message(WARNING "Your compiler is very old, please consider upgrading!")
endif ()

set(COMBINED_C_FLAGS "${CMAKE_C_FLAGS_analysis} ${CMAKE_C_ONLY_FLAGS_analysis} ${CMAKE_C_FLAGS_fortify}")
set(COMBINED_CXX_FLAGS "${CMAKE_C_FLAGS_analysis} ${CMAKE_C_FLAGS_fortify}")

set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} ${COMBINED_C_FLAGS}")
set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} ${COMBINED_C_FLAGS} ${FSANITIZE_FLAGS}")
set(CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_RELWITHDEBINFO} ${COMBINED_C_FLAGS}")
set(CMAKE_C_FLAGS_MINSIZEREL "${CMAKE_C_FLAGS_MINSIZEREL} ${COMBINED_C_FLAGS}")
set(CMAKE_C_FLAGS_NONE "${CMAKE_C_FLAGS_NONE} ${COMBINED_C_FLAGS}")

set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} ${COMBINED_CXX_FLAGS}")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} ${COMBINED_CXX_FLAGS} ${FSANITIZE_FLAGS}")
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELWITHDEBINFO} ${COMBINED_CXX_FLAGS}")
set(CMAKE_CXX_FLAGS_MINSIZEREL "${CMAKE_CXX_FLAGS_MINSIZEREL} ${COMBINED_CXX_FLAGS}")
set(CMAKE_CXX_FLAGS_NONE "${CMAKE_CXX_FLAGS_NONE} ${COMBINED_CXX_FLAGS}")

unset(CMAKE_C_FLAGS_analysis)
unset(CMAKE_C_ONLY_FLAGS_analysis)
unset(CMAKE_C_FLAGS_fortify)
unset(COMBINED_C_FLAGS)
unset(COMBINED_CXX_FLAGS)

# glib stuff, not for debug builds
set_property(DIRECTORY APPEND PROPERTY
    COMPILE_DEFINITIONS $<$<CONFIG:MinSizeRel>:G_DISABLE_ASSERT;G_DISABLE_CHECKS>
                        $<$<CONFIG:None>:G_DISABLE_ASSERT;G_DISABLE_CHECKS>
                        $<$<CONFIG:Release>:G_DISABLE_ASSERT;G_DISABLE_CHECKS>
                        $<$<CONFIG:RelWithDebInfo>:G_DISABLE_ASSERT;G_DISABLE_CHECKS>
   )


# make windows builds faster
if (MSVC)
    # speed up builds by using parallel compilation of source files
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /MP")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /MP")
endif ()


# add CPPFLAGS from environment, https://cmake.org/Bug/view.php?id=12928
add_definitions($ENV{CPPFLAGS})
