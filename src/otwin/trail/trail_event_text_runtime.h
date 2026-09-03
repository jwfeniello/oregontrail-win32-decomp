#ifndef OTWIN_TRAIL_EVENT_TEXT_RUNTIME_H
#define OTWIN_TRAIL_EVENT_TEXT_RUNTIME_H

// Canonical layout of the trail-event text runtime at original address
// 0x0043b6a0.  The final flag is at +0x38c (0x0043ba2c), so the complete
// storage range is 0x0043b6a0 through 0x0043ba2f: exactly 0x390 bytes.
#pragma pack(push, 1)
struct TrailEventTextRuntime_0041aac0_20260603 {
    char* name_pointer;                  // +0x000
    char* active_name_pointer;           // +0x004
    char* event_argument_pointer;        // +0x008
    char reserved_00c[0x04];             // +0x00c
    short cached_pronoun_mode;           // +0x010
    char unknown_text[0x0a];             // +0x012
    char subject_text[0x0a];             // +0x01c
    char capitalized_subject_text[0x0a]; // +0x026
    char object_text[0x0a];              // +0x030
    char possessive_text[0x0a];          // +0x03a
    char verb_text[0x0a];                // +0x044
    char capitalized_verb_text[0x0a];    // +0x04e
    char possessive_noun_text[0x0a];     // +0x058
    char reflexive_text[0x0a];           // +0x062
    char primary_text[0x190];            // +0x06c
    char secondary_text[0x190];          // +0x1fc
    int death_prefix_pending;             // +0x38c

    void OtPrepareMessagePronounSet_0001aac0_Wip(short requested_mode);
    char* OtFormatGameMessageText_0001ac80_ProductWip(int string_id);
    void OtSetTrailEventTextDependency_RealCpp(int string_id);
};

// OtFormatDelayDaysText treats the same global runtime as this prefix and
// writes its result into the +0x12 scratch text slot.
struct DelayTextState_0041ac20 {
    char reserved_00[0x12];
    char delay_text[0x0a];

    void OtFormatDelayDaysText_RealCpp(short days);
};
#pragma pack(pop)

typedef char OtTrailEventTextRuntimeSizeMustBe0x390[
    (sizeof(TrailEventTextRuntime_0041aac0_20260603) == 0x390) ? 1 : -1];

extern "C" TrailEventTextRuntime_0041aac0_20260603
    g_trailEventRuntimeState;

#endif
