// Semantic candidate for OtAllocateOrderedHuntSpriteSlot @ 0x00412dd0.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

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

#pragma optimize("s", off)
#pragma optimize("t", on)

int HuntState_00412dd0::OtAllocateOrderedHuntSpriteSlot_00412dd0_RealCpp(
    register int draw_order_key)
{
    register int active_count = 0;
    register int moving_count = 0;
    register HuntSprite_00412dd0** cursor = active_sprites;
    register HuntSprite_00412dd0** scan = cursor;

    for (;;) {
        register short state = (*scan)->state;
        if (state == 0) {
            break;
        }

        if (state == 1) {
            ++moving_count;
        }

        ++scan;
        ++active_count;
    }

    if ((active_count > 17 || moving_count >= 4) && draw_order_key != 0) {
        return -1;
    }

    register int insert_slot;
    if (draw_order_key >= 150) {
        insert_slot = 0;
        while ((*cursor)->state != 0 &&
               (*cursor)->draw_order_key < draw_order_key) {
            ++cursor;
            ++insert_slot;
        }
    } else {
        insert_slot = 0;
        while ((*cursor)->state != 0 &&
               draw_order_key < (*cursor)->draw_order_key) {
            ++cursor;
            ++insert_slot;
        }
    }

    int remaining;
    register HuntSprite_00412dd0** tail = &active_sprites[19];
    register int recycled_slot = (int)*tail;
    if (insert_slot < 19) {
        remaining = 19;
        remaining -= insert_slot;
        do {
            register HuntSprite_00412dd0* previous = tail[-1];
            --tail;
            --remaining;
            tail[1] = previous;
        } while (remaining != 0);
    }

    active_sprites[insert_slot] = (HuntSprite_00412dd0*)recycled_slot;
    return insert_slot;
}

#pragma optimize("", on)
