// Product-semantic constructors owned by the main trail-game dialog.
//
// The original dialog initializer allocates four objects whose constructor
// entry points live elsewhere in Oregon32.exe.  The journal and landmark
// objects already have recovered Product initializers; the map composite and
// travel viewport are recovered here from their resource-backed constructors.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

#include "../graphics/positioned_bitmap_descriptor_state.h"

typedef void* HGLOBAL_0042c2e0;
typedef void* HMODULE_0042c2e0;
typedef void* HWND_0042c2e0;
typedef void* HRSRC_0042c2e0;
typedef void* HRGN_0042c2e0;
typedef void* HPEN_0042c2e0;
typedef const char* LPCSTR_0042c2e0;

extern "C" __declspec(dllimport) HRSRC_0042c2e0 __stdcall FindResourceA(
    HMODULE_0042c2e0 module,
    LPCSTR_0042c2e0 resource_name,
    LPCSTR_0042c2e0 resource_type);
extern "C" __declspec(dllimport) HGLOBAL_0042c2e0 __stdcall LoadResource(
    HMODULE_0042c2e0 module,
    HRSRC_0042c2e0 resource_info);
extern "C" __declspec(dllimport) void* __stdcall LockResource(
    HGLOBAL_0042c2e0 resource);
extern "C" __declspec(dllimport) int __stdcall FreeResource(
    HGLOBAL_0042c2e0 resource);
extern "C" __declspec(dllimport) void __stdcall PostQuitMessage(
    int exit_code);
extern "C" __declspec(dllimport) int __stdcall MessageBoxA(
    HWND_0042c2e0 window,
    LPCSTR_0042c2e0 text,
    LPCSTR_0042c2e0 caption,
    unsigned int type);
extern "C" __declspec(dllimport) HRGN_0042c2e0 __stdcall CreateRectRgn(
    int left,
    int top,
    int right,
    int bottom);
extern "C" __declspec(dllimport) HPEN_0042c2e0 __stdcall CreatePen(
    int style,
    int width,
    unsigned long color);

#pragma comment(lib, "kernel32.lib")
#pragma comment(lib, "user32.lib")
#pragma comment(lib, "gdi32.lib")

extern "C" void* g_resourceModule;

#pragma pack(push, 1)

struct TrailJournalWindow_0040fc00_20260605 {
    char reserved_00[0x20];

    TrailJournalWindow_0040fc00_20260605(
        HMODULE_0042c2e0 module,
        HWND_0042c2e0 parent,
        LPCSTR_0042c2e0 descriptor_id);
    TrailJournalWindow_0040fc00_20260605*
        OtInitTrailJournalWindow_20260605_RealCpp(
            HMODULE_0042c2e0 module,
            HWND_0042c2e0 parent,
            LPCSTR_0042c2e0 descriptor_id);
};

struct LabeledBitmapDisplay_00405bd0_20260603 {
    char reserved_00[0x30];

    LabeledBitmapDisplay_00405bd0_20260603(
        HMODULE_0042c2e0 module,
        HWND_0042c2e0 parent,
        LPCSTR_0042c2e0 descriptor_id);
    LabeledBitmapDisplay_00405bd0_20260603*
        OtInitLandmarkDisplay_00405bd0_RealCpp(
            HMODULE_0042c2e0 module,
            HWND_0042c2e0 parent,
            LPCSTR_0042c2e0 descriptor_id);
};

struct TrailMapCompositeDescriptor_00406010 {
    short left;
    short top;
    short width;
    short height;
    unsigned short bitmap_resource_id;
    unsigned short polyline_resource_ids[4];
};

struct TrailMapComposite_00406010_20260603 {
    PositionedBitmapDescriptorState_0040ba40* base_bitmap;
    int reserved_04[3];
    int selected_polyline_variant;
    int last_progress_segment;
    HGLOBAL_0042c2e0 polyline_handles[4];
    void* active_points;
    void* auxiliary_points[4];
    HPEN_0042c2e0 progress_pen;
    int left;
    int top;
    int right;
    int bottom;

    TrailMapComposite_00406010_20260603(
        HMODULE_0042c2e0 module,
        LPCSTR_0042c2e0 descriptor_id);
};

