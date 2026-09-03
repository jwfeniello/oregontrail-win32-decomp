// Semantic recovery for FUN_0040cb20 / save trail journal as text.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include <string.h>
#include "active_text_runtime.h"

#pragma intrinsic(memcpy, memset, strlen)

typedef void* HWND_0040cb20;
typedef void* HANDLE_0040cb20;
typedef unsigned long DWORD_0040cb20;
typedef long LPARAM_0040cb20;

#pragma pack(push, 1)
struct OpenFileNameA_0040cb20 {
    DWORD_0040cb20 lStructSize;
    HWND_0040cb20 hwndOwner;
    void* hInstance;
    const char* lpstrFilter;
    char* lpstrCustomFilter;
    DWORD_0040cb20 nMaxCustFilter;
    DWORD_0040cb20 nFilterIndex;
    char* lpstrFile;
    DWORD_0040cb20 nMaxFile;
    char* lpstrFileTitle;
    DWORD_0040cb20 nMaxFileTitle;
    const char* lpstrInitialDir;
    const char* lpstrTitle;
    DWORD_0040cb20 Flags;
    unsigned short nFileOffset;
    unsigned short nFileExtension;
    const char* lpstrDefExt;
    LPARAM_0040cb20 lCustData;
    void* lpfnHook;
    const char* lpTemplateName;
};

struct SavedGameTextExportFrame_0040cb20 {
    DWORD_0040cb20 bytes_written;
    OpenFileNameA_0040cb20 open_name;
    char filter[28];
    char file_name[0x100];
    char initial_dir[0x100];
    char file_title[0x100];
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
extern "C" __declspec(dllimport) char* __stdcall lstrcatA(
    char* destination,
    const char* source);
extern "C" __declspec(dllimport) HANDLE_0040cb20 __stdcall CreateFileA(
    const char* file_name,
    DWORD_0040cb20 desired_access,
    DWORD_0040cb20 share_mode,
    void* security_attributes,
    DWORD_0040cb20 creation_disposition,
    DWORD_0040cb20 flags_and_attributes,
    HANDLE_0040cb20 template_file);
extern "C" __declspec(dllimport) void* __stdcall GlobalLock(void* handle);
extern "C" __declspec(dllimport) int __stdcall GlobalUnlock(void* handle);
extern "C" __declspec(dllimport) int __stdcall WriteFile(
    HANDLE_0040cb20 file,
    const void* buffer,
    DWORD_0040cb20 bytes_to_write,
    DWORD_0040cb20* bytes_written,
    void* overlapped);
extern "C" __declspec(dllimport) int __stdcall GetWindowTextA(
    HWND_0040cb20 window,
    char* text,
    int max_count);
extern "C" __declspec(dllimport) int __stdcall CloseHandle(
    HANDLE_0040cb20 handle);

#pragma comment(lib, "kernel32.lib")

extern "C" int __stdcall OtImportGetSaveFileNameA_RealCpp(
    OpenFileNameA_0040cb20* open_name);
extern "C" unsigned int __cdecl OtGetActiveTextLength_0040c790_RealCpp();
extern "C" int __cdecl OtCheckDiskFreeSpaceForSave_0040c7e0_RealCpp(
    char drive_letter,
    long required_bytes);
extern "C" void* __cdecl OtAllocateNewBlock_RealCpp(unsigned int size);
extern void __cdecl operator delete(void* block);

extern "C" int g_activeTextUsesEditControl;
extern "C" HWND_0040cb20 g_activeTextEditWindow;
#define DAT_004399d8_0040cb20 g_activeTextUsesEditControl
#define DAT_004399dc_0040cb20 g_activeTextEditWindow
#define DAT_004399e0_0040cb20 g_activeTextGlobalHandle_Product
extern "C" const char* PTR_s_oregon_ini_004390dc_0040cb20 = "oregon.ini";

extern "C" const char g_gameConfiguration_0040cb20[] = "Game Configuration";
extern "C" const char g_gameDir_0040cb20[] = "Game Dir";
extern "C" const char g_emptyString_0040cb20[] = "";
extern "C" const char g_textFileFilter_0040cb20[26] =
    "Text files (*.TXT)\0*.TXT\0";
extern "C" const char g_textFileDefExt_0040cb20[] = "TXT";
extern "C" const char g_saveJournalTextTitle_0040cb20[] =
    "Save the Trail Journal as Text";
extern "C" const char g_fileExtensionDot_0040cb20[] = ".";

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" int __cdecl OtSavedGameTextExport_0000cb20_RealCpp(
    HWND_0040cb20 owner_window)
{
    SavedGameTextExportFrame_0040cb20 frame;
    register int result;
    register HANDLE_0040cb20 file;
    register DWORD_0040cb20 bytes_to_write;
    char* edit_text;
    void* locked_text;

    memcpy(frame.filter, g_textFileFilter_0040cb20, 26);
    result = 0;
    memset(&frame.open_name, 0, sizeof(frame.open_name));

    GetPrivateProfileStringA(
        g_gameConfiguration_0040cb20,
        g_gameDir_0040cb20,
        g_emptyString_0040cb20,
        frame.initial_dir,
        0x100,
        PTR_s_oregon_ini_004390dc_0040cb20);

    frame.file_name[0] = 0;
    frame.open_name.hwndOwner = owner_window;
    frame.open_name.lpstrFilter = frame.filter;
    frame.open_name.lpstrFile = frame.file_name;
    frame.open_name.nMaxFile = 0x100;
    frame.open_name.lpstrFileTitle = frame.file_title;
    frame.open_name.nMaxFileTitle = 0x100;
    frame.open_name.lStructSize = sizeof(frame.open_name);
    frame.open_name.lpstrInitialDir = frame.initial_dir;
    frame.open_name.lpstrDefExt = g_textFileDefExt_0040cb20;
    frame.open_name.lpstrTitle = g_saveJournalTextTitle_0040cb20;
    frame.open_name.Flags = 0x880e;

    if (OtImportGetSaveFileNameA_RealCpp(&frame.open_name) != 0) {
        bytes_to_write = OtGetActiveTextLength_0040c790_RealCpp();
        if (OtCheckDiskFreeSpaceForSave_0040c7e0_RealCpp(
                *frame.open_name.lpstrFile,
                bytes_to_write) == 0) {
            return 0;
        }

        if (frame.open_name.nFileExtension == 0) {
            strlen(frame.open_name.lpstrFile);
            lstrcatA(frame.open_name.lpstrFile, g_fileExtensionDot_0040cb20);
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

        if (file != (HANDLE_0040cb20)-1) {
            if (DAT_004399d8_0040cb20 != 0) {
                edit_text =
                    (char*)OtAllocateNewBlock_RealCpp(bytes_to_write + 1);
                GetWindowTextA(
                    DAT_004399dc_0040cb20,
                    edit_text,
                    bytes_to_write);
                WriteFile(
                    file,
                    edit_text,
                    bytes_to_write,
                    &frame.bytes_written,
                        0);
                operator delete(edit_text);
            } else if (DAT_004399e0_0040cb20 != 0) {
                locked_text = GlobalLock(DAT_004399e0_0040cb20);
                WriteFile(
                    file,
                    locked_text,
                    bytes_to_write,
                    &frame.bytes_written,
                    0);
                GlobalUnlock(DAT_004399e0_0040cb20);
            }

            CloseHandle(file);
            result = 1;
        }
    }

    return result;
}

#pragma optimize("", on)
