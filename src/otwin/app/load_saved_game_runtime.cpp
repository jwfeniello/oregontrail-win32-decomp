// Canonical product WIP for Oregon32.exe!OtLoadSavedGameFromDialog
// (RVA 0x0000c4e0). Every dependency is a real product/API/VC4 CRT body.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

#include "active_text_runtime.h"
#include <string.h>

#pragma intrinsic(memcpy, memset, strcmp)

typedef void* HWND_0040c4e0_Product;
typedef void* HANDLE_0040c4e0_Product;
typedef unsigned long DWORD_0040c4e0_Product;

#pragma pack(push, 1)
struct OpenFileNameA_0040c4e0_Product {
    DWORD_0040c4e0_Product lStructSize;
    HWND_0040c4e0_Product hwndOwner;
    void* hInstance;
    const char* lpstrFilter;
    char* lpstrCustomFilter;
    DWORD_0040c4e0_Product nMaxCustFilter;
    DWORD_0040c4e0_Product nFilterIndex;
    char* lpstrFile;
    DWORD_0040c4e0_Product nMaxFile;
    char* lpstrFileTitle;
    DWORD_0040c4e0_Product nMaxFileTitle;
    const char* lpstrInitialDir;
    const char* lpstrTitle;
    DWORD_0040c4e0_Product Flags;
    unsigned short nFileOffset;
    unsigned short nFileExtension;
    const char* lpstrDefExt;
    long lCustData;
    void* lpfnHook;
    const char* lpTemplateName;
};

struct JourneyStateDefaults_0041a000_20260525 {
    void OtJourneyInitStateDefaultsMaskClosedFELTDR_0041a000();
};

struct TrailCalendarNameTriple_00419430 {
    char day_name[5];
    char month_name[0x40];
    char year_name[0x20];

    TrailCalendarNameTriple_00419430* OtCopyTrailDateNameTriple_RealCpp();
    int OtMatchTrailDateNameTriple_RealCpp();
};

struct JourneyState_0040c4e0_Product {
    char reserved_000[0x8e];
    short route_segment_id;
    char reserved_090[0xc8];

    JourneyState_0040c4e0_Product()
    {
        reinterpret_cast<TrailCalendarNameTriple_00419430*>(this)->
            OtCopyTrailDateNameTriple_RealCpp();
    }
};

typedef char JourneyState_0040c4e0_Product_must_be_0x158_bytes[
    sizeof(JourneyState_0040c4e0_Product) == 0x158 ? 1 : -1];
#pragma pack(pop)

extern "C" JourneyState_0040c4e0_Product* g_journeyState;
extern "C" void* g_activeRouteDescriptor;
extern "C" char DAT_00439650_0040c880[0x104];
extern "C" const char* PTR_s_oregon_ini_004390dc;

extern "C" void __stdcall OtLoadRouteDescriptor_RealCpp(short route_id);

extern "C" __declspec(dllimport) int __stdcall GetOpenFileNameA(
    OpenFileNameA_0040c4e0_Product* open_file_name);
extern "C" __declspec(dllimport) HANDLE_0040c4e0_Product __stdcall CreateFileA(
    const char* file_name,
    DWORD_0040c4e0_Product desired_access,
    DWORD_0040c4e0_Product share_mode,
    void* security_attributes,
    DWORD_0040c4e0_Product creation_disposition,
    DWORD_0040c4e0_Product flags_and_attributes,
    HANDLE_0040c4e0_Product template_file);
extern "C" __declspec(dllimport) int __stdcall ReadFile(
    HANDLE_0040c4e0_Product file,
    void* buffer,
    DWORD_0040c4e0_Product bytes_to_read,
    DWORD_0040c4e0_Product* bytes_read,
    void* overlapped);
extern "C" __declspec(dllimport) int __stdcall CloseHandle(
    HANDLE_0040c4e0_Product handle);
extern "C" __declspec(dllimport) void* __stdcall GlobalLock(void* handle);
extern "C" __declspec(dllimport) int __stdcall GlobalUnlock(void* handle);
extern "C" __declspec(dllimport) int __stdcall MessageBoxA(
    HWND_0040c4e0_Product window,
    const char* text,
    const char* caption,
    unsigned int type);
extern "C" __declspec(dllimport) unsigned long __stdcall
GetPrivateProfileStringA(
    const char* section,
    const char* key,
    const char* default_value,
    char* returned_string,
    DWORD_0040c4e0_Product size,
    const char* file_name);
extern "C" __declspec(dllimport) int __stdcall WritePrivateProfileStringA(
    const char* section,
    const char* key,
    const char* string_value,
    const char* file_name);

extern "C" char* __cdecl strncpy(
    char* destination,
    const char* source,
    unsigned int count);
extern void* __cdecl operator new(unsigned int bytes);
extern void __cdecl operator delete(void* block);

#pragma comment(lib, "comdlg32.lib")
#pragma comment(lib, "kernel32.lib")
#pragma comment(lib, "user32.lib")

