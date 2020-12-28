# Follow libtool versioning here, and these are a set of rules to help updating version information:
#   - Start with version information of ‘0:0:0’ for each libtool library.
#   - Update the version information only immediately before a public release of your software.
#     More frequent updates are unnecessary, and only guarantee that the current interface
#     number gets larger faster.
#   - If the library source code has changed at all since the last update,
#     then increment revision (‘c:r:a’ becomes ‘c:r+1:a’).
#   - If any interfaces have been added, removed, or changed since the last update,
#     increment current, and set revision to 0.
#   - If any interfaces have been added since the last public release,
#     then increment age.
#   - If any interfaces have been removed or changed since the last public release,
#     then set age to 0.
# NOTE: Never try to set the interface numbers so that they correspond to the release number of your package.
#       This is an abuse that only fosters misunderstanding of the purpose of library versions.
#
# Resources:
#   * https://www.gnu.org/software/libtool/manual/html_node/Libtool-versioning.html#Libtool-versioning
#   * https://www.gnu.org/software/libtool/manual/html_node/Updating-version-info.html#Updating-version-info
#   * https://autotools.io/libtool/version.html
set(ABI_VERSION_CURRENT 0)
set(ABI_VERSION_REVISION 0)
set(ABI_VERSION_AGE 0)

math(EXPR tmdb_SOVERSION "${ABI_VERSION_CURRENT} - ${ABI_VERSION_AGE}")
set(tmdb_VERSION ${library_SOVERSION}.${ABI_VERSION_AGE}.${ABI_VERSION_REVISION})
