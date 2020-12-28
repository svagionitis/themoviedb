include(GNUInstallDirs)
set(TMDB_INSTALL_INCLUDEDIR ${CMAKE_INSTALL_INCLUDEDIR}/tmdb)

install(FILES
    tmdb.h tmdb-compiler.h
    DESTINATION ${TMDB_INSTALL_INCLUDEDIR}
    COMPONENT dev
    )
