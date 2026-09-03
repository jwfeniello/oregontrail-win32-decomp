// Hunt background resource selection semantic recovery trial.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "hunt_runtime_state.h"

extern "C" int __cdecl OtRandomBelow_RealCpp(int upper_bound);

#pragma pack(push, 1)
struct HuntSceneJourneyState_00412ee0 {
    char reserved_00[0x54];
    short location_mile_marker;
    short snow_scene_offset;
    char reserved_58[0x36];
    short hunt_region;
};
#pragma pack(pop)

extern "C" int g_cdMediaMode_00439108;
extern "C" HuntSceneJourneyState_00412ee0* g_journeyState;

#pragma optimize("s", off)
#pragma optimize("t", on)

/**
 * Purpose: choose the base RCDATA id for the hunt background family from the
 * current route/hunt region, route progress, low-resource mode, and snow flag.
 *
 * Returns: base hunt backdrop resource id in the 0x4b00 range, with +3 applied
 * for the snowy variants.
 */
extern "C" int __cdecl OtChooseHuntSceneResourceId_00012ee0_SemanticAlt5_RealCpp()
{
    int scene_resource_id = 0x4b00;
    HuntSceneJourneyState_00412ee0* journey = g_journeyState;
    int hunt_region = journey->hunt_region;
    HuntSceneJourneyState_00412ee0* weather_journey = g_journeyState;
    int location_mile_marker = journey->location_mile_marker;
    int snow_scene_offset = weather_journey->snow_scene_offset;

    if (g_cdMediaMode_00439108 == 0) {
        if (hunt_region <= 5) {
            return 0x4b00;
        }
        return 0x4b5a;
    }

    if (hunt_region <= 2) {
        if (location_mile_marker <= 0x190) {
            scene_resource_id =
                (-(OtRandomBelow_RealCpp(2) == 0) & -80) + 0x4b5a;
        } else {
            scene_resource_id =
                (-(OtRandomBelow_RealCpp(2) == 0) & 30) + 0x4b00;
        }

        if (hunt_region <= 2) {
            goto after_region_four;
        }
    }

    if (hunt_region <= 4) {
        scene_resource_id = 0x4b46;
    }

after_region_four:
    if (hunt_region == 5) {
        scene_resource_id =
            (-(OtRandomBelow_RealCpp(2) == 0) & -50) + 0x4b46;
    }

    if (hunt_region <= 5) {
        goto maybe_snow_scene;
    }

    if (hunt_region <= 9) {
        if (OtRandomBelow_RealCpp(2) != 0) {
            scene_resource_id =
                (-(OtRandomBelow_RealCpp(2) == 0) & -40) + 0x4b3c;
        } else {
            scene_resource_id = 0x4b28;
        }
    }

maybe_snow_scene:
    if (hunt_region <= 9) {
        goto add_snow_scene_offset;
    }

    if (hunt_region <= 0xd) {
        scene_resource_id =
            (-(OtRandomBelow_RealCpp(2) == 0) & -10) + 0x4b32;
    }

    if (hunt_region <= 0xd) {
        goto add_snow_scene_offset;
    }

    switch (OtRandomBelow_RealCpp(4)) {
    case 0:
        scene_resource_id = 0x4b28;
        break;
    case 1:
        scene_resource_id = 0x4b32;
        break;
    case 2:
        scene_resource_id = 0x4b46;
        break;
    case 3:
        scene_resource_id = 0x4b50;
        break;
    default:
        scene_resource_id = 0x4b50;
        break;
    }

add_snow_scene_offset:
    if (snow_scene_offset > 0) {
        scene_resource_id += 3;
    }

    return scene_resource_id;
}

int HuntRuntimeState_004122b0_Product::OtChooseHuntSceneResourceId_Product()
{
    int scene_resource_id = 0x4b00;
    HuntSceneJourneyState_00412ee0* journey = g_journeyState;
    int hunt_region = journey->hunt_region;
    HuntSceneJourneyState_00412ee0* weather_journey = g_journeyState;
    int location_mile_marker = journey->location_mile_marker;
    int snow_scene_offset = weather_journey->snow_scene_offset;

    if (g_cdMediaMode_00439108 == 0) {
        if (hunt_region <= 5) {
            return 0x4b00;
        }
        return 0x4b5a;
    }

    if (hunt_region <= 2) {
        if (location_mile_marker <= 0x190) {
            scene_resource_id =
                ((OtRandomBelow_RealCpp(2) == 0 ? -1 : 0) & -80) + 0x4b5a;
        } else {
            scene_resource_id =
                ((OtRandomBelow_RealCpp(2) == 0 ? -1 : 0) & 30) + 0x4b00;
        }

        if (hunt_region <= 2) {
            goto after_region_four;
        }
    }

    if (hunt_region <= 4) {
        scene_resource_id = 0x4b46;
    }

after_region_four:
    if (hunt_region == 5) {
        scene_resource_id =
            ((OtRandomBelow_RealCpp(2) == 0 ? -1 : 0) & -50) + 0x4b46;
    }

    if (hunt_region <= 5) {
        goto maybe_snow_scene;
    }

    if (hunt_region <= 9) {
        if (OtRandomBelow_RealCpp(2) != 0) {
            scene_resource_id =
                ((OtRandomBelow_RealCpp(2) == 0 ? -1 : 0) & -40) + 0x4b3c;
        } else {
            scene_resource_id = 0x4b28;
        }
    }

maybe_snow_scene:
    if (hunt_region <= 9) {
        goto check_region_thirteen_after_scene_pick;
    }

    if (hunt_region <= 0xd) {
        scene_resource_id =
            ((OtRandomBelow_RealCpp(2) == 0 ? -1 : 0) & -10) + 0x4b32;
    }

check_region_thirteen_after_scene_pick:
    if (hunt_region <= 0xd) {
        goto add_snow_scene_offset;
    }

    switch (OtRandomBelow_RealCpp(4)) {
    case 0:
        scene_resource_id = 0x4b28;
        break;
    case 1:
        scene_resource_id = 0x4b32;
        break;
    case 2:
        scene_resource_id = 0x4b46;
        break;
    case 3:
        scene_resource_id = 0x4b50;
        break;
    default:
        scene_resource_id = 0x4b50;
        break;
    }

add_snow_scene_offset:
    if (snow_scene_offset > 0) {
        scene_resource_id += 3;
    }

    return scene_resource_id;
}

#pragma optimize("", on)
