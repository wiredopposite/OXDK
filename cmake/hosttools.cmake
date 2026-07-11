function(OxdkCreateDisc EXECUTABLE_TARGET_NAME)
    cmake_parse_arguments(ARG "" "DISC_NAME;TITLE_NAME;MODE" "" ${ARGN})

    if(NOT ARG_TITLE_NAME)
        set(ARG_TITLE_NAME "${EXECUTABLE_TARGET_NAME}")
    endif()

    if(NOT ARG_DISC_NAME)
        set(ARG_DISC_NAME "${ARG_TITLE_NAME}")
    endif()

    if(NOT ARG_MODE)
        set(ARG_MODE RETAIL)
    endif()

    if(NOT TARGET ${ARG_DISC_NAME}_DISC)
        add_custom_target(${ARG_DISC_NAME}_DISC ALL)
    else()
        message(FATAL_ERROR "Target ${ARG_DISC_NAME}_DISC already exists.")
    endif()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/hosttoolsprivate.cmake")

    OxdkEnsureCxbe(${EXECUTABLE_TARGET_NAME} _cxbe_exe)
    OxdkEnsureExtractXiso(${EXECUTABLE_TARGET_NAME} _extract_xiso_exe)

    set(_disc_path "${CMAKE_BINARY_DIR}/discs/${ARG_DISC_NAME}")
    set(_xbe_out "${_disc_path}/default.xbe")
    set(_xiso_out "${_disc_path}.iso")

    cmake_path(NATIVE_PATH _disc_path _disc_path)
    cmake_path(NATIVE_PATH _xiso_out _xiso_out)

    # cxbe (and any OxdkAddResource copies registered after this call) run as
    # POST_BUILD steps on EXECUTABLE_TARGET_NAME; extract-xiso must run after
    # ALL of those finish, so it lives on the dependent _DISC target instead
    # of bundled into the same POST_BUILD block. We could make a whole system
    # of dependencies to ensure the xiso is created every time the main target
    # is built, but for now just rely on the dependency on the _DISC target.
    add_custom_command(TARGET ${EXECUTABLE_TARGET_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory "${_disc_path}"
        COMMAND "${_cxbe_exe}"
            "-MODE:${ARG_MODE}"
            "-TITLE:${ARG_TITLE_NAME}"
            "-OUT:${_xbe_out}"
            "$<TARGET_FILE:${EXECUTABLE_TARGET_NAME}>"
        COMMENT "cxbe: ${EXECUTABLE_TARGET_NAME}.exe -> ${_xbe_out}"
        BYPRODUCTS "${_xbe_out}"
        VERBATIM
    )

    add_custom_command(TARGET ${ARG_DISC_NAME}_DISC POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E chdir "${CMAKE_CURRENT_BINARY_DIR}"
            "${_extract_xiso_exe}"
            "-c"
            "${_disc_path}"
            "${_xiso_out}"
        WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
        COMMENT "extract-xiso: ${_disc_path} -> ${_xiso_out}"
        BYPRODUCTS "${_xiso_out}"
        VERBATIM
    )
    add_dependencies(${ARG_DISC_NAME}_DISC ${EXECUTABLE_TARGET_NAME})
endfunction()

function(OxdkAddResource EXECUTABLE_TARGET_NAME)
    cmake_parse_arguments(ARG "" "DISC_NAME;FILE_PATH;DISC_PATH" "" ${ARGN})

    if(NOT ARG_FILE_PATH)
        message(FATAL_ERROR "FILE_PATH argument is required for OxdkAddResource.")
    endif()

    if(NOT ARG_DISC_NAME)
        set(ARG_DISC_NAME "${EXECUTABLE_TARGET_NAME}")
    endif()

    if(NOT TARGET ${ARG_DISC_NAME}_DISC)
        message(FATAL_ERROR "Target ${ARG_DISC_NAME}_DISC does not exist.")
    endif()

    set(ABS_DISC_PATH "${CMAKE_BINARY_DIR}/discs/${ARG_DISC_NAME}/${ARG_DISC_PATH}")

    add_custom_command(TARGET ${EXECUTABLE_TARGET_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy "${ARG_FILE_PATH}" "${ABS_DISC_PATH}"
        BYPRODUCTS "${ABS_DISC_PATH}"
        COMMENT "Copying resource ${ARG_FILE_PATH} to ${ABS_DISC_PATH}"
        VERBATIM
    )
endfunction()

function(OxdkAddResources EXECUTABLE_TARGET_NAME)
    cmake_parse_arguments(ARG "" "DISC_NAME;DIRECTORY;RELATIVE_PATH" "" ${ARGN})

    if(NOT ARG_DIRECTORY)
        message(FATAL_ERROR "DIRECTORY argument is required for OxdkAddResources.")
    endif()

    if(NOT ARG_DISC_NAME)
        set(ARG_DISC_NAME "${EXECUTABLE_TARGET_NAME}")
    endif()

    if(NOT ARG_RELATIVE_PATH)
        set(ARG_RELATIVE_PATH "${ARG_DIRECTORY}")
    endif()

    if(NOT TARGET ${ARG_DISC_NAME}_DISC)
        message(FATAL_ERROR "Target ${ARG_DISC_NAME}_DISC does not exist.")
    endif()

    file(GLOB_RECURSE _resources "${ARG_DIRECTORY}/*")
    foreach(_resource ${_resources})
        cmake_path(
            RELATIVE_PATH _resource 
            BASE_DIRECTORY "${ARG_RELATIVE_PATH}" 
            OUTPUT_VARIABLE _relative_path
        )
        OxdkAddResource(
            ${EXECUTABLE_TARGET_NAME}
            DISC_NAME "${ARG_DISC_NAME}"
            FILE_PATH "${_resource}"
            DISC_PATH "${_relative_path}"
        )
    endforeach()
endfunction()
