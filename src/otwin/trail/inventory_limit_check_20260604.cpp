// Semantic recovery for FUN_0041a960: checks whether a proposed inventory
// addition would exceed the game's per-category caps.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "../trade/trade_adjustment_list.h"

#pragma pack(push, 1)
struct JourneyInventoryLimits_0041a960 {
    char reserved_000[0x96];
    short oxen_count;
    short reserved_098;
    short clothing_count;
    short ammunition_count;
    short wagon_wheels;
    short wagon_axles;
    short wagon_tongues;
    short food_from_hunting;
    short food_from_plants;
};
#pragma pack(pop)

extern "C" JourneyInventoryLimits_0041a960* g_journeyState;

#pragma optimize("s", off)
#pragma optimize("t", on)

int TradeAdjustmentList_00427d70::
    OtWouldExceedInventoryLimit_0041a960_RealCpp(
        short inventory_kind,
        short added_count)
{
    switch (inventory_kind) {
    case 0:
        if (g_journeyState->oxen_count + added_count > 20) {
            return 1;
        }
        break;
    case 1:
        if (g_journeyState->clothing_count + added_count > 50) {
            return 1;
        }
        break;
    case 2:
        if (g_journeyState->ammunition_count + added_count > 2000) {
            return 1;
        }
        break;
    case 3:
        if (g_journeyState->wagon_wheels + added_count > 3) {
            return 1;
        }
        break;
    case 4:
        if (g_journeyState->wagon_axles + added_count > 3) {
            return 1;
        }
        break;
    case 5:
        if (g_journeyState->wagon_tongues + added_count > 3) {
            return 1;
        }
        break;
    case 6:
        if (static_cast<short>(
                g_journeyState->food_from_hunting +
                g_journeyState->food_from_plants) +
            added_count > 2000) {
            return 1;
        }
        break;
    }

    return 0;
}

#pragma optimize("", on)
