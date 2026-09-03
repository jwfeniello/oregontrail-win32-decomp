// Isolated semantic recovery candidate for OtRunBrokenWagonWheelEvent @ 0x004173d0.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "trail_runtime.h"
#include "trail_event_text_runtime.h"

extern "C" void* g_applicationModule_00405a40_20260603;
extern "C" char g_trailEventTempText[0x1d];

extern "C" short __cdecl OtResolveBrokenSupplyEvent_00017190_ProductWip(
    void* event,
    short supply_count,
    unsigned short shortage_flag);

#pragma pack(push, 1)
struct JourneyState_004173d0 {
    char reserved_000[0x5a];
    short route_stop_flags;
    char reserved_05c[0x42];
    short wagon_wheels;
};

struct TrailEventRunner_004173d0 {
    void OtRunBrokenWagonWheelEvent_004173d0_RealCpp();
    void OtRunBrokenWagonWheelEventAlt1_004173d0_RealCpp();
    void OtRunBrokenWagonWheelEventAlt2_004173d0_RealCpp();
    void OtRunBrokenWagonWheelEventAlt3_004173d0_RealCpp();
    void OtRunBrokenWagonWheelEventAlt4_004173d0_RealCpp();
    void OtRunBrokenWagonWheelEventAlt5_004173d0_RealCpp();
    void OtRunBrokenWagonWheelEventAlt6_004173d0_RealCpp();
    void OtRunBrokenWagonWheelEventAlt7_004173d0_RealCpp();
    void OtRunBrokenWagonWheelEventAlt8_004173d0_RealCpp();
    void OtRunBrokenWagonWheelEventAlt9_004173d0_RealCpp();
    void OtRunBrokenWagonWheelEventAlt10_004173d0_RealCpp();
    void OtRunBrokenWagonWheelEventAlt11_004173d0_RealCpp();
    void OtRunBrokenWagonWheelEventAlt12_004173d0_RealCpp();
    void OtRunBrokenWagonWheelEventAlt13_004173d0_RealCpp();
    void OtRunBrokenWagonWheelEventAlt14_004173d0_RealCpp();
    void OtRunBrokenWagonWheelEventAlt15_004173d0_RealCpp();
    void OtRunBrokenWagonWheelEventAlt16_004173d0_RealCpp();
    void OtRunBrokenWagonWheelEventAlt17_004173d0_RealCpp();
    void OtRunBrokenWagonWheelEventAlt18_004173d0_RealCpp();
    void OtRunBrokenWagonWheelEventAlt19_004173d0_RealCpp();
    void OtRunBrokenWagonWheelEventAlt20_004173d0_RealCpp();
    void OtRunBrokenWagonWheelEventAlt21_004173d0_RealCpp();
    void OtRunBrokenWagonWheelEventAlt22_004173d0_RealCpp();
    void OtRunBrokenWagonWheelEventAlt23_004173d0_RealCpp();
    void OtRunBrokenWagonWheelEventAlt24_004173d0_RealCpp();
    void OtRunBrokenWagonWheelEventAlt25_004173d0_RealCpp();
    void OtRunBrokenWagonWheelEventAlt26_004173d0_RealCpp();
    void OtRunBrokenWagonWheelEventAlt27_004173d0_RealCpp();
    void OtRunBrokenWagonWheelEventAlt28_004173d0_RealCpp();
};
#pragma pack(pop)

extern "C" JourneyState_004173d0* g_journeyState;

#pragma optimize("s", off)
#pragma optimize("t", on)

void TrailEventRunner_004173d0::OtRunBrokenWagonWheelEvent_004173d0_RealCpp()
{
    register TrailEventRunner_004173d0* event = this;

    LoadStringA(g_applicationModule_00405a40_20260603, 0x38a, g_trailEventTempText, 0x1d);
    JourneyState_004173d0* source = g_journeyState;
    g_trailEventRuntimeState.event_argument_pointer = g_trailEventTempText;
    short wheels = OtResolveBrokenSupplyEvent_00017190_ProductWip(
        event,
        source->wagon_wheels,
        2);

    register JourneyState_004173d0* journey = g_journeyState;
    register short* flags = &journey->route_stop_flags;
    short route_stop_flags = *flags;
    short spare_flag = static_cast<short>(route_stop_flags & 2);

    if (spare_flag != 0 && wheels > 0) {
        if (spare_flag != 0) {
            *flags = static_cast<short>(route_stop_flags ^ 2);
        }
        --wheels;
    }

    journey->wagon_wheels = wheels;
}

