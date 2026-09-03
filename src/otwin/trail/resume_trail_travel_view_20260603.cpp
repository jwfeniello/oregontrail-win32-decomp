// Product-tree semantic closure for OtResumeTrailTravelView @ 0x0042a950.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

extern "C" void* g_gamePalette;
extern "C" int g_titleThemeEnabled_004390ec;
extern "C" int g_midiPlaybackActive_0040cd60;
extern "C" int g_cdMediaMode_00439108;

extern "C" short g_activeTrailEventScene;

extern "C" __declspec(dllimport) void* __stdcall GetDC(void* window);
extern "C" __declspec(dllimport) unsigned int __stdcall RealizePalette(
    void* dc);
extern "C" __declspec(dllimport) int __stdcall ReleaseDC(
    void* window,
    void* dc);
extern "C" __declspec(dllimport) void* __stdcall SelectPalette(
    void* dc,
    void* palette,
    int force_background);

extern "C" void __cdecl OtCloseMidiAudioDeviceNoAsm_0040ccf0_RealCpp();
extern "C" void __cdecl OtCloseWaveAudioDevice_0040d0a0_RealCpp();
extern "C" void __cdecl OtPlayMidiAudio_0000ced0_RealCpp(int play_mode);

#pragma pack(push, 1)
struct JourneyState_0042a950_20260603 {
    char reserved_000[0x5a];
    short route_stop_flags;
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

struct TrailMapProgressLine_00406370_Product {
    void OtAdvanceTrailMapProgressLine_00406370_Product(
        void* map_window,
        int travel_progress);
};

struct TrailAnimationState_0042d460 {
    void OtSyncTrailActionControls_RealCpp(
        void* owner_window,
        int repaint);
};

struct TrailUiState_0042b370 {
    void OtPlayTrailPaceTheme_0042d3a0_ProductWip(void* owner_window);
    void OtPauseTrailTravel_RealCpp(void* owner_window);
};

struct TrailResumeState_0042a950_20260603 {
    char reserved_000[0x78c];
    void* progress_meter;
    char reserved_790[0x280];
    TrailTravelScene_00006510* travel_scene;
    char reserved_a14[8];
    int travel_pause_pending;
    int travel_submode;
    int overlay_caption_active;
    char reserved_a28[8];
    void* render_owner;
    char reserved_a34[0x14];
    unsigned int travelled_distance;
    unsigned int total_distance;
    char reserved_a50[4];
    int overlay_phase;

    int OtResumeTrailTravelView_20260603_RealCpp(
        void* owner_window,
        int continue_state,
        int progress_end);
};
#pragma pack(pop)

extern "C" JourneyState_0042a950_20260603* g_journeyState;

#pragma optimize("s", off)
#pragma optimize("t", on)

// Repaints the trail travel view after a pause/transition, resets the progress
// meter, then either resumes audio/action controls or leaves travel paused.
int TrailResumeState_0042a950_20260603::
    OtResumeTrailTravelView_20260603_RealCpp(
        void* owner_window,
        int continue_state,
        int progress_end)
{
    register TrailResumeState_0042a950_20260603* state = this;
    register void* owner = owner_window;
    register void* dc = GetDC(owner);

    SelectPalette(dc, g_gamePalette, 0);
    RealizePalette(dc);

    if (state->overlay_caption_active != 0) {
        state->travel_scene->OtRenderTrailTravelScene_00006510_RealCpp(
            dc,
            state->render_owner,
            state->travelled_distance,
            state->total_distance,
            state->overlay_phase,
            g_activeTrailEventScene);
    } else {
        state->travel_scene->OtRenderTrailTravelScene_00006510_RealCpp(
            dc,
            state->render_owner,
            state->travelled_distance,
            state->total_distance,
            state->overlay_phase,
            0);
    }

    register int progress = progress_end;
    reinterpret_cast<TrailMapProgressState_00405f70*>(state->progress_meter)
        ->OtResetTrailMapProgressLine_RealCpp(owner, dc, progress);
    reinterpret_cast<TrailMapProgressLine_00406370_Product*>(
        state->progress_meter)
        ->OtAdvanceTrailMapProgressLine_00406370_Product(owner, progress);

    register int zero = 0;
    ReleaseDC(owner, dc);

    if (continue_state != zero) {
        state->travel_pause_pending = zero;
        state->travel_submode = zero;
        reinterpret_cast<TrailAnimationState_0042d460*>(state)
            ->OtSyncTrailActionControls_RealCpp(owner, 1);

        if (g_titleThemeEnabled_004390ec != zero && g_midiPlaybackActive_0040cd60 != zero) {
            if (g_cdMediaMode_00439108 == zero) {
                OtCloseMidiAudioDeviceNoAsm_0040ccf0_RealCpp();
                reinterpret_cast<TrailUiState_0042b370*>(state)
                    ->OtPlayTrailPaceTheme_0042d3a0_ProductWip(owner);
                if (g_journeyState->route_stop_flags == zero) {
                    OtCloseWaveAudioDevice_0040d0a0_RealCpp();
                    OtPlayMidiAudio_0000ced0_RealCpp(zero);
                    return 0;
                }
            } else if (g_journeyState->route_stop_flags == zero) {
                OtCloseWaveAudioDevice_0040d0a0_RealCpp();
                OtPlayMidiAudio_0000ced0_RealCpp(-1);
                return 0;
            }
        } else if (g_titleThemeEnabled_004390ec == zero &&
                   g_midiPlaybackActive_0040cd60 != zero) {
            OtCloseMidiAudioDeviceNoAsm_0040ccf0_RealCpp();
            return 0;
        }
    } else {
        reinterpret_cast<TrailUiState_0042b370*>(state)
            ->OtPauseTrailTravel_RealCpp(owner);
    }

    return 0;
}

#pragma optimize("", on)
