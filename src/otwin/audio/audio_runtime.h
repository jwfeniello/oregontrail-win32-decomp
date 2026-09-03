#ifndef OTWIN_AUDIO_RUNTIME_H
#define OTWIN_AUDIO_RUNTIME_H

typedef unsigned long (__stdcall *OtMciSendCommandProc)(
    unsigned int device_id,
    unsigned int message,
    unsigned long flags,
    void* parameters);

extern "C" __declspec(dllimport) unsigned long __stdcall mciSendCommandA(
    unsigned int device_id,
    unsigned int message,
    unsigned long flags,
    void* parameters);
extern "C" __declspec(dllimport) int __stdcall IsWindow(void* window);
extern "C" int (__stdcall *PTR_IsWindow_0040d480_45pct)(void* window);
extern "C" __declspec(dllimport) int __stdcall LoadStringA(
    void* instance,
    unsigned int resource_id,
    char* buffer,
    int buffer_length);

#endif
