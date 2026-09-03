// Ordered hunt-sprite list maintenance at 0x00412ea0.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "hunt_runtime_state.h"

#pragma optimize("s", off)
#pragma optimize("t", on)

/**
 * Remove one active sprite from the ordered table, recycle its allocation at
 * the inactive tail, and mark it available for the next spawn.
 */
void HuntRuntimeState_004122b0_Product::OtRemoveHuntSpriteSlot_Product(
    int slot_index)
{
    register int slot = slot_index;
    register HuntSprite_004122b0_Product* removed = sprite_slots[slot];

    while (slot < 19) {
        sprite_slots[slot] = sprite_slots[slot + 1];
        ++slot;
    }

    sprite_slots[slot] = removed;
    removed->state = 0;
}

#pragma optimize("", on)
