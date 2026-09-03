// Focused small-wrapper trials for exact-to-semantic promotions.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "accepted_semantic_dependencies.h"

struct JourneyState_00424e30;

extern "C" JourneyState_00424e30* g_journeyState;
extern "C" short __cdecl OtComputePartyHealthScoreDependency_004195c0_39pct();

#pragma optimize("s", off)
#pragma optimize("t", on)

/**
 * Purpose: preserve the original wrapper dependency while sourcing the party-health score from
 * the recovered shared journey-state scorer.
 *
 * Parameters:
 * - none: reads the active journey-state singleton and forwards it to the scorer.
 */
extern "C" short __cdecl OtComputePartyHealthScoreDependency_004195c0_39pct()
{
    return reinterpret_cast<const PartyHealthScoreState_00419560_80pct*>(
        g_journeyState)->OtComputePartyHealthScore_RealCpp();
}

/**
 * Purpose: map the computed aggregate party-health score into the trail-HUD condition string ID.
 *
 * Parameters:
 * - none: pulls the current score from the shared party-health scoring routine.
 */
extern "C" int __cdecl OtGetPartyHealthClassStringIdAlt1_004195c0_39pct()
{
    short score = OtComputePartyHealthScoreDependency_004195c0_39pct();
    register int string_id;

    string_id = 0x90;
    if (score > 1000) {
        string_id = 0x91;
    }

    if (score > 2000) {
        ++string_id;
    }

    if (score > 3000) {
        ++string_id;
    }

    return string_id;
}

/**
 * Purpose: compact semantic filler that evaluates the first health bucket threshold while preserving
 * the same score source as the public string-ID wrapper.
 *
 * Parameters:
 * - none: pulls the current score from the shared party-health scoring routine.
 */
extern "C" int __cdecl OtIsPartyHealthAboveFairThreshold_004195c0_39pct()
{
    short score = OtComputePartyHealthScoreDependency_004195c0_39pct();
    return score > 1000;
}

/**
 * Purpose: preserved-register trial for mapping party-health score into the HUD condition string ID.
 *
 * Parameters:
 * - none: pulls the current score from the shared party-health scoring routine.
 */
extern "C" int __cdecl OtGetPartyHealthClassStringIdAlt3_004195c0_39pct()
{
    int string_id = 0x90;
    short score = OtComputePartyHealthScoreDependency_004195c0_39pct();

    if (score > 1000) {
        string_id = 0x91;
    }

    if (score > 2000) {
        ++string_id;
    }

    if (score > 3000) {
        ++string_id;
    }

    return string_id;
}

/**
 * Purpose: expose the original journey-state member ABI for Product callers
 * while retaining the recovered health-bucket behavior in ordinary C++.
 */
int PartyHealthScoreState_00419560_80pct::
OtGetPartyHealthClassStringId_RealCpp() const
{
    int string_id = 0x90;
    short score = OtComputePartyHealthScore_RealCpp();

    if (score > 1000) {
        string_id = 0x91;
    }

    if (score > 2000) {
        ++string_id;
    }

    if (score > 3000) {
        ++string_id;
    }

    return string_id;
}

/**
 * Purpose: alternate register-shaped trial for mapping party-health score into the HUD condition string ID.
 *
 * Parameters:
 * - none: pulls the current score from the shared party-health scoring routine.
 */
extern "C" int __cdecl OtGetPartyHealthClassStringIdAlt2_004195c0_39pct()
{
    short score = OtComputePartyHealthScoreDependency_004195c0_39pct();
    register int string_id = 0x90;

    if (score > 1000) {
        string_id = 0x91;
    }

    if (score > 2000) {
        ++string_id;
    }

    if (score > 3000) {
        ++string_id;
    }

    return string_id;
}

#pragma optimize("", on)
