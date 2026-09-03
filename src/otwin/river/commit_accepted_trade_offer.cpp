// Semantic candidate for OtCommitAcceptedTradeOffer @ 0x00427d70.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "../trail/trail_event_text_runtime.h"
#include "../trade/trade_adjustment_list.h"

extern "C" __declspec(dllimport) int __stdcall LoadStringA(
    void* instance,
    unsigned int string_id,
    char* buffer,
    int buffer_maximum);
extern "C" __declspec(dllimport) int __cdecl wsprintfA(
    char* buffer,
    const char* format,
    ...);

#pragma comment(lib, "user32.lib")

extern "C" void* __cdecl OtAllocateNewBlock_RealCpp(unsigned int size);
extern "C" short* __fastcall OtClearEventAdjustmentList_RealCpp(short* adjustments);
extern "C" int __cdecl OtRandomBelow_RealCpp(int upper_bound);
extern "C" void* g_applicationModule_00405a40_20260603;
extern "C" int g_tradeOfferAccepted;
extern "C" int g_generalStorePriceTable_00409560_Product[7];
extern "C" const char g_delayDaysFormat_0041ac20[];

extern "C" short g_tradeOfferedItem_00427d70 = 0;
extern "C" short g_tradeOfferedQuantity_00427d70 = 0;
extern "C" short g_tradeReceivedItem_00427d70 = 0;
extern "C" short g_tradeReceivedQuantity_00427d70 = 0;

#pragma pack(push, 1)
struct TradeJourneyState_0041a430_Product {
    char reserved_000[0x5a];
    unsigned short shortage_flags;
    char reserved_05c[0x3a];
    short oxen_count;
    short oxen_sick;
    short clothing;
    short bullets;
    short wheel_count;
    short axle_count;
    short tongue_count;
    short food_whole;
    short food_fraction;
    int cash_cents;
    char reserved_0ac[0x6a];
    short member_state[5];
};

struct TradeOfferRouteDescriptor_00427950_Product {
    unsigned short landmark_id;
    short route_stop_kind;
    short store_price_percent;
};
#pragma pack(pop)

extern "C" TradeJourneyState_0041a430_Product* g_journeyState;
extern "C" TradeOfferRouteDescriptor_00427950_Product*
    g_activeRouteDescriptor;

extern "C" char g_tradeOfferResponseText_00427950_Product[40] = "";
extern "C" char g_tradeOfferRequestText_00427950_Product[40] = "";

#pragma optimize("s", off)
#pragma optimize("t", on)

void* __cdecl TradeAdjustmentList_00427d70::operator new(unsigned int size)
{
    return OtAllocateNewBlock_RealCpp(size);
}

TradeAdjustmentList_00427d70::TradeAdjustmentList_00427d70()
{
    OtClearEventAdjustmentList_RealCpp(adjustments);
}

static short OtClampTradeAdjustment_0041a430(short available, short requested)
{
    return available < requested ? available : requested;
}

static void OtRecoverShortedTradeItem_0041a430(
    TradeJourneyState_0041a430_Product* journey,
    short* count,
    unsigned short flag)
{
    if ((journey->shortage_flags & flag) != 0 && *count > 0) {
        journey->shortage_flags =
            (unsigned short)(journey->shortage_flags ^ flag);
        --*count;
    }
}

