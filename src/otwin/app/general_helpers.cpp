// Additional semantic C++ match trials for the OTWIN32 30% pass.
//
// These are ordinary VC4-compatible C++ functions. Rows are promoted to the
// manifest only after byte comparison against the original executable.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "../trail/trail_event_context_source.h"

#include "app_runtime.h"
#include "active_text_runtime.h"
#include "../trail/trail_event_text_runtime.h"

extern "C" __declspec(dllimport) int __cdecl wsprintfA(
    char* buffer,
    const char* format,
    ...);
extern "C" const char* PTR_s_oregon_ini_004390dc;
extern "C" const char g_dialogPlacementProfileKey_00401430[] = "location";
extern "C" const char g_dialogPlacementFormat_00401430[] =
    "%d, %d, %d, %d";
extern "C" int g_usesIndexedColorDisplay;
extern "C" __declspec(dllimport) void* __stdcall LoadCursorA(
    void* instance,
    const void* cursor_name);
extern "C" __declspec(dllimport) void* __stdcall SetCursor(void* cursor);
extern "C" __declspec(dllimport) long __stdcall GetClassLongA(
    void* window,
    int index);
extern "C" __declspec(dllimport) int __stdcall FreeResource(void* resource);

#define PTR_wsprintfA_00401430 wsprintfA
#define PTR_GetDC_00403480 GetDC
#define PTR_GetDeviceCaps_00403480 GetDeviceCaps
#define PTR_ReleaseDC_00403480 ReleaseDC
#define PTR_FreeResource_00406240 FreeResource
#define PTR_DeleteObject_00406240 DeleteObject
#define PTR_LoadCursorA_0040d530 LoadCursorA
#define PTR_SetCursor_0040d530 SetCursor
#define PTR_GetClassLongA_0040d530 GetClassLongA
extern "C" int g_activeTextUsesEditControl = 0;
extern "C" void* g_activeTextEditWindow = 0;
extern "C" __declspec(dllimport) void* __stdcall GlobalLock(void* handle);
extern "C" __declspec(dllimport) int __stdcall GlobalUnlock(void* handle);
extern "C" char g_trailEventMessageBuffer[];
extern "C" int g_riverResultPromptStringId;
#define g_trailEventPromptText (g_trailEventRuntimeState.primary_text)
#define g_trailEventFollowupText (g_trailEventRuntimeState.secondary_text)

void __cdecl operator delete(void* block);

#pragma comment(lib, "user32.lib")
#pragma comment(lib, "gdi32.lib")
#pragma intrinsic(strlen)

#pragma pack(push, 1)
struct DialogPlacementRect_00401430 {
    int left;
    int top;
    int right;
    int bottom;
};

struct DisplayCapabilityState_00403480 {
    char reserved_00[4];
    void* window;

    void OtProbeIndexedDisplayCapability_00403480_RealCpp();
    void OtProbeIndexedDisplayCapabilityDirect_00403480_RealCpp();
    void OtProbeIndexedDisplayCapabilityDirectRegisterDc_00403480_RealCpp();
};

struct PositionedBitmapForOwner_00406240 {
    unsigned long bitmap_info_handle;
    unsigned long indexed_pixels_handle;
};

struct PositionedBitmapFree_0040b760_42pct {
    unsigned long bitmap_info_handle;
    unsigned long indexed_pixels_handle;

    void OtFreePositionedBitmapAlt5_0040b760_42pct();
};

struct GraphicsResourceOwner_00406240 {
    PositionedBitmapForOwner_00406240* owned_bitmap;
    char reserved_04[0x14];
    void* gdi_object_18;
    void* gdi_object_1c;
    void* gdi_object_20;
    void* gdi_object_24;
    char reserved_28[0x14];
    void* optional_gdi_object;

    void OtDestroyGraphicsResourceOwner_00406240_RealCpp();
    void OtDestroyGraphicsResourceOwnerNoAsm_00406240_RealCpp();
    void OtDestroyGraphicsResourceOwnerDirect_00406240_RealCpp();
    void OtDestroyGraphicsResourceOwnerDirectCalls_00406240_RealCpp();
};

struct JourneyStateForTrailEventContext_004163c0 {
    char reserved_00[0x50];
    unsigned short field_50;
    char reserved_52[4];
    unsigned short field_56;
};

#pragma pack(pop)

extern "C" JourneyStateForTrailEventContext_004163c0* g_journeyState;

#pragma optimize("s", off)
#pragma optimize("t", on)

