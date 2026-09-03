// Hunt-target animation and behavior update recovered from 0x00413d20.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This recovered runtime requires 32-bit MSVC."
#endif

#include "hunt_runtime_state.h"
#include "../graphics/raw_indexed_bitmap_runtime.h"
#include "../graphics/sprite_blitter_runtime.h"

extern "C" int __cdecl OtRandomBelow_RealCpp(int upper_bound);
extern "C" __declspec(dllimport) OtHuntTick __stdcall timeGetTime();
extern "C" __declspec(dllimport) int __stdcall sndPlaySoundA(
    const char* sound_name,
    unsigned int flags);
extern "C" int DAT_004390e8;

struct OtHuntState_004138d0_20260605 {
    int OtShouldRemoveFallingHuntTarget_004138d0_20260605_ReccmpP3(
        int slot_index);
};

#pragma comment(lib, "winmm.lib")

#pragma optimize("s", off)
#pragma optimize("t", on)

/**
 * Advance every active hunt target by one timed behavior step.
 *
 * The sentinel state at the end of sprite_slots terminates the walk.  The
 * per-target tables retain the original game's movement speeds, animation
 * lengths, and random transition probabilities.
 */
void HuntRuntimeState_004122b0_Product::
    OtAdvanceHuntTargets_00413d20_Product(void* draw_context)
{
    HuntSprite_004122b0_Product** redraw_cursor;
    HuntSprite_004122b0_Product* timed_sprite;
    unsigned short random_direction;
    short state_or_speed;
    OtHuntTick now;
    HuntSprite_004122b0_Product* sprite;
    int next_frame;
    unsigned short target_type;
    unsigned short* direction_cell;
    HuntSprite_004122b0_Product** slot_cursor;
    int slot_index;
    int redraw_slot;
    int target_speed[10];
    int target_behavior[40];
    OtHuntTick previous_shot_tick;

    target_speed[0] = 15;
    target_speed[1] = 15;
    target_speed[2] = 20;
    target_speed[3] = 5;
    target_speed[4] = 15;
    target_speed[5] = 20;
    target_speed[6] = 15;
    target_speed[7] = 5;
    target_speed[8] = 15;
    target_speed[9] = 20;

    target_behavior[30] = 3;
    target_behavior[31] = 3;
    target_behavior[34] = 3;
    target_behavior[35] = 3;
    target_behavior[36] = 3;
    target_behavior[38] = 10;
    target_behavior[39] = 10;
    target_behavior[32] = 6;
    target_behavior[33] = 4;
    target_behavior[37] = 8;
    target_behavior[20] = 6;
    target_behavior[21] = 6;
    target_behavior[22] = 0;
    target_behavior[23] = 1;
    target_behavior[25] = 4;
    target_behavior[28] = 0;
    target_behavior[29] = 0;
    target_behavior[10] = 0;
    target_behavior[11] = 0;
    target_behavior[12] = 0;
    target_behavior[13] = 1;
    target_behavior[14] = 1;
    target_behavior[15] = 1;
    target_behavior[16] = 1;
    target_behavior[17] = 0;
    target_behavior[24] = 3;
    target_behavior[0] = 5;
    target_behavior[1] = 5;
    target_behavior[26] = 2;
    target_behavior[27] = 2;
    target_behavior[18] = 0;
    target_behavior[4] = 5;
    target_behavior[5] = 5;
    target_behavior[6] = 5;
    target_behavior[7] = 10;
    target_behavior[19] = 0;
    target_behavior[2] = 0;
    target_behavior[3] = 6;

    slot_index = 0;
    target_behavior[8] = 12;
    target_behavior[9] = 12;

    if (sprite_slots[0]->state == 0) {
        return;
    }

    slot_cursor = sprite_slots;
    do {
        previous_shot_tick = last_shot_tick;
        if (previous_shot_tick != 0 &&
            timeGetTime() - previous_shot_tick > 20000UL) {
            last_shot_tick = 0;
        }

        state_or_speed = (*slot_cursor)->state;
        if (state_or_speed == 1 || state_or_speed == 6 ||
            state_or_speed == 4 || state_or_speed == 5) {
            now = timeGetTime();
            timed_sprite = *slot_cursor;
            if (timed_sprite->tick_interval < now - timed_sprite->last_tick) {
                timed_sprite->last_tick = now;
                if ((*slot_cursor)->state == 5) {
                    target_type = (*slot_cursor)->target_type;
                    if (target_type >= 8) {
                        sprite = *slot_cursor;
                        sprite->y +=
                            (short)(45 - (short)target_speed[target_type]);
                        sprite = *slot_cursor;
                        if (sprite->trajectory_mode == 1) {
                            sprite->x -= 10;
                        } else {
                            sprite->x += 10;
                        }

                        sprite = *slot_cursor;
                        if (sprite->fall_remove_y <= sprite->y) {
                            sprite->state = 2;
                            (*slot_cursor)->animation_frame =
                                (short)((*slot_cursor)->source_columns_per_row -
                                        1);
                            if (reinterpret_cast<
                                    OtHuntState_004138d0_20260605*>(this)->
                                    OtShouldRemoveFallingHuntTarget_004138d0_20260605_ReccmpP3(
                                        slot_index) == 0) {
                                if (DAT_004390e8 != 0) {
                                    sndPlaySoundA(0, 0);
                                    sndPlaySoundA(sound_data[3], 5);
                                }
                            } else {
                                if (DAT_004390e8 != 0) {
                                    sndPlaySoundA(0, 0);
                                    sndPlaySoundA(sound_data[4], 5);
                                }

                                reinterpret_cast<
                                    SpriteBlitter_00410660_Product*>(
                                    *slot_cursor)->
                                    OtExtractSpriteRegionToBuffer_Product_00410840(
                                        reinterpret_cast<
                                            RawIndexedBitmap_00410490_Product*>(
                                            frame_buffer),
                                        scratch_pixels);

                                redraw_slot = 0;
                                if (sprite_slots[0]->state != 0) {
                                    redraw_cursor = sprite_slots;
                                    do {
                                        if (slot_index != redraw_slot) {
                                            reinterpret_cast<
                                                SpriteBlitter_00410660_Product*>(
                                                *redraw_cursor)->
                                                OtCompositeSpriteIntoBuffer_Product_00410a30(
                                                    reinterpret_cast<
                                                        SpriteBlitter_00410660_Product*>(
                                                        *slot_cursor),
                                                    scratch_pixels,
                                                    reinterpret_cast<
                                                        RawIndexedBitmap_00410490_Product*>(
                                                        frame_buffer));
                                        }

                                        ++redraw_cursor;
                                        ++redraw_slot;
                                    } while ((*redraw_cursor)->state != 0);
                                }

                                reinterpret_cast<
                                    SpriteBlitter_00410660_Product*>(
                                    *slot_cursor)->
                                    OtBlitSpriteBuffer_Product_004106e0(
                                        draw_context,
                                        reinterpret_cast<
                                            RawIndexedBitmap_00410490_Product*>(
                                            frame_buffer),
                                        scratch_pixels);
                                OtRemoveHuntSpriteSlot_Product(slot_index);
                            }
                        }

                        if (OtAdvanceHuntTargetPathing_00413030_Product(
                                slot_index) == 1) {
                            goto redraw_advanced_target;
                        }
                        goto advance_behavior;
                    }

                    {
                        short* animation_frame_cursor;

                        sprite = *slot_cursor;
                        animation_frame_cursor =
                            &sprite->animation_frame;
                        next_frame =
                            (unsigned short)*animation_frame_cursor + 1;
                        if (target_behavior[target_type] <= next_frame) {
                            sprite->state = 2;
                            goto advance_behavior;
                        }

                        *animation_frame_cursor = (short)next_frame;
                        sprite = *slot_cursor;
                        if (sprite->trajectory_mode != 1) {
                            sprite->x +=
                                (short)target_speed[sprite->target_type];
                        } else {
                            sprite->x -=
                                (short)target_speed[sprite->target_type];
                        }

                        if (OtAdvanceHuntTargetPathing_00413030_Product(
                                slot_index) != 1) {
                            goto advance_behavior;
                        }
                    }

redraw_advanced_target:
                    OtRedrawHuntSpriteSlot_Product(
                        draw_context,
                        slot_index);
                }

advance_behavior:
                if ((*slot_cursor)->state == 6) {
                    if (OtRandomBelow_RealCpp(100) < 1) {
                        (*slot_cursor)->state = 1;
                        (*slot_cursor)->animation_frame = 0;
                        random_direction =
                            (unsigned short)OtRandomBelow_RealCpp(2);
                        (*slot_cursor)->trajectory_mode = random_direction;
                    } else if (OtRandomBelow_RealCpp(100) < 10) {
                        (*slot_cursor)->state = 4;
                        state_or_speed =
                            (short)OtRandomBelow_RealCpp(2);
                        (*slot_cursor)->animation_frame =
                            (short)((short)(*slot_cursor)->
                                        source_columns_per_row +
                                    state_or_speed - 3);
                        OtRedrawHuntSpriteSlot_Product(
                            draw_context,
                            slot_index);
                    }
                }

                if ((*slot_cursor)->state == 4) {
                    if (OtRandomBelow_RealCpp(100) < 1) {
                        (*slot_cursor)->state = 1;
                        (*slot_cursor)->animation_frame = 0;
                        random_direction =
                            (unsigned short)OtRandomBelow_RealCpp(2);
                        (*slot_cursor)->trajectory_mode = random_direction;
                    } else {
                        if (OtRandomBelow_RealCpp(100) < 1) {
                            (*slot_cursor)->state = 6;
                            (*slot_cursor)->animation_frame =
                                (short)(
                                    (*slot_cursor)->source_columns_per_row -
                                    1);
                        } else {
                            if (OtRandomBelow_RealCpp(100) >= 5) {
                                goto after_state4_transition;
                            }

                            state_or_speed =
                                (short)OtRandomBelow_RealCpp(2);
                            (*slot_cursor)->animation_frame =
                                (short)((short)(*slot_cursor)->
                                            source_columns_per_row +
                                        state_or_speed - 3);
                        }

                        OtRedrawHuntSpriteSlot_Product(
                            draw_context,
                            slot_index);
                    }
                }

after_state4_transition:
                if ((*slot_cursor)->state == 1 &&
                    target_behavior[(*slot_cursor)->target_type + 10] != 0 &&
                    OtRandomBelow_RealCpp(100) < 5 &&
                    last_shot_tick == 0) {
                    (*slot_cursor)->state = 6;
                    (*slot_cursor)->animation_frame =
                        (short)((*slot_cursor)->source_columns_per_row - 1);
                    OtRedrawHuntSpriteSlot_Product(
                        draw_context,
                        slot_index);
                }

                sprite = *slot_cursor;
                if (sprite->state == 1) {
                    int extra_speed;

                    next_frame =
                        target_behavior[sprite->target_type + 20];
                    if (next_frame != 0 &&
                        OtRandomBelow_RealCpp(100) <
                            next_frame) {
                        direction_cell = &(*slot_cursor)->trajectory_mode;
                        if (*direction_cell == 0) {
                            *direction_cell = 1;
                        } else {
                            *direction_cell = 0;
                        }
                    }

                    extra_speed = 0;
                    if (last_shot_tick > 0) {
                        extra_speed = 3;
                    }

                    sprite = *slot_cursor;
                    if (sprite->trajectory_mode != 1) {
                        sprite->x +=
                            (short)(target_speed[sprite->target_type] +
                                    extra_speed);
                    } else {
                        sprite->x -=
                            (short)(target_speed[sprite->target_type] +
                                    extra_speed);
                    }

                    if (OtAdvanceHuntTargetPathing_00413030_Product(
                            slot_index) == 1) {
                        ++(*slot_cursor)->animation_frame;
                        sprite = *slot_cursor;
                        if (target_behavior[sprite->target_type + 30] <=
                            (unsigned short)sprite->animation_frame) {
                            sprite->animation_frame = 0;
                        }
                    }

                    OtRedrawHuntSpriteSlot_Product(
                        draw_context,
                        slot_index);
                }
            }
        }

        ++slot_cursor;
        ++slot_index;
        OtAdvanceHuntProjectile_00414450_Product(draw_context);
    } while ((*slot_cursor)->state != 0);
}

#pragma optimize("", on)
