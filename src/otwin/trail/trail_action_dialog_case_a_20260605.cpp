// Product-tree semantic candidate for FUN_0042bb00 / trail action dialog case A.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#pragma pack(push, 1)
struct IndexedBitmapWidth_0042bb00_20260605 {
    unsigned long size;
    int width;
};

struct PositionedBitmap_0040b7b0_Semantic {
    unsigned long bitmap_info_handle;
    unsigned long indexed_pixels_handle;
    IndexedBitmapWidth_0042bb00_20260605* bitmap_info;
    unsigned char* indexed_pixels;
    short x;
    short y;
    short width;
    short height;
    int x_mirror;
    int y_mirror;
    int right;
    int bottom;

    int OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
        void* dc,
        int source_x,
        int source_y);
};

struct TrailActionControlBitmapSet_0042bb00_20260605 {
    PositionedBitmap_0040b7b0_Semantic state_c;
    PositionedBitmap_0040b7b0_Semantic state_b;
    PositionedBitmap_0040b7b0_Semantic state_a;
};

struct TrailActionDialogCaseA_0042bb00_20260605 {
    char reserved_000[0x08];
    TrailActionControlBitmapSet_0042bb00_20260605 drop_supplies;
    TrailActionControlBitmapSet_0042bb00_20260605 guide_book;
    TrailActionControlBitmapSet_0042bb00_20260605 status;
    TrailActionControlBitmapSet_0042bb00_20260605 ration_meager;
    TrailActionControlBitmapSet_0042bb00_20260605 ration_bare_bones;
    TrailActionControlBitmapSet_0042bb00_20260605 ration_filling;
    TrailActionControlBitmapSet_0042bb00_20260605 store;
    TrailActionControlBitmapSet_0042bb00_20260605 trade;
    TrailActionControlBitmapSet_0042bb00_20260605 talk;
    TrailActionControlBitmapSet_0042bb00_20260605 rest;
    TrailActionControlBitmapSet_0042bb00_20260605 pace_steady;
    TrailActionControlBitmapSet_0042bb00_20260605 pace_strenuous;
    TrailActionControlBitmapSet_0042bb00_20260605 pace_grueling;
    TrailActionControlBitmapSet_0042bb00_20260605 stop_continue;
    TrailActionControlBitmapSet_0042bb00_20260605 travel;
    TrailActionControlBitmapSet_0042bb00_20260605 pause;

    void OtTrailActionDialogCaseA_20260605_RealCpp(
        void* dc,
        unsigned int command);
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

void TrailActionDialogCaseA_0042bb00_20260605::
    OtTrailActionDialogCaseA_20260605_RealCpp(
        void* dc,
        unsigned int command)
{
    switch (command) {
    case 0x0fd2:
        travel.state_a.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        return;
    case 0x0fd3:
        pause.state_a.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        return;
    case 0x0fd4:
        drop_supplies.state_a.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        return;
    case 0x0fd5:
        guide_book.state_a.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        return;
    case 0x0fd6:
        status.state_a.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        return;
    case 0x0fd7:
        ration_meager.state_a.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        return;
    case 0x0fd8:
        ration_bare_bones.state_a.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        return;
    case 0x0fd9:
        ration_filling.state_a.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        return;
    case 0x0fda:
        store.state_a.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        return;
    case 0x0fdb:
        trade.state_a.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        return;
    case 0x0fdc:
        talk.state_a.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        return;
    case 0x0fdd:
        rest.state_a.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        return;
    case 0x0fde:
        pace_steady.state_a.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        return;
    case 0x0fdf:
        pace_strenuous.state_a.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        return;
    case 0x0fe0:
        pace_grueling.state_a.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        return;
    case 0x0fe1:
        stop_continue.state_a.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(dc, 0, 0);
        return;
    }
}

#pragma optimize("", on)
