// Product-tree semantic closure for OtPrepareMessagePronounSet_0001aac0.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "trail_event_text_runtime.h"

extern "C" __declspec(dllimport) int __stdcall LoadStringA(
    void* instance,
    unsigned int string_id,
    char* buffer,
    int buffer_max);
extern "C" __declspec(dllimport) unsigned long __stdcall CharUpperBuffA(
    char* buffer,
    unsigned long length);

extern "C" void* g_resourceModule;
extern "C" void* g_journeyState;
extern "C" short __fastcall OtCountLivingPartyMembers_RealCpp(const void* party);

#pragma optimize("s", off)
#pragma optimize("t", on)

void TrailEventTextRuntime_0041aac0_20260603::
    OtPrepareMessagePronounSet_0001aac0_Wip(short requested_mode)
{
    short mode;

    if (requested_mode < 0 || requested_mode >= 3) {
        return;
    }

    if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 1 &&
        requested_mode == 1) {
        mode = 2;
    } else {
        mode = requested_mode;
    }

    if (cached_pronoun_mode == mode) {
        return;
    }

    {
        register int string_base = static_cast<int>(mode);

        LoadStringA(
            g_resourceModule,
            static_cast<unsigned int>(string_base + 0x226),
            subject_text,
            10);
        LoadStringA(
            g_resourceModule,
            static_cast<unsigned int>(string_base + 0x226),
            capitalized_subject_text,
            10);
        CharUpperBuffA(capitalized_subject_text, 1);
        LoadStringA(
            g_resourceModule,
            static_cast<unsigned int>(string_base + 0x229),
            object_text,
            10);
        LoadStringA(
            g_resourceModule,
            static_cast<unsigned int>(string_base + 0x22c),
            possessive_text,
            10);
        LoadStringA(
            g_resourceModule,
            static_cast<unsigned int>(string_base + 0x231),
            verb_text,
            10);
        LoadStringA(
            g_resourceModule,
            static_cast<unsigned int>(string_base + 0x231),
            capitalized_verb_text,
            10);
        LoadStringA(
            g_resourceModule,
            static_cast<unsigned int>(string_base + 0x237),
            reflexive_text,
            10);
        LoadStringA(
            g_resourceModule,
            static_cast<unsigned int>(string_base + 0x234),
            possessive_noun_text,
            10);
        CharUpperBuffA(capitalized_verb_text, 1);
    }

    cached_pronoun_mode = mode;

    if (OtCountLivingPartyMembers_RealCpp(g_journeyState) == 1 &&
        requested_mode == 1) {
        active_name_pointer = subject_text;
        return;
    }

    active_name_pointer = name_pointer;
}

#pragma optimize("", on)
