// Hunt-round message and animation loop at 0x00414ba0.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This recovered runtime requires 32-bit MSVC."
#endif

#include "hunt_runtime_state.h"

#pragma pack(push, 4)
struct HuntPoint_00414ba0 {
    long x;
    long y;
};

struct HuntMessage_00414ba0 {
    void* window;
    unsigned int message;
    unsigned int wparam;
    long lparam;
    OtHuntTick time;
    HuntPoint_00414ba0 point;
};
#pragma pack(pop)

typedef char HuntMessage_00414ba0_size_check[
    sizeof(HuntMessage_00414ba0) == 0x1c ? 1 : -1];

extern "C" __declspec(dllimport) OtHuntTick __stdcall timeGetTime();
extern "C" __declspec(dllimport) int __stdcall PeekMessageA(
    HuntMessage_00414ba0*, void*, unsigned int, unsigned int, unsigned int);
extern "C" __declspec(dllimport) int __stdcall TranslateAcceleratorA(
    void*, void*, HuntMessage_00414ba0*);
extern "C" __declspec(dllimport) int __stdcall IsDialogMessageA(
    void*, HuntMessage_00414ba0*);
extern "C" __declspec(dllimport) int __stdcall TranslateMessage(
    const HuntMessage_00414ba0*);
extern "C" __declspec(dllimport) long __stdcall DispatchMessageA(
    const HuntMessage_00414ba0*);

extern "C" int DAT_004390e4;
extern "C" void* g_mainAccelerator_00402ed0;

#pragma comment(lib, "user32.lib")
#pragma comment(lib, "winmm.lib")

#pragma optimize("s", off)
#pragma optimize("t", on)

/**
 * Pump dialog messages and advance the active hunt round until its configured
 * duration expires, the dialog marks it complete, or WM_QUIT arrives.
 */
int HuntRuntimeState_004122b0_Product::
    OtRunHuntRoundLoop_00414ba0_Product(void* dialog)
{
    HuntRuntimeState_004122b0_Product* state;
    register OtHuntTick (__stdcall *get_tick)();
    OtHuntTick start_tick;
    int result;
    HuntMessage_00414ba0 message;

    redraw_pending = 0;
    state = this;
    result = 1;
    get_tick = timeGetTime;
    start_tick = get_tick();
    register void* dialog_window = dialog;

    while (state->round_done == 0) {
        if (PeekMessageA(&message, 0, 0, 0, 0) != 0) {
            if (message.message == 0x12) {
                result = 0;
                state->round_done = 1;
            } else {
                PeekMessageA(&message, 0, 0, 0, 1);
                if (TranslateAcceleratorA(
                        message.window,
                        g_mainAccelerator_00402ed0,
                        &message) == 0 &&
                    IsDialogMessageA(dialog_window, &message) == 0) {
                    TranslateMessage(&message);
                    DispatchMessageA(&message);
                }
            }
        } else {
            if (state->round_running == 1) {
                if (get_tick() - start_tick >=
                    static_cast<OtHuntTick>(DAT_004390e4 * 1000)) {
                    state->round_done = 1;
                }
                if (state->round_running == 1) {
                    if (state->active_round == 1) {
                        state->OtSpawnRandomHuntTarget_004129d0_Product();
                    }
                }
            }

            if (state->active_round == 1 && state->round_running == 1) {
                get_tick();
                state->OtAdvanceHuntProjectile_00414450_Product(
                    state->render_context);
                state->OtAdvanceHuntTargets_00413d20_Product(
                    state->render_context);
                state->OtAdvanceHuntProjectile_00414450_Product(
                    state->render_context);
            }
        }
    }

    return result;
}

#pragma optimize("", on)
