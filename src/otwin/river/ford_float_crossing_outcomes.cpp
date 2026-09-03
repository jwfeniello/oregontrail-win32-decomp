// Product implementations for ford and float river-crossing outcomes.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

extern "C" short* __fastcall OtClearEventAdjustmentList_RealCpp(
    short* adjustments);
extern "C" int __cdecl OtRandomBelow_RealCpp(int upper_bound);
extern "C" void __cdecl OtRollRiverCrossingPartyCasualties_0040f1e0_RealCpp(
    short probability,
    short* loss_adjustments);
extern "C" void __cdecl OtRollRiverCrossingOxLosses_0040f180_Product(
    short probability,
    short* loss_adjustment);
extern "C" int __cdecl
    OtResolveRiverCrossingLossAdjustmentList_0040f000_ProductWip(
        short probability,
        short* loss_adjustments);

#define OtRollRiverCrossingOxLosses_RealCpp \
    OtRollRiverCrossingOxLosses_0040f180_Product
#define OtResolveRiverCrossingLossAdjustmentList_0000f000_Exact_RealCpp \
    OtResolveRiverCrossingLossAdjustmentList_0040f000_ProductWip

#pragma pack(push, 1)
struct FordFloatJourneyState_0040f270 {
    char reserved_000[0x54];
    short river_depth;
};

struct FordFloatRouteState_0040f270 {
    short river_id;
    char reserved_02[0x06];
    short weather_factor;
    char reserved_0a[0x02];
    short ferry_factor;
};

struct RiverOutcomeAdjustmentListProduct_0040f270 {
    short entries[13];

    RiverOutcomeAdjustmentListProduct_0040f270();
};
#pragma pack(pop)

extern "C" FordFloatJourneyState_0040f270* g_journeyState;
extern "C" FordFloatRouteState_0040f270* g_activeRouteDescriptor;
extern "C" short g_riverCrossingPromptMode_0040ec30;
extern "C" short g_riverCrossingDialogResult_0040ec30;
extern "C" short g_riverCrossingSceneMode_0040f270;

#define g_fordFloatRouteState_0040f270 g_activeRouteDescriptor
#define g_fordFloatDifficultyScale_0040f270 \
    g_riverCrossingPromptMode_0040ec30
#define g_fordFloatTroubleFlag_0040f270 \
    g_riverCrossingDialogResult_0040ec30
#define g_fordFloatSceneMode_0040f270 \
    g_riverCrossingSceneMode_0040f270

