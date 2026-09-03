// Canonical Product member for OtPlayTrailPaceTheme @ 0x0042d3a0.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

extern "C" int g_cdMediaMode_00439108;

#pragma pack(push, 1)
struct JourneyState_0042d3a0_Product {
    char reserved_000[0x92];
    short trail_pace;
};

struct TrailUiState_0042b370 {
    void OtPlayTrailPaceTheme_0042d3a0_ProductWip(void* owner_window);
};
#pragma pack(pop)

extern "C" JourneyState_0042d3a0_Product* g_journeyState;
extern "C" void __cdecl OtOpenMidiAudioFileMaskClosed_0000cd60_RealCpp(
    void* owner_window,
    const char* filename);

static const char g_gruelingPaceMidiFilename_0042d3a0[] = "grueling.mid";
static const char g_strenuousPaceMidiFilename_0042d3a0[] = "stren.mid";
static const char g_steadyPaceMidiFilename_0042d3a0[] = "steady.mid";

#pragma code_seg(".otsem")
#pragma optimize("s", off)
#pragma optimize("t", on)

// Opens the original MIDI cue associated with the active trail pace. The
// receiver is intentionally unused, matching the original member ABI.
void TrailUiState_0042b370::
    OtPlayTrailPaceTheme_0042d3a0_ProductWip(void* owner_window)
{
    if (g_cdMediaMode_00439108 != 0) {
        short pace = g_journeyState->trail_pace;
        if (pace == 0) {
            OtOpenMidiAudioFileMaskClosed_0000cd60_RealCpp(
                owner_window,
                g_steadyPaceMidiFilename_0042d3a0);
            return;
        }

        if (pace == 1) {
            OtOpenMidiAudioFileMaskClosed_0000cd60_RealCpp(
                owner_window,
                g_strenuousPaceMidiFilename_0042d3a0);
            return;
        }

        OtOpenMidiAudioFileMaskClosed_0000cd60_RealCpp(
            owner_window,
            g_gruelingPaceMidiFilename_0042d3a0);
    }
}

#pragma optimize("", on)
#pragma code_seg()
