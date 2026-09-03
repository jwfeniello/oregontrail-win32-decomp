// Canonical Product palette-brush members @ 0x00406940 and 0x00406980.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

extern "C" int g_usesIndexedColorDisplay;

extern "C" __declspec(dllimport) unsigned long __stdcall CreateSolidBrush(
    unsigned long color);
extern "C" __declspec(dllimport) unsigned long __stdcall GetNearestColor(
    void* dc,
    unsigned long color);

#pragma comment(lib, "gdi32.lib")

struct TrailPaletteBrushState_00406940 {
    unsigned long OtCreateTrailGroundBrush_00406940_ProductWip(void* dc);
    unsigned long OtCreateTrailSkyBrush_00406980_ProductWip(void* dc);
};

#pragma code_seg(".otsem")
#pragma optimize("s", off)
#pragma optimize("t", on)

// Creates the foreground/ground brush from palette index 0xe3 or the nearest
// RGB color when the display is not using an indexed palette.
unsigned long TrailPaletteBrushState_00406940::
    OtCreateTrailGroundBrush_00406940_ProductWip(void* dc)
{
    if (g_usesIndexedColorDisplay != 0) {
        return CreateSolidBrush(0x010000e3);
    }

    return CreateSolidBrush(GetNearestColor(dc, 0x0000fa3a));
}

// Creates the sky brush from palette index 0xe2 or the nearest recovered sky
// RGB color when the display is not using an indexed palette.
unsigned long TrailPaletteBrushState_00406940::
    OtCreateTrailSkyBrush_00406980_ProductWip(void* dc)
{
    if (g_usesIndexedColorDisplay != 0) {
        return CreateSolidBrush(0x010000e2);
    }

    return CreateSolidBrush(GetNearestColor(dc, 0x00fad763));
}

#pragma optimize("", on)
#pragma code_seg()
