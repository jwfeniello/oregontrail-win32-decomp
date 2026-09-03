// Semantic recovery for OtRenderTrailTravelScene @ 0x00406510.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

extern "C" void* g_gamePalette;

extern "C" __declspec(dllimport) void* __stdcall SelectPalette(
    void* dc,
    void* palette,
    int force_background);
extern "C" __declspec(dllimport) unsigned int __stdcall RealizePalette(
    void* dc);
extern "C" __declspec(dllimport) int __stdcall FillRgn(
    void* dc,
    void* region,
    unsigned long brush);
extern "C" __declspec(dllimport) int __stdcall DeleteObject(
    unsigned long object);

#pragma comment(lib, "gdi32.lib")

#pragma pack(push, 1)
struct PositionedBitmap_00006510 {
    char reserved_000[0x2c];
    int source_x;
    char reserved_030[0x14];

};

struct PositionedBitmap_0040b7b0_Semantic {
    int OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
        void* dc,
        int source_x,
        int source_y);
};

struct TrailViewportPaletteState_004070a0_ProductWip {
    void OtAnimateTrailViewportFillPalette_004070a0_ProductWip(int frame);
};

struct TrailPaletteBrushState_00406940 {
    unsigned long OtCreateTrailGroundBrush_00406940_ProductWip(void* dc);
    unsigned long OtCreateTrailSkyBrush_00406980_ProductWip(void* dc);
};

struct TrailTravelOverlay_000066c0 {
    void OtRenderTrailTravelOverlay_000066c0_RealCpp(
        void* dc,
        int frame,
        unsigned int clip_start,
        unsigned int clip_end,
        void* palette,
        int event_overlay);
};

struct TrailTravelScene_00006510 {
    char reserved_000[0x0c];
    void* sky_fill_rect;
    void* ground_fill_rect;
    char reserved_014[0x14];
    PositionedBitmap_00006510 sky_strip;
    PositionedBitmap_00006510 ground_strip;

    void OtRenderTrailTravelScene_00006510_RealCpp(
        void* dc,
        void* owner,
        unsigned int travelled_distance,
        unsigned int total_distance,
        int overlay_phase,
        int caption_id);
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

void TrailTravelScene_00006510::
OtRenderTrailTravelScene_00006510_RealCpp(
    void* dc,
    void* owner,
    unsigned int travelled_distance,
    unsigned int total_distance,
    int overlay_phase,
    int caption_id)
{
    register TrailTravelScene_00006510* scene = this;
    register int phase = overlay_phase;

    SelectPalette(dc, g_gamePalette, 0);
    RealizePalette(dc);

    reinterpret_cast<TrailViewportPaletteState_004070a0_ProductWip*>(scene)->
        OtAnimateTrailViewportFillPalette_004070a0_ProductWip(phase);

    unsigned long brush =
        reinterpret_cast<TrailPaletteBrushState_00406940*>(scene)->
            OtCreateTrailSkyBrush_00406980_ProductWip(dc);
    FillRgn(dc, scene->sky_fill_rect, brush);
    DeleteObject(brush);

    brush = reinterpret_cast<TrailPaletteBrushState_00406940*>(scene)->
                OtCreateTrailGroundBrush_00406940_ProductWip(dc);
    FillRgn(dc, scene->ground_fill_rect, brush);
    DeleteObject(brush);

    reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
        &scene->sky_strip)->OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
            dc,
            scene->sky_strip.source_x,
            0);

    int source_x = scene->ground_strip.source_x;
    int ground_source_x = 1;
    if (source_x != 0) {
        ground_source_x = source_x;
    }

    reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
        &scene->ground_strip)->OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
            dc,
            ground_source_x,
            0);

    reinterpret_cast<TrailTravelOverlay_000066c0*>(scene)->
        OtRenderTrailTravelOverlay_000066c0_RealCpp(
            dc,
            reinterpret_cast<int>(owner),
            travelled_distance,
            total_distance,
            reinterpret_cast<void*>(phase),
            caption_id);
}

#pragma optimize("", on)
