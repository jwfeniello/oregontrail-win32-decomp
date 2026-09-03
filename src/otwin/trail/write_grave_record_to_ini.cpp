// Product semantic owner for OtWriteGraveRecordToIni @ 0x004120b0.

#include "grave_site_runtime.h"

extern "C" char* __cdecl strcpy(char* destination, const char* source);
extern "C" char* __cdecl strncpy(
    char* destination,
    const char* source,
    unsigned int count);
#pragma intrinsic(strcpy)

typedef int (__cdecl *OtGraveWsprintfAFn)(
    char* buffer,
    const char* format,
    ...);
typedef int (__stdcall *OtWritePrivateProfileStringAFn)(
    const char* section_name,
    const char* key_name,
    const char* string_value,
    const char* file_name);

extern "C" __declspec(dllimport) int __cdecl wsprintfA(
    char* buffer,
    const char* format,
    ...);
extern "C" __declspec(dllimport) int __stdcall WritePrivateProfileStringA(
    const char* section_name,
    const char* key_name,
    const char* string_value,
    const char* file_name);

#pragma comment(lib, "user32.lib")
#pragma comment(lib, "kernel32.lib")

extern "C" const char* PTR_s_oregon_ini_004390dc;
extern "C" const char g_zoneFormat_00439c28[];
extern "C" const char g_graveIntegerFormat_00439c30[];
extern "C" const char g_graveLastLandmark_00439c14[];
extern "C" const char g_graveNextLandmark_00439c00[];
extern "C" const char g_graveMilesToNext_00439bec[];
extern "C" const char g_graveName_00439be0[];
extern "C" const char g_epitaph_00439bd8[];

#pragma pack(push, 1)
struct GraveWriterRouteView_004120b0 {
    char reserved_000[6];
    short zone;
};

struct GraveWriterJourneyView_004120b0 {
    char reserved_000[0x5e];
    short landmark_history[0x16];
    short miles_to_next;
    short reserved_08c;
    short next_landmark;
    char reserved_090[0x30];
    char party_member_names[5][15];
};
#pragma pack(pop)

extern "C" GraveWriterRouteView_004120b0* g_activeRouteDescriptor;
extern "C" GraveWriterJourneyView_004120b0* g_journeyState;

typedef char OtGraveWriterRouteZoneOffsetMustBe06[
    (unsigned int)&(((GraveWriterRouteView_004120b0*)0)->zone) == 0x06
        ? 1
        : -1];
typedef char OtGraveWriterJourneyMilesOffsetMustBe8A[
    (unsigned int)&(
        ((GraveWriterJourneyView_004120b0*)0)->miles_to_next) == 0x8a
        ? 1
        : -1];
typedef char OtGraveWriterJourneyNextOffsetMustBe8E[
    (unsigned int)&(
        ((GraveWriterJourneyView_004120b0*)0)->next_landmark) == 0x8e
        ? 1
        : -1];
typedef char OtGraveWriterJourneyNameOffsetMustBeC0[
    (unsigned int)&(
        ((GraveWriterJourneyView_004120b0*)0)->party_member_names) == 0xc0
        ? 1
        : -1];

#pragma optimize("s", off)
#pragma optimize("t", on)

void GraveSiteRuntime_00411ee0::
    OtWriteGraveRecordToIni_000120b0_Product(
        const char* epitaph_text)
{
    char value_text[12];
    char section[12];
    short last_landmark_value;
    short landmark_count;
    register char* epitaph_destination;

    cached_zone = g_activeRouteDescriptor->zone;

    last_landmark_value = 0;
    landmark_count = g_journeyState->landmark_history[0];
    if (landmark_count != last_landmark_value) {
        last_landmark_value =
            g_journeyState->landmark_history[landmark_count];
    }
    last_landmark = last_landmark_value;

    next_landmark = g_journeyState->next_landmark;
    miles_to_next = g_journeyState->miles_to_next;

    strcpy(grave_name, g_journeyState->party_member_names[0]);
    epitaph_destination = reinterpret_cast<char*>(this) + 0x17;
    strncpy(epitaph_destination, epitaph_text, 0x2d);

    wsprintfA(
        section,
        g_zoneFormat_00439c28,
        static_cast<int>(cached_zone));
    wsprintfA(
        value_text,
        g_graveIntegerFormat_00439c30,
        static_cast<int>(last_landmark));

    WritePrivateProfileStringA(
        section,
        g_graveLastLandmark_00439c14,
        value_text,
        PTR_s_oregon_ini_004390dc);

    wsprintfA(
        value_text,
        g_graveIntegerFormat_00439c30,
        static_cast<int>(next_landmark));
    WritePrivateProfileStringA(
        section,
        g_graveNextLandmark_00439c00,
        value_text,
        PTR_s_oregon_ini_004390dc);

    wsprintfA(
        value_text,
        g_graveIntegerFormat_00439c30,
        static_cast<int>(miles_to_next));
    WritePrivateProfileStringA(
        section,
        g_graveMilesToNext_00439bec,
        value_text,
        PTR_s_oregon_ini_004390dc);

    WritePrivateProfileStringA(
        section,
        g_graveName_00439be0,
        grave_name,
        PTR_s_oregon_ini_004390dc);
    WritePrivateProfileStringA(
        section,
        g_epitaph_00439bd8,
        epitaph_destination,
        PTR_s_oregon_ini_004390dc);
}

#pragma optimize("", on)
