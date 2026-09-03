// Focused semantic promotion for river-crossing backdrop phase dispatch.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "raft_crash_sound_state.h"

#pragma pack(push, 1)
struct RiverCrossingBackdropSprite_00428480 {
    char reserved_00[0x0c];
    unsigned short frame;
    unsigned short frame_count;
    char reserved_10[0x0e];
    short active;
    char reserved_20[0x08];
    short x;
    short y;
    unsigned short width;
    unsigned short height;
};

struct RiverCrossingBackdropState_00428480 {
    char reserved_00[4];
    short phase;
    char reserved_06[0x9a];
    RiverCrossingBackdropSprite_00428480* foreground_layer;

    void OtRenderRiverCrossingBackdrop_00428480_RealCpp(void* owner);
};

struct RiverCrashBitmap_00428020_Product {
    char reserved_00[0x10];
    unsigned int width;
    unsigned int height;
};

struct RiverCrashState_00428020_Product {
    char reserved_00[0x8c];
    RiverCrashBitmap_00428020_Product* base_bitmap;
    char reserved_90[0x08];
    RiverCrossingBackdropSprite_00428480* primary;
    RiverCrossingBackdropSprite_00428480* aftermath;
    RiverCrossingBackdropSprite_00428480* debris;

    void OtAdvanceRiverCrashVariantA_Product_00428020(unsigned int tick);
    void OtAdvanceRiverCrashVariantB_Product_004281c0(unsigned int tick);
    void OtAdvanceRiverCrashVariantC_Product_00428370(unsigned int tick);
};

struct RiverCrashPreludeState_00427f40_Product {
    char reserved_00[0x9c];
    RiverCrossingBackdropSprite_00428480* source;
    RiverCrossingBackdropSprite_00428480* lead;
    RiverCrossingBackdropSprite_00428480* wake;
    RiverCrossingBackdropSprite_00428480* foam;
    RiverCrossingBackdropSprite_00428480* splash;

    void OtRiverCrashDialogPrelude_Product_00427f40(unsigned int tick);
};

struct RiverCounterOwner_00428180_Product {
    char reserved_00[0x98];
    RiverCrossingBackdropSprite_00428480* counters;

    void OtStepRiverCounterPairA_Product_00428180(unsigned int flags);
    void OtStepRiverCounterPairB_Product_004281a0(unsigned int flags);
};

struct RiverCrossingProgressState_004282e0 {
    void OtRiver_AdvanceCrossingProgress_004282e0_RealCpp(unsigned int tick);
};

#pragma pack(pop)

typedef char RiverCrashState_00428020_Product_size_must_be_0xa4[
    sizeof(RiverCrashState_00428020_Product) == 0xa4 ? 1 : -1];

extern "C" int g_cdMediaMode_00439108;

#pragma optimize("s", off)
#pragma optimize("t", on)

void RiverCrashPreludeState_00427f40_Product::
    OtRiverCrashDialogPrelude_Product_00427f40(unsigned int tick)
{
    if ((tick & 1) != 0) {
        return;
    }

    lead->x = (short)(lead->x - 2);
    if (wake->active == 0) {
        wake->active = 1;
        wake->x = source->x;
        wake->y = source->y;
        foam->active = 1;
        foam->x = source->x;
        foam->y = source->y;
        return;
    }

    --wake->y;
    ++foam->y;
    if (splash->active == 0) {
        splash->active = 1;
        splash->x = source->x;
        splash->y = source->y;
        return;
    }

    ++splash->x;
}

void RiverCounterOwner_00428180_Product::
    OtStepRiverCounterPairA_Product_00428180(unsigned int flags)
{
    if ((flags & 1) == 0) {
        counters->x = (short)(counters->x - 2);
        --counters->y;
    }
}

void RiverCounterOwner_00428180_Product::
    OtStepRiverCounterPairB_Product_004281a0(unsigned int flags)
{
    if ((flags & 1) == 0) {
        counters->x = (short)(counters->x - 2);
        --counters->y;
    }
}

