// Semantic audio-close register and scheduling trials.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "audio_runtime.h"
#include <string.h>

#pragma intrinsic(strcpy)
#pragma intrinsic(strcat)
#pragma intrinsic(strlen)

#pragma pack(push, 4)
struct OtMidiOpenParams_0040cd60 {
    void* callback;
    unsigned int device_id;
    unsigned int device_type;
    const char* element_name;
};

struct OtMidiPlayParams_0040cd60 {
    void* callback;
    unsigned int from;
    unsigned int to;
};

struct OtMidiStatusParams_0040cd60 {
    void* callback;
    unsigned int result;
    unsigned int item;
};

struct OtMidiGenericParams_0040cd60 {
    void* callback;
};

struct OtWaveOpenParams_0040d110 {
    void* callback;
    unsigned int device_id;
    unsigned int device_type;
    const char* element_name;
};

struct OtWavePlayParams_0040d110 {
    void* callback;
    unsigned int from;
    unsigned int to;
};

struct OtWaveStatusParams_0040d110 {
    void* callback;
    unsigned int result;
    unsigned int item;
};

struct OtWaveGenericParams_0040d110 {
    void* callback;
};
#pragma pack(pop)

typedef char OtMidiOpenParamsSize_0040cd60[
    sizeof(OtMidiOpenParams_0040cd60) == 0x10 ? 1 : -1];
typedef char OtMidiPlayParamsSize_0040cd60[
    sizeof(OtMidiPlayParams_0040cd60) == 0x0c ? 1 : -1];
typedef char OtMidiStatusParamsSize_0040cd60[
    sizeof(OtMidiStatusParams_0040cd60) == 0x0c ? 1 : -1];
typedef char OtMidiGenericParamsSize_0040cd60[
    sizeof(OtMidiGenericParams_0040cd60) == 0x04 ? 1 : -1];
typedef char OtWaveOpenParamsSize_0040d110[
    sizeof(OtWaveOpenParams_0040d110) == 0x10 ? 1 : -1];
typedef char OtWavePlayParamsSize_0040d110[
    sizeof(OtWavePlayParams_0040d110) == 0x0c ? 1 : -1];
typedef char OtWaveStatusParamsSize_0040d110[
    sizeof(OtWaveStatusParams_0040d110) == 0x0c ? 1 : -1];
typedef char OtWaveGenericParamsSize_0040d110[
    sizeof(OtWaveGenericParams_0040d110) == 0x04 ? 1 : -1];

typedef void* (__stdcall *OtSetCursorProc_0040cd60)(void* cursor);

extern "C" unsigned int g_audioBusy_0040cd60 = 0;
extern "C" unsigned int g_midiPlaybackActive_0040cd60 = 0;
extern "C" unsigned int g_midiPlaybackAvailable_0040cd60 = 0;
extern "C" OtMidiPlayParams_0040cd60 g_midiPlayParams_0040cd60 = { 0 };
extern "C" OtMidiOpenParams_0040cd60 g_midiOpenParams_0040cd60 = { 0 };
extern "C" OtMidiStatusParams_0040cd60 g_midiStatusParams_0040cd60 = { 0 };
extern "C" OtMidiGenericParams_0040cd60 g_midiCloseParams_0040cd60 = { 0 };
extern "C" char g_midiAudioRoot_0040cd60[] = "";
extern "C" char g_outOfMemoryMessage_0040cd60[] =
    "You don't have enough memory to play this sound.";
extern "C" char g_outOfMemoryTitle_0040cd60[] = "Out of Memory";
extern "C" char g_unknownMidiError_0040cd60[] = "Unknown error.";
extern "C" char g_midiErrorTitle_0040cd60[] = "Midi Error";
extern "C" unsigned int g_waveAudioDisabled_0040d110 = 0;
extern "C" OtWavePlayParams_0040d110 g_wavePlayParams_0040d110 = { 0 };
extern "C" OtWaveOpenParams_0040d110 g_waveOpenParams_0040d110 = { 0 };
extern "C" OtWaveStatusParams_0040d110 g_waveStatusParams_0040d110 = { 0 };
extern "C" OtWaveGenericParams_0040d110 g_waveCloseParams_0040d110 = { 0 };
extern "C" unsigned int g_wavePlaybackActive_0040d110 = 0;
extern "C" char g_waveStereoSuffix_0040d110[] = ".S";
extern "C" char g_waveMonoSuffix_0040d110[] = ".M";

