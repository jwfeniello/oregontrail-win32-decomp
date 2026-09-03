// Semantic recovery for the secondary application option toggle @ 0x00405770.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "app_runtime.h"
#include <string.h>

#pragma intrinsic(strcpy)

#pragma comment(lib, "user32.lib")
#pragma comment(lib, "kernel32.lib")

// Canonical application state shared with title/audio setup and every active-
// screen command producer.  These names represent the original 0x004390ec,
// 0x004390c8, and 0x004390dc storage slots; no per-function shadow state is
// used by the Product graph.
extern "C" int g_titleThemeEnabled_004390ec;
extern "C" void* g_activeScreenDialogWindow_00404dd0 = 0;
extern "C" const char* PTR_s_oregon_ini_004390dc;

extern "C" const char s_Game_Configuration_00439124[];
extern "C" const char g_musicOptionKey_00405770[] = "Music";
extern "C" const char g_applicationOptionOnValue_00405770[] = "on";
extern "C" const char g_applicationOptionOffValue_00405770[] = "off";

// The canonical menu helper is recovered in trail/event_handlers.cpp.  This
// compatible view preserves the original this pointer and calls the real
// GetMenu/GetSubMenu/GetMenuState/CheckMenuItem/DrawMenuBar implementation.
struct RuntimeWindowState_00405720 {
    char reserved_00[4];
    void* main_window;

    void OtToggleMenuItemCheckState_RealCpp(
        unsigned int menu_item_id,
        int unused);
};

#pragma pack(push, 1)
struct ApplicationSecondaryOption_00405770 {
    char reserved_00[4];
    void* main_window;

    void OtToggleOtherApplicationOption_00405770_RealCpp();
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

void ApplicationSecondaryOption_00405770::OtToggleOtherApplicationOption_00405770_RealCpp()
{
    char value[4];

    if (g_titleThemeEnabled_004390ec != 0) {
        strcpy(value, g_applicationOptionOffValue_00405770);
        g_titleThemeEnabled_004390ec = 0;
        if (IsWindow(g_activeScreenDialogWindow_00404dd0) != 0) {
            if (IsIconic(main_window) == 0) {
                PostMessageA(
                    g_activeScreenDialogWindow_00404dd0,
                    0x046b,
                    0,
                    0);
            }
        }
    } else {
        strcpy(value, g_applicationOptionOnValue_00405770);
        g_titleThemeEnabled_004390ec = 1;
        if (IsWindow(g_activeScreenDialogWindow_00404dd0) != 0) {
            if (IsIconic(main_window) == 0) {
                PostMessageA(
                    g_activeScreenDialogWindow_00404dd0,
                    0x046a,
                    0,
                    0);
            }
        }
    }

    WritePrivateProfileStringA(
        s_Game_Configuration_00439124,
        g_musicOptionKey_00405770,
        value,
        PTR_s_oregon_ini_004390dc);
    reinterpret_cast<RuntimeWindowState_00405720*>(this)->
        OtToggleMenuItemCheckState_RealCpp(0x79, 2);
}

#pragma optimize("", on)
