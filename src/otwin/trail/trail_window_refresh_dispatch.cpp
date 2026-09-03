// Trail-palette refresh and action-state dispatch recovered from Oregon32.exe.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This source must be compiled with 32-bit MSVC."
#endif

extern "C" __declspec(dllimport) void* __stdcall SelectPalette(
    void* dc,
    void* palette,
    int force_background);
extern "C" __declspec(dllimport) unsigned int __stdcall RealizePalette(
    void* dc);

#pragma pack(push, 1)
struct TrailRefreshDispatchState_0042edc0 {
    char reserved_00[0x0c];
    int dispatch_mode;
    int dispatch_flags;
    char reserved_14[4];
    void* dc;
};

struct TrailActionDialogCaseA_0042bb00_20260605 {
    void OtTrailActionDialogCaseA_20260605_RealCpp(
        void* dc,
        unsigned int command);
};

struct TrailActionDialogCaseB_0042bcd0_20260605 {
    void OtTrailActionDialogCaseB_20260605_RealCpp(
        void* dc,
        int command);
};

struct TrailActionDialogCaseC_0042bea0_20260604 {
    void OtTrailActionDialogCaseC_20260604_RealCpp(
        void* dc,
        unsigned int command);
};
#pragma pack(pop)

// Allocated by the trail-game dialog setup path and shared by all three action
// render-state dispatchers.
extern "C" void* g_trailGameDialogState_0042edc0 = 0;
extern "C" void* g_gamePalette;

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" void __cdecl
OtRefreshTrailWindowAndDispatchState_0042edc0_RealCpp(
    void*,
    TrailRefreshDispatchState_0042edc0* refresh_state,
    int command)
{
    register TrailRefreshDispatchState_0042edc0* state = refresh_state;

    SelectPalette(state->dc, g_gamePalette, 0);
    RealizePalette(state->dc);

    switch (state->dispatch_mode) {
    case 1:
        if ((state->dispatch_flags & 4) != 0) {
            reinterpret_cast<TrailActionDialogCaseA_0042bb00_20260605*>(
                g_trailGameDialogState_0042edc0)
                ->OtTrailActionDialogCaseA_20260605_RealCpp(
                    state->dc,
                    command);
        } else {
            reinterpret_cast<TrailActionDialogCaseC_0042bea0_20260604*>(
                g_trailGameDialogState_0042edc0)
                ->OtTrailActionDialogCaseC_20260604_RealCpp(
                    state->dc,
                    command);
        }
        break;

    case 2:
        if ((state->dispatch_flags & 1) != 0) {
            reinterpret_cast<TrailActionDialogCaseB_0042bcd0_20260605*>(
                g_trailGameDialogState_0042edc0)
                ->OtTrailActionDialogCaseB_20260605_RealCpp(
                    state->dc,
                    command);
        } else if ((state->dispatch_flags & 4) != 0) {
            reinterpret_cast<TrailActionDialogCaseA_0042bb00_20260605*>(
                g_trailGameDialogState_0042edc0)
                ->OtTrailActionDialogCaseA_20260605_RealCpp(
                    state->dc,
                    command);
        } else {
            reinterpret_cast<TrailActionDialogCaseC_0042bea0_20260604*>(
                g_trailGameDialogState_0042edc0)
                ->OtTrailActionDialogCaseC_20260604_RealCpp(
                    state->dc,
                    command);
        }
        break;
    }
}

#pragma optimize("", on)
