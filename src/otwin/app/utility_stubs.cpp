// Real C++ match-candidate implementations for recovered small OTWIN32
// functions.
//
// These are compiled by tools/otmatch/build-match-candidates.ps1 with the x86
// MSVC toolchain. Unlike generated_small_functions.cpp, these functions are
// intended to express recovered behavior in C++ and use matcher masks only for
// unavoidable relocation bytes.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "../trail/trail_event_runtime_abi.h"

#include "../trail/trail_event_text_runtime.h"

extern "C" int g_trailProgressStopPending = 0;
extern "C" const char* g_trailEventPrimaryText = 0;
extern "C" const char g_unimplementedEventMessageText[] =
    "Event not implemented yet";
extern "C" int g_tradeOfferAccepted = 0;
extern "C" int g_cdMediaMode_00439108;
extern "C" int DAT_004390e8;
extern "C" int g_usesIndexedColorDisplay = 0;
#define g_trailEventPromptText (g_trailEventRuntimeState.primary_text)
#define g_trailEventFollowupText (g_trailEventRuntimeState.secondary_text)
extern "C" unsigned int g_crtRandState = 0;
extern "C" int g_randomGeneratorSeeded = 0;

extern "C" void __cdecl OtStopMidiAudioDirectImport_0040d010_RealCpp();
extern "C" void __cdecl OtStopWaveAudioDirectImport_0040d480_RealCpp();
extern "C" void* __cdecl _nh_malloc(unsigned int size, int new_mode);
extern "C" long __cdecl time(long* timer);
extern "C" void __cdecl srand(unsigned int seed);
extern "C" int __cdecl rand();
extern "C" void* __cdecl memset(void* destination, int value, unsigned int size);

extern "C" __declspec(dllimport) int __stdcall GetOpenFileNameA(
    void* open_file_name);
extern "C" __declspec(dllimport) int __stdcall GetSaveFileNameA(
    void* open_file_name);
extern "C" __declspec(dllimport) void __stdcall RtlUnwind(
    void* frame,
    void* target_ip,
    void* exception_record,
    void* return_value);
extern "C" __declspec(dllimport) unsigned long __stdcall GlobalFree(
    unsigned long handle);
extern "C" __declspec(dllimport) int __stdcall GlobalUnlock(
    unsigned long handle);
extern "C" __declspec(dllimport) int __stdcall sndPlaySoundA(
    const char* sound,
    unsigned int flags);
extern "C" __declspec(dllimport) int __stdcall ShowWindow(
    void* window,
    int command_show);
extern "C" __declspec(dllimport) int __stdcall IsWindowVisible(void* window);
extern "C" __declspec(dllimport) int __stdcall IsWindowEnabled(void* window);
extern "C" __declspec(dllimport) int __stdcall EnableWindow(
    void* window,
    int enabled);
extern "C" __declspec(dllimport) unsigned long __stdcall CreateSolidBrush(
    unsigned long color);
extern "C" __declspec(dllimport) unsigned long __stdcall GetNearestColor(
    void* dc,
    unsigned long color);
extern "C" __declspec(dllimport) void* __stdcall GetDlgItem(
    void* dialog,
    int control_id);
typedef void* (__stdcall *GetDlgItemFn)(void*, int);
extern "C" __declspec(dllimport) int __stdcall SetWindowPos(
    void* window,
    void* insert_after,
    int x,
    int y,
    int width,
    int height,
    unsigned int flags);

#pragma intrinsic(memset)

#pragma comment(lib, "comdlg32.lib")
#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "kernel32.lib")
#pragma comment(lib, "user32.lib")
#pragma comment(lib, "winmm.lib")
#pragma comment(linker, "/include:_exit")
#pragma comment(linker, "/include:__exit")
#pragma comment(linker, "/include:__ismbblead")

// Canonical startup storage maps trail event IDs 1..34 to indexes 0..33.
extern "C" void* OtTrailEventObjectPointers_00418c50[34];

struct MainWindowState_00403470 {
    char reserved_00[8];
    unsigned long interaction_state;

    int OtIsCloseConfirmationState_RealCpp() const;
};

struct RawIndexedBitmap_0040b710 {
    unsigned long indexed_pixels_handle;
    unsigned long indexed_pixels;
    unsigned long bitmap_info_handle;
    unsigned long bitmap_info;

    void OtBlitRawIndexedBitmapDependency_RealCpp(void* dc, int x, int y);
};

// Product-owner ABI declarations used by the small accepted wrappers below.
// These types deliberately expose only the member entry point: the objects are
// owned by their graphics/river/trail runtimes, and the forwarding bridge must
// not invent a second layout for them here.
struct PositionedBitmap_0040b7b0_Semantic {
    int OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
        void* dc,
        int source_x,
        int source_y);
};

struct PositionedBitmapDescriptorState_0040ba40 {
    int OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
        void* module,
        short descriptor_id);
};

struct RawIndexedBitmap_00410490_Product {
    void OtBlitRawIndexedBitmap_Product_004105a0(
        void* dc,
        int x,
        int y);
};

