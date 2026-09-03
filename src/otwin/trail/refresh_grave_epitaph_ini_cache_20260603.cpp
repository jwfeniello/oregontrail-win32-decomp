// Product-tree semantic closure for FUN_00411fd0_00011fd0.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

extern "C" __declspec(dllimport) int __cdecl wsprintfA(
    char* buffer,
    const char* format,
    ...);

extern "C" __declspec(dllimport) unsigned int __stdcall GetPrivateProfileIntA(
    const char* section,
    const char* key,
    int default_value,
    const char* file_name);

extern "C" __declspec(dllimport) unsigned long __stdcall GetPrivateProfileStringA(
    const char* section,
    const char* key,
    const char* default_value,
    char* buffer,
    unsigned int buffer_count,
    const char* file_name);

extern "C" const char* PTR_s_oregon_ini_004390dc;
extern "C" const char g_zoneFormat_00439c28[];
extern "C" const char g_graveLastLandmark_00439c14[];
extern "C" const char g_graveNextLandmark_00439c00[];
extern "C" const char g_graveMilesToNext_00439bec[];
extern "C" const char g_graveName_00439be0[];
extern "C" const char g_epitaph_00439bd8[];
extern "C" const char g_emptyString_004395ac[];

#pragma pack(push, 1)
struct RouteDescriptor_00411fd0_20260603 {
    char reserved_000[6];
    short zone;
};

struct GraveEpitaphState_00411fd0_20260603 {
    short cached_zone;
    short last_landmark;
    short next_landmark;
    short miles_to_next;
    char name[15];
    char epitaph[45];
    short reserved_44;
    short reserved_46;
};
#pragma pack(pop)

extern "C" RouteDescriptor_00411fd0_20260603* g_activeRouteDescriptor;

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" void __fastcall OtRefreshGraveEpitaphIniCache_00411fd0_RealCpp(
    GraveEpitaphState_00411fd0_20260603* state)
{
    char section[12];
    short zone = g_activeRouteDescriptor->zone;

    if (state->cached_zone != zone) {
        state->cached_zone = zone;
        wsprintfA(section, g_zoneFormat_00439c28, static_cast<int>(zone));
        state->last_landmark = static_cast<short>(
            GetPrivateProfileIntA(
                section, g_graveLastLandmark_00439c14, -1, PTR_s_oregon_ini_004390dc));
        state->next_landmark = static_cast<short>(
            GetPrivateProfileIntA(
                section, g_graveNextLandmark_00439c00, -1, PTR_s_oregon_ini_004390dc));
        state->miles_to_next = static_cast<short>(
            GetPrivateProfileIntA(
                section, g_graveMilesToNext_00439bec, -1, PTR_s_oregon_ini_004390dc));
        GetPrivateProfileStringA(
            section, g_graveName_00439be0, g_emptyString_004395ac,
            state->name, 0xf, PTR_s_oregon_ini_004390dc);
        GetPrivateProfileStringA(
            section, g_epitaph_00439bd8, g_emptyString_004395ac,
            state->epitaph, 0x2d, PTR_s_oregon_ini_004390dc);
        *reinterpret_cast<unsigned long*>(&state->reserved_44) = 0;
    }
}

#pragma optimize("", on)
