#ifndef OTWIN_RIVER_TRADE_DIALOG_STATE_H
#define OTWIN_RIVER_TRADE_DIALOG_STATE_H

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This recovered runtime requires 32-bit MSVC."
#endif

struct RawIndexedBitmap_00410490_Product;
struct SpriteBlitter_00410660_Product;
struct RiverBitmapInfo_00426270_Product;

typedef void* RiverGlobalHandle_00426270;
typedef void* RiverDeviceContext_004277b0;

#pragma pack(push, 1)
struct RiverTradeDialogState_004277b0_20260604 {
    RiverGlobalHandle_00426270 resource_handles[5];
    void* locked_resources[5];
    RiverGlobalHandle_00426270 scratch_handle;
    int zero_after_init;
    int reserved_30;
    RiverGlobalHandle_00426270 resource_c21_handle;
    void* resource_c21_bits;
    RiverGlobalHandle_00426270 bitmap_info_handle;
    RiverBitmapInfo_00426270_Product* bitmap_info;
    int field_44;
    int field_48;
    int field_4c;
    int field_50;
    RiverGlobalHandle_00426270 resource_c22_handle;
    void* resource_c22_bits;
    RiverDeviceContext_004277b0 dc;
    int mouse_x;
    int selected_or_hovered_item;
    int audio_mode;
    int sound_started;
    void* scratch_bits;
    RawIndexedBitmap_00410490_Product* raw_background;
    SpriteBlitter_00410660_Product* summary_sprite;
    SpriteBlitter_00410660_Product* loss_sprites[4];

    static void* __cdecl operator new(unsigned int bytes);

    void OtMoveRaftTowardPointer_Product_004267b0(
        void* dc,
        int target_x);
    void OtAdvanceRaftObstacles_Product_00426c20(void* dc);
    int OtRunRaftingRoundLoop_Product_004270b0(
        void* dialog);

    RiverTradeDialogState_004277b0_20260604();
};
#pragma pack(pop)

typedef char RiverTradeDialogState_004277b0_20260604_size_must_be_0x8c[
    sizeof(RiverTradeDialogState_004277b0_20260604) == 0x8c ? 1 : -1];

#endif
