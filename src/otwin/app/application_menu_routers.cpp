// Product-semantic recovery of the application menu dispatchers at
// 0x00404dd0, 0x00404ed0, and 0x00405000.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

typedef void* OtMenuWindow;
typedef void* OtMenuHandle;
typedef long (__stdcall *OtMenuDialogProc)(
    OtMenuWindow dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam);

extern "C" __declspec(dllimport) int __stdcall DialogBoxParamA(
    void* instance,
    const void* template_name,
    OtMenuWindow parent_window,
    OtMenuDialogProc dialog_proc,
    long init_param);
extern "C" __declspec(dllimport) int __stdcall IsWindow(
    OtMenuWindow window);
extern "C" __declspec(dllimport) int __stdcall PostMessageA(
    OtMenuWindow window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" __declspec(dllimport) int __stdcall WinHelpA(
    OtMenuWindow window,
    const char* help_file,
    unsigned int command,
    unsigned long data);
extern "C" __declspec(dllimport) int __stdcall IsMenu(
    OtMenuHandle menu);
extern "C" __declspec(dllimport) unsigned int __stdcall EnableMenuItem(
    OtMenuHandle menu,
    unsigned int item,
    unsigned int flags);
extern "C" __declspec(dllimport) long __stdcall SendMessageA(
    OtMenuWindow window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" __declspec(dllimport) int __stdcall
IsClipboardFormatAvailable(unsigned int format);

#pragma comment(lib, "user32.lib")

extern "C" void* g_applicationModule_00405a40_20260603;
extern "C" OtMenuWindow g_activeScreenDialogWindow_00404dd0;
extern "C" char* g_helpFilePath_00405a40_20260603;
extern "C" const char g_windowsHelpFile_00404ed0[] = "winhelp.hlp";

extern "C" long __stdcall OtSimulationSpeedDialogProcA_00401f00(
    OtMenuWindow dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" long __stdcall OtHuntTimeDialogProcA_00402140(
    OtMenuWindow dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" long __stdcall OtIntroDialogProc_0040bb30_Product(
    OtMenuWindow dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" long __stdcall OtTrailGameShutdownDialogProc_00430350_Product(
    OtMenuWindow dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" long __stdcall OtAboutDialogProc_0041afa0_Product(
    OtMenuWindow dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam);

#pragma pack(push, 1)
struct ApplicationMenuCommandState_00404dd0 {
    void* vtable;
    OtMenuWindow main_window;

    int OtHandleApplicationMenuCommandAlt1_00404dd0(
        unsigned int command_id,
        long notify_code);
};

struct ApplicationSecondaryOption_00405770 {
    void* vtable;
    OtMenuWindow main_window;

    void OtToggleOtherApplicationOption_00405770_RealCpp();
};

struct ApplicationSoundOption_00405870 {
    void* vtable;
    OtMenuWindow main_window;

    void OtToggleSoundEnabled_00405870_RealCpp();
};

struct MenuCommandDispatcher_00404ed0 {
    void* vtable;
    OtMenuWindow main_window;
    int flow_state;

    int OtDispatchMenuCommand_82_85_00404ed0_RealCpp(
        unsigned int command_id,
        long notify_code);
};

struct SceneModeMessageState_00403320 {
    void* vtable;
    OtMenuWindow main_window;
    int flow_state;

    long OtSendSceneModeMessage_00403320_RealCpp();
};

struct MainWindowMessageRouter_00405000 {
    void* vtable;
    OtMenuWindow main_window;
    int flow_state;
    OtMenuDialogProc current_dialog_proc;
    OtMenuWindow interaction_window;

    void OtMainWindowMessageRouter_00005000_ProductWip(OtMenuHandle menu);
};
#pragma pack(pop)

typedef char OtApplicationMenuStateMainWindowOffsetMustBe4[
    (unsigned int)&(((ApplicationMenuCommandState_00404dd0*)0)->main_window) ==
            4
        ? 1
        : -1];
typedef char OtMainWindowRouterFlowStateOffsetMustBe8[
    (unsigned int)&(((MainWindowMessageRouter_00405000*)0)->flow_state) == 8
        ? 1
        : -1];
typedef char OtMainWindowRouterInteractionWindowOffsetMustBe10[
    (unsigned int)&(((MainWindowMessageRouter_00405000*)0)->
        interaction_window) == 0x10
        ? 1
        : -1];

#pragma optimize("s", off)
#pragma optimize("t", on)

int ApplicationMenuCommandState_00404dd0::
    OtHandleApplicationMenuCommandAlt1_00404dd0(
    unsigned int command_id,
    long)
{
    switch (command_id & 0xffff) {
    case 0x78:
        DialogBoxParamA(
            g_applicationModule_00405a40_20260603,
            (const void*)0x00cb,
            main_window,
            OtIntroDialogProc_0040bb30_Product,
            0);
        return 0;

    case 0x79:
        reinterpret_cast<ApplicationSecondaryOption_00405770*>(this)->
            OtToggleOtherApplicationOption_00405770_RealCpp();
        return 0;

    case 0x7a:
        reinterpret_cast<ApplicationSoundOption_00405870*>(this)->
            OtToggleSoundEnabled_00405870_RealCpp();
        return 0;

    case 0x7b:
        DialogBoxParamA(
            g_applicationModule_00405a40_20260603,
            (const void*)0x00d2,
            main_window,
            OtTrailGameShutdownDialogProc_00430350_Product,
            0);
        return 0;

    case 0x7c:
        DialogBoxParamA(
            g_applicationModule_00405a40_20260603,
            (const void*)0x00c9,
            main_window,
            OtSimulationSpeedDialogProcA_00401f00,
            0);
        if (IsWindow(g_activeScreenDialogWindow_00404dd0) != 0) {
            PostMessageA(
                g_activeScreenDialogWindow_00404dd0,
                0x046c,
                0,
                0);
            return 0;
        }
        break;

    case 0x7d:
        DialogBoxParamA(
            g_applicationModule_00405a40_20260603,
            (const void*)0x00ca,
            main_window,
            OtHuntTimeDialogProcA_00402140,
            0);
    }

    return 0;
}

int MenuCommandDispatcher_00404ed0::
    OtDispatchMenuCommand_82_85_00404ed0_RealCpp(
    unsigned int command_id,
    long)
{
    switch (command_id & 0xffff) {
    case 0x82:
        WinHelpA(main_window, g_helpFilePath_00405a40_20260603, 3, 0);
        return 0;

    case 0x83:
        reinterpret_cast<SceneModeMessageState_00403320*>(this)->
            OtSendSceneModeMessage_00403320_RealCpp();
        return 0;

    case 0x84:
        WinHelpA(main_window, g_windowsHelpFile_00404ed0, 4, 0);
        return 0;

    case 0x85:
        DialogBoxParamA(
            g_applicationModule_00405a40_20260603,
            (const void*)0x00c8,
            main_window,
            OtAboutDialogProc_0041afa0_Product,
            0);
        break;
    }

    return 0;
}

void MainWindowMessageRouter_00405000::
    OtMainWindowMessageRouter_00005000_ProductWip(OtMenuHandle menu)
{
    unsigned int enabled;
    long selection_count;

    if (IsMenu(menu) == 0) {
        return;
    }

    switch (flow_state) {
    case 0:
    case 1:
        EnableMenuItem(menu, 0x64, 1);
        EnableMenuItem(menu, 0x65, 1);
        EnableMenuItem(menu, 0x66, 1);
        EnableMenuItem(menu, 0x67, 1);
        EnableMenuItem(menu, 0x68, 1);
        EnableMenuItem(menu, 0x69, 1);
        break;

    case 2:
        EnableMenuItem(menu, 0x64, 0);
        EnableMenuItem(menu, 0x65, 0);
        EnableMenuItem(menu, 0x66, 1);
        EnableMenuItem(menu, 0x67, 1);
        EnableMenuItem(menu, 0x68, 1);
        EnableMenuItem(menu, 0x69, 0);
        break;

    case 3:
    case 4:
    case 5:
        EnableMenuItem(menu, 0x64, 1);
        EnableMenuItem(menu, 0x65, 0);
        EnableMenuItem(menu, 0x66, 1);
        EnableMenuItem(menu, 0x67, 1);
        EnableMenuItem(menu, 0x68, 0);
        EnableMenuItem(menu, 0x69, 0);
        break;

    case 6:
    case 7:
        EnableMenuItem(menu, 0x64, 1);
        EnableMenuItem(menu, 0x65, 1);
        EnableMenuItem(menu, 0x66, 0);
        EnableMenuItem(menu, 0x67, 0);
        EnableMenuItem(menu, 0x68, 0);
        EnableMenuItem(menu, 0x69, 0);
        break;

    case 8:
    case 9:
    case 11:
        EnableMenuItem(menu, 0x64, 1);
        EnableMenuItem(menu, 0x65, 1);
        EnableMenuItem(menu, 0x66, 0);
        EnableMenuItem(menu, 0x67, 0);
        EnableMenuItem(menu, 0x68, 1);
        EnableMenuItem(menu, 0x69, 1);
        break;

    case 10:
        EnableMenuItem(menu, 0x64, 1);
        EnableMenuItem(menu, 0x65, 1);
        EnableMenuItem(menu, 0x66, 0);
        EnableMenuItem(menu, 0x67, 0);
        EnableMenuItem(menu, 0x68, 0);
        EnableMenuItem(menu, 0x69, 1);
        break;

    default:
        EnableMenuItem(menu, 0x64, 0);
        EnableMenuItem(menu, 0x65, 0);
        EnableMenuItem(menu, 0x66, 1);
        EnableMenuItem(menu, 0x67, 0);
        EnableMenuItem(menu, 0x68, 1);
        EnableMenuItem(menu, 0x69, 0);
        break;
    }

    if (flow_state == 0 || flow_state == 1) {
        EnableMenuItem(menu, 0x78, 1);
        EnableMenuItem(menu, 0x79, 1);
        EnableMenuItem(menu, 0x7a, 1);
        EnableMenuItem(menu, 0x7b, 1);
        EnableMenuItem(menu, 0x7c, 1);
        EnableMenuItem(menu, 0x7d, 1);
        EnableMenuItem(menu, 0x82, 1);
        EnableMenuItem(menu, 0x83, 1);
        EnableMenuItem(menu, 0x84, 1);
        EnableMenuItem(menu, 0x85, 1);
    } else {
        enabled = flow_state == 2 || flow_state == 3 ? 0 : 1;
        EnableMenuItem(menu, 0x78, enabled);
        EnableMenuItem(menu, 0x79, 0);
        EnableMenuItem(menu, 0x7a, 0);
        EnableMenuItem(menu, 0x7b, 0);
        EnableMenuItem(menu, 0x7c, 0);
        EnableMenuItem(menu, 0x7d, 0);
        EnableMenuItem(menu, 0x82, 0);
        EnableMenuItem(menu, 0x83, 0);
        EnableMenuItem(menu, 0x84, 0);
        EnableMenuItem(menu, 0x85, 0);
    }

    if (flow_state != 10 || IsWindow(interaction_window) == 0) {
        EnableMenuItem(menu, 0x6e, 1);
        EnableMenuItem(menu, 0x6f, 1);
        EnableMenuItem(menu, 0x70, 1);
        EnableMenuItem(menu, 0x71, 1);
        EnableMenuItem(menu, 0x72, 1);
        return;
    }

    enabled = SendMessageA(interaction_window, 0x00c6, 0, 0) == 0;
    EnableMenuItem(menu, 0x6e, enabled);

    selection_count = SendMessageA(interaction_window, 0x00b0, 0, 0);
    enabled = selection_count < 1;
    EnableMenuItem(menu, 0x6f, enabled);
    EnableMenuItem(menu, 0x70, enabled);
    EnableMenuItem(menu, 0x72, enabled);

    enabled = IsClipboardFormatAvailable(1) == 0;
    EnableMenuItem(menu, 0x71, enabled);
}

#pragma optimize("", on)
