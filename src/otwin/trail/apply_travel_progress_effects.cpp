// Semantic candidates for applying per-day trail progress side effects.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#pragma pack(push, 1)
struct TrailDateState_00419280 {
    void OtAdvanceGameDate_RealCpp();
};

struct GraveSiteMarker_00412220_Product {
    char reserved_00[0x48];
};

struct JourneyState_00419bd0 {
    void OtApplyTrailStepProgress_RealCpp(int progress_percent);
};

struct JourneyState_00419f60 {
    char reserved_000[0x5a];
    unsigned short route_stop_flags;
    char reserved_05c[0x38];
    short delay_days;
    char reserved_096[0x8e];
    TrailDateState_00419280 calendar_state;

    void OtApplyTravelProgressEffects_RealCpp(unsigned int progress_percent);
    void OtApplyTravelProgressEffectsAlt1_00419f60(unsigned int progress_percent);
    void OtApplyTravelProgressEffectsAlt2_00419f60(unsigned int progress_percent);
    void OtApplyTravelProgressEffectsAlt3_00419f60(unsigned int progress_percent);
    void OtApplyTravelProgressEffectsAlt4_00419f60(unsigned int progress_percent);
    void OtApplyTravelProgressEffectsAlt5_00419f60(unsigned int progress_percent);
    void OtApplyTravelProgressEffectsAlt6_00419f60(unsigned int progress_percent);
    void OtApplyTravelProgressEffectsAlt7_00419f60(unsigned int progress_percent);
    void OtApplyTravelProgressEffectsAlt8_00419f60(unsigned int progress_percent);
};
#pragma pack(pop)

extern "C" GraveSiteMarker_00412220_Product* g_graveSiteRuntime;
extern "C" int __fastcall OtShouldTriggerGraveSiteEvent_00412220_Product(
    GraveSiteMarker_00412220_Product* marker);
extern "C" void __fastcall OtAdvanceWeatherState_004199a0_ProductWip(
    JourneyState_00419f60* journey);
extern "C" void __fastcall OtConsumeDailyFood_00419b50_Product(
    JourneyState_00419f60* journey);
extern "C" void __fastcall OtAdvancePartyHealthState_00419d40_ProductWip(
    JourneyState_00419f60* journey);
extern "C" void __cdecl OtTriggerTrailEventById_RealCpp(short event_id);
extern "C" void __cdecl OtRollTrailRandomEvents_00418d50_ProductWip();

#pragma optimize("s", off)
#pragma optimize("t", on)

// Applies travel progress for the current day, clears completed travel-delay
// flags, then advances trail food, weather, health, and random event state.
void JourneyState_00419f60::OtApplyTravelProgressEffects_RealCpp(
    unsigned int progress_percent)
{
    register JourneyState_00419f60* journey = this;

    journey->calendar_state.OtAdvanceGameDate_RealCpp();

    unsigned short route_stop_flags = journey->route_stop_flags;
    if ((route_stop_flags & 0x10) == 0 && (route_stop_flags & 0x60) == 0) {
        reinterpret_cast<JourneyState_00419bd0*>(journey)->
            OtApplyTrailStepProgress_RealCpp((int)progress_percent);
    } else {
        short delay_days = static_cast<short>(journey->delay_days - 1);
        journey->delay_days = delay_days;
        if (delay_days == 0) {
            if ((route_stop_flags & 0x10) != 0) {
                journey->route_stop_flags =
                    static_cast<unsigned short>(route_stop_flags ^ 0x10);
            }

            route_stop_flags = journey->route_stop_flags;
            if ((route_stop_flags & 0x20) != 0) {
                journey->route_stop_flags =
                    static_cast<unsigned short>(route_stop_flags ^ 0x20);
            }

            route_stop_flags = journey->route_stop_flags;
            if ((route_stop_flags & 0x40) != 0) {
                journey->route_stop_flags =
                    static_cast<unsigned short>(route_stop_flags ^ 0x40);
            }
        }
    }

    if (OtShouldTriggerGraveSiteEvent_00412220_Product(
            g_graveSiteRuntime) != 0) {
        OtTriggerTrailEventById_RealCpp(0x0c);
    }

    OtAdvanceWeatherState_004199a0_ProductWip(journey);
    OtConsumeDailyFood_00419b50_Product(journey);
    OtAdvancePartyHealthState_00419d40_ProductWip(journey);
    OtRollTrailRandomEvents_00418d50_ProductWip();
}

