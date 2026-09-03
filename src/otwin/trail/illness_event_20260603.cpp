// Product-tree semantic closure for OtRunIllnessEvent @ 0x00417b90.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

extern "C" __declspec(dllimport) long __stdcall SendMessageA(
    void* window,
    unsigned int message,
    unsigned int wparam,
    long lparam);

extern "C" int __cdecl OtRandomBelow_RealCpp(int upper_bound);
extern "C" short __fastcall
OtChooseRandomLivingPartyMemberSlotAlt27NoAsm_004195f0_40pct(
    const void* party);
extern "C" short __fastcall OtCountLivingPartyMembers_RealCpp(
    const void* party);

struct TrailEventContextSource_004163c0 {
    void OtPrimeActiveTrailEventContext_004163c0_RealCpp();
};

struct TrailEventTextRuntime_0041aac0_20260603 {
    char* OtFormatGameMessageText_0001ac80_ProductWip(int string_id);
};

struct TrailDateState_00419280 {
    void OtAdvanceGameDate_RealCpp();
};

#pragma pack(push, 1)
struct RouteDescriptor_00417b90_20260603 {
    char reserved_00[2];
    short route_kind;
};

struct TrailEventDate_00417b90_20260603 {
    char bytes[0x1a];

    void OtAdvanceGameDateDependency_00417b90();
};

struct JourneyState_00417b90_20260603 {
    char reserved_000[0x8a];
    short doctor_seen_today;
    char reserved_08c[0x20];
    short trail_condition;
    char reserved_0ae[0x10];
    short health_score;
    char party_member_names[5][15];
    char reserved_10b[1];
    short recovery_days[5];
    short member_state[5];
    char reserved_120[4];
    TrailEventDate_00417b90_20260603 current_date;
    TrailEventDate_00417b90_20260603 founder_death_date;
};

struct TrailEventTextState_00417b90_20260603 {
    void* first_argument;

    void OtFormatGameMessageTextDependency_00417b90(int string_id);
};

struct TrailEventDeathDispatcher_00417b90_20260603 {
    virtual void OtDispatchIllnessDeathFollowupDependency_00417b90(int reason);
};

struct TrailEventRunner_00417b90_20260603 {
    char reserved_00[6];
    short message_count;

    void OtPrimeActiveTrailEventContextDependency_00417b90();
    void OtRunIllnessEvent_RealCpp();
};
#pragma pack(pop)

extern "C" JourneyState_00417b90_20260603* g_journeyState;
extern "C" RouteDescriptor_00417b90_20260603* g_activeRouteDescriptor;
extern "C" TrailEventTextState_00417b90_20260603 g_trailEventRuntimeState;
extern "C" TrailEventDeathDispatcher_00417b90_20260603* g_pendingTrailEventDispatcher;
extern "C" void* g_trailEventDialogWindow;
extern "C" char g_trailEventMessageBuffer[];
extern "C" int g_founderDeathDatePending_00417b90_20260603 = 0;

#pragma code_seg(".otsem")
void TrailEventRunner_00417b90_20260603::
    OtPrimeActiveTrailEventContextDependency_00417b90()
{
    reinterpret_cast<TrailEventContextSource_004163c0*>(this)->
        OtPrimeActiveTrailEventContext_004163c0_RealCpp();
}

void TrailEventTextState_00417b90_20260603::
    OtFormatGameMessageTextDependency_00417b90(int string_id)
{
    reinterpret_cast<TrailEventTextRuntime_0041aac0_20260603*>(this)->
        OtFormatGameMessageText_0001ac80_ProductWip(string_id);
}

void TrailEventDate_00417b90_20260603::
    OtAdvanceGameDateDependency_00417b90()
{
    reinterpret_cast<TrailDateState_00419280*>(this)->
        OtAdvanceGameDate_RealCpp();
}
#pragma code_seg()

#pragma optimize("s", off)
#pragma optimize("t", on)

// Assigns or worsens an illness for one living party member. A first illness
// records recovery time; an already-ill member may receive a doctor/recovery
// message, otherwise the event marks the member dead and posts the follow-up.
void TrailEventRunner_00417b90_20260603::OtRunIllnessEvent_RealCpp()
{
    TrailEventRunner_00417b90_20260603* event = this;
    int already_ill = 0;
    short member;
    short illness;
    int member_index;
    int message_id;
    short* illness_slot;
    short old_illness;
    short doctor_threshold;

    event->OtPrimeActiveTrailEventContextDependency_00417b90();
    member = OtChooseRandomLivingPartyMemberSlotAlt27NoAsm_004195f0_40pct(
        g_journeyState);
    illness = static_cast<short>(OtRandomBelow_RealCpp(6) + 1);
    member_index = member;
    message_id = illness + 0x2bb;

    g_trailEventRuntimeState.first_argument =
        &g_journeyState->party_member_names[member_index][0];

    illness_slot = &g_journeyState->member_state[member_index];
    old_illness = *illness_slot;
    if (old_illness != 0) {
        int near_doctor;

        already_ill = 1;
        if (g_journeyState->doctor_seen_today != 0 ||
            g_activeRouteDescriptor->route_kind != 2) {
            near_doctor = 0;
        } else {
            near_doctor = 1;
        }

        if (member != 0 &&
            (near_doctor != 0 || g_journeyState->trail_condition == 3)) {
            if (old_illness == 7 || old_illness == 8) {
                doctor_threshold = 0x32;
            } else {
                doctor_threshold = 0x1e;
            }

            if (OtRandomBelow_RealCpp(100) < doctor_threshold) {
                g_trailEventRuntimeState.
                    OtFormatGameMessageTextDependency_00417b90(0x2c9);

                if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 0 ||
                    event->message_count == 1) {
                    SendMessageA(
                        g_trailEventDialogWindow,
                        0x477,
                        static_cast<unsigned short>(event->message_count),
                        reinterpret_cast<long>(g_trailEventMessageBuffer));
                }

                member = g_journeyState->recovery_days[member_index];
                if (member >= 3) {
                    return;
                }

                {
                    short updated_recovery_days =
                        static_cast<short>(
                            OtRandomBelow_RealCpp(3) + member);
                    g_journeyState->recovery_days[member_index] =
                        updated_recovery_days;
                }
                return;
            }
        }
    } else {
        *illness_slot = illness;
        g_journeyState->recovery_days[member_index] =
            static_cast<short>(OtRandomBelow_RealCpp(3) + 9);
    }

    if (already_ill != 0) {
        message_id += 6;
        g_journeyState->member_state[member_index] = 0x0f;
        if (g_journeyState->health_score > 0x69) {
            g_journeyState->health_score = 0x69;
        }

        if (member == 0) {
            g_founderDeathDatePending_00417b90_20260603 = 1;
            g_journeyState->founder_death_date = g_journeyState->current_date;
            g_journeyState->founder_death_date.
                OtAdvanceGameDateDependency_00417b90();
        }
    }

    g_trailEventRuntimeState.OtFormatGameMessageTextDependency_00417b90(
        message_id);

    if (already_ill != 0) {
        g_pendingTrailEventDispatcher->
            OtDispatchIllnessDeathFollowupDependency_00417b90(1);
        return;
    }

    if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 0 ||
        event->message_count == 1) {
        SendMessageA(
            g_trailEventDialogWindow,
            0x477,
            static_cast<unsigned short>(event->message_count),
            reinterpret_cast<long>(g_trailEventMessageBuffer));
    }
}

#pragma optimize("", on)
