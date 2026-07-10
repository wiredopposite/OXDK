if(NOT TARGET oxdk_sdlx)

set(_SDLX_DIR "$ENV{OXDK_DIR}/third-party/libSDLx")

file(GLOB _SDLX_SOURCES 
    "${_SDLX_DIR}/SDL/src/*.c"
    "${_SDLX_DIR}/SDL/src/audio/*.c"
    "${_SDLX_DIR}/SDL/src/audio/xbox/*.c"
    "${_SDLX_DIR}/SDL/src/cpuinfo/*.c"
    "${_SDLX_DIR}/SDL/src/endian/*.c"
    "${_SDLX_DIR}/SDL/src/events/*.c"
    "${_SDLX_DIR}/SDL/src/file/*.c"
    "${_SDLX_DIR}/SDL/src/joystick/*.c"
    "${_SDLX_DIR}/SDL/src/joystick/xbox/*.c"
    "${_SDLX_DIR}/SDL/src/stdlib/*.c"
    "${_SDLX_DIR}/SDL/src/thread/*.c"
    "${_SDLX_DIR}/SDL/src/thread/xbox/*.c"
    "${_SDLX_DIR}/SDL/src/timer/*.c"
    "${_SDLX_DIR}/SDL/src/timer/xbox/*.c"
    "${_SDLX_DIR}/SDL/src/video/*.c"
    "${_SDLX_DIR}/SDL/src/video/xbox/*.c"
)
list(REMOVE_ITEM _SDLX_SOURCES
    "${_SDLX_DIR}/SDL/src/audio/SDL_mixer_MMX.c"
    "${_SDLX_DIR}/SDL/src/audio/SDL_mixer_MMX_VC.c"
    "${_SDLX_DIR}/SDL/src/audio/SDL_mixer_m68k.c"
    "${_SDLX_DIR}/SDL/src/video/SDL_yuv_mmx.c"
    "${_SDLX_DIR}/SDL/src/cdrom/SDL_cdrom.c"
    "${_SDLX_DIR}/SDL/src/cdrom/xbox/SDL_syscdrom.c"
)

add_library(oxdk_sdlx STATIC 
    $ENV{OXDK_DIR}/samples/libsdlx/sdl_test/xbox_platform.c # move this elsewhere?
    ${_SDLX_SOURCES}
)

target_include_directories(oxdk_sdlx SYSTEM 
    PUBLIC
        "${_SDLX_DIR}/SDL/include"
)

target_include_directories(oxdk_sdlx
    PRIVATE
        "${_SDLX_DIR}/SDL/src"
        "${_SDLX_DIR}/SDL/src/audio"
        "${_SDLX_DIR}/SDL/src/video"
        "${_SDLX_DIR}/SDL/src/joystick"
        "${_SDLX_DIR}/SDL/src/cdrom"
        "${_SDLX_DIR}/SDL/src/events"
        "${_SDLX_DIR}/SDL/src/thread"
        "${_SDLX_DIR}/SDL/src/timer"
)

target_compile_definitions(oxdk_sdlx PUBLIC
    _LIB
    _WINDOWS
    WIN32
    WAV_MUSIC
    ENABLE_DIRECTX
    USE_RWOPS
    NO_SIGNAL_H
)

# SDL_xboxevents.c unconditionally #defines DEBUG_KEYBOARD/DEBUG_MOUSE itself
# (unless _XBOX_DONT_USE_DEVICES is set, which breaks compilation elsewhere in
# libSDLx - see the sdl_test Makefile's comment). That path calls XInputDebug* 
# methods, which live in xkbd.lib.
target_link_libraries(oxdk_sdlx PUBLIC "$ENV{OXDK_XDK_DIR}/lib/xkbd.lib")

add_library(Oxdk::sdlx ALIAS oxdk_sdlx)

endif()