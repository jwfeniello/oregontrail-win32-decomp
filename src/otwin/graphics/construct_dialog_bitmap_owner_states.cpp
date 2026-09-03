// Product-semantic bitmap-state owners recovered from dialog procedures that
// construct and destroy PositionedBitmap members under Visual C++ 4.0 /GX.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#pragma pack(push, 1)
struct PositionedBitmapDescriptorState_0040ba40 {
    void* bitmap_info_handle;
    void* indexed_pixels_handle;
    void* bitmap_info;
    void* indexed_pixels;
    short x;
    short y;
    short width;
    short height;
    int x_mirror;
    int y_mirror;
    int right;
    int bottom;

    PositionedBitmapDescriptorState_0040ba40();
    ~PositionedBitmapDescriptorState_0040ba40();
};

struct HuntResultsDialogState_004023b0_Product {
    PositionedBitmapDescriptorState_0040ba40 primary_button_up;
    PositionedBitmapDescriptorState_0040ba40 primary_button_down;
    int selected_result;

    HuntResultsDialogState_004023b0_Product();
};

struct GuideBookIndexDialogState_0040ae50_Product {
    PositionedBitmapDescriptorState_0040ba40 previous_button_up;
    PositionedBitmapDescriptorState_0040ba40 previous_button_down;
    PositionedBitmapDescriptorState_0040ba40 next_button_up;
    PositionedBitmapDescriptorState_0040ba40 next_button_down;

    GuideBookIndexDialogState_0040ae50_Product();
};

struct IntroDialogState_0040bb30_Product {
    PositionedBitmapDescriptorState_0040ba40 button_0_up;
    PositionedBitmapDescriptorState_0040ba40 button_0_down;
    PositionedBitmapDescriptorState_0040ba40 button_1_up;
    PositionedBitmapDescriptorState_0040ba40 button_1_down;
    PositionedBitmapDescriptorState_0040ba40 button_2_up;
    PositionedBitmapDescriptorState_0040ba40 button_2_down;

    IntroDialogState_0040bb30_Product();
};

struct TradeSelectionDialogState_0040ded0_Product {
    PositionedBitmapDescriptorState_0040ba40 okay_button_up;
    PositionedBitmapDescriptorState_0040ba40 okay_button_down;
    PositionedBitmapDescriptorState_0040ba40 cancel_button_up;
    PositionedBitmapDescriptorState_0040ba40 cancel_button_down;
    int* accepted_result;

    TradeSelectionDialogState_0040ded0_Product();
};

struct WillametteValleyArrivalDialogState_0040fee0_Product {
    PositionedBitmapDescriptorState_0040ba40 bitmap_0;
    PositionedBitmapDescriptorState_0040ba40 bitmap_1;
    PositionedBitmapDescriptorState_0040ba40 bitmap_2;

    WillametteValleyArrivalDialogState_0040fee0_Product();
};

struct EpitaphDialogState_004116e0_Product {
    PositionedBitmapDescriptorState_0040ba40 okay_button_up;
    PositionedBitmapDescriptorState_0040ba40 okay_button_down;
    PositionedBitmapDescriptorState_0040ba40 cancel_button_up;
    PositionedBitmapDescriptorState_0040ba40 cancel_button_down;

    EpitaphDialogState_004116e0_Product();
};

struct AboutDialogState_0041afa0_Product {
    PositionedBitmapDescriptorState_0040ba40 close_button_up;
    PositionedBitmapDescriptorState_0040ba40 close_button_down;

    AboutDialogState_0041afa0_Product();
};

struct StatusDialogState_0041d040_Product {
    PositionedBitmapDescriptorState_0040ba40 close_button_up;
    PositionedBitmapDescriptorState_0040ba40 close_button_down;

    StatusDialogState_0041d040_Product();
};

struct DropSuppliesDialogState_0041ead0_Product {
    PositionedBitmapDescriptorState_0040ba40 okay_button_up;
    PositionedBitmapDescriptorState_0040ba40 okay_button_down;
    PositionedBitmapDescriptorState_0040ba40 cancel_button_up;
    PositionedBitmapDescriptorState_0040ba40 cancel_button_down;

    DropSuppliesDialogState_0041ead0_Product();
};

