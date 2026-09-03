// Product-semantic constructor for the Trade Offer dialog-owned bitmap state.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "../graphics/positioned_bitmap_descriptor_state.h"

#pragma pack(push, 1)
struct TradeOfferDialogState_0040d580_Product {
    PositionedBitmapDescriptorState_0040ba40 leading_bitmap_0;
    PositionedBitmapDescriptorState_0040ba40 leading_bitmap_1;
    int* accepted_result;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_0;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_1;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_2;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_3;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_4;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_5;

    TradeOfferDialogState_0040d580_Product();
};
#pragma pack(pop)

typedef char OtTradeOfferBitmapSizeMustBe40[
    sizeof(PositionedBitmapDescriptorState_0040ba40) == 0x28 ? 1 : -1];
typedef char OtTradeOfferResultOffsetMustBe50[
    (unsigned int)&(((TradeOfferDialogState_0040d580_Product*)0)->
        accepted_result) == 0x050
        ? 1
        : -1];
typedef char OtTradeOfferFirstActionBitmapOffsetMustBe54[
    (unsigned int)&(((TradeOfferDialogState_0040d580_Product*)0)->
        action_bitmap_0) == 0x054
        ? 1
        : -1];
typedef char OtTradeOfferLastBitmapOffsetMustBe11c[
    (unsigned int)&(((TradeOfferDialogState_0040d580_Product*)0)->
        action_bitmap_5) == 0x11c
        ? 1
        : -1];
typedef char OtTradeOfferDialogStateSizeMustBe144[
    sizeof(TradeOfferDialogState_0040d580_Product) == 0x144 ? 1 : -1];

#pragma optimize("s", off)
#pragma optimize("t", on)

TradeOfferDialogState_0040d580_Product::
    TradeOfferDialogState_0040d580_Product()
{
}

#pragma optimize("", on)