struct RiverCrossingOverlayState_00427e80 {
    void OtUpdateRiverCrossingOverlay_00427e80_RealCpp(
        void* dc,
        void* owner);
};

struct RiverCrossingView_00428520 {
    void OtRenderRiverCrossingSpriteLayer_00428520_RealCpp(
        void* dc,
        int layer);
};

struct TrailMapProgressLine_00406370_Product {
    void OtAdvanceTrailMapProgressLine_00406370_Product(
        void* map_window,
        int travel_progress);
};

struct PositionedBitmap_0040b720 {
    unsigned long bitmap_info_handle;
    unsigned long indexed_pixels_handle;
    unsigned long bitmap_info;
    unsigned long indexed_pixels;

    PositionedBitmap_0040b720* OtInitAndLoadPositionedBitmap_RealCpp(
        void* module,
        void* descriptor_id);
    int OtLoadPositionedBitmapDescriptorDependency_RealCpp(void* module, void* descriptor_id);
    void OtBlitWrappedPositionedBitmapDependency_RealCpp(void* dc, int source_x, int source_y);
};

#pragma pack(push, 1)
struct SpriteBlitter_004106c0 {
    char reserved_00[0x12];
    unsigned long bitmap_info_handle;
};
#pragma pack(pop)

struct TrailAnimationState_0042d460 {
    char reserved_000[0xa1c];
    int travel_submode;
    int river_crossing_mode;
    char reserved_a24[0x24];
    unsigned int progress;
    unsigned int progress_end;

    int OtResetTrailActionState_RealCpp(void* owner_window);
    void OtMarkTrailDialogActive_RealCpp(int unused);
    void OtSyncTrailActionControls_RealCpp(void* owner_window, int repaint);
    void OtSetControlEnabledState_RealCpp(
        void* control,
        int enabled,
        int repaint);
};

struct TrailOverlayWindow_00405df0 {
    PositionedBitmap_0040b720* overlay_bitmap;
    void* child_window;

    void OtShowTrailOverlayWindow_RealCpp(void* unused, void* dc);
    void OtHideTrailOverlayWindow_RealCpp();
};

struct TrailMapProgressState_00405f70 {
    PositionedBitmap_0040b720* base_bitmap;
    char reserved_04[0x10];
    int last_progress_segment;

    void OtResetTrailMapProgressLine_RealCpp(void* map_window, void* dc, int travel_progress);
    void OtAdvanceTrailProgressMeterDependency_RealCpp(void* map_window, int travel_progress);
};

struct WindowVisibilityState_0040fb50 {
    void* window;

    void OtShowWindowIfHidden_RealCpp(void* unused);
};

struct RiverCrossingState_00428e80 {
    char reserved_00[0x40];
    void* caption_window;
    char reserved_44[0x48];
    RawIndexedBitmap_0040b710* base_bitmap;

    void OtShowRiverCrossingView_RealCpp(void* dc, void* owner_window);
    void OtUpdateRiverCrossingOverlayDependency_RealCpp(void* dc, void* owner_window);
    void OtRenderRiverCrossingSpriteLayerDependency_RealCpp(void* dc, int layer);
    void OtRenderRiverCrossingRemainingLayers_RealCpp(void* dc, void* unused);
};

struct PartyState_00419970 {
    char reserved_000[0x116];
    short member_state[5];
};

#pragma pack(push, 1)
struct JourneyState_00416380 {
    char reserved_000[0x5a];
    unsigned char route_stop_flags;
    char reserved_05b[0x33];
    short current_terrain;
    short ration_level;
    short pace_level;
    short delay_days;
};

struct TrailActionRouteDescriptor_0042d080 {
    short route_id;
    short stop_kind;
};
#pragma pack(pop)

extern "C" JourneyState_00416380* g_journeyState = 0;
extern "C" TrailActionRouteDescriptor_0042d080* g_activeRouteDescriptor;
// Canonical storage is original 0x0043b6a0..0x0043ba2f. The final death-text
// flag is at +0x38c, proving the runtime occupies exactly 0x390 bytes.
extern "C" TrailEventTextRuntime_0041aac0_20260603
    g_trailEventRuntimeState = { 0 };

// 0042aac0
//
// No-op callback/stub used where the executable needs a do-nothing function
// body. The original is a single `ret`.
extern "C" void __cdecl OtNoopCallback_0042aac0_RealCpp()
{
}

// 00433510
//
// Reads a 32-bit packed value at the current cursor and advances that cursor by
// four bytes.
extern "C" unsigned long __cdecl OtReadPackedU32Cursor_RealCpp(unsigned char** cursor)
{
    unsigned char* next = *cursor;
    next += 4;
    *cursor = next;
    return *reinterpret_cast<unsigned long*>(next - 4);
}

