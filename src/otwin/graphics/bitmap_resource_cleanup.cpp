// Semantic bitmap cleanup register-shape trials.
//
// These keep the recovered resource-management behavior in real C++ while
// varying declaration order enough for VC4 to expose the original preserved
// register allocation.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

extern "C" __declspec(dllimport) int __stdcall GlobalUnlock(
    unsigned long handle);
extern "C" __declspec(dllimport) int __stdcall GlobalFree(
    unsigned long handle);

#pragma comment(lib, "kernel32.lib")

#pragma pack(push, 1)
struct PositionedBitmapFree_0040b760_42pct {
    unsigned long bitmap_info_handle;
    unsigned long indexed_pixels_handle;

    void OtFreePositionedBitmapAlt1_0040b760_42pct();
    void OtFreePositionedBitmapAlt2_0040b760_42pct();
    void OtFreePositionedBitmapAlt3_0040b760_42pct();
    void OtFreePositionedBitmapAlt4_0040b760_42pct();
    void OtFreePositionedBitmapAlt5_0040b760_42pct();
};

struct RawIndexedBitmapFree_00410550_42pct {
    unsigned long indexed_pixels_handle;
    unsigned long unknown_04;
    unsigned long bitmap_info_handle;

    void OtFreeRawIndexedBitmapAlt1_00410550_42pct();
    void OtFreeRawIndexedBitmapAlt2_00410550_42pct();
    void OtFreeRawIndexedBitmapAlt3_00410550_42pct();
    void OtFreeRawIndexedBitmapAlt4_00410550_42pct();
    void OtFreeRawIndexedBitmapAlt5_00410550_42pct();
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

/**
 * Purpose: release the bitmap-info and indexed-pixel global blocks owned by a
 * positioned bitmap.
 *
 * Parameters:
 * - this: positioned bitmap whose two optional global handles are unlocked and freed.
 */
void PositionedBitmapFree_0040b760_42pct::OtFreePositionedBitmapAlt1_0040b760_42pct()
{
    register PositionedBitmapFree_0040b760_42pct* bitmap = this;
    register int (__stdcall *unlock_handle)(unsigned long);
    register int (__stdcall *free_handle)(unsigned long);
    unsigned long handle = bitmap->bitmap_info_handle;

    if (handle != 0) {
        unlock_handle = GlobalUnlock;
        unlock_handle(handle);
        handle = bitmap->bitmap_info_handle;
        free_handle = GlobalFree;
        free_handle(handle);
    } else {
        unlock_handle = GlobalUnlock;
        free_handle = GlobalFree;
    }

    handle = bitmap->indexed_pixels_handle;
    if (handle != 0) {
        unlock_handle(handle);
        handle = bitmap->indexed_pixels_handle;
        free_handle(handle);
    }
}

/**
 * Purpose: release the bitmap-info and indexed-pixel global blocks owned by a
 * positioned bitmap.
 *
 * Parameters:
 * - this: positioned bitmap whose two optional global handles are unlocked and freed.
 */
void PositionedBitmapFree_0040b760_42pct::OtFreePositionedBitmapAlt2_0040b760_42pct()
{
    register int (__stdcall *free_handle)(unsigned long);
    register int (__stdcall *unlock_handle)(unsigned long);
    register PositionedBitmapFree_0040b760_42pct* bitmap = this;
    unsigned long handle = bitmap->bitmap_info_handle;

    if (handle != 0) {
        unlock_handle = GlobalUnlock;
        unlock_handle(handle);
        handle = bitmap->bitmap_info_handle;
        free_handle = GlobalFree;
        free_handle(handle);
    } else {
        unlock_handle = GlobalUnlock;
        free_handle = GlobalFree;
    }

    handle = bitmap->indexed_pixels_handle;
    if (handle != 0) {
        unlock_handle(handle);
        handle = bitmap->indexed_pixels_handle;
        free_handle(handle);
    }
}

/**
 * Purpose: release the bitmap-info and indexed-pixel global blocks owned by a
 * positioned bitmap.
 *
 * Parameters:
 * - this: positioned bitmap whose two optional global handles are unlocked and freed.
 */
void PositionedBitmapFree_0040b760_42pct::OtFreePositionedBitmapAlt3_0040b760_42pct()
{
    register int (__stdcall *unlock_handle)(unsigned long);
    register int (__stdcall *free_handle)(unsigned long);
    register PositionedBitmapFree_0040b760_42pct* bitmap = this;
    unsigned long handle = bitmap->bitmap_info_handle;

    if (handle != 0) {
        unlock_handle = GlobalUnlock;
        unlock_handle(handle);
        handle = bitmap->bitmap_info_handle;
        free_handle = GlobalFree;
        free_handle(handle);
    } else {
        unlock_handle = GlobalUnlock;
        free_handle = GlobalFree;
    }

    handle = bitmap->indexed_pixels_handle;
    if (handle != 0) {
        unlock_handle(handle);
        handle = bitmap->indexed_pixels_handle;
        free_handle(handle);
    }
}

/**
 * Purpose: release the bitmap-info and indexed-pixel global blocks owned by a
 * positioned bitmap.
 *
 * Parameters:
 * - this: positioned bitmap whose two optional global handles are unlocked and freed.
 */
void PositionedBitmapFree_0040b760_42pct::OtFreePositionedBitmapAlt4_0040b760_42pct()
{
    register int (__stdcall *unlock_handle)(unsigned long);
    register PositionedBitmapFree_0040b760_42pct* bitmap = this;
    register int (__stdcall *free_handle)(unsigned long);

    if (bitmap->bitmap_info_handle != 0) {
        unlock_handle = GlobalUnlock;
        unlock_handle(bitmap->bitmap_info_handle);
        free_handle = GlobalFree;
        free_handle(bitmap->bitmap_info_handle);
    } else {
        unlock_handle = GlobalUnlock;
        free_handle = GlobalFree;
    }

    if (bitmap->indexed_pixels_handle != 0) {
        unlock_handle(bitmap->indexed_pixels_handle);
        free_handle(bitmap->indexed_pixels_handle);
    }
}

/**
 * Purpose: release the bitmap-info and indexed-pixel global blocks owned by a
 * raw indexed bitmap.
 *
 * Parameters:
 * - this: raw bitmap whose optional info and pixel handles are unlocked and freed.
 */
void RawIndexedBitmapFree_00410550_42pct::OtFreeRawIndexedBitmapAlt1_00410550_42pct()
{
    register RawIndexedBitmapFree_00410550_42pct* bitmap = this;
    register int (__stdcall *unlock_handle)(unsigned long);
    register int (__stdcall *free_handle)(unsigned long);
    unsigned long handle = bitmap->bitmap_info_handle;

    if (handle != 0) {
        unlock_handle = GlobalUnlock;
        unlock_handle(handle);
        handle = bitmap->bitmap_info_handle;
        free_handle = GlobalFree;
        free_handle(handle);
    } else {
        unlock_handle = GlobalUnlock;
        free_handle = GlobalFree;
    }

    handle = bitmap->indexed_pixels_handle;
    if (handle != 0) {
        unlock_handle(handle);
        handle = bitmap->indexed_pixels_handle;
        free_handle(handle);
    }
}

/**
 * Purpose: release the bitmap-info and indexed-pixel global blocks owned by a
 * raw indexed bitmap.
 *
 * Parameters:
 * - this: raw bitmap whose optional info and pixel handles are unlocked and freed.
 */
void RawIndexedBitmapFree_00410550_42pct::OtFreeRawIndexedBitmapAlt2_00410550_42pct()
{
    register int (__stdcall *free_handle)(unsigned long);
    register int (__stdcall *unlock_handle)(unsigned long);
    register RawIndexedBitmapFree_00410550_42pct* bitmap = this;
    unsigned long handle = bitmap->bitmap_info_handle;

    if (handle != 0) {
        unlock_handle = GlobalUnlock;
        unlock_handle(handle);
        handle = bitmap->bitmap_info_handle;
        free_handle = GlobalFree;
        free_handle(handle);
    } else {
        unlock_handle = GlobalUnlock;
        free_handle = GlobalFree;
    }

    handle = bitmap->indexed_pixels_handle;
    if (handle != 0) {
        unlock_handle(handle);
        handle = bitmap->indexed_pixels_handle;
        free_handle(handle);
    }
}

/**
 * Purpose: release the bitmap-info and indexed-pixel global blocks owned by a
 * raw indexed bitmap.
 *
 * Parameters:
 * - this: raw bitmap whose optional info and pixel handles are unlocked and freed.
 */
void RawIndexedBitmapFree_00410550_42pct::OtFreeRawIndexedBitmapAlt3_00410550_42pct()
{
    register int (__stdcall *unlock_handle)(unsigned long);
    register int (__stdcall *free_handle)(unsigned long);
    register RawIndexedBitmapFree_00410550_42pct* bitmap = this;
    unsigned long handle = bitmap->bitmap_info_handle;

    if (handle != 0) {
        unlock_handle = GlobalUnlock;
        unlock_handle(handle);
        handle = bitmap->bitmap_info_handle;
        free_handle = GlobalFree;
        free_handle(handle);
    } else {
        unlock_handle = GlobalUnlock;
        free_handle = GlobalFree;
    }

    handle = bitmap->indexed_pixels_handle;
    if (handle != 0) {
        unlock_handle(handle);
        handle = bitmap->indexed_pixels_handle;
        free_handle(handle);
    }
}

/**
 * Purpose: release the bitmap-info and indexed-pixel global blocks owned by a
 * raw indexed bitmap.
 *
 * Parameters:
 * - this: raw bitmap whose optional info and pixel handles are unlocked and freed.
 */
void RawIndexedBitmapFree_00410550_42pct::OtFreeRawIndexedBitmapAlt4_00410550_42pct()
{
    register int (__stdcall *unlock_handle)(unsigned long);
    register RawIndexedBitmapFree_00410550_42pct* bitmap = this;
    register int (__stdcall *free_handle)(unsigned long);

    if (bitmap->bitmap_info_handle != 0) {
        unlock_handle = GlobalUnlock;
        unlock_handle(bitmap->bitmap_info_handle);
        free_handle = GlobalFree;
        free_handle(bitmap->bitmap_info_handle);
    } else {
        unlock_handle = GlobalUnlock;
        free_handle = GlobalFree;
    }

    if (bitmap->indexed_pixels_handle != 0) {
        unlock_handle(bitmap->indexed_pixels_handle);
        free_handle(bitmap->indexed_pixels_handle);
    }
}

/**
 * Direct-import source shape matching the original compiler's cached IAT
 * targets for the two repeated GlobalUnlock/GlobalFree call pairs.
 */
void PositionedBitmapFree_0040b760_42pct::OtFreePositionedBitmapAlt5_0040b760_42pct()
{
    if (bitmap_info_handle != 0) {
        GlobalUnlock(bitmap_info_handle);
        GlobalFree(bitmap_info_handle);
    }

    if (indexed_pixels_handle != 0) {
        GlobalUnlock(indexed_pixels_handle);
        GlobalFree(indexed_pixels_handle);
    }
}

/**
 * Direct-import counterpart for the raw bitmap's reversed handle layout.
 */
void RawIndexedBitmapFree_00410550_42pct::OtFreeRawIndexedBitmapAlt5_00410550_42pct()
{
    if (bitmap_info_handle != 0) {
        GlobalUnlock(bitmap_info_handle);
        GlobalFree(bitmap_info_handle);
    }

    if (indexed_pixels_handle != 0) {
        GlobalUnlock(indexed_pixels_handle);
        GlobalFree(indexed_pixels_handle);
    }
}
