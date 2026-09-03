// Product-semantic recovery of the Willamette Valley score-summary
// initializer at 0x004253a0.
//
// This routine lays out the dialog, calculates and displays every component
// of the final trail score, optionally records that score in the List of
// Legends, and constructs the three positioned bitmaps owned by the dialog
// callback.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

#include <stdlib.h>
#include <string.h>

#include "../graphics/positioned_bitmap_descriptor_state.h"

#pragma intrinsic(memset)
#pragma intrinsic(strcat)
#pragma intrinsic(strlen)

typedef void* OtWillametteHandle_004253a0;

struct OtWillametteRect_004253a0 {
    long left;
    long top;
    long right;
    long bottom;

    long Width() const
    {
        return right - left;
    }

    long Height() const
    {
        return bottom - top;
    }
};

extern "C" __declspec(dllimport) OtWillametteHandle_004253a0 __stdcall
GetParent(OtWillametteHandle_004253a0 window);
extern "C" __declspec(dllimport) int __stdcall GetClientRect(
    OtWillametteHandle_004253a0 window,
    OtWillametteRect_004253a0* rect);
extern "C" __declspec(dllimport) unsigned int __stdcall
GetDialogBaseUnits();
extern "C" __declspec(dllimport) int __stdcall SetWindowPos(
    OtWillametteHandle_004253a0 window,
    OtWillametteHandle_004253a0 insert_after,
    int x,
    int y,
    int width,
    int height,
    unsigned int flags);
extern "C" __declspec(dllimport) OtWillametteHandle_004253a0 __stdcall
GetDlgItem(OtWillametteHandle_004253a0 dialog, int control_id);
extern "C" __declspec(dllimport) int __stdcall ShowWindow(
    OtWillametteHandle_004253a0 window,
    int show_command);
extern "C" __declspec(dllimport) int __stdcall GetWindowTextA(
    OtWillametteHandle_004253a0 window,
    char* text,
    int text_count);
extern "C" __declspec(dllimport) int __stdcall SetWindowTextA(
    OtWillametteHandle_004253a0 window,
    const char* text);
extern "C" __declspec(dllimport) int __stdcall LoadStringA(
    OtWillametteHandle_004253a0 module,
    unsigned int string_id,
    char* text,
    int text_count);
extern "C" __declspec(dllimport) int __stdcall MessageBoxA(
    OtWillametteHandle_004253a0 window,
    const char* text,
    const char* caption,
    unsigned int type);
extern "C" __declspec(dllimport) void __stdcall PostQuitMessage(
    int exit_code);
extern "C" __declspec(dllimport) long __stdcall SetWindowLongA(
    OtWillametteHandle_004253a0 window,
    int index,
    long value);
extern "C" __declspec(dllimport) OtWillametteHandle_004253a0 __stdcall
SetFocus(OtWillametteHandle_004253a0 window);
extern "C" __declspec(dllimport) long __stdcall SendMessageA(
    OtWillametteHandle_004253a0 window,
    unsigned int message,
    unsigned int wparam,
    long lparam);

#pragma comment(lib, "user32.lib")

extern void* __cdecl operator new(unsigned int bytes);

extern "C" void __cdecl
OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
    OtWillametteHandle_004253a0 dialog,
    int control_id,
    int dialog_unit_width,
    int dialog_unit_height);
extern "C" void __cdecl OtResizeControl_RealCpp(
    OtWillametteHandle_004253a0 dialog,
    int control_id,
    int width,
    int height);
extern "C" short __fastcall OtCountLivingPartyMembers_RealCpp(
    const void* party);

// DAT_004390a8 is the initialized application module, while DAT_004390ac is
// the separately loaded resource module.  Keeping those owners distinct is
// required for both string and bitmap resource lookup behavior.
extern "C" void* g_applicationModule_00405a40_20260603;
extern "C" void* g_resourceModule;
extern "C" void* g_journeyState;

