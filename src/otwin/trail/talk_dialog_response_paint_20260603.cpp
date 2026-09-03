// Product-tree semantic closure for FUN_0041f8f0_0001f8f0.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include <string.h>

#pragma intrinsic(strcpy, strcat, strlen)

typedef void* HINSTANCE_0041f8f0;
typedef void* HWND_0041f8f0;
extern "C" __declspec(dllimport) int __stdcall LoadStringA(
    HINSTANCE_0041f8f0 instance,
    unsigned int resource_id,
    char* buffer,
    int buffer_count);

extern "C" unsigned int __cdecl strlen(const char* text);
extern "C" __declspec(dllimport) char* __stdcall CharLowerA(char* text);

extern "C" HINSTANCE_0041f8f0 g_applicationModule_00405a40_20260603;

extern "C" char g_talkDialogResponsePrefix_0041f8f0[] =
    "You don't have that many ";
extern "C" char g_talkDialogResponseSuffix_0041f8f0[] = ".";
extern "C" char g_talkDialogCaption_0041f8f0[] = "Can't Drop That Much";

extern "C" int __cdecl OtRunSharedMessageDialog_00401e70_RealCpp(
    HWND_0041f8f0 parent_window,
    void* message_text,
    void* caption_text,
    int use_alternate_template);

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" int __cdecl OtTalkDialogResponsePaint_0041f8f0_RealCpp(
    int response_id,
    HWND_0041f8f0 parent_window)
{
    char text[100];
    char* cursor;
    char* suffix;
    int remaining;

    strcpy(text, g_talkDialogResponsePrefix_0041f8f0);
    cursor = text + strlen(text);
    remaining = sizeof(text) - strlen(text);
    suffix = g_talkDialogResponseSuffix_0041f8f0;

    LoadStringA(
        g_applicationModule_00405a40_20260603,
        response_id + 0x1f4,
        cursor,
        remaining);

    CharLowerA(cursor);
    strcat(text, suffix);

    return OtRunSharedMessageDialog_00401e70_RealCpp(
        parent_window,
        text,
        const_cast<char*>(g_talkDialogCaption_0041f8f0),
        0);
}

#pragma optimize("", on)
