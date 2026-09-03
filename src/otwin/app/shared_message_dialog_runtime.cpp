// Product-owned launcher and shared state for the game's common message dialog.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

typedef long (__stdcall *OtDialogProc_00401570)(
    void* dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam);

extern "C" __declspec(dllimport) int __stdcall DialogBoxParamA(
    void* instance,
    const char* template_name,
    void* parent_window,
    OtDialogProc_00401570 dialog_proc,
    long init_param);

#pragma comment(lib, "user32.lib")

extern "C" void* g_applicationModule_00405a40_20260603;

// These five values are one state machine: the launcher stages the text and
// caption, the callback records the selected button, and the launcher returns
// that result after DialogBoxParamA completes.
extern "C" int g_sharedMessageDialogResult = 0;
extern "C" void* g_sharedMessageDialogCaption = 0;
extern "C" void* g_sharedMessageDialogText = 0;
extern "C" int g_sharedMessageDialogUseAlternateTemplate = 0;

extern "C" long __stdcall OtSharedMessageDialogProcDependency_00401570(
    void* dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam);

#pragma optimize("s", off)
#pragma optimize("t", on)
#pragma code_seg(".otsem")

// Stages the dialog state, selects the one-button or two-button resource, and
// returns the button code written by the shared callback.
extern "C" int __cdecl OtRunSharedMessageDialog_00401e70_RealCpp(
    void* parent_window,
    void* message_text,
    void* caption_text,
    int use_alternate_template)
{
    g_sharedMessageDialogText = message_text;
    g_sharedMessageDialogCaption = caption_text;
    g_sharedMessageDialogUseAlternateTemplate = use_alternate_template;

    if (use_alternate_template == 0) {
        DialogBoxParamA(
            g_applicationModule_00405a40_20260603,
            reinterpret_cast<const char*>(0x0104),
            parent_window,
            OtSharedMessageDialogProcDependency_00401570,
            0);
        return g_sharedMessageDialogResult;
    }

    DialogBoxParamA(
        g_applicationModule_00405a40_20260603,
        reinterpret_cast<const char*>(0x0105),
        parent_window,
        OtSharedMessageDialogProcDependency_00401570,
        0);
    return g_sharedMessageDialogResult;
}

#pragma code_seg()
#pragma optimize("", on)