void TrailEventRunner_004173d0::OtRunBrokenWagonWheelEventAlt1_004173d0_RealCpp()
{
    LoadStringA(g_applicationModule_00405a40_20260603, 0x38a, g_trailEventTempText, 0x1d);
    g_trailEventRuntimeState.event_argument_pointer = g_trailEventTempText;

    short wheels = OtResolveBrokenSupplyEvent_00017190_ProductWip(
        this,
        g_journeyState->wagon_wheels,
        2);

    register JourneyState_004173d0* journey = g_journeyState;
    register short* flags = &journey->route_stop_flags;
    unsigned short route_stop_flags = *flags;
    unsigned short spare_flag = static_cast<unsigned short>(route_stop_flags & 2);

    if (spare_flag != 0 && wheels > 0) {
        if (spare_flag != 0) {
            *flags = static_cast<short>(route_stop_flags ^ 2);
        }
        --wheels;
    }

    journey->wagon_wheels = wheels;
}

void TrailEventRunner_004173d0::OtRunBrokenWagonWheelEventAlt2_004173d0_RealCpp()
{
    register TrailEventRunner_004173d0* event = this;

    LoadStringA(g_applicationModule_00405a40_20260603, 0x38a, g_trailEventTempText, 0x1d);
    g_trailEventRuntimeState.event_argument_pointer = g_trailEventTempText;

    short wheels = OtResolveBrokenSupplyEvent_00017190_ProductWip(
        event,
        g_journeyState->wagon_wheels,
        2);

    JourneyState_004173d0* journey = g_journeyState;
    short* flags = &journey->route_stop_flags;
    unsigned short route_stop_flags = *flags;
    unsigned short spare_flag = static_cast<unsigned short>(route_stop_flags & 2);

    if (spare_flag != 0 && wheels > 0) {
        if (spare_flag != 0) {
            *flags = static_cast<short>(route_stop_flags ^ 2);
        }
        --wheels;
    }

    journey->wagon_wheels = wheels;
}

void TrailEventRunner_004173d0::OtRunBrokenWagonWheelEventAlt3_004173d0_RealCpp()
{
    register TrailEventRunner_004173d0* event = this;

    LoadStringA(g_applicationModule_00405a40_20260603, 0x38a, g_trailEventTempText, 0x1d);
    JourneyState_004173d0* source = g_journeyState;
    g_trailEventRuntimeState.event_argument_pointer = g_trailEventTempText;

    short wheels = OtResolveBrokenSupplyEvent_00017190_ProductWip(
        event,
        source->wagon_wheels,
        2);

    register JourneyState_004173d0* journey = g_journeyState;
    short route_stop_flags = journey->route_stop_flags;
    short spare_flag = static_cast<short>(route_stop_flags & 2);

    if (spare_flag != 0 && wheels > 0) {
        journey->route_stop_flags = static_cast<short>(route_stop_flags ^ 2);
        --wheels;
    }

    journey->wagon_wheels = wheels;
}

void TrailEventRunner_004173d0::OtRunBrokenWagonWheelEventAlt4_004173d0_RealCpp()
{
    register TrailEventRunner_004173d0* event = this;

    LoadStringA(g_applicationModule_00405a40_20260603, 0x38a, g_trailEventTempText, 0x1d);
    JourneyState_004173d0* source = g_journeyState;
    g_trailEventRuntimeState.event_argument_pointer = g_trailEventTempText;

    short wheels = OtResolveBrokenSupplyEvent_00017190_ProductWip(
        event,
        source->wagon_wheels,
        2);

    JourneyState_004173d0* journey = g_journeyState;
    register short* flags = &journey->route_stop_flags;
    short route_stop_flags = *flags;
    short spare_flag = static_cast<short>(route_stop_flags & 2);

    if (spare_flag != 0 && wheels > 0) {
        if (spare_flag != 0) {
            *flags = static_cast<short>(route_stop_flags ^ 2);
        }
        --wheels;
    }

    journey->wagon_wheels = wheels;
}