// 00401430
//
extern "C" void __cdecl OtPersistDialogPlacement_00401430_RealCpp(
    const char* profile_section,
    const DialogPlacementRect_00401430* rect)
{
    char location[40];

    PTR_wsprintfA_00401430(
        location,
        g_dialogPlacementFormat_00401430,
        rect->left,
        rect->top,
        rect->right,
        rect->bottom);
    WritePrivateProfileStringA(
        profile_section,
        g_dialogPlacementProfileKey_00401430,
        location,
        PTR_s_oregon_ini_004390dc);
}

void DisplayCapabilityState_00403480::
    OtProbeIndexedDisplayCapabilityDirect_00403480_RealCpp()
{
    register DisplayCapabilityState_00403480* state = this;
    register int (__stdcall *get_device_caps)(void*, int);

    g_usesIndexedColorDisplay = 1;

    void* dc = GetDC(state->window);
    int bits_per_pixel = (get_device_caps = GetDeviceCaps)(dc, 0x0c);
    if (bits_per_pixel != 8 ||
        (get_device_caps(dc, 0x26) & 0x100) == 0) {
        g_usesIndexedColorDisplay = 0;
    }

    ReleaseDC(state->window, dc);
}

void DisplayCapabilityState_00403480::
    OtProbeIndexedDisplayCapabilityDirectRegisterDc_00403480_RealCpp()
{
    register DisplayCapabilityState_00403480* state = this;
    register void* dc;
    int (__stdcall *get_device_caps)(void*, int);

    g_usesIndexedColorDisplay = 1;

    dc = GetDC(state->window);
    if ((get_device_caps = GetDeviceCaps)(dc, 0x0c) != 8 ||
        (get_device_caps(dc, 0x26) & 0x100) == 0) {
        g_usesIndexedColorDisplay = 0;
    }

    ReleaseDC(state->window, dc);
}

extern "C" void __fastcall OtFreePositionedBitmapDependencyCall_00406240(
    PositionedBitmapForOwner_00406240* bitmap)
{
    reinterpret_cast<PositionedBitmapFree_0040b760_42pct*>(bitmap)->
        OtFreePositionedBitmapAlt5_0040b760_42pct();
}

extern "C" void __stdcall OtDeleteOwnedBitmapBlock_00406240(void* block)
{
    operator delete(block);
}

// 00406240
//
// Releases the resource handles and optional GDI object, then destroys the
// positioned bitmap owned by a graphics-resource aggregate.
void GraphicsResourceOwner_00406240::
    OtDestroyGraphicsResourceOwnerNoAsm_00406240_RealCpp()
{
    register GraphicsResourceOwner_00406240* owner = this;
    register int (__stdcall *delete_object)(void*);

    (delete_object = PTR_FreeResource_00406240)(owner->gdi_object_18);
    {
        register void* object_1c = owner->gdi_object_1c;
        delete_object(object_1c);
    }
    delete_object(owner->gdi_object_20);
    delete_object(owner->gdi_object_24);

    if (owner->optional_gdi_object != 0) {
        PTR_DeleteObject_00406240(owner->optional_gdi_object);
    }

    PositionedBitmapForOwner_00406240* bitmap = owner->owned_bitmap;
    if (bitmap != 0) {
        reinterpret_cast<PositionedBitmapFree_0040b760_42pct*>(bitmap)->
            OtFreePositionedBitmapAlt5_0040b760_42pct();
        operator delete(bitmap);
    }
}

void GraphicsResourceOwner_00406240::
    OtDestroyGraphicsResourceOwnerDirect_00406240_RealCpp()
{
    register GraphicsResourceOwner_00406240* owner = this;
    register int (__stdcall *delete_object)(void*);

    (delete_object = DeleteObject)(owner->gdi_object_18);
    {
        register void* object_1c = owner->gdi_object_1c;
        delete_object(object_1c);
    }
    delete_object(owner->gdi_object_20);
    delete_object(owner->gdi_object_24);

    if (owner->optional_gdi_object != 0) {
        DeleteObject(owner->optional_gdi_object);
    }

    PositionedBitmapForOwner_00406240* bitmap = owner->owned_bitmap;
    if (bitmap != 0) {
        reinterpret_cast<PositionedBitmapFree_0040b760_42pct*>(bitmap)->
            OtFreePositionedBitmapAlt5_0040b760_42pct();
        operator delete(bitmap);
    }
}

void GraphicsResourceOwner_00406240::
    OtDestroyGraphicsResourceOwnerDirectCalls_00406240_RealCpp()
{
    register GraphicsResourceOwner_00406240* owner = this;

    FreeResource(owner->gdi_object_18);
    FreeResource(owner->gdi_object_1c);
    FreeResource(owner->gdi_object_20);
    FreeResource(owner->gdi_object_24);

    if (owner->optional_gdi_object != 0) {
        DeleteObject(owner->optional_gdi_object);
    }

    PositionedBitmapForOwner_00406240* bitmap = owner->owned_bitmap;
    if (bitmap != 0) {
        reinterpret_cast<PositionedBitmapFree_0040b760_42pct*>(bitmap)->
            OtFreePositionedBitmapAlt5_0040b760_42pct();
        operator delete(bitmap);
    }
}

