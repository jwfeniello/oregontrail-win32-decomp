#ifndef OTWIN_TRAIL_RUNTIME_H
#define OTWIN_TRAIL_RUNTIME_H

extern "C" __declspec(dllimport) int __stdcall MoveToEx(
    void* dc,
    int x,
    int y,
    void* point);
extern "C" __declspec(dllimport) int __stdcall LineTo(void* dc, int x, int y);
extern "C" __declspec(dllimport) int __stdcall DeleteObject(void* object);
extern "C" __declspec(dllimport) int __stdcall LoadStringA(
    void* instance,
    unsigned int resource_id,
    char* buffer,
    int buffer_length);

#endif
