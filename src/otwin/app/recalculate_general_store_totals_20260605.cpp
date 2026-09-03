// Product-tree semantic closure for OtRecalculateGeneralStoreTotals @ 0x00409560.
//
// The source order and local-variable lifetimes retain the VC4 code shape of
// the original routine.  Prices are expressed in cents; the active route's
// percentage modifier is the signed 16-bit field at RouteDescriptor + 4.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include <string.h>

#pragma intrinsic(memset)

extern "C" __declspec(dllimport) unsigned int __stdcall GetDlgItemInt(
    void* dialog,
    int item_id,
    int* translated,
    int is_signed);
extern "C" __declspec(dllimport) void* __stdcall GetDlgItem(
    void* dialog,
    int item_id);
extern "C" __declspec(dllimport) int __stdcall SetWindowTextA(
    void* window,
    const char* text);
extern "C" __declspec(dllimport) int __stdcall wvsprintfA(
    char* buffer,
    const char* format,
    char* arglist);

#pragma pack(push, 1)
struct RouteDescriptor_00409560_Product {
    short landmark_id;
    short route_stop_kind;
    short store_price_percent;
    short region_id;
    short river_difficulty;
};
#pragma pack(pop)

extern "C" void* g_activeRouteDescriptor;

extern "C" int g_generalStorePriceTable_00409560_Product[7] = {
    2000,
    1000,
    10,
    1000,
    1000,
    1000,
    20
};
extern "C" const char g_storeCurrencyFormat_00409560_Product[] = "%4d.%02d";

struct StoreTotalFormatScratch_00409560_Product {
    int money[2];
    char text[9];
    char pad[3];
};

#pragma code_seg(".otsem")
#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" void __cdecl OtRecalculateGeneralStoreTotals_00409560_Product(
    void* dialog)
{
    int item_totals[7];
    int translated;
    StoreTotalFormatScratch_00409560_Product scratch;
    int total;
    register int item_index;
    register int* item_total;
    register char* text_buffer;
    register int divisor;
    int amount;
    short quantity;

    total = 0;
    item_total = item_totals;
    item_index = 0;

    do {
        if (item_total == item_totals + 2) {
            quantity = (short)((short)GetDlgItemInt(
                dialog,
                item_index + 0x604,
                &translated,
                0) * 0x14);
            if ((short)item_index == 7) {
                *item_total = (int)quantity * 100;
            } else {
                *item_total =
                    ((g_generalStorePriceTable_00409560_Product[
                          (short)item_index] *
                        (int)((RouteDescriptor_00409560_Product*)
                                  g_activeRouteDescriptor)
                            ->store_price_percent) /
                       100) *
                    (int)quantity;
            }
        } else {
            quantity = (short)GetDlgItemInt(
                dialog,
                item_index + 0x604,
                &translated,
                0);
            if ((short)item_index == 7) {
                *item_total = (int)quantity * 100;
            } else {
                *item_total =
                    ((g_generalStorePriceTable_00409560_Product[
                          (short)item_index] *
                        (int)((RouteDescriptor_00409560_Product*)
                                  g_activeRouteDescriptor)
                            ->store_price_percent) /
                       100) *
                    (int)quantity;
            }
        }

        amount = *item_total;
        text_buffer = scratch.text;
        memset(text_buffer, 0, sizeof(scratch.text));
        divisor = 100;

        scratch.money[0] = amount / divisor;
        scratch.money[1] = amount % divisor;
        wvsprintfA(
            text_buffer,
            g_storeCurrencyFormat_00409560_Product,
            (char*)scratch.money);
        SetWindowTextA(
            GetDlgItem(dialog, item_index + 0x622),
            text_buffer);

        ++item_total;
        ++item_index;
        total += amount;
    } while (item_total < item_totals + 7);

    divisor = 100;
    scratch.money[0] = total / divisor;
    scratch.money[1] = total % divisor;
    wvsprintfA(
        scratch.text,
        g_storeCurrencyFormat_00409560_Product,
        (char*)scratch.money);
    SetWindowTextA(GetDlgItem(dialog, 0x62d), scratch.text);
}

#pragma optimize("", on)
#pragma code_seg()
