// Product-tree semantic closure for FUN_00401290_00001290.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

extern "C" __declspec(dllimport) int __stdcall IsWindow(void*);
extern "C" __declspec(dllimport) void* __stdcall GetDlgItem(void*, int);
extern "C" __declspec(dllimport) int __stdcall GetWindowRect(void*, void*);
extern "C" __declspec(dllimport) int __stdcall ScreenToClient(void*, void*);
extern "C" __declspec(dllimport) int __stdcall SetWindowPos(
    void*,
    void*,
    int,
    int,
    int,
    int,
    unsigned int);

#pragma optimize("s", off)
#pragma optimize("t", on)

struct OtRect_00401290 {
    int left;
    int top;
    int right;
    int bottom;
};

extern "C" void __cdecl OtScaleDialogChildFromDialogUnits_00401290_DirectImport(
    void* dialog,
    int control_id,
    int dialog_unit_width,
    int dialog_unit_height)
{
    OtRect_00401290 rect;
    register void* child;

    if (IsWindow(dialog)) {
        child = GetDlgItem(dialog, control_id);
        if (IsWindow(child)) {
            GetWindowRect(GetDlgItem(dialog, control_id), &rect);
            ScreenToClient(dialog, &rect.left);
            ScreenToClient(dialog, &rect.right);

            rect.left = (rect.left * 10) / dialog_unit_width;
            rect.right = (rect.right * 10) / dialog_unit_width;
            rect.top = (rect.top * 20) / dialog_unit_height;
            rect.bottom = (rect.bottom * 20) / dialog_unit_height;

            SetWindowPos(
                GetDlgItem(dialog, control_id),
                0,
                rect.left,
                rect.top,
                rect.right - rect.left,
                rect.bottom - rect.top,
                4);
        }
    }
}

#pragma optimize("", on)
