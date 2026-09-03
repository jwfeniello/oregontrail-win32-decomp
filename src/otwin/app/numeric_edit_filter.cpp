// Product-semantic recovery of the numeric edit filter at 0x00401000.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include <string.h>

#pragma intrinsic(strcpy, strcmp, memset)

extern "C" __declspec(dllimport) void* __stdcall GetDlgItem(
    void* dialog,
    int control_id);
extern "C" __declspec(dllimport) int __stdcall GetWindowTextA(
    void* window,
    char* text,
    int maximum_characters);
extern "C" __declspec(dllimport) int __stdcall SetWindowTextA(
    void* window,
    const char* text);
extern "C" __declspec(dllimport) int __stdcall PostMessageA(
    void* window,
    unsigned int message,
    unsigned int wparam,
    long lparam);

#pragma pack(push, 1)
struct NumericEditFilterScratch_00401000_Product {
    char filtered_text[10];
    char reserved_0a[2];
    char original_text[9];
    char reserved_15[3];
};
#pragma pack(pop)

typedef char OtNumericEditFilterScratchSizeMustBe18[
    sizeof(NumericEditFilterScratch_00401000_Product) == 0x18 ? 1 : -1];

#pragma code_seg(".otsem")
#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" void __cdecl OtFilterNumericEditText_00401000_ProductWip(
    void* dialog,
    unsigned int control_id)
{
    NumericEditFilterScratch_00401000_Product scratch;
    char* cursor;

    memset(
        scratch.filtered_text,
        0,
        sizeof(scratch.filtered_text));

    GetWindowTextA(
        GetDlgItem(dialog, (int)control_id),
        scratch.original_text,
        9);
    strcpy(scratch.filtered_text, scratch.original_text);

    for (cursor = scratch.filtered_text; *cursor > '\0'; ++cursor) {
        if (*cursor > '9' || *cursor < '0') {
            strcpy(cursor, cursor + 1);
        }
    }

    if (strcmp(scratch.filtered_text, scratch.original_text) != 0) {
        SetWindowTextA(
            GetDlgItem(dialog, (int)control_id),
            scratch.filtered_text);
        PostMessageA(
            GetDlgItem(dialog, (int)control_id),
            0xb7,
            0,
            0);
    }
}

#pragma optimize("", on)
#pragma code_seg()
