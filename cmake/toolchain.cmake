# toolchain.cmake -- CMake toolchain for Xbox XDK cross-compilation (clang/clang++).
# Usage: cmake -DCMAKE_TOOLCHAIN_FILE=OXDK/cmake/toolchain.cmake [options]
# Optional: -DOXDK_XDK_DIR=<path>   (default: OXDK/xdk)

# Runs after CMake sets its own per-language rule defaults, so it can reliably override them.
set(CMAKE_USER_MAKE_RULES_OVERRIDE     "${CMAKE_CURRENT_LIST_DIR}/rulesoverride.cmake")
set(CMAKE_USER_MAKE_RULES_OVERRIDE_CXX "${CMAKE_CURRENT_LIST_DIR}/rulesoverride.cmake")

# Resolves clang/clang++, libc++ headers, OXDK_LINK_EXE/OXDK_LIB_EXE.
include("${CMAKE_CURRENT_LIST_DIR}/resolvehostdeps.cmake")

# XDK path resolution
if(NOT DEFINED ENV{OXDK_DIR})
    if(DEFINED OXDK_DIR)
        set(ENV{OXDK_DIR} "${OXDK_DIR}")
    else()
        set(OXDK_DIR "${CMAKE_CURRENT_LIST_DIR}/..")
        get_filename_component(OXDK_DIR "${OXDK_DIR}" ABSOLUTE)
        set(ENV{OXDK_DIR} "${OXDK_DIR}")
    endif()
endif()

if(NOT DEFINED ENV{OXDK_XDK_DIR})
    if(DEFINED OXDK_XDK_DIR)
        set(ENV{OXDK_XDK_DIR} "${OXDK_XDK_DIR}")
    else()
        set(OXDK_XDK_DIR "${OXDK_DIR}/xdk")
        get_filename_component(OXDK_XDK_DIR "${OXDK_XDK_DIR}" ABSOLUTE)
        set(ENV{OXDK_XDK_DIR} "${OXDK_XDK_DIR}")
    endif()
endif()

if(NOT EXISTS "$ENV{OXDK_XDK_DIR}/lib/xboxkrnl.lib")
    message(FATAL_ERROR
        "Xbox kernel library not found at $ENV{OXDK_XDK_DIR}/lib/"
        "Set OXDK_XDK_DIR to your XDK path or copy XDK files into OXDK/xdk/")
endif()

# Cross-compilation target
set(CMAKE_SYSTEM_NAME      Windows)
set(CMAKE_SYSTEM_PROCESSOR i386)

# Don't search for programs/libraries/headers inside a sysroot -- we manage
# all include and lib paths explicitly via compiler/linker flags.
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE NEVER)

# Use STATIC_LIBRARY mode for try_compile so it doesn't need a full link.
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# File suffixes
set(CMAKE_STATIC_LIBRARY_SUFFIX ".lib")
set(CMAKE_EXECUTABLE_SUFFIX     ".exe")
set(CMAKE_SHARED_LIBRARY_SUFFIX ".dll")

# Common C/C++ flags (mirrors OXDK_TARGET_FLAGS + OXDK_COMMON_FLAGS in oxdk.mk).
set(_oxdk_common_flags
    "-target i386-pc-windows-msvc -march=pentium3"
    "-fms-extensions -fms-compatibility -fms-compatibility-version=13.10"
    "-D_XBOX -D_X86_ -DWIN32_LEAN_AND_MEAN -D_NTOS_ -D_MT"
    "-Wno-microsoft-include -Wno-pragma-pack -Wno-ignored-pragmas"
    "-Wno-deprecated-declarations -Wno-writable-strings -Wno-microsoft-cast"
    "-Wno-unknown-pragmas -Wno-extra-tokens -Wno-nonportable-include-path"
    "-Wno-typedef-redefinition"
    "-Xclang -fdefault-calling-conv=stdcall"
    "-ffunction-sections -fdata-sections"
)
list(JOIN _oxdk_common_flags " " _oxdk_common_flags)

