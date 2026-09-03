// Product-semantic recovery of OtPopulateGeneralStoreForm at 0x00407a10.
//
// This routine fills the General Store title, capacity/current-inventory
// column, item labels, route-adjusted unit prices, and available cash.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This Product source must be compiled with 32-bit Microsoft C++."
#endif

#include <string.h>
#include <stdlib.h>

#pragma intrinsic(memset, strcat)

extern "C" __declspec(dllimport) void* __stdcall GetDlgItem(
    void* dialog,
    int control_id);
extern "C" __declspec(dllimport) int __stdcall SetWindowTextA(
    void* window,
    const char* text);
extern "C" __declspec(dllimport) int __stdcall LoadStringA(
    void* instance,
    unsigned int string_id,
    char* buffer,
    int buffer_maximum);
extern "C" __declspec(dllimport) int __stdcall wvsprintfA(
    char* buffer,
    const char* format,
    char* arguments);

#pragma comment(lib, "user32.lib")

#pragma pack(push, 1)
struct GeneralStoreRouteDescriptor_00407a10_Product {
    unsigned short landmark_id;
    short route_stop_kind;
    short store_price_percent;
};

struct GeneralStoreJourneyState_00407a10_Product {
    char reserved_000[0x96];
    short oxen_count;
    short sick_oxen_count;
    short clothing;
    short ammunition;
    short wagon_wheels;
    short wagon_axles;
    short wagon_tongues;
    short food_from_plants;
    short food_from_hunting;
    int cash_cents;
};

struct GeneralStoreMoneyFormat_00407a10_Product {
    int dollars;
    int cents;
};
#pragma pack(pop)

extern "C" void* g_applicationModule_00405a40_20260603;
extern "C" void* g_resourceModule;
extern "C" GeneralStoreRouteDescriptor_00407a10_Product*
    g_activeRouteDescriptor;
extern "C" GeneralStoreJourneyState_00407a10_Product* g_journeyState;
extern "C" int g_generalStorePriceTable_00409560_Product[7];
extern "C" const char g_storeCurrencyFormat_00409560_Product[];

#pragma code_seg(".otsem")

extern "C" __declspec(allocate(".otsem"))
const char g_generalStoreCashFormat_0043957c[] = "$%4d.%02d";
extern "C" __declspec(allocate(".otsem"))
const char g_generalStoreHaveLabel_00439594[] = "Have";
extern "C" __declspec(allocate(".otsem"))
const char g_generalStoreTitleSuffix_0043959c[] = " General Store";

enum GeneralStoreDisplayControl_00407a10 {
    kGeneralStoreTitleControl = 0x5dc,
    kGeneralStoreIntroControl = 0x5f0,
    kGeneralStoreInventoryFirstControl = 0x5fa,
    kGeneralStoreItemNameFirstControl = 0x60e,
    kGeneralStoreUnitPriceFirstControl = 0x618,
    kGeneralStoreCashControl = 0x62f
};

#pragma optimize("s", off)
#pragma optimize("t", on)

static __inline int OtGeneralStoreBaseUnitPriceCents_00407a10_Product(
    int item_index)
{
    // The original pricing rule has a fixed one-dollar eighth-item case.
    // This form is corroborated by the byte-matching General Store totals
    // routine even though this display loop currently visits only 0..6.
    if ((short)item_index == 7) {
        return 100;
    }

    return
        g_generalStorePriceTable_00409560_Product[(short)item_index] *
        (int)g_activeRouteDescriptor->store_price_percent / 100;
}

