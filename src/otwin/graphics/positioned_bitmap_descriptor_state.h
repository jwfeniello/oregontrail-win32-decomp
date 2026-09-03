#ifndef OTWIN_GRAPHICS_POSITIONED_BITMAP_DESCRIPTOR_STATE_H
#define OTWIN_GRAPHICS_POSITIONED_BITMAP_DESCRIPTOR_STATE_H

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This recovered Product state requires 32-bit Microsoft C++."
#endif

#pragma pack(push, 1)
struct BitmapInfoHeader_0040b870_ProductWip {
    unsigned int size;
    int width;
    int height;
    unsigned short planes;
    unsigned short bit_count;
    unsigned int compression;
    unsigned int size_image;
    int x_pels_per_meter;
    int y_pels_per_meter;
    unsigned int colors_used;
    unsigned int colors_important;
};

struct PositionedBitmapDescriptorState_0040ba40 {
    void* bitmap_info_handle;
    void* indexed_pixels_handle;
    BitmapInfoHeader_0040b870_ProductWip* bitmap_info;
    unsigned char* indexed_pixels;
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

    int OtLoadIndexedBitmapFromResourceDependency_0040ba40(
        void* module,
        short bitmap_resource_id,
        short left_value,
        short top_value,
        short width_value,
        short height_value);
    int OtLoadIndexedBitmapFromResource_0040b870_ProductWip(
        void* module,
        short bitmap_resource_id,
        short left_value,
        short top_value,
        short width_value,
        short height_value);
    int OtLoadIndexedBitmapFromResource_0040b870_ProductWip(
        void* module,
        unsigned short bitmap_resource_id,
        short left_value,
        short top_value,
        short width_value,
        short height_value);
    int OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
        void* module,
        short descriptor_id);
};

struct RectResource_0040b690 {
    long left;
    long top;
    long right;
    long bottom;

    RectResource_0040b690();

    int OtLoadRectFromResource_RealCpp(
        void* module,
        const void* resource_id);
};
#pragma pack(pop)

typedef char OtPositionedBitmapDescriptorSizeMustBe028[
    sizeof(PositionedBitmapDescriptorState_0040ba40) == 0x28 ? 1 : -1];
typedef char OtRectResourceSizeMustBe010[
    sizeof(RectResource_0040b690) == 0x10 ? 1 : -1];

#endif
