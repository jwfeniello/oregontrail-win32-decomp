// Semantic recovery for OtRecordHuntOutcomeMessage @ 0x00402fc0.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This Product source must be compiled with 32-bit MSVC."
#endif

#include "../trail/trail_event_text_runtime.h"

#include <stdlib.h>
#include <string.h>

extern "C" __declspec(dllimport) int __stdcall LoadStringA(
    void* instance,
    unsigned int string_id,
    char* buffer,
    int buffer_length);

extern "C" void* g_resourceModule;
extern "C" void* g_journeyState;
extern "C" short __fastcall OtCountLivingPartyMembers_RealCpp(
    const void* party);

#pragma comment(lib, "user32.lib")
#pragma intrinsic(strlen, memset)

#pragma pack(push, 1)
struct HuntOutcomeMessageState_00402fc0_Product {
    int reserved_00;
    int primary_pounds;
    int kept_pounds;
    int secondary_pounds;
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" void __stdcall OtRecordHuntOutcomeMessage_00002fc0_Product(
    HuntOutcomeMessageState_00402fc0_Product* outcome)
{
    char first_text[200];
    char second_text[200];
    int secondary_pounds;
    int primary_pounds = outcome->primary_pounds;

    if (primary_pounds == 0) {
        if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 1) {
            g_trailEventRuntimeState.
                OtFormatGameMessageText_0001ac80_ProductWip(0x3c8);
            return;
        }

        g_trailEventRuntimeState.
            OtFormatGameMessageText_0001ac80_ProductWip(0x3c9);
        return;
    }

    secondary_pounds = outcome->secondary_pounds;
    if (primary_pounds == secondary_pounds) {
        memset(first_text, 0, sizeof(first_text));
        _itoa(secondary_pounds, first_text, 10);
        int pounds_string_id =
            outcome->secondary_pounds == 1 ? 0x3b9 : 0x3b8;
        LoadStringA(
            g_resourceModule,
            pounds_string_id,
            first_text + strlen(first_text),
            sizeof(first_text) - strlen(first_text));
        g_trailEventRuntimeState.event_argument_pointer = first_text;
        g_trailEventRuntimeState.
            OtFormatGameMessageText_0001ac80_ProductWip(0x3cb);
        return;
    }

    if (outcome->kept_pounds == secondary_pounds) {
        memset(first_text, 0, sizeof(first_text));
        _itoa(primary_pounds, first_text, 10);
        LoadStringA(
            g_resourceModule,
            0x3b8,
            first_text + strlen(first_text),
            sizeof(first_text) - strlen(first_text));
        g_trailEventRuntimeState.event_argument_pointer = first_text;

        memset(second_text, 0, sizeof(second_text));
        _itoa(outcome->secondary_pounds, second_text, 10);
        LoadStringA(
            g_resourceModule,
            0x3b8,
            second_text + strlen(second_text),
            sizeof(second_text) - strlen(second_text));
        g_trailEventRuntimeState.name_pointer = second_text;

        if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 1) {
            g_trailEventRuntimeState.
                OtFormatGameMessageText_0001ac80_ProductWip(0x3cd);
            return;
        }

        g_trailEventRuntimeState.
            OtFormatGameMessageText_0001ac80_ProductWip(0x3ce);
        return;
    }

    if (secondary_pounds != 0) {
        memset(first_text, 0, sizeof(first_text));
        _itoa(primary_pounds, first_text, 10);
        LoadStringA(
            g_resourceModule,
            0x3b8,
            first_text + strlen(first_text),
            sizeof(first_text) - strlen(first_text));
        g_trailEventRuntimeState.event_argument_pointer = first_text;

        memset(second_text, 0, sizeof(second_text));
        secondary_pounds = outcome->secondary_pounds;
        int pounds_string_id =
            secondary_pounds == 1 ? 0x3b9 : 0x3b8;
        _itoa(secondary_pounds, second_text, 10);
        LoadStringA(
            g_resourceModule,
            pounds_string_id,
            second_text + strlen(second_text),
            sizeof(second_text) - strlen(second_text));
        g_trailEventRuntimeState.name_pointer = second_text;

        if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 1) {
            g_trailEventRuntimeState.
                OtFormatGameMessageText_0001ac80_ProductWip(0x3d0);
            return;
        }

        g_trailEventRuntimeState.
            OtFormatGameMessageText_0001ac80_ProductWip(0x3d1);
        return;
    }

    memset(first_text, 0, sizeof(first_text));
    _itoa(primary_pounds, first_text, 10);
    LoadStringA(
        g_resourceModule,
        0x3b8,
        first_text + strlen(first_text),
        sizeof(first_text) - strlen(first_text));
    g_trailEventRuntimeState.event_argument_pointer = first_text;
    g_trailEventRuntimeState.
        OtFormatGameMessageText_0001ac80_ProductWip(0x3cf);
}

#pragma optimize("", on)
