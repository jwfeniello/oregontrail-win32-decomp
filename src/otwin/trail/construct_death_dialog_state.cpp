// Product-semantic constructor for the Death dialog bitmap state used by
// OtDeathDialogProc (0x00410da0).

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

struct DeathDialogState_00410da0_Product {
    PositionedBitmapDescriptorState_0040ba40 bitmap_0;
    PositionedBitmapDescriptorState_0040ba40 bitmap_1;
    PositionedBitmapDescriptorState_0040ba40 bitmap_2;
    PositionedBitmapDescriptorState_0040ba40 bitmap_3;
    PositionedBitmapDescriptorState_0040ba40 bitmap_4;
    PositionedBitmapDescriptorState_0040ba40 bitmap_5;
    PositionedBitmapDescriptorState_0040ba40 bitmap_6;

    DeathDialogState_00410da0_Product();
};
#pragma pack(pop)

typedef char OtDeathBitmapSizeMustBe40[
    sizeof(PositionedBitmapDescriptorState_0040ba40) == 0x28 ? 1 : -1];
typedef char OtDeathLastBitmapOffsetMustBef0[
    (unsigned int)&(((DeathDialogState_00410da0_Product*)0)->bitmap_6) == 0x0f0
        ? 1
        : -1];
typedef char OtDeathDialogStateSizeMustBe118[
    sizeof(DeathDialogState_00410da0_Product) == 0x118 ? 1 : -1];

#pragma optimize("s", off)
#pragma optimize("t", on)

DeathDialogState_00410da0_Product::DeathDialogState_00410da0_Product()
{
}

#pragma optimize("", on)
