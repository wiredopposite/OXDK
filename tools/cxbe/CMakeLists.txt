cmake_minimum_required(VERSION 3.5)

project(cxbe C CXX)

add_executable(cxbe
    ${CMAKE_CURRENT_LIST_DIR}/Common.cpp
    ${CMAKE_CURRENT_LIST_DIR}/Error.cpp
    ${CMAKE_CURRENT_LIST_DIR}/Exe.cpp
    ${CMAKE_CURRENT_LIST_DIR}/Logo.cpp
    ${CMAKE_CURRENT_LIST_DIR}/Main.cpp
    ${CMAKE_CURRENT_LIST_DIR}/Xbe.cpp
)

if(WIN32)
    target_compile_options(cxbe PRIVATE -Dstrcasecmp=_stricmp)
endif()