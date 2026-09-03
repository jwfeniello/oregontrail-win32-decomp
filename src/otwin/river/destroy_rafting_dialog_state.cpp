// Semantic recovery candidate for OtDestroyRaftingDialogState @ 0x00426680.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "river_runtime.h"

#pragma comment(lib, "kernel32.lib")
#pragma comment(lib, "winmm.lib")

void __cdecl operator delete(void* block);

#pragma pack(push, 1)
struct RaftingDialogState_00426680 {
    void* obstacle_resources[4];
    void* backdrop_resource;
    char reserved_014[0x14];
    void* sprite_buffer_a;
    char reserved_02c[0x08];
    void* sprite_buffer_a_resource;
    char reserved_038[0x04];
    void* sprite_buffer_b;
    char reserved_040[0x14];
    void* sprite_buffer_b_resource;
    char reserved_058[0x1c];
    void* raw_indexed_bitmap;
    void* raft_sprite;
    void* obstacle_sprites[4];

    void OtDestroyRaftingDialogState_00426680_RealCpp();
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

void RaftingDialogState_00426680::OtDestroyRaftingDialogState_00426680_RealCpp()
{
    register RaftingDialogState_00426680* state = this;
    register void** sprite;
    register int remaining;

    sndPlaySoundA(0, 0);
    sprite = state->obstacle_sprites;
    remaining = 4;

    do {
        void* current_sprite = *sprite;
        if (current_sprite != 0) {
            OtFreeSpriteBlitter_RealCpp(current_sprite);
            operator delete(current_sprite);
        }

        FreeResource(*(sprite - 0x1f));
        ++sprite;
        --remaining;
    } while (remaining != 0);

    void* raft_sprite = state->raft_sprite;
    if (raft_sprite != 0) {
        OtFreeSpriteBlitter_RealCpp(raft_sprite);
        operator delete(raft_sprite);
    }

    FreeResource(state->backdrop_resource);

    GlobalUnlock(state->sprite_buffer_a);
    GlobalFree(state->sprite_buffer_a);
    GlobalUnlock(state->sprite_buffer_b);
    GlobalFree(state->sprite_buffer_b);

    FreeResource(state->sprite_buffer_a_resource);
    FreeResource(state->sprite_buffer_b_resource);

    void* bitmap = state->raw_indexed_bitmap;
    if (bitmap != 0) {
        reinterpret_cast<RawIndexedBitmapFree_00410550_42pct*>(bitmap)->
            OtFreeRawIndexedBitmapAlt5_00410550_42pct();
        operator delete(bitmap);
    }
}

#pragma optimize("", on)
