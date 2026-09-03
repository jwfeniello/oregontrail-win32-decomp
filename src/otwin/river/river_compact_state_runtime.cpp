#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

extern "C" void* __cdecl memset(
    void* destination,
    int value,
    unsigned int size);
#pragma intrinsic(memset)

#pragma pack(push, 1)
struct RiverCounterBlock_00428180 {
    char reserved_00[0x28];
    short timer_a;
    short timer_b;
};

struct RiverCounterOwner_00428180 {
    char reserved_000[0x98];
    RiverCounterBlock_00428180* counters;

    void OtStepRiverCounterPairA_RealCpp(int flags);
    void OtStepRiverCounterPairB_RealCpp(int flags);
};

struct RiverZeroBlock_0042fd80 {
    char reserved_00[4];
    unsigned long dwords[0x4d];
    unsigned short tail;

    RiverZeroBlock_0042fd80* OtClearRiverZeroBlock_RealCpp();
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

void RiverCounterOwner_00428180::OtStepRiverCounterPairA_RealCpp(int flags)
{
    if ((flags & 1) == 0) {
        counters->timer_a = static_cast<short>(counters->timer_a - 2);
        --counters->timer_b;
    }
}

void RiverCounterOwner_00428180::OtStepRiverCounterPairB_RealCpp(int flags)
{
    if ((flags & 1) == 0) {
        counters->timer_a = static_cast<short>(counters->timer_a - 2);
        --counters->timer_b;
    }
}

RiverZeroBlock_0042fd80*
RiverZeroBlock_0042fd80::OtClearRiverZeroBlock_RealCpp()
{
    memset(dwords, 0, sizeof(dwords) + sizeof(tail));
    return this;
}

#pragma optimize("", on)