RiverOutcomeAdjustmentListProduct_0040f270::
    RiverOutcomeAdjustmentListProduct_0040f270()
{
    OtClearEventAdjustmentList_RealCpp(entries);
}

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" short __cdecl OtResolveFordCrossingOutcome_0040f270_ProductWip()
{
    int result_text_id = 0x3f8;
    RiverOutcomeAdjustmentListProduct_0040f270* adjustment_list;
    short risk_score;
    int probability;

    adjustment_list = new RiverOutcomeAdjustmentListProduct_0040f270;
    g_fordFloatSceneMode_0040f270 = 0;
    risk_score = static_cast<short>(
        g_journeyState->river_depth * 2 / 10 +
        g_fordFloatRouteState_0040f270->weather_factor * 10);

    if (risk_score >= 25) {
        if (risk_score < 30) {
            g_fordFloatTroubleFlag_0040f270 = 1;
            result_text_id = 0x3fe;
        } else {
            probability = risk_score;
            probability -= 10;
            OtRollRiverCrossingOxLosses_RealCpp(
                static_cast<short>(
                    probability / g_fordFloatDifficultyScale_0040f270),
                adjustment_list->entries);
            risk_score = static_cast<short>(
                g_journeyState->river_depth * 2 / 10 +
                g_fordFloatRouteState_0040f270->weather_factor * 10);
            probability = risk_score;
            probability -= 25;
            probability /= g_fordFloatDifficultyScale_0040f270;
            OtRollRiverCrossingPartyCasualties_0040f1e0_RealCpp(
                static_cast<short>(probability),
                adjustment_list->entries);
            risk_score = static_cast<short>(
                g_journeyState->river_depth * 2 / 10 +
                g_fordFloatRouteState_0040f270->weather_factor * 10);
            if (OtResolveRiverCrossingLossAdjustmentList_0000f000_Exact_RealCpp(
                    static_cast<short>(risk_score /
                                       g_fordFloatDifficultyScale_0040f270),
                    adjustment_list->entries) != 0) {
                g_fordFloatSceneMode_0040f270 = 2;
                result_text_id = 0x3ff;
            }
        }
    } else {
        int river_id = g_fordFloatRouteState_0040f270->river_id;
        switch (river_id) {
        case 2: {
            short chance = static_cast<short>(
                40 / g_fordFloatDifficultyScale_0040f270);
            if (OtRandomBelow_RealCpp(100) < chance) {
                result_text_id = 0x3f9;
                g_fordFloatTroubleFlag_0040f270 = 1;
                g_fordFloatSceneMode_0040f270 = 1;
            } else {
                result_text_id = 0x3fa;
            }
            break;
        }
        case 9:
        case 12: {
            result_text_id = 0x3fb;
            short chance = static_cast<short>(
                16 / g_fordFloatDifficultyScale_0040f270);
            if (OtRandomBelow_RealCpp(100) < chance) {
                result_text_id = 0x3fc;
                g_fordFloatSceneMode_0040f270 = 3;
                if (OtResolveRiverCrossingLossAdjustmentList_0000f000_Exact_RealCpp(
                        static_cast<short>(OtRandomBelow_RealCpp(30) + 10),
                        adjustment_list->entries) != 0) {
                    result_text_id = 0x3fd;
                }
            }
            break;
        }
        }
    }

    delete adjustment_list;
    return static_cast<short>(result_text_id);
}

extern "C" short __cdecl OtResolveFloatCrossingOutcome_0040f4b0_ProductWip()
{
    int result_text_id = 0x408;
    short chance;
    short crossing_factor;
    RiverOutcomeAdjustmentListProduct_0040f270* adjustment_list;
    short* adjustments;
    short risk_score;
    int probability;

    crossing_factor = static_cast<short>(
        g_journeyState->river_depth / 100 +
        g_fordFloatRouteState_0040f270->ferry_factor);
    chance = static_cast<short>(
        (crossing_factor * 5) / g_fordFloatDifficultyScale_0040f270);
    g_fordFloatSceneMode_0040f270 = 4;
    adjustment_list = new RiverOutcomeAdjustmentListProduct_0040f270;
    adjustments = adjustment_list->entries;

    risk_score = static_cast<short>(
        g_journeyState->river_depth * 2 / 10 +
        g_fordFloatRouteState_0040f270->weather_factor * 10);
    if (risk_score >= 25 && OtRandomBelow_RealCpp(100) < chance) {
        risk_score = static_cast<short>(
            g_journeyState->river_depth * 2 / 10 +
            g_fordFloatRouteState_0040f270->weather_factor * 10);
        probability = ((risk_score * 2) - 60) /
            (g_fordFloatDifficultyScale_0040f270 * 3);
        OtRollRiverCrossingPartyCasualties_0040f1e0_RealCpp(
            static_cast<short>(probability),
            adjustments);

        crossing_factor = static_cast<short>(
            g_journeyState->river_depth / 100 +
            g_fordFloatRouteState_0040f270->ferry_factor);
        probability = ((crossing_factor * 5) + 2) /
            g_fordFloatDifficultyScale_0040f270;
        if (OtResolveRiverCrossingLossAdjustmentList_0000f000_Exact_RealCpp(
                static_cast<short>(probability),
                adjustments) != 0) {
            g_fordFloatSceneMode_0040f270 = 5;
            result_text_id = 0x409;
        }
    }

    delete adjustment_list;
    return static_cast<short>(result_text_id);
}

#pragma optimize("", on)