void TrailEventRunner_004173d0::OtRunBrokenWagonWheelEventAlt5_004173d0_RealCpp()
{
    register TrailEventRunner_004173d0* event = this;

    LoadStringA(g_applicationModule_00405a40_20260603, 0x38a, g_trailEventTempText, 0x1d);
    JourneyState_004173d0* source = g_journeyState;
    g_trailEventRuntimeState.event_argument_pointer = g_trailEventTempText;

    short wheels = OtResolveBrokenSupplyEvent_00017190_ProductWip(
        event,
        source->wagon_wheels,
        2);

    JourneyState_004173d0* journey = g_journeyState;
    short* flags = &journey->route_stop_flags;
    unsigned short route_stop_flags = *flags;
    unsigned short spare_flag = static_cast<unsigned short>(route_stop_flags & 2);

    if (spare_flag != 0) {
        if (wheels > 0) {
            if (spare_flag != 0) {
                *flags = static_cast<short>(route_stop_flags ^ 2);
            }
            --wheels;
        }
    }

    journey->wagon_wheels = wheels;
}

void TrailEventRunner_004173d0::OtRunBrokenWagonWheelEventAlt6_004173d0_RealCpp()
{
    register TrailEventRunner_004173d0* event = this;

    LoadStringA(g_applicationModule_00405a40_20260603, 0x38a, g_trailEventTempText, 0x1d);
    register JourneyState_004173d0* source = g_journeyState;
    g_trailEventRuntimeState.event_argument_pointer = g_trailEventTempText;

    short wheels = OtResolveBrokenSupplyEvent_00017190_ProductWip(
        event,
        source->wagon_wheels,
        2);

    JourneyState_004173d0* journey = g_journeyState;
    short* flags = &journey->route_stop_flags;
    short route_stop_flags = *flags;
    short spare_flag = static_cast<short>(route_stop_flags & 2);

    if (spare_flag != 0 && wheels > 0) {
        if (spare_flag != 0) {
            *flags = static_cast<short>(route_stop_flags ^ 2);
        }
        --wheels;
    }

    journey->wagon_wheels = wheels;
}

#pragma optimize("a", on)
void TrailEventRunner_004173d0::OtRunBrokenWagonWheelEventAlt7_004173d0_RealCpp()
{
    register TrailEventRunner_004173d0* event = this;

    LoadStringA(g_applicationModule_00405a40_20260603, 0x38a, g_trailEventTempText, 0x1d);
    JourneyState_004173d0* source = g_journeyState;
    g_trailEventRuntimeState.event_argument_pointer = g_trailEventTempText;

    short wheels = OtResolveBrokenSupplyEvent_00017190_ProductWip(
        event,
        source->wagon_wheels,
        2);

    register JourneyState_004173d0* journey = g_journeyState;
    register short* flags = &journey->route_stop_flags;
    short route_stop_flags = *flags;
    short spare_flag = static_cast<short>(route_stop_flags & 2);

    if (spare_flag != 0 && wheels > 0) {
        if (spare_flag != 0) {
            *flags = static_cast<short>(route_stop_flags ^ 2);
        }
        --wheels;
    }

    journey->wagon_wheels = wheels;
}
#pragma optimize("a", off)

void TrailEventRunner_004173d0::OtRunBrokenWagonWheelEventAlt8_004173d0_RealCpp()
{
    register TrailEventRunner_004173d0* event = this;

    LoadStringA(g_applicationModule_00405a40_20260603, 0x38a, g_trailEventTempText, 0x1d);
    JourneyState_004173d0* source = g_journeyState;
    g_trailEventRuntimeState.event_argument_pointer = g_trailEventTempText;

    short wheels = OtResolveBrokenSupplyEvent_00017190_ProductWip(
        event,
        source->wagon_wheels,
        2);

    register JourneyState_004173d0* journey = g_journeyState;
    short* flags = &journey->route_stop_flags;
    short route_stop_flags = *flags;
    short spare_flag = static_cast<short>(route_stop_flags & 2);

    if (spare_flag != 0 && wheels > 0) {
        if (spare_flag != 0) {
            *flags = static_cast<short>(route_stop_flags ^ 2);
        }
        --wheels;
    }

    journey->wagon_wheels = wheels;
}

