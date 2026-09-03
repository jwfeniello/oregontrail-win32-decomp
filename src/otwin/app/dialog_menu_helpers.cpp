// Product semantic recovery for the shared modal-dialog wrapper.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

extern "C" __declspec(dllimport) int __stdcall DialogBoxParamA(
    void* instance,
    const char* template_name,
    void* parent_window,
    void* dialog_proc,
    long init_param);
extern "C" __declspec(dllimport) int __stdcall UpdateWindow(void* window);

#pragma comment(lib, "user32.lib")

#pragma optimize("s", off)
#pragma optimize("t", on)

// Launches a shared modal dialog, normalizes the historical -1 initialization
// sentinel, and refreshes the owner after the dialog closes.
extern "C" int __cdecl OtRunModalDialogAndRefreshParentAlt1_00401530_38pct(
    void* instance,
    void* parent_window,
    void* dialog_proc,
    const char* template_name,
    long init_param)
{
    int result;

    if (init_param == -1) {
        result = DialogBoxParamA(
            instance,
            template_name,
            parent_window,
            dialog_proc,
            0);
    } else {
        result = DialogBoxParamA(
            instance,
            template_name,
            parent_window,
            dialog_proc,
            init_param);
    }

    UpdateWindow(parent_window);
    return result;
}

#pragma optimize("", on)
