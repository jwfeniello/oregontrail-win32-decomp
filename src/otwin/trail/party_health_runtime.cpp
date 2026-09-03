// Product semantic recovery for OtComputePartyHealthScore @ 0x00419560.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

#include "accepted_semantic_dependencies.h"

#pragma optimize("s", off)
#pragma optimize("t", on)

// Combines the party's health penalties, spare wagon parts, and food stores
// into the score used by daily random-event selection.
short PartyHealthScoreState_00419560_80pct::
    OtComputePartyHealthScore_RealCpp() const
{
    register short scale = 20;
    register short score = health_penalty_b;
    score = static_cast<short>(score / scale);

    score = static_cast<short>(score + wagon_wheels * scale);
    score = static_cast<short>(score + (wagon_tongues + 10) * 25);
    score = static_cast<short>(score + wagon_axles * 35);
    score = static_cast<short>(health_penalty_a * 3 + score * 2);
    score = static_cast<short>(score + food_from_plants);
    score = static_cast<short>(score + food_from_hunting);
    return score;
}

// Product callers historically use a fastcall facade. Both ABIs carry the
// state pointer in ECX, while the member above is the recovered original entry.
extern "C" short __fastcall OtComputePartyHealthScore_RealCpp(
    const PartyHealthScoreState_00419560_80pct* state)
{
    return state->OtComputePartyHealthScore_RealCpp();
}

#pragma optimize("", on)
