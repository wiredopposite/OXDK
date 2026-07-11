set(NO_LIBCXX_MSG "\
    The XDK's bundled STL is C++98-only, so C++ targets need libc++.\n\
    The official Windows LLVM release doesn't ship one -- you need\n\
    a separate libc++ install or a version that bundles it, e.g.:\n\
      - llvm-mingw (i686) install (github.com/mstorsjo/llvm-mingw)\n\
      - MSYS2 install (pacman -S mingw-w64-x86_64-llvm)\n\
      - vcpkg install 'llvm[clang,libcxx]' (any triplet)\n\
      - LLVM built with -DLLVM_ENABLE_PROJECTS=libcxx\n\
    Then pass its root with -DOXDK_LLVM_DIR=/path/to/llvm-root (the \n\
    directory containing include/c++/v1).\n\
")

# Compiler/libc++
if(DEFINED ENV{OXDK_LLVM_DIR} OR DEFINED OXDK_LLVM_DIR) # default to provided path
    if(NOT DEFINED ENV{OXDK_LLVM_DIR})
        set(ENV{OXDK_LLVM_DIR} "${OXDK_LLVM_DIR}")
    endif()

    if(NOT EXISTS "$ENV{OXDK_LLVM_DIR}/include/c++/v1")
        message(FATAL_ERROR
            "libc++ headers not found at $ENV{OXDK_LLVM_DIR}/include/c++/v1\n"
            "${NO_LIBCXX_MSG}"
        )
    endif()

    find_program(_oxdk_clang   NAMES clang   HINTS "$ENV{OXDK_LLVM_DIR}/bin" REQUIRED)
    find_program(_oxdk_clangxx NAMES clang++ HINTS "$ENV{OXDK_LLVM_DIR}/bin" REQUIRED)
    set(CMAKE_C_COMPILER   "${_oxdk_clang}"   CACHE FILEPATH "" FORCE)
    set(CMAKE_CXX_COMPILER "${_oxdk_clangxx}" CACHE FILEPATH "" FORCE)
    execute_process(
        COMMAND "${CMAKE_CXX_COMPILER}" -print-resource-dir
        OUTPUT_VARIABLE _oxdk_clang_res_dir
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )

else() # try to find an install somewhere
    find_program(_oxdk_clang   NAMES clang   REQUIRED)
    find_program(_oxdk_clangxx NAMES clang++ REQUIRED)
    set(CMAKE_C_COMPILER   "${_oxdk_clang}"   CACHE FILEPATH "" FORCE)
    set(CMAKE_CXX_COMPILER "${_oxdk_clangxx}" CACHE FILEPATH "" FORCE)

    set(_oxdk_libcxx_candidates "")
    execute_process(
        COMMAND "${CMAKE_CXX_COMPILER}" -print-resource-dir
        OUTPUT_VARIABLE _oxdk_clang_res_dir
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )
    get_filename_component(_oxdk_clang_llvm_root "${_oxdk_clang_res_dir}/../../.." ABSOLUTE)
    list(APPEND _oxdk_libcxx_candidates "${_oxdk_clang_llvm_root}")

    if(DEFINED ENV{VCPKG_ROOT}) # headers aren't architecture-bound, any triplet will do
        file(GLOB _oxdk_vcpkg_triplet_dirs "$ENV{VCPKG_ROOT}/installed/*")
        list(APPEND _oxdk_libcxx_candidates ${_oxdk_vcpkg_triplet_dirs})
    endif()

    set(OXDK_LLVM_DIR "")
    foreach(_candidate ${_oxdk_libcxx_candidates})
        if(EXISTS "${_candidate}/include/c++/v1")
            set(OXDK_LLVM_DIR "${_candidate}")
            break()
        endif()
    endforeach()

    if(NOT OXDK_LLVM_DIR)
        message(FATAL_ERROR
            "Could not find a valid LLVM installation with libc++ headers.\n"
            "${NO_LIBCXX_MSG}"
        )
    endif()

    set(ENV{OXDK_LLVM_DIR} "${OXDK_LLVM_DIR}")
endif()

if(DEFINED OXDK_LINKER OR DEFINED ENV{OXDK_LINKER})
    set(OXDK_LINK_EXE $<IF:$<BOOL:${OXDK_LINKER}>,${OXDK_LINKER},$ENV{OXDK_LINKER}>)
endif()

# Link/archive tools
if(CMAKE_HOST_WIN32)
    set(_msvc_bin_dir "")

    if(NOT OXDK_LINK_EXE)
        # try to find the msvc linker before defaulting to lld-link
        # lld-link has a bug (not sure if version dependant) where
        # merging $SUFFIX subsections then merging that into another section
        # will crash the program (Exception Code: 0xC0000005)
        # this doesn't happen with every compile target
        set(VSWHERE_EXE "C:/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe")
        if(EXISTS "${VSWHERE_EXE}")
            execute_process(
                COMMAND 
                    "${VSWHERE_EXE}" 
                    -latest 
                    -products * 
                    -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 
                    -property installationPath
                OUTPUT_VARIABLE _vswhere_path
                OUTPUT_STRIP_TRAILING_WHITESPACE
                ERROR_QUIET
            )
            if(_vswhere_path)
                file(GLOB_RECURSE _link_candidates "${_vswhere_path}/*/link.exe")
                if(_link_candidates)
                    list(GET _link_candidates 0 _first_link_candidate)
                    get_filename_component(_msvc_bin_dir "${_first_link_candidate}" DIRECTORY)
                    find_program(OXDK_LINK_EXE NAMES link.exe PATHS "${_msvc_bin_dir}" NO_DEFAULT_PATH)
                endif()
            endif()
        endif()
    else()
        get_filename_component(_msvc_bin_dir "${OXDK_LINK_EXE}" DIRECTORY)
    endif()

    if(_msvc_bin_dir)
        find_program(OXDK_LIB_EXE  NAMES lib.exe  PATHS "${_msvc_bin_dir}" NO_DEFAULT_PATH)
    endif()

    if(NOT OXDK_LINK_EXE)
        message(WARNING "Could not find MSVC's link.exe, trying lld-link (LLVM) which MAY HAVE ISSUES with section merging in some XDK libs.")
    endif()
endif()

if(NOT OXDK_LINK_EXE)
    find_program(OXDK_LINK_EXE NAMES lld-link PATHS "$ENV{OXDK_LLVM_DIR}/bin" REQUIRED)
endif()
if(NOT OXDK_LIB_EXE)
    find_program(OXDK_LIB_EXE NAMES llvm-lib PATHS "$ENV{OXDK_LLVM_DIR}/bin" REQUIRED)
endif()
