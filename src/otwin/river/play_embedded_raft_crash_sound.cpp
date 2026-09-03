// Semantic recovery candidate for OtPlayEmbeddedRaftCrashSound @ 0x00428e10.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "river_runtime.h"
#include "raft_crash_sound_state.h"

extern "C" void* g_applicationModule_00405a40_20260603;
extern "C" int g_cdMediaMode_00439108;
extern "C" void __cdecl OtCloseWaveAudioDevice_0040d0a0_RealCpp();

#pragma comment(lib, "winmm.lib")
#pragma comment(lib, "kernel32.lib")

#pragma optimize("s", off)
#pragma optimize("t", on)

void RaftingDialogState_00428e10::
    OtPlayEmbeddedRaftCrashSoundAlt3_00428e10_RealCpp()
{
    register RaftCrashSoundStorage_00428e10* state =
        reinterpret_cast<RaftCrashSoundStorage_00428e10*>(this);

    sndPlaySoundA(0, 0);

    void* cached_resource = state->crash_wave_resource;
    if (cached_resource != 0) {
        FreeResource(cached_resource);
        state->crash_wave_resource = 0;
    }

    void* resource_info = FindResourceA(
        g_applicationModule_00405a40_20260603,
        (const void*)0x4e3e,
        (const void*)10);
    state->crash_wave_resource =
        LoadResource(g_applicationModule_00405a40_20260603, resource_info);

    if (g_cdMediaMode_00439108 != 0) {
        OtCloseWaveAudioDevice_0040d0a0_RealCpp();
    }

    cached_resource = state->crash_wave_resource;
    if (cached_resource != 0) {
        const char* sound = (const char*)LockResource(cached_resource);
        sndPlaySoundA(sound, 5);
    }
}

#pragma optimize("", on)
