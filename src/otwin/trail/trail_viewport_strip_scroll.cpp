// Semantic recovery candidate for OtAdvanceTrailViewportStripScroll @ 0x00407000.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#pragma pack(push, 1)
struct JourneyState_00407000 {
    char reserved_000[0x88];
    short segment_distance_base;
    short segment_distance_target;
};

struct TrailTravelViewport_00407000 {
    char reserved_000[0x9c];
    int viewport_width;
    char reserved_0a0[0x24];
    int foreground_right;
    char reserved_0c8[0x04];
    int foreground_left;
    char reserved_0d0[0x198];
    int route_strip_span_units;
    char reserved_26c[0x08];
    int route_strip_clip_x;
    char reserved_278[0x14];
    short route_strip_x;
    char reserved_28e[0x12];
    int foreground_clip_left;
    char reserved_2a4[0x04];
    int foreground_clip_right;

    void OtAdvanceTrailViewportStripScrollAlt4_00407000_RealCpp(
        int progress,
        unsigned int progress_limit);
};
#pragma pack(pop)

extern "C" JourneyState_00407000* g_journeyState_00407000 = 0;

#pragma optimize("s", off)
#pragma optimize("t", on)

void TrailTravelViewport_00407000::
    OtAdvanceTrailViewportStripScrollAlt4_00407000_RealCpp(
        int progress,
        unsigned int progress_limit)
{
    register TrailTravelViewport_00407000* viewport = this;
    register int previous_clip = viewport->route_strip_clip_x;
    register int progress_span;

    progress_span = g_journeyState_00407000->segment_distance_target;
    progress_span -=
        (unsigned int)(g_journeyState_00407000->segment_distance_base *
                       progress) /
        progress_limit;

    int span_units =
        (((viewport->foreground_right - viewport->foreground_clip_left) -
          viewport->foreground_left) -
         2 +
         viewport->foreground_clip_right) /
        0x41;

    viewport->route_strip_span_units = span_units;

    progress_span *= viewport->route_strip_span_units;

    register int clip = viewport->viewport_width;
    register int origin = viewport->route_strip_x;

    clip -= 2;
    if (progress_span > 0) {
        clip -= origin;
        clip -= progress_span;
    } else {
        clip -= origin;
    }

    viewport->route_strip_clip_x = clip;
    if (viewport->route_strip_clip_x < previous_clip) {
        viewport->route_strip_clip_x = previous_clip;
    }

    previous_clip += 4;
    if (viewport->route_strip_clip_x > previous_clip) {
        viewport->route_strip_clip_x = previous_clip;
    }
}

#pragma optimize("", on)
