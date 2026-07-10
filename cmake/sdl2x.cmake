if(NOT TARGET oxdk_sdl2x)

set(_SDL2X_DIR "$ENV{OXDK_DIR}/third-party/SDL2x/libSDL2x")
file(STRINGS "${_SDL2X_DIR}/libSDL2x.vcxproj" _sdl2x_lines
    REGEX "<ClCompile Include=\"[^\"]+\"")

set(_SDL2X_SOURCES "")
foreach(_line ${_sdl2x_lines})
    string(REGEX REPLACE ".*<ClCompile Include=\"([^\"]+)\".*" "\\1" _rel_path "${_line}")
    string(REPLACE "\\" "/" _rel_path "${_rel_path}")
    list(APPEND _SDL2X_SOURCES "${_SDL2X_DIR}/${_rel_path}")
endforeach()

add_library(oxdk_sdl2x STATIC ${_SDL2X_SOURCES})

target_precompile_headers(oxdk_sdl2x 
    PRIVATE "$ENV{OXDK_DIR}/third-party/SDL2x/oxdk/interlocked_shim.h"
)

target_include_directories(oxdk_sdl2x 
    SYSTEM PUBLIC
        "${_SDL2X_DIR}/include"
    SYSTEM PRIVATE
        "${_SDL2X_DIR}/src"
)

target_compile_options(oxdk_sdl2x 
    PUBLIC
        -DXBOX
        -D_XBOX
        -D__XBOX__
        -D__PRFCHWINTRIN_H
    PRIVATE
        -D_LIB
        -DSDL_DISABLE_IMMINTRIN_H
        -U__SSE__
        -U__MMX__
        # clang can default incompatible-pointer-types to an error in C mode
        -Wno-error=incompatible-pointer-types
)

# SDL_xboxkeyboard.c calls the XInputDebug* functions (debug-kit keyboard
# input), which live in xkbd.lib -- same as libSDLx's sdl.cmake. PUBLIC since
# consuming executables link the missing symbols in, not this static lib itself.
target_link_libraries(oxdk_sdl2x PUBLIC "$ENV{OXDK_XDK_DIR}/lib/xkbd.lib")

add_library(Oxdk::sdl2x ALIAS oxdk_sdl2x)

endif()