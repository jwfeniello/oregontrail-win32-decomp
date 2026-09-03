// Product C++ promotion of FUN_00404950: renders the PRODUCT.PF license owner.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

#include <stdio.h>
#include <string.h>

extern "C" FILE* __cdecl _fsopen(
    const char* file_name,
    const char* mode,
    int share_flag);
extern "C" __declspec(dllimport) unsigned long __stdcall SetTextColor(
    void* dc,
    unsigned long color);
extern "C" __declspec(dllimport) unsigned int __stdcall SetTextAlign(
    void* dc,
    unsigned int flags);
extern "C" __declspec(dllimport) int __stdcall SetBkMode(void* dc, int mode);
extern "C" __declspec(dllimport) int __stdcall TextOutA(
    void* dc,
    int x,
    int y,
    const char* text,
    int text_length);
extern "C" __declspec(dllimport) void __stdcall FatalAppExitA(
    unsigned int action,
    const char* message);

#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "kernel32.lib")

extern "C" unsigned int __cdecl strlen(const char* text);
#pragma intrinsic(strlen)

#pragma code_seg(".otsem")
extern "C" __declspec(allocate(".otsem"))
const char g_productPfName_00404950_20260605[] = "product.pf";
extern "C" __declspec(allocate(".otsem"))
const char g_productPfMode_00404950_20260605[] = "rb";
extern "C" __declspec(allocate(".otsem"))
const char g_unableToOpenProductPf_00404950_20260605[] =
    "Unable to open PRODUCT.PF.";
extern "C" __declspec(allocate(".otsem"))
const char g_unableToReadProductPf_00404950_20260605[] =
    "Unable to read PRODUCT.PF.";
extern "C" __declspec(allocate(".otsem"))
const char g_productNeedsIdented_00404950_20260605[] =
    "This product needs to be idented with the MECC Copy/Label Utility.";
extern "C" __declspec(allocate(".otsem"))
const char g_licensedToPrefix_00404950_20260605[] = "Licensed to:";

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" void __cdecl
OtMainWindowCommandLatch_00004950_ProductPf_20260605_ReccmpWip(void* dc)
{
    char product_record[0x15e];
    register FILE* product_file;
    char* licensed_name;
    register void* device_context;

    product_file = _fsopen(
        g_productPfName_00404950_20260605,
        g_productPfMode_00404950_20260605,
        0x20);
    if (product_file == 0) {
        FatalAppExitA(0, g_unableToOpenProductPf_00404950_20260605);
    }

    if (fread(product_record, 0x15e, 1, product_file) == 0) {
        fclose(product_file);
        FatalAppExitA(0, g_unableToReadProductPf_00404950_20260605);
    }
    fclose(product_file);

    if (*reinterpret_cast<short*>(product_record + 4) != 0) {
        licensed_name = product_record + 0xba;
        if (strlen(licensed_name) == 0) {
            FatalAppExitA(0, g_productNeedsIdented_00404950_20260605);
        }

        device_context = dc;
        SetTextColor(device_context, 0);
        SetTextAlign(device_context, 6);
        SetBkMode(device_context, 1);
        SetBkMode(device_context, 0x00ffffff);
        TextOutA(
            device_context,
            0x140,
            0x13b,
            g_licensedToPrefix_00404950_20260605,
            0x0c);
        TextOutA(
            device_context,
            0x140,
            0x154,
            licensed_name,
            strlen(licensed_name));
    }
}

#pragma optimize("", on)
#pragma code_seg()