void TrailEventRunner_004173d0::OtRunBrokenWagonWheelEventAlt9_004173d0_RealCpp()
{
    register TrailEventRunner_004173d0* event = this;

    LoadStringA(g_applicationModule_00405a40_20260603, 0x38a, g_trailEventTempText, 0x1d);
    JourneyState_004173d0* source = g_journeyState;
    g_trailEventRuntimeState.event_argument_pointer = g_trailEventTempText;

    short wheels = OtResolveBrokenSupplyEvent_00017190_ProductWip(
        event,
        source->wagon_wheels,
        2);

    register JourneyState_004173d0* journey = g_journeyState;
    short route_stop_flags = journey->route_stop_flags;
    short spare_flag = static_cast<short>(route_stop_flags & 2);

    if (spare_flag != 0 && wheels > 0) {
        if (spare_flag != 0) {
            journey->route_stop_flags =
                static_cast<short>(route_stop_flags ^ 2);
        }
        --wheels;
    }

    journey->wagon_wheels = wheels;
}

void TrailEventRunner_004173d0::OtRunBrokenWagonWheelEventAlt10_004173d0_RealCpp()
{
    register TrailEventRunner_004173d0* event = this;

    LoadStringA(g_applicationModule_00405a40_20260603, 0x38a, g_trailEventTempText, 0x1d);
    register JourneyState_004173d0* source = g_journeyState;
    g_trailEventRuntimeState.event_argument_pointer = g_trailEventTempText;

    short wheels = OtResolveBrokenSupplyEvent_00017190_ProductWip(
        event,
        source->wagon_wheels,
        2);

    register JourneyState_004173d0* journey = g_journeyState;
    short* flags = &journey->route_stop_flags;
    register short route_stop_flags = *flags;
    short spare_flag = static_cast<short>(route_stop_flags & 2);

    if (spare_flag != 0 && wheels > 0) {
        if (spare_flag != 0) {
            *flags = static_cast<short>(route_stop_flags ^ 2);
        }
        --wheels;
    }

    journey->wagon_wheels = wheels;
}

void TrailEventRunner_004173d0::OtRunBrokenWagonWheelEventAlt11_004173d0_RealCpp()
{
    register TrailEventRunner_004173d0* event = this;

    LoadStringA(g_applicationModule_00405a40_20260603, 0x38a, g_trailEventTempText, 0x1d);
    JourneyState_004173d0* source = g_journeyState;
    g_trailEventRuntimeState.event_argument_pointer = g_trailEventTempText;

    short wheels = OtResolveBrokenSupplyEvent_00017190_ProductWip(
        event,
        source->wagon_wheels,
        2);

    JourneyState_004173d0* journey = g_journeyState;
    register short* flags = &journey->route_stop_flags;
    register short route_stop_flags = *flags;
    short spare_flag = static_cast<short>(route_stop_flags & 2);

    if (spare_flag != 0 && wheels > 0) {
        if (spare_flag != 0) {
            *flags = static_cast<short>(route_stop_flags ^ 2);
        }
        --wheels;
    }

    journey->wagon_wheels = wheels;
}

#pragma optimize("a", on)
void TrailEventRunner_004173d0::OtRunBrokenWagonWheelEventAlt12_004173d0_RealCpp()
{
    register TrailEventRunner_004173d0* event = this;
    JourneyState_004173d0* source;

    LoadStringA(g_applicationModule_00405a40_20260603, 0x38a, g_trailEventTempText, 0x1d);

    short wheels = OtResolveBrokenSupplyEvent_00017190_ProductWip(
        event,
        ((source = g_journeyState),
         (g_trailEventRuntimeState.event_argument_pointer = g_trailEventTempText),
         source->wagon_wheels),
        2);

    register JourneyState_004173d0* journey = g_journeyState;
    register short* flags = &journey->route_stop_flags;
    short route_stop_flags = *flags;
    short spare_flag = static_cast<short>(route_stop_flags & 2);

    if (spare_flag != 0 && wheels > 0) {
        if (spare_flag != 0) {
            *flags = static_cast<short>(route_stop_flags ^ 2);
        }
        --wheels;
    }

    journey->wagon_wheels = wheels;
}
#pragma optimize("a", off)

#pragma optimize("a", on)
void TrailEventRunner_004173d0::OtRunBrokenWagonWheelEventAlt13_004173d0_RealCpp()
{
    short wheels;
    {
        register TrailEventRunner_004173d0* event = this;
        JourneyState_004173d0* source;

        LoadStringA(
            g_applicationModule_00405a40_20260603,
            0x38a,
            g_trailEventTempText,
            0x1d);

        wheels = OtResolveBrokenSupplyEvent_00017190_ProductWip(
            event,
            ((source = g_journeyState),
             (g_trailEventRuntimeState.event_argument_pointer = g_trailEventTempText),
             static_cast<int>(source->wagon_wheels)),
            2);
    }

    register JourneyState_004173d0* journey = g_journeyState;
    register short* flags = &journey->route_stop_flags;
    short route_stop_flags = *flags;
    short spare_flag = static_cast<short>(route_stop_flags & 2);

    if (spare_flag != 0 && wheels > 0) {
        if (spare_flag != 0) {
            *flags = static_cast<short>(route_stop_flags ^ 2);
        }
        --wheels;
    }

    journey->wagon_wheels = wheels;
}
#pragma optimize("a", off)