void RiverCrashState_00428020_Product::
    OtAdvanceRiverCrashVariantA_Product_00428020(unsigned int tick)
{
    short sprite_x_value;
    short* sprite_x;
    unsigned short sprite_width;
    register unsigned int frame_limit;
    register short frame_value;
    register short* frame;
    register short* debris_active;
    RiverCrossingBackdropSprite_00428480* primary_sprite;
    RiverCrossingBackdropSprite_00428480* aftermath_sprite;

    if ((tick & 1) == 0) {
        primary_sprite = primary;
        if (primary_sprite->active == 1) {
            sprite_width = primary_sprite->width;
            sprite_x = &primary_sprite->x;
            sprite_x_value = *sprite_x;
            if ((base_bitmap->height >> 1 <
                    (unsigned int)(sprite_width >> 1) +
                        (int)sprite_x_value) ||
                (base_bitmap->width >> 1 <
                    (unsigned int)(primary_sprite->height >> 1) +
                        (int)primary_sprite->y)) {
                *sprite_x = (short)(sprite_x_value - 2);
                --primary->y;
                return;
            }
            primary_sprite->active = 0;
            aftermath->active = 1;
            aftermath->x = primary->x;
            if (g_cdMediaMode_00439108 != 0) {
                reinterpret_cast<RaftingDialogState_00428e10*>(this)->
                    OtPlayEmbeddedRaftCrashSoundAlt3_00428e10_RealCpp();
                return;
            }
        } else {
            aftermath_sprite = aftermath;
            if (aftermath_sprite->active == 1) {
                aftermath_sprite->x =
                    (short)(aftermath_sprite->x - 2);
                --aftermath->y;
                aftermath_sprite = aftermath;
                frame_limit = aftermath_sprite->frame_count;
                frame = reinterpret_cast<short*>(&aftermath_sprite->frame);
                frame_value = *frame;
                --frame_limit;
                if ((int)frame_limit <=
                    (int)(unsigned short)frame_value) {
                    aftermath_sprite->active = 0;
                    return;
                }
                ++frame_value;
                *frame = frame_value;
                return;
            }
            debris_active = &debris->active;
            if (*debris_active == 0 && (tick & 3) == 0) {
                *debris_active = 1;
                debris->x = aftermath->x;
                debris->y = aftermath->y;
            }
        }
    }
}

void RiverCrashState_00428020_Product::
    OtAdvanceRiverCrashVariantB_Product_004281c0(unsigned int tick)
{
    short* sprite_field;
    short sprite_x_value;
    unsigned short sprite_width;
    RiverCrossingBackdropSprite_00428480* primary_sprite;

    if ((tick & 1) == 0) {
        primary_sprite = primary;
        if (primary_sprite->active == 1) {
            sprite_width = primary_sprite->width;
            sprite_field = &primary_sprite->x;
            sprite_x_value = *sprite_field;
            if ((base_bitmap->height >> 1 <
                    (unsigned int)(sprite_width >> 1) +
                        (int)sprite_x_value) ||
                (base_bitmap->width >> 1 <
                    (unsigned int)(primary_sprite->height >> 1) +
                        (int)primary_sprite->y)) {
                *sprite_field = (short)(sprite_x_value - 2);
                sprite_field = &primary->y;
                --*sprite_field;
                return;
            }
            primary_sprite->active = 0;
            aftermath->active = 1;
            aftermath->x = primary->x;
            if (g_cdMediaMode_00439108 != 0) {
                reinterpret_cast<RaftingDialogState_00428e10*>(this)->
                    OtPlayEmbeddedRaftCrashSoundAlt3_00428e10_RealCpp();
                return;
            }
        } else {
            sprite_field = &aftermath->active;
            if (*sprite_field == 1) {
                *sprite_field = 0;
                return;
            }
            sprite_field = &debris->active;
            if ((*sprite_field == 0) && ((tick & 3) == 0)) {
                *sprite_field = 1;
                debris->x = aftermath->x;
                debris->y = aftermath->y;
            }
        }
    }
}

