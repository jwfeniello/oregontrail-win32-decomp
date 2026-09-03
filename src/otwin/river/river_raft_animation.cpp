// Product semantic WIP for rafting animation timing and blits.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

extern "C" __declspec(dllimport) unsigned int __stdcall timeGetTime();
extern "C" __declspec(dllimport) int __stdcall StretchDIBits(
    void* dc,
    int dest_x,
    int dest_y,
    int dest_width,
    int dest_height,
    int src_x,
    int src_y,
    int src_width,
    int src_height,
    const void* bits,
    const void* bitmap_info,
    unsigned int usage,
    unsigned long raster_op);

#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "winmm.lib")

#pragma pack(push, 1)
struct RaftAnimationState_00426ad0 {
    char reserved_00[0x38];
    void* bitmap_bits;
    char reserved_3c[4];
    void* bitmap_info;
    unsigned int last_tick;
    int frame_index;

    void OtRiver_TickRaftAnimation_00426ad0_RealCpp(void* dc);
};

struct RasterTarget_00426ad0 {
    void* handle;

    RasterTarget_00426ad0(void* value) : handle(value) {}
    operator void*() const { return handle; }
};

enum RasterOperation_00426ad0 {
    RasterOperation_Copy_00426ad0 = 0x00cc0020ul
};

enum BitmapColorUsage_00426ad0 {
    BitmapColorUsage_RgbColors_00426ad0 = 1
};

enum RaftFrameDimension_00426ad0 {
    RaftFrameWidth_00426ad0 = 0x48,
    RaftFrameHeight_00426ad0 = 0x4c
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

/**
 * Advance and draw the paired raft-animation strips after their 300 ms delay.
 *
 * The two blits read opposite vertical halves of the same indexed bitmap and
 * share one frame counter.  The semantic GDI types below preserve the original
 * VC4 register allocation without source-level register hints.
 */
void RaftAnimationState_00426ad0::
    OtRiver_TickRaftAnimation_00426ad0_RealCpp(void* dc)
{
    RasterTarget_00426ad0 target(dc);
    unsigned int tick = timeGetTime();
    unsigned int elapsed = tick - last_tick;

    if (elapsed > 0x12c) {
        last_tick = tick;
        StretchDIBits(
            target,
            0x34,
            0x13,
            RaftFrameWidth_00426ad0,
            RaftFrameHeight_00426ad0,
            frame_index * RaftFrameWidth_00426ad0,
            RaftFrameHeight_00426ad0,
            RaftFrameWidth_00426ad0,
            RaftFrameHeight_00426ad0,
            bitmap_bits,
            bitmap_info,
            BitmapColorUsage_RgbColors_00426ad0,
            RasterOperation_Copy_00426ad0);

        StretchDIBits(
            target,
            0x19c,
            0x13,
            RaftFrameWidth_00426ad0,
            RaftFrameHeight_00426ad0,
            frame_index * RaftFrameWidth_00426ad0,
            0,
            RaftFrameWidth_00426ad0,
            RaftFrameHeight_00426ad0,
            bitmap_bits,
            bitmap_info,
            BitmapColorUsage_RgbColors_00426ad0,
            RasterOperation_Copy_00426ad0);

        ++frame_index;
        if (frame_index > 7) {
            frame_index = 0;
        }
    }
}

#pragma optimize("", on)
