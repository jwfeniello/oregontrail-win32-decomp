#ifndef OTWIN_GRAPHICS_INDEXED_BITMAP_PRIMITIVES_H
#define OTWIN_GRAPHICS_INDEXED_BITMAP_PRIMITIVES_H

namespace otwin {
namespace reconstructed {
namespace graphics {

typedef int BOOL;
typedef unsigned int DWORD;
typedef unsigned int UINT;
typedef unsigned short WORD;
typedef int LONG;
typedef const char* LPCSTR;
typedef void* LPVOID;
typedef void* HMODULE;
typedef void* HRSRC;
typedef void* HGLOBAL;
typedef void* HDC;

const DWORD kBitmapInfoHeaderBytes = 0x28;
const DWORD kPaletteBitmapInfoBytes = 0x228;
const WORD kPaletteIndexCount = 256;
const DWORD kBiRgb = 0;
const UINT kDibPalColors = 1;
const DWORD kRasterOpSrcCopy = 0x00cc0020;
const WORD kResourceTypePositionedBitmapDescriptor = 0x07d2;
const WORD kResourceTypeRawIndexedPixels = 0x000a;
const WORD kResourceTypeRectangleBounds = 0x07da;

#ifndef OTWIN_RECONSTRUCTED_WINAPI
#if defined(_MSC_VER)
#define OTWIN_RECONSTRUCTED_WINAPI __stdcall
#else
#define OTWIN_RECONSTRUCTED_WINAPI
#endif
#endif

extern "C" {
HRSRC OTWIN_RECONSTRUCTED_WINAPI FindResourceA(HMODULE module, LPCSTR resource_name, LPCSTR resource_type);
HGLOBAL OTWIN_RECONSTRUCTED_WINAPI LoadResource(HMODULE module, HRSRC resource_info);
LPVOID OTWIN_RECONSTRUCTED_WINAPI LockResource(HGLOBAL resource_handle);
DWORD OTWIN_RECONSTRUCTED_WINAPI SizeofResource(HMODULE module, HRSRC resource_info);
HGLOBAL OTWIN_RECONSTRUCTED_WINAPI GlobalAlloc(UINT flags, DWORD bytes);
LPVOID OTWIN_RECONSTRUCTED_WINAPI GlobalLock(HGLOBAL handle);
BOOL OTWIN_RECONSTRUCTED_WINAPI GlobalUnlock(HGLOBAL handle);
HGLOBAL OTWIN_RECONSTRUCTED_WINAPI GlobalFree(HGLOBAL handle);
BOOL OTWIN_RECONSTRUCTED_WINAPI FreeResource(HGLOBAL resource_handle);
int OTWIN_RECONSTRUCTED_WINAPI StretchDIBits(
    HDC dc,
    int x_dest,
    int y_dest,
    int dest_width,
    int dest_height,
    int x_src,
    int y_src,
    int src_width,
    int src_height,
    const void* bits,
    const void* bitmap_info,
    UINT usage,
    DWORD raster_op);
}

struct ResourceRect {
    int left;
    int top;
    int right;
    int bottom;
};

struct BitmapInfoHeader {
    DWORD biSize;
    LONG biWidth;
    LONG biHeight;
    WORD biPlanes;
    WORD biBitCount;
    DWORD biCompression;
    DWORD biSizeImage;
    LONG biXPelsPerMeter;
    LONG biYPelsPerMeter;
    DWORD biClrUsed;
    DWORD biClrImportant;
};

typedef char OtBitmapInfoHeaderSizeCheck[
    sizeof(BitmapInfoHeader) == kBitmapInfoHeaderBytes ? 1 : -1];

struct IndexedBitmapInfo256 {
    BitmapInfoHeader bmiHeader;
    WORD palette_indexes[kPaletteIndexCount];
};

typedef char OtIndexedBitmapInfo256SizeCheck[
    sizeof(IndexedBitmapInfo256) == kPaletteBitmapInfoBytes ? 1 : -1];

// Original OTWIN32 layout stores these handles and pointers as 32-bit fields.
// The semantic reconstruction keeps native pointer types so the code remains
// readable and host-compilable.
struct PositionedBitmap {
    HGLOBAL bitmap_info_handle;
    HGLOBAL indexed_pixels_handle;
    IndexedBitmapInfo256* bitmap_info;
    unsigned char* indexed_pixels;
    short x;
    short y;
    unsigned short width;
    unsigned short height;
    int x_mirror;
    int y_mirror;
    int right;
    int bottom;
};

// Original OTWIN32 layout:
// - +0x00: owned indexed-pixel handle
// - +0x04: indexed-pixel pointer
// - +0x08: owned BITMAPINFO handle
// - +0x0c: BITMAPINFO pointer
// - +0x10/+0x14/+0x18/+0x1c: height, width, last_x, last_y
struct RawIndexedBitmap {
    HGLOBAL indexed_pixels_handle;
    unsigned char* indexed_pixels;
    HGLOBAL bitmap_info_handle;
    IndexedBitmapInfo256* bitmap_info;
    int height;
    int width;
    int last_x;
    int last_y;
};

int OtLoadRectFromResource(ResourceRect* out_rect, HMODULE module, LPCSTR resource_id);
PositionedBitmap* OtInitPositionedBitmap(PositionedBitmap* bitmap);
PositionedBitmap* OtInitAndLoadPositionedBitmap(PositionedBitmap* bitmap, HMODULE module, unsigned short descriptor_id);
void OtFreePositionedBitmap(PositionedBitmap* bitmap);
int OtBlitWrappedPositionedBitmap(const PositionedBitmap* bitmap, HDC dc, int source_x, int source_y);
int OtLoadIndexedBitmapFromResource(PositionedBitmap* bitmap,
                                     HMODULE module,
                                     unsigned short bitmap_resource_id,
                                     short x,
                                     short y,
                                     unsigned short width,
                                     unsigned short height);
int OtLoadPositionedBitmapDescriptor(PositionedBitmap* bitmap, HMODULE module, unsigned short descriptor_id);
RawIndexedBitmap* OtInitRawIndexedBitmap(RawIndexedBitmap* bitmap);
RawIndexedBitmap* OtLoadRawIndexedBitmap(
    RawIndexedBitmap* bitmap, HMODULE module, int width, int height, LPCSTR bitmap_resource_id);
void OtFreeRawIndexedBitmap(RawIndexedBitmap* bitmap);
void OtBlitRawIndexedBitmap(RawIndexedBitmap* bitmap, HDC dc, int x, int y);

inline LPCSTR OtMakeIntResource(WORD resource_id)
{
    return (LPCSTR)(unsigned long)resource_id;
}

inline void OtInitializeIndexedBitmapInfo(IndexedBitmapInfo256* bitmap_info, int width, int height)
{
    if (bitmap_info == 0) {
        return;
    }

    bitmap_info->bmiHeader.biSize = kBitmapInfoHeaderBytes;
    bitmap_info->bmiHeader.biWidth = width;
    bitmap_info->bmiHeader.biHeight = height;
    bitmap_info->bmiHeader.biPlanes = 1;
    bitmap_info->bmiHeader.biBitCount = 8;
    bitmap_info->bmiHeader.biCompression = kBiRgb;
    bitmap_info->bmiHeader.biSizeImage = 0;
    bitmap_info->bmiHeader.biXPelsPerMeter = 0;
    bitmap_info->bmiHeader.biYPelsPerMeter = 0;
    bitmap_info->bmiHeader.biClrUsed = 0;
    bitmap_info->bmiHeader.biClrImportant = 0;

    for (WORD palette_index = 0; palette_index < kPaletteIndexCount; ++palette_index) {
        bitmap_info->palette_indexes[palette_index] = palette_index;
    }
}

inline void OtReleaseGlobalMemory(HGLOBAL* handle)
{
    if (handle != 0 && *handle != 0) {
        GlobalUnlock(*handle);
        GlobalFree(*handle);
        *handle = 0;
    }
}

inline int OtCopyResourceBytesToOwnedBuffer(HMODULE module,
                                            HRSRC resource_info,
                                            HGLOBAL* out_handle,
                                            unsigned char** out_bytes)
{
    if (out_handle == 0 || out_bytes == 0) {
        return 0;
    }

    *out_handle = 0;
    *out_bytes = 0;

    if (resource_info == 0) {
        return 0;
    }

    HGLOBAL resource_handle = LoadResource(module, resource_info);
    if (resource_handle == 0) {
        return 0;
    }

    const void* source_bytes = LockResource(resource_handle);
    if (source_bytes == 0) {
        FreeResource(resource_handle);
        return 0;
    }

    const DWORD resource_bytes = SizeofResource(module, resource_info);
    HGLOBAL owned_handle = GlobalAlloc(0, resource_bytes);
    if (owned_handle == 0) {
        FreeResource(resource_handle);
        return 0;
    }

    void* owned_bytes = GlobalLock(owned_handle);
    if (owned_bytes == 0) {
        GlobalFree(owned_handle);
        FreeResource(resource_handle);
        return 0;
    }

    const unsigned char* source_cursor =
        static_cast<const unsigned char*>(source_bytes);
    unsigned char* destination_cursor = static_cast<unsigned char*>(owned_bytes);
    for (DWORD index = 0; index < resource_bytes; ++index) {
        destination_cursor[index] = source_cursor[index];
    }
    FreeResource(resource_handle);

    *out_handle = owned_handle;
    *out_bytes = static_cast<unsigned char*>(owned_bytes);
    return 1;
}

}  // namespace graphics
}  // namespace reconstructed
}  // namespace otwin

#endif
