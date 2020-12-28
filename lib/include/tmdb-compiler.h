#pragma once


/* try to make things compile using MSVC */
#if !defined __GNUC__
#    define __attribute__(xyz) /* ignore */
#endif


#ifdef __cplusplus
#    define TMDB_C_API_BEGIN extern "C" {
#    define TMDB_C_API_END }
#else /* __cplusplus */
#    define TMDB_C_API_BEGIN
#    define TMDB_C_API_END
#endif /* __cplusplus */


#if defined _MSC_VER
#    pragma section(".CRT$XCU", read)
#    define INITIALIZER2_(f, p) \
        static void f (void); \
        __declspec(allocate (".CRT$XCU")) void (*f##_) (void) = f; \
        __pragma (comment (linker, "/include:" p #f "_")) static void f (void)
#    ifdef _WIN64
#        define INITIALIZER(f, p) INITIALIZER2_ (f, "")
#    else
#        define INITIALIZER(f, p) INITIALIZER2_ (f, "_")
#    endif
#else
#    define INITIALIZER(f, p) \
        static void f (void) __attribute__ ((constructor (p))); \
        static void f (void)
#endif

#if defined _MSC_VER
#    pragma section(".CRT$XPU", read)
#    define FINALIZER2_(f, p) \
        static void f (void); \
        __declspec(allocate (".CRT$XPU")) void (*f##_) (void) = f; \
        __pragma (comment (linker, "/include:" p #f "_")) static void f (void)
#    ifdef _WIN64
#        define FINALIZER(f, p) FINALIZER2_ (f, "")
#    else
#        define FINALIZER(f, p) FINALIZER2_ (f, "_")
#    endif
#else
#    define FINALIZER(f, p) \
        static void f (void) __attribute__ ((destructor (p))); \
        static void f (void)
#endif

#ifndef __has_builtin
#    define __has_builtin(x) 0
#endif


// clang-format off
#if defined(_MSC_VER)
#    define TMDB_WARNINGS_PUSH           __pragma (warning (push))
#    define TMDB_WARNINGS_POP            __pragma (warning (pop))
#    define TMDB_WARNING_DISABLE_CLANG_GCC(w)
#    define TMDB_WARNING_DISABLE_CLANG(w)
#    define TMDB_WARNING_DISABLE_GCC(w)
#    define TMDB_WARNING_DISABLE_MSVC(n) __pragma (warning (disable : n))
#else
#    define TMDB_stringify(s) #s
#    define TMDB_JOIN(a, b)   TMDB_stringify (a) b
#    define TMDB_PRAGMA__(p)  _Pragma (#p)
#    define TMDB_PRAGMA_(p)   TMDB_PRAGMA__ (p)
#    if defined(__clang__)
#        define TMDB_WARNINGS_PUSH _Pragma ("clang diagnostic push")
#        define TMDB_WARNINGS_POP  _Pragma ("clang diagnostic pop")
#        define TMDB_WARNING_DISABLE_CLANG_GCC(w) TMDB_WARNING_DISABLE_CLANG (w)
#        define TMDB_WARNING_DISABLE_CLANG(w)     TMDB_PRAGMA_ (clang diagnostic ignored "-W" w)
#        define TMDB_WARNING_DISABLE_GCC(w)
#    elif defined(__GNUC__)
#        define TMDB_WARNINGS_PUSH _Pragma ("GCC diagnostic push")
#        define TMDB_WARNINGS_POP  _Pragma ("GCC diagnostic pop")
#        define TMDB_WARNING_DISABLE_CLANG_GCC(w) TMDB_WARNING_DISABLE_GCC (w)
#        define TMDB_WARNING_DISABLE_CLANG(w)
#        define TMDB_WARNING_DISABLE_GCC(w)       TMDB_PRAGMA_ (GCC diagnostic ignored "-W" w)
#    endif
#    define TMDB_WARNING_DISABLE_MSVC(n)
#endif
// clang-format on


#ifndef UNIT_TESTS
#    define TMDB_STATIC_UNLESS_UNITTESTS static
#else
#    define TMDB_STATIC_UNLESS_UNITTESTS
#endif
