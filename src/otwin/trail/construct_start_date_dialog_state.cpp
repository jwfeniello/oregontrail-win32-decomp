// Product-semantic constructor for the Start Date dialog bitmap state used by
// OtStartDateDialogProc (0x00423da0) and OtInitStartDateDialog (0x00424730).

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

struct StartDateDialogState_00423da0_Product {
    PositionedBitmapDescriptorState_0040ba40 play_audio_up;
    PositionedBitmapDescriptorState_0040ba40 play_audio_down;
    PositionedBitmapDescriptorState_0040ba40 stop_audio_up;
    PositionedBitmapDescriptorState_0040ba40 stop_audio_down;
    PositionedBitmapDescriptorState_0040ba40 date_choice_0_up;
    PositionedBitmapDescriptorState_0040ba40 date_choice_0_down;
    PositionedBitmapDescriptorState_0040ba40 date_choice_1_up;
    PositionedBitmapDescriptorState_0040ba40 date_choice_1_down;
    PositionedBitmapDescriptorState_0040ba40 date_choice_2_up;
    PositionedBitmapDescriptorState_0040ba40 date_choice_2_down;
    PositionedBitmapDescriptorState_0040ba40 date_choice_3_up;
    PositionedBitmapDescriptorState_0040ba40 date_choice_3_down;
    PositionedBitmapDescriptorState_0040ba40 date_choice_4_up;
    PositionedBitmapDescriptorState_0040ba40 date_choice_4_down;
    PositionedBitmapDescriptorState_0040ba40 date_choice_5_up;
    PositionedBitmapDescriptorState_0040ba40 date_choice_5_down;
    PositionedBitmapDescriptorState_0040ba40 continue_up;
    PositionedBitmapDescriptorState_0040ba40 continue_down;
    PositionedBitmapDescriptorState_0040ba40 selected_date_marker;

    StartDateDialogState_00423da0_Product();
};
#pragma pack(pop)

typedef char OtStartDateBitmapSizeMustBe40[
    sizeof(PositionedBitmapDescriptorState_0040ba40) == 0x28 ? 1 : -1];
typedef char OtStartDateMarkerOffsetMustBe2d0[
    (unsigned int)&(((StartDateDialogState_00423da0_Product*)0)->
        selected_date_marker) == 0x2d0
        ? 1
        : -1];
typedef char OtStartDateDialogStateSizeMustBe2f8[
    sizeof(StartDateDialogState_00423da0_Product) == 0x2f8 ? 1 : -1];

#pragma optimize("s", off)
#pragma optimize("t", on)

StartDateDialogState_00423da0_Product::
    StartDateDialogState_00423da0_Product()
{
}

#pragma optimize("", on)