# XDK isystem: normal priority for C, but appended dead last for C++ so libc++'s headers win.
set(CMAKE_C_FLAGS_INIT   "${_oxdk_common_flags} -isystem $ENV{OXDK_XDK_DIR}/include")

set(_oxdk_libcxx_inc "$ENV{OXDK_LLVM_DIR}/include/c++/v1")

set(CMAKE_CXX_FLAGS_INIT
    "${_oxdk_common_flags} -fdelayed-template-parsing -fno-rtti -fno-exceptions\
     -fms-compatibility-version=19.00 -nostdinc++\
     -isystem $ENV{OXDK_DIR}/oxdk/libcxx-config\
     -isystem ${_oxdk_libcxx_inc}\
     -isystem $ENV{OXDK_DIR}/oxdk/libcxx-cshim\
     -isystem ${_oxdk_clang_res_dir}/include\
     -isystem $ENV{OXDK_XDK_DIR}/include")

# Windows-Clang.cmake hardcodes the dynamic CRT (-D_DLL --dependent-lib=msvcrtd)
# into CMAKE_<LANG>_FLAGS_DEBUG_INIT for GNU-frontend clang, regardless of
# CMAKE_MSVC_RUNTIME_LIBRARY (that variable only applies to clang-cl/real MSVC).
# _CRTIMP in the XDK headers means dllimport under -D_DLL, so this expects
# CRT symbols as __imp_* -- but we link the static libcmtd.lib below, which
# has plain symbols. Same class of "clobbered by a platform module" bug
# rulesoverride.cmake already fights; force the static-CRT flags there too.
set(_OXDK_C_FLAGS_DEBUG   "-O0 -g -Xclang -gcodeview -D_DEBUG -D_MT -Xclang --dependent-lib=libcmtd")
set(_OXDK_CXX_FLAGS_DEBUG "${_OXDK_C_FLAGS_DEBUG}")

# ── Linker setup ───────────────────────────────────────────────────────────────
set(CMAKE_LINKER "${OXDK_LINK_EXE}")
set(CMAKE_AR     "${OXDK_LIB_EXE}")

# clang emits undecorated __imp__Name; xboxkrnl.lib ships __imp__Name@N.
set(_oxdk_kernel_imports
    "/alternatename:__imp__HalReturnToFirmware=__imp__HalReturnToFirmware@4\
     /alternatename:__imp__HalInitiateShutdown=__imp__HalInitiateShutdown@0\
     /alternatename:__imp__HalReadSMCTrayState=__imp__HalReadSMCTrayState@8\
     /alternatename:__imp__HalReadSMBusValue=__imp__HalReadSMBusValue@16\
     /alternatename:__imp__HalWriteSMBusValue=__imp__HalWriteSMBusValue@16\
     /alternatename:__imp__IoCreateSymbolicLink=__imp__IoCreateSymbolicLink@8\
     /alternatename:__imp__IoDeleteSymbolicLink=__imp__IoDeleteSymbolicLink@4\
     /alternatename:__imp__IoDismountVolumeByName=__imp__IoDismountVolumeByName@4\
     /alternatename:__imp__MmFreeContiguousMemory=__imp__MmFreeContiguousMemory@4"
)

# clang emits stdcall __ftol@8/__ftol2@8; libcmt ships them cdecl.
set(_oxdk_crt_helpers
    "/alternatename:__ftol@8=__ftol\
     /alternatename:__ftol2@8=__ftol2"
)

# No prebuilt libc++.a for i386-xbox -- compile libcxx_runtime.cpp's shim
# symbols once here and splice into every link.
set(_oxdk_libcxx_shim_src "$ENV{OXDK_DIR}/oxdk/libcxx-shim/libcxx_runtime.cpp")
set(_oxdk_libcxx_shim_dir "$ENV{OXDK_DIR}/oxdk/libcxx-shim/.build")
set(_oxdk_libcxx_shim_obj "${_oxdk_libcxx_shim_dir}/libcxx_runtime.obj")
set(_oxdk_libcxx_shim_lib "${_oxdk_libcxx_shim_dir}/libcxx_runtime.lib")

