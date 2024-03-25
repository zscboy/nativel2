# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(nativel2_library VERSION 0.0.1 LANGUAGES C)

add_library(nativel2 SHARED
  "nativel2.c"
)

set_target_properties(nativel2 PROPERTIES
  PUBLIC_HEADER nativel2.h
  OUTPUT_NAME "nativel2"
)

target_compile_definitions(nativel2 PUBLIC DART_SHARED_LIB)

target_link_libraries(nativel2 PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/../gol2/build/gol2.a)
