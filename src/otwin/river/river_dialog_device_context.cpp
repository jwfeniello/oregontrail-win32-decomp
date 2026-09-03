// Semantic match candidates for the river dialog device-context helper at
// 0040fb70. Kept isolated because this function is allocator-sensitive.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "river_runtime.h"
#include "../app/active_text_runtime.h"

extern "C" __declspec(dllimport) void* __stdcall GlobalLock(void* handle);
extern "C" __declspec(dllimport) int __stdcall GetWindowTextLengthA(
    void* window);
extern "C" __declspec(dllimport) int __stdcall GetWindowTextA(
    void* window,
    char* text,
    int max_count);
extern "C" __declspec(dllimport) int __stdcall SetWindowTextA(
    void* window,
    const char* text);

extern "C" char g_riverDialogDeviceContextConfirmText_0040fb70[] =
    "The trail journal is full!  Should text be deleted from the beginning "
    "of the journal to make room for new entries?";
extern "C" char g_riverDialogDeviceContextRetryText_0040fb70[] =
    "You will have to delete some text from the Trail Journal yourself.";
extern "C" char g_riverDialogDeviceContextCaption_0040fb70[] =
    "Trail Journal is Full";

#pragma comment(lib, "kernel32.lib")
#pragma comment(lib, "user32.lib")

extern "C" void* __cdecl memcpy(void* destination, const void* source, unsigned int size);
extern "C" void* __cdecl memset(void* destination, int value, unsigned int size);
#pragma intrinsic(memcpy)
#pragma intrinsic(memset)

#define g_trailJournalTextBufferHandle_0040fe00 g_activeTextGlobalHandle_Product

struct EditCaretState_0040feb0_37pct {
    void OtMoveEditCaretToEndAlt19_0040feb0_37pct();
};

struct RiverDialogDeviceContext_0040fb70 {
    void* window;

    int OtRiver_DialogInvokeWithDeviceContext_RealCpp();
    int OtRiver_DialogInvokeWithDeviceContextAlt1_RealCpp();
    int OtRiver_DialogInvokeWithDeviceContextAlt2_RealCpp();
    int OtRiver_DialogInvokeWithDeviceContextAlt3_RealCpp();
    int OtRiver_DialogInvokeWithDeviceContextAlt4_RealCpp();
    int OtRiver_DialogInvokeWithDeviceContextAlt5_RealCpp();
    void OtRiver_BlitDialogClientArea_0040fe00_RealCpp(unsigned int deleted_count);
};

typedef void* (__stdcall *GetDcLikeFn_0040fb70)(void*);
typedef int (__stdcall *ValidateDcLikeFn_0040fb70)(void*);
typedef int (__stdcall *MessageBoxFn_0040fb70)(
    void*,
    const char*,
    const char*,
    unsigned int);

#pragma optimize("s", off)
#pragma optimize("t", on)

int RiverDialogDeviceContext_0040fb70::OtRiver_DialogInvokeWithDeviceContext_RealCpp()
{
    void* window = this->window;
    register RiverDialogDeviceContext_0040fb70* state = this;
    register ValidateDcLikeFn_0040fb70 validate_window =
        IsWindowVisible;
    register GetDcLikeFn_0040fb70 get_parent = GetParent;
    void* parent_window = get_parent(window);

    if (validate_window(parent_window) != 0) {
        SendMessageA(get_parent(state->window), 0x0464, 0, 0);
    }

    register MessageBoxFn_0040fb70 message_box = MessageBoxA;
    if (message_box(
            0,
            g_riverDialogDeviceContextConfirmText_0040fb70,
            g_riverDialogDeviceContextCaption_0040fb70,
            4) == 6) {
        state->OtRiver_BlitDialogClientArea_0040fe00_RealCpp(0x03e8);
        return 1;
    }

    message_box(
        0,
        g_riverDialogDeviceContextRetryText_0040fb70,
        g_riverDialogDeviceContextCaption_0040fb70,
        0);

    if (validate_window(state->window) != 0) {
        SetFocus(state->window);
    }

    return 0;
}

int RiverDialogDeviceContext_0040fb70::
    OtRiver_DialogInvokeWithDeviceContextAlt1_RealCpp()
{
    void* window = this->window;
    register RiverDialogDeviceContext_0040fb70* state = this;
    register ValidateDcLikeFn_0040fb70 validate_window =
        IsWindowVisible;
    register GetDcLikeFn_0040fb70 get_parent = GetParent;

    if (validate_window(get_parent(window)) != 0) {
        SendMessageA(get_parent(state->window), 0x0464, 0, 0);
    }

    register MessageBoxFn_0040fb70 message_box = MessageBoxA;
    if (message_box(
            0,
            g_riverDialogDeviceContextConfirmText_0040fb70,
            g_riverDialogDeviceContextCaption_0040fb70,
            4) == 6) {
        state->OtRiver_BlitDialogClientArea_0040fe00_RealCpp(0x03e8);
        return 1;
    }

    message_box(
        0,
        g_riverDialogDeviceContextRetryText_0040fb70,
        g_riverDialogDeviceContextCaption_0040fb70,
        0);

    if (validate_window(state->window) != 0) {
        SetFocus(state->window);
    }

    return 0;
}

