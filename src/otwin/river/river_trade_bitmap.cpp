// Promotion: OtRiver_DrawTradeBitmap @ 0x004278f0.
//
// Repaints the trade-dialog bitmap layer inside a BeginPaint/EndPaint scope:
// selects the game palette, realizes it, blits the trade bitmap at (0x30, 0xf),
// and marks the trade view as bitmap-active.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "../graphics/raw_indexed_bitmap_runtime.h"

extern "C" __declspec(dllimport) void* __stdcall BeginPaint(
    void* window,
    void* paint_struct);
extern "C" __declspec(dllimport) int __stdcall EndPaint(
    void* window,
    const void* paint_struct);
extern "C" __declspec(dllimport) void* __stdcall SelectPalette(
    void* dc,
    void* palette,
    int force_background);
extern "C" __declspec(dllimport) unsigned int __stdcall RealizePalette(
    void* dc);

extern "C" void* g_gamePalette;

#pragma comment(lib, "user32.lib")
#pragma comment(lib, "gdi32.lib")

#pragma pack(push, 1)
struct PaintStruct_004278f0 {
    char data[0x40];
};

struct RiverTradeView_004278f0 {
    char reserved_00[0x64];
    int trade_bitmap_active;
    char reserved_68[0x0c];
    RawIndexedBitmap_00410490_Product* trade_bitmap;
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

#pragma optimize("a", on)
extern "C" void __cdecl OtRiver_DrawTradeBitmap_RealCpp(
    void* window,
    RiverTradeView_004278f0* state)
{
    PaintStruct_004278f0 ps;
    register void* w = window;
    register void* dc;

    dc = BeginPaint(w, &ps);
    SelectPalette(dc, g_gamePalette, 0);
    RealizePalette(dc);
    state->trade_bitmap->OtBlitRawIndexedBitmap_Product_004105a0(
        dc,
        0x30,
        0x0f);
    state->trade_bitmap_active = 1;
    EndPaint(w, &ps);
}
#pragma optimize("a", off)