void GraphicsResourceOwner_00406240::OtDestroyGraphicsResourceOwner_00406240_RealCpp()
{
    OtDestroyGraphicsResourceOwnerDirectCalls_00406240_RealCpp();
}

// 0040d530
//
// Selects the busy cursor during state transitions, otherwise restores the
// dialog class cursor and reports whether a valid cursor was available.
extern "C" int __cdecl OtSelectDialogCursor_0040d530_RealCpp(
    int force_busy_cursor,
    void* window)
{
    if (force_busy_cursor != 0) {
        PTR_SetCursor_0040d530(
            PTR_LoadCursorA_0040d530(0, reinterpret_cast<const void*>(0x7f02)));
        return 1;
    }

    long cursor = PTR_GetClassLongA_0040d530(window, -12);
    if (cursor != 0) {
        PTR_SetCursor_0040d530(reinterpret_cast<void*>(cursor));
    }

    return static_cast<unsigned long>(cursor) >= 1;
}

// 0040c790
//
// Reports the active text length, using the edit control length when present or
// the locked global text buffer length including its trailing NUL otherwise.
extern "C" unsigned int __cdecl OtGetActiveTextLength_0040c790_RealCpp()
{
    unsigned int length = 0;

    if (g_activeTextUsesEditControl != 0) {
        length = GetWindowTextLengthA(g_activeTextEditWindow);
    } else if (g_activeTextGlobalHandle_Product != 0) {
        const char* text = static_cast<const char*>(GlobalLock(g_activeTextGlobalHandle_Product));
        length = strlen(text) + 1;
        GlobalUnlock(g_activeTextGlobalHandle_Product);
    }

    return length;
}

// 004163c0
//
// Copies the active trail-event descriptor fields into the global text context
// consumed by the event dialog.
void TrailEventContextSource_004163c0::OtPrimeActiveTrailEventContext_004163c0_RealCpp()
{
    *reinterpret_cast<unsigned short*>(g_trailEventMessageBuffer + 0x1e) = 0;
    *reinterpret_cast<unsigned short*>(g_trailEventMessageBuffer) = message_count;
    *reinterpret_cast<unsigned int*>(g_trailEventMessageBuffer + 2) = field_20;

    JourneyStateForTrailEventContext_004163c0* journey_for_weather = g_journeyState;
    *reinterpret_cast<unsigned short*>(g_trailEventMessageBuffer + 0x20) = field_26;

    JourneyStateForTrailEventContext_004163c0* journey_for_route = g_journeyState;
    unsigned short variant = static_cast<unsigned short>(journey_for_weather->field_56 >= 1);
    if (journey_for_route->field_50 != 0) {
        variant = static_cast<unsigned short>(variant + 2);
    }

    *reinterpret_cast<unsigned int*>(g_trailEventMessageBuffer + 6) =
        variant_text_ids[static_cast<short>(variant)];
    *reinterpret_cast<unsigned int*>(g_trailEventMessageBuffer + 0x0a) = field_22;
    unsigned short field_24_value = field_24;
    *reinterpret_cast<unsigned int*>(g_trailEventMessageBuffer + 0x0e) =
        field_24_value;
    unsigned int message_count_value = message_count;
    *reinterpret_cast<const char**>(g_trailEventMessageBuffer + 0x16) = g_trailEventPromptText;
    *reinterpret_cast<const char**>(g_trailEventMessageBuffer + 0x1a) = g_trailEventFollowupText;
    *reinterpret_cast<unsigned int*>(g_trailEventMessageBuffer + 0x12) =
        message_count_value + 0x258;
}

// 00427cf0
//
// Picks a random string-id for the offered trade item. The original chooses
// uniformly among 9 hand-listed RT_STRING ids and returns the selected id to
// the trade dialog formatter. Restored from the pre-split semantic_30pct file.
extern "C" int __cdecl OtRandomBelow_RealCpp(int upper_bound);

extern "C" int __cdecl OtChooseRandomTradeItemStringId_RealCpp()
{
    int string_ids[9];

    string_ids[0] = 0x3f35;
    string_ids[1] = 0x3f36;
    string_ids[2] = 0x3f38;
    string_ids[3] = 0x3f39;
    string_ids[4] = 0x3f3f;
    string_ids[5] = 0x3f41;
    string_ids[6] = 0x3f43;
    string_ids[7] = 0x3f49;
    string_ids[8] = 0x3f42;

    return string_ids[OtRandomBelow_RealCpp(9)];
}

#pragma optimize("", on)
