#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

extern "C" void* g_applicationModule_00405a40_20260603;
extern "C" int g_cdMediaMode_00439108;
extern "C" long __stdcall OtDispatchStoredWindowObject_00405980_RealCpp(
    void* window,
    unsigned int message,
    unsigned int wparam,
    long lparam);

extern "C" __declspec(dllimport) void* __stdcall LoadIconA(
    void* instance,
    const void* icon_name);
extern "C" __declspec(dllimport) void* __stdcall LoadCursorA(
    void* instance,
    const void* cursor_name);
extern "C" __declspec(dllimport) unsigned short __stdcall RegisterClassA(
    const void* window_class);
extern "C" __declspec(dllimport) void __stdcall FatalAppExitA(
    unsigned int action,
    const char* message);

#pragma comment(lib, "user32.lib")

#pragma pack(push, 1)
struct WindowClassA_00404f60_Product {
    unsigned int style;
    void* window_proc;
    int class_extra;
    int window_extra;
    void* instance;
    void* icon;
    void* cursor;
    void* background_brush;
    const char* menu_name;
    const char* class_name;
};
#pragma pack(pop)

#pragma data_seg(".otdat")
extern "C" const char g_mainWindowClassName_00404f60[] = "OTMainWindow";
extern "C" const char g_mainWindowMenuName_00404f60[] = "MAINMENU";
extern "C" const char g_registerClassFatalMessage_00404f60[] =
    "Couldn't register the main window!";
#pragma data_seg()

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" void __cdecl OtRegisterMainWindowClass_00404f60_RealCpp()
{
    WindowClassA_00404f60_Product window_class;
    void* instance = g_applicationModule_00405a40_20260603;

    window_class.style = 0x2000;
    window_class.window_proc = OtDispatchStoredWindowObject_00405980_RealCpp;
    window_class.class_extra = 0;
    window_class.window_extra = 4;
    window_class.instance = instance;

    if (g_cdMediaMode_00439108 != 0) {
        window_class.icon =
            LoadIconA(instance, reinterpret_cast<const void*>(0x03e8));
    } else {
        window_class.icon =
            LoadIconA(instance, reinterpret_cast<const void*>(0x03e9));
    }

    window_class.cursor =
        LoadCursorA(0, reinterpret_cast<const void*>(0x7f00));
    window_class.background_brush = 0;
    window_class.menu_name = g_mainWindowMenuName_00404f60;
    window_class.class_name = g_mainWindowClassName_00404f60;

    if (RegisterClassA(&window_class) == 0) {
        FatalAppExitA(0, g_registerClassFatalMessage_00404f60);
    }
}

#pragma optimize("", on)