extern "C" __declspec(dllimport) void* __stdcall LoadCursorA(
    void* instance,
    const char* cursor_name);
extern "C" __declspec(dllimport) void* __stdcall SetCursor(void* cursor);
extern "C" __declspec(dllimport) int __stdcall MessageBoxA(
    void* window,
    const char* text,
    const char* caption,
    unsigned int type);
extern "C" __declspec(dllimport) int __stdcall mciGetErrorStringA(
    unsigned int error,
    char* text,
    unsigned int length);

#pragma comment(lib, "winmm.lib")
#pragma comment(lib, "user32.lib")

#pragma optimize("s", off)
#pragma optimize("t", on)

/**
 * Purpose: close the active wave MCI device after confirming it is still in a
 * closeable state, then clear the stored device id.
 *
 * Parameters: none.
 */
extern "C" void __cdecl OtCloseWaveAudioDevice_0040d0a0_RealCpp()
{
    register unsigned int zero = 0;
    unsigned int* device_check = &g_waveOpenParams_0040d110.device_id;

    g_wavePlaybackActive_0040d110 = zero;

    if (*device_check > zero) {
        g_waveStatusParams_0040d110.result = zero;

        if (mciSendCommandA(
                g_waveOpenParams_0040d110.device_id,
                0x0814,
                0x0100,
                &g_waveStatusParams_0040d110) == 0 &&
            g_waveStatusParams_0040d110.result != zero) {
            mciSendCommandA(
                g_waveOpenParams_0040d110.device_id,
                0x0804,
                2,
                &g_waveCloseParams_0040d110);
            g_waveOpenParams_0040d110.device_id = zero;
            return;
        }

        g_waveOpenParams_0040d110.device_id = 0;
    }
}

/**
 * Purpose: stop and close the active MIDI MCI device, then clear the active
 * device identifier regardless of whether the status query succeeds.
 *
 * Parameters: none.
 */
extern "C" void __cdecl OtCloseMidiAudioDeviceAlt1_0040ccf0_45pct()
{
    register unsigned int zero = 0;
    register unsigned long (__stdcall *mci_send)(
        unsigned int,
        unsigned int,
        unsigned long,
        void*) = mciSendCommandA;
    unsigned int device = g_midiOpenParams_0040cd60.device_id;

    g_midiPlaybackActive_0040cd60 = zero;
    g_midiStatusParams_0040cd60.result = zero;

    if (mci_send(device, 0x0814, 0x0100, &g_midiStatusParams_0040cd60) == 0 &&
        g_midiStatusParams_0040cd60.result != zero) {
        mci_send(
            g_midiOpenParams_0040cd60.device_id,
            0x0804,
            2,
            &g_midiCloseParams_0040cd60);
        g_midiOpenParams_0040cd60.device_id = zero;
        return;
    }

    g_midiOpenParams_0040cd60.device_id = 0;
}

/**
 * Purpose: stop and close the active MIDI MCI device, then clear the active
 * device identifier regardless of whether the status query succeeds.
 *
 * Parameters: none.
 */
extern "C" void __cdecl OtCloseMidiAudioDeviceAlt2_0040ccf0_45pct()
{
    register unsigned int zero = 0;
    register unsigned long (__stdcall *mci_send)(
        unsigned int,
        unsigned int,
        unsigned long,
        void*) = mciSendCommandA;

    if ((
            g_midiPlaybackActive_0040cd60 = zero,
            g_midiStatusParams_0040cd60.result = zero,
            mci_send(
                g_midiOpenParams_0040cd60.device_id,
                0x0814,
                0x0100,
                &g_midiStatusParams_0040cd60)) == 0 &&
        g_midiStatusParams_0040cd60.result != zero) {
        mci_send(
            g_midiOpenParams_0040cd60.device_id,
            0x0804,
            2,
            &g_midiCloseParams_0040cd60);
        g_midiOpenParams_0040cd60.device_id = zero;
        return;
    }

    g_midiOpenParams_0040cd60.device_id = 0;
}