// 00433540
//
// Reads the low 16 bits from a four-byte packed slot, then advances the cursor
// by one slot.
extern "C" unsigned short __cdecl OtReadPackedU16FromU32SlotCursor_RealCpp(
    unsigned char** cursor)
{
    unsigned char* next = *cursor;
    next += 4;
    *cursor = next;
    return *reinterpret_cast<unsigned short*>(next - 4);
}

// 00433520
//
// Reads a 64-bit packed value and advances the cursor by eight bytes.
#pragma optimize("s", off)
#pragma optimize("t", on)
extern "C" unsigned __int64 __cdecl OtReadPackedU64Cursor_RealCpp(unsigned char** cursor)
{
    unsigned char* next = *cursor;
    next += 8;
    *cursor = next;
    unsigned __int64 value = *reinterpret_cast<unsigned __int64*>(next - 8);
    next -= 8;
    return value;
}
#pragma optimize("", on)

// 0040b710
//
// Clears the four handle/pointer fields in a raw indexed bitmap object.
extern "C" RawIndexedBitmap_0040b710* __fastcall OtInitRawIndexedBitmap_RealCpp(
    RawIndexedBitmap_0040b710* bitmap)
{
    bitmap->indexed_pixels_handle = 0;
    bitmap->indexed_pixels = 0;
    bitmap->bitmap_info_handle = 0;
    bitmap->bitmap_info = 0;
    return bitmap;
}

// 0040b720
//
// Clears the four resource-handle/pointer fields in a positioned bitmap object.
extern "C" PositionedBitmap_0040b720* __fastcall OtInitPositionedBitmap_RealCpp(
    PositionedBitmap_0040b720* bitmap)
{
    bitmap->bitmap_info_handle = 0;
    bitmap->indexed_pixels_handle = 0;
    bitmap->indexed_pixels = 0;
    bitmap->bitmap_info = 0;
    return bitmap;
}

// 00403470
//
// Returns nonzero when the main window/controller state is the close-confirm
// state that posts the follow-up shutdown message instead of destroying the
// window immediately.
int MainWindowState_00403470::OtIsCloseConfirmationState_RealCpp() const
{
    return !(interaction_state - 0x0b);
}

// 0042d460
//
// Marks the trail UI as dialog-active unless travel is explicitly stopped, then
// runs the global side effect used when sound/UI synchronization is enabled.
#pragma optimize("s", off)
#pragma optimize("t", on)
void TrailAnimationState_0042d460::OtMarkTrailDialogActive_RealCpp(int)
{
    if (travel_submode != 1) {
        travel_submode = 2;
    }

    if (g_cdMediaMode_00439108 != 0) {
        OtStopMidiAudioDirectImport_0040d010_RealCpp();
    }
}
#pragma optimize("", on)

// 0042d000
//
// Clears the trail action state after modal river/trail work completes, then
// re-enables the synchronized trail action controls for the owner window.
#pragma optimize("s", off)
#pragma optimize("t", on)
int TrailAnimationState_0042d460::OtResetTrailActionState_RealCpp(void* owner_window)
{
    OtSyncTrailActionControls_RealCpp((travel_submode = 0, owner_window), 1);
    return 0;
}
#pragma optimize("", on)

