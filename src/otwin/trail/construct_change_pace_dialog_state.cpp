// Product-semantic constructor for the Change Pace dialog bitmap state used
// by OtChangePaceDialogProc (0x004206a0).

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

struct ChangePaceDialogState_004206a0_Product {
    int selected_pace;
    PositionedBitmapDescriptorState_0040ba40 choice_0_up;
    PositionedBitmapDescriptorState_0040ba40 choice_0_down;
    PositionedBitmapDescriptorState_0040ba40 choice_1_up;
    PositionedBitmapDescriptorState_0040ba40 choice_1_down;
    PositionedBitmapDescriptorState_0040ba40 choice_2_up;
    PositionedBitmapDescriptorState_0040ba40 choice_2_down;
    PositionedBitmapDescriptorState_0040ba40 confirm_up;
    PositionedBitmapDescriptorState_0040ba40 confirm_down;

    ChangePaceDialogState_004206a0_Product();
};
#pragma pack(pop)

typedef char OtChangePaceBitmapSizeMustBe40[
    sizeof(PositionedBitmapDescriptorState_0040ba40) == 0x28 ? 1 : -1];
typedef char OtChangePaceFirstBitmapOffsetMustBe4[
    (unsigned int)&(((ChangePaceDialogState_004206a0_Product*)0)->
        choice_0_up) == 0x004
        ? 1
        : -1];
typedef char OtChangePaceLastBitmapOffsetMustBe11c[
    (unsigned int)&(((ChangePaceDialogState_004206a0_Product*)0)->
        confirm_down) == 0x11c
        ? 1
        : -1];
typedef char OtChangePaceDialogStateSizeMustBe144[
    sizeof(ChangePaceDialogState_004206a0_Product) == 0x144 ? 1 : -1];

#pragma optimize("s", off)
#pragma optimize("t", on)

ChangePaceDialogState_004206a0_Product::
    ChangePaceDialogState_004206a0_Product()
{
}

#pragma optimize("", on)
