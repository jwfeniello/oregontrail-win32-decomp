// Semantic recovery for FUN_00401110 / persisted dialog placement.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

extern "C" __declspec(dllimport) unsigned long __stdcall GetPrivateProfileStringA(
    const char* section,
    const char* key,
    const char* default_value,
    char* buffer,
    unsigned long buffer_size,
    const char* file_name);
extern "C" __declspec(dllimport) int __stdcall IsRectEmpty(const void* rect);
extern "C" __declspec(dllimport) void* __stdcall GetDesktopWindow();
extern "C" __declspec(dllimport) int __stdcall GetWindowRect(void* window, void* rect);

extern "C" int __cdecl atoi(const char* text);
extern "C" char* __cdecl strchr(char* text, int ch);
extern "C" int __cdecl strcmp(const char* left, const char* right);
extern "C" unsigned int __cdecl strlen(const char* text);

#pragma comment(lib, "user32.lib")
#pragma comment(lib, "kernel32.lib")

#pragma intrinsic(strcmp, strlen)

extern "C" const char g_dialogPlacementDefault_00401110[] = "default";
extern "C" const char g_dialogPlacementProfileKey_00401430[];
extern "C" const char* PTR_s_oregon_ini_004390dc;

#pragma pack(push, 1)
struct DialogPlacementRect_00401110 {
    int left;
    int top;
    int right;
    int bottom;
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" int __cdecl OtLoadSavedDialogPlacement_00401110_RealCpp(
    const char* section,
    DialogPlacementRect_00401110* persisted_rect)
{
    char text[0x28];
    DialogPlacementRect_00401110 desktop_rect;
    char* token;

    GetPrivateProfileStringA(
        section,
        g_dialogPlacementProfileKey_00401430,
        g_dialogPlacementDefault_00401110,
        text,
        0x27,
        PTR_s_oregon_ini_004390dc);

    if (strcmp(text, g_dialogPlacementDefault_00401110) == 0) {
        return 0;
    }

    persisted_rect->left = 0;
    persisted_rect->left = atoi(text);

    token = strchr(text, ' ');
    if (token != 0) {
        if (strlen(token) > 1) {
            ++token;
            persisted_rect->top = atoi(token);

            token = strchr(token, ' ');
            if (token != 0) {
                if (strlen(token) > 1) {
                    ++token;
                    persisted_rect->right = atoi(token);

                    token = strchr(token, ' ');
                    if (token != 0) {
                        if (strlen(token) > 1) {
                            ++token;
                            persisted_rect->bottom = atoi(token);
                        }
                    }
                }
            }
        }
    }

    if (IsRectEmpty(persisted_rect) != 0) {
        return 0;
    }

    GetWindowRect(GetDesktopWindow(), &desktop_rect);

    if (persisted_rect->top > desktop_rect.top &&
        persisted_rect->bottom < desktop_rect.bottom &&
        persisted_rect->left > desktop_rect.left &&
        persisted_rect->right < desktop_rect.right) {
        return 1;
    }

    return 0;
}

#pragma optimize("", on)
