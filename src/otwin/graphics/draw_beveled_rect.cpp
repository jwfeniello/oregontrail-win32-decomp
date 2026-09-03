// Semantic candidate for OtDrawBeveledRect (0x0040b4c0).

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "graphics_runtime.h"

#pragma comment(lib, "gdi32.lib")

#pragma pack(push, 1)
struct BeveledRect_0000b4c0 {
    int left;
    int top;
    int right;
    int bottom;

    void OtDrawBeveledRect_0000b4c0_RealCpp(void* dc);
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

// Draws the three-pen beveled frame around the rectangle coordinates.
void BeveledRect_0000b4c0::OtDrawBeveledRect_0000b4c0_RealCpp(void* dc)
{
    void* first_pen;
    void* second_pen;
    void* third_pen;
    void* old_pen;

    if (dc != 0) {
        first_pen = CreatePen(0, 2, 0x01000057ul);
        old_pen = SelectObject(dc, first_pen);

        MoveToEx(dc, left + 1, top + 1, 0);
        LineTo(dc, right - 1, top + 1);
        LineTo(dc, right - 1, bottom - 1);
        LineTo(dc, left + 1, bottom - 1);
        LineTo(dc, left + 1, top + 1);

        second_pen = CreatePen(0, 1, 0x01000088ul);
        SelectObject(dc, second_pen);

        MoveToEx(dc, left + 2, top + 2, 0);
        LineTo(dc, right - 2, top + 2);
        MoveToEx(dc, right, top, 0);
        LineTo(dc, right, bottom);
        LineTo(dc, left, bottom);
        MoveToEx(dc, left + 2, top + 2, 0);
        LineTo(dc, left + 2, bottom - 2);

        third_pen = CreatePen(0, 1, 0x01000083ul);
        SelectObject(dc, third_pen);

        MoveToEx(dc, left, top, 0);
        LineTo(dc, right, top);
        MoveToEx(dc, right - 2, top + 2, 0);
        LineTo(dc, right - 2, bottom - 2);
        MoveToEx(dc, left + 2, bottom - 2, 0);
        LineTo(dc, right - 2, bottom - 2);
        MoveToEx(dc, left, top, 0);
        LineTo(dc, left, bottom);

        SelectObject(dc, old_pen);
        DeleteObject(first_pen);
        DeleteObject(second_pen);
        DeleteObject(third_pen);
    }
}

#pragma optimize("", on)
