function(OxdkEnsureCxbe TARGET_NAME OUT_EXE)
    if(OXDK_CXBE AND TARGET oxdk_cxbe_build)
        set(${OUT_EXE} "${OXDK_CXBE}" PARENT_SCOPE)
        add_dependencies(${TARGET_NAME} oxdk_cxbe_build)
        return()
    endif()

    find_program(_found_cxbe cxbe HINTS "$ENV{OXDK_DIR}/tools/cxbe" NO_DEFAULT_PATH)
    if(_found_cxbe AND TARGET oxdk_cxbe_build)
        set(OXDK_CXBE "${_found_cxbe}" CACHE FILEPATH "Path to cxbe" FORCE)
        set(${OUT_EXE} "${_found_cxbe}" PARENT_SCOPE)
        add_dependencies(${TARGET_NAME} oxdk_cxbe_build)
        return()
    endif()

    set(_cxbe_bin "$ENV{OXDK_DIR}/tools/cxbe/cxbe")
    if(NOT TARGET oxdk_cxbe_build)
        add_custom_command(
            OUTPUT  "${_cxbe_bin}"
            COMMAND ${CMAKE_MAKE_PROGRAM} -C "$ENV{OXDK_DIR}/tools/cxbe"
            COMMENT "Building cxbe..."
        )
        add_custom_target(oxdk_cxbe_build DEPENDS "${_cxbe_bin}")
    endif()

    set(OXDK_CXBE "${_cxbe_bin}" CACHE FILEPATH "Path to cxbe" FORCE)
    set(${OUT_EXE} "${_cxbe_bin}" PARENT_SCOPE)
    add_dependencies(${TARGET_NAME} oxdk_cxbe_build)
endfunction()