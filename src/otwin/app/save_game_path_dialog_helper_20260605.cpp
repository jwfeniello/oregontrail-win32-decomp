// Semantic recovery for FUN_0040c880 / save-game path dialog helper.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include <string.h>
#include "active_text_runtime.h"

#pragma intrinsic(memcpy, memset, strlen, strcpy, strcmp)

typedef void* HWND_0040c880;
typedef void* HANDLE_0040c880;
typedef unsigned long DWORD_0040c880;
typedef long LPARAM_0040c880;

#pragma pack(push, 1)
struct OpenFileNameA_0040c880 {
    DWORD_0040c880 lStructSize;
    HWND_0040c880 hwndOwner;
    void* hInstance;
    const char* lpstrFilter;
    char* lpstrCustomFilter;
    DWORD_0040c880 nMaxCustFilter;
    DWORD_0040c880 nFilterIndex;
    char* lpstrFile;
    DWORD_0040c880 nMaxFile;
    char* lpstrFileTitle;
    DWORD_0040c880 nMaxFileTitle;
    const char* lpstrInitialDir;
    const char* lpstrTitle;
    DWORD_0040c880 Flags;
    unsigned short nFileOffset;
    unsigned short nFileExtension;
    const char* lpstrDefExt;
    LPARAM_0040c880 lCustData;
    void* lpfnHook;
    const char* lpTemplateName;
};

struct SaveGamePathDialogFrame_0040c880 {
    DWORD_0040c880 bytes_written;
    OpenFileNameA_0040c880 open_name;
    char filter[28];
    char file_name[0x104];
    char initial_dir[0x104];
    char file_title[0x104];
};
#pragma pack(pop)

extern "C" __declspec(dllimport) unsigned long __stdcall
GetPrivateProfileStringA(
    const char* section,
    const char* key,
    const char* default_value,
    char* returned_string,
    unsigned long size,
    const char* file_name);
extern "C" __declspec(dllimport) int __stdcall
WritePrivateProfileStringA(
    const char* section,
    const char* key,
    const char* string,
    const char* file_name);
extern "C" __declspec(dllimport) char* __stdcall lstrcatA(
    char* destination,
    const char* source);
extern "C" __declspec(dllimport) HANDLE_0040c880 __stdcall CreateFileA(
    const char* file_name,
    DWORD_0040c880 desired_access,
    DWORD_0040c880 share_mode,
    void* security_attributes,
    DWORD_0040c880 creation_disposition,
    DWORD_0040c880 flags_and_attributes,
    HANDLE_0040c880 template_file);
extern "C" __declspec(dllimport) void* __stdcall GlobalLock(void* handle);
extern "C" __declspec(dllimport) int __stdcall GlobalUnlock(void* handle);
extern "C" __declspec(dllimport) int __stdcall WriteFile(
    HANDLE_0040c880 file,
    const void* buffer,
    DWORD_0040c880 bytes_to_write,
    DWORD_0040c880* bytes_written,
    void* overlapped);
extern "C" __declspec(dllimport) int __stdcall GetWindowTextA(
    HWND_0040c880 window,
    char* text,
    int max_count);
extern "C" __declspec(dllimport) int __stdcall CloseHandle(
    HANDLE_0040c880 handle);

#pragma comment(lib, "kernel32.lib")

extern "C" int __stdcall OtImportGetSaveFileNameA_RealCpp(
    OpenFileNameA_0040c880* open_name);
extern "C" unsigned int __cdecl OtGetActiveTextLength_0040c790_RealCpp();
extern "C" int __cdecl OtCheckDiskFreeSpaceForSave_0040c7e0_RealCpp(
    char drive_letter,
    long required_bytes);
extern "C" void* __cdecl OtAllocateNewBlock_RealCpp(unsigned int size);
extern void __cdecl operator delete(void* block);

extern "C" int g_activeTextUsesEditControl;
extern "C" HWND_0040c880 g_activeTextEditWindow;
extern "C" void* g_journeyState;
#define DAT_004399d8_0040c880 g_activeTextUsesEditControl
#define DAT_004399dc_0040c880 g_activeTextEditWindow
#define DAT_004399e0_0040c880 g_activeTextGlobalHandle_Product
#define DAT_00439d58_0040c880 g_journeyState
extern "C" char DAT_00439650_0040c880[0x104] = "";
extern "C" const char* PTR_s_oregon_ini_004390dc_0040c880 =
    "oregon.ini";

extern "C" const char g_gameConfiguration_0040c880[] =
    "Game Configuration";
