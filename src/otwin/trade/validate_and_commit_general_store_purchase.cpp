// Product semantic recovery for OtValidateAndCommitGeneralStorePurchase
// at original address 0x00407fa0.
//
// The general-store Buy command validates every capacity independently so the
// user is returned to each offending edit control.  Once all quantities are
// valid, it parses the displayed purchase total, debits cash, applies the
// seven supply gains, and prepares the matching trail-event summary text.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This Product source must be compiled with 32-bit MSVC."
#endif

#include <stddef.h>
#include <stdlib.h>
#include <string.h>

#include "../trail/trail_event_text_runtime.h"
#include "trade_adjustment_list.h"

#pragma intrinsic(memset)
#pragma intrinsic(strlen)
#pragma intrinsic(strcat)

extern "C" __declspec(dllimport) unsigned int __stdcall GetDlgItemInt(
    void* dialog,
    int item_id,
    int* translated,
    int is_signed);
extern "C" __declspec(dllimport) void* __stdcall GetDlgItem(
    void* dialog,
    int item_id);
extern "C" __declspec(dllimport) void* __stdcall SetFocus(void* window);
extern "C" __declspec(dllimport) int __stdcall GetWindowTextA(
    void* window,
    char* text,
    int maximum_count);
extern "C" __declspec(dllimport) void* __stdcall GetPropA(
    void* window,
    const char* name);
extern "C" __declspec(dllimport) int __stdcall LoadStringA(
    void* instance,
    unsigned int string_id,
    char* buffer,
    int buffer_max);
extern "C" __declspec(dllimport) char* __stdcall CharLowerA(char* text);

extern "C" int __cdecl OtRunSharedMessageDialog_00401e70_RealCpp(
    void* parent_window,
    void* message_text,
    void* caption_text,
    int use_alternate_template);

#pragma pack(push, 1)
struct GeneralStoreJourneyState_00407fa0_Product {
    char reserved_000[0x96];
    short oxen_count;       // +0x096
    short oxen_sick;        // +0x098
    short clothing;         // +0x09a
    short ammunition;       // +0x09c
    short wagon_wheels;     // +0x09e
    short wagon_axles;      // +0x0a0
    short wagon_tongues;    // +0x0a2
    short food_from_plants; // +0x0a4
    short food_from_hunting;// +0x0a6
    int cash_cents;         // +0x0a8
};

// The same 13-short object is interpreted by the formatter at 0x0041a320.
struct EventAdjustmentListFormatter_0041a320 {
    short entries[13];

    short OtFormatEventAdjustmentList_0041a320_RealCpp(
        const char* person_event_text);
};
#pragma pack(pop)

typedef char OtGeneralStoreJourneyOxenOffsetMustBe096[
    (offsetof(GeneralStoreJourneyState_00407fa0_Product, oxen_count) ==
     0x96) ? 1 : -1];
typedef char OtGeneralStoreJourneyCashOffsetMustBe0a8[
    (offsetof(GeneralStoreJourneyState_00407fa0_Product, cash_cents) ==
     0xa8) ? 1 : -1];
typedef char OtGeneralStoreAdjustmentListSizeMustBe01a[
    (sizeof(TradeAdjustmentList_00427d70) == 0x1a) ? 1 : -1];

extern "C" void* g_applicationModule_00405a40_20260603;
extern "C" void* g_resourceModule;
extern "C" GeneralStoreJourneyState_00407fa0_Product* g_journeyState;
extern "C" const char g_emptyString_004395ac[];

// Original DAT_00439570.  The general-store dialog owns the allocation and
// releases it on WM_DESTROY; this routine fills and consumes the live object.
extern "C" TradeAdjustmentList_00427d70*
    g_generalStorePurchaseAdjustments_00439570 = 0;

#pragma code_seg(".otsem")

// Exact original data literals used by this routine.  These are named here
// because no other Product translation unit currently owns their storage.
extern "C" __declspec(allocate(".otsem"))
const char g_generalStoreFirstVisitProperty_00439574[] = "first";
extern "C" __declspec(allocate(".otsem"))
const char g_generalStoreSentencePeriod_0043919c[] = ".";
extern "C" __declspec(allocate(".otsem"))
const char g_generalStoreWordSeparator_004395b0[] = " ";

enum GeneralStoreControlId_00407fa0 {
    kStoreOxenControl = 0x604,
    kStoreClothingControl = 0x605,
    kStoreAmmunitionControl = 0x606,
    kStoreWheelControl = 0x607,
    kStoreAxleControl = 0x608,
    kStoreTongueControl = 0x609,
    kStoreFoodControl = 0x60a,
    kStoreTotalControl = 0x62d
};

enum GeneralStoreCapacity_00407fa0 {
    kMaximumOxen = 20,
    kMaximumClothing = 50,
    kAmmunitionPerBox = 20,
    kMaximumAmmunition = 2000,
    kMaximumWagonPart = 3,
    kMaximumFood = 2000
};