/**
 * Purpose: stop and close the active MIDI MCI device, then clear the active
 * device identifier regardless of whether the status query succeeds.
 *
 * Parameters: none.
 */
extern "C" void __cdecl OtCloseMidiAudioDeviceAlt3_0040ccf0_45pct()
{
    register unsigned int zero = 0;
    unsigned int device = g_midiOpenParams_0040cd60.device_id;
    register unsigned long (__stdcall *mci_send)(
        unsigned int,
        unsigned int,
        unsigned long,
        void*) = mciSendCommandA;

    g_midiPlaybackActive_0040cd60 = zero;
    g_midiStatusParams_0040cd60.result = zero;

    if (mci_send(device, 0x0814, 0x0100, &g_midiStatusParams_0040cd60) == 0 &&
        g_midiStatusParams_0040cd60.result != zero) {
        mci_send(
            g_midiOpenParams_0040cd60.device_id,
            0x0804,
            2,
            &g_midiCloseParams_0040cd60);
        g_midiOpenParams_0040cd60.device_id = zero;
        return;
    }

    g_midiOpenParams_0040cd60.device_id = 0;
}

extern "C" void __cdecl OtCloseMidiAudioDeviceAlt4_0040ccf0_45pct()
{
    register unsigned int zero = 0;
    unsigned int device = g_midiOpenParams_0040cd60.device_id;

    g_midiPlaybackActive_0040cd60 = zero;
    g_midiStatusParams_0040cd60.result = zero;

    if (mciSendCommandA(
            device,
            0x0814,
            0x0100,
            &g_midiStatusParams_0040cd60) == 0 &&
        g_midiStatusParams_0040cd60.result != zero) {
        mciSendCommandA(
            g_midiOpenParams_0040cd60.device_id,
            0x0804,
            2,
            &g_midiCloseParams_0040cd60);
        g_midiOpenParams_0040cd60.device_id = zero;
        return;
    }

    g_midiOpenParams_0040cd60.device_id = 0;
}

extern "C" void __cdecl OtCloseMidiAudioDeviceAlt5NoAsm_0040ccf0_RealCpp()
{
    register unsigned int zero = 0;

    g_midiPlaybackActive_0040cd60 = zero;
    g_midiStatusParams_0040cd60.result = zero;

    if (mciSendCommandA(
            g_midiOpenParams_0040cd60.device_id,
            0x0814,
            0x0100,
            &g_midiStatusParams_0040cd60) == 0 &&
        g_midiStatusParams_0040cd60.result != zero) {
        mciSendCommandA(
            g_midiOpenParams_0040cd60.device_id,
            0x0804,
            2,
            &g_midiCloseParams_0040cd60);
        g_midiOpenParams_0040cd60.device_id = zero;
        return;
    }

    g_midiOpenParams_0040cd60.device_id = 0;
}

extern "C" void __cdecl OtCloseMidiAudioDeviceNoAsm_0040ccf0_RealCpp()
{
    register unsigned int zero = 0;

    g_midiPlaybackActive_0040cd60 = zero;
    g_midiStatusParams_0040cd60.result = zero;

    if (mciSendCommandA(
            g_midiOpenParams_0040cd60.device_id,
            0x0814,
            0x0100,
            &g_midiStatusParams_0040cd60) == 0 &&
        g_midiStatusParams_0040cd60.result != zero) {
        mciSendCommandA(
            g_midiOpenParams_0040cd60.device_id,
            0x0804,
            2,
            &g_midiCloseParams_0040cd60);
        g_midiOpenParams_0040cd60.device_id = zero;
        return;
    }

    g_midiOpenParams_0040cd60.device_id = 0;
}

