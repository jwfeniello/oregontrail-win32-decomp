// VC4 runtime-library reference anchors for functions identified as compiler
// and CRT support code in the original executable.
//
// These are not byte-literal stubs. They deliberately pull the matching Visual
// C++ 4.0 CRT objects into the match-candidate DLL so the manifest can track
// which original ranges are toolchain/runtime code rather than game logic.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#pragma comment(lib, "LIBC.LIB")
#pragma comment(lib, "KERNEL32.LIB")
#pragma comment(lib, "COMDLG32.LIB")

#pragma comment(linker, "/include:?_CallMemberFunction0@@YGXPAX0@Z")
#pragma comment(linker, "/include:?__ArrayUnwind@@YGXPAXIHP6EX0@Z@Z")
#pragma comment(linker, "/include:_atol")
#pragma comment(linker, "/include:_strchr")
#pragma comment(linker, "/include:_strlen")
#pragma comment(linker, "/include:_strncpy")
#pragma comment(linker, "/include:__global_unwind2")
#pragma comment(linker, "/include:__local_unwind2")
#pragma comment(linker, "/include:__abnormal_termination")
#pragma comment(linker, "/include:___CxxFrameHandler")
#pragma comment(linker, "/include:___InternalCxxFrameHandler")
#pragma comment(linker, "/include:__CallSettingFrame@12")
#pragma comment(linker, "/include:_fclose")
#pragma comment(linker, "/include:_wprintf")
#pragma comment(linker, "/include:__isctype")
#pragma comment(linker, "/include:__close")
#pragma comment(linker, "/include:_fflush")
#pragma comment(linker, "/include:__flush")
#pragma comment(linker, "/include:__filbuf")
#pragma comment(linker, "/include:__openfile")
#pragma comment(linker, "/include:__getstream")
#pragma comment(linker, "/include:__seh_longjmp_unwind@4")
#pragma comment(linker, "/include:__stbuf")
#pragma comment(linker, "/include:__ftbuf")
#pragma comment(linker, "/include:__setargv")
#pragma comment(linker, "/include:___initmbctable")
#pragma comment(linker, "/include:___crtGetStringTypeA")
#pragma comment(linker, "/include:_abort")
#pragma comment(linker, "/include:__set_osfhnd")
#pragma comment(linker, "/include:__getbuf")
#pragma comment(linker, "/include:_wctomb")
#pragma comment(linker, "/include:__nh_malloc")
#pragma comment(linker, "/include:_malloc")
#pragma comment(linker, "/include:__callnewh")
#pragma comment(linker, "/include:__isatty")
#pragma comment(linker, "/include:__aulldiv")
#pragma comment(linker, "/include:__aullrem")
#pragma comment(linker, "/include:___crtMessageBoxA")
#pragma comment(linker, "/include:_raise")
#pragma comment(linker, "/include:__chsize")
#pragma comment(linker, "/include:__itoa")
#pragma comment(linker, "/include:__mbsnbicoll")
#pragma comment(linker, "/include:___wtomb_environ")
#pragma comment(linker, "/include:__mbschr")
#pragma comment(linker, "/include:__strdup")
#pragma comment(linker, "/include:__mbscpy")
#pragma comment(linker, "/include:__strlwr")
#pragma comment(linker, "/include:___crtLCMapStringA")
#pragma comment(linker, "/include:_strncat")
#pragma comment(linker, "/include:_strstr")
#pragma comment(linker, "/include:??3@YAXPAX@Z")
#pragma comment(linker, "/include:__fptrap")
#pragma comment(linker, "/include:_fread")
#pragma comment(linker, "/include:_time")
#pragma comment(linker, "/include:__isindst")
#pragma comment(linker, "/include:_free")
#pragma comment(linker, "/include:__heap_alloc")
#pragma comment(linker, "/include:__heap_init")
#pragma comment(linker, "/include:___tzset")
#pragma comment(linker, "/include:??_M@YGXPAXIHP6EX0@Z@Z")
#pragma comment(linker, "/include:___loctotime_t")
#pragma comment(linker, "/include:_getenv")
#pragma comment(linker, "/include:__setmode")
#pragma comment(linker, "/include:??_L@YGXPAXIHP6EX0@Z1@Z")
#pragma comment(linker, "/include:__get_osfhandle")
#pragma comment(linker, "/include:__alloc_osfhnd")
#pragma comment(linker, "/include:?terminate@@YAXXZ")
#pragma comment(linker, "/include:_calloc")
#pragma comment(linker, "/include:__cinit")
#pragma comment(linker, "/include:_realloc")
#pragma comment(linker, "/include:__setenvp")
#pragma comment(linker, "/include:__free_osfhnd")
#pragma comment(linker, "/include:__fcloseall")
#pragma comment(linker, "/include:__flsbuf")
#pragma comment(linker, "/include:__commit")
#pragma comment(linker, "/include:__lseek")
#pragma comment(linker, "/include:__dosmaperr")
#pragma comment(linker, "/include:_memmove")
#pragma comment(linker, "/include:__read")
#pragma comment(linker, "/include:__write")
#pragma comment(linker, "/include:___crtGetEnvironmentStringsA")
#pragma comment(linker, "/include:__ioinit")
#pragma comment(linker, "/include:__NMSG_WRITE")
#pragma comment(linker, "/include:___crtsetenv")
#pragma comment(linker, "/include:___crtCompareStringA")
#pragma comment(linker, "/include:__setmbcp")
#pragma comment(linker, "/include:__sopen")
#pragma comment(linker, "/include:__tzset")
#pragma comment(linker, "/include:__mbsnbcoll")
#pragma comment(linker, "/include:__chkstk")
#pragma comment(linker, "/include:_GetOpenFileNameA@4")
#pragma comment(linker, "/include:_GetSaveFileNameA@4")
#pragma comment(linker, "/include:_WinMainCRTStartup")

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
