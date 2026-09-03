// Product semantic WIP for OtRestoreTrailViewAfterRiverCrossing @ 0x0042c180.
//
// Restores the ordinary overland view after the timed river-crossing phase:
// audio is stopped, the crossing scene is released, the trail scene/progress
// line are redrawn, and the four main menu groups are enabled again.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

#include "../river/river_crossing_state_runtime.h"

extern "C" void* g_gamePalette;
extern "C" short g_activeTrailEventScene;
extern "C" char g_trailDailyStateDirty_0043b70c;
extern "C" char g_trailStatusDirty_0043b89c;

extern "C" __declspec(dllimport) void* __stdcall GetDC(void* window);
extern "C" __declspec(dllimport) void* __stdcall SelectPalette(
    void* dc,
    void* palette,
    int force_background);
extern "C" __declspec(dllimport) unsigned int __stdcall RealizePalette(
    void* dc);
extern "C" __declspec(dllimport) int __stdcall ReleaseDC(
    void* window,
    void* dc);

extern "C" __declspec(dllimport) void* __stdcall GetParent(void* window);
extern "C" __declspec(dllimport) void* __stdcall GetMenu(void* window);
extern "C" __declspec(dllimport) int __stdcall EnableMenuItem(
    void* menu,
    unsigned int item,
    unsigned int flags);
extern "C" __declspec(dllimport) int __stdcall DrawMenuBar(void* window);

#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "user32.lib")

extern "C" int __cdecl OtRunSharedMessageDialog_00401e70_RealCpp(
    void* owner_window,
    void* message_text,
    void* caption_text,
    int use_alternate_template);

void __cdecl operator delete(void* block);

#pragma pack(push, 1)
struct TrailAnimationState_0042d460 {
    void OtSyncTrailActionControls_RealCpp(
        void* owner_window,
        int repaint);
};

struct TrailJournalState_0040f950 {
    void OtAppendTrailJournalText_0040f950_ProductWip(
        const char* pending_text);
};

struct TrailTravelScene_00006510 {
    void OtRenderTrailTravelScene_00006510_RealCpp(
        void* dc,
        void* owner,
        unsigned int travelled_distance,
        unsigned int total_distance,
        int overlay_phase,
        int caption_id);
};

struct TrailMapProgressState_00405f70 {
    void OtResetTrailMapProgressLine_RealCpp(
        void* map_window,
        void* dc,
        int travel_progress);
};

struct TrailProgressView_0042c0b0_Product {
    void OtComputeTrailProgressRange_0042c0b0_Product(
        int* first_mile,
        int* last_mile);
};

struct TrailUiState_0042b370 {
    char reserved_000[0x78c];
    TrailMapProgressState_00405f70* progress_meter;
    char reserved_790[0x27c];
    TrailJournalState_0040f950* trail_journal;
    TrailTravelScene_00006510* travel_scene;
    RiverCrossingState_004285a0_ProductWip* river_crossing;
    char reserved_a18[8];
    int river_crossing_mode;
    char reserved_a24[0x0c];
    void* render_owner;
    char reserved_a34[0x14];
    unsigned int travelled_distance;
    unsigned int total_distance;
    char reserved_a50[4];
    int overlay_phase;

    void OtRestoreTrailViewAfterRiverCrossing_0042c180_ProductWip(
        void* owner_window);
};
#pragma pack(pop)

static char kRiverCrossingTitle_0042c180[] = "River Crossing";

#pragma code_seg(".otsem")
#pragma optimize("s", off)
#pragma optimize("t", on)

void TrailUiState_0042b370::
OtRestoreTrailViewAfterRiverCrossing_0042c180_ProductWip(
    void* owner_window)
{
    int first_progress;
    int last_progress;
    register TrailUiState_0042b370* state = this;

    state->river_crossing->OtStopSfxAndWaveAudio_RealCpp();

    register void* owner = owner_window;
    state->river_crossing_mode = 0;
    reinterpret_cast<TrailAnimationState_0042d460*>(state)
        ->OtSyncTrailActionControls_RealCpp(owner, 1);

    OtRunSharedMessageDialog_00401e70_RealCpp(
        owner,
        &g_trailDailyStateDirty_0043b70c,
        kRiverCrossingTitle_0042c180,
        0);
    state->trail_journal->OtAppendTrailJournalText_0040f950_ProductWip(
        &g_trailStatusDirty_0043b89c);

    register RiverCrossingState_004285a0_ProductWip* crossing =
        state->river_crossing;
    if (crossing != 0) {
        crossing->OtDestroyRiverCrossingState_Product_00428bf0();
        operator delete(crossing);
    }

    state->river_crossing = 0;

    reinterpret_cast<TrailProgressView_0042c0b0_Product*>(state)
        ->OtComputeTrailProgressRange_0042c0b0_Product(
            &first_progress,
            &last_progress);

    void* dc = GetDC(owner);
    SelectPalette(dc, g_gamePalette, 0);
    RealizePalette(dc);
    state->travel_scene->OtRenderTrailTravelScene_00006510_RealCpp(
        dc,
        state->render_owner,
        state->travelled_distance,
        state->total_distance,
        state->overlay_phase,
        g_activeTrailEventScene);
    state->progress_meter->OtResetTrailMapProgressLine_RealCpp(
        owner,
        dc,
        last_progress);
    ReleaseDC(owner, dc);

    EnableMenuItem(GetMenu(GetParent(owner)), 0, 0x400);
    EnableMenuItem(GetMenu(GetParent(owner)), 1, 0x400);
    EnableMenuItem(GetMenu(GetParent(owner)), 2, 0x400);
    EnableMenuItem(GetMenu(GetParent(owner)), 3, 0x400);
    DrawMenuBar(GetParent(owner));
}

#pragma code_seg()
#pragma optimize("", on)
