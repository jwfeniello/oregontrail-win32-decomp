// Projectile update and hit-resolution dispatch at 0x00414450.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "hunt_runtime_state.h"

extern "C" __declspec(dllimport) OtHuntTick __stdcall timeGetTime();

#pragma comment(lib, "winmm.lib")

#pragma optimize("s", off)
#pragma optimize("t", on)

void HuntRuntimeState_004122b0_Product::
    OtAdvanceHuntProjectile_00414450_Product(void* draw_context)
{
    int slot;
    int projectile_slot;
    HuntSprite_004122b0_Product* sprite;
    OtHuntTick now;
    unsigned short trajectory_mode;
    short* projectile_x_cell;
    int projectile_x;
    int projectile_y;

    projectile_slot = -1;
    slot = 0;
    do {
        short state = sprite_slots[slot]->state;
        if (state == 0) {
            break;
        }
        if (state == 99) {
            projectile_slot = slot;
        }
        ++slot;
    } while (slot < 19);

    if (projectile_slot == -1) {
        return;
    }

    now = timeGetTime();
    sprite = sprite_slots[projectile_slot];
    if (now - sprite->last_tick < sprite->tick_interval) {
        return;
    }

    sprite->last_tick = now;
    trajectory_mode = sprite_slots[projectile_slot]->trajectory_mode;
    sprite = sprite_slots[projectile_slot];
    projectile_x_cell = &sprite->x;
    projectile_x = *projectile_x_cell;
    projectile_y = sprite->y;

    switch (trajectory_mode) {
    case 0:
        projectile_y -= 8;
        if (projectile_y < shot_y) {
            OtRedrawHuntSceneWithoutSpriteSlot_Product(
                draw_context,
                projectile_slot);
            OtResolveHuntShotHit_Product();
            OtRemoveHuntSpriteSlot_Product(projectile_slot);
            return;
        }
        break;

    case 1:
        projectile_x -= 8;
        projectile_y =
            projectile_intercept + (projectile_slope * projectile_x) / 1000;
        if (projectile_x < shot_x) {
            OtRedrawHuntSceneWithoutSpriteSlot_Product(
                draw_context,
                projectile_slot);
            OtResolveHuntShotHit_Product();
            OtRemoveHuntSpriteSlot_Product(projectile_slot);
            return;
        }
        break;

    case 2:
    case 3:
        projectile_y -= 8;
        projectile_x =
            ((projectile_y - projectile_intercept) * 1000) /
            projectile_slope;
        if (projectile_y < shot_y) {
            OtRedrawHuntSceneWithoutSpriteSlot_Product(
                draw_context,
                projectile_slot);
            OtResolveHuntShotHit_Product();
            OtRemoveHuntSpriteSlot_Product(projectile_slot);
            return;
        }
        break;

    case 4:
        projectile_x += 8;
        projectile_y =
            projectile_intercept + (projectile_slope * projectile_x) / 1000;
        if (shot_x < projectile_x) {
            OtRedrawHuntSceneWithoutSpriteSlot_Product(
                draw_context,
                projectile_slot);
            OtResolveHuntShotHit_Product();
            OtRemoveHuntSpriteSlot_Product(projectile_slot);
            return;
        }
        break;

    default:
        OtRedrawHuntSceneWithoutSpriteSlot_Product(
            draw_context,
            projectile_slot);
        OtRemoveHuntSpriteSlot_Product(projectile_slot);
        return;
    }

    *projectile_x_cell = (short)projectile_x;
    sprite_slots[projectile_slot]->y = (short)projectile_y;
    OtRedrawHuntSpriteSlot_Product(draw_context, projectile_slot);
}

#pragma optimize("", on)