// 0042d080
//
// Synchronizes the trail action controls with the active travel/river mode.
// The third argument passed to the control-state helper is retained because it
// is part of the original member-call footprint, although the helper itself
// only needs the requested enabled state.
#pragma optimize("s", off)
#pragma optimize("t", on)
void TrailAnimationState_0042d460::OtSyncTrailActionControls_RealCpp(
    void* owner_window,
    int repaint)
{
    void* dialog;
    int caller_repaint;

    if (river_crossing_mode != 2 && river_crossing_mode != 1) {
        caller_repaint = repaint;
        dialog = owner_window;
        OtSetControlEnabledState_RealCpp(
            static_cast<GetDlgItemFn>(&GetDlgItem)(dialog, 0x0fd4), 1, caller_repaint);
        OtSetControlEnabledState_RealCpp(
            static_cast<GetDlgItemFn>(&GetDlgItem)(dialog, 0x0fd6), 1, caller_repaint);
        OtSetControlEnabledState_RealCpp(
            static_cast<GetDlgItemFn>(&GetDlgItem)(dialog, 0x0fd5), 1, caller_repaint);

        if (g_journeyState->ration_level == 0) {
            OtSetControlEnabledState_RealCpp(
                static_cast<GetDlgItemFn>(&GetDlgItem)(dialog, 0x0fd7), 1, caller_repaint);
        } else if (g_journeyState->ration_level == 1) {
            OtSetControlEnabledState_RealCpp(
                static_cast<GetDlgItemFn>(&GetDlgItem)(dialog, 0x0fd8), 1, caller_repaint);
        } else {
            OtSetControlEnabledState_RealCpp(
                static_cast<GetDlgItemFn>(&GetDlgItem)(dialog, 0x0fd9), 1, caller_repaint);
        }

        OtSetControlEnabledState_RealCpp(
            static_cast<GetDlgItemFn>(&GetDlgItem)(dialog, 0x0fdc), 1, caller_repaint);
        OtSetControlEnabledState_RealCpp(
            static_cast<GetDlgItemFn>(&GetDlgItem)(dialog, 0x0fdb), 1, caller_repaint);
        OtSetControlEnabledState_RealCpp(
            static_cast<GetDlgItemFn>(&GetDlgItem)(dialog, 0x0fdd), 1, caller_repaint);

        if (g_journeyState->pace_level == 0) {
            OtSetControlEnabledState_RealCpp(
                static_cast<GetDlgItemFn>(&GetDlgItem)(dialog, 0x0fde), 1, caller_repaint);
        } else if (g_journeyState->pace_level == 1) {
            OtSetControlEnabledState_RealCpp(
                static_cast<GetDlgItemFn>(&GetDlgItem)(dialog, 0x0fdf), 1, caller_repaint);
        } else {
            OtSetControlEnabledState_RealCpp(
                static_cast<GetDlgItemFn>(&GetDlgItem)(dialog, 0x0fe0), 1, caller_repaint);
        }
    } else {
        caller_repaint = repaint;
        dialog = owner_window;
        OtSetControlEnabledState_RealCpp(
            static_cast<GetDlgItemFn>(&GetDlgItem)(dialog, 0x0fd4), 0, caller_repaint);
        OtSetControlEnabledState_RealCpp(
            static_cast<GetDlgItemFn>(&GetDlgItem)(dialog, 0x0fd6), 0, caller_repaint);
        OtSetControlEnabledState_RealCpp(
            static_cast<GetDlgItemFn>(&GetDlgItem)(dialog, 0x0fd5), 0, caller_repaint);

        if (g_journeyState->ration_level == 0) {
            OtSetControlEnabledState_RealCpp(
                static_cast<GetDlgItemFn>(&GetDlgItem)(dialog, 0x0fd7), 0, caller_repaint);
        } else if (g_journeyState->ration_level == 1) {
            OtSetControlEnabledState_RealCpp(
                static_cast<GetDlgItemFn>(&GetDlgItem)(dialog, 0x0fd8), 0, caller_repaint);
        } else {
            OtSetControlEnabledState_RealCpp(
                static_cast<GetDlgItemFn>(&GetDlgItem)(dialog, 0x0fd9), 0, caller_repaint);
        }

        OtSetControlEnabledState_RealCpp(
            static_cast<GetDlgItemFn>(&GetDlgItem)(dialog, 0x0fdc), 0, caller_repaint);
        OtSetControlEnabledState_RealCpp(
            static_cast<GetDlgItemFn>(&GetDlgItem)(dialog, 0x0fdb), 0, caller_repaint);
        OtSetControlEnabledState_RealCpp(
            static_cast<GetDlgItemFn>(&GetDlgItem)(dialog, 0x0fdd), 0, caller_repaint);

        if (g_journeyState->pace_level == 0) {
            OtSetControlEnabledState_RealCpp(
                static_cast<GetDlgItemFn>(&GetDlgItem)(dialog, 0x0fde), 0, caller_repaint);
        } else if (g_journeyState->pace_level == 1) {
            OtSetControlEnabledState_RealCpp(
                static_cast<GetDlgItemFn>(&GetDlgItem)(dialog, 0x0fdf), 0, caller_repaint);
        } else {
            OtSetControlEnabledState_RealCpp(
                static_cast<GetDlgItemFn>(&GetDlgItem)(dialog, 0x0fe0), 0, caller_repaint);
        }
    }

    if (river_crossing_mode != 2 && river_crossing_mode != 1) {
        OtSetControlEnabledState_RealCpp(
            static_cast<GetDlgItemFn>(&GetDlgItem)(dialog, 0x0fe1), 1, caller_repaint);
    } else {
        OtSetControlEnabledState_RealCpp(
            static_cast<GetDlgItemFn>(&GetDlgItem)(dialog, 0x0fe1), 0, caller_repaint);
    }

    if ((travel_submode == 1 || travel_submode == 2) &&
        g_trailProgressStopPending != 0 &&
        (g_activeRouteDescriptor->stop_kind == 2 ||
         g_journeyState->current_terrain == 0)) {
        OtSetControlEnabledState_RealCpp(
            static_cast<GetDlgItemFn>(&GetDlgItem)(dialog, 0x0fda), 1, caller_repaint);
    } else {
        OtSetControlEnabledState_RealCpp(
            static_cast<GetDlgItemFn>(&GetDlgItem)(dialog, 0x0fda), 0, caller_repaint);
    }

    if (river_crossing_mode != 1 && river_crossing_mode != 2) {
        if (travel_submode == 1) {
            OtSetControlEnabledState_RealCpp(
                static_cast<GetDlgItemFn>(&GetDlgItem)(dialog, 0x0fd2), 1, caller_repaint);
            OtSetControlEnabledState_RealCpp(
                static_cast<GetDlgItemFn>(&GetDlgItem)(dialog, 0x0fd3), 0, caller_repaint);
        } else {
            OtSetControlEnabledState_RealCpp(
                static_cast<GetDlgItemFn>(&GetDlgItem)(dialog, 0x0fd2), 0, caller_repaint);
            OtSetControlEnabledState_RealCpp(
                static_cast<GetDlgItemFn>(&GetDlgItem)(dialog, 0x0fd3), 1, caller_repaint);
        }
    } else {
        OtSetControlEnabledState_RealCpp(
            static_cast<GetDlgItemFn>(&GetDlgItem)(dialog, 0x0fd2), 0, caller_repaint);
        OtSetControlEnabledState_RealCpp(
            static_cast<GetDlgItemFn>(&GetDlgItem)(dialog, 0x0fd3), 0, caller_repaint);
    }
}

