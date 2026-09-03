// Canonical product message pump for Oregon32.exe RVA 0x00002ed0.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

#pragma comment(lib, "user32.lib")

#pragma pack(push, 4)
struct AppMessage_00402ed0 {
    void* window;
    unsigned int message;
    unsigned int wparam;
    long lparam;
    unsigned long time;
    long point_x;
    long point_y;
};
#pragma pack(pop)

typedef int (__stdcall *OtIsDialogMessageProc_00402ed0)(
    void* dialog,
    AppMessage_00402ed0* message);
typedef int (__stdcall *OtTranslateMessageProc_00402ed0)(
    const AppMessage_00402ed0* message);
typedef int (__stdcall *OtIsWindowProc_00402ed0)(void* window);

extern "C" __declspec(dllimport) int __stdcall GetMessageA(
    AppMessage_00402ed0* message,
    void* window,
    unsigned int first_message,
    unsigned int last_message);
extern "C" __declspec(dllimport) int __stdcall TranslateAcceleratorA(
    void* window,
    void* accelerator,
    AppMessage_00402ed0* message);
extern "C" __declspec(dllimport) int __stdcall IsWindow(void* window);
extern "C" __declspec(dllimport) int __stdcall IsDialogMessageA(
    void* dialog,
    AppMessage_00402ed0* message);
extern "C" __declspec(dllimport) int __stdcall TranslateMessage(
    const AppMessage_00402ed0* message);
extern "C" __declspec(dllimport) long __stdcall DispatchMessageA(
    const AppMessage_00402ed0* message);

#pragma data_seg(".otdat")
extern "C" void* g_mainAccelerator_00402ed0 = 0;
extern "C" void* g_primaryModelessDialog_00402ed0 = 0;
extern "C" void* g_secondaryModelessDialog_00402ed0 = 0;
extern "C" void* g_tertiaryModelessDialog_00402ed0 = 0;
#pragma data_seg()

#pragma optimize("s", off)
#pragma optimize("t", on)
#pragma code_seg(".otsem")

extern "C" unsigned int __cdecl
OtRunApplicationMessagePump_00402ed0_RealCpp()
{
    AppMessage_00402ed0 message;

    if (GetMessageA(&message, 0, 0, 0) != 0) {
        OtIsDialogMessageProc_00402ed0 dispatch_to_dialog;
        OtTranslateMessageProc_00402ed0 translate_message;
        OtIsWindowProc_00402ed0 is_window;

        dispatch_to_dialog = IsDialogMessageA;
        translate_message = TranslateMessage;
        is_window = IsWindow;
        do {
            if (TranslateAcceleratorA(
                    message.window,
                    g_mainAccelerator_00402ed0,
                    &message) == 0) {
                if ((!is_window(g_primaryModelessDialog_00402ed0) ||
                     !dispatch_to_dialog(
                         g_primaryModelessDialog_00402ed0,
                         &message)) &&
                    (!is_window(g_secondaryModelessDialog_00402ed0) ||
                     !dispatch_to_dialog(
                         g_secondaryModelessDialog_00402ed0,
                         &message)) &&
                    (!is_window(g_tertiaryModelessDialog_00402ed0) ||
                     !dispatch_to_dialog(
                         g_tertiaryModelessDialog_00402ed0,
                         &message))) {
                    translate_message(&message);
                    DispatchMessageA(&message);
                }
            }
        } while (GetMessageA(&message, 0, 0, 0) != 0);
    }

    return message.wparam;
}

#pragma code_seg()
#pragma optimize("", on)