#pragma data_seg(".otdat")
// Canonical owner for original DAT_004390f0.  The application options flow
// enables this flag when scores should be persisted in the List of Legends.
extern "C" __declspec(allocate(".otdat"))
int g_trailLeaderboardEnabled_004390f0;
#pragma data_seg()

#pragma pack(push, 1)
#include "willamette_valley_summary_dialog_state.h"

struct WillametteSummaryJourneyState_004253a0 {
    char reserved_000[0x96];
    short oxen_count;
    short sick_oxen_count;
    short clothing_sets;
    short bullets;
    short spare_wheels;
    short spare_axles;
    short spare_tongues;
    short food_from_plants;
    short food_from_hunting;
    int cash_cents;
    short occupation;
    char occupation_name[15];
    char reserved_0bd[1];
    short health_score;
    char party_member_names[5][15];
    char reserved_10b[0x19];
    char date_text[0x1a];
};

struct TrailLeaderboardEntry_004253a0 {
    char name[20];
    char score[11];
};

// All three recovered leaderboard member functions operate on this same
// 0x13a-byte object.  Their historical class names differ because they were
// recovered in separate lanes before the common owner was known.
struct RiverZeroBlock_0042fd80 {
    int count;
    unsigned long entry_dwords[0x4d];
    unsigned short entry_tail;

    RiverZeroBlock_0042fd80* OtClearRiverZeroBlock_RealCpp();
};

struct TrailGameScoreList_0042fc30 {
    int count;
    TrailLeaderboardEntry_004253a0 entries[10];

    int OtLoadScoreList_0042fda0_RealCpp();
};

struct TrailLeaderboardList_0042fc30 {
    int count;
    TrailLeaderboardEntry_004253a0 entries[10];

    int OtInsertRankedScore_0042fc30_RealCpp(
        const char* name,
        int score);
};
#pragma pack(pop)

typedef char OtWillamettePositionedBitmapSizeMustBe28_004253a0[
    sizeof(PositionedBitmapDescriptorState_0040ba40) == 0x28 ? 1 : -1];
typedef char OtWillametteSummaryStateSizeMustBe78_004253a0[
    sizeof(WillametteValleySummaryDialogState_00424f50_Product) == 0x78
        ? 1
        : -1];
typedef char OtWillametteHealthScoreOffsetMustBeBe_004253a0[
    (unsigned int)&(((WillametteSummaryJourneyState_004253a0*)0)->
        health_score) == 0xbe
        ? 1
        : -1];
typedef char OtWillametteLeaderNameOffsetMustBeC0_004253a0[
    (unsigned int)&(((WillametteSummaryJourneyState_004253a0*)0)->
        party_member_names) == 0xc0
        ? 1
        : -1];
typedef char OtWillametteDateTextOffsetMustBe124_004253a0[
    (unsigned int)&(((WillametteSummaryJourneyState_004253a0*)0)->
        date_text) == 0x124
        ? 1
        : -1];
typedef char OtWillametteLeaderboardStorageSizeMustBe13a_004253a0[
    sizeof(RiverZeroBlock_0042fd80) == 0x13a ? 1 : -1];
typedef char OtWillametteLeaderboardLoadViewSizeMustBe13a_004253a0[
    sizeof(TrailGameScoreList_0042fc30) == 0x13a ? 1 : -1];
typedef char OtWillametteLeaderboardInsertViewSizeMustBe13a_004253a0[
    sizeof(TrailLeaderboardList_0042fc30) == 0x13a ? 1 : -1];

#pragma code_seg(".otsem")

// Fixed text recovered from the original initializer's data references.
extern "C" __declspec(allocate(".otsem"))
const char g_willametteSummaryAllocationMessage_004253a0[] =
    "Unable to allocate dialog information structure";
extern "C" __declspec(allocate(".otsem"))
const char g_willametteSummaryAllocationCaption_004253a0[] =
    "WillVallDlgProc";
