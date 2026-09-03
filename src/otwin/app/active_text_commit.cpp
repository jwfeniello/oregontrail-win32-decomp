#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

extern "C" void* g_activeTextGlobalHandle_Product;
extern "C" int g_activeTextUsesEditControl;
extern "C" void* g_activeTextEditWindow;

extern "C" __declspec(dllimport) void* __stdcall GlobalLock(void* handle);
extern "C" __declspec(dllimport) int __stdcall GetWindowTextLengthA(
    void* window);
extern "C" __declspec(dllimport) int __stdcall GetWindowTextA(
    void* window,
    char* text,
    int max_count);
extern "C" __declspec(dllimport) int __stdcall GlobalUnlock(void* handle);
extern "C" __declspec(dllimport) int __stdcall DestroyWindow(void* window);

#pragma comment(lib, "kernel32.lib")
#pragma comment(lib, "user32.lib")

#pragma pack(push, 1)
struct ActiveTextCommitState_0040fdb0 {
    void* edit_control;

    void OtCommitActiveEditTextToGlobal_0040fdb0_RealCpp();
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

void ActiveTextCommitState_0040fdb0::
    OtCommitActiveEditTextToGlobal_0040fdb0_RealCpp()
{
    char* text = static_cast<char*>(GlobalLock(g_activeTextGlobalHandle_Product));
    if (text != 0) {
        int text_length = GetWindowTextLengthA(edit_control) + 1;
        GetWindowTextA(edit_control, text, text_length);
        GlobalUnlock(g_activeTextGlobalHandle_Product);
    }

    g_activeTextUsesEditControl = 0;
    g_activeTextEditWindow = 0;
    DestroyWindow(edit_control);
}

#pragma optimize("", on)
