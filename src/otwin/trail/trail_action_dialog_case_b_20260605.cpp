// Product-tree semantic candidate for FUN_0042bcd0 / trail action dialog case B.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#pragma pack(push, 1)
struct PositionedBitmap_0040b7b0_Semantic {
    char reserved_00[0x28];

    int OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
        void* dc,
        int source_x,
        int source_y);
};

struct TrailActionBitmapSlot_0042bcd0_20260605 {
    PositionedBitmap_0040b7b0_Semantic case_c_bitmap;
    PositionedBitmap_0040b7b0_Semantic case_b_bitmap;
    PositionedBitmap_0040b7b0_Semantic case_a_bitmap;
};

struct TrailActionDialogCaseB_0042bcd0_20260605 {
    char reserved_000[0x08];
    TrailActionBitmapSlot_0042bcd0_20260605 action_bitmaps[16];

    void OtTrailActionDialogCaseB_20260605_RealCpp(
        void* dc,
        int command_id);
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

void TrailActionDialogCaseB_0042bcd0_20260605::
    OtTrailActionDialogCaseB_20260605_RealCpp(
        void* dc,
        int command_id)
{
    switch (command_id) {
    case 0x0fd2:
        action_bitmaps[14].case_b_bitmap.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        return;
    case 0x0fd3:
        action_bitmaps[15].case_b_bitmap.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        return;
    case 0x0fd4:
        action_bitmaps[0].case_b_bitmap.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        return;
    case 0x0fd5:
        action_bitmaps[1].case_b_bitmap.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        return;
    case 0x0fd6:
        action_bitmaps[2].case_b_bitmap.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        return;
    case 0x0fd7:
        action_bitmaps[3].case_b_bitmap.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        return;
    case 0x0fd8:
        action_bitmaps[4].case_b_bitmap.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        return;
    case 0x0fd9:
        action_bitmaps[5].case_b_bitmap.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        return;
    case 0x0fda:
        action_bitmaps[6].case_b_bitmap.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        return;
    case 0x0fdb:
        action_bitmaps[7].case_b_bitmap.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        return;
    case 0x0fdc:
        action_bitmaps[8].case_b_bitmap.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        return;
    case 0x0fdd:
        action_bitmaps[9].case_b_bitmap.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        return;
    case 0x0fde:
        action_bitmaps[10].case_b_bitmap.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        return;
    case 0x0fdf:
        action_bitmaps[11].case_b_bitmap.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        return;
    case 0x0fe0:
        action_bitmaps[12].case_b_bitmap.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        return;
    case 0x0fe1:
        action_bitmaps[13].case_b_bitmap.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        return;
    }
}

#pragma optimize("", on)
