# rulesoverride.cmake -- link/archive rule overrides for the OXDK toolchain.
# Included via CMAKE_USER_MAKE_RULES_OVERRIDE(_CXX), which runs after CMake's
# platform modules (Windows-GNU.cmake/Windows-Clang.cmake) so it reliably wins.

set(CMAKE_C_LINK_EXECUTABLE
    "\"${OXDK_LINK_EXE}\" <LINK_FLAGS> /OUT:<TARGET> <OBJECTS> <LINK_LIBRARIES>"
    CACHE STRING "" FORCE)
set(CMAKE_CXX_LINK_EXECUTABLE
    "\"${OXDK_LINK_EXE}\" <LINK_FLAGS> /OUT:<TARGET> <OBJECTS> <LINK_LIBRARIES>"
    CACHE STRING "" FORCE)

set(CMAKE_C_CREATE_STATIC_LIBRARY
    "\"${OXDK_LIB_EXE}\" /nologo /OUT:<TARGET> <OBJECTS>"
    CACHE STRING "" FORCE)
set(CMAKE_CXX_CREATE_STATIC_LIBRARY
    "\"${OXDK_LIB_EXE}\" /nologo /OUT:<TARGET> <OBJECTS>"
    CACHE STRING "" FORCE)

# Same clobbering hits these -- force from the toolchain-private names.
set(CMAKE_EXE_LINKER_FLAGS    "${_OXDK_EXE_LINKER_FLAGS}"    CACHE STRING "" FORCE)
set(CMAKE_SHARED_LINKER_FLAGS "${_OXDK_SHARED_LINKER_FLAGS}" CACHE STRING "" FORCE)

# And CMAKE_C/CXX_FLAGS_DEBUG (Windows-Clang.cmake hardcodes the dynamic CRT there).
set(CMAKE_C_FLAGS_DEBUG   "${_OXDK_C_FLAGS_DEBUG}"   CACHE STRING "" FORCE)
set(CMAKE_CXX_FLAGS_DEBUG "${_OXDK_CXX_FLAGS_DEBUG}" CACHE STRING "" FORCE)

# Windows-GNU.cmake seeds these with mingw -lkernel32-style libs; clear them, we supply our own.
set(CMAKE_C_STANDARD_LIBRARIES   "" CACHE STRING "" FORCE)
set(CMAKE_CXX_STANDARD_LIBRARIES "" CACHE STRING "" FORCE)

# Windows-Clang.cmake also injects /subsystem:console and -fuse-ld=lld-link into <LINK_FLAGS>
# outside CMAKE_EXE_LINKER_FLAGS -- blank them, we set our own subsystem and invoke link.exe directly.
foreach(_oxdk_lang C CXX)
    set(CMAKE_${_oxdk_lang}_CREATE_CONSOLE_EXE "")
    set(CMAKE_${_oxdk_lang}_CREATE_WIN32_EXE   "")
    set(CMAKE_${_oxdk_lang}_USING_LINKER_DEFAULT "")
    set(CMAKE_${_oxdk_lang}_USING_LINKER_LLD     "")
endforeach()
