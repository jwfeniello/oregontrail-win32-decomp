// Applies trail-event losses to the current journey and party state.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

extern "C" void* g_journeyState;

#pragma pack(push, 1)
struct JourneyLossState_0041a660_ProductWip {
    char reserved_000[0x5a];
    unsigned short route_stop_flags;
    char reserved_05c[0x3a];
    short oxen_count;
    short oxen_sick;
    short clothing;
    short bullets;
    short wheel_count;
    short axle_count;
    short tongue_count;
    short food_whole;
    short food_fraction;
    int cash_cents;
    char reserved_0ac[0x6a];
    short member_state[5];
};

struct LossEventAdjustmentList_0041a660_ProductWip {
    short entries[13];

    void OtApplyLossEventAdjustmentList_0041a660_ProductWip();
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

void LossEventAdjustmentList_0041a660_ProductWip::
    OtApplyLossEventAdjustmentList_0041a660_ProductWip()
{
    unsigned short flag;
    JourneyLossState_0041a660_ProductWip* journey;
    unsigned short* flags_ptr;
    short* count;
    short value;
    unsigned short flags;

    value = static_cast<JourneyLossState_0041a660_ProductWip*>(
        g_journeyState)->oxen_count;
    if (entries[0] > value) {
        entries[0] = value;
    }

    value = static_cast<JourneyLossState_0041a660_ProductWip*>(
        g_journeyState)->clothing;
    if (entries[1] > value) {
        entries[1] = value;
    }

    value = static_cast<JourneyLossState_0041a660_ProductWip*>(
        g_journeyState)->bullets;
    if (entries[2] > value) {
        entries[2] = value;
    }

    value = static_cast<JourneyLossState_0041a660_ProductWip*>(
        g_journeyState)->wheel_count;
    if (entries[3] > value) {
        entries[3] = value;
    }

    value = static_cast<JourneyLossState_0041a660_ProductWip*>(
        g_journeyState)->axle_count;
    if (entries[4] > value) {
        entries[4] = value;
    }

    value = static_cast<JourneyLossState_0041a660_ProductWip*>(
        g_journeyState)->tongue_count;
    if (entries[5] > value) {
        entries[5] = value;
    }

    value = static_cast<short>(
        static_cast<JourneyLossState_0041a660_ProductWip*>(
            g_journeyState)->food_whole +
        static_cast<JourneyLossState_0041a660_ProductWip*>(
            g_journeyState)->food_fraction);
    if (entries[6] > value) {
        entries[6] = value;
    }

    count = &static_cast<JourneyLossState_0041a660_ProductWip*>(
        g_journeyState)->oxen_count;
    journey = static_cast<JourneyLossState_0041a660_ProductWip*>(
        g_journeyState);
    value = *count;
    value = static_cast<short>(value - entries[0]);
    flags_ptr = &journey->route_stop_flags;
    flags = *flags_ptr;
    flag = flags;
    flag = static_cast<unsigned short>(flag & 1);
    if (flag != 0 && value > 0) {
        if (flag != 0) {
            *flags_ptr = static_cast<unsigned short>(flags ^ 1);
        }
        if (journey->oxen_sick != 0) {
            journey->oxen_sick = 0;
            --value;
        }
    }
    *count = value;

    static_cast<JourneyLossState_0041a660_ProductWip*>(
        g_journeyState)->clothing = static_cast<short>(
            static_cast<JourneyLossState_0041a660_ProductWip*>(
                g_journeyState)->clothing - entries[1]);
    static_cast<JourneyLossState_0041a660_ProductWip*>(
        g_journeyState)->bullets = static_cast<short>(
            static_cast<JourneyLossState_0041a660_ProductWip*>(
                g_journeyState)->bullets - entries[2]);

    count = &static_cast<JourneyLossState_0041a660_ProductWip*>(
        g_journeyState)->wheel_count;
    value = *count;
    value = static_cast<short>(value - entries[3]);
    flags_ptr = &static_cast<JourneyLossState_0041a660_ProductWip*>(
        g_journeyState)->route_stop_flags;
    flags = *flags_ptr;
    flag = static_cast<unsigned short>(flags & 2);
    if (flag != 0 && value > 0) {
        if (flag != 0) {
            *flags_ptr = static_cast<unsigned short>(flags ^ 2);
        }
        --value;
    }
    *count = value;

    count = &static_cast<JourneyLossState_0041a660_ProductWip*>(
        g_journeyState)->axle_count;
    value = *count;
    value = static_cast<short>(value - entries[4]);
    flags_ptr = &static_cast<JourneyLossState_0041a660_ProductWip*>(
        g_journeyState)->route_stop_flags;
    flags = *flags_ptr;
    flag = static_cast<unsigned short>(flags & 4);
    if (flag != 0 && value > 0) {
        if (flag != 0) {
            *flags_ptr = static_cast<unsigned short>(flags ^ 4);
        }
        --value;
    }
    *count = value;

    count = &static_cast<JourneyLossState_0041a660_ProductWip*>(
        g_journeyState)->tongue_count;
    value = *count;
    value = static_cast<short>(value - entries[5]);
    flags_ptr = &static_cast<JourneyLossState_0041a660_ProductWip*>(
        g_journeyState)->route_stop_flags;
    flags = *flags_ptr;
    flag = static_cast<unsigned short>(flags & 8);
    if (flag != 0 && value > 0) {
        if (flag != 0) {
            *flags_ptr = static_cast<unsigned short>(flags ^ 8);
        }
        --value;
    }
    *count = value;

    value = entries[6];
    count = &static_cast<JourneyLossState_0041a660_ProductWip*>(
        g_journeyState)->food_fraction;
    if (*count >= value) {
        value = static_cast<short>(*count - value);
        if (value + static_cast<JourneyLossState_0041a660_ProductWip*>(
                        g_journeyState)->food_whole > 2000) {
            *count = static_cast<short>(
                2000 - static_cast<JourneyLossState_0041a660_ProductWip*>(
                    g_journeyState)->food_whole);
        } else {
            *count = value;
        }
    } else {
        value = static_cast<short>(value - *count);
        entries[6] = value;
        {
            JourneyLossState_0041a660_ProductWip* food_journey;

            food_journey =
                static_cast<JourneyLossState_0041a660_ProductWip*>(
                    g_journeyState);
            if (food_journey->food_whole > 2000) {
                food_journey->food_fraction = static_cast<short>(
                    2000 - food_journey->food_whole);
            } else {
                food_journey->food_fraction = 0;
            }
        }
        static_cast<JourneyLossState_0041a660_ProductWip*>(
            g_journeyState)->food_whole = static_cast<short>(
                static_cast<JourneyLossState_0041a660_ProductWip*>(
                    g_journeyState)->food_whole - entries[6]);
    }

    static_cast<JourneyLossState_0041a660_ProductWip*>(
        g_journeyState)->cash_cents -= entries[7] * 100;

    {
        int member_state_dead = 0x0f;

        for (short member_index = 8; member_index < 13;
             ++member_index) {
            if (entries[member_index] != 0) {
                short member_slot =
                    static_cast<short>(member_index - 8);
                if (static_cast<JourneyLossState_0041a660_ProductWip*>(
                        g_journeyState)->member_state[member_slot] ==
                        member_state_dead) {
                    entries[member_index] = 0;
                }
            }
        }
    }

    {
        short member_slot;
        short member_index;
        int member_state_dead;

        member_state_dead = 0x0f;
        member_index = 8;
        while (member_index < 13) {
            if (entries[member_index] != 0) {
                member_slot = static_cast<short>(member_index - 8);
                static_cast<JourneyLossState_0041a660_ProductWip*>(
                    g_journeyState)->member_state[member_slot] =
                    static_cast<short>(member_state_dead);
            }
            ++member_index;
        }
    }
}

#pragma optimize("", on)
