set(SDL2X_ROOT "$ENV{OXDK_DIR}/third-party/SDL2x")
file(GLOB SDL2X_SAMPLE_DIRS "${SDL2X_ROOT}/Samples/*")

foreach(SAMPLE_DIR ${SDL2X_SAMPLE_DIRS})
    get_filename_component(SAMPLE_NAME ${SAMPLE_DIR} NAME)

    file(GLOB SAMPLE_SOURCES "${SAMPLE_DIR}/*.cpp" "${SAMPLE_DIR}/*.c")

    add_executable(sdl2x${SAMPLE_NAME} ${SAMPLE_SOURCES})

    target_link_libraries(sdl2x${SAMPLE_NAME} Oxdk::sdl2x)

    OxdkCreateDisc(sdl2x${SAMPLE_NAME})

    if(EXISTS "${SAMPLE_DIR}/Media")
        OxdkAddResources(sdl2x${SAMPLE_NAME} DIRECTORY "${SAMPLE_DIR}/Media")
    endif()
endforeach()
