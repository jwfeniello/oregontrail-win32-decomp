// Product-tree semantic closure for OtInitLandmarkDisplay_00005bd0.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

typedef void* HGLOBAL_00405bd0;
typedef void* HMODULE_00405bd0;
typedef void* HMENU_00405bd0;
typedef void* HWND_00405bd0;
typedef void* HRSRC_00405bd0;
typedef const char* LPCSTR_00405bd0;

extern "C" __declspec(dllimport) HRSRC_00405bd0 __stdcall FindResourceA(
    HMODULE_00405bd0 module,
    LPCSTR_00405bd0 resource_name,
    LPCSTR_00405bd0 resource_type);
extern "C" __declspec(dllimport) HGLOBAL_00405bd0 __stdcall LoadResource(
    HMODULE_00405bd0 module,
    HRSRC_00405bd0 resource_info);
extern "C" __declspec(dllimport) void* __stdcall LockResource(
    HGLOBAL_00405bd0 resource);
extern "C" __declspec(dllimport) int __stdcall FreeResource(
    HGLOBAL_00405bd0 resource);
extern "C" __declspec(dllimport) int __stdcall MessageBoxA(
    HWND_00405bd0 window,
    const char* text,
    const char* caption,
    unsigned int type);
extern "C" __declspec(dllimport) void __stdcall PostQuitMessage(
    int exit_code);
extern "C" __declspec(dllimport) int __stdcall LoadStringA(
    HMODULE_00405bd0 instance,
    unsigned int string_id,
    char* buffer,
    int buffer_max);
extern "C" __declspec(dllimport) HWND_00405bd0 __stdcall CreateWindowExA(
    unsigned long ex_style,
    const char* class_name,
    const char* window_name,
    unsigned long style,
    int x,
    int y,
    int width,
    int height,
    HWND_00405bd0 parent,
    HMENU_00405bd0 menu,
    HMODULE_00405bd0 instance,
    void* parameter);

#pragma comment(lib, "kernel32.lib")
#pragma comment(lib, "user32.lib")

extern "C" void* g_resourceModule;
extern "C" void* __cdecl OtAllocateNewBlock_RealCpp(unsigned int bytes);

extern "C" const char g_initLandmarkStaticClass_00405bd0_20260603[] = "STATIC";
extern "C" const char g_initLandmarkLoadErrorText_00405bd0_20260603[] =
    "Can't load resource";
extern "C" const char g_initLandmarkLoadErrorCaption_00405bd0_20260603[] =
    "LandmarkDisplay constructor";

#pragma pack(push, 1)
struct PositionedBitmap_00405bd0_20260603 {
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

    static void* __cdecl operator new(unsigned int bytes);

    PositionedBitmap_00405bd0_20260603(
        HMODULE_00405bd0 module,
        void* descriptor_id);
    PositionedBitmap_00405bd0_20260603*
        OtInitAndLoadPositionedBitmapDependency_00405bd0_20260603(
            HMODULE_00405bd0 module,
            void* descriptor_id);
    int OtLoadIndexedBitmapFromResourceDependency_00405bd0_20260603(
        HMODULE_00405bd0 module,
        unsigned short bitmap_resource_id,
        short x,
        short y,
        unsigned short width,
        unsigned short height);
};

struct LabeledBitmapDisplay_00405bd0_20260603 {
    PositionedBitmap_00405bd0_20260603* image;
    HWND_00405bd0 label_window;
    int reserved_08[2];
    int image_left;
    int image_top;
    int image_right;
    int image_bottom;
    int label_left;
    int label_top;
    int label_right;
    int label_bottom;

    LabeledBitmapDisplay_00405bd0_20260603*
        OtInitLandmarkDisplay_00405bd0_RealCpp(
            HMODULE_00405bd0 module,
            HWND_00405bd0 parent,
            LPCSTR_00405bd0 descriptor_id);
};

struct PositionedBitmapDescriptorState_0040ba40 {
    int OtLoadIndexedBitmapFromResource_0040b870_ProductWip(
        void* module,
        short bitmap_resource_id,
        short left,
        short top,
        short width,
        short height);
    int OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
        void* module,
        short descriptor_id);
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

#pragma code_seg(".otsem")

void* __cdecl PositionedBitmap_00405bd0_20260603::operator new(
    unsigned int bytes)
{
    return OtAllocateNewBlock_RealCpp(bytes);
}

