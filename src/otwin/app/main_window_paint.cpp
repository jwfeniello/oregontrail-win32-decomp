// Semantic recovery for the main application paint helper @ 0x00404880.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "app_runtime.h"

#pragma comment(lib, "user32.lib")
#pragma comment(lib, "gdi32.lib")

extern "C" void* g_gamePalette;
extern "C" int g_cdMediaMode_00439108;

extern "C" void __cdecl OtMainWindowCommandLatch_00004950_ProductPf_20260605_ReccmpWip(
    void* dc);

struct PositionedBitmap_0040b7b0_Semantic {
    char storage[0x28];

    int OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
        void* dc,
        int source_x,
        int source_y);
};

#pragma pack(push, 1)
struct MainWindowPaintState_00404880 {
    void* vtable;
    void* main_window;
    char reserved_08[0x0c];
    PositionedBitmap_0040b7b0_Semantic backdrop;
    PositionedBitmap_0040b7b0_Semantic title;
    PositionedBitmap_0040b7b0_Semantic guide;
    PositionedBitmap_0040b7b0_Semantic wagon;
    PositionedBitmap_0040b7b0_Semantic* active_overlay;
    unsigned int overlay_timer;
    int should_start_overlay_timer;

    void OtPaintMainWindow_00404880_RealCpp();
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

void MainWindowPaintState_00404880::OtPaintMainWindow_00404880_RealCpp()
{
    char paint[0x40];
    void* dc = BeginPaint(main_window, paint);

    SelectPalette(dc, g_gamePalette, 0);
    RealizePalette(dc);

    backdrop.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
    title.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
    guide.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
    wagon.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);

    if (should_start_overlay_timer != 0) {
        active_overlay->OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        if (g_cdMediaMode_00439108 == 0) {
            OtMainWindowCommandLatch_00004950_ProductPf_20260605_ReccmpWip(dc);
        }
        overlay_timer = SetTimer(main_window, 0x02bc, 0x0fa0, 0);
    }

    EndPaint(main_window, paint);
}

#pragma optimize("", on)
