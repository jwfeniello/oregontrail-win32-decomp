// Product-semantic constructor for the Rest dialog bitmap state used by
// OtRestDialogProc (0x0041e370).

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

struct RestDialogState_0041e370_Product {
    PositionedBitmapDescriptorState_0040ba40 decrease_days_up;
    PositionedBitmapDescriptorState_0040ba40 decrease_days_down;
    PositionedBitmapDescriptorState_0040ba40 increase_days_up;
    PositionedBitmapDescriptorState_0040ba40 increase_days_down;

    RestDialogState_0041e370_Product();
};
#pragma pack(pop)

typedef char OtRestBitmapSizeMustBe40[
    sizeof(PositionedBitmapDescriptorState_0040ba40) == 0x28 ? 1 : -1];
typedef char OtRestLastBitmapOffsetMustBe78[
    (unsigned int)&(((RestDialogState_0041e370_Product*)0)->
        increase_days_down) == 0x078
        ? 1
        : -1];
typedef char OtRestDialogStateSizeMustBea0[
    sizeof(RestDialogState_0041e370_Product) == 0x0a0 ? 1 : -1];

#pragma optimize("s", off)
#pragma optimize("t", on)

RestDialogState_0041e370_Product::RestDialogState_0041e370_Product()
{
}

#pragma optimize("", on)
