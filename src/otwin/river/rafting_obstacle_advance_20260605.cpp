// Semantic recovery for FUN_00426880 / rafting obstacle advance.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif


#include "../graphics/raw_indexed_bitmap_runtime.h"
#include "../graphics/sprite_blitter_runtime.h"

extern "C" __declspec(dllimport) unsigned long __stdcall timeGetTime(void);

#pragma comment(lib, "winmm.lib")

#pragma pack(push, 1)
struct RaftingObstacleSprite_00426880 {
    unsigned long last_update_time;
    unsigned long update_interval;
    char reserved_08[0x20];
    short x;
    short y;

};

struct RaftingObstacleAdvanceState_00426880 {
    char reserved_00[0x2c];
    int obstacle_frame;
    char reserved_30[0x40];
    void* scratch_buffer;
    void* base_bitmap;
    RaftingObstacleSprite_00426880* obstacle;

    int OtRaftingObstacleAdvance_00426880_RealCpp(void* dc);
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)
#pragma optimize("y", on)

int RaftingObstacleAdvanceState_00426880::
    OtRaftingObstacleAdvance_00426880_RealCpp(void* dc)
{
    int frames[60] = {
        0x21c,
        0x21c,
        0x21c,
        0x21d,
        0x21d,
        0x21d,
        0x21e,
        0x21e,
        0x21e,
        0x21f,
        0x21f,
        0x220,
        0x220,
        0x220,
        0x220,
        0x222,
        0x222,
        0x222,
        0x222,
        0x224,
        0x224,
        0x224,
        0x226,
        0x226,
        0x224,
        0x224,
        0x223,
        0x222,
        0x221,
        0x221,
        0x21f,
        0x21f,
        0x21d,
        0x21b,
        0x21b,
        0x219,
        0x217,
        0x217,
        0x215,
        0x215,
        0x212,
        0x212,
        0x210,
        0x210,
        0x20f,
        0x20f,
        0x20d,
        0x20d,
        0x20c,
        0x20b,
        0x20b,
        0x20c,
        0x20d,
        0x20d,
        0x20d,
        0x20e,
        0x20e,
        0x20e,
        0x20e,
        0x20e,
    };
    unsigned long now;

    now = timeGetTime();
    if (now - obstacle->last_update_time < obstacle->update_interval) {
        return 0;
    }

    obstacle->last_update_time = now;
    obstacle->y = static_cast<short>(obstacle->y - 6);
    obstacle->x = static_cast<short>(frames[obstacle_frame] - 0x2f);
    ++obstacle_frame;
    reinterpret_cast<SpriteBlitter_00410660_Product*>(obstacle)->
        OtExtractSpriteRegionToBuffer_Product_00410840(
        reinterpret_cast<RawIndexedBitmap_00410490_Product*>(base_bitmap),
        reinterpret_cast<unsigned char*>(scratch_buffer));
    reinterpret_cast<SpriteBlitter_00410660_Product*>(obstacle)->
        OtCompositeSpriteIntoBuffer_Product_00410a30(
        reinterpret_cast<SpriteBlitter_00410660_Product*>(obstacle),
        reinterpret_cast<unsigned char*>(scratch_buffer),
        reinterpret_cast<RawIndexedBitmap_00410490_Product*>(base_bitmap));
    reinterpret_cast<SpriteBlitter_00410660_Product*>(obstacle)->
        OtBlitSpriteBuffer_Product_004106e0(
        dc,
        reinterpret_cast<RawIndexedBitmap_00410490_Product*>(base_bitmap),
        scratch_buffer);
    return !(obstacle_frame - 0x39);
}

#pragma optimize("", on)