// The original contains this sequence once for each capped supply.  A macro
// keeps the recovered source readable while retaining those independent
// in-function sequences for eventual VC4 source shaping.
#define OT_SHOW_STORE_CAPACITY_ERROR(                                      \
    prefix_string_id, maximum, item_string_id, caption_string_id,          \
    caption_capacity, control)                                             \
    do {                                                                   \
        char* item_text;                                                   \
        memset(message_text, 0, sizeof(message_text));                     \
        memset(caption_text, 0, sizeof(caption_text));                     \
        LoadStringA(                                                       \
            g_resourceModule,                                             \
            prefix_string_id,                                             \
            message_text,                                                 \
            0x95);                                                        \
        _itoa(                                                             \
            maximum,                                                      \
            message_text + strlen(message_text),                          \
            10);                                                          \
        strcat(message_text, g_generalStoreWordSeparator_004395b0);        \
        item_text = message_text + strlen(message_text);                   \
        LoadStringA(                                                       \
            g_applicationModule_00405a40_20260603,                        \
            item_string_id,                                               \
            item_text,                                                    \
            0x95 - (int)strlen(message_text));                             \
        CharLowerA(item_text);                                             \
        strcat(message_text, g_generalStoreSentencePeriod_0043919c);       \
        LoadStringA(                                                       \
            g_resourceModule,                                             \
            caption_string_id,                                            \
            caption_text,                                                 \
            caption_capacity);                                            \
        OtRunSharedMessageDialog_00401e70_RealCpp(                         \
            dialog,                                                       \
            message_text,                                                 \
            caption_text,                                                 \
            0);                                                           \
        SetFocus(GetDlgItem(dialog, control));                             \
        purchase_is_valid = 0;                                             \
    } while (0)

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" int __cdecl
OtValidateAndCommitGeneralStorePurchase_00007fa0_Product(
    void* dialog,
    void* command_source)
{
    int translated;
    char caption_text[30];
    char message_text[150];
    int purchase_is_valid = 1;
    unsigned int quantity;

    quantity = GetDlgItemInt(
        dialog,
        kStoreOxenControl,
        &translated,
        0);
    quantity += g_journeyState->oxen_count;
    if (quantity > kMaximumOxen) {
        OT_SHOW_STORE_CAPACITY_ERROR(
            0x639,
            kMaximumOxen,
            0x1f4,
            0x636,
            0x1d,
            kStoreOxenControl);
    } else if (command_source != 0) {
        quantity = GetDlgItemInt(
            dialog,
            kStoreOxenControl,
            &translated,
            0);
        quantity += g_journeyState->oxen_count;
        if (quantity == 0) {
            memset(message_text, 0, sizeof(message_text));
            memset(caption_text, 0, sizeof(caption_text));
            LoadStringA(
                g_resourceModule,
                0x63b,
                message_text,
                0x95);
            LoadStringA(
                g_resourceModule,
                0x63c,
                caption_text,
                0x1d);
            OtRunSharedMessageDialog_00401e70_RealCpp(
                dialog,
                message_text,
                caption_text,
                0);
            SetFocus(GetDlgItem(dialog, kStoreOxenControl));
            purchase_is_valid = 0;
        }
    }

    quantity = GetDlgItemInt(
        dialog,
        kStoreClothingControl,
        &translated,
        0);
    quantity += g_journeyState->clothing;
    if (quantity > kMaximumClothing) {
        OT_SHOW_STORE_CAPACITY_ERROR(
            0x63a,
            kMaximumClothing,
            0x1f5,
            0x636,
            0x1d,
            kStoreClothingControl);
    }

    if (GetDlgItemInt(
            dialog,
            kStoreAmmunitionControl,
            &translated,
            0) * kAmmunitionPerBox +
            g_journeyState->ammunition >
        kMaximumAmmunition) {
        OT_SHOW_STORE_CAPACITY_ERROR(
            0x63a,
            100,
            0x1f6,
            0x636,
            0x1d,
            kStoreAmmunitionControl);
    }

    quantity = GetDlgItemInt(
        dialog,
        kStoreWheelControl,
        &translated,
        0);
    quantity += g_journeyState->wagon_wheels;
    if (quantity > kMaximumWagonPart) {
        OT_SHOW_STORE_CAPACITY_ERROR(
            0x63a,
            kMaximumWagonPart,
            0x1f7,
            0x636,
            0x1d,
            kStoreWheelControl);
    }

    quantity = GetDlgItemInt(
        dialog,
        kStoreAxleControl,
        &translated,
        0);
    quantity += g_journeyState->wagon_axles;
    if (quantity > kMaximumWagonPart) {
        OT_SHOW_STORE_CAPACITY_ERROR(
            0x63a,
            kMaximumWagonPart,
            0x1f8,
            0x636,
            0x1d,
            kStoreAxleControl);
    }

    quantity = GetDlgItemInt(
        dialog,
        kStoreTongueControl,
        &translated,
        0);
    quantity += g_journeyState->wagon_tongues;
    if (quantity > kMaximumWagonPart) {
        OT_SHOW_STORE_CAPACITY_ERROR(
            0x63a,
            kMaximumWagonPart,
            0x1f9,
            0x636,
            0x1e,
            kStoreTongueControl);
    }

    short food_on_hand = (short)(
        g_journeyState->food_from_plants +
        g_journeyState->food_from_hunting);
    quantity = GetDlgItemInt(
        dialog,
        kStoreFoodControl,
        &translated,
        0);
    if ((int)food_on_hand + quantity > kMaximumFood) {
        OT_SHOW_STORE_CAPACITY_ERROR(
            0x63a,
            kMaximumFood,
            0x1fa,
            0x637,
            0x1d,
            kStoreFoodControl);
    }

    if (purchase_is_valid != 0) {
        int purchase_cost_cents;
        char* decimal_point;

        memset(message_text, 0, sizeof(message_text));
        GetWindowTextA(
            GetDlgItem(dialog, kStoreTotalControl),
            message_text,
            0x95);
        decimal_point = strstr(
            message_text,
            g_generalStoreSentencePeriod_0043919c);
        purchase_cost_cents = atoi(decimal_point + 1);
        purchase_cost_cents +=
            GetDlgItemInt(
                dialog,
                kStoreTotalControl,
                &translated,
                0) * 100;

        if (g_journeyState->cash_cents < purchase_cost_cents) {
            memset(message_text, 0, sizeof(message_text));
            memset(caption_text, 0, sizeof(caption_text));
            LoadStringA(
                g_resourceModule,
                0x63d,
                message_text,
                0x95);
            LoadStringA(
                g_resourceModule,
                0x638,
                caption_text,
                0x95);
            OtRunSharedMessageDialog_00401e70_RealCpp(
                dialog,
                message_text,
                caption_text,
                0);
            SetFocus(GetDlgItem(dialog, kStoreOxenControl));
            purchase_is_valid = 0;
        } else {
            g_journeyState->cash_cents -= purchase_cost_cents;
        }

        if (purchase_is_valid != 0) {
            int event_message_id;

            quantity = GetDlgItemInt(
                dialog,
                kStoreOxenControl,
                &translated,
                0);
            g_generalStorePurchaseAdjustments_00439570->adjustments[0] =
                (short)quantity;
            quantity = GetDlgItemInt(
                dialog,
                kStoreClothingControl,
                &translated,
                0);
            g_generalStorePurchaseAdjustments_00439570->adjustments[1] =
                (short)quantity;
            quantity = GetDlgItemInt(
                dialog,
                kStoreAmmunitionControl,
                &translated,
                0);
            g_generalStorePurchaseAdjustments_00439570->adjustments[2] =
                (short)((short)quantity * kAmmunitionPerBox);
            quantity = GetDlgItemInt(
                dialog,
                kStoreWheelControl,
                &translated,
                0);
            g_generalStorePurchaseAdjustments_00439570->adjustments[3] =
                (short)quantity;
            quantity = GetDlgItemInt(
                dialog,
                kStoreAxleControl,
                &translated,
                0);
            g_generalStorePurchaseAdjustments_00439570->adjustments[4] =
                (short)quantity;
            quantity = GetDlgItemInt(
                dialog,
                kStoreTongueControl,
                &translated,
                0);
            g_generalStorePurchaseAdjustments_00439570->adjustments[5] =
                (short)quantity;
            quantity = GetDlgItemInt(
                dialog,
                kStoreFoodControl,
                &translated,
                0);
            g_generalStorePurchaseAdjustments_00439570->adjustments[6] =
                (short)quantity;

            g_generalStorePurchaseAdjustments_00439570
                ->OtApplyEventAdjustmentList_Product_0041a430();
            reinterpret_cast<EventAdjustmentListFormatter_0041a320*>(
                g_generalStorePurchaseAdjustments_00439570)
                ->OtFormatEventAdjustmentList_0041a320_RealCpp(
                    g_emptyString_004395ac);

            event_message_id =
                GetPropA(
                    dialog,
                    g_generalStoreFirstVisitProperty_00439574) == 0
                    ? 0x481
                    : 0x47e;

            if (g_generalStorePurchaseAdjustments_00439570
                        ->adjustments[0] != 0 ||
                g_generalStorePurchaseAdjustments_00439570
                        ->adjustments[1] != 0 ||
                g_generalStorePurchaseAdjustments_00439570
                        ->adjustments[2] != 0 ||
                g_generalStorePurchaseAdjustments_00439570
                        ->adjustments[3] != 0 ||
                g_generalStorePurchaseAdjustments_00439570
                        ->adjustments[4] != 0 ||
                g_generalStorePurchaseAdjustments_00439570
                        ->adjustments[5] != 0 ||
                g_generalStorePurchaseAdjustments_00439570
                        ->adjustments[6] != 0) {
                g_trailEventRuntimeState.
                    OtFormatGameMessageText_0001ac80_ProductWip(
                        event_message_id);
            }
        }
    }

    return purchase_is_valid;
}

#pragma optimize("", on)

#undef OT_SHOW_STORE_CAPACITY_ERROR

#pragma code_seg()