// Offset-oriented variant that follows Ghidra's storage reloads closely.
void JourneyState_00419f60::OtApplyTravelProgressEffectsAlt1_00419f60(
    unsigned int progress_percent)
{
    register JourneyState_00419f60* journey = this;
    unsigned short route_stop_flags;
    short delay_days;

    journey->calendar_state.OtAdvanceGameDate_RealCpp();
    route_stop_flags = *(unsigned short*)((char*)journey + 0x5a);
    if (((route_stop_flags & 0x10) == 0) && ((route_stop_flags & 0x60) == 0)) {
        reinterpret_cast<JourneyState_00419bd0*>(journey)->
            OtApplyTrailStepProgress_RealCpp((int)progress_percent);
    } else {
        delay_days = (short)(*(short*)((char*)journey + 0x94) - 1);
        *(short*)((char*)journey + 0x94) = delay_days;
        if (delay_days == 0) {
            if ((route_stop_flags & 0x10) != 0) {
                *(unsigned short*)((char*)journey + 0x5a) =
                    (unsigned short)(route_stop_flags ^ 0x10);
            }
            if ((*(unsigned short*)((char*)journey + 0x5a) & 0x20) != 0) {
                *(unsigned short*)((char*)journey + 0x5a) =
                    (unsigned short)(*(unsigned short*)((char*)journey + 0x5a) ^ 0x20);
            }
            if ((*(unsigned short*)((char*)journey + 0x5a) & 0x40) != 0) {
                *(unsigned short*)((char*)journey + 0x5a) =
                    (unsigned short)(*(unsigned short*)((char*)journey + 0x5a) ^ 0x40);
            }
        }
    }

    if (OtShouldTriggerGraveSiteEvent_00412220_Product(
            g_graveSiteRuntime) != 0) {
        OtTriggerTrailEventById_RealCpp(0x0c);
    }
    OtAdvanceWeatherState_004199a0_ProductWip(journey);
    OtConsumeDailyFood_00419b50_Product(journey);
    OtAdvancePartyHealthState_00419d40_ProductWip(journey);
    OtRollTrailRandomEvents_00418d50_ProductWip();
}

// Keeps the active-delay flag as a distinct 16-bit temporary so the first
// flag test can survive into the later clear path.
void JourneyState_00419f60::OtApplyTravelProgressEffectsAlt2_00419f60(
    unsigned int progress_percent)
{
    register JourneyState_00419f60* journey = this;
    unsigned short active_delay_flag;
    unsigned short route_stop_flags;
    short delay_days;

    journey->calendar_state.OtAdvanceGameDate_RealCpp();

    route_stop_flags = journey->route_stop_flags;
    active_delay_flag = route_stop_flags;
    active_delay_flag = static_cast<unsigned short>(active_delay_flag & 0x10);
    if (active_delay_flag != 0 || (route_stop_flags & 0x60) != 0) {
        delay_days = static_cast<short>(journey->delay_days - 1);
        journey->delay_days = delay_days;
        if (delay_days == 0) {
            if (active_delay_flag != 0) {
                route_stop_flags = static_cast<unsigned short>(route_stop_flags ^ 0x10);
                journey->route_stop_flags = route_stop_flags;
            }

            route_stop_flags = journey->route_stop_flags;
            if ((route_stop_flags & 0x20) != 0) {
                route_stop_flags = static_cast<unsigned short>(route_stop_flags ^ 0x20);
                journey->route_stop_flags = route_stop_flags;
            }

            route_stop_flags = journey->route_stop_flags;
            if ((route_stop_flags & 0x40) != 0) {
                route_stop_flags = static_cast<unsigned short>(route_stop_flags ^ 0x40);
                journey->route_stop_flags = route_stop_flags;
            }
        }
    } else {
        reinterpret_cast<JourneyState_00419bd0*>(journey)->
            OtApplyTrailStepProgress_RealCpp((int)progress_percent);
    }

    if (OtShouldTriggerGraveSiteEvent_00412220_Product(
            g_graveSiteRuntime) != 0) {
        OtTriggerTrailEventById_RealCpp(0x0c);
    }

    OtAdvanceWeatherState_004199a0_ProductWip(journey);
    OtConsumeDailyFood_00419b50_Product(journey);
    OtAdvancePartyHealthState_00419d40_ProductWip(journey);
    OtRollTrailRandomEvents_00418d50_ProductWip();
}

