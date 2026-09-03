#ifndef OTWIN_HUNT_DIALOG_STATE_CONSTRUCTOR_H
#define OTWIN_HUNT_DIALOG_STATE_CONSTRUCTOR_H

#pragma pack(push, 1)
struct PositionedBitmapDescriptorState_0040ba40 {
    char reserved_00[0x10];
    short left;
    short top;
    short width;
    short height;
    int left_int;
    int top_int;
    int right;
    int bottom;

    PositionedBitmapDescriptorState_0040ba40();
    ~PositionedBitmapDescriptorState_0040ba40();

    int OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
        void* module,
        short descriptor_id);
};

struct HuntDialogState_00415380_SetupWip {
    char reserved_000[0xa8];
    int paint_ready;
    int active;
    int cursor_zone;
    int command_pressed;
    void* dc;
    PositionedBitmapDescriptorState_0040ba40 next_button;
    PositionedBitmapDescriptorState_0040ba40 start_button;
    PositionedBitmapDescriptorState_0040ba40 action_button;
    PositionedBitmapDescriptorState_0040ba40 disabled_button;
    char reserved_15c[0x70];

    HuntDialogState_00415380_SetupWip();
};
#pragma pack(pop)

#endif
