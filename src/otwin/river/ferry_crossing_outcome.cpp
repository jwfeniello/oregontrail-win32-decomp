// Product implementation for the ferry river-crossing outcome.

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
struct FerryOutcomeJourneyState_0040f650 {
    char reserved_000[0x54];
    short river_depth;
};

struct FerryRouteState_0040f650 {
    char reserved_00[0x0c];
    short ferry_factor;
};

struct FerryEventAdjustmentListProduct_0040f650 {
    short entries[13];

    FerryEventAdjustmentListProduct_0040f650();
};
#pragma pack(pop)

extern "C" FerryOutcomeJourneyState_0040f650* g_journeyState;
extern "C" FerryRouteState_0040f650* g_activeRouteDescriptor;
extern "C" short g_riverCrossingSceneMode_0040f270;

#define g_riverRouteState_0040f650 g_activeRouteDescriptor
#define g_riverCrossingSceneMode_0040f650 \
    g_riverCrossingSceneMode_0040f270

FerryEventAdjustmentListProduct_0040f650::
    FerryEventAdjustmentListProduct_0040f650()
{
    OtClearEventAdjustmentList_RealCpp(entries);
}

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" short __cdecl OtResolveFerryCrossingOutcome_0040f650_ProductWip()
{
    int result_text_id = 0x41b;
    short danger_score;
    FerryEventAdjustmentListProduct_0040f650* adjustment_list;

    g_riverCrossingSceneMode_0040f650 = 6;
    danger_score =
        static_cast<short>(g_riverRouteState_0040f650->ferry_factor +
                           g_journeyState->river_depth / 100);
    adjustment_list = new FerryEventAdjustmentListProduct_0040f650;

    if (danger_score < 5) {
        danger_score = 0;
    } else {
        if (danger_score < 10) {
            danger_score = 5;
        } else {
            danger_score = 10;
        }
    }

    if (OtRandomBelow_RealCpp(100) < danger_score) {
        OtRollRiverCrossingPartyCasualties_0040f1e0_RealCpp(
            20,
            adjustment_list->entries);
        OtRollRiverCrossingOxLosses_RealCpp(50, adjustment_list->entries);

        if (OtResolveRiverCrossingLossAdjustmentList_0000f000_Exact_RealCpp(
                80,
                adjustment_list->entries) != 0) {
            g_riverCrossingSceneMode_0040f650 = 7;
            result_text_id = 0x41c;
        } else {
            result_text_id = 0x41d;
        }
    }

    delete adjustment_list;
    return static_cast<short>(result_text_id);
}

#pragma optimize("", on)
