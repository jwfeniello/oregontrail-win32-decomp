#ifndef OTWIN_TRAIL_ACCEPTED_SEMANTIC_DEPENDENCIES_H
#define OTWIN_TRAIL_ACCEPTED_SEMANTIC_DEPENDENCIES_H

// Product-facing declarations for byte-verified semantic implementations.
// Keep callers on the accepted bodies instead of the matcher-only dependency
// aliases that live in excluded staging translation units.

#pragma pack(push, 1)
struct PartyHealthScoreState_00419560_80pct {
    char reserved_000[0x9a];
    short health_penalty_a;
    short health_penalty_b;
    short wagon_wheels;
    short wagon_axles;
    short wagon_tongues;
    short food_from_plants;
    short food_from_hunting;

    short OtComputePartyHealthScore_RealCpp() const;
    int OtGetPartyHealthClassStringId_RealCpp() const;
};
#pragma pack(pop)

extern "C" short __fastcall
OtChooseRandomLivingPartyMemberSlotAlt27NoAsm_004195f0_40pct(
    const void* journey);

extern "C" int __cdecl
OtRunModalDialogAndRefreshParentAlt1_00401530_38pct(
    void* instance,
    void* parent_window,
    void* dialog_proc,
    const char* template_name,
    long init_param);

extern "C" void __cdecl OtStopMidiAudioDirectImport_0040d010_RealCpp();
extern "C" void __cdecl OtCloseWaveAudioDevice_0040d0a0_RealCpp();
extern "C" void __cdecl OtCloseMidiAudioDeviceNoAsm_0040ccf0_RealCpp();

#endif