// Signed-short locals avoid AX-special immediate forms on some VC4 16-bit
// bitwise expressions.
void JourneyState_00419f60::OtApplyTravelProgressEffectsAlt3_00419f60(
    unsigned int progress_percent)
{
    register JourneyState_00419f60* journey = this;
    short route_stop_flags;
    short active_delay_flag;

    journey->calendar_state.OtAdvanceGameDate_RealCpp();
    route_stop_flags = *(short*)((char*)journey + 0x5a);
    active_delay_flag = route_stop_flags;
    active_delay_flag = (short)(active_delay_flag & 0x10);
    if (active_delay_flag == 0 && (route_stop_flags & 0x60) == 0) {
        reinterpret_cast<JourneyState_00419bd0*>(journey)->
            OtApplyTrailStepProgress_RealCpp((int)progress_percent);
    } else {
        short delay_days = (short)(*(short*)((char*)journey + 0x94) - 1);
        *(short*)((char*)journey + 0x94) = delay_days;
        if (delay_days == 0) {
            if (active_delay_flag != 0) {
                route_stop_flags = (short)(route_stop_flags ^ 0x10);
                *(short*)((char*)journey + 0x5a) = route_stop_flags;
            }
            route_stop_flags = *(short*)((char*)journey + 0x5a);
            if ((route_stop_flags & 0x20) != 0) {
                route_stop_flags = (short)(route_stop_flags ^ 0x20);
                *(short*)((char*)journey + 0x5a) = route_stop_flags;
            }
            route_stop_flags = *(short*)((char*)journey + 0x5a);
            if ((route_stop_flags & 0x40) != 0) {
                route_stop_flags = (short)(route_stop_flags ^ 0x40);
                *(short*)((char*)journey + 0x5a) = route_stop_flags;
            }
        }
    }

    if (OtShouldTriggerGraveSiteEvent_00412220_Product(
            g_graveSiteRuntime) != 0) {
        OtTriggerTrailEventById_RealCpp(0x0c);
    }

    OtAdvanceWeatherState_004199a0_ProductWip(journey);
    OtConsumeDailyFood_00419b50_Product(journey);
    OtAdvancePartyHealthState_00419d40_ProductWip(journey);
    OtRollTrailRandomEvents_00418d50_ProductWip();
}

void JourneyState_00419f60::OtApplyTravelProgressEffectsAlt4_00419f60(
    unsigned int progress_percent)
{
    register JourneyState_00419f60* journey = this;
    short route_stop_flags;
    register short active_delay_flag;
    short delay_days;

    journey->calendar_state.OtAdvanceGameDate_RealCpp();
    route_stop_flags = *(short*)((char*)journey + 0x5a);
    active_delay_flag = route_stop_flags;
    active_delay_flag = (short)(active_delay_flag & 0x10);
    if (active_delay_flag == 0 && (route_stop_flags & 0x60) == 0) {
        reinterpret_cast<JourneyState_00419bd0*>(journey)->
            OtApplyTrailStepProgress_RealCpp((int)progress_percent);
    } else {
        delay_days = (short)(*(short*)((char*)journey + 0x94) - 1);
        *(short*)((char*)journey + 0x94) = delay_days;
        if (delay_days == 0) {
            if (active_delay_flag != 0) {
                route_stop_flags = (short)(route_stop_flags ^ 0x10);
                *(short*)((char*)journey + 0x5a) = route_stop_flags;
            }
            route_stop_flags = *(short*)((char*)journey + 0x5a);
            if ((route_stop_flags & 0x20) != 0) {
                route_stop_flags = (short)(route_stop_flags ^ 0x20);
                *(short*)((char*)journey + 0x5a) = route_stop_flags;
            }
            route_stop_flags = *(short*)((char*)journey + 0x5a);
            if ((route_stop_flags & 0x40) != 0) {
                route_stop_flags = (short)(route_stop_flags ^ 0x40);
                *(short*)((char*)journey + 0x5a) = route_stop_flags;
            }
        }
    }

    if (OtShouldTriggerGraveSiteEvent_00412220_Product(
            g_graveSiteRuntime) != 0) {
        OtTriggerTrailEventById_RealCpp(0x0c);
    }

    OtAdvanceWeatherState_004199a0_ProductWip(journey);
    OtConsumeDailyFood_00419b50_Product(journey);
    OtAdvancePartyHealthState_00419d40_ProductWip(journey);
    OtRollTrailRandomEvents_00418d50_ProductWip();
}

