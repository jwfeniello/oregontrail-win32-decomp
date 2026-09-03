// Product-tree semantic closure for FUN_004038d0_000038d0.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#pragma pack(push, 1)
struct Rect_004038d0 {
    long left;
    long top;
    long right;
    long bottom;
};

struct PositionedBitmap_004038d0 {
    unsigned long bitmap_info_handle;
    unsigned long indexed_pixels_handle;
    unsigned long bitmap_info;
    unsigned long indexed_pixels;
    short x;
    short y;
    short width;
    short height;
    int left;
    int top;
    int right;
    int bottom;

    static void* __cdecl operator new(unsigned int bytes);
    static void __cdecl operator delete(void* object);

    PositionedBitmap_004038d0(void* module, unsigned int descriptor_id);
    int OtLoadPositionedBitmapDescriptorDependency_004038d0(
        void* module,
        unsigned int descriptor_id);
};

struct PositionedBitmapDescriptorState_0040ba40 {
    int OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
        void* module,
        short descriptor_id);
};

struct StringResourceGroupOwner_004038d0 {
    char reserved_000[4];
    void* window;
    char reserved_008[0xac];
    PositionedBitmap_004038d0* owned_bitmap;

    void OtStringResourceGroupLoad_004038d0_RealCpp();
};
#pragma pack(pop)

extern "C" __declspec(dllimport) int __stdcall GetClientRect(
    void* window,
    Rect_004038d0* rect);

extern "C" void* g_resourceModule;
extern "C" void* __cdecl OtAllocateNewBlock_RealCpp(unsigned int bytes);
void __cdecl operator delete(void* object);

#pragma optimize("s", off)
#pragma optimize("t", on)

#pragma code_seg(".otsem")
void* __cdecl PositionedBitmap_004038d0::operator new(unsigned int bytes)
{
    return OtAllocateNewBlock_RealCpp(bytes);
}

void __cdecl PositionedBitmap_004038d0::operator delete(void* object)
{
    ::operator delete(object);
}

int PositionedBitmap_004038d0::
    OtLoadPositionedBitmapDescriptorDependency_004038d0(
        void* module,
        unsigned int descriptor_id)
{
    return reinterpret_cast<PositionedBitmapDescriptorState_0040ba40*>(this)->
        OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            module,
            static_cast<short>(descriptor_id));
}

PositionedBitmap_004038d0::PositionedBitmap_004038d0(
    void* module,
    unsigned int descriptor_id)
{
    bitmap_info_handle = 0;
    indexed_pixels_handle = 0;
    indexed_pixels = 0;
    bitmap_info = 0;
    OtLoadPositionedBitmapDescriptorDependency_004038d0(module, descriptor_id);
}
#pragma code_seg()

void StringResourceGroupOwner_004038d0::
    OtStringResourceGroupLoad_004038d0_RealCpp()
{
    Rect_004038d0 client_rect;
    register StringResourceGroupOwner_004038d0* owner = this;

    GetClientRect(owner->window, &client_rect);

    register PositionedBitmap_004038d0* bitmap =
        new PositionedBitmap_004038d0(g_resourceModule, 0x0bbc);

    int client_bottom = client_rect.bottom;
    owner->owned_bitmap = bitmap;

    if (client_bottom - client_rect.top - 0x14 < bitmap->height) {
        bitmap->height =
            (short)client_rect.bottom - (short)client_rect.top - 0x14;
        bitmap = owner->owned_bitmap;
        bitmap->bottom = bitmap->height + bitmap->top;
    }

    if (client_rect.right - client_rect.left - 0x14 <
        owner->owned_bitmap->width) {
        owner->owned_bitmap->width =
            (short)client_rect.right - (short)client_rect.left - 0x14;
        owner->owned_bitmap->right =
            owner->owned_bitmap->width + owner->owned_bitmap->left;
    }
}

#pragma optimize("", on)