#pragma optimize("a", on)
void TrailEventRunner_004173d0::OtRunBrokenWagonWheelEventAlt14_004173d0_RealCpp()
{
    register TrailEventRunner_004173d0* event = this;

    LoadStringA(g_applicationModule_00405a40_20260603, 0x38a, g_trailEventTempText, 0x1d);
    JourneyState_004173d0* source = g_journeyState;
    g_trailEventRuntimeState.event_argument_pointer = g_trailEventTempText;

    short wheels = OtResolveBrokenSupplyEvent_00017190_ProductWip(
        event,
        source->wagon_wheels,
        2);

    register JourneyState_004173d0* journey = g_journeyState;
    register short* flags = &journey->route_stop_flags;
    short route_stop_flags = *flags;
    short spare_flag = static_cast<short>(route_stop_flags & 2);

    if (spare_flag != 0 && wheels > 0) {
        if (spare_flag != 0) {
            *flags = static_cast<short>(route_stop_flags ^ 2);
        }
        --wheels;
    }

    journey->wagon_wheels = wheels;
}
#pragma optimize("a", off)

#pragma optimize("a", on)
void TrailEventRunner_004173d0::OtRunBrokenWagonWheelEventAlt15_004173d0_RealCpp()
{
    register TrailEventRunner_004173d0* event = this;
    JourneyState_004173d0* source;

    LoadStringA(g_applicationModule_00405a40_20260603, 0x38a, g_trailEventTempText, 0x1d);

    register short wheels =
        ((source = g_journeyState),
         (g_trailEventRuntimeState.event_argument_pointer = g_trailEventTempText),
         source->wagon_wheels);

    wheels = OtResolveBrokenSupplyEvent_00017190_ProductWip(event, wheels, 2);

    register JourneyState_004173d0* journey = g_journeyState;
    register short* flags = &journey->route_stop_flags;
    short route_stop_flags = *flags;
    short spare_flag = static_cast<short>(route_stop_flags & 2);

    if (spare_flag != 0 && wheels > 0) {
        if (spare_flag != 0) {
            *flags = static_cast<short>(route_stop_flags ^ 2);
        }
        --wheels;
    }

    journey->wagon_wheels = wheels;
}
#pragma optimize("a", off)

#pragma optimize("a", on)
void TrailEventRunner_004173d0::OtRunBrokenWagonWheelEventAlt16_004173d0_RealCpp()
{
    register TrailEventRunner_004173d0* event = this;
    JourneyState_004173d0* source;

    LoadStringA(g_applicationModule_00405a40_20260603, 0x38a, g_trailEventTempText, 0x1d);

    register short wheels =
        ((source = g_journeyState),
         (g_trailEventRuntimeState.event_argument_pointer = g_trailEventTempText),
         source->wagon_wheels);

    wheels = OtResolveBrokenSupplyEvent_00017190_ProductWip(event, wheels, 2);

    register JourneyState_004173d0* journey = g_journeyState;
    short* flags = &journey->route_stop_flags;
    short route_stop_flags = *flags;
    register short spare_flag = static_cast<short>(route_stop_flags & 2);

    if (spare_flag != 0 && wheels > 0) {
        if (spare_flag != 0) {
            *flags = static_cast<short>(route_stop_flags ^ 2);
        }
        --wheels;
    }

    journey->wagon_wheels = wheels;
}
#pragma optimize("a", off)

