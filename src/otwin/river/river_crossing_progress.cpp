// Focused semantic trial for the river-crossing progress sprite advance helper.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#pragma pack(push, 1)
struct RiverCrossingBitmap_004282e0 {
    char reserved_00[0x10];
    unsigned int height;
    unsigned int width;
};

struct RiverCrossingSprite_004282e0 {
    char reserved_00[0x0c];
    unsigned short frame;
    char reserved_0e[0x10];
    short active;
    char reserved_20[8];
    short x;
    short y;
    unsigned short width;
    unsigned short height;
};

struct RiverCrossingProgressState_004282e0 {
    char reserved_00[0x8c];
    RiverCrossingBitmap_004282e0* backdrop;
    char reserved_90[8];
    RiverCrossingSprite_004282e0* progress_sprite;

    void OtRiver_AdvanceCrossingProgress_004282e0_RealCpp(unsigned int tick);
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

void RiverCrossingProgressState_004282e0::OtRiver_AdvanceCrossingProgress_004282e0_RealCpp(
    unsigned int tick)
{
    register unsigned int phase = tick;

    if ((phase & 1) == 0) {
        progress_sprite->x = (short)(progress_sprite->x - 2);
        progress_sprite->y = (short)(progress_sprite->y - 1);

        register RiverCrossingSprite_004282e0* sprite = progress_sprite;
        register RiverCrossingBitmap_004282e0* bitmap = backdrop;

        if ((unsigned int)(sprite->x + sprite->width) <= (bitmap->width >> 1) &&
            (unsigned int)(sprite->y + sprite->height) <= (bitmap->height >> 1)) {
            if ((phase & 3) == 0) {
                unsigned short frame = sprite->frame;
                if (frame != 0) {
                    sprite->frame = (unsigned short)(frame - 1);
                }
            }
        } else {
            if ((phase & 3) == 0) {
                sprite = (RiverCrossingSprite_004282e0*)((char*)sprite + 0x0c);
                unsigned short frame = *(unsigned short*)sprite;
                if (frame < 3) {
                    *(unsigned short*)sprite = (unsigned short)(frame + 1);
                }
            }
        }
    }
}

#pragma optimize("", on)
