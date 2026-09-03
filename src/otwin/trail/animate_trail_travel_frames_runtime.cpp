// Canonical Product implementation of OtAnimateTrailTravelFrames @ 0x00406400.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

#pragma pack(push, 1)
struct JourneyState_00406400_Product {
    char reserved_000[0x88];
    short travel_pace_units;
};

struct PositionedBitmap_0040b7b0_Semantic {
    char reserved_000[0x28];

    int OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
        void* dc,
        int source_x,
        int source_y);
};

struct TrailTravelAnimation_00406400_Product {
    char reserved_000[0x14];
    unsigned int background_interval;
    char reserved_018[0x08];
    int background_frame_count;
    char reserved_024[0x30];
    int background_source_x;
    unsigned int foreground_interval;
    char reserved_05c[0x08];
    int foreground_frame_count;
    char reserved_068[0x30];
    int foreground_source_x;
    char reserved_09c[0x10];
    PositionedBitmap_0040b7b0_Semantic travel_frames[5];
    char reserved_174[0xf0];
    int active_frame_index;

    void OtAnimateTrailTravelFrames_00406400_Product(
        void* dc,
        unsigned int tick);
};
#pragma pack(pop)

extern "C" JourneyState_00406400_Product* g_journeyState;

#pragma code_seg(".otsem")
#pragma optimize("s", off)
#pragma optimize("t", on)

// Advances the five-frame wagon animation and scrolls foreground/background
// strips at intervals derived from the active journey pace.
void TrailTravelAnimation_00406400_Product::
    OtAnimateTrailTravelFrames_00406400_Product(
        void* dc,
        unsigned int tick)
{
    TrailTravelAnimation_00406400_Product* overlay = this;
    int pace = g_journeyState->travel_pace_units / 5;

    if ((tick & 3) == 0) {
        int frame_index = overlay->active_frame_index + 1;
        overlay->active_frame_index = frame_index;
        overlay->active_frame_index = frame_index % 5;
    }

    overlay->travel_frames[overlay->active_frame_index]
        .OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);

    unsigned int* foreground_interval = &overlay->foreground_interval;
    if (pace > 0) {
        *foreground_interval = 4 / pace + 1;
    } else {
        *foreground_interval = 4;
    }

    if ((tick % *foreground_interval) == 0) {
        int source_x;
        int current_source_x = overlay->foreground_source_x;
        source_x = 1;
        if (current_source_x != 0) {
            source_x = current_source_x;
        }

        reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
            reinterpret_cast<char*>(overlay) + 0x6c)
            ->OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                dc,
                source_x,
                0);

        source_x = overlay->foreground_source_x - 2;
        overlay->foreground_source_x = source_x;
        if (source_x < 0) {
            overlay->foreground_source_x =
                overlay->foreground_frame_count - 2;
        }
    }

    unsigned int* background_interval = &overlay->background_interval;
    if (pace > 0) {
        *background_interval = 10 / pace + 1;
    } else {
        *background_interval = 10;
    }

    if ((tick % *background_interval) == 0) {
        reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
            reinterpret_cast<char*>(overlay) + 0x28)
            ->OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
                dc,
                overlay->background_source_x,
                0);

        int source_x = overlay->background_source_x - 1;
        overlay->background_source_x = source_x;
        if (source_x < 0) {
            overlay->background_source_x =
                overlay->background_frame_count - 1;
        }
    }
}

#pragma optimize("", on)
#pragma code_seg()