void JourneyState_00419f60::OtApplyTravelProgressEffectsAlt5_00419f60(
    unsigned int progress_percent)
{
    register JourneyState_00419f60* journey = this;
    register short route_stop_flags;
    short active_delay_flag;
    short delay_days;

    journey->calendar_state.OtAdvanceGameDate_RealCpp();
    route_stop_flags = *(short*)((char*)journey + 0x5a);
    active_delay_flag = route_stop_flags;
    active_delay_flag = (short)(active_delay_flag & 0x10);
    if (active_delay_flag == 0 && (route_stop_flags & 0x60) == 0) {
        reinterpret_cast<JourneyState_00419bd0*>(journey)->
            OtApplyTrailStepProgress_RealCpp((int)progress_percent);
    } else {
        delay_days = (short)(*(short*)((char*)journey + 0x94) - 1);
        *(short*)((char*)journey + 0x94) = delay_days;
        if (delay_days == 0) {
            if (active_delay_flag != 0) {
                route_stop_flags = (short)(route_stop_flags ^ 0x10);
                *(short*)((char*)journey + 0x5a) = route_stop_flags;
            }
            route_stop_flags = *(short*)((char*)journey + 0x5a);
            if ((route_stop_flags & 0x20) != 0) {
                route_stop_flags = (short)(route_stop_flags ^ 0x20);
                *(short*)((char*)journey + 0x5a) = route_stop_flags;
            }
            route_stop_flags = *(short*)((char*)journey + 0x5a);
            if ((route_stop_flags & 0x40) != 0) {
                route_stop_flags = (short)(route_stop_flags ^ 0x40);
                *(short*)((char*)journey + 0x5a) = route_stop_flags;
            }
        }
    }

    if (OtShouldTriggerGraveSiteEvent_00412220_Product(
            g_graveSiteRuntime) != 0) {
        OtTriggerTrailEventById_RealCpp(0x0c);
    }

    OtAdvanceWeatherState_004199a0_ProductWip(journey);
    OtConsumeDailyFood_00419b50_Product(journey);
    OtAdvancePartyHealthState_00419d40_ProductWip(journey);
    OtRollTrailRandomEvents_00418d50_ProductWip();
}

void JourneyState_00419f60::OtApplyTravelProgressEffectsAlt6_00419f60(
    unsigned int progress_percent)
{
    register JourneyState_00419f60* journey = this;
    short route_stop_flags;
    register unsigned short active_delay_flag;
    short delay_days;

    journey->calendar_state.OtAdvanceGameDate_RealCpp();
    route_stop_flags = *(short*)((char*)journey + 0x5a);
    active_delay_flag = (unsigned short)route_stop_flags;
    active_delay_flag = (unsigned short)(active_delay_flag & 0x10);
    if (active_delay_flag == 0 && (route_stop_flags & 0x60) == 0) {
        reinterpret_cast<JourneyState_00419bd0*>(journey)->
            OtApplyTrailStepProgress_RealCpp((int)progress_percent);
    } else {
        delay_days = (short)(*(short*)((char*)journey + 0x94) - 1);
        *(short*)((char*)journey + 0x94) = delay_days;
        if (delay_days == 0) {
            if (active_delay_flag != 0) {
                route_stop_flags = (short)(route_stop_flags ^ 0x10);
                *(short*)((char*)journey + 0x5a) = route_stop_flags;
            }
            route_stop_flags = *(short*)((char*)journey + 0x5a);
            if ((route_stop_flags & 0x20) != 0) {
                route_stop_flags = (short)(route_stop_flags ^ 0x20);
                *(short*)((char*)journey + 0x5a) = route_stop_flags;
            }
            route_stop_flags = *(short*)((char*)journey + 0x5a);
            if ((route_stop_flags & 0x40) != 0) {
                route_stop_flags = (short)(route_stop_flags ^ 0x40);
                *(short*)((char*)journey + 0x5a) = route_stop_flags;
            }
        }
    }

    if (OtShouldTriggerGraveSiteEvent_00412220_Product(
            g_graveSiteRuntime) != 0) {
        OtTriggerTrailEventById_RealCpp(0x0c);
    }

    OtAdvanceWeatherState_004199a0_ProductWip(journey);
    OtConsumeDailyFood_00419b50_Product(journey);
    OtAdvancePartyHealthState_00419d40_ProductWip(journey);
    OtRollTrailRandomEvents_00418d50_ProductWip();
}

