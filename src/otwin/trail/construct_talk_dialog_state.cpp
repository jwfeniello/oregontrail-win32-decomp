// Product-semantic constructor for the Talk dialog bitmap state used by
// OtTalkDialogProc (0x00421020).

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

struct TalkDialogState_00421020_Product {
    PositionedBitmapDescriptorState_0040ba40 play_audio_up;
    PositionedBitmapDescriptorState_0040ba40 play_audio_down;
    PositionedBitmapDescriptorState_0040ba40 stop_audio_up;
    PositionedBitmapDescriptorState_0040ba40 stop_audio_down;
    PositionedBitmapDescriptorState_0040ba40 close_up;
    PositionedBitmapDescriptorState_0040ba40 close_down;
    PositionedBitmapDescriptorState_0040ba40 dialog_backdrop;
    PositionedBitmapDescriptorState_0040ba40 speaker_portrait;
    int talk_variant;

    TalkDialogState_00421020_Product();
};
#pragma pack(pop)

typedef char OtTalkBitmapSizeMustBe40[
    sizeof(PositionedBitmapDescriptorState_0040ba40) == 0x28 ? 1 : -1];
typedef char OtTalkLastBitmapOffsetMustBe118[
    (unsigned int)&(((TalkDialogState_00421020_Product*)0)->speaker_portrait) ==
            0x118
        ? 1
        : -1];
typedef char OtTalkVariantOffsetMustBe140[
    (unsigned int)&(((TalkDialogState_00421020_Product*)0)->talk_variant) ==
            0x140
        ? 1
        : -1];
typedef char OtTalkDialogStateSizeMustBe144[
    sizeof(TalkDialogState_00421020_Product) == 0x144 ? 1 : -1];

#pragma optimize("s", off)
#pragma optimize("t", on)

TalkDialogState_00421020_Product::TalkDialogState_00421020_Product()
{
}

#pragma optimize("", on)
