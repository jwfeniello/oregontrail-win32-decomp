// Semantic recovery candidate for OtLoadGlobalPalette @ 0x004036b0.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "graphics_runtime.h"

extern "C" void* g_resourceModule;
extern "C" void* g_gamePalette;
extern "C" int g_usesIndexedColorDisplay;

#pragma comment(lib, "kernel32.lib")
#pragma comment(lib, "user32.lib")
#pragma comment(lib, "gdi32.lib")

#pragma pack(push, 1)
struct PaletteEntry_004036b0 {
    unsigned char red;
    unsigned char green;
    unsigned char blue;
    unsigned char flags;
};

struct LogPalette_004036b0 {
    unsigned short version;
    unsigned short entry_count;
    PaletteEntry_004036b0 entries[256];
};

struct PaletteOwner_004036b0 {
    char reserved_00[4];
    void* owner_window;

    int OtLoadGlobalPalette_004036b0_Semantic();
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

int PaletteOwner_004036b0::OtLoadGlobalPalette_004036b0_Semantic()
{
    register PaletteOwner_004036b0* state = this;
    void* resource_info;
    void* resource_data;
    unsigned char* resource_bytes;
    void* palette_handle;
    LogPalette_004036b0* palette;
    unsigned char* palette_entry;
    void* dc;
    int index;
    register unsigned char* source;
    int count;
    unsigned char* flag;
    unsigned char red;

    resource_info = FindResourceA(
        g_resourceModule,
        (const void*)0x258,
        (const void*)0x7d8);
    if (resource_info == 0) {
        return 0;
    }

    resource_data = LoadResource(g_resourceModule, resource_info);
    if (resource_data == 0) {
        return 0;
    }

    resource_bytes = (unsigned char*)LockResource(resource_data);
    palette_handle = GlobalAlloc(2, 0x408);
    if (palette_handle == 0) {
        FreeResource(resource_data);
        return 0;
    }

    palette = (LogPalette_004036b0*)GlobalLock(palette_handle);
    palette->version = 0x300;
    index = 0;
    palette->entry_count = *(unsigned short*)(resource_bytes + 0x16);

    if (*(unsigned short*)(resource_bytes + 0x16) > 0) {
        palette_entry = (unsigned char*)palette->entries;
        source = resource_bytes + 0x18;
        do {
            red = source[0];
            palette_entry += 4;
            source += 4;
            ++index;
            palette_entry[-4] = red;
            palette_entry[-3] = source[-3];
            palette_entry[-2] = source[-2];
            palette_entry[-1] = 0;
        } while (index < (int)*(unsigned short*)(resource_bytes + 0x16));
    }

    FreeResource(resource_data);

    if (g_usesIndexedColorDisplay != 0) {
        flag = ((unsigned char*)palette) + 0x1cb;
        count = 8;
        do {
            *flag = 5;
            flag += 4;
            --count;
        } while (count != 0);

        flag = ((unsigned char*)palette) + 0x2ef;
        count = 6;
        do {
            *flag = 5;
            flag += 4;
            --count;
        } while (count != 0);

        ((unsigned char*)palette)[0x38f] = 5;
        ((unsigned char*)palette)[0x393] = 5;
    }

    g_gamePalette = CreatePalette(palette);
    UnrealizeObject(g_gamePalette);

    dc = GetDC(state->owner_window);
    SelectPalette(dc, g_gamePalette, 0);
    RealizePalette(dc);
    ReleaseDC(state->owner_window, dc);

    GlobalUnlock(palette_handle);
    GlobalFree(palette_handle);
    return 1;
}

#pragma optimize("", on)
