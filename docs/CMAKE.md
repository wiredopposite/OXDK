# CMake build system

## Setup
### Build tools
The CMake toolchain assumes LLVM is installed, make sure you have an LLVM distro (or one you've built) that includes libc++, this will be in `<path to LLVM>/include/c++/v1`. The toolchain has been tested with both Ninja and MinGW as generators, do not use MSVC.

On Windows, [the official LLVM distro](https://github.com/llvm/llvm-project) does not include libc++ by default. You'll need a separate LLVM install or a distro that bundles it, e.g.:
- [llvm-mingw](https://github.com/mstorsjo/llvm-mingw) (i686 build)
- MSYS2 (`pacman -S mingw-w64-x86_64-llvm`)
- [vcpkg](https://vcpkg.io) (`vcpkg install llvm[clang,libcxx]`, any triplet works since the headers aren't architecture-bound)
- Official LLVM built from source with `-DLLVM_ENABLE_PROJECTS=libcxx`

If `<path to LLVM>/bin` is not on your system's path, you can point the OXDK toolchain to your install by configuring with `-DOXDK_LLVM_DIR=<path to LLVM>` or by setting `OXDK_LLVM_DIR` in your environment.

- **NOTE**: There seems to be a bug in LLVM's lld-link on Windows, which CAN cause an error while merging binary sections. Because of this, it is advised that you install [Build Tools for Visual Studio](https://visualstudio.microsoft.com/downloads/) (bottom of the page, All Downloads > Tools for Visual Studio) so that its linker can be used instead. On Windows, OXDK's toolchain will attempt to locate this linker via vswhere, but the path can be manually provided by configuring with `-DOXDK_LINKER=<path to MSVC linker>` or by setting `OXDK_LINKER` in your environment.

### Toolchain

The toolchain file must be set, either by configuring with `-DCMAKE_TOOLCHAIN_FILE=<path to OXDK>/cmake/toolchain.cmake` or by declaring `set(CMAKE_TOOLCHAIN_FILE "<path to OXDK>/cmake/toolchain.cmake")` in your project's main CMakeLists.txt file, after `cmake_minimum_required(X.XX)` and before anything else.

### XDK

The path to the root of your vendor SDK (XDK, the directory with `/include/` and `/lib/`) must be provided if you have not copied its contents into `<path to OXDK>/xdk`. You can set this by either configuring with `-DOXDK_XDK_DIR=<path to XDK>` or by setting `OXDK_XDK_DIR` in your environment. If you have RXDK installed, this path will be `<path to RXDK>/xbox`.

## Usage

### Libs

Required and most common XDK libs are pulled into your project by default by setting the toolchain file, unused libs will be pruned at link time. If you need to link an XDK lib not provided by default, you can link them manually:
```cmake
target_link_libraries(target PRIVATE
    $ENV{OXDK_XDK_DIR}/lib/<name>.lib
)
```

SDLX and SDL2X are both bundled with OXDK, you can pull them into your project by declaring `include("<path to OXDK>/cmake/sdlx.cmake")` and `include("<path to OXDK>/cmake/sdl2x.cmake")` respectively. Add them to your target as you would a normal CMake library:
```cmake
target_link_libraries(target PRIVATE 
    Oxdk::sdlx 
    Oxdk::sdl2x
)
```

### Example CMakeLists.txt

```cmake
cmake_minimum_required(VERISON 3.5)

set(CMAKE_TOOLCHAIN_FILE "<path to OXDK>/cmake/toolchain.cmake")

project(myproject C CXX)

# ENV{OXDK_DIR} set automatically by the toolchain
include("$ENV{OXDK_DIR}/cmake/sdl2x.cmake")

add_executable(myproject src/main.cpp)

target_link_libraries(myproject PRIVATE
    Oxdk::sdl2x
)

# generate .xbe, disc structure, and .iso post build
OxdkCreateDisc(myproject)
```

### Build

As an example, these commands will show you how to build the samples that come with OXDK.

Clone this repo
```
git clone --recursive https://github.com/MrMilenko/OXDK
```
Cd into the samples folder
```
cd OXDK/samples
```
Configure (if all required paths are available in default locations)
```
cmake -S . -B build -G Ninja -DCMAKE_TOOLCHAIN_FILE="../cmake/toolchain.cmake"
```
If you need to provide more paths for OXDK, instead use
```
cmake -S . -B build -G Ninja -DCMAKE_TOOLCHAIN_FILE="../cmake/toolchain.cmake" -DOXDK_XDK_DIR="<path to XDK>" -DOXDK_LLVM_DIR="<path to LLVM with libc++>" -DOXDK_LINKER="<path to linker>"
```

Build
```
cmake --build build
```

## API

```cmake
OxdkCreateDisc(<EXECUTABLE_TARGET_NAME> 
               [DISC_NAME <name>] 
               [TITLE_NAME <name>] 
               [MODE <RETAIL|DEBUG>])
```
Create a disc structure from an executable, needed to ensure `.xbe` and `.iso` files are created post build. Should be invoked after declaring `add_executable(<EXECUTABLE_TARGET_NAME>)` in your CMakeLists.txt file. Disc can be found in `<CMAKE_BINARY_DIRECTORY>/discs/<DISC_NAME>` post build. 
- **EXECUTABLE_TARGET_NAME** Required, the executable target that will be turned into `<DISC_NAME>/default.xbe`.
- **TITLE_NAME** Optional, the title name of the executable, to be embedded in the resulting .xbe. Defaults to `<EXECUTABLE_TARGET_NAME>`.
- **DISC_NAME** Optional, the name of the disc. Defaults to `<TITLE_NAME>`.
- **MODE** Optional, specifies retail or devkit xbe linkage/import table. Defaults to `RETAIL`.
##
```cmake
OxdkAddResource(<EXECUTABLE_TARGET_NAME> 
                [DISC_NAME <name>] 
                [FILE_PATH <path>] 
                [DISC_PATH <path>])
```
Add a resource file to your disc structure. Should be invoked after declaring `OxdkCreateDisc(<EXECUTABLE_TARGET_NAME>)` in your CMakeLists.txt file.
- **EXECUTABLE_TARGET_NAME** Required, the executable (default.xbe) on the disc.
- **DISC_NAME** Required if different from `<EXECUTABLE_TARGET_NAME>`.
- **FILE_PATH** Required, path to file to be copied to the disc structure.
- **DISC_PATH** Optional, the relative path in the disc structure where the file should be copied. Defaults to the root of the disc.
##
```cmake
OxdkAddResources(<EXECUTABLE_TARGET_NAME>
                 [DISC_NAME <name>]
                 [DIRECTORY] <path>
                 [BASE_DIRECTORY] <path>)
```
Copy a directory structure to the root of the disc. Should be invoked after declaring `OxdkCreateDisc(<EXECUTABLE_TARGET_NAME>)` in your CMakeLists.txt file.
- **EXECUTABLE_TARGET_NAME** Required, the executable (default.xbe) on the disc.
- **DISC_NAME** Required if different from `<EXECUTABLE_TARGET_NAME>`.
- **DIRECTORY** Required, the directory to be copied to the disc.
- **BASE_DIRECTORY** Optional, the root path to be trimmed from `<DIRECTORY>`, defaults to `<DIRECTORY>`.