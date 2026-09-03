// Semantic candidate for OtAreGraveSitesEnabled (0x00411ef0).

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

extern "C" const char g_graveSitesSection_00411ef0[] = "Game Configuration";
extern "C" const char g_graveSitesKey_00411ef0[] = "GraveSites";
extern "C" const char g_graveSitesDefault_00411ef0[] = "Yes";
extern "C" const char g_graveSitesDisabledValue_00411ef0[] = "No";
extern "C" const char* PTR_s_oregon_ini_004390dc;
extern "C" const char g_graveSitesFallback_00411ef0[] = "";

extern "C" __declspec(dllimport) unsigned long __stdcall GetPrivateProfileStringA(
    const char* section_name,
    const char* key_name,
    const char* default_value,
    char* returned_string,
    unsigned long returned_string_size,
    const char* file_name);
extern "C" __declspec(dllimport) int __stdcall WritePrivateProfileStringA(
    const char* section_name,
    const char* key_name,
    const char* string_value,
    const char* file_name);
extern "C" __declspec(dllimport) int __stdcall lstrcmpiA(
    const char* left,
    const char* right);

#pragma comment(lib, "kernel32.lib")

extern "C" char* __cdecl strcpy(char* destination, const char* source);
#pragma intrinsic(strcpy)

#pragma pack(push, 1)
struct GraveSitesLocalConfigSection_00411ef0 {
    unsigned long word0;
    unsigned long word1;
    unsigned long word2;
    unsigned long word3;
    unsigned short tail0;
    unsigned char tail1;
};

struct GraveSitesLocalKey_00411ef0 {
    unsigned long word0;
    unsigned long word1;
    unsigned short tail0;
    unsigned char tail1;
};

struct GraveSitesOptionFrame_00411ef0 {
    char value[8];
    GraveSitesLocalKey_00411ef0 key;
    unsigned char pad;
    GraveSitesLocalConfigSection_00411ef0 section;
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" int __cdecl OtAreGraveSitesEnabled_00411ef0_RealCpp()
{
    GraveSitesOptionFrame_00411ef0 frame;

    frame.section =
        *reinterpret_cast<const GraveSitesLocalConfigSection_00411ef0*>(
            g_graveSitesSection_00411ef0);
    frame.key =
        *reinterpret_cast<const GraveSitesLocalKey_00411ef0*>(
            g_graveSitesKey_00411ef0);

    char* value = frame.value;
    const char* key_name = reinterpret_cast<const char*>(&frame.key);
    const char* section_name = reinterpret_cast<const char*>(&frame.section);
    const char* ini_path = PTR_s_oregon_ini_004390dc;

    if (GetPrivateProfileStringA(
            section_name,
            key_name,
            g_graveSitesFallback_00411ef0,
            value,
            6,
            ini_path) == 0) {
        strcpy(frame.value, g_graveSitesDefault_00411ef0);
        ini_path = PTR_s_oregon_ini_004390dc;
        WritePrivateProfileStringA(
            section_name,
            key_name,
            frame.value,
            ini_path);
    }

    return lstrcmpiA(
        frame.value,
        g_graveSitesDisabledValue_00411ef0) != 0;
}

#pragma optimize("", on)
