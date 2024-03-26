# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "nativel2")
project(${PROJECT_NAME} LANGUAGES CXX)

# Invoke the build for native code shared with the other target platforms.
# This can be changed to accommodate different builds.
#add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/../src" "${CMAKE_CURRENT_BINARY_DIR}/shared")

set(GOLIB ${CMAKE_CURRENT_SOURCE_DIR}/../src/gol2/build/gol2.dll)

add_library(nativel2 SHARED IMPORTED GLOBAL)
set_target_properties(nativel2
  PROPERTIES
  IMPORTED_LOCATION ${GOLIB}
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_CURRENT_BINARY_DIR})

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(nativel2_bundled_libraries
  # Defined in ../src/CMakeLists.txt.
  # This can be changed to accommodate different builds.
  $<TARGET_FILE:nativel2>
  PARENT_SCOPE
)