#pragma code_seg(".otsem")
extern "C" __declspec(allocate(".otsem"))
const char g_loadGameEmptyString_0040c4e0[] = "";
extern "C" __declspec(allocate(".otsem"))
const char g_oregonTrailCaption_0040c4e0[] = "The Oregon Trail";
extern "C" __declspec(allocate(".otsem"))
const char g_loadGameConfiguration_0040c4e0[] = "Game Configuration";
extern "C" __declspec(allocate(".otsem"))
const char g_loadGameDir_0040c4e0[] = "Game Dir";
extern "C" __declspec(allocate(".otsem"))
const char g_loadSaveDefExt_0040c4e0[] = "SAV";
extern "C" __declspec(allocate(".otsem"))
const char g_loadSavedGameTitle_0040c4e0[] = "Load a Saved Game";
extern "C" __declspec(allocate(".otsem"))
const char g_unreadableSavedGameText_0040c4e0[] =
    "This saved game is unreadable.";
extern "C" __declspec(allocate(".otsem"))
const char g_notOregonTrailSaveText_0040c4e0[] =
    "The file is not an Oregon Trail file.";
extern "C" __declspec(allocate(".otsem"))
const char g_savedGameFilter_0040c4e0[27] =
    "Oregon Trail games\0*.SAV\0";

#pragma optimize("s", off)
#pragma optimize("t", on)
extern "C" int __cdecl OtLoadSavedGameFromDialog_0000c4e0_Wip(
    HWND_0040c4e0_Product owner_window)
{
    char file_title[0x104];
    char initial_dir[0x104];
    char file_name[0x104];
    char filter_text[27];
    OpenFileNameA_0040c4e0_Product open_file_name;
    DWORD_0040c4e0_Product bytes_read;
    register HANDLE_0040c4e0_Product file;
    void* journal_text;
    register int zero;
    register int loaded;

    memcpy(filter_text, g_savedGameFilter_0040c4e0, 27);
    zero = 0;
    loaded = zero;
    memset(&open_file_name, 0, sizeof(open_file_name));

    GetPrivateProfileStringA(
        g_loadGameConfiguration_0040c4e0,
        g_loadGameDir_0040c4e0,
        g_loadGameEmptyString_0040c4e0,
        initial_dir,
        0x100,
        PTR_s_oregon_ini_004390dc);

    file_name[0] = static_cast<char>(zero);
    open_file_name.lStructSize = sizeof(open_file_name);
    open_file_name.hwndOwner = owner_window;
    open_file_name.lpstrFilter = filter_text;
    open_file_name.lpstrFile = file_name;
    open_file_name.nMaxFile = 0x104;
    open_file_name.lpstrFileTitle = file_title;
    open_file_name.nMaxFileTitle = 0x104;
    open_file_name.lpstrInitialDir = initial_dir;
    open_file_name.lpstrDefExt = g_loadSaveDefExt_0040c4e0;
    open_file_name.lpstrTitle = g_loadSavedGameTitle_0040c4e0;
    open_file_name.Flags = 0x100c;

    if (GetOpenFileNameA(&open_file_name) == 0) {
        return loaded;
    }

    file = CreateFileA(
        open_file_name.lpstrFile, 0x80000000, 1, 0, 3, 1, 0);
    if (file == reinterpret_cast<HANDLE_0040c4e0_Product>(-1)) {
        MessageBoxA(
            0,
            g_unreadableSavedGameText_0040c4e0,
            g_oregonTrailCaption_0040c4e0,
            0);
        return zero;
    }

    reinterpret_cast<JourneyStateDefaults_0041a000_20260525*>(
        g_journeyState)->
        OtJourneyInitStateDefaultsMaskClosedFELTDR_0041a000();

    if (ReadFile(file, g_journeyState, 0x158, &bytes_read, 0) == 0) {
        return zero;
    }

    journal_text = GlobalLock(g_activeTextGlobalHandle_Product);
    ReadFile(file, journal_text, 0x7d00, &bytes_read, 0);
    CloseHandle(file);

    if (bytes_read != 0) {
        --bytes_read;
        static_cast<char*>(journal_text)[bytes_read] = 0;
    }
    GlobalUnlock(g_activeTextGlobalHandle_Product);
    loaded = 1;

    OtLoadRouteDescriptor_RealCpp(g_journeyState->route_segment_id);

    if (reinterpret_cast<TrailCalendarNameTriple_00419430*>(
            g_journeyState)->OtMatchTrailDateNameTriple_RealCpp() == 0) {
        MessageBoxA(
            0,
            g_notOregonTrailSaveText_0040c4e0,
            g_oregonTrailCaption_0040c4e0,
            0);
        operator delete(g_journeyState);
        JourneyState_0040c4e0_Product* replacement_journey =
            new JourneyState_0040c4e0_Product;
        loaded = 0;
        g_journeyState = replacement_journey;
    } else {
        strncpy(
            DAT_00439650_0040c880,
            open_file_name.lpstrFileTitle,
            0x104);
        file_name[open_file_name.nFileOffset - 1] = 0;
        if (strcmp(file_name, initial_dir) != 0) {
            WritePrivateProfileStringA(
                g_loadGameConfiguration_0040c4e0,
                g_loadGameDir_0040c4e0,
                file_name,
                PTR_s_oregon_ini_004390dc);
        }
    }

    return loaded;
}
#pragma optimize("", on)
#pragma code_seg()
