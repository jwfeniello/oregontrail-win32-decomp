#ifndef OTWIN_RIVER_CROSSING_STATE_RUNTIME_H
#define OTWIN_RIVER_CROSSING_STATE_RUNTIME_H

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This recovered runtime requires 32-bit MSVC."
#endif

struct RawIndexedBitmap_00410490_Product;
struct SpriteBlitter_00410660_Product;

#pragma pack(push, 1)
struct PaletteEntry_004285a0_ProductWip {
    unsigned char red;
    unsigned char green;
    unsigned char blue;
    unsigned char flags;
};

struct RiverCrossingState_004285a0_ProductWip {
    int reserved_00;
    short crossing_mode;
    short crossing_choice;
    int reserved_08;
    int primary_frame_count;
    int secondary_frame_count;
    int reserved_14;
    PaletteEntry_004285a0_ProductWip palette_entries[8];
    void* crash_sound_resource;
    int reserved_3c;
    void* caption_window;
    void* scratch_handle;
    void* scratch_bits;
    void* resource_handle_4c;
    void* resource_bits_50;
    void* resource_handle_54;
    void* resource_bits_58;
    void* resource_handle_5c;
    void* resource_bits_60;
    void* resource_handle_64;
    void* resource_bits_68;
    void* resource_handle_6c;
    void* resource_handle_70;
    void* resource_handle_74;
    void* resource_handle_78;
    void* resource_bits_7c;
    void* resource_bits_80;
    void* resource_bits_84;
    void* resource_bits_88;
    RawIndexedBitmap_00410490_Product* base_bitmap;
    enum SpriteSlot {
        kFarBankSpriteSlot,
        kNearBankSpriteSlot,
        kWagonSpriteSlot,
        kCrossingSpriteSlot,
        kEffectSpriteASlot,
        kEffectSpriteBSlot,
        kEffectSpriteCSlot,
        kEffectSpriteDSlot,
        kSpriteSlotCount
    };
    SpriteBlitter_00410660_Product* sprite_slots[kSpriteSlotCount];

    int OtInitRiverSpriteLayerFromResource_Product(
        void* module,
        const void* resource_name,
        SpriteBlitter_00410660_Product* sprite,
        void** resource_handle,
        void* reserved_bits,
        int width,
        int height,
        int requested_x,
        int requested_y,
        int source_columns,
        int mode);

    RiverCrossingState_004285a0_ProductWip(
        void* owner_window,
        short choice,
        short crossing_mode_value);

    void OtStopSfxAndWaveAudio_RealCpp();
    void OtDestroyRiverCrossingState_Product_00428bf0();
};
#pragma pack(pop)

typedef char RiverCrossingState_004285a0_size_must_be_0xb0[
    sizeof(RiverCrossingState_004285a0_ProductWip) == 0xb0 ? 1 : -1];

#endif
