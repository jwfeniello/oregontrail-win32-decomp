// Product semantic WIP for OtAnimateTrailViewportFillPalette @ 0x004070a0.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

#pragma pack(push, 1)
struct PaletteEntry_004070a0_ProductWip {
    unsigned char red;
    unsigned char green;
    unsigned char blue;
    unsigned char flags;
};

struct JourneyState_004070a0_ProductWip {
    char reserved_000[0x50];
    short trail_condition;
    char reserved_052[0x02];
    short light_level;
    short winter_overlay_days;
    char reserved_058[0x02];
    short route_stop_flags;
};

struct TrailViewportPaletteState_004070a0_ProductWip {
    void OtAnimateTrailViewportFillPalette_004070a0_ProductWip(int frame);
};
#pragma pack(pop)

extern "C" int g_dailyTravelDistanceScale;
extern "C" void* g_gamePalette;
extern "C" JourneyState_004070a0_ProductWip* g_journeyState;

extern "C" __declspec(dllimport) int __stdcall AnimatePalette(
    void* palette,
    unsigned int start_index,
    unsigned int entry_count,
    PaletteEntry_004070a0_ProductWip* entries);
extern "C" __declspec(dllimport) unsigned int __stdcall GetPaletteEntries(
    void* palette,
    unsigned int start_index,
    unsigned int entry_count,
    PaletteEntry_004070a0_ProductWip* entries);

#pragma comment(lib, "gdi32.lib")

#pragma data_seg(".otdat")
extern "C" __declspec(allocate(".otdat"))
int g_trailViewportPaletteAnimationEnabled_004070a0 = 0;
#pragma data_seg()

#pragma code_seg(".otsem")
#pragma optimize("s", off)
#pragma optimize("t", on)

void TrailViewportPaletteState_004070a0_ProductWip::
OtAnimateTrailViewportFillPalette_004070a0_ProductWip(int frame)
{
    int step;
    int limit;
    PaletteEntry_004070a0_ProductWip* entry_pointer;
    PaletteEntry_004070a0_ProductWip entry;

    if (g_trailViewportPaletteAnimationEnabled_004070a0 == 0) {
        return;
    }

    step = 0x40 / g_dailyTravelDistanceScale;

    if (g_journeyState->winter_overlay_days > 0) {
        *reinterpret_cast<unsigned long*>(&entry) = 0x00fffcfcul;
    } else {
        if (g_journeyState->light_level > 20) {
            *reinterpret_cast<unsigned long*>(&entry) = 0x0000fa3aul;
        } else {
            *reinterpret_cast<unsigned long*>(&entry) = 0x0000aadcul;
        }
    }

    entry_pointer = &entry;
    entry_pointer->flags = 1;
    AnimatePalette(g_gamePalette, 0xe3, 1, entry_pointer);

    if (frame == 2 && g_journeyState->route_stop_flags == 0) {
        GetPaletteEntries(g_gamePalette, 0xe2, 1, &entry);
        entry_pointer = &entry;

        if (g_journeyState->trail_condition <= 1) {
            if ((int)entry.red > step) {
                entry.red = (unsigned char)(entry.red - (unsigned char)step);
            } else {
                entry.red = 0;
            }

            if ((int)entry.green > step) {
                entry.green =
                    (unsigned char)(entry.green - (unsigned char)step);
            } else {
                entry.green = 0;
            }

            if ((int)entry.red < step && (int)entry.green < step) {
                if ((int)entry.blue > step) {
                    entry.blue =
                        (unsigned char)(entry.blue - (unsigned char)step);
                } else {
                    entry.blue = 0;
                }
            }
        } else {
            step = step / 2;

            if ((int)entry.red > step) {
                entry.red = (unsigned char)(entry.red - (unsigned char)step);
            } else {
                entry.red = 0;
            }

            if ((int)entry.green > step) {
                entry.green =
                    (unsigned char)(entry.green - (unsigned char)step);
            } else {
                entry.green = 0;
            }

            if ((int)entry.blue > step) {
                entry.blue =
                    (unsigned char)(entry.blue - (unsigned char)step);
            } else {
                entry.blue = 0;
            }
        }
    } else if (frame == 3 && g_journeyState->route_stop_flags == 0) {
        GetPaletteEntries(g_gamePalette, 0xe2, 1, &entry);
        entry_pointer = &entry;

        if (g_journeyState->trail_condition <= 1) {
            if (entry_pointer->blue != 0xfa) {
                limit = (0x7d - step) * 2;
                if ((int)entry_pointer->blue < limit) {
                    entry_pointer->blue =
                        (unsigned char)(entry_pointer->blue +
                                        (unsigned char)(step * 2));
                } else {
                    entry_pointer->blue = 0xfa;
                }
            } else {
                limit = step * 2;

                if ((int)entry_pointer->red < 0x63 - limit) {
                    entry_pointer->red =
                        (unsigned char)(entry_pointer->red +
                                        (unsigned char)(step * 2));
                } else {
                    entry_pointer->red = 0x63;
                }

                if ((int)entry_pointer->green < 0xd7 - limit) {
                    entry_pointer->green =
                        (unsigned char)(entry_pointer->green +
                                        (unsigned char)(step * 2));
                } else {
                    entry_pointer->green = 0xd7;
                }
            }
        } else {
            if (entry.red < 200) {
                entry.red = (unsigned char)(entry.red + (unsigned char)step);
            } else {
                entry.red = 200;
            }

            if (entry.green < 200) {
                entry.green =
                    (unsigned char)(entry.green + (unsigned char)step);
            } else {
                entry.green = 200;
            }

            if (entry.blue < 200) {
                entry.blue =
                    (unsigned char)(entry.blue + (unsigned char)step);
            } else {
                entry.blue = 200;
            }
        }
    } else {
        if (g_journeyState->trail_condition <= 1) {
            *reinterpret_cast<unsigned long*>(&entry) = 0x00fad763ul;
        } else {
            *reinterpret_cast<unsigned long*>(&entry) = 0x00c8c8c8ul;
        }
        entry_pointer = &entry;
    }

    entry_pointer->flags = 1;
    AnimatePalette(g_gamePalette, 0xe2, 1, entry_pointer);
}

#pragma optimize("", on)
#pragma code_seg()