struct TrailMapComposite_00406290 {
    void OtSelectTrailMapPolylineVariantNoAsm2_00406290_RealCpp();
};

struct TrailTravelViewportDescriptor_004069c0 {
    short left;
    short top;
    short width;
    short height;
    short sky_top;
    short sky_height;
    short ground_top;
    short ground_height;
    short background_top;
    short background_width;
    short background_height;
    short background_limit;
    unsigned short background_bitmap_id;
    short landscape_top;
    short landscape_width;
    short landscape_height;
    short landscape_limit;
    unsigned short landscape_bitmap_id;
    short frame_left;
    short frame_top;
    short frame_width;
    short frame_height;
    unsigned short ox_bitmap_ids[5];
    short route_strip_descriptor_id;
};

struct TrailTravelViewportInitializer_004069c0 {
    char reserved_000[0x0c];
    HRGN_0042c2e0 sky_region;
    HRGN_0042c2e0 ground_region;
    char reserved_014[0x0c];
    int background_width;
    char reserved_024[4];
    PositionedBitmapDescriptorState_0040ba40 background_strip;
    char reserved_050[4];
    int background_limit;
    char reserved_058[8];
    int landscape_top;
    int landscape_width;
    int landscape_height;
    PositionedBitmapDescriptorState_0040ba40 distant_landscape;
    char reserved_094[4];
    int landscape_limit;
    int frame_left;
    int frame_top;
    int frame_width;
    int frame_height;
    PositionedBitmapDescriptorState_0040ba40 ox_frames[5];
    PositionedBitmapDescriptorState_0040ba40 wagon;
    PositionedBitmapDescriptorState_0040ba40 wagon_frames[5];
    int current_wagon_frame;
    int route_segment_span;
    char reserved_26c[8];
    int route_strip_offset;
    PositionedBitmapDescriptorState_0040ba40 route_strip;
    int left;
    int top;
    int right;
    int bottom;

    TrailTravelViewportInitializer_004069c0(
        HMODULE_0042c2e0 module,
        HWND_0042c2e0 parent,
        LPCSTR_0042c2e0 descriptor_id);
};

struct JourneyState_004069c0 {
    char reserved_000[0x8a];
    short current_segment_distance;
};

#pragma pack(pop)

typedef char OtTrailMapCompositeSizeCheck[
    sizeof(TrailMapComposite_00406010_20260603) == 0x50 ? 1 : -1];
typedef char OtTrailViewportSizeCheck[
    sizeof(TrailTravelViewportInitializer_004069c0) == 0x2b0 ? 1 : -1];
typedef char OtTrailViewportOxOffsetCheck[
    (unsigned int)&(((TrailTravelViewportInitializer_004069c0*)0)->ox_frames) ==
            0x0ac
        ? 1
        : -1];
typedef char OtTrailViewportRouteOffsetCheck[
    (unsigned int)&(((TrailTravelViewportInitializer_004069c0*)0)->route_strip) ==
            0x278
        ? 1
        : -1];

extern "C" JourneyState_004069c0* g_journeyState;

static const char g_travelViewportLoadErrorText_004069c0[] =
    "Can't load resource";
static const char g_travelViewportLoadErrorCaption_004069c0[] =
    "TrottyOxClass constructor";

static HGLOBAL_0042c2e0 OtLoadTrailPolylineResource_00406010(
    HMODULE_0042c2e0 module,
    short resource_id,
    void** locked_points)
{
    HRSRC_0042c2e0 resource_info = FindResourceA(
        module,
        (LPCSTR_0042c2e0)(unsigned int)(unsigned short)resource_id,
        (LPCSTR_0042c2e0)0x07d9);
    HGLOBAL_0042c2e0 resource_handle =
        LoadResource(module, resource_info);
    if (resource_handle == 0) {
        *locked_points = 0;
    } else {
        *locked_points = LockResource(resource_handle);
    }
    return resource_handle;
}

#pragma optimize("s", off)
#pragma optimize("t", on)

