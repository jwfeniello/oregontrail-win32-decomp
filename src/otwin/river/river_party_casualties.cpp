// Focused semantic candidate for river-crossing party casualty rolls.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

extern "C" int __cdecl OtRandomBelow_RealCpp(int upper_bound);

#pragma pack(push, 1)
struct RiverPartyCasualtyJourneyState_0040f1e0 {
    char reserved_000[0x116];
    short member_state[5];
};
#pragma pack(pop)

extern "C" RiverPartyCasualtyJourneyState_0040f1e0* g_journeyState;

#pragma optimize("s", off)
#pragma optimize("t", on)

// Rolls river-crossing casualty losses into party-member adjustment entries.
extern "C" void __cdecl OtRollRiverCrossingPartyCasualties_0040f1e0_RealCpp(
    short probability,
    short* loss_adjustments)
{
    register int all_remaining_marked = 1;
    register int probability32 = probability;
    register short adjustment_index = 9;

    do {
        if (OtRandomBelow_RealCpp(100) < probability32) {
            loss_adjustments[adjustment_index] = 1;
        }

        ++adjustment_index;
    } while (adjustment_index < 13);

    {
        register short scan_index = 9;
        register int dead_state = 0x0f;

        while (1) {
            if (scan_index >= 13) {
                break;
            }

            if (*(short*)((char*)g_journeyState +
                          0x116 +
                          (int)static_cast<short>(scan_index - 8) * 2) !=
                    dead_state &&
                loss_adjustments[scan_index] != 1) {
                all_remaining_marked = 0;
            }

            ++scan_index;
        }
    }

    if (all_remaining_marked != 0) {
        if (OtRandomBelow_RealCpp(100) < probability32) {
            loss_adjustments[8] = 1;
        }
    }
}

#pragma optimize("", on)
