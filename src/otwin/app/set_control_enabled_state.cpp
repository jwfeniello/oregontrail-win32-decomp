// USER32 control enabled-state synchronization recovered from Oregon32.exe.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This Product source must be compiled with 32-bit MSVC."
#endif

#include <windows.h>

#pragma comment(lib, "user32.lib")

#pragma optimize("s", off)
#pragma optimize("t", on)

/**
 * Synchronizes a control's enabled state only when a transition is needed.
 *
 * @param control Child window whose enabled state is being synchronized.
 * @param enabled Requested state passed through to EnableWindow.
 * @param unused Preserved trailing argument from the original ABI.
 */
extern "C" void __stdcall OtSetControlEnabledState_0042c070_Product(
    void* control,
    int enabled,
    int)
{
    if ((enabled != 0 && IsWindowEnabled(control) == 0) ||
        (enabled == 0 && IsWindowEnabled(control) != 0)) {
        EnableWindow(control, enabled);
    }
}

#pragma optimize("", on)
