# OXDK Notes

The non-obvious things that make OXDK work, and what to check when something
breaks. If you just want to build, include `oxdk.mk` and look at `samples/`;
it already handles everything below. This file is the "why" behind it.

## Background

Compiling 2003-era Xbox code used to mean a Windows VM and Visual Studio .NET
2003. clang can target `-target i386-pc-windows-msvc` (Pentium III, MSVC ABI,
PE/COFF) and lld-link reads MSVC COFF libraries, so you can build against the
real Microsoft XDK from macOS or Linux. There are a handful of sharp edges.
Here they are.

## The flag you cannot skip: stdcall

The XDK compiles everything with MSVC `/Gz`, making `__stdcall` the default
calling convention (the callee cleans the stack). clang defaults to `__cdecl`
(the caller cleans). Mix the two and the stack pointer drifts four bytes per
argument per call until something corrupts. The symptoms are random crashes
with no error message, which makes it brutal to find.

Fix: `-Xclang -fdefault-calling-conv=stdcall`. oxdk.mk sets it for both C and
C++ so calls across translation units agree (asymmetric defaults broke samples
like testgamecontroller). Variadic functions stay cdecl regardless, which is
correct.

## XDK header ordering: xdk_compat.h

The XDK headers expect MSVC include ordering. NT kernel types (`NTSTATUS`,
`STRING`, `OBJECT_ATTRIBUTES`) must exist before `xtl.h` reaches `winbase.h`.
MSVC's precompiled headers did this implicitly; clang needs help. `xdk_compat.h`
is force-included (`-include`) to pull the NT types in the right order and set
the guards that stop the XDK headers from redefining them.

## Kernel import decoration

`xboxkrnl.lib` exports stdcall-decorated names (`_HalReturnToFirmware@4`); clang
emits undecorated imports (`__imp__HalReturnToFirmware`), and lld-link cannot
match them. oxdk.mk carries `/alternatename` mappings for the common kernel
functions. Call one that is not mapped and you get an undefined symbol; add:

```
/alternatename:__imp__YourFunction=__imp__YourFunction@N
```

where `N` is the parameter size in bytes (one DWORD is 4).

## PE to XBE: cxbe

Xbox executables are XBE, not PE. cxbe (from nxdk) does the conversion. Two
tweaks were needed for XDK-linked binaries: every section is marked executable,
and the library version table is read from the PE's `.XBLD` section instead of
a placeholder so the kernel initializes D3D, DirectSound, and XNet. Both
changes landed in the same session as the stdcall fix and were never isolated,
so one of them may be unnecessary. Test one thing at a time.

## Modern C++: the STL situation

The XDK ships MSVC 7.1's STL, which is C++98. There is no `<type_traits>`,
`<random>`, `<unordered_map>`, `<chrono>`, and so on, and it uses pre-C++17
constructs (dynamic exception specifications) that current clang rejects.
Do not fight it.

Set `OXDK_LIBCXX=1` instead. OXDK routes the whole C++ standard library to
LLVM's libc++ layered over the XDK CRT, giving you real C++17. The support
files are in `oxdk/`: a target-tuned `__config_site`, clean C-header shims so
libc++ and the XDK headers coexist, and the few runtime symbols libc++ expects
from its prebuilt library. `samples/libcxx/cxx17_hello` and `samples/sdl2x/scene`
build this way. You need libc++ headers on the host (`brew install llvm` on
macOS, or point `OXDK_LIBCXX_DIR` at your `include/c++/v1`).

Two things to know about libc++ mode:

- It raises MSVC-compat to 19.00 (`char16_t` / `char32_t` are keywords only
  there) and reorders includes so libc++ wins over the XDK's C-but-also-C++
  headers.
- It builds with `-fno-exceptions`. clang emits the v3 exception personality
  but the MSVC 7.1 CRT only has v1, and the unwind ABIs are incompatible, so
  throws become aborts.

## Black screens are usually not crashes

- **Debug libraries assert.** `dsoundd.lib` and `d3d8d.lib` call `RtlAssert`,
  which halts the thread with no debugger attached and looks exactly like a
  hang. Link the release libs (`dsound.lib`, `d3d8.lib`) for clean runs.
- **Stack too small.** Use `/stack:1048576` (1MB). 64KB overflows during boot
  before any crash handler exists.

## Case sensitivity (Linux and case-sensitive filesystems)

Two versions of the same problem:

- The XDK ships mixed-case filenames (`XTL.H`, `D3d8.h`) but source includes
  them lowercase. macOS does not care; Linux does. Run
  `tools/normalize-xdk.sh xdk/` once to lowercase the tree (it is a no-op on
  case-insensitive filesystems and detects genuine collisions), or
  `make normalize-xdk`.
- If your own source has a filename that collides with a system header modulo
  case (Theseus had `Locale.h` versus the CRT's `locale.h`), use `-iquote` for
  your source directory so angle-bracket includes skip it.

## Where to go from here

- Include `oxdk.mk` and copy `Makefile.template`; it applies everything above.
- `samples/` has working builds per library: `d3d/`, `libsdlx/`, `sdl2x/`,
  `libcxx/`.
- For SDL 2, `third-party/SDL2x/oxdk/sdl2x.mk` builds any libSDL2x consumer;
  the sample Makefiles are about fifteen lines each.
- For modern C++, set `OXDK_LIBCXX=1`.

OXDK was built to compile the Xbox side of [Theseus](https://github.com/MrMilenko/Theseus),
the reverse-engineered Xbox Dashboard engine that also powers UIX Desktop on
macOS, Linux, and Windows. Tested on real hardware by [TeamUIX](https://github.com/OfficialTeamUIX).
