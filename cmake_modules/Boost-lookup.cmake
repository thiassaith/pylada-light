set(toolset "")
if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Intel")
  set(toolset "toolset=intel-linux")
endif()

# Patches class for intel 13 c++11 (miss?)behavior
# Resolution from https://svn.boost.org/trac/boost/ticket/9417
file(WRITE "${EXTERNAL_ROOT}/src/boost.patch"
    "--- boost/test/utils/trivial_singleton.hpp	2008-10-13 09:20:26.000000000 +0100\n"
    "+++ boost/test/utils/trivial_singleton.new.hpp	2014-05-08 12:46:52.711942285 +0100\n"
    "@@ -37,7 +37,7 @@\n"
    " public:\n"
    "     static Derived& instance() { static Derived the_inst; return the_inst; }    \n"
    " protected:\n"
    "-    singleton()  {}\n"
    "+    singleton() : noncopyable() {}\n"
    "     ~singleton() {}\n"
    " };\n"
)

find_program(PATCH_EXECUTABLE patch REQUIRED)
ExternalProject_Add(
    Boost
    PREFIX ${EXTERNAL_ROOT}
    # Downloads boost from url -- much faster than svn
    URL http://sourceforge.net/projects/boost/files/boost/1.55.0/boost_1_55_0.tar.bz2/download
    BUILD_IN_SOURCE 1
    CONFIGURE_COMMAND ./bootstrap.sh 
    PATCH_COMMAND ${PATCH_EXECUTABLE} -p0 < "${EXTERNAL_ROOT}/src/boost.patch"
    BUILD_COMMAND  ./b2 ${toolset} link=static variant=release
    INSTALL_COMMAND ./b2 ${toolset} link=static variant=release
        --prefix=${EXTERNAL_ROOT} install
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
)
# Rerun cmake to capture new boost install
add_recursive_cmake_step(Boost DEPENDEES install)
set(BOOST_ROOT "${EXTERNAL_ROOT}" CACHE INTERNAL "Prefix for Boost install")
# Makes sure those are not in the CACHE, otherwise, new version will not be found
unset(Boost_INCLUDE_DIR CACHE)
unset(Boost_LIBRARY_DIR CACHE)