void TrailAnimationState_0042d460::OtSetControlEnabledState_RealCpp(
    void* control,
    int enabled,
    int)
{
    register void* window = control;
    register int requested = enabled;

    if (requested != 0) {
        if (IsWindowEnabled(window) == 0) {
            EnableWindow(window, requested);
        }
    } else if (IsWindowEnabled(window) != 0) {
        EnableWindow(window, requested);
    }
}
#pragma optimize("", on)

// 00416470
//
// Installs the fallback "unimplemented event" text pointer into the active
// trail-event message slot.
extern "C" void __cdecl OtSetUnimplementedEventMessage_RealCpp()
{
    g_trailEventPrimaryText = g_unimplementedEventMessageText;
}

// 0041a300
//
// Clears the 13-entry event-adjustment list used by trail event side effects.
#pragma optimize("s", off)
#pragma optimize("t", on)
extern "C" short* __fastcall OtClearEventAdjustmentList_RealCpp(short* adjustments)
{
    short index = 0;
    do {
        adjustments[index++] = 0;
    } while (index < 13);

    return adjustments;
}
#pragma optimize("", on)

// 0041a410
//
// Tests whether any event-adjustment entry is nonzero.
#pragma optimize("s", off)
#pragma optimize("t", on)
extern "C" int __fastcall OtHasEventAdjustmentEntries_RealCpp(const short* adjustments)
{
    short index = 0;
    int has_entries = 0;
    do {
        if (adjustments[index] != 0) {
            has_entries = 1;
        }
        ++index;
    } while (index < 13);

    return has_entries;
}
#pragma optimize("", on)

// 00419970
//
// Counts party members whose state is not the dead-state marker 0x0f.
#pragma optimize("s", off)
#pragma optimize("t", on)
extern "C" short __fastcall OtCountLivingPartyMembers_RealCpp(const PartyState_00419970* party)
{
    short living_members = 0;
    short index = 0;
    const short dead_state = 0x0f;
    do {
        if (party->member_state[index] != dead_state) {
            ++living_members;
        }
        ++index;
    } while (index < 5);

    return living_members;
}
#pragma optimize("", on)

// 00418c70
//
// Queues a trail event by ID through the first vtable slot on the global trail
// event table.
extern "C" void __cdecl OtTriggerTrailEventById_RealCpp(short event_id)
{
    TrailEventDispatchInterface_00418c70* event =
        static_cast<TrailEventDispatchInterface_00418c70*>(
            OtTrailEventObjectPointers_00418c50[event_id - 1]);
    event->OtSetTrailEventPendingState_RealCpp(1);
}

// 00418c90
//
// Clears a trail event pending flag through the same event-table dispatch path.
extern "C" void __cdecl OtClearTrailEventById_RealCpp(short event_id)
{
    TrailEventDispatchInterface_00418c70* event =
        static_cast<TrailEventDispatchInterface_00418c70*>(
            OtTrailEventObjectPointers_00418c50[event_id - 1]);
    event->OtSetTrailEventPendingState_RealCpp(0);
}

// 00416460
//
// Sets or clears the pending flag at +0x08 on a trail event object. The original
// stack parameter is loaded as a full int and truncated by the 16-bit store.
void TrailEventPendingStateImplementation_00416460::
    OtSetTrailEventPendingState_RealCpp(
    int pending_value)
{
    pending = static_cast<short>(pending_value);
}

// 004165c0
//
// Sets or clears the queued party-recovery event. Clearing also drops each
// per-member recovery flag.
#pragma optimize("s", off)
#pragma optimize("t", on)
void PartyFollowupEventObject_004165c0::OtSetPartyRecoveryEventPendingState_RealCpp(
    int pending_value)
{
    pending = static_cast<short>(pending_value);
    if (pending_value == 0) {
        memset(member_followup_flags, 0, sizeof(member_followup_flags));
    }
}
#pragma optimize("", on)

// 004168a0
//
// Same pending/flag storage pattern as the recovery event, used for grouped
// party-death follow-up messages.
#pragma optimize("s", off)
#pragma optimize("t", on)
void PartyFollowupEventObject_004165c0::OtSetPartyDeathEventPendingState_RealCpp(
    int pending_value)
{
    pending = static_cast<short>(pending_value);
    if (pending_value == 0) {
        memset(member_followup_flags, 0, sizeof(member_followup_flags));
    }
}
#pragma optimize("", on)

