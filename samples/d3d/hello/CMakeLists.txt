add_executable(d3dhello
    "${CMAKE_CURRENT_LIST_DIR}/main.cpp"
    "${CMAKE_CURRENT_LIST_DIR}/lld_workaround.cpp"
)

OxdkCreateDisc(d3dhello
    TITLE_NAME "d3dhello"
    MODE RETAIL
)
