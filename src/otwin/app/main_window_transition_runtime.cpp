// Canonical Product implementations for the contiguous main-window helpers at
// Oregon32.exe RVAs 0x00003320 through 0x00003480.  These neighboring
// main-window methods are retained in original address order under one
// canonical semantic owner.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

extern "C" __declspec(dllimport) int __stdcall WinHelpA(
    void* window,
    const char* help_file,
    unsigned int command,
    unsigned long data);

typedef int (__stdcall *DialogProc_00403390)(
    void* dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam);

extern "C" __declspec(dllimport) int __stdcall DialogBoxParamA(
    void* instance,
    const void* template_name,
    void* parent_window,
    DialogProc_00403390 dialog_proc,
    long init_param);

extern "C" __declspec(dllimport) int __stdcall MessageBoxA(
    void* owner,
    const char* text,
    const char* caption,
    unsigned int type);

extern "C" __declspec(dllimport) void* __stdcall GetDC(void* window);
extern "C" __declspec(dllimport) int __stdcall GetDeviceCaps(
    void* dc,
    int index);
extern "C" __declspec(dllimport) int __stdcall ReleaseDC(
    void* window,
    void* dc);

#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "user32.lib")

#pragma data_seg(".otdat")
extern "C" char* g_helpFilePath_00405a40_20260603;
#pragma data_seg()

extern "C" void* g_applicationModule_00405a40_20260603;
extern "C" int g_generalStorePurchaseCommitted_004390f8;
extern "C" int g_savedGameTextRefreshPending_00404b30;
extern "C" int g_usesIndexedColorDisplay;

extern "C" int __stdcall
OtHuntResultDialogProc_00002d50_20260604_HuntAlt14(
    void*,
    unsigned int,
    unsigned int,
    long);

extern "C" int __cdecl OtSaveGamePathDialogHelper_0000c880_20260605_Wip(
    void* owner_window);

extern "C" int __cdecl OtSavedGameTextExport_0000cb20_RealCpp(
    void* owner_window);

extern "C" const char g_closeConfirmationText_Product_00403410[] =
    "Do you want to save your trail journal?";
extern "C" const char g_closeConfirmationCaption_Product_00403410[] =
    "Game Over";

#pragma pack(push, 1)
struct SceneModeMessageState_00403320 {
    char reserved_00[4];
    void* window;
    int mode;

    long OtSendSceneModeMessage_00403320_RealCpp();
};

struct StateTransitionConfirmation_00003390 {
    char reserved_00[4];
    void* parent_window;
    int mode;

    int OtConfirmStateTransitionMsgBox_00003390_RealCpp();
};

struct CloseConfirmationState_00403410 {
    char reserved_00[4];
    void* main_window;

    int OtConfirmCloseTransition_Product_00403410();
};

struct MainWindowCloseState_00403470 {
    char reserved_00[8];
    unsigned long interaction_state;

    int OtIsCloseConfirmationState_RealCpp() const;
};

struct DisplayCapabilityPureProbe_00403480 {
    char reserved_00[4];
    void* window;

    void OtProbeIndexedDisplayCapabilityDirectThis_00403480_RealCpp();
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

// Maps the current scene/controller mode to a WinHelp topic and dispatches it
// through the canonical help-file path.
long SceneModeMessageState_00403320::
    OtSendSceneModeMessage_00403320_RealCpp()
{
    int command;
    int current_mode = mode;

    if (current_mode == 2) {
        command = 0x0401;
    } else if (current_mode == 4) {
        command = 0x0402;
    } else if (current_mode == 7) {
        command = 0x0405;
    } else if (current_mode == 8) {
        command = 0x1003;
    } else if (current_mode == 9) {
        command = 1;
    } else if (current_mode == 10) {
        command = 0x141c;
    } else {
        if (current_mode == 11) {
            goto set_default_command;
        }

        command = 1;
        if (current_mode == 12) {
            goto send_message;
        }

set_default_command:
        command = 1;
    }

send_message:
    return WinHelpA(
        window,
        g_helpFilePath_00405a40_20260603,
        1,
        static_cast<unsigned long>(command));
}

// Shows the confirmation dialog for a pending state transition. Confirm and
// cancel both clear the pending flag; closing the dialog rejects the transition.
int StateTransitionConfirmation_00003390::
    OtConfirmStateTransitionMsgBox_00003390_RealCpp()
{
    register StateTransitionConfirmation_00003390* state = this;
    int accepted = 1;

    if (state->mode == 7 &&
        g_generalStorePurchaseCommitted_004390f8 != 0) {
        int response = DialogBoxParamA(
            g_applicationModule_00405a40_20260603,
            (const void*)0x00cc,
            state->parent_window,
            OtHuntResultDialogProc_00002d50_20260604_HuntAlt14,
            0);

        if (response == 0x0134) {
            OtSaveGamePathDialogHelper_0000c880_20260605_Wip(
                state->parent_window);
            g_generalStorePurchaseCommitted_004390f8 = 0;
        } else if (response == 0x0135) {
            g_generalStorePurchaseCommitted_004390f8 = 0;
        } else {
            accepted = 0;
        }
    }

    return accepted;
}

// Offers to export the pending trail journal before closing the current game.
int CloseConfirmationState_00403410::
    OtConfirmCloseTransition_Product_00403410()
{
    if (g_savedGameTextRefreshPending_00404b30 != 0) {
        if (MessageBoxA(
                main_window,
                g_closeConfirmationText_Product_00403410,
                g_closeConfirmationCaption_Product_00403410,
                4) == 6) {
            OtSavedGameTextExport_0000cb20_RealCpp(main_window);
            g_savedGameTextRefreshPending_00404b30 = 0;
            return 1;
        }

        g_savedGameTextRefreshPending_00404b30 = 0;
        return 0;
    }

    return 0;
}

// Returns true when the main-window interaction state is the close-confirm
// sentinel value.
int MainWindowCloseState_00403470::
    OtIsCloseConfirmationState_RealCpp() const
{
    return interaction_state == 0x0b;
}

// Probes the display DC for the indexed-color capabilities used by the game.
void DisplayCapabilityPureProbe_00403480::
    OtProbeIndexedDisplayCapabilityDirectThis_00403480_RealCpp()
{
    void* dc;

    g_usesIndexedColorDisplay = 1;
    dc = GetDC(this->window);
    if (GetDeviceCaps(dc, 0x0c) != 8 ||
        (GetDeviceCaps(dc, 0x26) & 0x100) == 0) {
        g_usesIndexedColorDisplay = 0;
    }
    ReleaseDC(this->window, dc);
}

#pragma optimize("", on)