extern "C" const char g_gameDir_0040c880[] = "Game Dir";
extern "C" const char g_emptyString_0040c880[] = "";
extern "C" const char g_saveGameFilter_0040c880[27] =
    "Oregon Trail games\0*.ORG\0";
extern "C" const char g_saveGameDefExt_0040c880[] = "ORG";
extern "C" const char g_saveCurrentGameTitle_0040c880[] =
    "Save the Current Game";
extern "C" const char g_fileExtensionDot_0040c880[] = ".";

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" int __cdecl OtSaveGamePathDialogHelper_0000c880_20260605_Wip(
    HWND_0040c880 owner_window)
{
    SaveGamePathDialogFrame_0040c880 frame;
    register int result;

    memcpy(frame.filter, g_saveGameFilter_0040c880, 27);
    result = 0;
    memset(&frame.open_name, 0, sizeof(frame.open_name));

    GetPrivateProfileStringA(
        g_gameConfiguration_0040c880,
        g_gameDir_0040c880,
        g_emptyString_0040c880,
        frame.initial_dir,
        0x100,
        PTR_s_oregon_ini_004390dc_0040c880);

    frame.file_name[0] = 0;
    frame.open_name.hwndOwner = owner_window;
    frame.open_name.lpstrFilter = frame.filter;
    frame.open_name.lpstrFile = frame.file_name;
    frame.open_name.nMaxFile = 0x104;
    frame.open_name.lpstrFileTitle = frame.file_title;
    frame.open_name.nMaxFileTitle = 0x104;
    frame.open_name.lpstrInitialDir = frame.initial_dir;
    frame.open_name.lStructSize = sizeof(frame.open_name);
    frame.open_name.lpstrDefExt = g_saveGameDefExt_0040c880;
    frame.open_name.lpstrTitle = g_saveCurrentGameTitle_0040c880;
    strcpy(frame.file_name, DAT_00439650_0040c880);
    frame.open_name.Flags = 0x880e;

    if (OtImportGetSaveFileNameA_RealCpp(&frame.open_name) != 0) {
        register HANDLE_0040c880 file;
        register DWORD_0040c880 bytes_to_write;
        char* edit_text;
        void* locked_text;

        strcpy(DAT_00439650_0040c880, frame.open_name.lpstrFileTitle);
        bytes_to_write = OtGetActiveTextLength_0040c790_RealCpp();
        if (OtCheckDiskFreeSpaceForSave_0040c7e0_RealCpp(
                *frame.open_name.lpstrFile,
                bytes_to_write + 0x158) == 0) {
            return 0;
        }

        if (frame.open_name.nFileExtension == 0) {
            strlen(frame.open_name.lpstrFile);
            lstrcatA(frame.open_name.lpstrFile, g_fileExtensionDot_0040c880);
            lstrcatA(frame.open_name.lpstrFile, frame.open_name.lpstrDefExt);
        }

        file = CreateFileA(
            frame.open_name.lpstrFile,
            0x40000000,
            0,
            0,
            2,
            0x80,
            0);

        if (file != (HANDLE_0040c880)-1) {
            WriteFile(
                file,
                DAT_00439d58_0040c880,
                0x158,
                &frame.bytes_written,
                0);

            if (DAT_004399d8_0040c880 != 0) {
                edit_text =
                    (char*)OtAllocateNewBlock_RealCpp(bytes_to_write + 1);
                GetWindowTextA(
                    DAT_004399dc_0040c880,
                    edit_text,
                    bytes_to_write);
                WriteFile(
                    file,
                    edit_text,
                    bytes_to_write,
                    &frame.bytes_written,
                    0);
                operator delete(edit_text);
            } else if (DAT_004399e0_0040c880 != 0) {
                locked_text = GlobalLock(DAT_004399e0_0040c880);
                WriteFile(
                    file,
                    locked_text,
                    bytes_to_write,
                    &frame.bytes_written,
                    0);
                GlobalUnlock(DAT_004399e0_0040c880);
            }

            CloseHandle(file);
            result = 1;
        }

        frame.file_name[frame.open_name.nFileOffset - 1] = 0;
        if (strcmp(frame.file_name, frame.initial_dir) != 0) {
            WritePrivateProfileStringA(
                g_gameConfiguration_0040c880,
                g_gameDir_0040c880,
                frame.file_name,
                PTR_s_oregon_ini_004390dc_0040c880);
        }
    }

    return result;
}

#pragma optimize("", on)
