// Semantic recovery candidate for OtRiver_BeginRaftSession @ 0x00426b70.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "../graphics/sprite_blitter_runtime.h"

extern "C" __declspec(dllimport) unsigned long __stdcall timeGetTime(void);
extern "C" int __cdecl OtRandomBelow_RealCpp(int upper_bound);

#pragma comment(lib, "winmm.lib")

#pragma pack(push, 1)
struct RaftObstacleSprite_00426b70 {
    char reserved_00[0x1a];
    short horizontal_flip;
    short mode_or_variant;
    short active_state;
    char reserved_20[8];
    short requested_x;
    short requested_y;
    char reserved_2c[8];
    short course_index;

};

struct RaftingState_00426b70 {
    char reserved_00[0x2c];
    int raft_descent_frame;
    char reserved_30[0x1c];
    unsigned int last_obstacle_spawn_tick;
    char reserved_50[0x2c];
    RaftObstacleSprite_00426b70* sprites[4];

    void OtRiver_BeginRaftSession_00426b70_RealCpp();
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

void RaftingState_00426b70::OtRiver_BeginRaftSession_00426b70_RealCpp()
{
    register RaftingState_00426b70* state = this;
    register unsigned int chosen_slot = 0xffffffff;
    register unsigned int tick = timeGetTime();

    if (state->raft_descent_frame <= 0x32) {
        if ((unsigned int)(OtRandomBelow_RealCpp(1000) + 2000) <=
            tick - state->last_obstacle_spawn_tick) {
            register unsigned int slot;
            register unsigned short inactive;

            state->last_obstacle_spawn_tick = tick;
            slot = 1;
            inactive = 0;
            while (1) {
                if (slot >= 4) {
                    break;
                }

                if (state->sprites[slot]->active_state == inactive) {
                    chosen_slot = slot;
                }

                ++slot;
            }

            if (chosen_slot != 0xffffffff) {
                short course_index =
                    (short)OtRandomBelow_RealCpp(12);
                register RaftObstacleSprite_00426b70** sprite =
                    &state->sprites[chosen_slot];

                (*sprite)->requested_x = 0;
                (*sprite)->course_index = course_index;
                (*sprite)->requested_y = 10;
                (*sprite)->active_state = 1;
                (*sprite)->horizontal_flip =
                    (short)OtRandomBelow_RealCpp(2);
                reinterpret_cast<SpriteBlitter_00410660_Product*>(*sprite)->
                    OtResetSpriteBlitterBitmapInfo_Product_004107b0();
            }
        }
    }
}

#pragma optimize("", on)
