// Daily trail status thresholds and message-band selection at 0x00419660.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This recovered runtime requires 32-bit MSVC."
#endif

extern "C" int __cdecl OtRandomBelow_RealCpp(int upper_bound);
extern "C" __declspec(dllimport) void __stdcall FatalAppExitA(
    unsigned int action,
    const char* message_text);

#pragma comment(lib, "kernel32.lib")

struct GameDateState_00419410 {
    void OtInitializeGameDate_RealCpp(short month_string_id_value);
};

#pragma pack(push, 1)
struct TrailDailyStatusState_00419660_Product {
    char reserved_000[0x50];
    short status_message_id;
    short random_percent;
    short travel_threshold;
    short bonus_threshold;
    char reserved_058[0xcc];
    GameDateState_00419410 primary_date;
    char reserved_125[0x19];
    GameDateState_00419410 secondary_date;

    void OtPrepareDailyStatus_00419660_Product(short month);
};
#pragma pack(pop)

static const char kBadMonthMessage_00419660[] =
    "Error initializing date: bad month";

#pragma code_seg(".otsem")
#pragma optimize("s", off)
#pragma optimize("t", on)

void TrailDailyStatusState_00419660_Product::
    OtPrepareDailyStatus_00419660_Product(short month)
{
    short message_band;

    primary_date.OtInitializeGameDate_RealCpp(month);
    secondary_date.OtInitializeGameDate_RealCpp(0);
    status_message_id = 0;
    bonus_threshold = 0;

    switch (month) {
    case 2:
        message_band = 0x21;
        travel_threshold = 0x1f4;
        bonus_threshold =
            static_cast<short>(OtRandomBelow_RealCpp(0x4b0));
        break;
    case 3:
        travel_threshold = 0x190;
        message_band = 0x2e;
        break;
    case 4:
        travel_threshold = 0x12c;
        message_band = 0x37;
        break;
    case 5:
        travel_threshold = 0xc8;
        message_band = 0x41;
        break;
    case 6:
        travel_threshold = 0x64;
        message_band = 0x46;
        break;
    case 7:
        travel_threshold = 0;
        message_band = 0x44;
        break;
    default:
        // FatalAppExitA terminates the application, so continuing paths have
        // assigned message_band in one of the valid month cases above.
        FatalAppExitA(0, kBadMonthMessage_00419660);
        break;
    }

    random_percent = static_cast<short>(
        (OtRandomBelow_RealCpp(0x28) + message_band) / 0x14);
    travel_threshold = static_cast<short>(
        travel_threshold + OtRandomBelow_RealCpp(0x64));
}

#pragma optimize("", on)
#pragma code_seg()
