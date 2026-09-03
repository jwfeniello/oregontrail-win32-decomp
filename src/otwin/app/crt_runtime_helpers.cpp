#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

extern "C" unsigned int g_crtRandState;
extern "C" int __error_mode;
extern "C" int __lc_codepage;

extern "C" long __cdecl atol(const char* text);
extern "C" void* __cdecl _getstream();
extern "C" void* __cdecl _openfile(
    const char* path,
    const char* mode,
    int share_flag,
    void* stream);
extern "C" void __cdecl _FF_MSGBANNER();
extern "C" void __cdecl _NMSG_WRITE(int message_id);
extern "C" void __cdecl free(void* block);

extern "C" __declspec(dllimport) void __stdcall ExitProcess(
    unsigned int exit_code);
extern "C" __declspec(dllimport) int __stdcall IsBadReadPtr(
    const void* pointer,
    unsigned int size);
extern "C" __declspec(dllimport) int __stdcall IsBadStringPtrA(
    const void* pointer,
    unsigned int size);
extern "C" __declspec(dllimport) int __stdcall IsBadWritePtr(
    void* pointer,
    unsigned int size);
extern "C" __declspec(dllimport) int __stdcall IsBadCodePtr(
    const void* pointer);
extern "C" __declspec(dllimport) unsigned int __stdcall GetACP();
extern "C" __declspec(dllimport) unsigned int __stdcall GetOEMCP();

#pragma comment(lib, "kernel32.lib")

#pragma pack(push, 1)
struct OtCrtStream_00432030 {
    char* cursor;
    int count;
    char* base;
    int flags;
};
#pragma pack(pop)

#pragma data_seg(".otdat")
extern "C" int g_crtCodePageUsesSystemDefault_00433f00 = 0;
#pragma data_seg()

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" int __cdecl OtCrtRand_RealCpp()
{
    g_crtRandState = g_crtRandState * 214013u + 2531011u;
    return static_cast<int>((g_crtRandState & 0x7fff0000u) >> 16);
}

extern "C" int __cdecl OtAtoi_RealCpp(const char* text)
{
    return static_cast<int>(atol(text));
}

extern "C" int __cdecl OtValidateRead_RealCpp(
    const void* pointer,
    unsigned int size)
{
    int valid = 1;
    if (IsBadReadPtr(pointer, size) != 0) {
        valid = 0;
    }
    return valid;
}

extern "C" int __cdecl OtValidateWrite_RealCpp(
    void* pointer,
    unsigned int size)
{
    int valid = 1;
    if (IsBadWritePtr(pointer, size) != 0) {
        valid = 0;
    }
    return valid;
}

extern "C" int __cdecl OtValidateExecute_RealCpp(const void* pointer)
{
    int valid = 1;
    if (IsBadCodePtr(pointer) != 0) {
        valid = 0;
    }
    return valid;
}

extern "C" void* __cdecl OtFsOpen_RealCpp(
    const char* path,
    const char* mode,
    int share_flag)
{
    void* stream = _getstream();
    if (stream == 0) {
        return 0;
    }
    return _openfile(path, mode, share_flag, stream);
}

extern "C" void __cdecl OtCrtRuntimeMessageExit_RealCpp(int message_id)
{
    if (__error_mode == 1) {
        _FF_MSGBANNER();
    }
    _NMSG_WRITE(message_id);
    ExitProcess(0xff);
}

extern "C" void __cdecl __freebuf_RealCpp(OtCrtStream_00432030* stream)
{
    int flags = stream->flags;
    if ((flags & 0x83) != 0 && (flags & 8) != 0) {
        free(stream->base);
        stream->cursor = 0;
        stream->flags &= 0xfffffbf7;
        stream->base = 0;
        stream->count = 0;
    }
}

extern "C" unsigned int __cdecl getSystemCP_RealCpp(int code_page)
{
    g_crtCodePageUsesSystemDefault_00433f00 = 0;
    if (code_page == -2) {
        g_crtCodePageUsesSystemDefault_00433f00 = 1;
        return GetOEMCP();
    }
    if (code_page == -3) {
        g_crtCodePageUsesSystemDefault_00433f00 = 1;
        return GetACP();
    }
    if (code_page == -4) {
        g_crtCodePageUsesSystemDefault_00433f00 = 1;
        return static_cast<unsigned int>(__lc_codepage);
    }
    return static_cast<unsigned int>(code_page);
}

extern "C" unsigned int __cdecl _CPtoLCID_RealCpp(unsigned int code_page)
{
    switch (code_page) {
    case 932:
        return 0x411;
    case 936:
        return 0x804;
    case 949:
        return 0x412;
    case 950:
        return 0x404;
    default:
        return 0;
    }
}

#pragma optimize("", on)
