// Product-owned dialog transition methods recovered from Oregon32.exe.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

typedef void* HWND_00403410;

extern "C" __declspec(dllimport) void* __stdcall LoadCursorA(
    void* instance,
    const void* cursor_name);
extern "C" __declspec(dllimport) void* __stdcall SetCursor(void* cursor);
extern "C" __declspec(dllimport) int __stdcall IsWindow(HWND_00403410 window);
extern "C" __declspec(dllimport) int __stdcall DestroyWindow(
    HWND_00403410 window);

#pragma comment(lib, "user32.lib")

extern "C" HWND_00403410 g_activeScreenDialogWindow_00404dd0;

// Canonical product-tree owner for the original busy-cursor state at
// DAT_00439100. Other promoted users can bind to this storage as they leave
// exact/recovery scaffolding.
extern "C" int g_appBusyCursorActive_Product_004034d0 = 0;

#pragma pack(push, 1)
// Consumer ABI for the canonical implementation in
// main_window_transition_runtime.cpp.
struct CloseConfirmationState_00403410 {
    char reserved_00[4];
    HWND_00403410 main_window;

    int OtConfirmCloseTransition_Product_00403410();
};

struct ActiveScreenDialogState_004034d0 {
    char reserved_00[8];
    int interaction_state;

    void OtDestroyActiveScreenDialog_Product_004034d0();
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)
#pragma code_seg(".otsem")

// Tears down the active game dialog while selecting the transition cursor.
void ActiveScreenDialogState_004034d0::
    OtDestroyActiveScreenDialog_Product_004034d0()
{
    int state = interaction_state;

    if (state == 0x0d || state == 0x0c) {
        ((CloseConfirmationState_00403410*)this)->
            OtConfirmCloseTransition_Product_00403410();
    }

    g_appBusyCursorActive_Product_004034d0 = 1;
    SetCursor(LoadCursorA(0, (const void*)0x7f02));

    if (IsWindow(g_activeScreenDialogWindow_00404dd0) != 0) {
        DestroyWindow(g_activeScreenDialogWindow_00404dd0);
        g_activeScreenDialogWindow_00404dd0 = 0;
    }
}

#pragma code_seg()
#pragma optimize("", on)
