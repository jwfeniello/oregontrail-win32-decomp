#ifndef OTWIN_RIVER_RUNTIME_H
#define OTWIN_RIVER_RUNTIME_H

extern "C" void __fastcall OtFreeSpriteBlitter_RealCpp(void* sprite);

struct RawIndexedBitmapFree_00410550_42pct {
    void OtFreeRawIndexedBitmapAlt5_00410550_42pct();
};

extern "C" __declspec(dllimport) int __stdcall sndPlaySoundA(
    const char* sound_name,
    unsigned int flags);
extern "C" __declspec(dllimport) void* __stdcall FindResourceA(
    void* module,
    const void* name,
    const void* type);
extern "C" __declspec(dllimport) void* __stdcall LoadResource(
    void* module,
    void* resource_info);
extern "C" __declspec(dllimport) void* __stdcall LockResource(void* resource_data);
extern "C" __declspec(dllimport) int __stdcall FreeResource(void* resource);
extern "C" __declspec(dllimport) int __stdcall GlobalUnlock(void* handle);
extern "C" __declspec(dllimport) void* __stdcall GlobalFree(void* handle);
extern "C" __declspec(dllimport) void* __stdcall GetParent(void* window);
extern "C" __declspec(dllimport) int __stdcall IsWindowVisible(void* window);
extern "C" __declspec(dllimport) long __stdcall SendMessageA(
    void* window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" __declspec(dllimport) int __stdcall MessageBoxA(
    void* owner,
    const char* text,
    const char* caption,
    unsigned int type);
extern "C" __declspec(dllimport) void* __stdcall SetFocus(void* window);

#endif
