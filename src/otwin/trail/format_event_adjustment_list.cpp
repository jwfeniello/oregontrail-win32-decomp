// Semantic recovery candidate for OtFormatEventAdjustmentList @ 0x0041a320.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

extern "C" void* g_resourceModule;
extern "C" void* g_journeyState;
extern "C" void* g_trailEventTextArgument;
extern "C" char g_eventAdjustmentText_0041a320[0x190] = {0};
extern "C" const char g_eventAdjustmentCountFormat_0041a320[] = "%d %s\n";
extern "C" const char g_eventAdjustmentPersonFormat_0041a320[] = "%s %s\n";

extern "C" __declspec(dllimport) int __stdcall LoadStringA(
    void* instance,
    unsigned int string_id,
    char* buffer,
    int buffer_max);
extern "C" __declspec(dllimport) int __cdecl wsprintfA(
    char* buffer,
    const char* format,
    ...);

#pragma pack(push, 1)
struct EventAdjustmentListFormatter_0041a320 {
    short entries[13];

    short OtFormatEventAdjustmentList_0041a320_RealCpp(
        const char* person_event_text);
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

short EventAdjustmentListFormatter_0041a320::
    OtFormatEventAdjustmentList_0041a320_RealCpp(
        const char* person_event_text)
{
    char* write_cursor = g_eventAdjustmentText_0041a320;
    short formatted_count = 0;
    short index = 0;
    char item_name[40];

    g_eventAdjustmentText_0041a320[0] = '\0';
    do {
        int entry_index = static_cast<int>(index);
        short adjustment = entries[entry_index];
        if (adjustment != 0) {
            short plural_suffix = static_cast<short>(adjustment > 1);
            ++formatted_count;
            LoadStringA(
                g_resourceModule,
                static_cast<unsigned int>(
                    plural_suffix + 900 + entry_index * 2),
                item_name,
                0x27);
            write_cursor += static_cast<short>(
                wsprintfA(
                    write_cursor,
                    g_eventAdjustmentCountFormat_0041a320,
                    static_cast<int>(entries[entry_index]),
                    item_name));
        }
        ++index;
    } while (index < 8);

    index = 8;
    do {
        if (entries[index] != 0) {
            ++formatted_count;
            write_cursor += static_cast<short>(
                wsprintfA(
                    write_cursor,
                    g_eventAdjustmentPersonFormat_0041a320,
                    static_cast<char*>(g_journeyState) +
                        static_cast<short>(index - 8) * 15 + 0xc0,
                    person_event_text));
        }
        ++index;
    } while (index < 13);

    if (formatted_count != 0) {
        write_cursor[-1] = '\0';
    }

    g_trailEventTextArgument = g_eventAdjustmentText_0041a320;
    return formatted_count;
}

#pragma optimize("", on)
