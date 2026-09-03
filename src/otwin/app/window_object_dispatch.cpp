// Semantic recovery for the stored window-object dispatch helper @ 0x00405980.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "app_runtime.h"

#pragma comment(lib, "user32.lib")

struct WindowObjectDispatchTarget_00405980 {
    virtual long OtDispatchWindowMessage_00405980(
        unsigned int message,
        unsigned int wparam,
        long lparam);
};

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" long __stdcall OtDispatchStoredWindowObject_00405980_RealCpp(
    void* window,
    unsigned int message,
    unsigned int wparam,
    long lparam)
{
    WindowObjectDispatchTarget_00405980* target =
        (WindowObjectDispatchTarget_00405980*)GetWindowLongA(window, 0);

    if (target == 0) {
        if (message == 1) {
            target = *(WindowObjectDispatchTarget_00405980**)lparam;
            SetWindowLongA(window, 0, (long)target);
            return target->OtDispatchWindowMessage_00405980(message, wparam, lparam);
        }

        return DefWindowProcA(window, message, wparam, lparam);
    }

    return target->OtDispatchWindowMessage_00405980(message, wparam, lparam);
}

#pragma optimize("", on)