extern "C" void __cdecl OtOpenMidiAudioFile_0000cd60_RealCpp(void* owner, char* filename)
{
    register void* owner_window = owner;
    register OtSetCursorProc_0040cd60 set_cursor;
    void* cursor;
    unsigned int open_error;
    char path[100];

    g_audioBusy_0040cd60 = 1;
    cursor = LoadCursorA(0, (const char*)0x7f02);
    set_cursor = SetCursor;
    set_cursor(cursor);
    g_midiPlaybackActive_0040cd60 = 0;
    g_midiStatusParams_0040cd60.callback = owner_window;
    g_midiCloseParams_0040cd60.callback = owner_window;
    g_midiPlayParams_0040cd60.callback = owner_window;
    g_midiOpenParams_0040cd60.callback = owner_window;
    g_midiOpenParams_0040cd60.device_type = 0x20b;

    strcpy(path, g_midiAudioRoot_0040cd60);
    strcat(path, filename);

    g_midiOpenParams_0040cd60.element_name = path;
    open_error = mciSendCommandA(0, 0x0803, 0x3202, &g_midiOpenParams_0040cd60);
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

extern "C" void __cdecl OtOpenMidiAudioFileAlt1_0000cd60_RealCpp(
    void* owner,
    char* filename)
{
    register void* owner_window = owner;
    register OtSetCursorProc_0040cd60 set_cursor;
    void* cursor;
    unsigned int open_error;
    char path[100];

    g_audioBusy_0040cd60 = 1;
    cursor = LoadCursorA(0, (const char*)0x7f02);
    (set_cursor = SetCursor, set_cursor)(cursor);
    g_midiPlaybackActive_0040cd60 = 0;
    g_midiStatusParams_0040cd60.callback = owner_window;
    g_midiCloseParams_0040cd60.callback = owner_window;
    g_midiPlayParams_0040cd60.callback = owner_window;
    g_midiOpenParams_0040cd60.callback = owner_window;
    g_midiOpenParams_0040cd60.device_type = 0x20b;

    strcpy(path, g_midiAudioRoot_0040cd60);
    strcat(path, filename);

    g_midiOpenParams_0040cd60.element_name = path;
    open_error = mciSendCommandA(0, 0x0803, 0x3202, &g_midiOpenParams_0040cd60);
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

extern "C" void __cdecl OtOpenMidiAudioFileAlt2_0000cd60_RealCpp(
    void* owner,
    char* filename)
{
    register void* owner_window = owner;
    register OtSetCursorProc_0040cd60 set_cursor = SetCursor;
    unsigned int open_error;
    char path[100];

    g_audioBusy_0040cd60 = 1;
    set_cursor(LoadCursorA(0, (const char*)0x7f02));
    g_midiPlaybackActive_0040cd60 = 0;
    g_midiStatusParams_0040cd60.callback = owner_window;
    g_midiCloseParams_0040cd60.callback = owner_window;
    g_midiPlayParams_0040cd60.callback = owner_window;
    g_midiOpenParams_0040cd60.callback = owner_window;
    g_midiOpenParams_0040cd60.device_type = 0x20b;

    strcpy(path, g_midiAudioRoot_0040cd60);
    strcat(path, filename);

    g_midiOpenParams_0040cd60.element_name = path;
    open_error = mciSendCommandA(0, 0x0803, 0x3202, &g_midiOpenParams_0040cd60);
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

extern "C" void __cdecl OtOpenMidiAudioFileAlt3_0000cd60_RealCpp(
    void* owner,
    char* filename)
{
    register void* owner_window = owner;
    unsigned int open_error;
    char path[100];

    g_audioBusy_0040cd60 = 1;
    SetCursor(LoadCursorA(0, (const char*)0x7f02));
    g_midiPlaybackActive_0040cd60 = 0;
    g_midiStatusParams_0040cd60.callback = owner_window;
    g_midiCloseParams_0040cd60.callback = owner_window;
    g_midiPlayParams_0040cd60.callback = owner_window;
    g_midiOpenParams_0040cd60.callback = owner_window;
    g_midiOpenParams_0040cd60.device_type = 0x20b;

    strcpy(path, g_midiAudioRoot_0040cd60);
    strcat(path, filename);

    g_midiOpenParams_0040cd60.element_name = path;
    open_error = mciSendCommandA(0, 0x0803, 0x3202, &g_midiOpenParams_0040cd60);
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
    SetCursor(LoadCursorA(0, (const char*)0x7f00));
}

extern "C" void __cdecl OtPlayMidiAudio_0000ced0_RealCpp(int play_mode)
{
    register unsigned int zero = 0;
    unsigned int play_error;
    char error_text[256];

    g_midiPlaybackActive_0040cd60 = zero;
    if (g_midiPlaybackAvailable_0040cd60 == zero) {
        return;
    }

    if (IsWindow(g_midiOpenParams_0040cd60.callback) == zero) {
        g_midiOpenParams_0040cd60.device_id = zero;
        return;
    }

    g_midiStatusParams_0040cd60.item = 7;
    if (mciSendCommandA(
            g_midiOpenParams_0040cd60.device_id,
            0x0814,
            0x0100,
            &g_midiStatusParams_0040cd60) != zero) {
        g_midiOpenParams_0040cd60.device_id = zero;
        return;
    }

    if (play_mode != -1) {
        g_midiPlayParams_0040cd60.from = zero;
        play_error = mciSendCommandA(
            g_midiOpenParams_0040cd60.device_id,
            0x0806,
            5,
            &g_midiPlayParams_0040cd60);
    } else {
        play_error = mciSendCommandA(
            g_midiOpenParams_0040cd60.device_id,
            0x0806,
            1,
            &g_midiPlayParams_0040cd60);
    }

    if (play_error == zero) {
        g_midiStatusParams_0040cd60.item = 4;
        do {
            mciSendCommandA(
                g_midiOpenParams_0040cd60.device_id,
                0x0814,
                0x0100,
                &g_midiStatusParams_0040cd60);
        } while (g_midiStatusParams_0040cd60.result == 0x020c);
        g_midiPlaybackActive_0040cd60 = 1;
        return;
    }

    if (mciGetErrorStringA(play_error, error_text, 0x100) != zero) {
        MessageBoxA(0, error_text, g_midiErrorTitle_0040cd60, 0);
        return;
    }
    MessageBoxA(0, g_unknownMidiError_0040cd60, g_midiErrorTitle_0040cd60, 0);
}

extern "C" void __cdecl OtOpenWaveAudioFile_0000d110_RealCpp(void* owner, char* logical_name)
{
    register void* owner_window = owner;
    register char* audio_root;
    unsigned int open_error;
    unsigned int clip_length;
    char clip_name[20];
    char path[100];

    if (g_waveAudioDisabled_0040d110 == 1) {
        return;
    }

    g_audioBusy_0040cd60 = 1;
    SetCursor(LoadCursorA(0, (const char*)0x7f02));

    strcpy(clip_name, logical_name);
    clip_length = strlen(logical_name);

    g_wavePlaybackActive_0040d110 = 0;
    g_waveStatusParams_0040d110.callback = owner_window;
    g_waveStatusParams_0040d110.result = 0;
    g_waveStatusParams_0040d110.item = 7;
    if (mciSendCommandA(
            g_waveOpenParams_0040d110.device_id,
            (clip_name[clip_length - 4] = '\0', 0x0814),
            0x0100,
            &g_waveStatusParams_0040d110) == 0 ||
        g_waveStatusParams_0040d110.result == 1) {
        OtCloseWaveAudioDevice_0040d0a0_RealCpp();
    }

    audio_root = g_midiAudioRoot_0040cd60;
    g_waveCloseParams_0040d110.callback = owner_window;
    g_wavePlayParams_0040d110.callback = owner_window;
    g_waveOpenParams_0040d110.callback = owner_window;
    g_waveOpenParams_0040d110.device_type = 0x20a;

    strcpy(path, audio_root);
    strcat(path, clip_name);
    strcat(path, g_waveStereoSuffix_0040d110);

    g_waveOpenParams_0040d110.element_name = path;
    open_error = mciSendCommandA(
        0,
        0x0803,
        0x3202,
        &g_waveOpenParams_0040d110);
    if (open_error == 0) {
        g_wavePlayParams_0040d110.from = 0;
        g_wavePlayParams_0040d110.to = 0;
        open_error = mciSendCommandA(
            g_waveOpenParams_0040d110.device_id,
            0x0806,
            0x0e,
            &g_wavePlayParams_0040d110);
        g_wavePlayParams_0040d110.to = 0xffffffff;
    }

    if (open_error != 0) {
        OtCloseWaveAudioDevice_0040d0a0_RealCpp();
        strcpy(path, g_midiAudioRoot_0040cd60);
        strcat(path, clip_name);
        strcat(path, g_waveMonoSuffix_0040d110);
        g_waveOpenParams_0040d110.element_name = path;
        open_error = mciSendCommandA(
            g_waveOpenParams_0040d110.device_id,
            0x0803,
            0x3202,
            &g_waveOpenParams_0040d110);
    }

    if (open_error == 0) {
        g_waveAudioDisabled_0040d110 = 0;
        goto wave_open_done;
    }
    g_waveAudioDisabled_0040d110 = 1;

wave_open_done:
    if (open_error == 0x0108) {
        MessageBoxA(
            owner_window,
            g_outOfMemoryMessage_0040cd60,
            g_outOfMemoryTitle_0040cd60,
            0x30);
    }

    g_audioBusy_0040cd60 = 0;
    SetCursor(LoadCursorA(0, (const char*)0x7f00));
}

extern "C" void __cdecl OtStopMidiAudioDirectImport_0040d010_RealCpp()
{
    if (g_midiPlaybackAvailable_0040cd60 == 0) {
        return;
    }

    if (IsWindow(g_midiOpenParams_0040cd60.callback) == 0) {
        g_midiOpenParams_0040cd60.device_id = 0;
        g_midiPlaybackActive_0040cd60 = 0;
        return;
    }

    g_midiStatusParams_0040cd60.item = 7;
    if (mciSendCommandA(
            g_midiOpenParams_0040cd60.device_id,
            0x0814,
            0x0100,
            &g_midiStatusParams_0040cd60) != 0) {
        g_midiOpenParams_0040cd60.device_id = 0;
        g_midiPlaybackActive_0040cd60 = 0;
        return;
    }

    if (mciSendCommandA(
            g_midiOpenParams_0040cd60.device_id,
            0x0808,
            2,
            &g_midiCloseParams_0040cd60) != 0) {
        g_midiPlaybackActive_0040cd60 = 0;
    }
}

extern "C" void __cdecl OtPlayWaveAudioDirectImport_0040d3e0_RealCpp()
{
    if (g_waveAudioDisabled_0040d110 == 1) {
        return;
    }

    g_wavePlaybackActive_0040d110 = 0;

    if (IsWindow(g_waveOpenParams_0040d110.callback) == 0) {
        g_waveOpenParams_0040d110.device_id = 0;
        return;
    }

    g_waveStatusParams_0040d110.item = 7;
    if (mciSendCommandA(
            g_waveOpenParams_0040d110.device_id,
            0x0814,
            0x0100,
            &g_waveStatusParams_0040d110) != 0) {
        g_waveOpenParams_0040d110.device_id = 0;
        return;
    }

    g_wavePlayParams_0040d110.from = 0;
    if (mciSendCommandA(
            g_waveOpenParams_0040d110.device_id,
            0x0806,
            5,
            &g_wavePlayParams_0040d110) == 0) {
        g_wavePlaybackActive_0040d110 = 1;
    }
}

/**
 * Purpose: stop active wave playback through MCI and mark the wave channel as
 * having a pending stop when the command succeeds.
 *
 * Parameters: none.
 */
extern "C" void __cdecl OtStopWaveAudioAlt1_0040d480_45pct()
{
    register unsigned long (__stdcall *mci_send)(
        unsigned int,
        unsigned int,
        unsigned long,
        void*);

    if (IsWindow(g_waveOpenParams_0040d110.callback) != 0) {
        unsigned int device = g_waveOpenParams_0040d110.device_id;
        g_waveStatusParams_0040d110.item = 7;
        mci_send = mciSendCommandA;

        if (mci_send(
                device,
                0x0814,
                0x0100,
                &g_waveStatusParams_0040d110) != 0) {
            g_waveOpenParams_0040d110.device_id = 0;
            return;
        }

        if (mci_send(
                g_waveOpenParams_0040d110.device_id,
                0x0808,
                2,
                &g_waveCloseParams_0040d110) == 0) {
            g_wavePlaybackActive_0040d110 = 1;
        }
    }
}

/**
 * Purpose: stop active wave playback through MCI and mark the wave channel as
 * having a pending stop when the command succeeds.
 *
 * Parameters: none.
 */
extern "C" void __cdecl OtStopWaveAudioAlt2_0040d480_45pct()
{
    register unsigned long (__stdcall *mci_send)(
        unsigned int,
        unsigned int,
        unsigned long,
        void*);

    if (IsWindow(g_waveOpenParams_0040d110.callback) != 0) {
        g_waveStatusParams_0040d110.item = 7;
        unsigned int device = g_waveOpenParams_0040d110.device_id;
        mci_send = mciSendCommandA;

        if (mci_send(
                device,
                0x0814,
                0x0100,
                &g_waveStatusParams_0040d110) != 0) {
            g_waveOpenParams_0040d110.device_id = 0;
            return;
        }

        device = g_waveOpenParams_0040d110.device_id;
        if (mci_send(
                device,
                0x0808,
                2,
                &g_waveCloseParams_0040d110) == 0) {
            g_wavePlaybackActive_0040d110 = 1;
        }
    }
}

/**
 * Purpose: stop active wave playback through MCI and mark the wave channel as
 * having a pending stop when the command succeeds.
 *
 * Parameters: none.
 */
extern "C" void __cdecl OtStopWaveAudioAlt3_0040d480_45pct()
{
    register unsigned long (__stdcall *mci_send)(
        unsigned int,
        unsigned int,
        unsigned long,
        void*);

    if (IsWindow(g_waveOpenParams_0040d110.callback) != 0) {
        g_waveStatusParams_0040d110.item = 7;

        if ((mci_send = mciSendCommandA)(
                g_waveOpenParams_0040d110.device_id,
                0x0814,
                0x0100,
                &g_waveStatusParams_0040d110) != 0) {
            g_waveOpenParams_0040d110.device_id = 0;
            return;
        }

        if (mci_send(
                g_waveOpenParams_0040d110.device_id,
                0x0808,
                2,
                &g_waveCloseParams_0040d110) == 0) {
            g_wavePlaybackActive_0040d110 = 1;
        }
    }
}

extern "C" void __cdecl OtStopWaveAudioDirectImport_0040d480_RealCpp()
{
    if (IsWindow(g_waveOpenParams_0040d110.callback) != 0) {
        g_waveStatusParams_0040d110.item = 7;

        if (mciSendCommandA(
                g_waveOpenParams_0040d110.device_id,
                0x0814,
                0x0100,
                &g_waveStatusParams_0040d110) != 0) {
            g_waveOpenParams_0040d110.device_id = 0;
            return;
        }

        if (mciSendCommandA(
                g_waveOpenParams_0040d110.device_id,
                0x0808,
                2,
                &g_waveCloseParams_0040d110) == 0) {
            g_wavePlaybackActive_0040d110 = 1;
        }
    }
}