#pragma optimize("a", on)
void TrailEventRunner_004173d0::OtRunBrokenWagonWheelEventAlt17_004173d0_RealCpp()
{
    register TrailEventRunner_004173d0* event = this;
    JourneyState_004173d0* source;

    LoadStringA(g_applicationModule_00405a40_20260603, 0x38a, g_trailEventTempText, 0x1d);

    short wheels = OtResolveBrokenSupplyEvent_00017190_ProductWip(
        event,
        ((source = g_journeyState),
         (g_trailEventRuntimeState.event_argument_pointer = g_trailEventTempText),
         source->wagon_wheels),
        2);

    register JourneyState_004173d0* journey = g_journeyState;
    register short* flags = &journey->route_stop_flags;
    short route_stop_flags = *flags;
    register short spare_flag = static_cast<short>(route_stop_flags & 2);

    if (spare_flag != 0 && wheels > 0) {
        if (spare_flag != 0) {
            *flags = static_cast<short>(route_stop_flags ^ 2);
        }
        --wheels;
    }

    journey->wagon_wheels = wheels;
}
#pragma optimize("a", off)

#pragma optimize("a", on)
void TrailEventRunner_004173d0::OtRunBrokenWagonWheelEventAlt18_004173d0_RealCpp()
{
    register TrailEventRunner_004173d0* event = this;
    JourneyState_004173d0* source;

    LoadStringA(g_applicationModule_00405a40_20260603, 0x38a, g_trailEventTempText, 0x1d);

    short wheels = OtResolveBrokenSupplyEvent_00017190_ProductWip(
        event,
        ((source = g_journeyState),
         (g_trailEventRuntimeState.event_argument_pointer = g_trailEventTempText),
         source->wagon_wheels),
        2);

    register JourneyState_004173d0* journey = g_journeyState;
    short* flags = &journey->route_stop_flags;
    short route_stop_flags = *flags;
    short spare_flag = static_cast<short>(route_stop_flags & 2);

    if (spare_flag != 0) {
        if (wheels > 0) {
            if (spare_flag != 0) {
                *flags = static_cast<short>(route_stop_flags ^ 2);
            }
            --wheels;
        }
    }

    journey->wagon_wheels = wheels;
}
#pragma optimize("a", off)

#pragma optimize("a", on)
void TrailEventRunner_004173d0::OtRunBrokenWagonWheelEventAlt19_004173d0_RealCpp()
{
    register TrailEventRunner_004173d0* event = this;
    JourneyState_004173d0* source;

    LoadStringA(g_applicationModule_00405a40_20260603, 0x38a, g_trailEventTempText, 0x1d);

    unsigned short supply_count =
        ((source = g_journeyState),
         (g_trailEventRuntimeState.event_argument_pointer = g_trailEventTempText),
         static_cast<unsigned short>(source->wagon_wheels));

    short wheels = OtResolveBrokenSupplyEvent_00017190_ProductWip(
        event,
        static_cast<short>(supply_count),
        2);

    register JourneyState_004173d0* journey = g_journeyState;
    register short* flags = &journey->route_stop_flags;
    short route_stop_flags = *flags;
    short spare_flag = static_cast<short>(route_stop_flags & 2);

    if (spare_flag != 0 && wheels > 0) {
        if (spare_flag != 0) {
            *flags = static_cast<short>(route_stop_flags ^ 2);
        }
        --wheels;
    }

    journey->wagon_wheels = wheels;
}
#pragma optimize("a", off)

#pragma optimize("a", on)
void TrailEventRunner_004173d0::OtRunBrokenWagonWheelEventAlt20_004173d0_RealCpp()
{
    short wheels;
    {
        register TrailEventRunner_004173d0* event = this;
        JourneyState_004173d0* source;
        unsigned short supply_count;

        LoadStringA(
            g_applicationModule_00405a40_20260603,
            0x38a,
            g_trailEventTempText,
            0x1d);

        supply_count =
            ((source = g_journeyState),
             (g_trailEventRuntimeState.event_argument_pointer = g_trailEventTempText),
             static_cast<unsigned short>(source->wagon_wheels));

        wheels = OtResolveBrokenSupplyEvent_00017190_ProductWip(
            event,
            static_cast<short>(supply_count),
            2);
    }

    register JourneyState_004173d0* journey = g_journeyState;
    register short* flags = &journey->route_stop_flags;
    short route_stop_flags = *flags;
    short spare_flag = static_cast<short>(route_stop_flags & 2);

    if (spare_flag != 0 && wheels > 0) {
        if (spare_flag != 0) {
            *flags = static_cast<short>(route_stop_flags ^ 2);
        }
        --wheels;
    }

    journey->wagon_wheels = wheels;
}
#pragma optimize("a", off)

