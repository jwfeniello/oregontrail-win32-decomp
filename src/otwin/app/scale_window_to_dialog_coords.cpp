// Product-tree recovery of FUN_00401370_00001370. The helper converts an
// existing child rectangle from pixels into the caller's 10-by-20 dialog-unit
// grid before moving the child without changing its Z order.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This recovered runtime requires 32-bit MSVC."
#endif

typedef void* OtWindowHandle_00401370;

extern "C" __declspec(dllimport) int __stdcall IsWindow(
    OtWindowHandle_00401370 window);
extern "C" __declspec(dllimport) int __stdcall GetWindowRect(
    OtWindowHandle_00401370 window,
    long* rect);
extern "C" __declspec(dllimport) int __stdcall ScreenToClient(
    OtWindowHandle_00401370 window,
    long* point);
extern "C" __declspec(dllimport) int __stdcall SetWindowPos(
    OtWindowHandle_00401370 window,
    OtWindowHandle_00401370 insert_after,
    int x,
    int y,
    int width,
    int height,
    unsigned int flags);

#pragma comment(lib, "user32.lib")

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" void __cdecl OtScaleWindowToDialogCoords_00401370_Product(
    OtWindowHandle_00401370 parent,
    OtWindowHandle_00401370 child,
    int width_scale,
    int height_scale)
{
    long rect[4];

    if (IsWindow(parent) != 0) {
        if (IsWindow(child) != 0) {
            GetWindowRect(child, rect);
            ScreenToClient(parent, rect);
            ScreenToClient(parent, rect + 2);

            rect[0] = (rect[0] * 10) / width_scale;
            rect[2] = (rect[2] * 10) / width_scale;
            rect[1] = (rect[1] * 20) / height_scale;
            rect[3] = (rect[3] * 20) / height_scale;

            SetWindowPos(
                child,
                0,
                rect[0],
                rect[1],
                rect[2] - rect[0],
                rect[3] - rect[1],
                4);
        }
    }
}

#pragma optimize("", on)
