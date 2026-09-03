// Product semantic recovery for OtToggleMenuItemCheckState @ 0x00405720.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This Product source must be compiled with 32-bit MSVC."
#endif

#pragma comment(lib, "user32.lib")

extern "C" __declspec(dllimport) void* __stdcall GetMenu(void* window);
extern "C" __declspec(dllimport) void* __stdcall GetSubMenu(
    void* menu,
    int position);
extern "C" __declspec(dllimport) unsigned int __stdcall GetMenuState(
    void* menu,
    unsigned int item_id,
    unsigned int flags);
extern "C" __declspec(dllimport) unsigned int __stdcall CheckMenuItem(
    void* menu,
    unsigned int item_id,
    unsigned int check);
extern "C" __declspec(dllimport) int __stdcall DrawMenuBar(void* window);

#pragma pack(push, 1)
struct RuntimeWindowState_00405720 {
    char reserved_00[4];
    void* main_window;

    void OtToggleMenuItemCheckState_RealCpp(
        unsigned int menu_item_id,
        int unused);
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)
#pragma code_seg(".otsem")

// Toggles one item under the application's Options submenu and redraws the
// menu bar. Keeping the menu lookup and check-state selection as their natural
// nested expressions preserves the original VC4 argument schedule.
void RuntimeWindowState_00405720::OtToggleMenuItemCheckState_RealCpp(
    unsigned int menu_item_id,
    int)
{
    void* menu;
    int item;
    unsigned int state;

    menu = GetSubMenu(GetMenu(main_window), 2);
    item = menu_item_id;
    state = GetMenuState(menu, item, 0);

    if ((state & 8) != 0) {
        CheckMenuItem(menu, item, 0);
    } else {
        CheckMenuItem(menu, item, 8);
    }
    DrawMenuBar(main_window);
}

#pragma code_seg()
#pragma optimize("", on)
