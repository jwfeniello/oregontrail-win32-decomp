// Canonical no-op member callback used by the timed transition loop.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

#include "timed_transition_state.h"

#pragma code_seg(".otsem")
#pragma optimize("s", off)
#pragma optimize("t", on)

void TimedTransitionState_0042dfa0_ProductWip::
    OtNoopCallback_0042aac0_RealCpp()
{
}

#pragma optimize("", on)
#pragma code_seg()
