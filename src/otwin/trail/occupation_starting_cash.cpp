// Semantic recovery candidate for OtSetOccupationAndStartingCash @ 0x00419760.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

extern "C" void* g_resourceModule;
extern "C" const char g_undefinedOccupationError_00419760[] =
    "Error - undefined occupation!";

extern "C" __declspec(dllimport) int __stdcall LoadStringA(
    void* instance,
    unsigned int string_id,
    char* buffer,
    int buffer_max);

extern "C" int __cdecl printf(const char* format, ...);

#pragma code_seg(".otsem")
extern "C" int __cdecl OtPrintUndefinedOccupationError_00419760(
    const char* error_text)
{
    return printf(error_text);
}
#pragma code_seg()

#pragma pack(push, 1)
struct JourneyOccupationState_00419760 {
    char reserved_000[0xa8];
    int cash_cents;
    short occupation;
    char occupation_name[15];

    void OtSetOccupationAndStartingCash_00419760_RealCpp(short occupation_id);
    void OtSetOccupationAndStartingCash_00419760_Wip1(short occupation_id);
    void OtSetOccupationAndStartingCash_00419760_Wip2(short occupation_id);
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

void JourneyOccupationState_00419760::
    OtSetOccupationAndStartingCash_00419760_RealCpp(short occupation_id)
{
    register JourneyOccupationState_00419760* journey = this;

    journey->occupation = occupation_id;

    switch (occupation_id) {
    case 0:
        journey->cash_cents = 160000;
        break;
    case 1:
        {
            int starting_cash = 80000;
            journey->cash_cents = starting_cash;
        }
        break;
    case 2:
        journey->cash_cents = 80000;
        break;
    case 3:
        journey->cash_cents = 120000;
        break;
    case 4:
        {
            int starting_cash = 120000;
            journey->cash_cents = starting_cash;
        }
        break;
    case 5:
        {
            int starting_cash = 80000;
            journey->cash_cents = starting_cash;
        }
        break;
    case 6:
    case 7:
        journey->cash_cents = 40000;
        break;
    default:
        OtPrintUndefinedOccupationError_00419760(
            g_undefinedOccupationError_00419760);
        break;
    }

    LoadStringA(
        g_resourceModule,
        occupation_id + 0xa0,
        journey->occupation_name,
        0x0f);
}

void JourneyOccupationState_00419760::
    OtSetOccupationAndStartingCash_00419760_Wip1(short occupation_id)
{
    register JourneyOccupationState_00419760* journey = this;
    register int occupation_index = occupation_id;

    journey->occupation = occupation_id;

    switch (occupation_index) {
    case 0:
        journey->cash_cents = 160000;
        break;
    case 1:
        journey->cash_cents = 80000;
        break;
    case 2:
        journey->cash_cents = 80000;
        break;
    case 3:
        journey->cash_cents = 120000;
        break;
    case 4:
        journey->cash_cents = 120000;
        break;
    case 5:
        journey->cash_cents = 80000;
        break;
    case 6:
    case 7:
        journey->cash_cents = 40000;
        break;
    default:
        OtPrintUndefinedOccupationError_00419760(
            g_undefinedOccupationError_00419760);
        break;
    }

    LoadStringA(
        g_resourceModule,
        occupation_index + 0xa0,
        journey->occupation_name,
        0x0f);
}

void JourneyOccupationState_00419760::
    OtSetOccupationAndStartingCash_00419760_Wip2(short occupation_id)
{
    register int occupation_index = occupation_id;
    register JourneyOccupationState_00419760* journey = this;

    journey->occupation = occupation_id;

    switch (occupation_index) {
    case 0:
        journey->cash_cents = 160000;
        break;
    case 1:
        {
            int starting_cash = 80000;
            journey->cash_cents = starting_cash;
        }
        break;
    case 2:
        journey->cash_cents = 80000;
        break;
    case 3:
        journey->cash_cents = 120000;
        break;
    case 4:
        {
            int starting_cash = 120000;
            journey->cash_cents = starting_cash;
        }
        break;
    case 5:
        {
            int starting_cash = 80000;
            journey->cash_cents = starting_cash;
        }
        break;
    case 6:
    case 7:
        journey->cash_cents = 40000;
        break;
    default:
        OtPrintUndefinedOccupationError_00419760(
            g_undefinedOccupationError_00419760);
        break;
    }

    LoadStringA(
        g_resourceModule,
        occupation_index + 0xa0,
        journey->occupation_name,
        0x0f);
}

#pragma optimize("", on)
