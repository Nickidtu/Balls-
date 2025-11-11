cmake_minimum_required(VERSION 3.10)
project(raylib_demo C)

find_package(PkgConfig REQUIRED)
pkg_check_modules(RAYLIB REQUIRED raylib)

include_directories(${RAYLIB_INCLUDE_DIRS})
link_directories(${RAYLIB_LIBRARY_DIRS})

add_executable(app main.c)
target_link_libraries(app ${RAYLIB_LIBRARIES})
