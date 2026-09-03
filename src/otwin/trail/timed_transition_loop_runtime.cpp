// Product semantic implementation of the trail/river timed transition loop.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

#include "timed_transition_state.h"

extern "C" __declspec(dllimport) unsigned long __stdcall timeGetTime();

#pragma comment(lib, "winmm.lib")

#pragma code_seg(".otsem")
#pragma optimize("s", off)
#pragma optimize("t", on)

int TimedTransitionState_0042dfa0_ProductWip::
    OtRunTimedTransitionLoop_0042dfa0_ProductWip(int)
{
    unsigned long start_tick = timeGetTime();

    frame = 1;
    for (;;) {
        unsigned long elapsed = timeGetTime() - start_tick;
        if (elapsed >= 2000) {
            break;
        }

        if (elapsed % 200 == 0) {
            ++frame;
            OtNoopCallback_0042aac0_RealCpp();
        }
    }

    return 0;
}

#pragma optimize("", on)
#pragma code_seg()