void RiverCrashState_00428020_Product::
    OtAdvanceRiverCrashVariantC_Product_00428370(unsigned int tick)
{
    register short frame_value;
    short* frame;
    RiverCrossingBackdropSprite_00428480* current_sprite;
    register short debris_active;
    register short* debris_active_flag;

    if ((tick % 6) != 0) {
        return;
    }

    current_sprite = primary;
    if (current_sprite->active == 1) {
        current_sprite->x = (short)(current_sprite->x - 2);
        --primary->y;
        current_sprite = primary;
        frame = reinterpret_cast<short*>(&current_sprite->frame);
        frame_value = *frame;
        if ((unsigned short)frame_value >= 3) {
            current_sprite->active = 0;
            aftermath->active = 1;
            aftermath->x = primary->x;
            return;
        }
        ++frame_value;
        *frame = frame_value;
        return;
    }

    debris_active_flag = &debris->active;
    debris_active = *debris_active_flag;
    if (debris_active == 1) {
        return;
    }

    current_sprite = aftermath;
    frame = reinterpret_cast<short*>(&current_sprite->frame);
    frame_value = *frame;
    if ((unsigned short)frame_value >= 2) {
        if (current_sprite->active == 1) {
            current_sprite->active = 0;
            if (g_cdMediaMode_00439108 != 0) {
                reinterpret_cast<RaftingDialogState_00428e10*>(this)->
                    OtPlayEmbeddedRaftCrashSoundAlt3_00428e10_RealCpp();
                return;
            }
        } else if (debris_active == 0) {
            *debris_active_flag = 1;
            debris->x = aftermath->x;
            debris->y = aftermath->y;
            return;
        }
        return;
    }

    ++frame_value;
    *frame = frame_value;
}

void RiverCrossingBackdropState_00428480::OtRenderRiverCrossingBackdrop_00428480_RealCpp(
    void* owner)
{
    register RiverCrossingBackdropSprite_00428480* foreground = foreground_layer;

    if (foreground != 0 && foreground->active == 1) {
        reinterpret_cast<RiverCrashPreludeState_00427f40_Product*>(this)->
            OtRiverCrashDialogPrelude_Product_00427f40(
                (unsigned int)owner);
        return;
    }

    register short current_phase = phase;
    if (current_phase == 0 || current_phase == 1) {
        reinterpret_cast<RiverCrossingProgressState_004282e0*>(this)->
            OtRiver_AdvanceCrossingProgress_004282e0_RealCpp(
                (unsigned int)owner);
        return;
    }

    if (current_phase == 2 || current_phase == 3) {
        reinterpret_cast<RiverCrashState_00428020_Product*>(this)->
            OtAdvanceRiverCrashVariantC_Product_00428370(
                (unsigned int)owner);
        return;
    }

    if (current_phase == 4) {
        reinterpret_cast<RiverCounterOwner_00428180_Product*>(this)->
            OtStepRiverCounterPairB_Product_004281a0(
                (unsigned int)owner);
        return;
    }

    if (current_phase == 5) {
        reinterpret_cast<RiverCrashState_00428020_Product*>(this)->
            OtAdvanceRiverCrashVariantB_Product_004281c0(
                (unsigned int)owner);
        return;
    }

    if (current_phase == 6) {
        reinterpret_cast<RiverCounterOwner_00428180_Product*>(this)->
            OtStepRiverCounterPairA_Product_00428180(
                (unsigned int)owner);
        return;
    }

    reinterpret_cast<RiverCrashState_00428020_Product*>(this)->
        OtAdvanceRiverCrashVariantA_Product_00428020(
            (unsigned int)owner);
}

#pragma optimize("", on)