// 00418cb0
//
// Queues the party-recovery follow-up and marks the affected party slot.
#pragma optimize("s", off)
#pragma optimize("t", on)
extern "C" void __cdecl OtQueuePartyRecoveryEventForMember_RealCpp(short member_index)
{
    reinterpret_cast<PartyFollowupEventObject_004165c0*>(
        OtTrailEventObjectPointers_00418c50[2])
        ->OtSetTrailEventPendingState_RealCpp(1);
    reinterpret_cast<PartyFollowupEventObject_004165c0*>(
        OtTrailEventObjectPointers_00418c50[2])
        ->member_followup_flags[member_index] = 1;
}
#pragma optimize("", on)

// 00418ce0
//
// Queues the party-death follow-up and marks the affected party slot.
#pragma optimize("s", off)
#pragma optimize("t", on)
extern "C" void __cdecl OtQueuePartyDeathEventForMember_RealCpp(short member_index)
{
    reinterpret_cast<PartyFollowupEventObject_004165c0*>(
        OtTrailEventObjectPointers_00418c50[0])
        ->OtSetTrailEventPendingState_RealCpp(1);
    reinterpret_cast<PartyFollowupEventObject_004165c0*>(
        OtTrailEventObjectPointers_00418c50[0])
        ->member_followup_flags[member_index] = 1;
}
#pragma optimize("", on)

// 00427d50
//
// Chooses the trade-offer dialog text. A zero accepted flag keeps the pending
// offer text; nonzero switches to the accepted-offer confirmation text.
extern "C" const char* __cdecl OtGetTradeOfferPromptText_RealCpp()
{
    if (g_tradeOfferAccepted != 0) {
        return g_trailEventFollowupText;
    }

    return g_trailEventPromptText;
}

// 0042a3c0
//
// Returns the global trail-overlay-active flag.
extern "C" int __cdecl OtIsTrailOverlayActive_RealCpp()
{
    return g_trailProgressStopPending;
}

// 00430fd0
//
// Stores the CRT random-generator seed/state value used by OtRandomBelow.
extern "C" void __cdecl OtSeedRandomGenerator_RealCpp(unsigned int seed)
{
    g_crtRandState = seed;
}

// 004106c0
//
// Frees the BITMAPINFO allocation owned by a sprite blitter. The source sprite
// sheet itself is owned by the surrounding hunt/river/rafting state.
#pragma optimize("s", off)
#pragma optimize("t", on)
extern "C" void __fastcall OtFreeSpriteBlitter_RealCpp(SpriteBlitter_004106c0* sprite)
{
    unsigned long handle = sprite->bitmap_info_handle;
    if (handle != 0) {
        GlobalUnlock(handle);
        register unsigned long free_handle = sprite->bitmap_info_handle;
        GlobalFree(free_handle);
    }
}
#pragma optimize("", on)

// 00405df0
//
// Hides the trail overlay child window.
#pragma optimize("s", off)
#pragma optimize("t", on)
void TrailOverlayWindow_00405df0::OtHideTrailOverlayWindow_RealCpp()
{
    ShowWindow(child_window, 0);
}
#pragma optimize("", on)

// Honest ABI bridges from the historical wrapper type to the canonical
// positioned-bitmap Product implementations. Keep these expanded bridges out
// of ordinary .text so the accepted wrapper bodies retain their code layout.
#pragma optimize("s", off)
#pragma optimize("t", on)
#pragma code_seg(".otsem")
void PositionedBitmap_0040b720::OtBlitWrappedPositionedBitmapDependency_RealCpp(
    void* dc,
    int source_x,
    int source_y)
{
    reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(this)->
        OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
            dc,
            source_x,
            source_y);
}

int PositionedBitmap_0040b720::OtLoadPositionedBitmapDescriptorDependency_RealCpp(
    void* module,
    void* descriptor_id)
{
    short resource_id = static_cast<short>(
        reinterpret_cast<unsigned long>(descriptor_id));
    return reinterpret_cast<PositionedBitmapDescriptorState_0040ba40*>(this)->
        OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            module,
            resource_id);
}
#pragma code_seg()
#pragma optimize("", on)

// 0040b730
//
// Clears a positioned-bitmap object, then loads its type-0x7d2 descriptor.
#pragma optimize("s", off)
#pragma optimize("t", on)
PositionedBitmap_0040b720*
PositionedBitmap_0040b720::OtInitAndLoadPositionedBitmap_RealCpp(void* module, void* descriptor_id)
{
    bitmap_info_handle = 0;
    indexed_pixels_handle = 0;
    indexed_pixels = 0;
    bitmap_info = 0;
    OtLoadPositionedBitmapDescriptorDependency_RealCpp(module, descriptor_id);
    return this;
}
#pragma optimize("", on)