TrailJournalWindow_0040fc00_20260605::
    TrailJournalWindow_0040fc00_20260605(
        HMODULE_0042c2e0 module,
        HWND_0042c2e0 parent,
        LPCSTR_0042c2e0 descriptor_id)
{
    OtInitTrailJournalWindow_20260605_RealCpp(
        module,
        parent,
        descriptor_id);
}

LabeledBitmapDisplay_00405bd0_20260603::
    LabeledBitmapDisplay_00405bd0_20260603(
        HMODULE_0042c2e0 module,
        HWND_0042c2e0 parent,
        LPCSTR_0042c2e0 descriptor_id)
{
    OtInitLandmarkDisplay_00405bd0_RealCpp(
        module,
        parent,
        descriptor_id);
}

TrailMapComposite_00406010_20260603::
    TrailMapComposite_00406010_20260603(
        HMODULE_0042c2e0 module,
        LPCSTR_0042c2e0 descriptor_id)
{
    int load_failed = 0;
    HGLOBAL_0042c2e0 descriptor_handle = 0;

    if (descriptor_id == 0) {
        load_failed = 1;
    } else {
        HRSRC_0042c2e0 descriptor_resource = FindResourceA(
            module,
            descriptor_id,
            (LPCSTR_0042c2e0)0x07d6);
        descriptor_handle = LoadResource(module, descriptor_resource);
        if (descriptor_handle == 0) {
            load_failed = 1;
        }
    }

    if (load_failed != 0) {
        PostQuitMessage(0);
        return;
    }

    TrailMapCompositeDescriptor_00406010* descriptor =
        (TrailMapCompositeDescriptor_00406010*)LockResource(
            descriptor_handle);
    left = descriptor->left;
    top = descriptor->top;
    right = descriptor->left + descriptor->width;
    bottom = descriptor->top + descriptor->height;

    if (descriptor->bitmap_resource_id != 0) {
        PositionedBitmapDescriptorState_0040ba40* bitmap =
            new PositionedBitmapDescriptorState_0040ba40;
        base_bitmap = bitmap;
        bitmap->OtLoadIndexedBitmapFromResource_0040b870_ProductWip(
            module,
            descriptor->bitmap_resource_id,
            descriptor->left,
            descriptor->top,
            descriptor->width,
            descriptor->height);
    }

    int polyline_index = 0;
    do {
        polyline_handles[polyline_index] =
            OtLoadTrailPolylineResource_00406010(
                module,
                descriptor->polyline_resource_ids[polyline_index],
                &auxiliary_points[polyline_index]);
        ++polyline_index;
    } while (polyline_index < 4);

    selected_polyline_variant = 1;
    last_progress_segment = 0;
    reinterpret_cast<TrailMapComposite_00406290*>(this)->
        OtSelectTrailMapPolylineVariantNoAsm2_00406290_RealCpp();
    progress_pen = CreatePen(0, 2, 0x000000ff);
    FreeResource(descriptor_handle);
}

