// Product-semantic constructor for the Guide Book dialog bitmap state used by
// OtGuideBookDialogProc (0x00409e50).

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

struct GuideBookDialogState_00409e50_Product {
    PositionedBitmapDescriptorState_0040ba40 previous_page_up;
    PositionedBitmapDescriptorState_0040ba40 previous_page_down;
    PositionedBitmapDescriptorState_0040ba40 next_page_up;
    PositionedBitmapDescriptorState_0040ba40 next_page_down;
    PositionedBitmapDescriptorState_0040ba40 contents_up;
    PositionedBitmapDescriptorState_0040ba40 contents_down;
    PositionedBitmapDescriptorState_0040ba40 play_audio_up;
    PositionedBitmapDescriptorState_0040ba40 play_audio_down;
    PositionedBitmapDescriptorState_0040ba40 stop_audio_up;
    PositionedBitmapDescriptorState_0040ba40 stop_audio_down;
    PositionedBitmapDescriptorState_0040ba40 close_up;
    PositionedBitmapDescriptorState_0040ba40 close_down;

    GuideBookDialogState_00409e50_Product();
};
#pragma pack(pop)

typedef char OtGuideBookBitmapSizeMustBe40[
    sizeof(PositionedBitmapDescriptorState_0040ba40) == 0x28 ? 1 : -1];
typedef char OtGuideBookLastBitmapOffsetMustBe1b8[
    (unsigned int)&(((GuideBookDialogState_00409e50_Product*)0)->close_down) ==
            0x1b8
        ? 1
        : -1];
typedef char OtGuideBookDialogStateSizeMustBe1e0[
    sizeof(GuideBookDialogState_00409e50_Product) == 0x1e0 ? 1 : -1];

#pragma optimize("s", off)
#pragma optimize("t", on)

GuideBookDialogState_00409e50_Product::
    GuideBookDialogState_00409e50_Product()
{
}

#pragma optimize("", on)
