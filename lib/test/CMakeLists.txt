project(unit-tests)

include(CTest)
include(GNUInstallDirs)
set(TMDB_INSTALL_INCLUDEDIR ${CMAKE_INSTALL_INCLUDEDIR}/tmdb)

add_executable(test_get_api_key test_get_api_key.c)
target_include_directories(test_get_api_key PRIVATE ${CMAKE_SOURCE_DIR}/lib/include
                                                    ${CMAKE_SOURCE_DIR}/lib/src
                                                    ${CMAKE_BINARY_DIR}/lib/src
                            )
target_link_libraries(test_get_api_key unity tmdb)
add_test(test_get_api_key test_get_api_key)
