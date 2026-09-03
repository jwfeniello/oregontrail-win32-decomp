// Semantic candidate for OtRefreshGameDateText (0x00419300).

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

extern "C" void* g_resourceModule;
extern "C" const char g_dateAfterMonthSeparator_00419300[] = " ";
extern "C" const char g_dateBeforeYearSeparator_00419300[] = ", ";
extern "C" __declspec(dllimport) int __stdcall LoadStringA(
    void* module,
    unsigned int resource_id,
    char* buffer,
    int buffer_length);
extern "C" char* __cdecl strcat(char* destination, const char* source);
extern "C" char* __cdecl _itoa(int value, char* buffer, int radix);
#pragma intrinsic(strcat)

#pragma pack(push, 1)
struct GameDateTextState_00419300 {
    char formatted_date[0x14];
    short year;
    short month_string_id;
    short day;

    void OtRefreshGameDateText_00419300_RealCpp();
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

void GameDateTextState_00419300::OtRefreshGameDateText_00419300_RealCpp()
{
    char day_text[4];
    char year_text[8];

    LoadStringA(
        g_resourceModule,
        month_string_id,
        formatted_date,
        0x0f);

    strcat(formatted_date, g_dateAfterMonthSeparator_00419300);
    strcat(formatted_date, _itoa(day, day_text, 10));
    strcat(formatted_date, g_dateBeforeYearSeparator_00419300);
    strcat(formatted_date, _itoa(year, year_text, 10));
}

#pragma optimize("", on)
