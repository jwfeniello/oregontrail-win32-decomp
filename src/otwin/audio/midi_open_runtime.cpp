// Canonical product implementation of Oregon32.exe!OtOpenMidiAudioFile
// (RVA 0x0000cd60).

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

#include "audio_runtime.h"
#include <string.h>

#pragma intrinsic(strcpy)
#pragma intrinsic(strcat)

#pragma pack(push, 4)
struct OtMidiOpenParams_0040cd60_Product {
    void* callback;
    unsigned int device_id;
    unsigned int device_type;
    const char* element_name;
};

struct OtMidiPlayParams_0040cd60_Product {
    void* callback;
    unsigned int from;
    unsigned int to;
};

struct OtMidiStatusParams_0040cd60_Product {
    void* callback;
    unsigned int result;
    unsigned int item;
};

struct OtMidiGenericParams_0040cd60_Product {
    void* callback;
};
#pragma pack(pop)

extern "C" unsigned int g_audioBusy_0040cd60;
extern "C" unsigned int g_midiPlaybackActive_0040cd60;
extern "C" unsigned int g_midiPlaybackAvailable_0040cd60;
extern "C" OtMidiPlayParams_0040cd60_Product g_midiPlayParams_0040cd60;
extern "C" OtMidiOpenParams_0040cd60_Product g_midiOpenParams_0040cd60;
extern "C" OtMidiStatusParams_0040cd60_Product g_midiStatusParams_0040cd60;
extern "C" OtMidiGenericParams_0040cd60_Product g_midiCloseParams_0040cd60;
extern "C" char g_midiAudioRoot_0040cd60[];
extern "C" char g_outOfMemoryMessage_0040cd60[];
extern "C" char g_outOfMemoryTitle_0040cd60[];

extern "C" __declspec(dllimport) void* __stdcall LoadCursorA(
    void* instance,
    const char* cursor_name);
extern "C" __declspec(dllimport) void* __stdcall SetCursor(void* cursor);
extern "C" __declspec(dllimport) int __stdcall MessageBoxA(
    void* window,
    const char* text,
    const char* caption,
    unsigned int type);

#pragma comment(lib, "winmm.lib")
#pragma comment(lib, "user32.lib")

typedef void* (__stdcall *OtSetCursorProc_0040cd60_Product)(void* cursor);

#pragma code_seg(".otsem")
#pragma optimize("s", off)
#pragma optimize("t", on)
extern "C" void __cdecl OtOpenMidiAudioFileMaskClosed_0000cd60_RealCpp(
    void* owner,
    const char* filename)
{
    register void* owner_window = owner;
    register OtSetCursorProc_0040cd60_Product set_cursor;
    register unsigned int seed;
    unsigned int open_error;
    char path[100];

    seed = 0xffffffff;
    g_audioBusy_0040cd60 = 1;
    SetCursor(LoadCursorA(0, (const char*)0x7f02));
    set_cursor = SetCursor;
    if (seed != 0) {
        g_midiPlaybackActive_0040cd60 = 0;
        g_midiStatusParams_0040cd60.callback = owner_window;
        g_midiCloseParams_0040cd60.callback = owner_window;
        g_midiPlayParams_0040cd60.callback = owner_window;
        g_midiOpenParams_0040cd60.callback = owner_window;
        g_midiOpenParams_0040cd60.device_type = 0x20b;

        strcpy(path, g_midiAudioRoot_0040cd60);
        strcat(path, filename);

        g_midiOpenParams_0040cd60.element_name = path;
        open_error = mciSendCommandA(
            0, 0x0803, 0x3202, &g_midiOpenParams_0040cd60);
        if (open_error == 0) {
            g_midiPlaybackAvailable_0040cd60 = 1;
        } else {
            g_midiPlaybackAvailable_0040cd60 = 0;
            if (open_error == 0x0108) {
                MessageBoxA(
                    owner_window,
                    g_outOfMemoryMessage_0040cd60,
                    g_outOfMemoryTitle_0040cd60,
                    0x30);
            }
        }

        g_midiStatusParams_0040cd60.item = 0x4003;
        if (mciSendCommandA(
                g_midiOpenParams_0040cd60.device_id,
                0x0814,
                0x0100,
                &g_midiStatusParams_0040cd60) != 0) {
            g_midiPlaybackAvailable_0040cd60 = 0;
        }
        if ((short)g_midiStatusParams_0040cd60.result != -1) {
            g_midiPlaybackAvailable_0040cd60 = 0;
        }

        g_audioBusy_0040cd60 = 0;
        set_cursor(LoadCursorA(0, (const char*)0x7f00));
    }
}
#pragma optimize("", on)
#pragma code_seg()
