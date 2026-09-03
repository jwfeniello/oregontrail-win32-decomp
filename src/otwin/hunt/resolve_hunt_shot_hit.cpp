// Semantic recovery of hunt-shot collision resolution at 0x00414860.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This recovered runtime requires 32-bit MSVC."
#endif

#include "hunt_runtime_state.h"

struct SpriteBufferSampler_00410cf0_47pct {
    short OtSampleSpriteBufferPixelAlt10_00410cf0_47pct(
        short x,
        short y) const;
};

extern "C" int DAT_004390e8;
extern "C" int __cdecl OtRandomBelow_RealCpp(int upper_bound);
extern "C" __declspec(dllimport) int __stdcall sndPlaySoundA(
    const char* sound,
    unsigned int flags);

#pragma comment(lib, "winmm.lib")

#pragma optimize("s", off)
#pragma optimize("t", on)

void HuntRuntimeState_004122b0_Product::OtResolveHuntShotHit_Product()
{
    unsigned short target_type;
    int shot_x_value;
    int shot_y_value;
    int sprite_x;
    int sprite_y;
    int slot;
    short state;
    const char* sound;
    HuntSprite_004122b0_Product* sprite;
    HuntSprite_004122b0_Product** cursor;
    int hit_slot;
    int hit_found;
    int hit_damage[40];

    hit_damage[0] = 3;
    slot = 0;
    hit_slot = -1;
    hit_damage[1] = 3;
    hit_damage[2] = 0;
    hit_damage[4] = 3;
    hit_damage[5] = 3;
    hit_damage[3] = 4;
    hit_damage[7] = 8;
    hit_damage[10] = 0x12;
    hit_damage[6] = 3;
    hit_damage[13] = 0x20;
    hit_damage[8] = 10;
    hit_damage[9] = 10;
    hit_damage[11] = 0x0f;
    hit_damage[12] = 0x25;
    hit_damage[15] = 0x20;
    hit_damage[18] = 10;
    hit_damage[14] = 0x29;
    hit_damage[16] = 0x23;
    hit_damage[17] = 0x16;
    hit_damage[19] = 6;

    do {
        state = sprite_slots[slot]->state;
        if (state == 0) {
            break;
        }
        if (state == 99) {
            hit_slot = slot;
        }
        ++slot;
    } while (slot < 19);

    if (hit_slot == -1) {
        return;
    }

    cursor = &sprite_slots[hit_slot - 1];
    hit_found = 0;
    do {
        --hit_slot;
        if (hit_slot < 0) {
            return;
        }

        sprite = *cursor;
        shot_x_value = shot_x;
        sprite_x = sprite->x;
        if (sprite_x <= shot_x_value &&
            shot_x_value + 5 <
                (int)((unsigned int)sprite->width + sprite_x)) {
            sprite_y = sprite->y;
            shot_y_value = shot_y;
            if (sprite_y <= shot_y_value &&
                shot_y_value + 5 <
                    (int)((unsigned int)sprite->height + sprite_y)) {
                state = reinterpret_cast<SpriteBufferSampler_00410cf0_47pct*>(
                    sprite)->OtSampleSpriteBufferPixelAlt10_00410cf0_47pct(
                        (short)((shot_x_value - sprite_x) + 2),
                        (short)((shot_y_value - sprite_y) + 2));
                if ((int)state != -1) {
                    sprite = *cursor;
                    if ((unsigned int)sprite->transparent_index !=
                        (int)state) {
                        state = sprite->state;
                        if ((state == 1 || state == 6 || state == 4) &&
                            sprite->target_type != 2) {
                            target_type = sprite->target_type;
                            sprite->animation_frame =
                                (short)hit_damage[target_type];
                            (*cursor)->state = 5;
                            sprite = *cursor;
                            sprite->draw_order_key =
                                (short)hit_damage[sprite->target_type + 10] +
                                sprite->y;
                            sprite = *cursor;
                            if (sprite->target_type > 7) {
                                sprite->fall_remove_y =
                                    (short)(0xe6 - sprite->y);
                            }

                            hit_damage[30] = 1;
                            hit_damage[31] = 1;
                            hit_damage[32] = 0;
                            hit_damage[33] = 0xfa;
                            hit_damage[34] = 0x23;
                            hit_damage[35] = 0x14;
                            hit_damage[36] = 0xaf;
                            hit_damage[37] = 0x5a;
                            hit_damage[38] = 1;
                            hit_damage[39] = 1;
                            hit_damage[20] = 2;
                            hit_damage[21] = 1;
                            hit_damage[22] = 0;
                            hit_damage[23] = 0x10e;
                            hit_damage[24] = 0x19;
                            hit_damage[25] = 10;
                            hit_damage[26] = 0xb4;
                            hit_damage[27] = 0x1e;
                            hit_damage[28] = 3;
                            target_type = (*cursor)->target_type;
                            hit_damage[29] = 1;
                            meat_pounds +=
                                hit_damage[target_type + 30] +
                                OtRandomBelow_RealCpp(
                                    hit_damage[target_type + 20]);

                            if (DAT_004390e8 != 0 &&
                                (*cursor)->target_type < 8) {
                                sndPlaySoundA(0, 0);
                                state = (*cursor)->target_type;
                                if (state == 0 || state == 1 || state == 5) {
                                    sound = sound_data[3];
                                } else {
                                    sound = sound_data[2];
                                }
                                sndPlaySoundA(sound, 5);
                            }
                        }
                        hit_found = 1;
                    }
                }
            }
        }

        --cursor;
    } while (hit_found == 0);
}

#pragma optimize("", on)
