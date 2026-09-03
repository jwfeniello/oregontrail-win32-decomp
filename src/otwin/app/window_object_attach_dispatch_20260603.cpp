// Product-tree semantic closure for FUN_00405a40_00005a40.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include <string.h>
#include "application_runtime_lifecycle.h"

#pragma intrinsic(strlen, strcpy, strcat)

typedef void* HMODULE_00405a40;
typedef void* HWND_00405a40;
typedef int (__stdcall *EnumWindowsProc_00405a40)(
    HWND_00405a40 window,
    long param);

extern "C" __declspec(dllimport) unsigned long __stdcall GetModuleFileNameA(
    HMODULE_00405a40 module,
    char* filename,
    unsigned long size);
extern "C" __declspec(dllimport) int __stdcall EnumWindows(
    EnumWindowsProc_00405a40 callback,
    long param);
extern "C" __declspec(dllimport) HWND_00405a40 __stdcall GetLastActivePopup(
    HWND_00405a40 window);
extern "C" __declspec(dllimport) int __stdcall ShowWindow(
    HWND_00405a40 window,
    int command_show);
extern "C" __declspec(dllimport) HWND_00405a40 __stdcall SetActiveWindow(
    HWND_00405a40 window);

extern "C" int __stdcall OtCaptureMatchingWindowOwner_RealCpp(
    HWND_00405a40 window,
    long previous_instance);
extern "C" unsigned int __cdecl
    OtRunApplicationMessagePump_00402ed0_RealCpp();
extern void* __cdecl operator new(unsigned int bytes);

extern "C" HMODULE_00405a40 g_applicationModule_00405a40_20260603 = 0;
extern "C" void* g_previousInstance_00405a40_20260603 = 0;
extern "C" int g_initialShowCommand_00405a40_20260603 = 0;
extern "C" char g_applicationDirectory_00405a40_20260603[0x50] = { 0 };
extern "C" char* g_helpFilePath_00405a40_20260603 = 0;
extern "C" const char g_helpFileName_00405a40_20260603[] = "oregon.hlp";
extern "C" EnumWindowsProc_00405a40
    g_previousInstanceEnumProc_00405a40_20260603 = 0;
extern "C" HWND_00405a40 g_previousInstanceWindow_00405a40_20260603 = 0;

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" int __stdcall OtWindowObjectAttachDispatch_00405a40_RealCpp(
    HMODULE_00405a40 module,
    void* previous_instance,
    char* command_line,
    int command_show)
{
    if (previous_instance != 0) {
        g_previousInstanceEnumProc_00405a40_20260603 =
            OtCaptureMatchingWindowOwner_RealCpp;
        EnumWindows(
            OtCaptureMatchingWindowOwner_RealCpp,
            (long)previous_instance);

        if (g_previousInstanceWindow_00405a40_20260603 == 0) {
            return 0;
        }

        g_previousInstanceWindow_00405a40_20260603 =
            GetLastActivePopup(g_previousInstanceWindow_00405a40_20260603);
        ShowWindow(g_previousInstanceWindow_00405a40_20260603, 1);
        SetActiveWindow(g_previousInstanceWindow_00405a40_20260603);
        return 0;
    }

    g_applicationModule_00405a40_20260603 = module;
    g_previousInstance_00405a40_20260603 = previous_instance;
    g_initialShowCommand_00405a40_20260603 = command_show;

    GetModuleFileNameA(module, g_applicationDirectory_00405a40_20260603, 0x50);

    int directory_length = strlen(g_applicationDirectory_00405a40_20260603);
    if (directory_length > 0) {
        do {
            if (g_applicationDirectory_00405a40_20260603[directory_length] == '\\') {
                g_applicationDirectory_00405a40_20260603[directory_length + 1] = 0;
                break;
            }
            --directory_length;
        } while (directory_length > 0);
    }

    char* help_path =
        (char*)operator new(strlen(g_applicationDirectory_00405a40_20260603) + 11);
    g_helpFilePath_00405a40_20260603 = help_path;
    strcpy(help_path, g_applicationDirectory_00405a40_20260603);
    strcat(help_path, g_helpFileName_00405a40_20260603);

    MainWindowRuntimeObject_00405a40 runtime;
    int result = (int)OtRunApplicationMessagePump_00402ed0_RealCpp();
    return result;
}

extern "C" __declspec(dllimport) HWND_00405a40 __stdcall GetParent(
    HWND_00405a40 window);
extern "C" __declspec(dllimport) long __stdcall GetWindowLongA(
    HWND_00405a40 window,
    int index);

#pragma comment(lib, "user32.lib")

#pragma code_seg(".otsem")
extern "C" int __stdcall OtCaptureMatchingWindowOwner_RealCpp(
    HWND_00405a40 window,
    long expected_owner)
{
    if (GetParent(window) == 0 &&
        GetWindowLongA(window, -6) == expected_owner) {
        g_previousInstanceWindow_00405a40_20260603 = window;
        return 0;
    }

    return 1;
}
#pragma code_seg()

#pragma optimize("", on)