void TradeAdjustmentList_00427d70::
    OtApplyEventAdjustmentList_Product_0041a430()
{
    TradeJourneyState_0041a430_Product* journey = g_journeyState;

    adjustments[0] = OtClampTradeAdjustment_0041a430(
        (short)(20 - journey->oxen_count), adjustments[0]);
    adjustments[1] = OtClampTradeAdjustment_0041a430(
        (short)(50 - journey->clothing), adjustments[1]);
    adjustments[2] = OtClampTradeAdjustment_0041a430(
        (short)(2000 - journey->bullets), adjustments[2]);
    adjustments[3] = OtClampTradeAdjustment_0041a430(
        (short)(3 - journey->wheel_count), adjustments[3]);
    adjustments[4] = OtClampTradeAdjustment_0041a430(
        (short)(3 - journey->axle_count), adjustments[4]);
    adjustments[5] = OtClampTradeAdjustment_0041a430(
        (short)(3 - journey->tongue_count), adjustments[5]);
    adjustments[6] = OtClampTradeAdjustment_0041a430(
        (short)((2000 - journey->food_whole) - journey->food_fraction),
        adjustments[6]);

    journey->oxen_count =
        (short)(journey->oxen_count + adjustments[0]);
    if ((journey->shortage_flags & 1) != 0 && journey->oxen_count > 0) {
        journey->shortage_flags =
            (unsigned short)(journey->shortage_flags ^ 1);
        if (journey->oxen_sick != 0) {
            journey->oxen_sick = 0;
            --journey->oxen_count;
        }
    }

    journey->clothing = (short)(journey->clothing + adjustments[1]);
    journey->bullets = (short)(journey->bullets + adjustments[2]);
    journey->wheel_count =
        (short)(journey->wheel_count + adjustments[3]);
    OtRecoverShortedTradeItem_0041a430(
        journey, &journey->wheel_count, 2);
    journey->axle_count =
        (short)(journey->axle_count + adjustments[4]);
    OtRecoverShortedTradeItem_0041a430(
        journey, &journey->axle_count, 4);
    journey->tongue_count =
        (short)(journey->tongue_count + adjustments[5]);
    OtRecoverShortedTradeItem_0041a430(
        journey, &journey->tongue_count, 8);
    journey->food_whole =
        (short)(journey->food_whole + adjustments[6]);
    journey->cash_cents += adjustments[7] * 100;
}

void TradeAdjustmentList_00427d70::
    OtApplyLossEventAdjustmentList_Product_0041a660()
{
    TradeJourneyState_0041a430_Product* journey = g_journeyState;
    short food_loss;
    short member_index;

    adjustments[0] = OtClampTradeAdjustment_0041a430(
        journey->oxen_count, adjustments[0]);
    adjustments[1] = OtClampTradeAdjustment_0041a430(
        journey->clothing, adjustments[1]);
    adjustments[2] = OtClampTradeAdjustment_0041a430(
        journey->bullets, adjustments[2]);
    adjustments[3] = OtClampTradeAdjustment_0041a430(
        journey->wheel_count, adjustments[3]);
    adjustments[4] = OtClampTradeAdjustment_0041a430(
        journey->axle_count, adjustments[4]);
    adjustments[5] = OtClampTradeAdjustment_0041a430(
        journey->tongue_count, adjustments[5]);
    adjustments[6] = OtClampTradeAdjustment_0041a430(
        (short)(journey->food_whole + journey->food_fraction),
        adjustments[6]);

    journey->oxen_count =
        (short)(journey->oxen_count - adjustments[0]);
    if ((journey->shortage_flags & 1) != 0 && journey->oxen_count > 0) {
        journey->shortage_flags =
            (unsigned short)(journey->shortage_flags ^ 1);
        if (journey->oxen_sick != 0) {
            journey->oxen_sick = 0;
            --journey->oxen_count;
        }
    }

    journey->clothing = (short)(journey->clothing - adjustments[1]);
    journey->bullets = (short)(journey->bullets - adjustments[2]);
    journey->wheel_count =
        (short)(journey->wheel_count - adjustments[3]);
    OtRecoverShortedTradeItem_0041a430(
        journey, &journey->wheel_count, 2);
    journey->axle_count =
        (short)(journey->axle_count - adjustments[4]);
    OtRecoverShortedTradeItem_0041a430(
        journey, &journey->axle_count, 4);
    journey->tongue_count =
        (short)(journey->tongue_count - adjustments[5]);
    OtRecoverShortedTradeItem_0041a430(
        journey, &journey->tongue_count, 8);

    food_loss = adjustments[6];
    if (journey->food_fraction < food_loss) {
        adjustments[6] = (short)(food_loss - journey->food_fraction);
        journey->food_fraction =
            journey->food_whole < 2001 ?
                0 : (short)(2000 - journey->food_whole);
        journey->food_whole =
            (short)(journey->food_whole - adjustments[6]);
    } else if ((short)(journey->food_fraction - food_loss) +
                   journey->food_whole < 2001) {
        journey->food_fraction =
            (short)(journey->food_fraction - food_loss);
    } else {
        journey->food_fraction = (short)(2000 - journey->food_whole);
    }

    journey->cash_cents -= adjustments[7] * 100;
    for (member_index = 8; member_index < 13; ++member_index) {
        if (adjustments[member_index] != 0 &&
            journey->member_state[member_index - 8] == 0x0f) {
            adjustments[member_index] = 0;
        }
    }
    for (member_index = 8; member_index < 13; ++member_index) {
        if (adjustments[member_index] != 0) {
            journey->member_state[member_index - 8] = 0x0f;
        }
    }
}

