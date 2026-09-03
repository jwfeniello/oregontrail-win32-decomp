// Product implementation of the trade-selection validation and offer flow at
// Oregon32.exe 0x0040eb20.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

extern "C" void* g_applicationModule_00405a40_20260603;
extern "C" int g_lastSelectedTradeItem_Product_0043995c = -1;

extern "C" __declspec(dllimport) long __stdcall GetWindowLongA(
    void* window,
    int index);
extern "C" __declspec(dllimport) void* __stdcall GetDlgItem(
    void* dialog,
    int control_id);
extern "C" __declspec(dllimport) int __stdcall GetWindowTextA(
    void* window,
    char* text,
    int max_count);
extern "C" __declspec(dllimport) long __stdcall SendMessageA(
    void* window,
    unsigned int message,
    unsigned int wparam,
    long lparam);

typedef long (__stdcall *TradeOfferDialogProc_0040eb20)(
    void* dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam);

extern "C" __declspec(dllimport) int __stdcall DialogBoxParamA(
    void* instance,
    const char* template_name,
    void* parent,
    TradeOfferDialogProc_0040eb20 dialog_proc,
    long init_param);

extern "C" int __cdecl OtAtoi_RealCpp(const char* text);
extern "C" int __stdcall OtBuildTradeOffer_00427950_ProductWip(
    short offered_item,
    short wanted_quantity);
extern "C" long __stdcall OtTradeOfferDialogProc_0040d580_ProductWip(
    void* dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" int __cdecl OtRunSharedMessageDialog_00401e70_RealCpp(
    void* parent_window,
    void* message_text,
    void* caption_text,
    int use_alternate_template);

static char kTradeSelectionMissingOfferText_0040eb20[] =
    "You must select an item to trade for.";
static char kTradeSelectionMissingOfferCaption_0040eb20[] =
    "Trading Error";

#pragma pack(push, 1)
struct TradeSelectionDialogState_0040eb20 {
    unsigned char button_bitmaps[4][0x28];
    int* accepted_result;
};
#pragma pack(pop)

typedef char TradeSelectionDialogStateSizeMustBeA4_0040eb20[
    sizeof(TradeSelectionDialogState_0040eb20) == 0xa4 ? 1 : -1];

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" int __cdecl
OtValidateTradeSelectionAndOpenOfferDialog_0040eb20_Product(
    void* dialog,
    short* selected_item,
    short* wanted_quantity)
{
    char quantity_text[8];
    void* owner = dialog;
    TradeSelectionDialogState_0040eb20* state;
    int item_index;

    state = reinterpret_cast<TradeSelectionDialogState_0040eb20*>(
        GetWindowLongA(owner, 8));

    GetWindowTextA(GetDlgItem(owner, 0x64dd), quantity_text, 5);
    *wanted_quantity = static_cast<short>(OtAtoi_RealCpp(quantity_text));

    item_index = 0;
    while (SendMessageA(
               GetDlgItem(owner, 0x64e1 + item_index),
               0xf0,
               0,
               0) == 0) {
        ++item_index;
        if (item_index >= 8) {
            break;
        }
    }

    if (item_index < 8) {
        *selected_item = static_cast<short>(item_index);
        g_lastSelectedTradeItem_Product_0043995c = item_index;
    } else {
        *selected_item = -1;
    }

    if (*wanted_quantity > 0) {
        if (*selected_item != -1) {
            *state->accepted_result =
                OtBuildTradeOffer_00427950_ProductWip(
                    *selected_item,
                    *wanted_quantity);

            DialogBoxParamA(
                g_applicationModule_00405a40_20260603,
                reinterpret_cast<const char*>(0xfd),
                owner,
                OtTradeOfferDialogProc_0040d580_ProductWip,
                reinterpret_cast<long>(state->accepted_result));

            return 1;
        }

        OtRunSharedMessageDialog_00401e70_RealCpp(
            owner,
            kTradeSelectionMissingOfferText_0040eb20,
            kTradeSelectionMissingOfferCaption_0040eb20,
            0);
        return 0;
    }

    return 1;
}

#pragma optimize("", on)
