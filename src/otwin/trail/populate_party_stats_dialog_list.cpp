// Semantic recovery candidate for OtPopulatePartyStatsDialogList @ 0x00419830.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

typedef int (__stdcall *LoadStringAFn_00419830)(
    void* instance,
    unsigned int string_id,
    char* buffer,
    int max_chars);

extern "C" int __cdecl OtRandomBelow_RealCpp(int upper_bound);
extern "C" char* __cdecl strncpy(char* dest, const char* src, unsigned int count);

extern "C" __declspec(dllimport) int __stdcall LoadStringA(
    void* instance,
    unsigned int string_id,
    char* buffer,
    int max_chars);

extern "C" void* g_resourceModule;
extern "C" const char g_defaultPartyMemberName_00419830[] = "USERNAME";

#pragma pack(push, 1)
struct PartyStatsDialogList_00419830 {
    char reserved_000[0xc0];
    char party_member_names[5][15];

    void OtPopulatePartyStatsDialogList_00419830_RealCpp();
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

void PartyStatsDialogList_00419830::
    OtPopulatePartyStatsDialogList_00419830_RealCpp()
{
    register short used_index = 0;
    int used_name_ids[21];
    char loaded_name[40];

    register PartyStatsDialogList_00419830* state = this;
    do {
        used_name_ids[used_index] = 0;
        ++used_index;
    } while (used_index < 21);

    LoadStringAFn_00419830 load_string = LoadStringA;
    register short slot = 0;

populate_next_slot:
    if (slot >= 5) {
        goto populated_all_slots;
    }

    {
        register int unused_marker = 0;
        register short random_name_id;
        do {
            random_name_id =
                static_cast<short>(OtRandomBelow_RealCpp(21));
        } while (used_name_ids[random_name_id] != unused_marker);

        register char* name_buffer = loaded_name;
        used_name_ids[random_name_id] = 1;

        load_string(
            g_resourceModule,
            static_cast<unsigned int>(random_name_id + 0x10),
            name_buffer,
            40);

        strncpy(state->party_member_names[slot], name_buffer, 15);
        ++slot;
    }

    goto populate_next_slot;

populated_all_slots:
    strncpy(state->party_member_names[0], g_defaultPartyMemberName_00419830, 15);
}

#pragma optimize("", on)
