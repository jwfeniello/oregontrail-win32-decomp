// Product semantic WIP for OtFormatGameMessageText @ 0x0041ac80.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

#include "trail_event_text_runtime.h"

extern "C" __declspec(dllimport) int __stdcall LoadStringA(
    void* instance,
    unsigned int string_id,
    char* buffer,
    int buffer_max);
extern "C" __declspec(dllimport) int __stdcall wvsprintfA(
    char* output,
    const char* format,
    char* arguments);
extern "C" __declspec(dllimport) unsigned long __stdcall CharUpperBuffA(
    char* buffer,
    unsigned long length);

extern "C" char* __cdecl strcat(char* destination, const char* source);
extern "C" char* __cdecl strchr(char* text, int ch);
extern "C" unsigned int __cdecl strlen(const char* text);

extern "C" void* g_resourceModule;
extern "C" void* g_journeyState;
extern "C" const char g_emptyString_004395ac[];

#pragma comment(lib, "user32.lib")
#pragma intrinsic(strcat)
#pragma intrinsic(strlen)

#pragma pack(push, 1)
struct TrailDateState_00419280 {
    char reserved_00[0x14];
    short year;
    short month;
    short day;

    void OtAdvanceGameDate_RealCpp();
};
#pragma pack(pop)

typedef char OtTrailEventDateTextSizeMustBe0x1a[
    (sizeof(TrailDateState_00419280) == 0x1a) ? 1 : -1];

#pragma code_seg(".otsem")
extern "C" __declspec(allocate(".otsem"))
const char g_dateYearSeparator_0041ac80[] = ", ";
extern "C" __declspec(allocate(".otsem"))
const char g_deathDatePrefix_0041ac80[] = "On ";

#pragma optimize("s", off)
#pragma optimize("t", on)

// Expands the game's @-placeholders into both narrative-voice buffers.  This
// remains a byte-shaping WIP, but it is the genuine formatter used by product
// callers rather than a matcher-only forwarding scaffold.
char* TrailEventTextRuntime_0041aac0_20260603::
    OtFormatGameMessageText_0001ac80_ProductWip(int string_id)
{
    short pass;
    const char* format_arguments[6];
    char date_text[0x1a];
    char format_text[0x100];

    *reinterpret_cast<TrailDateState_00419280*>(date_text) =
        *reinterpret_cast<TrailDateState_00419280*>(
            static_cast<char*>(g_journeyState) + 0x124);

    pass = 0;
    do {
        char* template_cursor;
        short argument_count;

        OtPrepareMessagePronounSet_0001aac0_Wip(pass);
        template_cursor = format_text;

        if (death_prefix_pending == 1 && pass != 0) {
            reinterpret_cast<TrailDateState_00419280*>(date_text)
                ->OtAdvanceGameDate_RealCpp();
            template_cursor += LoadStringA(
                g_resourceModule,
                0x340,
                template_cursor,
                0x100);
            strcat(template_cursor, g_deathDatePrefix_0041ac80);
            strcat(template_cursor, date_text);
            strcat(template_cursor, g_dateYearSeparator_0041ac80);
            template_cursor += strlen(template_cursor);
            death_prefix_pending = 0;
        }

        LoadStringA(g_resourceModule, string_id, template_cursor, 0x100);
        argument_count = 0;

        while ((template_cursor = strchr(template_cursor, '@')) != 0 &&
               argument_count < 6) {
            char* placeholder_code = template_cursor + 1;
            int placeholder = *placeholder_code;

            switch (placeholder) {
            case '2':
                if (cached_pronoun_mode != 0) {
                    template_cursor[0] = '\0';
                    template_cursor = placeholder_code;
                    goto skip_argument;
                }
                format_arguments[argument_count++] = g_emptyString_004395ac;
                break;

            case 'A':
                format_arguments[argument_count++] = possessive_noun_text;
                break;

            case 'D':
                format_arguments[argument_count++] = unknown_text;
                break;

            case 'H':
                format_arguments[argument_count++] = reflexive_text;
                break;

            case 'I':
                format_arguments[argument_count++] = capitalized_subject_text;
                break;

            case 'L':
                format_arguments[argument_count++] = verb_text;
                break;

            case 'M':
                format_arguments[argument_count++] = capitalized_verb_text;
                break;

            case 'N':
                format_arguments[argument_count++] = name_pointer;
                break;

            case 'O':
                format_arguments[argument_count++] = object_text;
                break;

            case 'S':
                format_arguments[argument_count++] = event_argument_pointer;
                break;

            case 'U':
                format_arguments[argument_count++] = possessive_text;
                break;

            case 'W':
                format_arguments[argument_count++] = subject_text;
                break;

            case 'n':
                format_arguments[argument_count++] = active_name_pointer;
                break;

            default:
                goto skip_argument;
            }

skip_argument:
            template_cursor[0] = '%';
            ++template_cursor;
            template_cursor[0] = 's';
            ++template_cursor;
        }

        wvsprintfA(
            pass == 0 ? primary_text : secondary_text,
            format_text,
            reinterpret_cast<char*>(format_arguments));
        CharUpperBuffA(pass == 0 ? primary_text : secondary_text, 1);
        ++pass;
    } while (pass <= 1);

    return primary_text;
}

#pragma optimize("", on)
#pragma code_seg()