extern "C" void __cdecl OtPopulateGeneralStoreForm_00407a10_ProductWip(
    void* dialog_parameter,
    int show_capacity_limits)
{
    register void* dialog = dialog_parameter;
    char text[100];
    GeneralStoreMoneyFormat_00407a10_Product money;
    int item_index;

    // Route identifiers use the original low-28-bit presence predicate.  The
    // descriptor stores the identifier in the low word, so this is also the
    // ordinary nonzero-landmark test seen by the General Store UI.
    if ((((unsigned int)g_activeRouteDescriptor->landmark_id) &
            0x0fffffffUL) != 0) {
        memset(text, 0, sizeof(text));
        LoadStringA(
            g_resourceModule,
            (g_activeRouteDescriptor->landmark_id + 13) * 16,
            text,
            sizeof(text) - 1);
        strcat(text, g_generalStoreTitleSuffix_0043959c);
        SetWindowTextA(GetDlgItem(dialog, kGeneralStoreTitleControl), text);
    }

    if (show_capacity_limits != 0) {
        memset(text, 0, sizeof(text));
        _itoa(20, text, 10);
        SetWindowTextA(
            GetDlgItem(dialog, kGeneralStoreInventoryFirstControl),
            text);

        memset(text, 0, 10);
        _itoa(50, text, 10);
        SetWindowTextA(
            GetDlgItem(dialog, kGeneralStoreInventoryFirstControl + 1),
            text);

        memset(text, 0, 10);
        _itoa(100, text, 10);
        SetWindowTextA(
            GetDlgItem(dialog, kGeneralStoreInventoryFirstControl + 2),
            text);

        memset(text, 0, 10);
        _itoa(3, text, 10);
        SetWindowTextA(
            GetDlgItem(dialog, kGeneralStoreInventoryFirstControl + 3),
            text);

        memset(text, 0, 10);
        _itoa(3, text, 10);
        SetWindowTextA(
            GetDlgItem(dialog, kGeneralStoreInventoryFirstControl + 4),
            text);

        memset(text, 0, 10);
        _itoa(3, text, 10);
        SetWindowTextA(
            GetDlgItem(dialog, kGeneralStoreInventoryFirstControl + 5),
            text);

        memset(text, 0, 10);
        _itoa(2000, text, 10);
        SetWindowTextA(
            GetDlgItem(dialog, kGeneralStoreInventoryFirstControl + 6),
            text);
    } else {
        SetWindowTextA(
            GetDlgItem(dialog, kGeneralStoreIntroControl),
            g_generalStoreHaveLabel_00439594);

        memset(text, 0, sizeof(text));
        _itoa(g_journeyState->oxen_count, text, 10);
        SetWindowTextA(
            GetDlgItem(dialog, kGeneralStoreInventoryFirstControl),
            text);

        memset(text, 0, sizeof(text));
        _itoa(g_journeyState->clothing, text, 10);
        SetWindowTextA(
            GetDlgItem(dialog, kGeneralStoreInventoryFirstControl + 1),
            text);

        memset(text, 0, sizeof(text));
        _itoa((g_journeyState->ammunition + 19) / 20, text, 10);
        SetWindowTextA(
            GetDlgItem(dialog, kGeneralStoreInventoryFirstControl + 2),
            text);

        memset(text, 0, sizeof(text));
        _itoa(g_journeyState->wagon_wheels, text, 10);
        SetWindowTextA(
            GetDlgItem(dialog, kGeneralStoreInventoryFirstControl + 3),
            text);

        memset(text, 0, sizeof(text));
        _itoa(g_journeyState->wagon_axles, text, 10);
        SetWindowTextA(
            GetDlgItem(dialog, kGeneralStoreInventoryFirstControl + 4),
            text);

        memset(text, 0, sizeof(text));
        _itoa(g_journeyState->wagon_tongues, text, 10);
        SetWindowTextA(
            GetDlgItem(dialog, kGeneralStoreInventoryFirstControl + 5),
            text);

        memset(text, 0, sizeof(text));
        _itoa(
            (short)(g_journeyState->food_from_plants +
                    g_journeyState->food_from_hunting),
            text,
            10);
        SetWindowTextA(
            GetDlgItem(dialog, kGeneralStoreInventoryFirstControl + 6),
            text);
    }

    for (item_index = 0; item_index < 7; ++item_index) {
        LoadStringA(
            g_applicationModule_00405a40_20260603,
            500 + item_index,
            text,
            sizeof(text));
        SetWindowTextA(
            GetDlgItem(
                dialog,
                kGeneralStoreItemNameFirstControl + item_index),
            text);

        if (item_index == 2) {
            money.dollars =
                (OtGeneralStoreBaseUnitPriceCents_00407a10_Product(
                     item_index) * 20) / 100;
            money.cents =
                (OtGeneralStoreBaseUnitPriceCents_00407a10_Product(
                     item_index) * 20) % 100;
        } else {
            money.dollars =
                OtGeneralStoreBaseUnitPriceCents_00407a10_Product(
                    item_index) / 100;
            money.cents =
                OtGeneralStoreBaseUnitPriceCents_00407a10_Product(
                    item_index) % 100;
        }

        wvsprintfA(
            text,
            g_storeCurrencyFormat_00409560_Product,
            (char*)&money);
        SetWindowTextA(
            GetDlgItem(
                dialog,
                kGeneralStoreUnitPriceFirstControl + item_index),
            text);
    }

    money.dollars = g_journeyState->cash_cents / 100;
    money.cents = g_journeyState->cash_cents % 100;
    wvsprintfA(text, g_generalStoreCashFormat_0043957c, (char*)&money);
    SetWindowTextA(GetDlgItem(dialog, kGeneralStoreCashControl), text);
}

#pragma optimize("", on)
#pragma code_seg()