TrailTravelViewportInitializer_004069c0::
    TrailTravelViewportInitializer_004069c0(
        HMODULE_0042c2e0 module,
        HWND_0042c2e0 parent,
        LPCSTR_0042c2e0 descriptor_id)
{
    int load_failed = 0;
    HGLOBAL_0042c2e0 descriptor_handle = 0;
    if (descriptor_id == 0) {
        load_failed = 1;
    } else {
        HRSRC_0042c2e0 descriptor_resource = FindResourceA(
            module,
            descriptor_id,
            (LPCSTR_0042c2e0)0x07d7);
        descriptor_handle = LoadResource(module, descriptor_resource);
        if (descriptor_handle == 0) {
            load_failed = 1;
        }
    }

    if (load_failed != 0) {
        MessageBoxA(
            parent,
            g_travelViewportLoadErrorText_004069c0,
            g_travelViewportLoadErrorCaption_004069c0,
            0);
        PostQuitMessage(0);
        return;
    }

    TrailTravelViewportDescriptor_004069c0* descriptor =
        (TrailTravelViewportDescriptor_004069c0*)LockResource(
            descriptor_handle);

    left = descriptor->left;
    top = descriptor->top;
    right = descriptor->left + descriptor->width;
    bottom = descriptor->top + descriptor->height;

    sky_region = CreateRectRgn(
        left,
        descriptor->sky_top,
        right,
        descriptor->sky_top + descriptor->sky_height);
    ground_region = CreateRectRgn(
        left,
        descriptor->ground_top,
        right,
        descriptor->ground_top + descriptor->ground_height);

    if (descriptor->background_bitmap_id != 0) {
        background_width = descriptor->background_width;
        background_limit = descriptor->background_limit;
        background_strip.OtLoadIndexedBitmapFromResource_0040b870_ProductWip(
            module,
            descriptor->background_bitmap_id,
            (short)left,
            descriptor->background_top,
            descriptor->background_width,
            descriptor->background_height);
    }
    background_strip.width = descriptor->width;

    if (descriptor->landscape_bitmap_id != 0) {
        landscape_width = descriptor->landscape_width;
        landscape_limit = descriptor->landscape_limit;
        landscape_top = descriptor->landscape_top;
        landscape_height = descriptor->landscape_height;
        distant_landscape.
            OtLoadIndexedBitmapFromResource_0040b870_ProductWip(
                module,
                descriptor->landscape_bitmap_id,
                (short)left,
                descriptor->landscape_top,
                descriptor->landscape_width,
                descriptor->landscape_height);
        distant_landscape.width = descriptor->width;
    }

    frame_left = descriptor->frame_left;
    frame_top = descriptor->frame_top;
    frame_width = descriptor->frame_width;
    frame_height = descriptor->frame_height;

    int ox_index = 0;
    do {
        ox_frames[ox_index].
            OtLoadIndexedBitmapFromResource_0040b870_ProductWip(
                module,
                descriptor->ox_bitmap_ids[ox_index],
                (short)frame_left,
                (short)frame_top,
                (short)frame_width,
                (short)frame_height);
        ++ox_index;
    } while (ox_index < 5);

    current_wagon_frame = 0;
    wagon.OtLoadIndexedBitmapFromResource_0040b870_ProductWip(
        module, (unsigned short)0x3b12,
        (short)frame_left, (short)frame_top,
        (short)frame_width, (short)frame_height);
    wagon_frames[0].OtLoadIndexedBitmapFromResource_0040b870_ProductWip(
        module, (unsigned short)0x3b15,
        (short)frame_left, (short)frame_top,
        (short)frame_width, (short)frame_height);
    wagon_frames[1].OtLoadIndexedBitmapFromResource_0040b870_ProductWip(
        module, (unsigned short)0x3b13,
        (short)frame_left, (short)frame_top,
        (short)frame_width, (short)frame_height);
    wagon_frames[2].OtLoadIndexedBitmapFromResource_0040b870_ProductWip(
        module, (unsigned short)0x3b14,
        (short)frame_left, (short)frame_top,
        (short)frame_width, (short)frame_height);
    wagon_frames[3].OtLoadIndexedBitmapFromResource_0040b870_ProductWip(
        module, (unsigned short)0x3b17,
        (short)frame_left, (short)frame_top,
        (short)frame_width, (short)frame_height);
    wagon_frames[4].OtLoadIndexedBitmapFromResource_0040b870_ProductWip(
        module, (unsigned short)0x3b16,
        (short)frame_left, (short)frame_top,
        (short)frame_width, (short)frame_height);

    if (descriptor->route_strip_descriptor_id != 0) {
        route_strip.OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_resourceModule,
            descriptor->route_strip_descriptor_id);

        int segment_span = ox_frames[0].left_int;
        segment_span -= ox_frames[0].right;
        segment_span -= left;
        segment_span += right - 2;
        segment_span /= 0x41;
        route_segment_span = segment_span;
        int traveled_span =
            g_journeyState->current_segment_distance * segment_span;
        int strip_origin = frame_left - 2;
        if (traveled_span > 0) {
            route_strip_offset =
                (strip_origin - route_strip.width) - traveled_span;
        } else {
            route_strip_offset = strip_origin - route_strip.width;
        }
    }

    FreeResource(descriptor_handle);
}

#pragma optimize("", on)
