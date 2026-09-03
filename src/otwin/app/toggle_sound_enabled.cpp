// Semantic candidate for OtToggleSoundEnabled @ 0x00405870.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "app_runtime.h"
#include <string.h>

#pragma intrinsic(strcpy)

#pragma comment(lib, "user32.lib")
#pragma comment(lib, "winmm.lib")
#pragma comment(lib, "kernel32.lib")

// Canonical shared application slots and option strings.  DAT_004390e8 is the
// executable's sound-enabled flag; its Product owner is the hunt/audio state
// used by every sound-effect call site.
extern "C" int DAT_004390e8;
extern "C" void* g_activeScreenDialogWindow_00404dd0;
extern "C" const char* PTR_s_oregon_ini_004390dc;

extern "C" const char s_Game_Configuration_00439124[];
extern "C" const char g_applicationOptionOnValue_00405770[];
extern "C" const char g_applicationOptionOffValue_00405770[];
extern "C" const char g_soundOptionKey_00405870[] = "Sound";

struct RuntimeWindowState_00405720 {
    char reserved_00[4];
    void* main_window;

    void OtToggleMenuItemCheckState_RealCpp(
        unsigned int menu_item_id,
        int unused);
};

#pragma pack(push, 1)
struct ApplicationSoundOption_00405870 {
    char reserved_00[4];
    void* main_window;

    void OtToggleSoundEnabled_00405870_RealCpp();
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

void ApplicationSoundOption_00405870::OtToggleSoundEnabled_00405870_RealCpp()
{
    char value[4];

    if (DAT_004390e8 != 0) {
        strcpy(value, g_applicationOptionOffValue_00405770);
        DAT_004390e8 = 0;
        if (g_activeScreenDialogWindow_00404dd0 != 0) {
            if (IsIconic(main_window) == 0) {
                PostMessageA(
                    g_activeScreenDialogWindow_00404dd0,
                    0x0469,
                    0,
                    0);
            }
        }
        sndPlaySoundA(0, 0);
    } else {
        strcpy(value, g_applicationOptionOnValue_00405770);
        DAT_004390e8 = 1;
        if (g_activeScreenDialogWindow_00404dd0 != 0) {
            if (IsIconic(main_window) == 0) {
                PostMessageA(
                    g_activeScreenDialogWindow_00404dd0,
                    0x0468,
                    0,
                    0);
            }
        }
    }

    WritePrivateProfileStringA(
        s_Game_Configuration_00439124,
        g_soundOptionKey_00405870,
        value,
        PTR_s_oregon_ini_004390dc);
    reinterpret_cast<RuntimeWindowState_00405720*>(this)->
        OtToggleMenuItemCheckState_RealCpp(0x7a, 3);
}

#pragma optimize("", on)