#pragma optimize("a", on)
void TrailEventRunner_004173d0::OtRunBrokenWagonWheelEventAlt21_004173d0_RealCpp()
{
    register TrailEventRunner_004173d0* event = this;
    JourneyState_004173d0* source;

    LoadStringA(g_applicationModule_00405a40_20260603, 0x38a, g_trailEventTempText, 0x1d);

    register unsigned short supply_count =
        ((source = g_journeyState),
         (g_trailEventRuntimeState.event_argument_pointer = g_trailEventTempText),
         static_cast<unsigned short>(source->wagon_wheels));

    short wheels = OtResolveBrokenSupplyEvent_00017190_ProductWip(
        event,
        static_cast<short>(supply_count),
        2);

    register JourneyState_004173d0* journey = g_journeyState;
    register short* flags = &journey->route_stop_flags;
    short route_stop_flags = *flags;
    short spare_flag = static_cast<short>(route_stop_flags & 2);

    if (spare_flag != 0 && wheels > 0) {
        if (spare_flag != 0) {
            *flags = static_cast<short>(route_stop_flags ^ 2);
        }
        --wheels;
    }

    journey->wagon_wheels = wheels;
}

void TrailEventRunner_004173d0::OtRunBrokenWagonWheelEventAlt22_004173d0_RealCpp()
{
    register TrailEventRunner_004173d0* event = this;
    JourneyState_004173d0* source;

    LoadStringA(g_applicationModule_00405a40_20260603, 0x38a, g_trailEventTempText, 0x1d);

    short wheels = OtResolveBrokenSupplyEvent_00017190_ProductWip(
        event,
        ((source = g_journeyState),
         (g_trailEventRuntimeState.event_argument_pointer = g_trailEventTempText),
         source->wagon_wheels),
        2);

    JourneyState_004173d0* journey = g_journeyState;
    register short* flags = &journey->route_stop_flags;
    register short route_stop_flags = *flags;
    short spare_flag = static_cast<short>(route_stop_flags & 2);

    if (spare_flag != 0 && wheels > 0) {
        if (spare_flag != 0) {
            *flags = static_cast<short>(route_stop_flags ^ 2);
        }
        --wheels;
    }

    journey->wagon_wheels = wheels;
}

void TrailEventRunner_004173d0::OtRunBrokenWagonWheelEventAlt23_004173d0_RealCpp()
{
    short wheels;
    {
        register TrailEventRunner_004173d0* event = this;
        JourneyState_004173d0* source;

        LoadStringA(
            g_applicationModule_00405a40_20260603,
            0x38a,
            g_trailEventTempText,
            0x1d);

        wheels = OtResolveBrokenSupplyEvent_00017190_ProductWip(
            event,
            ((source = g_journeyState),
             (g_trailEventRuntimeState.event_argument_pointer = g_trailEventTempText),
             source->wagon_wheels),
            2);
    }

    JourneyState_004173d0* journey = g_journeyState;
    register short* flags = &journey->route_stop_flags;
    register short route_stop_flags = *flags;
    short spare_flag = route_stop_flags;
    spare_flag = static_cast<short>(spare_flag & 2);

    if (spare_flag != 0 && wheels > 0) {
        if (spare_flag != 0) {
            *flags = static_cast<short>(route_stop_flags ^ 2);
        }
        --wheels;
    }

    journey->wagon_wheels = wheels;
}

void TrailEventRunner_004173d0::OtRunBrokenWagonWheelEventAlt24_004173d0_RealCpp()
{
    register TrailEventRunner_004173d0* event = this;
    JourneyState_004173d0* source;

    LoadStringA(g_applicationModule_00405a40_20260603, 0x38a, g_trailEventTempText, 0x1d);

    register short supply_count =
        ((source = g_journeyState),
         (g_trailEventRuntimeState.event_argument_pointer = g_trailEventTempText),
         source->wagon_wheels);

    short wheels = OtResolveBrokenSupplyEvent_00017190_ProductWip(
        event,
        supply_count,
        2);

    JourneyState_004173d0* journey = g_journeyState;
    register short* flags = &journey->route_stop_flags;
    register short route_stop_flags = *flags;
    short spare_flag = route_stop_flags;
    spare_flag = static_cast<short>(spare_flag & 2);

    if (spare_flag != 0 && wheels > 0) {
        if (spare_flag != 0) {
            *flags = static_cast<short>(route_stop_flags ^ 2);
        }
        --wheels;
    }

    journey->wagon_wheels = wheels;
}

