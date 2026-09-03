// Product-tree semantic recovery of the trail-journal text append routine at
// 0x0040f950.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

typedef void* HWND_0040f950;
typedef long LPARAM_0040f950;
typedef long LRESULT_0040f950;
typedef unsigned int UINT_0040f950;
typedef unsigned int WPARAM_0040f950;
typedef LRESULT_0040f950 (__stdcall *SendMessageFn_0040f950)(
    HWND_0040f950 window,
    UINT_0040f950 message,
    WPARAM_0040f950 wparam,
    LPARAM_0040f950 lparam);

extern "C" __declspec(dllimport) int __stdcall GetWindowTextLengthA(
    HWND_0040f950 window);
extern "C" __declspec(dllimport) LRESULT_0040f950 __stdcall SendMessageA(
    HWND_0040f950 window,
    UINT_0040f950 message,
    WPARAM_0040f950 wparam,
    LPARAM_0040f950 lparam);
extern "C" __declspec(dllimport) int __stdcall PostMessageA(
    HWND_0040f950 window,
    UINT_0040f950 message,
    WPARAM_0040f950 wparam,
    LPARAM_0040f950 lparam);

#pragma comment(lib, "USER32.LIB")

extern "C" int __cdecl strlen(const char* text);
extern "C" int __cdecl strcmp(const char* left, const char* right);
extern "C" char* __cdecl strcpy(char* destination, const char* source);
extern "C" void* __cdecl memcpy(
    void* destination,
    const void* source,
    unsigned int size);
#pragma intrinsic(strlen)
#pragma intrinsic(strcmp)
#pragma intrinsic(strcpy)
#pragma intrinsic(memcpy)

#pragma pack(push, 1)
struct TrailJournalTextCache_0040f950 {
    char reserved_0000[0x0124];
    char current_line[0x001a];
    char previous_line[0x001a];
};

struct EditCaretState_0040feb0_37pct {
    HWND_0040f950 edit_control;

    void OtMoveEditCaretToEndAlt19_0040feb0_37pct();
};

struct RiverDialogDeviceContext_0040fb70 {
    HWND_0040f950 window;

    int OtRiver_DialogInvokeWithDeviceContextAlt5_RealCpp();
};

struct TrailJournalState_0040f950 {
    HWND_0040f950 edit_control;

    int OtAppendTrailJournalText_0040f950_RealCpp(char* pending_text);
    void OtAppendTrailJournalText_0040f950_ProductWip(
        const char* pending_text);
};
#pragma pack(pop)

extern "C" TrailJournalTextCache_0040f950* g_journeyState;
extern "C" const char g_emptyString_004395ac[];
extern "C" int g_trailJournalEditHasSelection_0040f870;
extern "C" int g_trailJournalEditSelectionDirty_0040f870;

#pragma optimize("s", off)
#pragma optimize("t", on)

int TrailJournalState_0040f950::
    OtAppendTrailJournalText_0040f950_RealCpp(char* pending_text)
{
    register TrailJournalState_0040f950* state = this;
    register char* text = pending_text;
    int text_length;
    unsigned int index;
    unsigned int projected_text_length;

    if (strlen(text) == 0) {
        return 0;
    }

    reinterpret_cast<EditCaretState_0040feb0_37pct*>(state)->
        OtMoveEditCaretToEndAlt19_0040feb0_37pct();

    if (strcmp(
            g_journeyState->previous_line,
            g_journeyState->current_line) != 0) {
        char* previous_line;
        unsigned int previous_length;
        register unsigned int projected_length;

        memcpy(
            g_journeyState->previous_line,
            g_journeyState->current_line,
            0x001a);

        previous_line = g_journeyState->previous_line;
        previous_length = strlen(previous_line);

        projected_length =
            previous_length + GetWindowTextLengthA(state->edit_control) + 2;
        if (projected_length >= 0x00007d00) {
            if (reinterpret_cast<RiverDialogDeviceContext_0040fb70*>(state)->
                    OtRiver_DialogInvokeWithDeviceContextAlt5_RealCpp() == 0) {
                return 0;
            }
        }

        reinterpret_cast<SendMessageFn_0040f950>(SendMessageA)(
            state->edit_control,
            0x0102,
            0x000d,
            0);
        index = 0;

        if (previous_length != 0) {
            do {
                reinterpret_cast<SendMessageFn_0040f950>(SendMessageA)(
                    state->edit_control,
                    0x0102,
                    (WPARAM_0040f950)(signed char)previous_line[index],
                    0);
                ++index;
            } while (previous_length > index);
        }

        reinterpret_cast<SendMessageFn_0040f950>(SendMessageA)(
            state->edit_control,
            0x0102,
            0x000d,
            0);
    }

    text_length = strlen(text);
    projected_text_length = GetWindowTextLengthA(state->edit_control);
    projected_text_length += text_length + 5;
    if (projected_text_length >= 0x00007d00) {
        if (reinterpret_cast<RiverDialogDeviceContext_0040fb70*>(state)->
                OtRiver_DialogInvokeWithDeviceContextAlt5_RealCpp() == 0) {
            return 0;
        }
    }

    index = 4;
    do {
        reinterpret_cast<SendMessageFn_0040f950>(SendMessageA)(
            state->edit_control,
            0x0102,
            0x0020,
            0);
        --index;
    } while (index != 0);

    for (index = 0; index < text_length; ++index) {
        reinterpret_cast<SendMessageFn_0040f950>(SendMessageA)(
            state->edit_control,
            0x0102,
            (WPARAM_0040f950)(signed char)text[index],
            0);
    }

    reinterpret_cast<SendMessageFn_0040f950>(SendMessageA)(
        state->edit_control,
        0x0102,
        0x000d,
        0);
    PostMessageA(state->edit_control, 0x00cd, 0, 0);

    strcpy(text, g_emptyString_004395ac);

    g_trailJournalEditHasSelection_0040f870 = 1;
    g_trailJournalEditSelectionDirty_0040f870 = 1;
    return 1;
}

#pragma optimize("", on)

// Current Product callers discard the original integer result and declare the
// mutable text buffer as const. Keep that compatibility adapter out of the
// candidate .text section while retaining the original thiscall ABI above.
#pragma code_seg(".otsem")
void TrailJournalState_0040f950::
    OtAppendTrailJournalText_0040f950_ProductWip(const char* pending_text)
{
    OtAppendTrailJournalText_0040f950_RealCpp(
        const_cast<char*>(pending_text));
}
#pragma code_seg()