// 00405db0
//
// Blits the trail overlay art and shows the associated child window if needed.
#pragma optimize("s", off)
#pragma optimize("t", on)
void TrailOverlayWindow_00405df0::OtShowTrailOverlayWindow_RealCpp(void*, void* dc)
{
    overlay_bitmap->OtBlitWrappedPositionedBitmapDependency_RealCpp(dc, 0, 0);

    if (IsWindowVisible(child_window) == 0) {
        ShowWindow(child_window, 5);
    }
}
#pragma optimize("", on)

// 0040fb50
//
// Shows a window only when it is not already visible.
#pragma optimize("s", off)
#pragma optimize("t", on)
void WindowVisibilityState_0040fb50::OtShowWindowIfHidden_RealCpp(void*)
{
    if (IsWindowVisible(window) == 0) {
        ShowWindow(window, 5);
    }
}
#pragma optimize("", on)

// 00406940
//
// Creates the ground-fill brush for the trail travel scene. Palette mode uses
// palette index 0xe3 directly; RGB mode asks GDI for the nearest device color.
#pragma optimize("s", off)
#pragma optimize("t", on)
extern "C" unsigned long __stdcall OtCreateTrailGroundBrush_RealCpp(void* dc)
{
    if (g_usesIndexedColorDisplay != 0) {
        return CreateSolidBrush(0x010000e3);
    }

    return CreateSolidBrush(GetNearestColor(dc, 0x0000fa3a));
}
#pragma optimize("", on)

// 00406980
//
// Creates the sky-fill brush for the trail travel scene. Palette mode uses
// palette index 0xe2; RGB mode uses the nearest color for the recovered sky RGB.
#pragma optimize("s", off)
#pragma optimize("t", on)
extern "C" unsigned long __stdcall OtCreateTrailSkyBrush_RealCpp(void* dc)
{
    if (g_usesIndexedColorDisplay != 0) {
        return CreateSolidBrush(0x010000e2);
    }

    return CreateSolidBrush(GetNearestColor(dc, 0x00fad763));
}
#pragma optimize("", on)

// River-view ABI bridges target the real graphics and river Product owners.
#pragma optimize("s", off)
#pragma optimize("t", on)
#pragma code_seg(".otsem")
void RawIndexedBitmap_0040b710::OtBlitRawIndexedBitmapDependency_RealCpp(
    void* dc,
    int x,
    int y)
{
    reinterpret_cast<RawIndexedBitmap_00410490_Product*>(this)->
        OtBlitRawIndexedBitmap_Product_004105a0(dc, x, y);
}

void RiverCrossingState_00428e80::OtUpdateRiverCrossingOverlayDependency_RealCpp(
    void* dc,
    void* owner_window)
{
    reinterpret_cast<RiverCrossingOverlayState_00427e80*>(this)->
        OtUpdateRiverCrossingOverlay_00427e80_RealCpp(
            dc,
            owner_window);
}

void RiverCrossingState_00428e80::OtRenderRiverCrossingSpriteLayerDependency_RealCpp(
    void* dc,
    int layer)
{
    reinterpret_cast<RiverCrossingView_00428520*>(this)->
        OtRenderRiverCrossingSpriteLayer_00428520_RealCpp(dc, layer);
}
#pragma code_seg()
#pragma optimize("", on)

// 00427f00
//
// Shows the river-crossing caption/static child window, blits the base
// river-crossing indexed bitmap at the recovered screen offset, then draws the
// current layered river overlay.
#pragma optimize("s", off)
#pragma optimize("t", on)
void RiverCrossingState_00428e80::OtShowRiverCrossingView_RealCpp(void* dc, void* owner_window)
{
    register RiverCrossingState_00428e80* state = this;
    register void* render_dc = dc;
    void* owner = owner_window;

    ShowWindow(state->caption_window, 5);
    state->base_bitmap->OtBlitRawIndexedBitmapDependency_RealCpp(render_dc, 0x3b, 1);
    state->OtUpdateRiverCrossingOverlayDependency_RealCpp(render_dc, owner);
}
#pragma optimize("", on)

// 00428e80
//
// Draws the remaining river-crossing sprite layers after the two primary
// overlay passes have already been rendered.
#pragma optimize("s", off)
#pragma optimize("t", on)
void RiverCrossingState_00428e80::OtRenderRiverCrossingRemainingLayers_RealCpp(void* dc, void*)
{
    RiverCrossingState_00428e80* state = this;
    void* render_dc = dc;

    state->OtRenderRiverCrossingSpriteLayerDependency_RealCpp(render_dc, 2);
    state->OtRenderRiverCrossingSpriteLayerDependency_RealCpp(render_dc, 3);
    state->OtRenderRiverCrossingSpriteLayerDependency_RealCpp(render_dc, 4);
    state->OtRenderRiverCrossingSpriteLayerDependency_RealCpp(render_dc, 5);
    state->OtRenderRiverCrossingSpriteLayerDependency_RealCpp(render_dc, 6);
    state->OtRenderRiverCrossingSpriteLayerDependency_RealCpp(render_dc, 7);
}
#pragma optimize("", on)

