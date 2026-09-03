// VC4 multi-threaded runtime-library reference anchors.
//
// OREGON32.DLL was linked against LIBCMT.LIB (the multi-threaded variant of
// the VC4 C runtime), as evidenced by the presence of __mtinit, __getptd,
// __lock, and other lock-bracketed CRT helpers in its .text. The default
// match-candidate DLL pulls LIBC.LIB (single-threaded), which produces
// different bytes for any function that includes lock acquire/release
// brackets or thread-local storage lookups.
//
// This file lives in a SEPARATE candidate DLL so LIBCMT and LIBC symbols
// don't collide (both libraries export the same names with different
// implementations). Build it via build-match-candidates.ps1's lcmt mode;
// reference its symbols from manifest rows by setting the candidate_dll
// column to "lcmt".

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#pragma comment(lib, "LIBCMT.LIB")
#pragma comment(lib, "KERNEL32.LIB")
#pragma comment(lib, "COMDLG32.LIB")

// CRT helpers that have OREGON32.DLL twin candidates and need LIBCMT bytes
// (rather than LIBC bytes) to match.
#pragma comment(linker, "/include:__amsg_exit")
#pragma comment(linker, "/include:_fclose")
#pragma comment(linker, "/include:__close")
#pragma comment(linker, "/include:__setargv")
#pragma comment(linker, "/include:___crtMessageBoxA")
#pragma comment(linker, "/include:__callnewh")
#pragma comment(linker, "/include:__dosmaperr")
#pragma comment(linker, "/include:__ioterm")
#pragma comment(linker, "/include:__write")
#pragma comment(linker, "/include:__free_osfhnd")
// Multi-threaded primitives the DLL also uses.
#pragma comment(linker, "/include:__mtinit")
#pragma comment(linker, "/include:__mtterm")
#pragma comment(linker, "/include:__mtinitlocks")
#pragma comment(linker, "/include:__mtdeletelocks")
#pragma comment(linker, "/include:__lock")
#pragma comment(linker, "/include:__unlock")
#pragma comment(linker, "/include:__lock_fhandle")
#pragma comment(linker, "/include:__unlock_fhandle")
#pragma comment(linker, "/include:__getptd")
#pragma comment(linker, "/include:__initptd")
#pragma comment(linker, "/include:__freeptd")
// Locked _lk variants of stdio CRT helpers.
#pragma comment(linker, "/include:__close_lk")
#pragma comment(linker, "/include:__fclose_lk")
#pragma comment(linker, "/include:__fflush_lk")
#pragma comment(linker, "/include:__lseek_lk")
#pragma comment(linker, "/include:__write_lk")
// _parse_cmdline is pulled transitively by __setargv (same stdargv.obj),
// so it's already addressable in the candidate map; no explicit /include
// needed.
//
// __DllMainCRTStartup@12 cannot be anchored alongside __amsg_exit: the
// former pulls dllcrt0.obj which duplicates crt0.obj's __wenvptr/__aenvptr.
// Probe DllMain support separately by dropping __amsg_exit or splitting
// into a third candidate DLL.

extern "C" int __cdecl main()
{
    return 0;
}

extern "C" int __cdecl wmain()
{
    return 0;
}

extern "C" int __stdcall WinMain(void*, void*, char*, int)
{
    return 0;
}

extern "C" int __stdcall wWinMain(void*, void*, unsigned short*, int)
{
    return 0;
}
