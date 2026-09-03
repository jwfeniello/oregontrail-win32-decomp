#ifndef OTWIN_TRADE_GENERAL_STORE_DIALOG_STATE_H
#define OTWIN_TRADE_GENERAL_STORE_DIALOG_STATE_H

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This recovered Product state requires 32-bit Microsoft C++."
#endif

#include "../graphics/positioned_bitmap_descriptor_state.h"

#pragma pack(push, 1)
struct GeneralStoreDialogState_00407340_Product {
    PositionedBitmapDescriptorState_0040ba40 information_default;
    PositionedBitmapDescriptorState_0040ba40 information_pressed;
    PositionedBitmapDescriptorState_0040ba40 buy_default;
    PositionedBitmapDescriptorState_0040ba40 buy_pressed;
    PositionedBitmapDescriptorState_0040ba40 leave_default;
    PositionedBitmapDescriptorState_0040ba40 leave_pressed;
    PositionedBitmapDescriptorState_0040ba40 dialog_backdrop;
    RectResource_0040b690 backdrop_fill_rect;
};
#pragma pack(pop)

typedef char OtGeneralStorePositionedBitmapSizeMustBe028[
    sizeof(PositionedBitmapDescriptorState_0040ba40) == 0x28 ? 1 : -1];
typedef char OtGeneralStoreRectResourceSizeMustBe010[
    sizeof(RectResource_0040b690) == 0x10 ? 1 : -1];
typedef char OtGeneralStoreDialogStateSizeMustBe128[
    sizeof(GeneralStoreDialogState_00407340_Product) == 0x128 ? 1 : -1];

#endif
