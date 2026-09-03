// Product-semantic constructor for the Change Rations dialog bitmap state
// used by OtChangeRationsDialogProc (0x0041fd20).

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

struct ChangeRationsDialogState_0041fd20_Product {
    int selected_ration;
    PositionedBitmapDescriptorState_0040ba40 choice_0_up;
    PositionedBitmapDescriptorState_0040ba40 choice_0_down;
    PositionedBitmapDescriptorState_0040ba40 choice_1_up;
    PositionedBitmapDescriptorState_0040ba40 choice_1_down;
    PositionedBitmapDescriptorState_0040ba40 choice_2_up;
    PositionedBitmapDescriptorState_0040ba40 choice_2_down;
    PositionedBitmapDescriptorState_0040ba40 confirm_up;
    PositionedBitmapDescriptorState_0040ba40 confirm_down;

    ChangeRationsDialogState_0041fd20_Product();
};
#pragma pack(pop)

typedef char OtChangeRationsBitmapSizeMustBe40[
    sizeof(PositionedBitmapDescriptorState_0040ba40) == 0x28 ? 1 : -1];
typedef char OtChangeRationsFirstBitmapOffsetMustBe4[
    (unsigned int)&(((ChangeRationsDialogState_0041fd20_Product*)0)->
        choice_0_up) == 0x004
        ? 1
        : -1];
typedef char OtChangeRationsLastBitmapOffsetMustBe11c[
    (unsigned int)&(((ChangeRationsDialogState_0041fd20_Product*)0)->
        confirm_down) == 0x11c
        ? 1
        : -1];
typedef char OtChangeRationsDialogStateSizeMustBe144[
    sizeof(ChangeRationsDialogState_0041fd20_Product) == 0x144 ? 1 : -1];

#pragma optimize("s", off)
#pragma optimize("t", on)

ChangeRationsDialogState_0041fd20_Product::
    ChangeRationsDialogState_0041fd20_Product()
{
}

#pragma optimize("", on)
