// Semantic Product reconstruction for OtPaintHuntResultsText @ 0x004027b0.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This Product source must be compiled with 32-bit MSVC."
#endif

#include <stdlib.h>
#include <string.h>

#pragma comment(lib, "user32.lib")
#pragma comment(lib, "gdi32.lib")
#pragma intrinsic(strlen, strcat, memset)

#pragma pack(push, 1)
struct HuntResultRect_004027b0_Product {
    long left;
    long top;
    long right;
    long bottom;
};

struct HuntResultTextMetrics_004027b0_Product {
    long height;
    unsigned char reserved_004[52];
};

struct HuntResultPaintState_004027b0_Product {
    void* dc;
    int erase_background;
    HuntResultRect_004027b0_Product paint_rect;
    int restore;
    int update_region_changed;
    unsigned char reserved_020[32];
};

struct HuntResultSummary_004027b0_Product {
    int shots_fired;
    int total_pounds;
    int carrying_capacity;
    int kept_pounds;

    int KeptAllPounds(int hunted_total) const
    {
        return hunted_total == kept_pounds;
    }

    int HasDiscardedPounds(int hunted_total) const
    {
        return (unsigned int)hunted_total > (unsigned int)kept_pounds;
    }
};
#pragma pack(pop)

extern "C" __declspec(dllimport) void* __stdcall BeginPaint(
    void* window,
    HuntResultPaintState_004027b0_Product* paint);
extern "C" __declspec(dllimport) int __stdcall EndPaint(
    void* window,
    const HuntResultPaintState_004027b0_Product* paint);
extern "C" __declspec(dllimport) int __stdcall GetClientRect(
    void* window,
    HuntResultRect_004027b0_Product* rect);
extern "C" __declspec(dllimport) int __stdcall GetTextMetricsA(
    void* dc,
    HuntResultTextMetrics_004027b0_Product* metrics);
extern "C" __declspec(dllimport) int __stdcall SetBkMode(
    void* dc,
    int mode);
extern "C" __declspec(dllimport) int __stdcall LoadStringA(
    void* instance,
    unsigned int string_id,
    char* buffer,
    int buffer_length);
extern "C" __declspec(dllimport) int __stdcall DrawTextA(
    void* dc,
    const char* text,
    int text_length,
    HuntResultRect_004027b0_Product* rect,
    unsigned int format);

extern "C" void* g_resourceModule;
extern "C" void* g_journeyState;
extern "C" short __fastcall OtCountLivingPartyMembers_RealCpp(
    const void* party);

static const char kHuntResultSentencePeriod_004027b0[] = ".";

static __inline void OtAppendHuntResultResourceText_004027b0(
    char* text,
    unsigned int string_id)
{
    LoadStringA(
        g_resourceModule,
        string_id,
        text + strlen(text),
        200 - strlen(text));
}

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" void __cdecl OtPaintHuntResultsText_000027b0_Product(
    void* dialog,
    const HuntResultSummary_004027b0_Product* results)
{
    void* dc;
    const HuntResultSummary_004027b0_Product* state;
    char number[20];
    HuntResultRect_004027b0_Product rect;
    char text[200];
    HuntResultTextMetrics_004027b0_Product metrics;
    HuntResultPaintState_004027b0_Product paint;
    int total_pounds;
    int kept_pounds;
    int shots_fired;
    unsigned int string_id;
    int draw_height;

    dc = BeginPaint(dialog, &paint);
    GetClientRect(dialog, &rect);
    GetTextMetricsA(dc, &metrics);
    SetBkMode(dc, 1);
    state = results;
    total_pounds = state->total_pounds;

    if (total_pounds != 0) {
        memset(number, 0, sizeof(number));
        _itoa(total_pounds, number, 10);
        string_id = state->total_pounds == 1 ? 0x3b9 : 0x3b8;
        LoadStringA(g_resourceModule, 0x3b7, text, sizeof(text));
        strcat(text, number);
        OtAppendHuntResultResourceText_004027b0(text, string_id);
    } else {
        LoadStringA(g_resourceModule, 0x3b6, text, sizeof(text));
    }

    total_pounds = state->total_pounds;
    kept_pounds = state->kept_pounds;
    if (state->KeptAllPounds(total_pounds)) {
        strcat(text, kHuntResultSentencePeriod_004027b0);
    } else if ((unsigned int)kept_pounds <
               (unsigned int)state->carrying_capacity) {
        if (kept_pounds == 0) {
            OtAppendHuntResultResourceText_004027b0(text, 0x3be);
        } else {
            memset(number, 0, sizeof(number));
            _itoa(kept_pounds, number, 10);
            string_id = state->kept_pounds == 1 ? 0x3c1 : 0x3c0;
            OtAppendHuntResultResourceText_004027b0(text, 0x3bf);
            strcat(text, number);
            OtAppendHuntResultResourceText_004027b0(text, string_id);
        }
    } else if (state->HasDiscardedPounds(total_pounds)) {
        memset(number, 0, sizeof(number));
        _itoa(kept_pounds, number, 10);
        OtAppendHuntResultResourceText_004027b0(text, 0x3ba);
        strcat(text, number);
        OtAppendHuntResultResourceText_004027b0(text, 0x3bb);

        if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 1) {
            OtAppendHuntResultResourceText_004027b0(text, 0x3bc);
        } else {
            OtAppendHuntResultResourceText_004027b0(text, 0x3bd);
        }
    }

    draw_height = DrawTextA(
        dc,
        text,
        strlen(text),
        &rect,
        0x11);
    rect.top += metrics.height + draw_height;

    memset(text, 0, sizeof(text));
    shots_fired = state->shots_fired;
    if (shots_fired != 0) {
        memset(number, 0, sizeof(number));
        _itoa(shots_fired, number, 10);
        LoadStringA(g_resourceModule, 0x3c2, text, sizeof(text));
        strcat(text, number);
        string_id = state->shots_fired == 1 ? 0x3c4 : 0x3c3;
        OtAppendHuntResultResourceText_004027b0(text, string_id);
    } else {
        LoadStringA(g_resourceModule, 0x3c5, text, sizeof(text));
    }

    draw_height = DrawTextA(
        dc,
        text,
        strlen(text),
        &rect,
        0x11);
    if ((unsigned int)state->total_pounds > 0) {
        rect.top += metrics.height + draw_height;
        memset(text, 0, sizeof(text));
        LoadStringA(g_resourceModule, 0x3c6, text, sizeof(text));
        DrawTextA(dc, text, strlen(text), &rect, 0x11);
    }

    EndPaint(dialog, &paint);
}

#pragma optimize("", on)
