// Scene-specific hunt-target pathing recovered from 0x00413030.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This recovered runtime requires 32-bit MSVC."
#endif

#include "hunt_runtime_state.h"

#pragma optimize("s", off)
#pragma optimize("t", on)

/**
 * Apply the current hunt scene's travel-lane rules after a target moves.
 *
 * A target can turn around at a scenery boundary or be removed after it
 * leaves the playable area.  The direction sampled at entry is intentional:
 * each scene id selects at most one of the rule groups below.
 */
int HuntRuntimeState_004122b0_Product::
    OtAdvanceHuntTargetPathing_00413030_Product(int slot_index)
{
    int direction;
    int bottom_y;
    HuntSprite_004122b0_Product* initial_sprite;
    HuntSprite_004122b0_Product* sprite;
    int right_x;
    int x;
    int scene_id;
    unsigned int height;
    unsigned short* direction_cell;

    scene_id = OtCurrentHuntSceneResourceId_00413030();
    initial_sprite = sprite_slots[slot_index];
    height = initial_sprite->height;
    direction_cell = &initial_sprite->trajectory_mode;
    direction = *direction_cell;
    x = initial_sprite->x;
    bottom_y = initial_sprite->y + height;

    if (scene_id < 0x4b1e ||
        ((scene_id >= 0x4b3c && scene_id < 0x4b46) ||
         scene_id >= 0x4b50) ||
        initial_sprite->target_type >= 8) {
        goto check_outer_boundary;
    }

    if (scene_id == 0x4b1e || scene_id == 0x4b21) {
        if (direction == 1 && x > 0x244) {
            OtRemoveHuntSpriteSlot_Product(slot_index);
            return 0;
        }
        if (direction == 0 && (int)(initial_sprite->width + x) > 0x154) {
            *direction_cell = 1;
        }
    }

    if (scene_id == 0x4b1f || scene_id == 0x4b22) {
        if (direction == 1 && x > 0x244) {
            OtRemoveHuntSpriteSlot_Product(slot_index);
            return 0;
        }
        if (direction == 0 &&
            (int)(sprite_slots[slot_index]->width + x) > 0xa5) {
            sprite_slots[slot_index]->trajectory_mode = 1;
        }
    }

    if (scene_id == 0x4b28 || scene_id == 0x4b2b) {
        if (direction == 1 && x < 0xcd && x > 0x4b) {
            sprite_slots[slot_index]->trajectory_mode = 0;
        }
        if (direction == 0) {
            right_x = sprite_slots[slot_index]->width + x;
            if (right_x > 0x4b && right_x < 0xcd) {
                sprite_slots[slot_index]->trajectory_mode = 1;
            }
        }
    }

    if (scene_id == 0x4b29 || scene_id == 0x4b2c) {
        if (direction == 1 && x > 0x244) {
            OtRemoveHuntSpriteSlot_Product(slot_index);
            return 0;
        }
        if (direction == 0 &&
            (int)(sprite_slots[slot_index]->width + x) > 0x1c2) {
            sprite_slots[slot_index]->trajectory_mode = 1;
        }
    }

    if (scene_id == 0x4b2a || scene_id == 0x4b2d) {
        if (direction == 1 && x > 0x244) {
            OtRemoveHuntSpriteSlot_Product(slot_index);
            return 0;
        }
        if (direction == 0 &&
            (int)(sprite_slots[slot_index]->width + x) > 0x136) {
            sprite_slots[slot_index]->trajectory_mode = 1;
        }
    }

    if (scene_id == 0x4b32 || scene_id == 0x4b35) {
        if (direction == 1 && x > 0x244) {
            OtRemoveHuntSpriteSlot_Product(slot_index);
            return 0;
        }
        if (direction == 0 &&
            (int)(sprite_slots[slot_index]->width + x) > 500) {
            sprite_slots[slot_index]->trajectory_mode = 1;
        }
    }

    if (scene_id == 0x4b33 || scene_id == 0x4b36) {
        if (direction == 1 && x < 0xcd && x > 0x4b) {
            sprite_slots[slot_index]->trajectory_mode = 0;
        }
        if (direction == 0) {
            right_x = sprite_slots[slot_index]->width + x;
            if (right_x > 0x4b && right_x < 0xcd) {
                sprite_slots[slot_index]->trajectory_mode = 1;
            }
        }
    }

    if (scene_id == 0x4b34 || scene_id == 0x4b37) {
        if (direction == 1 && x > 0x244) {
            OtRemoveHuntSpriteSlot_Product(slot_index);
            return 0;
        }
        if (direction == 0 &&
            (int)(sprite_slots[slot_index]->width + x) > 0x1c2) {
            sprite_slots[slot_index]->trajectory_mode = 1;
        }
    }

    if (scene_id == 0x4b46 || scene_id == 0x4b49) {
        if (bottom_y > 0xf0) {
            if (direction == 1 && x < 0x230 && x > 0x10e) {
                sprite_slots[slot_index]->trajectory_mode = 0;
            }
            if (direction == 0) {
                sprite = sprite_slots[slot_index];
                right_x = sprite->width + x;
                if (right_x > 0x10e && right_x < 0x230) {
                    sprite->trajectory_mode = 1;
                }
            }
        } else if (bottom_y > 0xdc) {
            if (direction == 1 && x < 500 && x > 0xf0) {
                sprite_slots[slot_index]->trajectory_mode = 0;
            }
            if (direction == 0) {
                sprite = sprite_slots[slot_index];
                right_x = sprite->width + x;
                if (right_x > 0xf0 && right_x < 500) {
                    sprite->trajectory_mode = 1;
                }
            }
        } else if (bottom_y > 0xc8) {
            if (direction == 1 && x < 0x1ae && x > 0xd2) {
                sprite_slots[slot_index]->trajectory_mode = 0;
            }
            if (direction == 0) {
                sprite = sprite_slots[slot_index];
                right_x = sprite->width + x;
                if (right_x > 0xd2 && right_x < 0x1ae) {
                    sprite->trajectory_mode = 1;
                }
            }
        } else if (bottom_y > 0xb4) {
            if (direction == 1 && x < 0x15e && x > 200) {
                sprite_slots[slot_index]->trajectory_mode = 0;
            }
            if (direction == 0) {
                sprite = sprite_slots[slot_index];
                right_x = sprite->width + x;
                if (right_x > 200 && right_x < 0x15e) {
                    sprite->trajectory_mode = 1;
                }
            }
        } else if (bottom_y > 0xa0) {
            if (direction == 1 && x < 300 && x > 0xb4) {
                sprite_slots[slot_index]->trajectory_mode = 0;
            }
            if (direction == 0) {
                sprite = sprite_slots[slot_index];
                right_x = sprite->width + x;
                if (right_x > 0xb4 && right_x < 300) {
                    sprite->trajectory_mode = 1;
                }
            }
        }
    }

    if (scene_id == 0x4b47 || scene_id == 0x4b4a) {
        if (bottom_y > 0xf0) {
            if (direction == 1 && x > 0x244) {
                OtRemoveHuntSpriteSlot_Product(slot_index);
                return 0;
            }
            if (direction == 0 &&
                (int)(sprite_slots[slot_index]->width + x) > 0x1cc) {
                sprite_slots[slot_index]->trajectory_mode = 1;
            }
        } else if (bottom_y > 0xdc) {
            if (direction == 1 && x > 0x244) {
                OtRemoveHuntSpriteSlot_Product(slot_index);
                return 0;
            }
            if (direction == 0 &&
                (int)(sprite_slots[slot_index]->width + x) > 0x1ae) {
                sprite_slots[slot_index]->trajectory_mode = 1;
            }
        } else if (bottom_y > 0xc8) {
            if (direction == 1 && x > 0x244) {
                OtRemoveHuntSpriteSlot_Product(slot_index);
                return 0;
            }
            if (direction == 0 &&
                (int)(sprite_slots[slot_index]->width + x) > 400) {
                sprite_slots[slot_index]->trajectory_mode = 1;
            }
        } else if (bottom_y > 0xb4) {
            if (direction == 1 && x < 0x21c && x > 0x186) {
                sprite_slots[slot_index]->trajectory_mode = 0;
            }
            if (direction == 0) {
                sprite = sprite_slots[slot_index];
                right_x = sprite->width + x;
                if (right_x > 0x186 && right_x < 0x21c) {
                    sprite->trajectory_mode = 1;
                }
            }
        } else if (bottom_y > 0xa0) {
            if (direction == 1 && x < 0x1ea && x > 0x172) {
                sprite_slots[slot_index]->trajectory_mode = 0;
            }
            if (direction == 0) {
                sprite = sprite_slots[slot_index];
                right_x = sprite->width + x;
                if (right_x > 0x172 && right_x < 0x1ea) {
                    sprite->trajectory_mode = 1;
                }
            }
        }
    }

    if (scene_id == 0x4b48 || scene_id == 0x4b4b) {
        if (bottom_y > 0xf0) {
            if (direction == 1 && x < 0x19a && x > 0x78) {
                sprite_slots[slot_index]->trajectory_mode = 0;
            }
            if (direction == 0) {
                sprite = sprite_slots[slot_index];
                right_x = sprite->width + x;
                if (right_x > 0x78 && right_x < 0x19a) {
                    sprite->trajectory_mode = 1;
                }
            }
        } else if (bottom_y > 0xdc) {
            if (direction == 1 && x < 0x15e && x > 0x5a) {
                sprite_slots[slot_index]->trajectory_mode = 0;
            }
            if (direction == 0) {
                sprite = sprite_slots[slot_index];
                right_x = sprite->width + x;
                if (right_x > 0x5a && right_x < 0x15e) {
                    sprite->trajectory_mode = 1;
                }
            }
        } else if (bottom_y > 0xc8) {
            if (direction == 1 && x < 0x118 && x > 0x3c) {
                sprite_slots[slot_index]->trajectory_mode = 0;
            }
            if (direction == 0) {
                sprite = sprite_slots[slot_index];
                right_x = sprite->width + x;
                if (right_x > 0x3c && right_x < 0x118) {
                    sprite->trajectory_mode = 1;
                }
            }
        } else if (bottom_y > 0xb4) {
            if (direction == 1 && x < 200 && x > 0x32) {
                sprite_slots[slot_index]->trajectory_mode = 0;
            }
            if (direction == 0) {
                sprite = sprite_slots[slot_index];
                right_x = sprite->width + x;
                if (right_x > 0x32 && right_x < 200) {
                    sprite->trajectory_mode = 1;
                }
            }
        } else if (bottom_y > 0xa0) {
            if (direction == 1 && x < 0x96 && x > 0x1e) {
                sprite_slots[slot_index]->trajectory_mode = 0;
            }
            if (direction == 0) {
                sprite = sprite_slots[slot_index];
                right_x = sprite->width + x;
                if (right_x > 0x1e && right_x < 0x96) {
                    sprite->trajectory_mode = 1;
                }
            }
        }
    }

check_outer_boundary:
    sprite = sprite_slots[slot_index];
    if ((sprite->trajectory_mode != 1 || sprite->x >= -0x50) &&
        (sprite->trajectory_mode != 0 || sprite->x <= 0x294)) {
        return 1;
    }

    OtRemoveHuntSpriteSlot_Product(slot_index);
    return 0;
}

#pragma optimize("", on)
