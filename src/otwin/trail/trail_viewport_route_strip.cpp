// Semantic recovery for OtUpdateTrailViewportRouteStripState @ 0x00406f70.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#pragma pack(push, 1)
struct PositionedBitmapDescriptorState_0040ba40 {
    void* bitmap_info_handle;
    void* indexed_pixels_handle;
    void* bitmap_info;
    unsigned char* indexed_pixels;
    short left;
    short top;
    short width;
    short height;
    int left_int;
    int top_int;
    int right;
    int bottom;

    int OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
        void* module,
        short descriptor_id);
};

struct JourneyState_00406f70 {
    char reserved_000[0x8a];
    short current_segment_distance;
};

struct TrailTravelViewport_00406f70 {
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
    PositionedBitmapDescriptorState_0040ba40 route_strip;
    int foreground_clip_left;
    char reserved_2a4[0x04];
    int foreground_clip_right;

    void OtUpdateTrailViewportRouteStripStateAlt32_00406f70_RealCpp(
        void* module,
        int descriptor_id);
};

#pragma pack(pop)

extern "C" JourneyState_00406f70* g_journeyState;
#define g_journeyState_00406f70 g_journeyState

#pragma optimize("s", off)
#pragma optimize("t", on)

void TrailTravelViewport_00406f70::
    OtUpdateTrailViewportRouteStripStateAlt32_00406f70_RealCpp(
        void* module,
        int descriptor_id)
{
    if (descriptor_id != 0) {
        route_strip.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            module,
            static_cast<short>(descriptor_id));
    }

    int span_units = foreground_right;
    int clip_right = foreground_clip_right;
    span_units -= foreground_clip_left;
    span_units -= foreground_left;
    span_units = (span_units + clip_right - 2) / 0x41;

    int clip_base = viewport_width;
    route_strip_span_units = span_units;

    short progress_distance =
        g_journeyState_00406f70->current_segment_distance;
    clip_base -= 2;
    int progress_offset = progress_distance * span_units;
    int strip_width = route_strip.width;

    if (progress_offset > 0) {
        route_strip_clip_x = (clip_base - strip_width) - progress_offset;
        return;
    }

    route_strip_clip_x = clip_base - strip_width;
}

#pragma optimize("", on)
