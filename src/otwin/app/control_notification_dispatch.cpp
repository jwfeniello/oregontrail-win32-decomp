// Focused semantic promotion for control-notification command dispatch.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#pragma pack(push, 1)
struct ControlNotificationDispatcher_00404a70 {
    char reserved_00[0x10];
    void* target_window;

    int OtDispatchControlNotification_6e_72_00404a70_RealCpp(
        unsigned int notification_id,
        unsigned int);
};
#pragma pack(pop)

extern "C" __declspec(dllimport) int __stdcall IsWindow(void* window);
extern "C" __declspec(dllimport) int __stdcall PostMessageA(
    void* window,
    unsigned int message,
    unsigned int wparam,
    long lparam);

#pragma comment(lib, "user32.lib")

#pragma optimize("s", off)
#pragma optimize("t", on)

int ControlNotificationDispatcher_00404a70::
    OtDispatchControlNotification_6e_72_00404a70_RealCpp(
        unsigned int notification_id,
        unsigned int)
{
    register ControlNotificationDispatcher_00404a70* dispatcher = this;

    if (IsWindow(dispatcher->target_window) == 0) {
        return 0;
    }

    switch (notification_id & 0x0ffff) {
    case 0x6e:
        PostMessageA(dispatcher->target_window, 0x00c7, 0, 0);
        return 0;

    case 0x6f:
        PostMessageA(dispatcher->target_window, 0x0300, 0, 0);
        return 0;

    case 0x70:
        PostMessageA(dispatcher->target_window, 0x0301, 0, 0);
        return 0;

    case 0x71:
        PostMessageA(dispatcher->target_window, 0x0302, 0, 0);
        return 0;

    case 0x72:
        PostMessageA(dispatcher->target_window, 0x0303, 0, 0);
        break;
    }

    return 0;
}

#pragma optimize("", on)
