// Canonical product implementation for choosing a living party member.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

extern "C" int __cdecl OtRandomBelow_RealCpp(int upper_bound);

#pragma pack(push, 1)
struct PartyMemberRuntimeState_004195f0 {
    char reserved_000[0x116];
    short member_state[5];
};
#pragma pack(pop)

#pragma code_seg(".otsem")
#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" short __fastcall
OtChooseRandomLivingPartyMemberSlotAlt27NoAsm_004195f0_40pct(
    const void* journey)
{
    const PartyMemberRuntimeState_004195f0* state =
        static_cast<const PartyMemberRuntimeState_004195f0*>(journey);
    short living_slots[5] = {0, 0, 0, 0, 0};
    short slot;
    register short count;
    register int death_state;

    slot = 1;
    count = living_slots[0];
    death_state = 0x0f;

    while (1) {
        if (slot >= 5) {
            break;
        }

        if (state->member_state[slot] != death_state) {
            living_slots[count] = slot;
            ++count;
        }

        ++slot;
    }

    if (count == 0) {
        return 0;
    }

    return living_slots[OtRandomBelow_RealCpp(count)];
}

#pragma optimize("", on)
#pragma code_seg()
