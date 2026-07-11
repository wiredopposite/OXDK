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

    set(_cxbe_build_dir "$ENV{OXDK_DIR}/tools/cxbe/build")
    set(_cxbe_bin "${_cxbe_build_dir}/cxbe")

    if(NOT TARGET oxdk_cxbe_build)
        add_custom_command(
            OUTPUT  "${_cxbe_bin}"
            COMMAND ${CMAKE_COMMAND} -S "$ENV{OXDK_DIR}/tools/cxbe" -B "${_cxbe_build_dir}" -G "${CMAKE_GENERATOR}" -DCMAKE_BUILD_TYPE=Release
            COMMAND ${CMAKE_COMMAND} --build "${_cxbe_build_dir}" --config Release
            COMMENT "Building cxbe..."
            VERBATIM
        )
        add_custom_target(oxdk_cxbe_build DEPENDS "${_cxbe_bin}")
        set_directory_properties(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES "${_cxbe_build_dir}")
    endif()

    set(OXDK_CXBE "${_cxbe_bin}" CACHE FILEPATH "Path to cxbe" FORCE)
    set(${OUT_EXE} "${_cxbe_bin}" PARENT_SCOPE)
    add_dependencies(${TARGET_NAME} oxdk_cxbe_build)
endfunction()

function(OxdkEnsureExtractXiso TARGET_NAME OUT_EXE)
    if(OXDK_EXTRACT_XISO AND TARGET oxdk_extract_xiso_build)
        set(${OUT_EXE} "${OXDK_EXTRACT_XISO}" PARENT_SCOPE)
        add_dependencies(${TARGET_NAME} oxdk_extract_xiso_build)
        return()
    endif()

    find_program(_found_extract_xiso extract-xiso HINTS "$ENV{OXDK_DIR}/tools/extract-xiso" NO_DEFAULT_PATH)
    if(_found_extract_xiso AND TARGET oxdk_extract_xiso_build)
        set(OXDK_EXTRACT_XISO "${_found_extract_xiso}" CACHE FILEPATH "Path to extract-xiso" FORCE)
        set(${OUT_EXE} "${_found_extract_xiso}" PARENT_SCOPE)
        add_dependencies(${TARGET_NAME} oxdk_extract_xiso_build)
        return()
    endif()

    set(_extract_xiso_build_dir "$ENV{OXDK_DIR}/tools/extract-xiso/build")
    set(_extract_xiso_bin "${_extract_xiso_build_dir}/extract-xiso")

    set(_extract_xiso_c_flags "")
    if(CMAKE_HOST_WIN32)
        set(_extract_xiso_c_flags "-DWIN32 -D_CRT_SECURE_NO_WARNINGS -D_CRT_NONSTDC_NO_DEPRECATE")
    endif()

    if(NOT TARGET oxdk_extract_xiso_build)
        add_custom_command(
            OUTPUT  "${_extract_xiso_bin}"
            COMMAND ${CMAKE_COMMAND} 
                -S "$ENV{OXDK_DIR}/tools/extract-xiso" 
                -B "${_extract_xiso_build_dir}" 
                -G "${CMAKE_GENERATOR}" 
                -DCMAKE_BUILD_TYPE=Release 
                "-DCMAKE_C_FLAGS=${_extract_xiso_c_flags}"
            COMMAND ${CMAKE_COMMAND} --build "${_extract_xiso_build_dir}" --config Release
            COMMENT "Building extract-xiso..."
            VERBATIM
        )
        add_custom_target(oxdk_extract_xiso_build DEPENDS "${_extract_xiso_bin}")
        set_directory_properties(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES "${_extract_xiso_build_dir}")
    endif()

    set(OXDK_EXTRACT_XISO "${_extract_xiso_bin}" CACHE FILEPATH "Path to extract-xiso" FORCE)
    set(${OUT_EXE} "${_extract_xiso_bin}" PARENT_SCOPE)
    add_dependencies(${TARGET_NAME} oxdk_extract_xiso_build)
endfunction()