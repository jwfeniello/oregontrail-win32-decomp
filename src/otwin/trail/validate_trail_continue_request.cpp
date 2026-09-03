// Focused exact-to-semantic trials for OtValidateTrailContinueRequest.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#pragma pack(push, 1)
struct JourneyState_0042a590 {
    char reserved_000[0x5a];
    unsigned short route_stop_flags;
    char reserved_05c[0x3a];
    short trail_continue_days;
};
#pragma pack(pop)

extern "C" JourneyState_0042a590* g_journeyState;

extern "C" int __cdecl OtRunSharedMessageDialog_00401e70_RealCpp(
    void* parent_window,
    const char* message_text,
    const char* caption_text,
    int use_alternate_template);

extern "C" short __fastcall OtCountLivingPartyMembers_RealCpp(
    const JourneyState_0042a590* journey);

extern "C" const char kTrailNeedWagonWheelText_0042a590[] =
    "You can't continue because you need a wagon wheel.  You will have to "
    "trade for one.";
extern "C" const char kTrailNeedWagonAxleText_0042a590[] =
    "You can't continue because you need an axle.  You will have to trade "
    "for one.";
extern "C" const char kTrailNeedWagonTongueText_0042a590[] =
    "You can't continue because you need a wagon tongue.  You will have to "
    "trade for one.";
extern "C" const char kTrailNoOxenText_0042a590[] =
    "You can't continue because you don't have any oxen.  You will have to "
    "trade for some.";
extern "C" const char kTrailOneSickOxText_0042a590[] =
    "You can't continue because you have only one ox, and it is sick.  You "
    "will have to trade for more oxen.";
extern "C" const char kTrailCannotContinueCaption_0042a590[] =
    "Can't Continue";

#pragma optimize("s", off)
#pragma optimize("t", on)
#pragma optimize("a", on)

extern "C" __declspec(dllexport) int __stdcall
OtValidateTrailContinueRequestAlt1_0042a590_RealCpp(void* parent_window)
{
    register int can_continue = 0;
    unsigned short flags = g_journeyState->route_stop_flags;

    if ((flags & 1) == 0 && g_journeyState->trail_continue_days > 0) {
        if ((flags & 2) != 0) {
            OtRunSharedMessageDialog_00401e70_RealCpp(
                parent_window,
                kTrailNeedWagonWheelText_0042a590,
                kTrailCannotContinueCaption_0042a590,
                can_continue);
            return can_continue;
        }
        if ((flags & 4) != 0) {
            OtRunSharedMessageDialog_00401e70_RealCpp(
                parent_window,
                kTrailNeedWagonAxleText_0042a590,
                kTrailCannotContinueCaption_0042a590,
                0);
            return can_continue;
        }
        if ((flags & 8) != 0) {
            OtRunSharedMessageDialog_00401e70_RealCpp(
                parent_window,
                kTrailNeedWagonTongueText_0042a590,
                kTrailCannotContinueCaption_0042a590,
                0);
            return can_continue;
        }
        if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 0) {
            can_continue = 1;
            return can_continue;
        }
    } else {
        if (g_journeyState->trail_continue_days <= 0) {
            OtRunSharedMessageDialog_00401e70_RealCpp(
                parent_window,
                kTrailNoOxenText_0042a590,
                kTrailCannotContinueCaption_0042a590,
                0);
            return can_continue;
        }
        OtRunSharedMessageDialog_00401e70_RealCpp(
            parent_window,
            kTrailOneSickOxText_0042a590,
            kTrailCannotContinueCaption_0042a590,
            0);
    }

    return can_continue;
}

extern "C" __declspec(dllexport) int __stdcall
OtValidateTrailContinueRequestAlt2_0042a590_RealCpp(void* parent_window)
{
    register short zero = 0;
    unsigned short flags = g_journeyState->route_stop_flags;

    if ((flags & 1) == 0 && g_journeyState->trail_continue_days > zero) {
        if ((flags & 2) != 0) {
            OtRunSharedMessageDialog_00401e70_RealCpp(
                parent_window,
                kTrailNeedWagonWheelText_0042a590,
                kTrailCannotContinueCaption_0042a590,
                zero);
            return zero;
        }
        if ((flags & 4) != 0) {
            OtRunSharedMessageDialog_00401e70_RealCpp(
                parent_window,
                kTrailNeedWagonAxleText_0042a590,
                kTrailCannotContinueCaption_0042a590,
                zero);
            return zero;
        }
        if ((flags & 8) != 0) {
            OtRunSharedMessageDialog_00401e70_RealCpp(
                parent_window,
                kTrailNeedWagonTongueText_0042a590,
                kTrailCannotContinueCaption_0042a590,
                zero);
            return zero;
        }
        if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > zero) {
            return 1;
        }
    } else {
        if (g_journeyState->trail_continue_days <= 0) {
            OtRunSharedMessageDialog_00401e70_RealCpp(
                parent_window,
                kTrailNoOxenText_0042a590,
                kTrailCannotContinueCaption_0042a590,
                zero);
            return zero;
        }
        OtRunSharedMessageDialog_00401e70_RealCpp(
            parent_window,
            kTrailOneSickOxText_0042a590,
            kTrailCannotContinueCaption_0042a590,
            zero);
    }

    return zero;
}

#pragma optimize("", on)

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" __declspec(dllexport) int __stdcall
OtValidateTrailContinueRequestAlt3_0042a590_RealCpp(void* parent_window)
{
    register int can_continue = 0;
    unsigned short flags = g_journeyState->route_stop_flags;

    if ((flags & 1) == 0 && g_journeyState->trail_continue_days > 0) {
        if ((flags & 2) != 0) {
            OtRunSharedMessageDialog_00401e70_RealCpp(
                parent_window,
                kTrailNeedWagonWheelText_0042a590,
                kTrailCannotContinueCaption_0042a590,
                can_continue);
            goto done;
        }
        if ((flags & 4) != 0) {
            OtRunSharedMessageDialog_00401e70_RealCpp(
                parent_window,
                kTrailNeedWagonAxleText_0042a590,
                kTrailCannotContinueCaption_0042a590,
                can_continue);
            goto done;
        }
        if ((flags & 8) != 0) {
            OtRunSharedMessageDialog_00401e70_RealCpp(
                parent_window,
                kTrailNeedWagonTongueText_0042a590,
                kTrailCannotContinueCaption_0042a590,
                can_continue);
            goto done;
        }
        if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 0) {
            can_continue = 1;
            goto done;
        }
    } else {
        if (g_journeyState->trail_continue_days <= 0) {
            OtRunSharedMessageDialog_00401e70_RealCpp(
                parent_window,
                kTrailNoOxenText_0042a590,
                kTrailCannotContinueCaption_0042a590,
                can_continue);
            goto done;
        }
        OtRunSharedMessageDialog_00401e70_RealCpp(
            parent_window,
            kTrailOneSickOxText_0042a590,
            kTrailCannotContinueCaption_0042a590,
            can_continue);
    }

done:
    return can_continue;
}

#pragma optimize("", on)
