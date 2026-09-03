#ifndef OTWIN_HUNT_RUNTIME_STATE_H
#define OTWIN_HUNT_RUNTIME_STATE_H

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This recovered runtime requires 32-bit MSVC."
#endif

#include <stddef.h>

typedef unsigned long OtHuntTick;

#pragma pack(push, 1)
struct HuntSprite_004122b0_Product {
    OtHuntTick last_tick;
    OtHuntTick tick_interval;
    unsigned char* source_pixels;
    short animation_frame;
    unsigned short source_columns_per_row;
    unsigned short transparent_index;
    char reserved_012[0x08];
    unsigned short trajectory_mode;
    unsigned short target_type;
    short state;
    char reserved_020[0x08];
    short x;
    short y;
    unsigned short width;
    unsigned short height;
    char reserved_030[0x04];
    short fall_remove_y;
    short draw_order_key;
};

struct HuntPositionedBitmap_004122b0_Product {
    char storage[0x28];

    HuntPositionedBitmap_004122b0_Product();
    ~HuntPositionedBitmap_004122b0_Product();
};

struct HuntRawIndexedBitmap_004122b0_Product {
    char storage;
};

struct HuntRuntimeState_004122b0_Product {
    int redraw_pending;
    void* state_memory_handle;
    unsigned char* scratch_pixels;
    int meat_pounds;
    int bullets_fired;
    int bullets_available;
    void* target_resource_pairs[8];
    void* target_sprite_pixels[8];
    void* projectile_resource;
    void* projectile_pixels;
    int target_types[4];
    int target_side;
    int projectile_slope;
    int projectile_intercept;
    OtHuntTick last_spawn_tick;
    void* sound_resources[5];
    const char* sound_data[5];
    int active_round;
    int round_running;
    int cursor_state;
    int round_done;
    void* render_context;
    HuntPositionedBitmap_004122b0_Product bitmap_0bc;
    HuntPositionedBitmap_004122b0_Product bitmap_0e4;
    HuntPositionedBitmap_004122b0_Product bitmap_10c;
    HuntPositionedBitmap_004122b0_Product bitmap_134;
    OtHuntTick last_shot_tick;
    int scene_variant_offset;
    int scene_base_resource;
    int shot_x;
    int shot_y;
    void* default_cursor;
    void* hunt_cursor;
    HuntRawIndexedBitmap_004122b0_Product* frame_buffer;
    HuntSprite_004122b0_Product* sprite_slots[20];

    ~HuntRuntimeState_004122b0_Product();

    int OtCurrentHuntSceneResourceId_00413030() const
    {
        return scene_variant_offset + scene_base_resource;
    }

    int OtChooseHuntSceneResourceId_Product();
    int OtRollHuntTargetSpawnChance_004128c0_RealCpp(int target_type);
    void OtSpawnRandomHuntTarget_004129d0_Product();
    void OtRemoveHuntSpriteSlot_Product(int slot_index);
    int OtAdvanceHuntTargetPathing_00413030_Product(int slot_index);
    void OtAdvanceHuntTargets_00413d20_Product(void* draw_context);
    void OtAdvanceHuntProjectile_00414450_Product(void* draw_context);
    int OtRunHuntRoundLoop_00414ba0_Product(void* dialog);
    void OtResolveHuntShotHit_Product();
    void OtRedrawHuntSceneWithoutSpriteSlot_Product(
        void* draw_context,
        int omitted_slot);
    void OtRedrawHuntSpriteSlot_Product(void* draw_context, int slot);
};

#pragma pack(pop)

typedef char HuntRuntimeState_004122b0_Product_size_must_be_0x1cc[
    sizeof(HuntRuntimeState_004122b0_Product) == 0x1cc ? 1 : -1];
typedef char HuntSprite_004122b0_Product_size_must_be_0x38[
    sizeof(HuntSprite_004122b0_Product) == 0x38 ? 1 : -1];
typedef char HuntSprite_state_offset_must_be_0x1e[
    offsetof(HuntSprite_004122b0_Product, state) == 0x1e ? 1 : -1];
typedef char HuntSprite_position_offset_must_be_0x28[
    offsetof(HuntSprite_004122b0_Product, x) == 0x28 ? 1 : -1];
typedef char HuntSprite_draw_order_offset_must_be_0x36[
    offsetof(HuntSprite_004122b0_Product, draw_order_key) == 0x36 ? 1 : -1];
typedef char HuntRuntime_target_pixels_offset_must_be_0x38[
    offsetof(HuntRuntimeState_004122b0_Product, target_sprite_pixels) ==
        0x38 ? 1 : -1];
typedef char HuntRuntime_target_types_offset_must_be_0x60[
    offsetof(HuntRuntimeState_004122b0_Product, target_types) == 0x60 ?
        1 : -1];
typedef char HuntRuntime_target_side_offset_must_be_0x70[
    offsetof(HuntRuntimeState_004122b0_Product, target_side) == 0x70 ?
        1 : -1];
typedef char HuntRuntime_last_spawn_offset_must_be_0x7c[
    offsetof(HuntRuntimeState_004122b0_Product, last_spawn_tick) == 0x7c ?
        1 : -1];
typedef char HuntRuntime_round_flags_offset_must_be_0xa8[
    offsetof(HuntRuntimeState_004122b0_Product, active_round) == 0xa8 ?
        1 : -1];
typedef char HuntRuntime_render_context_offset_must_be_0xb8[
    offsetof(HuntRuntimeState_004122b0_Product, render_context) == 0xb8 ?
        1 : -1];
typedef char HuntRuntime_sprite_slots_offset_must_be_0x17c[
    offsetof(HuntRuntimeState_004122b0_Product, sprite_slots) == 0x17c ?
        1 : -1];

#endif