extern "C" void __cdecl OtCommitAcceptedTradeOffer_00027d70_RealCpp()
{
    register TradeAdjustmentList_00427d70* offered_adjustments =
        new TradeAdjustmentList_00427d70;
    register TradeAdjustmentList_00427d70* received_adjustments =
        new TradeAdjustmentList_00427d70;

    offered_adjustments->adjustments[g_tradeOfferedItem_00427d70] =
        g_tradeOfferedQuantity_00427d70;
    offered_adjustments->OtApplyEventAdjustmentList_Product_0041a430();

    received_adjustments->adjustments[g_tradeReceivedItem_00427d70] =
        g_tradeReceivedQuantity_00427d70;
    received_adjustments->OtApplyLossEventAdjustmentList_Product_0041a660();

    g_trailEventRuntimeState.
        OtFormatGameMessageText_0001ac80_ProductWip(0x450);

    delete offered_adjustments;
    delete received_adjustments;

    g_tradeOfferAccepted = 1;
}

#pragma optimize("", on)

#pragma optimize("s", off)
#pragma optimize("t", on)

static __inline int OtTradeOfferUnitValue_00427950_Product(short item)
{
    if (item == 7) {
        return 100;
    }

    return
        (int)g_activeRouteDescriptor->store_price_percent *
        g_generalStorePriceTable_00409560_Product[(int)item] / 100;
}