if(NOT EXISTS "${_oxdk_libcxx_shim_lib}" OR "${_oxdk_libcxx_shim_src}" IS_NEWER_THAN "${_oxdk_libcxx_shim_lib}")
    file(MAKE_DIRECTORY "${_oxdk_libcxx_shim_dir}")
    separate_arguments(_oxdk_shim_cxx_flags UNIX_COMMAND "${CMAKE_CXX_FLAGS_INIT}")

    execute_process(
        COMMAND "${CMAKE_CXX_COMPILER}" ${_oxdk_shim_cxx_flags}
                -c "${_oxdk_libcxx_shim_src}" -o "${_oxdk_libcxx_shim_obj}"
        RESULT_VARIABLE _oxdk_shim_rc
        OUTPUT_VARIABLE _oxdk_shim_out
        ERROR_VARIABLE  _oxdk_shim_err
    )
    if(NOT _oxdk_shim_rc EQUAL 0)
        message(FATAL_ERROR "Failed to build libc++ runtime shim:\n${_oxdk_shim_out}\n${_oxdk_shim_err}")
    endif()

    execute_process(
        COMMAND "${OXDK_LIB_EXE}" /nologo "/OUT:${_oxdk_libcxx_shim_lib}" "${_oxdk_libcxx_shim_obj}"
        RESULT_VARIABLE _oxdk_shim_ar_rc
        OUTPUT_VARIABLE _oxdk_shim_ar_out
        ERROR_VARIABLE  _oxdk_shim_ar_err
    )
    if(NOT _oxdk_shim_ar_rc EQUAL 0)
        message(FATAL_ERROR "Failed to archive libc++ runtime shim:\n${_oxdk_shim_ar_out}\n${_oxdk_shim_ar_err}")
    endif()
endif()

# Default XDK libs, linked implicitly into every executable
set(_oxdk_default_lib_names
    libcmtd.lib libcpmtd.lib xboxkrnl.lib
    d3d8d.lib d3dx8d.lib xgraphicsd.lib dsoundd.lib
    xnetd.lib xonlined.lib xbdm.lib
    xapilibd.lib xapilib.lib xapilibp.lib
)
set(_oxdk_default_libs "")
foreach(_oxdk_lib_name ${_oxdk_default_lib_names})
    if(NOT EXISTS "$ENV{OXDK_XDK_DIR}/lib/${_oxdk_lib_name}")
        continue()
    endif()
    string(APPEND _oxdk_default_libs " \"$ENV{OXDK_XDK_DIR}/lib/${_oxdk_lib_name}\"")
endforeach()

# Base linker flag
set(_oxdk_common_link_flags
    "/nologo /subsystem:windows /fixed:no\
     /machine:x86 /nodefaultlib /force:multiple\
     /safeseh:no /merge:.edata=.edataxb /opt:ref\
     /libpath:$ENV{OXDK_XDK_DIR}/lib\
     ${_oxdk_kernel_imports}\
     ${_oxdk_crt_helpers}\
     \"${_oxdk_libcxx_shim_lib}\""
)

# Private names, not CMAKE_EXE_LINKER_FLAGS_INIT -- Windows-GNU.cmake clobbers that.
# rulesoverride.cmake force-applies these into the real cache vars.
set(_OXDK_EXE_LINKER_FLAGS
    "${_oxdk_common_link_flags}\
    /base:0x00010000\
    /entry:mainCRTStartup\
    /stack:1048576\
    ${_oxdk_default_libs}"
)
set(_OXDK_SHARED_LINKER_FLAGS "${_oxdk_common_link_flags}")

# C/C++ standards
set(CMAKE_C_STANDARD   11)
set(CMAKE_CXX_STANDARD 17)

# Host tools
include("$ENV{OXDK_DIR}/cmake/hosttools.cmake")