// Hunt-dialog state teardown at 0x00412730.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "hunt_runtime_state.h"

extern "C" __declspec(dllimport) int __stdcall FreeResource(void* resource);
extern "C" __declspec(dllimport) int __stdcall GlobalUnlock(void* handle);
extern "C" __declspec(dllimport) void* __stdcall GlobalFree(void* handle);
extern "C" __declspec(dllimport) int __stdcall DestroyCursor(void* cursor);
extern "C" __declspec(dllimport) int __stdcall sndPlaySoundA(
    const char* sound,
    unsigned int flags);

extern "C" void __fastcall OtFreePositionedBitmapDependencyCall_00406240(
    void* bitmap);
extern "C" void __fastcall OtFreeSpriteBlitter_RealCpp(void* sprite);
extern "C" void __fastcall OtFreeRawIndexedBitmap_RealCpp(void* bitmap);
void __cdecl operator delete(void* block);

#pragma comment(lib, "kernel32.lib")
#pragma comment(lib, "user32.lib")
#pragma comment(lib, "winmm.lib")

#pragma optimize("s", off)
#pragma optimize("t", on)

HuntPositionedBitmap_004122b0_Product::~HuntPositionedBitmap_004122b0_Product()
{
    OtFreePositionedBitmapDependencyCall_00406240(this);
}

HuntRuntimeState_004122b0_Product::~HuntRuntimeState_004122b0_Product()
{
    register int index;
    register HuntSprite_004122b0_Product* sprite;
    register HuntSprite_004122b0_Product** sprite_slot;

    sndPlaySoundA(0, 0);

    sprite_slot = sprite_slots;
    for (index = 0; index < 20; ++index) {
        sprite = *sprite_slot;
        if (sprite != 0) {
            OtFreeSpriteBlitter_RealCpp(sprite);
            operator delete(sprite);
        }
        ++sprite_slot;
    }

    {
        register int remaining_pairs;
        register void** resource_pair;
        register int (__stdcall *free_resource)(void*);

        resource_pair = target_resource_pairs;
        remaining_pairs = 4;
        free_resource = FreeResource;

        do {
            free_resource(resource_pair[0]);
            free_resource(resource_pair[1]);
            resource_pair += 2;
            --remaining_pairs;
        } while (remaining_pairs != 0);

        free_resource(sound_resources[0]);
        free_resource(sound_resources[1]);
        free_resource(sound_resources[2]);
        free_resource(sound_resources[3]);
        free_resource(sound_resources[4]);
        free_resource(projectile_resource);
    }

    GlobalUnlock(state_memory_handle);
    GlobalFree(state_memory_handle);
    DestroyCursor(hunt_cursor);

    {
        HuntRawIndexedBitmap_004122b0_Product* bitmap = frame_buffer;
        if (bitmap != 0) {
            OtFreeRawIndexedBitmap_RealCpp(bitmap);
            operator delete(bitmap);
        }
    }
}

#pragma optimize("", on)
