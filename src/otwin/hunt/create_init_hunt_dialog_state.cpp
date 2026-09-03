// Hunt-dialog runtime-state constructor at 0x004122b0.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "hunt_runtime_state.h"
#include "hunt_dialog_state_constructor.h"
#include "../graphics/sprite_blitter_runtime.h"

extern "C" __declspec(dllimport) void* __stdcall LoadCursorA(
    void* instance,
    const char* cursor_name);
extern "C" __declspec(dllimport) void* __stdcall GlobalAlloc(
    unsigned int flags,
    unsigned long bytes);
extern "C" __declspec(dllimport) void* __stdcall GlobalLock(void* handle);
extern "C" __declspec(dllimport) void* __stdcall FindResourceA(
    void* module,
    const void* resource_name,
    const void* resource_type);
extern "C" __declspec(dllimport) void* __stdcall LoadResource(
    void* module,
    void* resource_info);
extern "C" __declspec(dllimport) void* __stdcall LockResource(
    void* resource_data);

#pragma comment(lib, "kernel32.lib")
#pragma comment(lib, "user32.lib")

#pragma pack(push, 1)
struct HuntJourneyState_004122b0_Product {
    char reserved_000[0x9c];
    short bullets_available;
    char reserved_09e[0x9c];
    short hunt_region;
};

struct HuntRouteDescriptor_004122b0_Product {
    char reserved_000[0x1a];
    short spawn_probabilities[0x100];
};
#pragma pack(pop)

extern "C" void* g_resourceModule;
extern "C" HuntJourneyState_004122b0_Product* g_journeyState;
extern "C" HuntRouteDescriptor_004122b0_Product* g_activeRouteDescriptor;

extern "C" void* __fastcall OtInitPositionedBitmap_RealCpp(void* bitmap);
extern "C" int __cdecl OtRandomBelow_RealCpp(int upper_bound);

#pragma optimize("s", off)
#pragma optimize("t", on)

HuntPositionedBitmap_004122b0_Product::
    HuntPositionedBitmap_004122b0_Product()
{
    OtInitPositionedBitmap_RealCpp(this);
}