struct RiverCrossingHelpDialogState_00423880_Product {
    PositionedBitmapDescriptorState_0040ba40 close_button_up;
    PositionedBitmapDescriptorState_0040ba40 close_button_down;

    RiverCrossingHelpDialogState_00423880_Product();
};

struct OccupationInfoDialogState_00429c50_Product {
    PositionedBitmapDescriptorState_0040ba40 close_button_up;
    PositionedBitmapDescriptorState_0040ba40 close_button_down;

    OccupationInfoDialogState_00429c50_Product();
};
#pragma pack(pop)

typedef char OtDialogBitmapStateElementSizeMustBe28[
    sizeof(PositionedBitmapDescriptorState_0040ba40) == 0x28 ? 1 : -1];
typedef char OtHuntResultsDialogStateSizeMustBe54[
    sizeof(HuntResultsDialogState_004023b0_Product) == 0x54 ? 1 : -1];
typedef char OtGuideBookIndexDialogStateSizeMustBeA0[
    sizeof(GuideBookIndexDialogState_0040ae50_Product) == 0xa0 ? 1 : -1];
typedef char OtIntroDialogStateSizeMustBeF0[
    sizeof(IntroDialogState_0040bb30_Product) == 0xf0 ? 1 : -1];
typedef char OtTradeSelectionResultOffsetMustBeA0[
    (unsigned int)&(((TradeSelectionDialogState_0040ded0_Product*)0)->
        accepted_result) == 0xa0
        ? 1
        : -1];
typedef char OtTradeSelectionDialogStateSizeMustBeA4[
    sizeof(TradeSelectionDialogState_0040ded0_Product) == 0xa4 ? 1 : -1];
typedef char OtWillametteArrivalDialogStateSizeMustBe78[
    sizeof(WillametteValleyArrivalDialogState_0040fee0_Product) == 0x78
        ? 1
        : -1];
typedef char OtEpitaphDialogStateSizeMustBeA0[
    sizeof(EpitaphDialogState_004116e0_Product) == 0xa0 ? 1 : -1];
typedef char OtAboutDialogStateSizeMustBe50[
    sizeof(AboutDialogState_0041afa0_Product) == 0x50 ? 1 : -1];
typedef char OtStatusDialogStateSizeMustBe50[
    sizeof(StatusDialogState_0041d040_Product) == 0x50 ? 1 : -1];
typedef char OtDropSuppliesDialogStateSizeMustBeA0[
    sizeof(DropSuppliesDialogState_0041ead0_Product) == 0xa0 ? 1 : -1];
typedef char OtRiverHelpDialogStateSizeMustBe50[
    sizeof(RiverCrossingHelpDialogState_00423880_Product) == 0x50 ? 1 : -1];
typedef char OtOccupationInfoDialogStateSizeMustBe50[
    sizeof(OccupationInfoDialogState_00429c50_Product) == 0x50 ? 1 : -1];

#pragma optimize("s", off)
#pragma optimize("t", on)

HuntResultsDialogState_004023b0_Product::
    HuntResultsDialogState_004023b0_Product()
{
}

GuideBookIndexDialogState_0040ae50_Product::
    GuideBookIndexDialogState_0040ae50_Product()
{
}

IntroDialogState_0040bb30_Product::IntroDialogState_0040bb30_Product()
{
}

TradeSelectionDialogState_0040ded0_Product::
    TradeSelectionDialogState_0040ded0_Product()
{
}

WillametteValleyArrivalDialogState_0040fee0_Product::
    WillametteValleyArrivalDialogState_0040fee0_Product()
{
}

EpitaphDialogState_004116e0_Product::EpitaphDialogState_004116e0_Product()
{
}

AboutDialogState_0041afa0_Product::AboutDialogState_0041afa0_Product()
{
}

StatusDialogState_0041d040_Product::StatusDialogState_0041d040_Product()
{
}

DropSuppliesDialogState_0041ead0_Product::
    DropSuppliesDialogState_0041ead0_Product()
{
}

RiverCrossingHelpDialogState_00423880_Product::
    RiverCrossingHelpDialogState_00423880_Product()
{
}

OccupationInfoDialogState_00429c50_Product::
    OccupationInfoDialogState_00429c50_Product()
{
}

#pragma optimize("", on)