void TrailEventRunner_004173d0::OtRunBrokenWagonWheelEventAlt25_004173d0_RealCpp()
{
    register TrailEventRunner_004173d0* event = this;
    JourneyState_004173d0* source;

    LoadStringA(g_applicationModule_00405a40_20260603, 0x38a, g_trailEventTempText, 0x1d);

    short wheels = OtResolveBrokenSupplyEvent_00017190_ProductWip(
        event,
        ((source = g_journeyState),
         (g_trailEventRuntimeState.event_argument_pointer = g_trailEventTempText),
         source->wagon_wheels),
        2);

    register JourneyState_004173d0* journey = g_journeyState;
    short* flags = &journey->route_stop_flags;
    register short route_stop_flags = *flags;
    short spare_flag = route_stop_flags;
    spare_flag = static_cast<short>(spare_flag & 2);

    if (spare_flag != 0 && wheels > 0) {
        if (spare_flag != 0) {
            *flags = static_cast<short>(route_stop_flags ^ 2);
        }
        --wheels;
    }

    journey->wagon_wheels = wheels;
}

void TrailEventRunner_004173d0::OtRunBrokenWagonWheelEventAlt26_004173d0_RealCpp()
{
    register TrailEventRunner_004173d0* event = this;
    JourneyState_004173d0* source;

    LoadStringA(g_applicationModule_00405a40_20260603, 0x38a, g_trailEventTempText, 0x1d);

    short wheels = OtResolveBrokenSupplyEvent_00017190_ProductWip(
        event,
        ((source = g_journeyState),
         (g_trailEventRuntimeState.event_argument_pointer = g_trailEventTempText),
         source->wagon_wheels),
        2);

    JourneyState_004173d0* journey = g_journeyState;
    register short* flags = &journey->route_stop_flags;
    register short route_stop_flags = *flags;
    register short spare_flag = route_stop_flags;
    spare_flag = static_cast<short>(spare_flag & 2);

    if (spare_flag != 0 && wheels > 0) {
        if (spare_flag != 0) {
            *flags = static_cast<short>(route_stop_flags ^ 2);
        }
        --wheels;
    }

    journey->wagon_wheels = wheels;
}

void TrailEventRunner_004173d0::OtRunBrokenWagonWheelEventAlt27_004173d0_RealCpp()
{
    register TrailEventRunner_004173d0* event = this;
    JourneyState_004173d0* source;

    LoadStringA(g_applicationModule_00405a40_20260603, 0x38a, g_trailEventTempText, 0x1d);

    short wheels = OtResolveBrokenSupplyEvent_00017190_ProductWip(
        event,
        ((source = g_journeyState),
         (g_trailEventRuntimeState.event_argument_pointer = g_trailEventTempText),
         source->wagon_wheels),
        2);

    register JourneyState_004173d0* journey = g_journeyState;
    short route_stop_flags = journey->route_stop_flags;
    register short spare_flag = route_stop_flags;
    spare_flag = static_cast<short>(spare_flag & 2);

    if (spare_flag != 0 && wheels > 0) {
        if (spare_flag != 0) {
            journey->route_stop_flags =
                static_cast<short>(route_stop_flags ^ 2);
        }
        --wheels;
    }

    journey->wagon_wheels = wheels;
}

void TrailEventRunner_004173d0::OtRunBrokenWagonWheelEventAlt28_004173d0_RealCpp()
{
    short wheels;
    {
        register TrailEventRunner_004173d0* event = this;
        JourneyState_004173d0* source;
        short supply_count;

        LoadStringA(
            g_applicationModule_00405a40_20260603,
            0x38a,
            g_trailEventTempText,
            0x1d);

        supply_count =
            ((source = g_journeyState),
             (g_trailEventRuntimeState.event_argument_pointer = g_trailEventTempText),
             source->wagon_wheels);

        wheels = OtResolveBrokenSupplyEvent_00017190_ProductWip(
            event,
            supply_count,
            2);
    }

    JourneyState_004173d0* journey = g_journeyState;
    register short* flags = &journey->route_stop_flags;
    short route_stop_flags = *flags;
    register short spare_flag = route_stop_flags;
    spare_flag = static_cast<short>(spare_flag & 2);

    if (spare_flag != 0 && wheels > 0) {
        if (spare_flag != 0) {
            *flags = static_cast<short>(route_stop_flags ^ 2);
        }
        --wheels;
    }

    journey->wagon_wheels = wheels;
}
#pragma optimize("a", off)

#pragma optimize("", on)
