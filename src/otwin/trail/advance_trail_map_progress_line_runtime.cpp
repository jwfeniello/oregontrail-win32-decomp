// Canonical Product implementation of OtAdvanceTrailMapProgressLine @ 0x00406370.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

extern "C" void* g_gamePalette;

extern "C" __declspec(dllimport) void* __stdcall GetDC(void* window);
extern "C" __declspec(dllimport) void* __stdcall SelectPalette(
    void* dc,
    void* palette,
    int force_background);
extern "C" __declspec(dllimport) unsigned int __stdcall RealizePalette(
    void* dc);
extern "C" __declspec(dllimport) void* __stdcall SelectObject(
    void* dc,
    void* object);
extern "C" __declspec(dllimport) int __stdcall ReleaseDC(
    void* window,
    void* dc);

#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "user32.lib")

#pragma pack(push, 1)
struct TrailMapDisplay_00405fb0_44pct {
    void OtDrawTrailMapProgressSegmentAlt15_00405fb0_44pct(
        void* dc,
        int previous_index,
        int current_index);
};

struct TrailMapProgressLine_00406370_Product {
    char reserved_00[0x14];
    int last_progress_segment;
    char reserved_18[0x24];
    void* progress_pen;

    void OtAdvanceTrailMapProgressLine_00406370_Product(
        void* map_window,
        int travel_progress);
};
#pragma pack(pop)

#pragma code_seg(".otsem")
#pragma optimize("s", off)
#pragma optimize("t", on)
#pragma optimize("a", on)

// Converts distance to a clamped route-segment index and draws only the
// segments not already present on the trail map.
void TrailMapProgressLine_00406370_Product::
    OtAdvanceTrailMapProgressLine_00406370_Product(
        void* map_window,
        int travel_progress)
{
    int next_segment;
    int last_segment;
    void* dc = GetDC(map_window);

    SelectPalette(dc, g_gamePalette, 0);
    RealizePalette(dc);
    SelectObject(dc, progress_pen);

    int target_segment = travel_progress / 10;
    if (target_segment > 0xcf) {
        target_segment = 0xcf;
    }

    last_segment = last_progress_segment;
    if (target_segment > last_segment) {
        while (target_segment > ++last_segment) {
            next_segment = last_segment;
            reinterpret_cast<TrailMapDisplay_00405fb0_44pct*>(this)
                ->OtDrawTrailMapProgressSegmentAlt15_00405fb0_44pct(
                    dc,
                    next_segment - 1,
                    next_segment);
        }

        last_progress_segment = target_segment - 1;
    }

    ReleaseDC(map_window, dc);
}

#pragma optimize("", on)
#pragma code_seg()
