// Semantic recovery candidate for OtDestroyTrailTravelViewport @ 0x00406e70.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "trail_runtime.h"

#pragma comment(lib, "gdi32.lib")

#pragma pack(push, 1)
struct PositionedBitmap_00406e70 {
    char reserved_00[0x28];

    ~PositionedBitmap_00406e70();
};

struct PositionedBitmapFree_0040b760_42pct {
    void OtFreePositionedBitmapAlt5_0040b760_42pct();
};

struct TrailTravelViewport_00406e70 {
    char reserved_000[0x0c];
    void* sky_region;
    void* ground_region;
    char reserved_014[0x14];
    PositionedBitmap_00406e70 background_strip;
    char reserved_050[0x1c];
    PositionedBitmap_00406e70 distant_landscape;
    char reserved_094[0x18];
    PositionedBitmap_00406e70 ox_frames[5];
    PositionedBitmap_00406e70 wagon;
    PositionedBitmap_00406e70 wagon_frames[5];
    char reserved_264[0x14];
    PositionedBitmap_00406e70 route_strip;

    ~TrailTravelViewport_00406e70();
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

PositionedBitmap_00406e70::~PositionedBitmap_00406e70()
{
    reinterpret_cast<PositionedBitmapFree_0040b760_42pct*>(this)->
        OtFreePositionedBitmapAlt5_0040b760_42pct();
}

TrailTravelViewport_00406e70::~TrailTravelViewport_00406e70()
{
    if (sky_region != 0) {
        DeleteObject(sky_region);
    }

    DeleteObject(ground_region);
}

#pragma optimize("", on)
