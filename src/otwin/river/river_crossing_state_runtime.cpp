// Product semantic WIP for the river-crossing scene state @ 0x004285a0.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

#include "../graphics/raw_indexed_bitmap_runtime.h"
#include "../graphics/sprite_blitter_runtime.h"
#include "river_crossing_state_runtime.h"

extern "C" __declspec(dllimport) void* __stdcall GlobalAlloc(
    unsigned int flags,
    unsigned long bytes);
extern "C" __declspec(dllimport) void* __stdcall GlobalLock(void* handle);
extern "C" __declspec(dllimport) unsigned int __stdcall GetPaletteEntries(
    void* palette,
    unsigned int start_index,
    unsigned int entry_count,
    void* entries);
extern "C" __declspec(dllimport) void* __stdcall FindResourceA(
    void* module,
    const void* name,
    const void* type);
extern "C" __declspec(dllimport) void* __stdcall LoadResource(
    void* module,
    void* resource_info);
extern "C" __declspec(dllimport) void* __stdcall LockResource(
    void* resource_data);
extern "C" __declspec(dllimport) int __stdcall LoadStringA(
    void* module,
    unsigned int id,
    char* buffer,
    int max_count);
extern "C" __declspec(dllimport) void* __stdcall CreateWindowExA(
    unsigned long extended_style,
    const char* class_name,
    const char* window_name,
    unsigned long style,
    int x,
    int y,
    int width,
    int height,
    void* parent,
    void* menu,
    void* instance,
    void* parameter);
extern "C" void* __cdecl memset(
    void* destination,
    int value,
    unsigned int count);
#pragma intrinsic(memset)

#pragma comment(lib, "kernel32.lib")
#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "user32.lib")

extern "C" void* g_applicationModule_00405a40_20260603;
extern "C" void* g_resourceModule;
extern "C" void* g_gamePalette;
extern "C" void* g_activeRouteDescriptor;
extern "C" int DAT_004390e8;
extern "C" int g_cdMediaMode_00439108;

extern "C" void __cdecl OtOpenWaveAudioFile_0000d110_RealCpp(
    void* owner,
    char* logical_name);
extern "C" void __cdecl OtPlayWaveAudioDirectImport_0040d3e0_RealCpp();

