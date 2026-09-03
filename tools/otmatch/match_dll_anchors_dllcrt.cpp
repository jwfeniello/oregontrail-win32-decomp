// VC4 LIBCMT DLL-startup reference anchors.
//
// The DLL-side CRT entry point and initializer (_DllMainCRTStartup@12 and
// _CRT_INIT@12) live in LIBCMT:dllcrt0.obj. That object's symbols
// (__wenvptr, __aenvptr, __error_mode, __aexit_rtn) collide with the same
// symbols in LIBCMT:crt0.obj, which __amsg_exit pulls in via wincrt0.obj.
//
// So we can't anchor dllcrt0 in either match_dll_anchors.cpp (LIBC, no
// dllcrt at all) or match_dll_anchors_lcmt.cpp (LIBCMT + wincrt0). This
// third candidate DLL pulls dllcrt0 alone, with nothing that triggers
// crt0/wincrt0. Manifest rows that need dllcrt0 bytes set
// candidate_dll=dllcrt to resolve through it.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#pragma comment(lib, "LIBCMT.LIB")
#pragma comment(lib, "KERNEL32.LIB")

#pragma comment(linker, "/include:__DllMainCRTStartup@12")
// _CRT_INIT@12 is pulled transitively by _DllMainCRTStartup; both are in
// dllcrt0.obj, so no explicit /include needed.

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