PositionedBitmap_00405bd0_20260603::PositionedBitmap_00405bd0_20260603(
    HMODULE_00405bd0 module,
    void* descriptor_id)
{
    OtInitAndLoadPositionedBitmapDependency_00405bd0_20260603(
        module,
        descriptor_id);
}

PositionedBitmap_00405bd0_20260603*
PositionedBitmap_00405bd0_20260603::
    OtInitAndLoadPositionedBitmapDependency_00405bd0_20260603(
        HMODULE_00405bd0 module,
        void* descriptor_id)
{
    bitmap_info_handle = 0;
    indexed_pixels_handle = 0;
    bitmap_info = 0;
    indexed_pixels = 0;
    reinterpret_cast<PositionedBitmapDescriptorState_0040ba40*>(this)->
        OtLoadPositionedBitmapDescriptor_0040ba40_RealCpp(
            module,
            static_cast<short>(reinterpret_cast<unsigned int>(descriptor_id)));
    return this;
}

int PositionedBitmap_00405bd0_20260603::
    OtLoadIndexedBitmapFromResourceDependency_00405bd0_20260603(
        HMODULE_00405bd0 module,
        unsigned short bitmap_resource_id,
        short left,
        short top,
        unsigned short width,
        unsigned short height)
{
    int result =
        reinterpret_cast<PositionedBitmapDescriptorState_0040ba40*>(this)->
            OtLoadIndexedBitmapFromResource_0040b870_ProductWip(
                module,
                static_cast<short>(bitmap_resource_id),
                left,
                top,
                static_cast<short>(width),
                static_cast<short>(height));
    return result;
}

#pragma code_seg()

LabeledBitmapDisplay_00405bd0_20260603*
LabeledBitmapDisplay_00405bd0_20260603::
    OtInitLandmarkDisplay_00405bd0_RealCpp(
        HMODULE_00405bd0 module,
        HWND_00405bd0 parent,
        LPCSTR_00405bd0 descriptor_id)
{
    register LabeledBitmapDisplay_00405bd0_20260603* display = this;
    register HMODULE_00405bd0 active_module = module;
    register int load_failed = 0;
    register HGLOBAL_00405bd0 descriptor_handle = 0;

    if (descriptor_id != 0) {
        HRSRC_00405bd0 descriptor_resource = FindResourceA(
            active_module,
            descriptor_id,
            (LPCSTR_00405bd0)0x07d3);
        descriptor_handle = LoadResource(active_module, descriptor_resource);
        if (descriptor_handle != 0) {
            goto descriptor_loaded;
        }
    }
    load_failed = 1;

descriptor_loaded:
    if (load_failed != 0) {
        MessageBoxA(
            parent,
            g_initLandmarkLoadErrorText_00405bd0_20260603,
            g_initLandmarkLoadErrorCaption_00405bd0_20260603,
            0);
        PostQuitMessage(0);
    } else {
        register short* descriptor_words =
            (short*)LockResource(descriptor_handle);

        display->image_left = descriptor_words[0];
        display->image_top = descriptor_words[1];
        display->image_right = descriptor_words[0] + descriptor_words[2];
        display->image_bottom = descriptor_words[1] + descriptor_words[3];
        display->label_left = descriptor_words[5];
        display->label_top = descriptor_words[6];
        display->label_right = descriptor_words[7] + descriptor_words[5];
        display->label_bottom = descriptor_words[8] + descriptor_words[6];

        display->image =
            new PositionedBitmap_00405bd0_20260603(active_module, 0);

        display->image
            ->OtLoadIndexedBitmapFromResourceDependency_00405bd0_20260603(
                (HMODULE_00405bd0)g_resourceModule,
                descriptor_words[4],
                descriptor_words[0],
                descriptor_words[1],
                descriptor_words[2],
                descriptor_words[3]);

        char label_text[100];
        LoadStringA(
            (HMODULE_00405bd0)g_resourceModule,
            (unsigned short)descriptor_words[9],
            label_text,
            99);

        register int label_top = display->label_top;
        register int label_left = display->label_left;

        display->label_window = CreateWindowExA(
            0,
            g_initLandmarkStaticClass_00405bd0_20260603,
            label_text,
            0x40000001ul,
            label_left,
            label_top,
            display->label_right - label_left,
            display->label_bottom - label_top,
            parent,
            (HMENU_00405bd0)0x1f40,
            active_module,
            0);

        FreeResource(descriptor_handle);
    }

    return display;
}

#pragma optimize("", on)
