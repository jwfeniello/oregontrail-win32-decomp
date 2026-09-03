// Semantic recovery candidate for loading four positioned string resources.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#pragma pack(push, 1)
struct Rect_00403830 {
    long left;
    long top;
    long right;
    long bottom;
};

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

    int OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
        void* module,
        short descriptor_id);
};

struct FourStringResourceOwner_00403830 {
    char reserved_000[4];
    void* window;
    char reserved_008[0x96];
    short visible_bottom_offset;
    char reserved_0a0[2];
    short baseline_y;
    char reserved_0a4[4];
    int visible_bottom_delta;
    char reserved_0ac[4];
    int visible_bottom;

    void OtLoadFourStringIntoSubResources_00403830_RealCpp();
};
#pragma pack(pop)

extern "C" void* g_resourceModule;
extern "C" __declspec(dllimport) int __stdcall GetClientRect(
    void* window,
    Rect_00403830* rect);

#pragma comment(lib, "user32.lib")

#pragma optimize("s", off)
#pragma optimize("t", on)

void FourStringResourceOwner_00403830::
    OtLoadFourStringIntoSubResources_00403830_RealCpp()
{
    Rect_00403830 client_rect;
    register FourStringResourceOwner_00403830* owner = this;

    GetClientRect(owner->window, &client_rect);

    ((PositionedBitmapDescriptorState_0040ba40*)((char*)owner + 0x14))->
        OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_resourceModule,
            0x0bb8);
    ((PositionedBitmapDescriptorState_0040ba40*)((char*)owner + 0x3c))->
        OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_resourceModule,
            0x0bb9);
    ((PositionedBitmapDescriptorState_0040ba40*)((char*)owner + 0x64))->
        OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_resourceModule,
            0x0bba);
    ((PositionedBitmapDescriptorState_0040ba40*)((char*)owner + 0x8c))->
        OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            g_resourceModule,
            0x0bbb);

    if (client_rect.bottom < owner->visible_bottom) {
        register int bottom_delta = client_rect.bottom - owner->baseline_y;
        owner->visible_bottom_offset = (short)bottom_delta;
        owner->visible_bottom_delta = bottom_delta;
        owner->visible_bottom = client_rect.bottom;
    }
}

#pragma optimize("", on)