// Forwards the accepted reset wrapper to the canonical progress-line runtime.
#pragma optimize("s", off)
#pragma optimize("t", on)
#pragma code_seg(".otsem")
void TrailMapProgressState_00405f70::OtAdvanceTrailProgressMeterDependency_RealCpp(
    void* map_window,
    int travel_progress)
{
    reinterpret_cast<TrailMapProgressLine_00406370_Product*>(this)->
        OtAdvanceTrailMapProgressLine_00406370_Product(
            map_window,
            travel_progress);
}
#pragma code_seg()
#pragma optimize("", on)

// 00405f70
//
// Restores the trail-map base bitmap, resets the drawn progress segment, and
// advances the progress-meter line to the requested travel progress.
#pragma optimize("s", off)
#pragma optimize("t", on)
void TrailMapProgressState_00405f70::OtResetTrailMapProgressLine_RealCpp(
    void* map_window,
    void* dc,
    int travel_progress)
{
    if (base_bitmap != 0) {
        base_bitmap->OtBlitWrappedPositionedBitmapDependency_RealCpp(dc, 0, 0);
    }

    last_progress_segment = 0;
    OtAdvanceTrailProgressMeterDependency_RealCpp(map_window, travel_progress);
}
#pragma optimize("", on)

#include "../river/river_crossing_state_runtime.h"

// 00428ed0
//
// Stops active sndPlaySound playback and, when the wave-audio backend is
// enabled, stops the current MCI wave device without closing it.
#pragma optimize("s", off)
#pragma optimize("t", on)
void RiverCrossingState_004285a0_ProductWip::
OtStopSfxAndWaveAudio_RealCpp()
{
    if (DAT_004390e8 != 0) {
        sndPlaySoundA(0, 0);

        if (g_cdMediaMode_00439108 != 0) {
            OtStopWaveAudioDirectImport_0040d480_RealCpp();
        }
    }
}
#pragma optimize("", on)

// 00430a40
//
// CRT operator-new allocation wrapper used throughout the executable. It
// forwards the requested byte count with the new-handler retry flag enabled.
#pragma optimize("s", off)
#pragma optimize("t", on)
extern "C" void* __cdecl OtAllocateNewBlock_RealCpp(unsigned int size)
{
    return _nh_malloc(size, 1);
}
#pragma optimize("", on)

// 00430550
//
// Import thunk for COMDLG32 GetOpenFileNameA.
extern "C" int __stdcall OtImportGetOpenFileNameA_RealCpp(void* open_file_name)
{
    return GetOpenFileNameA(open_file_name);
}

// 00430556
//
// Import thunk for COMDLG32 GetSaveFileNameA.
extern "C" int __stdcall OtImportGetSaveFileNameA_RealCpp(void* open_file_name)
{
    return GetSaveFileNameA(open_file_name);
}

// 00436a38
//
// Import thunk for KERNEL32 RtlUnwind.
extern "C" void __stdcall OtImportRtlUnwind_RealCpp(
    void* frame,
    void* target_ip,
    void* exception_record,
    void* return_value)
{
    RtlUnwind(frame, target_ip, exception_record, return_value);
}

// 00401ed0
//
// Resizes a child dialog control without moving it or changing z-order.
#pragma optimize("s", off)
#pragma optimize("t", on)
extern "C" void __cdecl OtResizeControl_RealCpp(
    void* dialog,
    int control_id,
    int width,
    int height)
{
    void* control = GetDlgItem(dialog, control_id);
    if (control != 0) {
        SetWindowPos(control, 0, 0, 0, width, height, 6);
    }
}
#pragma optimize("", on)

// 00416380
//
// Applies a pending trail delay to the global journey state. When the requested
// delay exceeds the current pending delay, the game accumulates it and marks the
// route-stop flag before advancing the shared calendar/event state.
extern "C" void __stdcall OtAddTrailDelayDays_RealCpp(short days)
{
    short requested_delay = days;
    register JourneyState_00416380* journey = g_journeyState;
    short current_delay = journey->delay_days;
    short* delay_days = &journey->delay_days;

    if (requested_delay > current_delay) {
        *delay_days = static_cast<short>(current_delay + requested_delay);
        g_journeyState->route_stop_flags =
            static_cast<unsigned char>(g_journeyState->route_stop_flags | 0x20);
    }

    reinterpret_cast<DelayTextState_0041ac20*>(&g_trailEventRuntimeState)->
        OtFormatDelayDaysText_RealCpp(requested_delay);
}

// 0040d4f0
//
// Returns a pseudo-random value in [0, upper_bound). The original lazily seeds
// the CRT generator from time(0) the first time this helper is called.
#pragma optimize("s", off)
#pragma optimize("t", on)
extern "C" int __cdecl OtRandomBelow_RealCpp(int upper_bound)
{
    if (g_randomGeneratorSeeded == 0) {
        int seed = static_cast<int>(time(0));
        srand(seed);
        g_randomGeneratorSeeded = 1;
    }

    int scaled_random = rand() * upper_bound;
    return scaled_random / 0x8000;
}
#pragma optimize("", on)
