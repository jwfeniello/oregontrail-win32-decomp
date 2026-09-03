// Hunt-target spawn-chance roll at 0x004128c0.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This recovered runtime requires 32-bit MSVC."
#endif

#include "hunt_runtime_state.h"

#pragma pack(push, 1)
struct HuntSpawnJourneyState_004128c0_Product {
    char reserved_000[0x54];
    short money;
    char reserved_056[0x06];
    short current_mileage;
    char reserved_05e[0x2e];
    short previous_mileage;
    char reserved_08e[0xac];
    short hunt_region;
};

struct HuntSpawnRouteDescriptor_004128c0_Product {
    char reserved_000[0x1a];
    short spawn_probabilities[0x100];
};
#pragma pack(pop)

extern "C" HuntSpawnJourneyState_004128c0_Product* g_journeyState;
extern "C" HuntSpawnRouteDescriptor_004128c0_Product*
    g_activeRouteDescriptor;
extern "C" int __cdecl OtRandomBelow_RealCpp(int upper_bound);

class HuntSpawnChanceEvaluator_004128c0_Product {
public:
    HuntSpawnChanceEvaluator_004128c0_Product(
        short probability,
        HuntSpawnJourneyState_004128c0_Product* journey)
        : probability_(probability), journey_(journey)
    {
    }

    __inline int Roll(int distance_scale) const
    {
        int distance_delta =
            static_cast<int>(journey_->current_mileage) -
            static_cast<int>(journey_->previous_mileage);

        if (distance_delta < 20) {
            distance_scale = 1;
        } else if (distance_delta < 40) {
            distance_scale = 5;
        }

        if (probability_ != 5) {
            return OtRandomBelow_RealCpp(100) <
                static_cast<int>(probability_) * distance_scale;
        }

        if (g_journeyState->money >= 400) {
            distance_scale <<= 2;
            return OtRandomBelow_RealCpp(100) < distance_scale;
        }

        return 0;
    }

private:
    short probability_;
    HuntSpawnJourneyState_004128c0_Product* journey_;
};

#pragma optimize("s", off)
#pragma optimize("t", on)
#pragma code_seg(".otsem")

/**
 * Roll whether a target type may spawn using its route-region probability.
 * Recent travel distance scales ordinary targets; the special probability-five
 * entry instead requires at least 400 journey cash units.
 */
int HuntRuntimeState_004122b0_Product::
OtRollHuntTargetSpawnChance_004128c0_RealCpp(int target_type)
{
    int distance_scale;
    int table_index_by_target[10];

    table_index_by_target[0] = 2;
    table_index_by_target[1] = 3;
    table_index_by_target[3] = 0;
    table_index_by_target[4] = 1;
    table_index_by_target[5] = 6;
    table_index_by_target[6] = 4;
    table_index_by_target[7] = 5;
    distance_scale = 10;
    table_index_by_target[2] = 10;
    table_index_by_target[8] = 7;
    table_index_by_target[9] = 9;

    HuntSpawnChanceEvaluator_004128c0_Product evaluator(
        g_activeRouteDescriptor->spawn_probabilities[
            g_journeyState->hunt_region * 11 +
            table_index_by_target[target_type]],
        g_journeyState);
    return evaluator.Roll(distance_scale);
}

#pragma code_seg()
#pragma optimize("", on)