#pragma pack(push, 1)
struct RouteDescriptor_004285a0_ProductWip {
    unsigned short route_id;
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

int RiverCrossingState_004285a0_ProductWip::
OtInitRiverSpriteLayerFromResource_Product(
    void* module,
    const void* resource_name,
    SpriteBlitter_00410660_Product* sprite,
    void** resource_handle,
    void* reserved_bits,
    int width,
    int height,
    int requested_x,
    int requested_y,
    int source_columns,
    int mode)
{
    void* resource_info =
        FindResourceA(module, resource_name, (const void*)10);
    void* resource_data = LoadResource(module, resource_info);
    unsigned char* source_pixels;
    *resource_handle = resource_data;
    if (resource_data == 0) {
        return 0;
    }

    source_pixels = static_cast<unsigned char*>(LockResource(resource_data));
    sprite->draw_bottom = 0;
    sprite->source_height = (unsigned short)height;
    sprite->source_pixels = source_pixels;
    sprite->source_frame = 0;
    sprite->source_width = (unsigned short)width;
    sprite->mode_or_variant = (short)mode;
    sprite->source_columns_per_row = (unsigned short)source_columns;
    sprite->requested_x = (short)requested_x;
    sprite->requested_y = (short)requested_y;
    sprite->resource_handle_or_state = 1;
    *reinterpret_cast<unsigned short*>(&sprite->transparent_index) = 0x17;
    sprite->horizontal_flip = 0;
    sprite->OtResetSpriteBlitterBitmapInfo_Product_004107b0();
    return 1;
}

#pragma code_seg(".otsem")
#pragma optimize("s", off)
#pragma optimize("t", on)

RiverCrossingState_004285a0_ProductWip::
RiverCrossingState_004285a0_ProductWip(
    void* owner_window,
    short choice,
    short crossing_mode_value)
{
    RiverCrossingState_004285a0_ProductWip* state = this;
    int uses_crossing_effects;
    const void* wagon_resource;
    int* primary_frame_count;
    char caption[52];

    state->scratch_handle = 0;
    state->scratch_bits = 0;
    state->resource_handle_4c = 0;
    state->resource_handle_54 = 0;
    state->resource_handle_5c = 0;
    state->resource_handle_64 = 0;
    state->resource_handle_6c = 0;
    state->resource_handle_70 = 0;
    state->resource_handle_74 = 0;
    state->resource_handle_78 = 0;
    state->base_bitmap = 0;
    memset(state->sprite_slots, 0, sizeof(state->sprite_slots));

    state->crash_sound_resource = 0;

    GetPaletteEntries(g_gamePalette, 0x71, 8, state->palette_entries);
    state->crossing_mode = crossing_mode_value;
    if (choice == 0x67) {
        if (crossing_mode_value < 4) {
            state->crossing_choice = 100;
        } else {
            state->crossing_choice = 101;
        }
    } else {
        state->crossing_choice = choice;
    }

    if (crossing_mode_value == 2 || crossing_mode_value == 3 ||
        crossing_mode_value == 5 || crossing_mode_value == 7) {
        uses_crossing_effects = 1;
    } else {
        uses_crossing_effects = 0;
    }

    state->scratch_handle = GlobalAlloc(0x40, 55000);
    state->scratch_bits = GlobalLock(state->scratch_handle);
    state->base_bitmap = ::new RawIndexedBitmap_00410490_Product(
        g_applicationModule_00405a40_20260603,
        300,
        0xb1,
        (const void*)0x4e36);

    state->sprite_slots[kNearBankSpriteSlot] =
        ::new SpriteBlitter_00410660_Product;
    state->OtInitRiverSpriteLayerFromResource_Product(
        g_applicationModule_00405a40_20260603,
        (const void*)0x4e37,
        state->sprite_slots[kNearBankSpriteSlot],
        &state->resource_handle_4c,
        state->resource_bits_50,
        0x6e,
        0x4a,
        0xbe,
        0x67,
        1,
        100);
    state->sprite_slots[kNearBankSpriteSlot]->active_state = 1;

    state->sprite_slots[kFarBankSpriteSlot] =
        ::new SpriteBlitter_00410660_Product;
    state->OtInitRiverSpriteLayerFromResource_Product(
        g_applicationModule_00405a40_20260603,
        (const void*)0x4e38,
        state->sprite_slots[kFarBankSpriteSlot],
        &state->resource_handle_54,
        state->resource_bits_58,
        0x6e,
        0x4a,
        -0xe6,
        -0x72,
        1,
        101);
    if (uses_crossing_effects != 0) {
        state->sprite_slots[kFarBankSpriteSlot]->active_state = 0;
    } else {
        state->sprite_slots[kFarBankSpriteSlot]->active_state = 1;
    }

    if (state->crossing_choice == 100) {
        primary_frame_count = &state->primary_frame_count;
        wagon_resource = (const void*)0x4e2f;
        state->secondary_frame_count = 3;
        *primary_frame_count = 4;
    } else if (state->crossing_choice == 0x66) {
        primary_frame_count = &state->primary_frame_count;
        state->secondary_frame_count = 2;
        *primary_frame_count = 1;
        wagon_resource = (const void*)0x4e2c;
    } else {
        primary_frame_count = &state->primary_frame_count;
        state->secondary_frame_count = 2;
        *primary_frame_count = 1;
        wagon_resource = (const void*)0x4e2a;
    }

    SpriteBlitter_00410660_Product* wagon_sprite =
        ::new SpriteBlitter_00410660_Product;
    state->sprite_slots[kWagonSpriteSlot] = wagon_sprite;
    state->OtInitRiverSpriteLayerFromResource_Product(
        g_applicationModule_00405a40_20260603,
        wagon_resource,
        wagon_sprite,
        &state->resource_handle_5c,
        state->resource_bits_60,
        0x6d,
        0x45,
        0x88,
        0x47,
        *primary_frame_count,
        0);
    wagon_sprite->active_state = 1;

    if (uses_crossing_effects != 0) {
        if (state->crossing_mode == 2 || state->crossing_mode == 3) {
            state->secondary_frame_count = 3;
            wagon_resource = (const void*)0x4e30;
        } else if (state->crossing_mode == 7) {
            state->secondary_frame_count = 2;
            wagon_resource = (const void*)0x4e2d;
        } else {
            state->secondary_frame_count = 1;
            wagon_resource = (const void*)0x4e2b;
        }

        SpriteBlitter_00410660_Product* crossing_sprite =
            ::new SpriteBlitter_00410660_Product;
        state->sprite_slots[kCrossingSpriteSlot] = crossing_sprite;
        state->OtInitRiverSpriteLayerFromResource_Product(
            g_applicationModule_00405a40_20260603,
            wagon_resource,
            crossing_sprite,
            &state->resource_handle_64,
            state->resource_bits_68,
            0x6d,
            0x45,
            0x88,
            0x47,
            state->secondary_frame_count,
            0);
        crossing_sprite->active_state = 0;

        state->sprite_slots[kEffectSpriteASlot] =
            ::new SpriteBlitter_00410660_Product;
        state->OtInitRiverSpriteLayerFromResource_Product(
            g_applicationModule_00405a40_20260603,
            (const void*)0x4e32,
            state->sprite_slots[kEffectSpriteASlot],
            &state->resource_handle_6c,
            state->resource_bits_7c,
            0x35,
            0x18,
            0,
            0,
            1,
            0);
        state->sprite_slots[kEffectSpriteASlot]->active_state = 0;

        state->sprite_slots[kEffectSpriteBSlot] =
            ::new SpriteBlitter_00410660_Product;
        state->OtInitRiverSpriteLayerFromResource_Product(
            g_applicationModule_00405a40_20260603,
            (const void*)0x4e33,
            state->sprite_slots[kEffectSpriteBSlot],
            &state->resource_handle_70,
            state->resource_bits_80,
            0x25,
            0x13,
            0,
            0,
            1,
            0);
        state->sprite_slots[kEffectSpriteBSlot]->active_state = 0;

        state->sprite_slots[kEffectSpriteCSlot] =
            ::new SpriteBlitter_00410660_Product;
        state->OtInitRiverSpriteLayerFromResource_Product(
            g_applicationModule_00405a40_20260603,
            (const void*)0x4e34,
            state->sprite_slots[kEffectSpriteCSlot],
            &state->resource_handle_74,
            state->resource_bits_84,
            0x20,
            0x1b,
            0,
            0,
            1,
            0);
        state->sprite_slots[kEffectSpriteCSlot]->active_state = 0;

        state->sprite_slots[kEffectSpriteDSlot] =
            ::new SpriteBlitter_00410660_Product;
        state->OtInitRiverSpriteLayerFromResource_Product(
            g_applicationModule_00405a40_20260603,
            (const void*)0x4e35,
            state->sprite_slots[kEffectSpriteDSlot],
            &state->resource_handle_78,
            state->resource_bits_88,
            0x12,
            0x0e,
            0,
            0,
            1,
            0);
        state->sprite_slots[kEffectSpriteDSlot]->active_state = 0;
    }

    memset(caption, 0, 50);
    LoadStringA(
        g_resourceModule,
        (static_cast<RouteDescriptor_004285a0_ProductWip*>(
             g_activeRouteDescriptor)->route_id +
         0x0d) *
            0x10,
        caption,
        0x31);
    state->caption_window = CreateWindowExA(
        0,
        "STATIC",
        caption,
        0x40000001ul,
        0x3c,
        0xb3,
        299,
        0x15,
        owner_window,
        (void*)-1,
        g_applicationModule_00405a40_20260603,
        0);

    if (DAT_004390e8 != 0 && g_cdMediaMode_00439108 != 0) {
        static char crossing_wave[] = "crssingw.wav";
        OtOpenWaveAudioFile_0000d110_RealCpp(
            owner_window,
            crossing_wave);
        OtPlayWaveAudioDirectImport_0040d3e0_RealCpp();
    }
}

extern "C" __declspec(dllimport) int __stdcall GlobalUnlock(void* handle);
extern "C" __declspec(dllimport) void* __stdcall GlobalFree(void* handle);
extern "C" __declspec(dllimport) int __stdcall FreeResource(void* resource);
extern "C" __declspec(dllimport) int __stdcall DestroyWindow(void* window);

extern "C" void __cdecl OtCloseWaveAudioDevice_0040d0a0_RealCpp();
extern "C" void __fastcall OtFreeRawIndexedBitmap_RealCpp(void* bitmap);
extern "C" void __fastcall OtFreeSpriteBlitter_RealCpp(void* sprite);

void __cdecl operator delete(void* block);

void RiverCrossingState_004285a0_ProductWip::
OtDestroyRiverCrossingState_Product_00428bf0()
{
    RiverCrossingState_004285a0_ProductWip* state = this;
    void* owned_object;

    if (g_cdMediaMode_00439108 != 0) {
        OtCloseWaveAudioDevice_0040d0a0_RealCpp();
    }

    if (state->crash_sound_resource != 0) {
        FreeResource(state->crash_sound_resource);
    }

    if (state->scratch_handle != 0) {
        GlobalUnlock(state->scratch_handle);
        GlobalFree(state->scratch_handle);
    }

    owned_object = state->base_bitmap;
    if (owned_object != 0) {
        OtFreeRawIndexedBitmap_RealCpp(owned_object);
        operator delete(owned_object);
    }

    if (state->resource_handle_4c != 0) {
        FreeResource(state->resource_handle_4c);
    }

    owned_object = state->sprite_slots[kNearBankSpriteSlot];
    if (owned_object != 0) {
        OtFreeSpriteBlitter_RealCpp(owned_object);
        operator delete(owned_object);
    }

    if (state->resource_handle_54 != 0) {
        FreeResource(state->resource_handle_54);
    }

    owned_object = state->sprite_slots[kFarBankSpriteSlot];
    if (owned_object != 0) {
        OtFreeSpriteBlitter_RealCpp(owned_object);
        operator delete(owned_object);
    }

    if (state->resource_handle_5c != 0) {
        FreeResource(state->resource_handle_5c);
    }

    owned_object = state->sprite_slots[kWagonSpriteSlot];
    if (owned_object != 0) {
        OtFreeSpriteBlitter_RealCpp(owned_object);
        operator delete(owned_object);
    }

    if (state->resource_handle_64 != 0) {
        FreeResource(state->resource_handle_64);
    }

    owned_object = state->sprite_slots[kCrossingSpriteSlot];
    if (owned_object != 0) {
        OtFreeSpriteBlitter_RealCpp(owned_object);
        operator delete(owned_object);
    }

    if (state->resource_handle_6c != 0) {
        FreeResource(state->resource_handle_6c);
        FreeResource(state->resource_handle_70);
        FreeResource(state->resource_handle_74);
        FreeResource(state->resource_handle_78);
    }

    owned_object = state->sprite_slots[kEffectSpriteASlot];
    if (owned_object != 0) {
        OtFreeSpriteBlitter_RealCpp(owned_object);
        operator delete(owned_object);

        owned_object = state->sprite_slots[kEffectSpriteBSlot];
        if (owned_object != 0) {
            OtFreeSpriteBlitter_RealCpp(owned_object);
            operator delete(owned_object);
        }

        owned_object = state->sprite_slots[kEffectSpriteCSlot];
        if (owned_object != 0) {
            OtFreeSpriteBlitter_RealCpp(owned_object);
            operator delete(owned_object);
        }

        owned_object = state->sprite_slots[kEffectSpriteDSlot];
        if (owned_object != 0) {
            OtFreeSpriteBlitter_RealCpp(owned_object);
            operator delete(owned_object);
        }
    }

    DestroyWindow(state->caption_window);
}

#pragma optimize("", on)
#pragma code_seg()
