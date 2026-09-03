// Product-semantic constructor for the River Crossing Choice dialog state
// used by OtRiverCrossingChoiceDialogProc (0x004229e0).

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

struct RiverCrossingChoiceDialogState_004229e0_Product {
    short* selected_choice;
    PositionedBitmapDescriptorState_0040ba40 ford_up;
    PositionedBitmapDescriptorState_0040ba40 ford_down;
    PositionedBitmapDescriptorState_0040ba40 caulk_and_float_up;
    PositionedBitmapDescriptorState_0040ba40 caulk_and_float_down;
    PositionedBitmapDescriptorState_0040ba40 ferry_up;
    PositionedBitmapDescriptorState_0040ba40 ferry_down;
    PositionedBitmapDescriptorState_0040ba40 hire_guide_up;
    PositionedBitmapDescriptorState_0040ba40 hire_guide_down;
    PositionedBitmapDescriptorState_0040ba40 wait_up;
    PositionedBitmapDescriptorState_0040ba40 wait_down;
    PositionedBitmapDescriptorState_0040ba40 help_up;
    PositionedBitmapDescriptorState_0040ba40 help_down;
    PositionedBitmapDescriptorState_0040ba40 cancel_up;
    PositionedBitmapDescriptorState_0040ba40 cancel_down;

    RiverCrossingChoiceDialogState_004229e0_Product();
};
#pragma pack(pop)

typedef char OtRiverChoiceBitmapSizeMustBe40[
    sizeof(PositionedBitmapDescriptorState_0040ba40) == 0x28 ? 1 : -1];
typedef char OtRiverChoiceFirstBitmapOffsetMustBe4[
    (unsigned int)&(((RiverCrossingChoiceDialogState_004229e0_Product*)0)->
        ford_up) == 0x4
        ? 1
        : -1];
typedef char OtRiverChoiceLastBitmapOffsetMustBe20c[
    (unsigned int)&(((RiverCrossingChoiceDialogState_004229e0_Product*)0)->
        cancel_down) == 0x20c
        ? 1
        : -1];
typedef char OtRiverChoiceDialogStateSizeMustBe234[
    sizeof(RiverCrossingChoiceDialogState_004229e0_Product) == 0x234 ? 1 : -1];

#pragma optimize("s", off)
#pragma optimize("t", on)

RiverCrossingChoiceDialogState_004229e0_Product::
    RiverCrossingChoiceDialogState_004229e0_Product()
{
}

#pragma optimize("", on)
