// Product semantic WIP for OtProcessRiverCrossingChoice @ 0x0040ec30.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

#include "../trail/trail_event_text_pointers.h"

extern "C" __declspec(dllimport) int __stdcall LoadStringA(
    void* instance,
    unsigned int string_id,
    char* buffer,
    int buffer_length);
extern "C" __declspec(dllimport) int __cdecl wsprintfA(
    char* buffer,
    const char* format,
    ...);

extern "C" int __cdecl OtRandomBelow_RealCpp(int upper_bound);
extern "C" int __cdecl OtRunSharedMessageDialog_00401e70_RealCpp(
    void* parent_window,
    void* message_text,
    void* caption_text,
    int use_alternate_template);

extern "C" void* g_applicationModule_00405a40_20260603;
extern "C" void* g_journeyState;
extern "C" void* g_activeRouteDescriptor;
extern "C" const char g_delayDaysFormat_0041ac20[];

#pragma comment(lib, "user32.lib")

#pragma pack(push, 1)
struct RouteDescriptor_0040ec30_ProductWip {
    short landmark_id;
    short route_stop_kind;
    short store_price_percent;
    short region_id;
    short river_difficulty;
};

struct JourneyState_0040ec30_ProductWip {
    char reserved_000[0x54];
    short river_condition;
    char reserved_056[0x44];
    short clothing;
    char reserved_09c[0x0c];
    int cash_cents;
};

struct TrailEventTextRuntime_0041aac0_20260603 {
    void* first_argument;

    char* OtFormatGameMessageText_0001ac80_ProductWip(int string_id);
};

struct DelayTextState_0041ac20 {
    char reserved_00[0x12];
    char delay_text[1];

    void OtFormatDelayDaysText_RealCpp(short days);
};
#pragma pack(pop)

extern "C" TrailEventTextRuntime_0041aac0_20260603
    g_trailEventRuntimeState;

#pragma data_seg(".otdat")
extern "C" __declspec(allocate(".otdat"))
short g_riverCrossingPromptMode_0040ec30 = 0;
extern "C" __declspec(allocate(".otdat"))
short g_riverCrossingChoice_0040ec30 = 0;
extern "C" __declspec(allocate(".otdat"))
short g_riverCrossingDialogResult_0040ec30 = 0;
#pragma data_seg()