HuntDialogState_00415380_SetupWip::HuntDialogState_00415380_SetupWip()
{
    int selected_targets[4];
    short target_table[10];
    short* spawn_row;
    int* selected_scan;
    int* selected_write;
    int* selected_read;
    void** resource_cursor;
    int* target_type_cursor;
    int roll;
    int rejected;
    int index;
    unsigned int scene_resource;
    void* resource_info;
    void* resource_data;
    HuntRuntimeState_004122b0_Product* state =
        (HuntRuntimeState_004122b0_Product*)this;

    index = 0;
    resource_cursor = (void**)state->sprite_slots;
    do {
        *resource_cursor = 0;
        ++resource_cursor;
        ++index;
    } while (index < 20);

    state->frame_buffer = 0;
    state->meat_pounds = 0;
    state->bullets_fired = 0;

    if (g_journeyState->bullets_available >= 20) {
        state->bullets_available = 20;
    } else {
        state->bullets_available = g_journeyState->bullets_available;
    }

    state->scene_variant_offset = 0;
    state->scene_base_resource =
        state->OtChooseHuntSceneResourceId_Product();
    state->target_side = OtRandomBelow_RealCpp(2);
    state->last_shot_tick = 0;
    state->last_spawn_tick = 0;
    state->hunt_cursor = LoadCursorA(g_resourceModule, (const char*)0x0960);
    state->default_cursor = LoadCursorA(0, (const char*)0x7f00);

    state->state_memory_handle = GlobalAlloc(0x40, 50000);
    state->scratch_pixels =
        (unsigned char*)GlobalLock(state->state_memory_handle);

    state->sound_resources[0] = 0;
    resource_info = FindResourceA(
        g_resourceModule,
        (const void*)0x09c4,
        (const void*)0x000a);
    resource_data = LoadResource(g_resourceModule, resource_info);
    state->sound_resources[0] = resource_data;
    state->sound_data[0] = (const char*)LockResource(resource_data);

    state->sound_resources[1] = 0;
    resource_info = FindResourceA(
        g_resourceModule,
        (const void*)0x09c5,
        (const void*)0x000a);
    resource_data = LoadResource(g_resourceModule, resource_info);
    state->sound_resources[1] = resource_data;
    state->sound_data[1] = (const char*)LockResource(resource_data);

    state->sound_resources[2] = 0;
    resource_info = FindResourceA(
        g_resourceModule,
        (const void*)0x09c6,
        (const void*)0x000a);
    resource_data = LoadResource(g_resourceModule, resource_info);
    state->sound_resources[2] = resource_data;
    state->sound_data[2] = (const char*)LockResource(resource_data);

    state->sound_resources[3] = 0;
    resource_info = FindResourceA(
        g_resourceModule,
        (const void*)0x09c7,
        (const void*)0x000a);
    resource_data = LoadResource(g_resourceModule, resource_info);
    state->sound_resources[3] = resource_data;
    state->sound_data[3] = (const char*)LockResource(resource_data);

    resource_info = FindResourceA(
        g_resourceModule,
        (const void*)0x09c8,
        (const void*)0x000a);
    resource_data = LoadResource(g_resourceModule, resource_info);
    state->sound_resources[4] = resource_data;
    state->sound_data[4] = (const char*)LockResource(resource_data);

    state->projectile_resource = 0;
    resource_info = FindResourceA(
        g_resourceModule,
        (const void*)0x0898,
        (const void*)0x000a);
    resource_data = LoadResource(g_resourceModule, resource_info);
    state->projectile_resource = resource_data;
    state->projectile_pixels = LockResource(resource_data);

    spawn_row = &g_activeRouteDescriptor->spawn_probabilities[
        g_journeyState->hunt_region * 11];
    target_table[0] = 2;
    target_table[1] = 3;
    target_table[2] = 10;
    target_table[3] = 0;
    target_table[4] = 1;
    selected_scan = selected_targets;
    target_table[5] = 6;
    target_table[6] = 4;
    target_table[7] = 5;
    target_table[8] = 7;
    target_table[9] = 9;
    selected_write = selected_targets;
    selected_scan[0] = -1;
    selected_scan[1] = -1;
    selected_scan[2] = -1;
    selected_scan[3] = -1;

    do {
        roll = OtRandomBelow_RealCpp(10);
        rejected = 0;
        selected_scan = selected_targets;
        do {
            if (*selected_scan == roll) {
                rejected = 1;
            }
            ++selected_scan;
        } while (selected_scan < selected_targets + 4);

        scene_resource = (unsigned int)state->scene_base_resource;
        if (scene_resource >= 0x4b1e &&
            ((scene_resource < 0x4b3c || scene_resource >= 0x4b46) &&
             scene_resource < 0x4b50) &&
            roll == 2) {
            rejected = 1;
        }

        if (!rejected && spawn_row[target_table[roll]] != 0) {
            *selected_write = roll;
            ++selected_write;
        }
    } while (selected_write < selected_targets + 4);

    target_type_cursor = state->target_types;
    resource_cursor = state->target_resource_pairs;
    selected_read = selected_targets;
    do {
        *resource_cursor = 0;
        roll = *selected_read;
        resource_info = FindResourceA(
            g_resourceModule,
            (const void*)(roll + 2000),
            (const void*)0x000a);
        resource_data = LoadResource(g_resourceModule, resource_info);
        *resource_cursor = resource_data;
        resource_cursor[8] = LockResource(resource_data);

        resource_cursor[1] = 0;
        resource_info = FindResourceA(
            g_resourceModule,
            (const void*)(roll + 0x0834),
            (const void*)0x000a);
        resource_data = LoadResource(g_resourceModule, resource_info);
        resource_cursor[1] = resource_data;
        resource_cursor[9] = LockResource(resource_data);

        *target_type_cursor = roll;
        ++target_type_cursor;
        ++selected_read;
        resource_cursor += 2;
    } while (selected_read < selected_targets + 4);

    index = 0;
    do {
        state->sprite_slots[index] = (HuntSprite_004122b0_Product*)
            new SpriteBlitter_00410660_Product;
        ++index;
    } while (index < 20);
}

#pragma optimize("", on)
