// Semantic implementation of OtPlayCurrentRouteAudioCue @ 0x00405e00.
//
// The accepted verifier body retains the original free-function ABI.  The
// product graph also exposes the member-shaped symbol used by recovered trail
// callers; that bridge delegates to this same implementation.

#if 1

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "audio_runtime.h"
#include <string.h>

#pragma intrinsic(strlen)
#pragma intrinsic(strcat)

#pragma comment(lib, "user32.lib")

extern "C" int g_titleThemeEnabled_004390ec;
extern "C" int g_cdMediaMode_00439108;
extern "C" void* g_resourceModule;
extern "C" void* g_activeRouteDescriptor;

static const char kMidiAudioSuffix_00405e00[] = ".mid";

struct TrailOverlayWindow_00405df0 {
    void OtPlayCurrentRouteAudioCue_00405e00_ProductWip(
        void* owner_window);
};

extern "C" void __cdecl OtStopMidiAudioDirectImport_0040d010_RealCpp();
extern "C" void __cdecl OtOpenWaveAudioFile_0000d110_RealCpp(
    void* owner,
    char* clip_name);
extern "C" void __cdecl OtPlayWaveAudioDirectImport_0040d3e0_RealCpp();
extern "C" void __cdecl OtCloseMidiAudioDeviceNoAsm_0040ccf0_RealCpp();
extern "C" void __cdecl OtOpenMidiAudioFileMaskClosed_0000cd60_RealCpp(
    void* owner,
    const char* clip_name);
extern "C" void __cdecl OtPlayMidiAudio_0000ced0_RealCpp(int restart);

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" void __stdcall OtPlayCurrentRouteAudioCue_00005e00_RealCpp(void* owner)
{
    char clip_name[20];

    if (g_titleThemeEnabled_004390ec != 0) {
        if (g_cdMediaMode_00439108 != 0) {
            OtStopMidiAudioDirectImport_0040d010_RealCpp();
            LoadStringA(
                g_resourceModule,
                (unsigned int)
                    *(unsigned short*)g_activeRouteDescriptor * 0x10 + 0xd1,
                clip_name,
                0x13);
            OtOpenWaveAudioFile_0000d110_RealCpp(owner, clip_name);
            OtPlayWaveAudioDirectImport_0040d3e0_RealCpp();
            return;
        }

        OtCloseMidiAudioDeviceNoAsm_0040ccf0_RealCpp();
        LoadStringA(
            g_resourceModule,
            (unsigned int)
                *(unsigned short*)g_activeRouteDescriptor * 0x10 + 0xd1,
            clip_name,
            0x13);
        clip_name[strlen(clip_name) - 4] = '\0';
        strcat(clip_name, kMidiAudioSuffix_00405e00);
        OtOpenMidiAudioFileMaskClosed_0000cd60_RealCpp(owner, clip_name);
        OtPlayMidiAudio_0000ced0_RealCpp(0);
    }
}

#pragma code_seg(".otsem")
void TrailOverlayWindow_00405df0::
    OtPlayCurrentRouteAudioCue_00405e00_ProductWip(void* owner_window)
{
    OtPlayCurrentRouteAudioCue_00005e00_RealCpp(owner_window);
}
#pragma code_seg()

#pragma optimize("", on)

#endif
