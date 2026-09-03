// Trail-game dialog owned-resource teardown recovered from Oregon32.exe.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This source must be compiled with 32-bit MSVC."
#endif

#include "../river/river_crossing_state_runtime.h"

extern "C" __declspec(dllimport) int __stdcall IsBadCodePtr(void* procedure);
void __cdecl operator delete(void* block);

#pragma pack(push, 1)
struct ActiveTextCommitState_0040fdb0 {
    void OtCommitActiveEditTextToGlobal_0040fdb0_RealCpp();
};

struct PositionedBitmapOwner_00405d90 {
    void OtDestroyOwnedPositionedBitmap_RealCpp();
};

struct TrailTravelViewport_00406e70 {
    ~TrailTravelViewport_00406e70();
};

struct GraphicsResourceOwner_00406240 {
    void OtDestroyGraphicsResourceOwnerDirectCalls_00406240_RealCpp();
};

struct TrailGameDialogOwnedResources_0042a6f0 {
    void* callback_a;
    void* callback_b;
    char reserved_008[0x0780];
    PositionedBitmapOwner_00405d90* overlay_bitmap_owner;
    GraphicsResourceOwner_00406240* graphics_owner;
    char reserved_790[0x027c];
    ActiveTextCommitState_0040fdb0* active_text;
    TrailTravelViewport_00406e70* travel_viewport;
    RiverCrossingState_004285a0_ProductWip* river_crossing;

    void OtDestroyTrailGameDialogOwnedResources_RealCpp();
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

void TrailGameDialogOwnedResources_0042a6f0::
    OtDestroyTrailGameDialogOwnedResources_RealCpp()
{
    register TrailGameDialogOwnedResources_0042a6f0* state = this;

    IsBadCodePtr(state->callback_a);
    IsBadCodePtr(state->callback_b);

    register RiverCrossingState_004285a0_ProductWip* river_crossing =
        state->river_crossing;
    if (river_crossing != 0) {
        river_crossing->OtDestroyRiverCrossingState_Product_00428bf0();
        ::operator delete(river_crossing);
    }

    register ActiveTextCommitState_0040fdb0* active_text = state->active_text;
    if (active_text != 0) {
        active_text->OtCommitActiveEditTextToGlobal_0040fdb0_RealCpp();
        ::operator delete(active_text);
    }

    register PositionedBitmapOwner_00405d90* overlay_bitmap_owner =
        state->overlay_bitmap_owner;
    if (overlay_bitmap_owner != 0) {
        overlay_bitmap_owner->OtDestroyOwnedPositionedBitmap_RealCpp();
        ::operator delete(overlay_bitmap_owner);
    }

    register TrailTravelViewport_00406e70* travel_viewport =
        state->travel_viewport;
    if (travel_viewport != 0) {
        travel_viewport->~TrailTravelViewport_00406e70();
        ::operator delete(travel_viewport);
    }

    register GraphicsResourceOwner_00406240* graphics_owner =
        state->graphics_owner;
    if (graphics_owner != 0) {
        graphics_owner
            ->OtDestroyGraphicsResourceOwnerDirectCalls_00406240_RealCpp();
        ::operator delete(graphics_owner);
    }
}

#pragma optimize("", on)
