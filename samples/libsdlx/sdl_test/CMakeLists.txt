add_executable(sdl_test
    "${CMAKE_CURRENT_LIST_DIR}/sdl_test.cpp"
)

target_link_libraries(sdl_test PRIVATE Oxdk::sdlx)

OxdkCreateDisc(sdl_test)