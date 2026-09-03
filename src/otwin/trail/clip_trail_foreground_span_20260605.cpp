// Product semantic implementation of OtClipTrailForegroundSpan @ 0x004065d0.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

extern "C" __declspec(dllimport) int __stdcall FillRect(
    void* dc,
    const void* rect,
    void* brush);
extern "C" __declspec(dllimport) int __stdcall DeleteObject(void* object);

#pragma comment(lib, "gdi32.lib")

#pragma pack(push, 1)
struct Rect_20260603_065d0 {
    long left;
    long top;
    long right;
    long bottom;
};

struct PositionedBitmap_20260603_065d0 {
    int OtBlitWrappedPositionedBitmapDependency_20260603_065d0(
        void* dc,
        int source_x,
        int source_y);
};

struct TrailForegroundSpan_20260603_065d0 {
    char reserved_000[0x274];
    int foreground_clip_x;
    PositionedBitmap_20260603_065d0 foreground_strip;
    char reserved_2a4[
        0x288 - (0x278 + sizeof(PositionedBitmap_20260603_065d0))];
    short clipped_span_start;
    char reserved_28a[0x02];
    short clipped_span_width;
    char reserved_28e[0x02];
    Rect_20260603_065d0 foreground_fill_rect;
    int route_strip_clip_x;

    void OtAdvanceTrailViewportStripScrollDependency_20260603_065d0(
        unsigned int clip_start,
        unsigned int clip_end);
    void* OtCreateTrailGroundBrushDependency_20260603_065d0(void* dc);

    void OtClipTrailForegroundSpanAlt80_004065d0_RealCpp(
        void* dc,
        unsigned int clip_start,
        unsigned int clip_end);
};

struct TrailTravelViewport_00407000 {
    void OtAdvanceTrailViewportStripScrollAlt4_00407000_RealCpp(
        int progress,
        unsigned int progress_limit);
};

struct TrailPaletteBrushState_00406940 {
    unsigned long OtCreateTrailGroundBrush_00406940_ProductWip(void* dc);
    unsigned long OtCreateTrailSkyBrush_00406980_ProductWip(void* dc);
};

struct PositionedBitmap_0040b7b0_Semantic {
    int OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
        void* dc,
        int source_x,
        int source_y);
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

// Advances the route-strip clip and repairs the newly exposed foreground span.
void TrailForegroundSpan_20260603_065d0::
    OtClipTrailForegroundSpanAlt80_004065d0_RealCpp(
        void* dc,
        unsigned int clip_start,
        unsigned int clip_end)
{
    OtAdvanceTrailViewportStripScrollDependency_20260603_065d0(
        clip_start,
        clip_end);

    int route_probe = route_strip_clip_x;
    int foreground_probe = foreground_clip_x;
    if (route_probe < foreground_probe) {
        void* brush;
        Rect_20260603_065d0 fill_rect;
        int fill_right;

        clipped_span_start = static_cast<short>(foreground_probe);
        foreground_strip.OtBlitWrappedPositionedBitmapDependency_20260603_065d0(
            dc,
            0,
            0);
        brush = OtCreateTrailGroundBrushDependency_20260603_065d0(dc);
        fill_rect = foreground_fill_rect;
        fill_right = foreground_clip_x;
        fill_rect.left = route_strip_clip_x;
        fill_rect.right = fill_right;
        FillRect(dc, &fill_rect, brush);
        DeleteObject(brush);
        return;
    }

    short clipped_width = clipped_span_width;
    if (route_probe < foreground_probe + clipped_width) {
        int original_width = clipped_width;

        clipped_width = static_cast<short>(
            clipped_width - static_cast<short>(route_probe));
        clipped_width = static_cast<short>(
            clipped_width + static_cast<short>(foreground_probe));
        clipped_span_start = static_cast<short>(route_probe);
        clipped_span_width = clipped_width;
        foreground_strip.OtBlitWrappedPositionedBitmapDependency_20260603_065d0(
            dc,
            original_width - static_cast<int>(clipped_width),
            0);
        clipped_span_width = static_cast<short>(original_width);
    }
}

#pragma optimize("", on)

#pragma code_seg(".otsem")

void TrailForegroundSpan_20260603_065d0::
    OtAdvanceTrailViewportStripScrollDependency_20260603_065d0(
        unsigned int clip_start,
        unsigned int clip_end)
{
    reinterpret_cast<TrailTravelViewport_00407000*>(this)->
        OtAdvanceTrailViewportStripScrollAlt4_00407000_RealCpp(
            static_cast<int>(clip_start),
            clip_end);
}

void* TrailForegroundSpan_20260603_065d0::
    OtCreateTrailGroundBrushDependency_20260603_065d0(void* dc)
{
    unsigned long brush =
        reinterpret_cast<TrailPaletteBrushState_00406940*>(this)->
            OtCreateTrailGroundBrush_00406940_ProductWip(dc);
    return reinterpret_cast<void*>(brush);
}

int PositionedBitmap_20260603_065d0::
    OtBlitWrappedPositionedBitmapDependency_20260603_065d0(
        void* dc,
        int source_x,
        int source_y)
{
    int result = reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(this)->
        OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
            dc,
            source_x,
            source_y);
    return result;
}

#pragma code_seg()
