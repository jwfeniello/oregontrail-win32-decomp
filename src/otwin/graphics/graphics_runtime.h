#ifndef OTWIN_GRAPHICS_RUNTIME_H
#define OTWIN_GRAPHICS_RUNTIME_H

extern "C" __declspec(dllimport) void* __stdcall CreatePen(
    int style,
    int width,
    unsigned long color);
extern "C" __declspec(dllimport) void* __stdcall SelectObject(
    void* dc,
    void* object);
extern "C" __declspec(dllimport) int __stdcall MoveToEx(
    void* dc,
    int x,
    int y,
    void* point);
extern "C" __declspec(dllimport) int __stdcall LineTo(
    void* dc,
    int x,
    int y);
extern "C" __declspec(dllimport) int __stdcall DeleteObject(void* object);
extern "C" __declspec(dllimport) void* __stdcall FindResourceA(
    void* module,
    const void* name,
    const void* type);
extern "C" __declspec(dllimport) void* __stdcall LoadResource(void* module, void* resource_info);
extern "C" __declspec(dllimport) void* __stdcall LockResource(void* resource_data);
extern "C" __declspec(dllimport) void* __stdcall GlobalAlloc(unsigned int flags, unsigned long bytes);
extern "C" __declspec(dllimport) void* __stdcall GlobalLock(void* handle);
extern "C" __declspec(dllimport) int __stdcall FreeResource(void* resource_data);
extern "C" __declspec(dllimport) int __stdcall GlobalUnlock(void* handle);
extern "C" __declspec(dllimport) void* __stdcall GlobalFree(void* handle);
extern "C" __declspec(dllimport) void* __stdcall GetDC(void* window);
extern "C" __declspec(dllimport) int __stdcall ReleaseDC(void* window, void* dc);
extern "C" __declspec(dllimport) void* __stdcall CreatePalette(void* palette);
extern "C" __declspec(dllimport) int __stdcall UnrealizeObject(void* object);
extern "C" __declspec(dllimport) void* __stdcall SelectPalette(
    void* dc,
    void* palette,
    int force_background);
extern "C" __declspec(dllimport) unsigned int __stdcall RealizePalette(void* dc);

#endif