#pragma code_seg(".otsem")
#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" unsigned short __stdcall
OtProcessRiverCrossingChoice_0040ec30_ProductWip(
    void* parent_window,
    short choice)
{
    char crossing_caption[60];
    char guide_unit_text[152];
    char guide_cost_text[152];
    short guide_clothing_cost;
    int guide_followup_message;

    g_riverCrossingChoice_0040ec30 = choice;
    g_riverCrossingPromptMode_0040ec30 = 1;
    g_riverCrossingDialogResult_0040ec30 = 0;

    LoadStringA(
        g_applicationModule_00405a40_20260603,
        static_cast<unsigned int>(choice + 0x385),
        crossing_caption,
        sizeof(crossing_caption));

    if (static_cast<RouteDescriptor_0040ec30_ProductWip*>(
            g_activeRouteDescriptor)->route_stop_kind != 1) {
        return 0;
    }

    switch (choice) {
    case 100:
        return 0;

    case 101:
        if (static_cast<short>(
                static_cast<short>((static_cast<
                    JourneyState_0040ec30_ProductWip*>(
                        g_journeyState)->river_condition * 2) / 10) +
                static_cast<RouteDescriptor_0040ec30_ProductWip*>(
                    g_activeRouteDescriptor)->river_difficulty * 10) < 15) {
            OtRunSharedMessageDialog_00401e70_RealCpp(
                parent_window,
                g_trailEventRuntimeState.
                    OtFormatGameMessageText_0001ac80_ProductWip(0x40a),
                crossing_caption,
                0);
            return 0xffff;
        }
        return 1;

    case 102:
        if (static_cast<short>(
                static_cast<short>((static_cast<
                    JourneyState_0040ec30_ProductWip*>(
                        g_journeyState)->river_condition * 2) / 10) +
                static_cast<RouteDescriptor_0040ec30_ProductWip*>(
                    g_activeRouteDescriptor)->river_difficulty * 10) < 25) {
            OtRunSharedMessageDialog_00401e70_RealCpp(
                parent_window,
                g_trailEventRuntimeState.
                    OtFormatGameMessageText_0001ac80_ProductWip(0x418),
                crossing_caption,
                0);
            return 0xffff;
        }

        g_riverCrossingDialogResult_0040ec30 =
            static_cast<short>(OtRandomBelow_RealCpp(6) + 1);
        reinterpret_cast<DelayTextState_0041ac20*>(
            &g_trailEventRuntimeState)->OtFormatDelayDaysText_RealCpp(
                g_riverCrossingDialogResult_0040ec30);

        if (OtRunSharedMessageDialog_00401e70_RealCpp(
                parent_window,
                g_trailEventRuntimeState.
                    OtFormatGameMessageText_0001ac80_ProductWip(0x419),
                crossing_caption,
                4) == 7) {
            return 0xffff;
        }

        if (static_cast<JourneyState_0040ec30_ProductWip*>(
                g_journeyState)->cash_cents < 500) {
            OtRunSharedMessageDialog_00401e70_RealCpp(
                parent_window,
                g_trailEventRuntimeState.
                    OtFormatGameMessageText_0001ac80_ProductWip(0x41a),
                crossing_caption,
                0);
            return 0xffff;
        }

        static_cast<JourneyState_0040ec30_ProductWip*>(
            g_journeyState)->cash_cents -= 500;
        return static_cast<unsigned short>(
            g_riverCrossingDialogResult_0040ec30);

    case 103:
        guide_clothing_cost =
            static_cast<short>(OtRandomBelow_RealCpp(2) + 2);
        LoadStringA(g_applicationModule_00405a40_20260603, 0x387, guide_unit_text, 0x27);
        wsprintfA(
            guide_cost_text,
            g_delayDaysFormat_0041ac20,
            static_cast<int>(guide_clothing_cost),
            guide_unit_text);
        g_trailEventTextPointers.primary = guide_cost_text;

        if (static_cast<JourneyState_0040ec30_ProductWip*>(
                g_journeyState)->clothing < guide_clothing_cost) {
            OtRunSharedMessageDialog_00401e70_RealCpp(
                parent_window,
                g_trailEventRuntimeState.
                    OtFormatGameMessageText_0001ac80_ProductWip(0x429),
                crossing_caption,
                0);
            return 0xffff;
        }

        if (OtRunSharedMessageDialog_00401e70_RealCpp(
                parent_window,
                g_trailEventRuntimeState.
                    OtFormatGameMessageText_0001ac80_ProductWip(0x428),
                crossing_caption,
                4) == 7) {
            return 0xffff;
        }

        static_cast<JourneyState_0040ec30_ProductWip*>(
            g_journeyState)->clothing -= guide_clothing_cost;
        g_riverCrossingPromptMode_0040ec30 = 5;

        if (static_cast<short>(
                static_cast<short>((static_cast<
                    JourneyState_0040ec30_ProductWip*>(
                        g_journeyState)->river_condition * 2) / 10) +
                static_cast<RouteDescriptor_0040ec30_ProductWip*>(
                    g_activeRouteDescriptor)->river_difficulty * 10) < 25) {
            g_riverCrossingChoice_0040ec30 = 100;
            g_riverCrossingDialogResult_0040ec30 = 0;
            guide_followup_message = 0x42a;
        } else {
            g_riverCrossingChoice_0040ec30 = 101;
            g_riverCrossingDialogResult_0040ec30 = 1;
            guide_followup_message = 0x42b;
        }

        OtRunSharedMessageDialog_00401e70_RealCpp(
            parent_window,
            g_trailEventRuntimeState.
                OtFormatGameMessageText_0001ac80_ProductWip(
                    guide_followup_message),
            crossing_caption,
            0);
        return static_cast<unsigned short>(
            g_riverCrossingDialogResult_0040ec30);

    case 104:
        OtRunSharedMessageDialog_00401e70_RealCpp(
            parent_window,
            g_trailEventRuntimeState.
                OtFormatGameMessageText_0001ac80_ProductWip(0x430),
            crossing_caption,
            0);
        return 1;

    default:
        return 0;
    }
}

#pragma optimize("", on)
#pragma code_seg()