void JourneyState_00419f60::OtApplyTravelProgressEffectsAlt7_00419f60(
    unsigned int progress_percent)
{
    register JourneyState_00419f60* journey = this;
    short delay_days;
    short active_delay_flag;
    short route_stop_flags;

    journey->calendar_state.OtAdvanceGameDate_RealCpp();
    route_stop_flags = *(short*)((char*)journey + 0x5a);
    active_delay_flag = route_stop_flags;
    active_delay_flag = (short)(active_delay_flag & 0x10);
    if (active_delay_flag == 0 && (route_stop_flags & 0x60) == 0) {
        reinterpret_cast<JourneyState_00419bd0*>(journey)->
            OtApplyTrailStepProgress_RealCpp((int)progress_percent);
    } else {
        delay_days = (short)(*(short*)((char*)journey + 0x94) - 1);
        *(short*)((char*)journey + 0x94) = delay_days;
        if (delay_days == 0) {
            if (active_delay_flag != 0) {
                route_stop_flags = (short)(route_stop_flags ^ 0x10);
                *(short*)((char*)journey + 0x5a) = route_stop_flags;
            }
            route_stop_flags = *(short*)((char*)journey + 0x5a);
            if ((route_stop_flags & 0x20) != 0) {
                route_stop_flags = (short)(route_stop_flags ^ 0x20);
                *(short*)((char*)journey + 0x5a) = route_stop_flags;
            }
            route_stop_flags = *(short*)((char*)journey + 0x5a);
            if ((route_stop_flags & 0x40) != 0) {
                route_stop_flags = (short)(route_stop_flags ^ 0x40);
                *(short*)((char*)journey + 0x5a) = route_stop_flags;
            }
        }
    }

    if (OtShouldTriggerGraveSiteEvent_00412220_Product(
            g_graveSiteRuntime) != 0) {
        OtTriggerTrailEventById_RealCpp(0x0c);
    }

    OtAdvanceWeatherState_004199a0_ProductWip(journey);
    OtConsumeDailyFood_00419b50_Product(journey);
    OtAdvancePartyHealthState_00419d40_ProductWip(journey);
    OtRollTrailRandomEvents_00418d50_ProductWip();
}

void JourneyState_00419f60::OtApplyTravelProgressEffectsAlt8_00419f60(
    unsigned int progress_percent)
{
    register JourneyState_00419f60* journey = this;
    short delay_days = 0;
    short route_stop_flags;
    short active_delay_flag;

    journey->calendar_state.OtAdvanceGameDate_RealCpp();
    route_stop_flags = *(short*)((char*)journey + 0x5a);
    active_delay_flag = route_stop_flags;
    active_delay_flag = (short)(active_delay_flag & 0x10);
    if (active_delay_flag == 0 && (route_stop_flags & 0x60) == 0) {
        reinterpret_cast<JourneyState_00419bd0*>(journey)->
            OtApplyTrailStepProgress_RealCpp((int)progress_percent);
    } else {
        delay_days = (short)(*(short*)((char*)journey + 0x94) - 1);
        *(short*)((char*)journey + 0x94) = delay_days;
        if (delay_days == 0) {
            if (active_delay_flag != 0) {
                route_stop_flags = (short)(route_stop_flags ^ 0x10);
                *(short*)((char*)journey + 0x5a) = route_stop_flags;
            }
            route_stop_flags = *(short*)((char*)journey + 0x5a);
            if ((route_stop_flags & 0x20) != 0) {
                route_stop_flags = (short)(route_stop_flags ^ 0x20);
                *(short*)((char*)journey + 0x5a) = route_stop_flags;
            }
            route_stop_flags = *(short*)((char*)journey + 0x5a);
            if ((route_stop_flags & 0x40) != 0) {
                route_stop_flags = (short)(route_stop_flags ^ 0x40);
                *(short*)((char*)journey + 0x5a) = route_stop_flags;
            }
        }
    }

    if (OtShouldTriggerGraveSiteEvent_00412220_Product(
            g_graveSiteRuntime) != 0) {
        OtTriggerTrailEventById_RealCpp(0x0c);
    }

    OtAdvanceWeatherState_004199a0_ProductWip(journey);
    OtConsumeDailyFood_00419b50_Product(journey);
    OtAdvancePartyHealthState_00419d40_ProductWip(journey);
    OtRollTrailRandomEvents_00418d50_ProductWip();
}

#pragma optimize("", on)
