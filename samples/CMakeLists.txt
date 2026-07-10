cmake_minimum_required(VERSION 3.5)

# OXDK_XDK_DIR should be provided if not "OXDK/xdk/" (-DOXDK_XDK_DIR=...)
# OXDK_LLVM_DIR should be provided if default LLVM install lacks libc++ headers (-DOXDK_LLVM_DIR=...)

set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_LIST_DIR}/../cmake/toolchain.cmake")

set(CMAKE_PROJECT_NAME "oxdksamples")
project(${CMAKE_PROJECT_NAME} C CXX)

# Pull in sdl libs
include("$ENV{OXDK_DIR}/cmake/sdlx.cmake")
include("$ENV{OXDK_DIR}/cmake/sdl2x.cmake")

add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/d3d/hello)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/libcxx/cxx17_hello)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/libsdlx/sdl_test)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/sdl2x)