extern "C" int __stdcall OtBuildTradeOffer_00427950_ProductWip(
    short offered_item,
    short wanted_quantity)
{
    short requested_adjustment_storage[13];
    int tried_items[8];
    char item_text[40];
    register int accepted;
    register short attempts;
    register short offered;
    int requested_quantity;
    int random_factor;
    int requested_value;
    int candidate_item;
    int candidate_unit_value;
    short available_quantity;
    int message_id;

    OtClearEventAdjustmentList_RealCpp(
        requested_adjustment_storage);
    accepted = 0;
    attempts = 1;
    offered = offered_item;
    g_tradeOfferAccepted = 0;

    tried_items[0] = 1;
    tried_items[1] = 1;
    tried_items[2] = 1;
    tried_items[3] = 1;
    tried_items[4] = 1;
    tried_items[5] = 1;
    tried_items[6] = 1;
    tried_items[7] = 1;

    random_factor = OtRandomBelow_RealCpp(0x78) + 100;
    requested_quantity = (int)wanted_quantity;
    g_tradeOfferedItem_00427d70 = offered;
    g_tradeReceivedItem_00427d70 = offered;
    g_tradeOfferedQuantity_00427d70 = wanted_quantity;

    LoadStringA(
        g_applicationModule_00405a40_20260603,
        (offered * 2) + 900 + (wanted_quantity > 1),
        item_text,
        0x27);
    wsprintfA(
        g_tradeOfferRequestText_00427950_Product,
        g_delayDaysFormat_0041ac20,
        requested_quantity,
        item_text);
    g_trailEventRuntimeState.event_argument_pointer =
        g_tradeOfferRequestText_00427950_Product;

    if (OtRandomBelow_RealCpp(2) != 0) {
        g_trailEventRuntimeState.
            OtFormatGameMessageText_0001ac80_ProductWip(0x44d);
        return 0;
    }

    if (reinterpret_cast<TradeAdjustmentList_00427d70*>(
            requested_adjustment_storage)->
            OtWouldExceedInventoryLimit_0041a960_RealCpp(
                offered, wanted_quantity) != 0) {
        g_trailEventRuntimeState.
            OtFormatGameMessageText_0001ac80_ProductWip(
                (offered == 0) + 0x44e);
        return 0;
    }

    tried_items[(int)offered] = 0;
    if (offered == 7) {
        requested_value =
            random_factor * requested_quantity * 100 / 100;
    } else {
        requested_value =
            ((int)g_activeRouteDescriptor->store_price_percent *
                 g_generalStorePriceTable_00409560_Product[(int)offered] /
             100) *
            random_factor * requested_quantity / 100;
    }

    do {
        if (attempts > 7) {
            break;
        }

        g_tradeReceivedItem_00427d70 =
            (short)OtRandomBelow_RealCpp(8);
        candidate_item = (int)g_tradeReceivedItem_00427d70;
        if (tried_items[candidate_item] == 0) {
            goto candidate_rejected;
        }

        ++attempts;
        tried_items[candidate_item] = 0;
        candidate_unit_value =
            OtTradeOfferUnitValue_00427950_Product(
                g_tradeReceivedItem_00427d70);
        g_tradeReceivedQuantity_00427d70 =
            (short)(requested_value / candidate_unit_value);
        if (g_tradeReceivedQuantity_00427d70 < 1) {
            goto candidate_rejected;
        }

        switch (candidate_item) {
        case 0:
            if (g_journeyState->oxen_count <=
                g_tradeReceivedQuantity_00427d70) {
                goto candidate_rejected;
            }
            accepted = 1;
            break;

        case 1:
            available_quantity = g_journeyState->clothing;
            goto compare_available_quantity;

        case 2:
            available_quantity = g_journeyState->bullets;
            goto compare_available_quantity;

        case 3:
            available_quantity = g_journeyState->wheel_count;
            goto compare_available_quantity;

        case 4:
            available_quantity = g_journeyState->axle_count;
            goto compare_available_quantity;

        case 5:
            available_quantity = g_journeyState->tongue_count;
            goto compare_available_quantity;

        case 6:
            available_quantity = (short)(
                g_journeyState->food_whole +
                g_journeyState->food_fraction);

compare_available_quantity:
            if (available_quantity >=
                g_tradeReceivedQuantity_00427d70) {
                accepted = 1;
            }
            break;

        case 7:
            if ((int)g_tradeReceivedQuantity_00427d70 * 100 <=
                g_journeyState->cash_cents) {
                accepted = 1;
            }
            break;
        }

candidate_rejected:
        ;
    } while (accepted == 0);

    if (accepted == 0) {
        message_id = 0x44d;
    } else {
        LoadStringA(
            g_applicationModule_00405a40_20260603,
            (g_tradeReceivedItem_00427d70 * 2) + 900 +
                (g_tradeReceivedQuantity_00427d70 > 1),
            item_text,
            0x27);
        wsprintfA(
            g_tradeOfferResponseText_00427950_Product,
            g_delayDaysFormat_0041ac20,
            (int)g_tradeReceivedQuantity_00427d70,
            item_text);
        g_trailEventRuntimeState.name_pointer =
            g_tradeOfferResponseText_00427950_Product;
        message_id = 0x44c;
    }

    g_trailEventRuntimeState.
        OtFormatGameMessageText_0001ac80_ProductWip(message_id);
    return accepted;
}

#pragma optimize("", on)
