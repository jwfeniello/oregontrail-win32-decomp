// Product-semantic constructor for the trail-game dialog state @ 0x0042efa0.

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

struct RectResource_0040b690 {
    int left;
    int top;
    int right;
    int bottom;

    RectResource_0040b690();
};

struct TrailGameDialogState_0042efa0_Product {
    int timer_tick;
    int timer_phase;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_00;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_01;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_02;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_03;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_04;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_05;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_06;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_07;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_08;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_09;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_10;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_11;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_12;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_13;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_14;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_15;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_16;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_17;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_18;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_19;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_20;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_21;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_22;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_23;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_24;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_25;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_26;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_27;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_28;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_29;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_30;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_31;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_32;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_33;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_34;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_35;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_36;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_37;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_38;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_39;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_40;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_41;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_42;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_43;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_44;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_45;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_46;
    PositionedBitmapDescriptorState_0040ba40 action_bitmap_47;
    void* landmark_display;
    void* map_composite;
    RectResource_0040b690 progress_rect;
    PositionedBitmapDescriptorState_0040ba40 progress_frames[12];
    PositionedBitmapDescriptorState_0040ba40 progress_overlay;
    char reserved_9a8[0x38];
    PositionedBitmapDescriptorState_0040ba40 route_audio_bitmap;
    unsigned int timer_handle;
    void* trail_journal;
    void* travel_viewport;
    int reserved_a14;
    int route_transition_pending;
    int travel_submode;
    int river_crossing_mode;
    int active_action;
    int hovered_action;
    int action_controls_ready;
    int scene_initialized;
    int distance_per_day;
    int terrain_distance_per_day;
    int metric_a;
    int metric_b;
    int metric_unused;
    int redraw_pending;
    int food_cost_per_day;
    int food_cost_per_member;
    int travel_metric_mode;

    TrailGameDialogState_0042efa0_Product();
};
#pragma pack(pop)

typedef char OtTrailGameCtorFirstBitmapOffset[
    (unsigned int)&(((TrailGameDialogState_0042efa0_Product*)0)->
        action_bitmap_00) == 0x8
        ? 1
        : -1];
typedef char OtTrailGameCtorLastActionBitmapOffset[
    (unsigned int)&(((TrailGameDialogState_0042efa0_Product*)0)->
        action_bitmap_47) == 0x760
        ? 1
        : -1];
typedef char OtTrailGameCtorProgressFramesOffset[
    (unsigned int)&(((TrailGameDialogState_0042efa0_Product*)0)->
        progress_frames) == 0x7a0
        ? 1
        : -1];
typedef char OtTrailGameCtorProgressOverlayOffset[
    (unsigned int)&(((TrailGameDialogState_0042efa0_Product*)0)->
        progress_overlay) == 0x980
        ? 1
        : -1];
typedef char OtTrailGameCtorRouteAudioOffset[
    (unsigned int)&(((TrailGameDialogState_0042efa0_Product*)0)->
        route_audio_bitmap) == 0x9e0
        ? 1
        : -1];
typedef char OtTrailGameCtorStateSize[
    sizeof(TrailGameDialogState_0042efa0_Product) == 0xa58 ? 1 : -1];

#pragma optimize("s", off)
#pragma optimize("t", on)

TrailGameDialogState_0042efa0_Product::
    TrailGameDialogState_0042efa0_Product()
{
}

#pragma optimize("", on)