int RiverDialogDeviceContext_0040fb70::
    OtRiver_DialogInvokeWithDeviceContextAlt2_RealCpp()
{
    void* window = this->window;
    register RiverDialogDeviceContext_0040fb70* state = this;
    register ValidateDcLikeFn_0040fb70 validate_window;
    register GetDcLikeFn_0040fb70 get_parent;

    if ((validate_window = IsWindowVisible)(
            (get_parent = GetParent)(window)) != 0) {
        SendMessageA(get_parent(state->window), 0x0464, 0, 0);
    }

    register MessageBoxFn_0040fb70 message_box;
    if ((message_box = MessageBoxA)(
            0,
            g_riverDialogDeviceContextConfirmText_0040fb70,
            g_riverDialogDeviceContextCaption_0040fb70,
            4) == 6) {
        state->OtRiver_BlitDialogClientArea_0040fe00_RealCpp(0x03e8);
        return 1;
    }

    message_box(
        0,
        g_riverDialogDeviceContextRetryText_0040fb70,
        g_riverDialogDeviceContextCaption_0040fb70,
        0);

    if (validate_window(state->window) != 0) {
        SetFocus(state->window);
    }

    return 0;
}

int RiverDialogDeviceContext_0040fb70::
    OtRiver_DialogInvokeWithDeviceContextAlt3_RealCpp()
{
    register RiverDialogDeviceContext_0040fb70* state = this;
    register ValidateDcLikeFn_0040fb70 validate_window =
        IsWindowVisible;
    register GetDcLikeFn_0040fb70 get_parent = GetParent;
    void* parent_window;

    parent_window = get_parent(this->window);
    if (validate_window(parent_window) != 0) {
        SendMessageA(get_parent(state->window), 0x0464, 0, 0);
    }

    register MessageBoxFn_0040fb70 message_box = MessageBoxA;
    if (message_box(
            0,
            g_riverDialogDeviceContextConfirmText_0040fb70,
            g_riverDialogDeviceContextCaption_0040fb70,
            4) == 6) {
        state->OtRiver_BlitDialogClientArea_0040fe00_RealCpp(0x03e8);
        return 1;
    }

    message_box(
        0,
        g_riverDialogDeviceContextRetryText_0040fb70,
        g_riverDialogDeviceContextCaption_0040fb70,
        0);

    if (validate_window(state->window) != 0) {
        SetFocus(state->window);
    }

    return 0;
}

int RiverDialogDeviceContext_0040fb70::
    OtRiver_DialogInvokeWithDeviceContextAlt4_RealCpp()
{
    void* window = this->window;
    register RiverDialogDeviceContext_0040fb70* state = this;
    GetDcLikeFn_0040fb70 get_parent;
    void* parent_window =
        (get_parent = GetParent)(window);
    register ValidateDcLikeFn_0040fb70 validate_window =
        IsWindowVisible;

    if (validate_window(parent_window) != 0) {
        SendMessageA(get_parent(state->window), 0x0464, 0, 0);
    }

    MessageBoxFn_0040fb70 message_box;
    if ((message_box = MessageBoxA)(
            0,
            g_riverDialogDeviceContextConfirmText_0040fb70,
            g_riverDialogDeviceContextCaption_0040fb70,
            4) == 6) {
        state->OtRiver_BlitDialogClientArea_0040fe00_RealCpp(0x03e8);
        return 1;
    }

    message_box(
        0,
        g_riverDialogDeviceContextRetryText_0040fb70,
        g_riverDialogDeviceContextCaption_0040fb70,
        0);

    if (validate_window(state->window) != 0) {
        SetFocus(state->window);
    }

    return 0;
}

int RiverDialogDeviceContext_0040fb70::
    OtRiver_DialogInvokeWithDeviceContextAlt5_RealCpp()
{
    if (IsWindowVisible(GetParent(window)) != 0) {
        SendMessageA(GetParent(window), 0x0464, 0, 0);
    }

    if (MessageBoxA(
            0,
            g_riverDialogDeviceContextConfirmText_0040fb70,
            g_riverDialogDeviceContextCaption_0040fb70,
            4) == 6) {
        OtRiver_BlitDialogClientArea_0040fe00_RealCpp(0x03e8);
        return 1;
    }

    MessageBoxA(
        0,
        g_riverDialogDeviceContextRetryText_0040fb70,
        g_riverDialogDeviceContextCaption_0040fb70,
        0);

    if (IsWindowVisible(window) != 0) {
        SetFocus(window);
    }

    return 0;
}

#pragma optimize("", on)

#pragma optimize("s", off)
#pragma optimize("t", on)

void RiverDialogDeviceContext_0040fb70::
    OtRiver_BlitDialogClientArea_0040fe00_RealCpp(unsigned int deleted_count)
{
    char* journal_text = static_cast<char*>(
        GlobalLock(g_trailJournalTextBufferHandle_0040fe00));
    if (journal_text != 0) {
        int text_length = GetWindowTextLengthA(window);
        GetWindowTextA(window, journal_text, text_length);

        char* shifted_text = journal_text + deleted_count;
        unsigned int retained_count = 0x7d00 - deleted_count;
        memcpy(journal_text, shifted_text, retained_count);
        memset(journal_text + 0x7d00 - deleted_count, 0, deleted_count);

        SetWindowTextA(window, journal_text);
        SendMessageA(window, 0x00c5, 0x7cff, 0);
        reinterpret_cast<EditCaretState_0040feb0_37pct*>(this)->
            OtMoveEditCaretToEndAlt19_0040feb0_37pct();
        GlobalUnlock(g_trailJournalTextBufferHandle_0040fe00);
    }
}

#pragma optimize("", on)
