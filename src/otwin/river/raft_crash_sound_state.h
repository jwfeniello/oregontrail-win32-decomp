#ifndef OTWIN_RIVER_RAFT_CRASH_SOUND_STATE_H
#define OTWIN_RIVER_RAFT_CRASH_SOUND_STATE_H

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This recovered runtime requires 32-bit MSVC."
#endif

#pragma pack(push, 1)
struct RaftingDialogState_00428e10 {
    void OtPlayEmbeddedRaftCrashSoundAlt3_00428e10_RealCpp();
};

struct RaftCrashSoundStorage_00428e10 {
    char reserved_00[0x38];
    void* crash_wave_resource;
};
#pragma pack(pop)

typedef char RaftCrashSoundStorage_00428e10_size_must_be_0x3c[
    sizeof(RaftCrashSoundStorage_00428e10) == 0x3c ? 1 : -1];

#endif
