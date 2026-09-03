#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

extern "C" void* __cdecl memset(
    void* destination,
    int value,
    unsigned int size);
#pragma intrinsic(memset)

#pragma pack(push, 1)
struct RiverRecordSlot_0042fd20 {
    unsigned int dwords[7];
    unsigned short tail_word;
    unsigned char tail_byte;
};

struct RiverRecordTable_0042fd20 {
    int count;
    RiverRecordSlot_0042fd20 slots[1];

    void OtRemoveRiverRecordAt_0042fd20_RealCpp(int index);
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

void RiverRecordTable_0042fd20::
    OtRemoveRiverRecordAt_0042fd20_RealCpp(int index)
{
    int current_count = count;
    if (index < current_count) {
        --current_count;
        if (index < current_count) {
            do {
                slots[index] = slots[index + 1];
                ++index;
            } while (count - 1 > index);
        }
        memset(
            &slots[count - 1],
            0,
            sizeof(RiverRecordSlot_0042fd20));
        --count;
    }
}

#pragma optimize("", on)