extern "C" __declspec(allocate(".otsem"))
const char g_willametteSummaryEquationSeparator_004253a0[] = "  =  ";
extern "C" __declspec(allocate(".otsem"))
const char g_willametteSummaryDivisionSeparator_004253a0[] = " / ";
extern "C" __declspec(allocate(".otsem"))
const char g_willametteSummaryOccupationBonus_004253a0[] = " bonus x ";
extern "C" __declspec(allocate(".otsem"))
const char g_willametteSummaryDecimalPoint_004253a0[] = ".";

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" void __cdecl
OtInitWillametteValleySummaryDialog_004253a0_ProductWip(void* dialog_window)
{
    OtWillametteHandle_004253a0 dialog = dialog_window;
#define journey \
    reinterpret_cast<WillametteSummaryJourneyState_004253a0*>( \
        g_journeyState)
    RiverZeroBlock_0042fd80 leaderboard;
    OtWillametteRect_004253a0 client_rect;
    int score_parts[8];
    char text[100];
    unsigned int dialog_units;
    int dialog_unit_width;
    int dialog_unit_height;
    int control_id;
    int health_points_per_person;
    int base_score;
    int occupation_multiplier;
    int final_score;
    int index;

    leaderboard.OtClearRiverZeroBlock_RealCpp();

    GetClientRect(GetParent(dialog), &client_rect);
    dialog_units = GetDialogBaseUnits();
    dialog_unit_width = static_cast<unsigned short>(dialog_units);
    dialog_unit_height = static_cast<unsigned short>(
        GetDialogBaseUnits() >> 16);
    int x = client_rect.left + 10;
    int y = client_rect.top + 10;
    SetWindowPos(
        dialog,
        0,
        x,
        y,
        client_rect.Width() - 20,
        client_rect.Height() - 20,
        4);
    GetClientRect(dialog, &client_rect);

    control_id = 0x1b59;
    do {
        OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
            dialog,
            control_id,
            dialog_unit_width,
            dialog_unit_height);
        ++control_id;
    } while (control_id <= 0x1b71);
    OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
        dialog,
        0x12c,
        dialog_unit_width,
        dialog_unit_height);

    {
        short health_class = static_cast<short>(
            journey->health_score / 35);
        if (health_class == 0) {
            health_points_per_person = 500;
        }
        if (health_class == 1) {
            health_points_per_person = 400;
        }
        if (health_class == 2) {
            health_points_per_person = 300;
        }
        if (health_class == 3) {
            health_points_per_person = 200;
        }
    }

    score_parts[0] =
        OtCountLivingPartyMembers_RealCpp(journey) *
        health_points_per_person;
    score_parts[1] = 50;
    score_parts[2] = journey->oxen_count * 4;
    score_parts[3] =
        (journey->spare_wheels +
         journey->spare_axles +
         journey->spare_tongues) * 2;
    score_parts[4] = journey->clothing_sets * 2;
    score_parts[5] = journey->bullets / 50;
    score_parts[6] = static_cast<short>(
        journey->food_from_plants + journey->food_from_hunting) / 25;
    score_parts[7] = (journey->cash_cents / 100) / 5;

    base_score = 0;
    for (index = 0; index < 8; ++index) {
        base_score += score_parts[index];
    }

    {
        short occupation = journey->occupation;
        if (occupation == 0) {
            occupation_multiplier = 10;
        } else if (occupation == 1) {
            occupation_multiplier = 20;
        } else if (occupation == 2) {
            occupation_multiplier = 20;
        } else if (occupation == 3) {
            occupation_multiplier = 10;
        } else if (occupation == 4) {
            occupation_multiplier = 30;
        } else if (occupation == 5) {
            occupation_multiplier = 15;
        } else if (occupation == 6) {
            occupation_multiplier = 25;
        } else {
            occupation_multiplier = 35;
        }
    }
    final_score = occupation_multiplier * base_score / 10;

    if (g_trailLeaderboardEnabled_004390f0 != 0) {
        reinterpret_cast<TrailGameScoreList_0042fc30*>(&leaderboard)
            ->OtLoadScoreList_0042fda0_RealCpp();
        if (reinterpret_cast<TrailLeaderboardList_0042fc30*>(&leaderboard)
                ->OtInsertRankedScore_0042fc30_RealCpp(
                    journey->party_member_names[0],
                    final_score) == 0) {
            ShowWindow(GetDlgItem(dialog, 0x1b5a), 0);
        }
    }

    GetWindowTextA(GetDlgItem(dialog, 0x1b5b), text, sizeof(text));
    strcat(text, journey->date_text);
    LoadStringA(
        g_applicationModule_00405a40_20260603,
        0x212,
        text + strlen(text),
        99 - static_cast<int>(strlen(text)));
    SetWindowTextA(GetDlgItem(dialog, 0x1b5b), text);

    memset(text, 0, sizeof(text));
    _itoa(OtCountLivingPartyMembers_RealCpp(journey), text, 10);
    LoadStringA(
        g_applicationModule_00405a40_20260603,
        0x213,
        text + strlen(text),
        99 - static_cast<int>(strlen(text)));
    LoadStringA(
        g_applicationModule_00405a40_20260603,
        static_cast<short>(journey->health_score / 35) + 0xb0,
        text + strlen(text),
        99 - static_cast<int>(strlen(text)));
    LoadStringA(
        g_applicationModule_00405a40_20260603,
        0x214,
        text + strlen(text),
        99 - static_cast<int>(strlen(text)));
    _itoa(
        health_points_per_person,
        text + strlen(text),
        10);
    strcat(text, g_willametteSummaryEquationSeparator_004253a0);
    SetWindowTextA(GetDlgItem(dialog, 0x1b5c), text);

    memset(text, 0, sizeof(text));
    _itoa(score_parts[0], text, 10);
    SetWindowTextA(GetDlgItem(dialog, 0x1b64), text);

    memset(text, 0, sizeof(text));
    LoadStringA(
        g_applicationModule_00405a40_20260603,
        0x21a,
        text,
        99);
    _itoa(50, text + strlen(text), 10);
    strcat(text, g_willametteSummaryEquationSeparator_004253a0);
    SetWindowTextA(GetDlgItem(dialog, 0x1b5d), text);
    _itoa(score_parts[1], text, 10);
    SetWindowTextA(GetDlgItem(dialog, 0x1b65), text);

    memset(text, 0, sizeof(text));
    _itoa(journey->oxen_count, text, 10);
    LoadStringA(
        g_applicationModule_00405a40_20260603,
        0x215,
        text + strlen(text),
        99 - static_cast<int>(strlen(text)));
    _itoa(4, text + strlen(text), 10);
    strcat(text, g_willametteSummaryEquationSeparator_004253a0);
    SetWindowTextA(GetDlgItem(dialog, 0x1b5e), text);
    _itoa(score_parts[2], text, 10);
    SetWindowTextA(GetDlgItem(dialog, 0x1b66), text);

    memset(text, 0, sizeof(text));
    _itoa(
        journey->spare_wheels +
        journey->spare_axles +
        journey->spare_tongues,
        text,
        10);
    LoadStringA(
        g_applicationModule_00405a40_20260603,
        0x216,
        text + strlen(text),
        99 - static_cast<int>(strlen(text)));
    _itoa(2, text + strlen(text), 10);
    strcat(text, g_willametteSummaryEquationSeparator_004253a0);
    SetWindowTextA(GetDlgItem(dialog, 0x1b5f), text);
    _itoa(score_parts[3], text, 10);
    SetWindowTextA(GetDlgItem(dialog, 0x1b67), text);

    memset(text, 0, sizeof(text));
    _itoa(journey->clothing_sets, text, 10);
    LoadStringA(
        g_applicationModule_00405a40_20260603,
        0x217,
        text + strlen(text),
        99 - static_cast<int>(strlen(text)));
    _itoa(2, text + strlen(text), 10);
    strcat(text, g_willametteSummaryEquationSeparator_004253a0);
    SetWindowTextA(GetDlgItem(dialog, 0x1b60), text);
    _itoa(score_parts[4], text, 10);
    SetWindowTextA(GetDlgItem(dialog, 0x1b68), text);

    memset(text, 0, sizeof(text));
    _itoa(journey->bullets, text, 10);
    LoadStringA(
        g_applicationModule_00405a40_20260603,
        0x218,
        text + strlen(text),
        99 - static_cast<int>(strlen(text)));
    _itoa(50, text + strlen(text), 10);
    strcat(text, g_willametteSummaryEquationSeparator_004253a0);
    SetWindowTextA(GetDlgItem(dialog, 0x1b61), text);
    _itoa(score_parts[5], text, 10);
    SetWindowTextA(GetDlgItem(dialog, 0x1b69), text);

    memset(text, 0, sizeof(text));
    _itoa(
        static_cast<short>(
            journey->food_from_plants + journey->food_from_hunting),
        text,
        10);
    LoadStringA(
        g_applicationModule_00405a40_20260603,
        0x219,
        text + strlen(text),
        99 - static_cast<int>(strlen(text)));
    _itoa(25, text + strlen(text), 10);
    strcat(text, g_willametteSummaryEquationSeparator_004253a0);
    SetWindowTextA(GetDlgItem(dialog, 0x1b62), text);
    _itoa(score_parts[6], text, 10);
    SetWindowTextA(GetDlgItem(dialog, 0x1b6a), text);

    memset(text, 0, sizeof(text));
    text[0] = '$';
    _itoa(journey->cash_cents / 100, text + 1, 10);
    strcat(text, g_willametteSummaryDecimalPoint_004253a0);
    _itoa(journey->cash_cents % 100, text + strlen(text), 10);
    strcat(text, g_willametteSummaryDivisionSeparator_004253a0);
    _itoa(5, text + strlen(text), 10);
    strcat(text, g_willametteSummaryEquationSeparator_004253a0);
    SetWindowTextA(GetDlgItem(dialog, 0x1b63), text);
    _itoa(score_parts[7], text, 10);
    SetWindowTextA(GetDlgItem(dialog, 0x1b6b), text);

    memset(text, 0, sizeof(text));
    _itoa(base_score, text, 10);
    SetWindowTextA(GetDlgItem(dialog, 0x1b6f), text);

    memset(text, 0, sizeof(text));
    LoadStringA(
        g_applicationModule_00405a40_20260603,
        journey->occupation + 0xa0,
        text,
        99);
    strcat(text, g_willametteSummaryOccupationBonus_004253a0);
    SetWindowTextA(GetDlgItem(dialog, 0x1b6d), text);

    memset(text, 0, sizeof(text));
    _itoa(occupation_multiplier / 10, text, 10);
    if (occupation_multiplier % 10 != 0) {
        strcat(text, g_willametteSummaryDecimalPoint_004253a0);
        _itoa(
            occupation_multiplier % 10,
            text + strlen(text),
            10);
    }
    SetWindowTextA(GetDlgItem(dialog, 0x1b70), text);

    memset(text, 0, sizeof(text));
    _itoa(final_score, text, 10);
    SetWindowTextA(GetDlgItem(dialog, 0x1b71), text);

    WillametteValleySummaryDialogState_00424f50_Product* state =
        new WillametteValleySummaryDialogState_00424f50_Product;
    if (state == 0) {
        MessageBoxA(
            GetParent(dialog),
            g_willametteSummaryAllocationMessage_004253a0,
            g_willametteSummaryAllocationCaption_004253a0,
            0);
        PostQuitMessage(0);
        return;
    }

    state->close_button_up.
        OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603,
            0x2826);
    state->close_button_down.
        OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_applicationModule_00405a40_20260603,
            0x2827);
    state->score_sheet.
        OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_resourceModule,
            0x579);

    SetWindowLongA(dialog, 8, reinterpret_cast<long>(state));
    OtResizeControl_RealCpp(
        dialog,
        0x12c,
        state->close_button_up.width,
        state->close_button_up.height);
    SetFocus(GetDlgItem(dialog, 0x12c));
    SendMessageA(dialog, 0x401, 0x12c, 0);

#undef journey
}

#pragma optimize("", on)
#pragma code_seg()
