// Random hunt-target creation at 0x004129d0.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This recovered runtime requires 32-bit MSVC."
#endif

#include "hunt_runtime_state.h"
#include "../graphics/sprite_blitter_runtime.h"

#pragma pack(push, 1)
struct HuntSprite_00412dd0 {
    char reserved_00[0x1e];
    short state;
    char reserved_20[0x16];
    short draw_order_key;
};

struct HuntState_00412dd0 {
    char reserved_000[0x17c];
    HuntSprite_00412dd0* active_sprites[20];

    int OtAllocateOrderedHuntSpriteSlot_00412dd0_RealCpp(
        register int draw_order_key);
};
#pragma pack(pop)

extern "C" int __cdecl OtRandomBelow_RealCpp(int upper_bound);
extern "C" __declspec(dllimport) OtHuntTick __stdcall timeGetTime();

#pragma comment(lib, "winmm.lib")

#pragma optimize("s", off)
#pragma optimize("t", on)

/**
 * Select and initialize one of the configured hunt targets when the spawn
 * timer and route-specific probability permit it.
 */
void HuntRuntimeState_004122b0_Product::
    OtSpawnRandomHuntTarget_004129d0_Product()
{
    int side_variant;
    int selected_slot;
    int left_height[10];
    int right_height[10];
    int left_width[10];
    int right_width[10];
    int frame_count[10];
    int tick_interval[10];
    register HuntRuntimeState_004122b0_Product* state;
    register int target_type;
    register int y;
    int slot;
    register HuntSprite_004122b0_Product** sprite_slot;
    OtHuntTick now;

    state = this;

    left_width[0] = 0x25;
    left_width[1] = 0x27;
    left_width[2] = 0x27;
    left_width[3] = 0x3a;
    left_width[5] = 0x34;
    left_width[6] = 0x3a;
    left_width[7] = 0x34;
    left_width[4] = 0x38;
    left_width[8] = 0x21;
    left_height[2] = 0x25;
    left_height[3] = 0x26;
    left_height[0] = 0x17;
    left_width[9] = 0x19;
    left_height[4] = 0x2f;
    left_height[6] = 0x32;
    left_height[8] = 0x26;
    left_height[1] = 0x13;
    left_height[5] = 0x2b;
    right_width[2] = 0x27;
    right_width[0] = 0x20;
    right_width[3] = 0x34;
    left_height[7] = 0x1a;
    left_height[9] = 0x1e;
    right_width[1] = 0x24;
    right_width[5] = 0x30;
    right_width[4] = 0x32;
    right_width[6] = 0x36;
    right_width[7] = 0x2c;
    right_width[9] = 0x16;
    right_height[2] = 0x25;
    right_width[8] = 0x1c;
    right_height[0] = 0x14;
    right_height[1] = 0x12;
    right_height[6] = 0x2f;
    right_height[7] = 0x16;
    right_height[3] = 0x22;
    right_height[8] = 0x20;
    frame_count[0] = 5;
    frame_count[1] = 5;
    right_height[4] = 0x2a;
    right_height[5] = 0x28;
    right_height[9] = 0x1a;
    frame_count[2] = 6;
    frame_count[3] = 9;
    frame_count[4] = 9;
    frame_count[6] = 9;
    frame_count[5] = 8;
    frame_count[7] = 10;
    tick_interval[0] = 0x4b;
    tick_interval[3] = 0xc8;
    tick_interval[4] = 0x96;
    tick_interval[5] = 0x55;
    tick_interval[6] = 0xaf;
    tick_interval[7] = 0x7d;
    frame_count[8] = 0x0c;
    frame_count[9] = 0x0c;
    tick_interval[1] = 0x5a;
    tick_interval[2] = 0x5a;
    tick_interval[9] = 0x50;
    tick_interval[8] = 0x5a;

    selected_slot = OtRandomBelow_RealCpp(4);
    target_type = state->target_types[selected_slot];
    side_variant = OtRandomBelow_RealCpp(2);

    now = timeGetTime();
    if (now - state->last_spawn_tick < 300) {
        return;
    }

    state->last_spawn_tick = now;
    if (!state->OtRollHuntTargetSpawnChance_004128c0_RealCpp(target_type)) {
        return;
    }

    if (target_type < 8) {
        if (side_variant == 0) {
            y = OtRandomBelow_RealCpp(
                    0x32 - left_height[target_type]) + 0xc3;
        } else {
            y = OtRandomBelow_RealCpp(
                    0x2f - right_height[target_type]) + 0xa0;
        }
    } else {
        if (side_variant == 0) {
            y = 0x28 - OtRandomBelow_RealCpp(
                    0x32 - left_height[target_type]);
        } else {
            y = 0x46 - OtRandomBelow_RealCpp(
                    0x28 - right_height[target_type]);
        }
    }

    if (side_variant == 0) {
        slot = reinterpret_cast<HuntState_00412dd0*>(state)->
            OtAllocateOrderedHuntSpriteSlot_00412dd0_RealCpp(
                left_height[target_type] + y - 5);
    } else {
        slot = reinterpret_cast<HuntState_00412dd0*>(state)->
            OtAllocateOrderedHuntSpriteSlot_00412dd0_RealCpp(
                right_height[target_type] + y - 5);
    }

    if (slot == -1) {
        return;
    }

    sprite_slot = &state->sprite_slots[slot];
    if (side_variant == 0) {
        (*sprite_slot)->draw_order_key =
            (short)(left_height[target_type] + y - 5);
        (*sprite_slot)->state = 1;
        (*sprite_slot)->source_pixels =
            (unsigned char*)state->target_sprite_pixels[selected_slot * 2];
        (*sprite_slot)->width = (unsigned short)left_width[target_type];
        (*sprite_slot)->height = (unsigned short)left_height[target_type];
    } else {
        (*sprite_slot)->draw_order_key =
            (short)(right_height[target_type] + y - 5);
        (*sprite_slot)->state = 1;
        (*sprite_slot)->source_pixels = (unsigned char*)
            state->target_sprite_pixels[selected_slot * 2 + 1];
        (*sprite_slot)->width = (unsigned short)right_width[target_type];
        (*sprite_slot)->height = (unsigned short)right_height[target_type];
    }

    (*sprite_slot)->source_columns_per_row =
        (unsigned short)frame_count[target_type];
    (*sprite_slot)->animation_frame = 0;
    (*sprite_slot)->transparent_index = 0xe1;
    (*sprite_slot)->tick_interval = (OtHuntTick)tick_interval[target_type];
    (*sprite_slot)->target_type = (unsigned short)target_type;
    (*sprite_slot)->y = (short)y;

    if (target_type != 2) {
        if (OtRandomBelow_RealCpp(2) == 0) {
            (*sprite_slot)->x = -60;
            (*sprite_slot)->trajectory_mode = 0;
        } else {
            (*sprite_slot)->x = 640;
            (*sprite_slot)->trajectory_mode = 1;
        }
    } else if (state->target_side == 0) {
        (*sprite_slot)->x = -60;
        (*sprite_slot)->trajectory_mode = 0;
    } else {
        (*sprite_slot)->x = 640;
        (*sprite_slot)->trajectory_mode = 1;
    }

    reinterpret_cast<SpriteBlitter_00410660_Product*>(*sprite_slot)->
        OtResetSpriteBlitterBitmapInfo_Product_004107b0();
}

#pragma optimize("", on)
