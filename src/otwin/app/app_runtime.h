#ifndef OTWIN_APP_RUNTIME_H
#define OTWIN_APP_RUNTIME_H

#include <string.h>

extern "C" __declspec(dllimport) void* __stdcall BeginPaint(void* window, void* paint);
extern "C" __declspec(dllimport) void* __stdcall SelectPalette(
    void* dc,
    void* palette,
    int force_background);
extern "C" __declspec(dllimport) unsigned int __stdcall RealizePalette(void* dc);
extern "C" __declspec(dllimport) unsigned int __stdcall SetTimer(
    void* window,
    unsigned int timer_id,
    unsigned int elapsed_ms,
    void* timer_proc);
extern "C" __declspec(dllimport) int __stdcall EndPaint(void* window, void* paint);
extern "C" __declspec(dllimport) void* __stdcall GetDC(void* window);
extern "C" __declspec(dllimport) int __stdcall GetDeviceCaps(
    void* dc,
    int index);
extern "C" __declspec(dllimport) int __stdcall ReleaseDC(
    void* window,
    void* dc);
extern "C" __declspec(dllimport) int __stdcall DeleteObject(void* object);
extern "C" __declspec(dllimport) int __stdcall DeleteDC(void* dc);
extern "C" __declspec(dllimport) void* __stdcall GetMenu(void* window);
extern "C" __declspec(dllimport) void* __stdcall GetSubMenu(void* menu, int position);
extern "C" __declspec(dllimport) unsigned int __stdcall GetMenuState(
    void* menu,
    unsigned int item,
    unsigned int flags);
extern "C" __declspec(dllimport) unsigned int __stdcall CheckMenuItem(
    void* menu,
    unsigned int item,
    unsigned int flags);
extern "C" __declspec(dllimport) int __stdcall DrawMenuBar(void* window);
extern "C" __declspec(dllimport) int __stdcall IsWindow(void* window);
extern "C" __declspec(dllimport) int __stdcall IsIconic(void* window);
extern "C" __declspec(dllimport) int __stdcall PostMessageA(
    void* window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" __declspec(dllimport) int __stdcall sndPlaySoundA(
    const char* sound_name,
    unsigned int flags);
extern "C" __declspec(dllimport) int __stdcall WritePrivateProfileStringA(
    const char* section,
    const char* key,
    const char* value,
    const char* file_name);
extern "C" __declspec(dllimport) long __stdcall GetWindowLongA(void* window, int index);
extern "C" __declspec(dllimport) long __stdcall SetWindowLongA(
    void* window,
    int index,
    long value);
extern "C" __declspec(dllimport) long __stdcall DefWindowProcA(
    void* window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" __declspec(dllimport) int __stdcall GetWindowTextLengthA(void* window);
extern "C" __declspec(dllimport) long __stdcall SendMessageA(
    void* window,
    unsigned int message,
    unsigned int wparam,
    long lparam);

#endif
