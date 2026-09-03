// Recovered hunt-scenery occlusion test at 0x004138d0.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This recovered runtime requires 32-bit MSVC."
#endif

#pragma pack(push, 1)
struct OtHuntSprite_004138d0_20260605 {
    char reserved_000[0x28];
    short x;
    short y;
    unsigned short width;
    unsigned short height;
};

struct OtHuntState_004138d0_20260605 {
    char reserved_000[0x160];
    int scene_base_resource;
    int scene_variant_offset;
    char reserved_168[0x14];
    OtHuntSprite_004138d0_20260605* active_sprites[20];

    int OtCurrentSceneResourceId_20260716() const
    {
        return scene_base_resource + scene_variant_offset;
    }

    int OtShouldRemoveFallingHuntTarget_004138d0_20260605_ReccmpP3(int slot);
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)
#pragma code_seg(".otsem")

/**
 * Return one when a falling hunt target has moved behind the foreground
 * scenery for the current scene variant and can be removed.
 */
int OtHuntState_004138d0_20260605::
    OtShouldRemoveFallingHuntTarget_004138d0_20260605_ReccmpP3(int slot)
{
    int scene_id;
    OtHuntSprite_004138d0_20260605* sprite;
    int x;
    int right_x;
    int bottom_y;

    scene_id = OtCurrentSceneResourceId_20260716();
    sprite = active_sprites[slot];
    x = sprite->x;
    bottom_y = (int)sprite->height + (int)sprite->y;

    if (scene_id < 0x4b1e ||
        ((scene_id >= 0x4b3c && scene_id < 0x4b46) ||
         scene_id >= 0x4b50)) {
        return 0;
    }

    if ((scene_id == 0x4b1e || scene_id == 0x4b21) &&
        (int)((unsigned int)sprite->width + x) > 0x154) {
        return 1;
    }

    if ((scene_id == 0x4b1f || scene_id == 0x4b22) &&
        (int)((unsigned int)sprite->width + x) > 0xa5) {
        return 1;
    }

    if ((scene_id == 0x4b28 || scene_id == 0x4b2b) &&
        (right_x = (unsigned int)sprite->width + x, right_x > 0x4b) &&
        right_x < 0xcd) {
        return 1;
    }

    if ((scene_id == 0x4b29 || scene_id == 0x4b2c) &&
        (int)((unsigned int)sprite->width + x) > 0x1c2) {
        return 1;
    }

    if ((scene_id == 0x4b2a || scene_id == 0x4b2d) &&
        (int)((unsigned int)sprite->width + x) > 0x136) {
        return 1;
    }

    if ((scene_id == 0x4b32 || scene_id == 0x4b35) &&
        (int)((unsigned int)sprite->width + x) > 500) {
        return 1;
    }

    if ((scene_id == 0x4b33 || scene_id == 0x4b36) &&
        (right_x = (unsigned int)sprite->width + x, right_x > 0x4b) &&
        right_x < 0xcd) {
        return 1;
    }

    if ((scene_id == 0x4b34 || scene_id == 0x4b37) &&
        (int)((unsigned int)sprite->width + x) > 0x1c2) {
        return 1;
    }

    if (scene_id == 0x4b46 || scene_id == 0x4b49) {
        if (bottom_y > 0xf0) {
            right_x = (unsigned int)sprite->width + x;
            if (right_x > 0x10e && right_x < 0x230) {
                return 1;
            }
        } else if (bottom_y > 0xdc) {
            right_x = (unsigned int)sprite->width + x;
            if (right_x > 0xf0 && right_x < 500) {
                return 1;
            }
        } else if (bottom_y > 0xc8) {
            right_x = (unsigned int)sprite->width + x;
            if (right_x > 0xd2 && right_x < 0x1ae) {
                return 1;
            }
        } else if (bottom_y > 0xb4) {
            right_x = (unsigned int)sprite->width + x;
            if (right_x > 200 && right_x < 0x15e) {
                return 1;
            }
        } else if (bottom_y > 0xa0) {
            right_x = (unsigned int)sprite->width + x;
            if (right_x > 0xb4 && right_x < 300) {
                return 1;
            }
        }
    }

    if (scene_id == 0x4b47 || scene_id == 0x4b4a) {
        if (bottom_y > 0xf0) {
            if ((int)((unsigned int)sprite->width + x) > 0x1cc) {
                return 1;
            }
        } else if (bottom_y > 0xdc) {
            if ((int)((unsigned int)sprite->width + x) > 0x1ae) {
                return 1;
            }
        } else if (bottom_y > 0xc8) {
            if ((int)((unsigned int)sprite->width + x) > 400) {
                return 1;
            }
        } else if (bottom_y > 0xb4) {
            right_x = (unsigned int)sprite->width + x;
            if (right_x > 0x186 && right_x < 0x21c) {
                return 1;
            }
        } else if (bottom_y > 0xa0) {
            right_x = (unsigned int)sprite->width + x;
            if (right_x > 0x172 && right_x < 0x1ea) {
                return 1;
            }
        }
    }

    if (scene_id == 0x4b48 || scene_id == 0x4b4b) {
        if (bottom_y > 0xf0) {
            right_x = (unsigned int)sprite->width + x;
            if (right_x > 0x78 && right_x < 0x19a) {
                return 1;
            }
        } else if (bottom_y > 0xdc) {
            right_x = (unsigned int)sprite->width + x;
            if (right_x > 0x5a && right_x < 0x15e) {
                return 1;
            }
        } else if (bottom_y > 0xc8) {
            right_x = (unsigned int)sprite->width + x;
            if (right_x > 0x3c && right_x < 0x118) {
                return 1;
            }
        } else if (bottom_y > 0xb4) {
            right_x = (unsigned int)sprite->width + x;
            if (right_x > 0x32 && right_x < 200) {
                return 1;
            }
        } else if (bottom_y > 0xa0) {
            right_x = (unsigned int)sprite->width + x;
            if (right_x > 0x1e && right_x < 0x96) {
                return 1;
            }
        }
    }

    return 0;
}

#pragma code_seg()
#pragma optimize("", on)
