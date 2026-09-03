// Product semantic WIP for OtDrawTrailConditionGauge @ 0x0042ad80.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

extern "C" void* g_journeyState;
extern "C" void* g_resourceModule;
extern "C" void* g_sharedDialogBackgroundBrush_004390c0;
extern "C" void* g_dialogFont_004390d8_00405320;

extern "C" __declspec(dllimport) void* __stdcall CreatePen(
    int style,
    int width,
    unsigned long color);
extern "C" __declspec(dllimport) void* __stdcall SelectObject(
    void* dc,
    void* object);
extern "C" __declspec(dllimport) int __stdcall MoveToEx(
    void* dc,
    int x,
    int y,
    void* old_point);
extern "C" __declspec(dllimport) int __stdcall LineTo(
    void* dc,
    int x,
    int y);
extern "C" __declspec(dllimport) int __stdcall DeleteObject(void* object);
extern "C" __declspec(dllimport) int __stdcall SetBkMode(void* dc, int mode);
extern "C" __declspec(dllimport) unsigned int __stdcall SetTextAlign(
    void* dc,
    unsigned int flags);
extern "C" __declspec(dllimport) int __stdcall LoadStringA(
    void* module,
    unsigned int resource_id,
    char* buffer,
    int buffer_length);
extern "C" __declspec(dllimport) int __stdcall FillRect(
    void* dc,
    const void* rect,
    void* brush);
extern "C" __declspec(dllimport) unsigned long __stdcall GetTextColor(
    void* dc);
extern "C" __declspec(dllimport) unsigned long __stdcall SetTextColor(
    void* dc,
    unsigned long color);
extern "C" __declspec(dllimport) int __stdcall TextOutA(
    void* dc,
    int x,
    int y,
    const char* text,
    int text_length);

#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "user32.lib")

extern "C" unsigned int __cdecl strlen(const char* text);
#pragma intrinsic(strlen)

#pragma pack(push, 1)
struct PositionedBitmap_0040b7b0_Semantic {
    char opaque[1];

    int OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
        void* dc,
        int source_x,
        int source_y);
};

struct JourneyConditionState_0042ad80_ProductWip {
    char reserved_000[0x52];
    short condition_id;
};

struct Rect_0042ad80_ProductWip {
    int left;
    int top;
    int right;
    int bottom;
};

struct TrailConditionGaugeState_0042ad80_ProductWip {
    char reserved_000[0x980];
    PositionedBitmap_0040b7b0_Semantic gauge_bitmap;
    char reserved_981[0x17];
    int gauge_left;
    int gauge_top;
    int gauge_right;
    int label_bottom_base;

    void OtDrawTrailConditionGauge_0042ad80_ProductWip(void* dc);
};
#pragma pack(pop)

#pragma code_seg(".otsem")
#pragma optimize("s", off)
#pragma optimize("t", on)

void TrailConditionGaugeState_0042ad80_ProductWip::
OtDrawTrailConditionGauge_0042ad80_ProductWip(void* dc)
{
    unsigned long old_color;
    short condition;
    int marker_delta;
    Rect_0042ad80_ProductWip label_rect;
    char condition_text[40];
    TrailConditionGaugeState_0042ad80_ProductWip* state = this;
    void* device_context = dc;

    state->gauge_bitmap.OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
        device_context,
        0,
        0);

    {
        void* old_pen;
        void* pen = CreatePen(0, 2, 0x01000029ul);
        old_pen = SelectObject(device_context, pen);
        MoveToEx(
            device_context,
            state->gauge_left +
                    ((state->gauge_right - state->gauge_left) / 2) -
                1,
            state->gauge_top + 0x2d,
            0);
        marker_delta = 9;
        marker_delta -= static_cast<int>(
            static_cast<JourneyConditionState_0042ad80_ProductWip*>(
                g_journeyState)
                ->condition_id);
        marker_delta += marker_delta * 4;
        LineTo(
            device_context,
            state->gauge_left +
                    ((state->gauge_right - state->gauge_left) / 2) -
                1,
            state->gauge_top + marker_delta);
        SelectObject(device_context, old_pen);
        DeleteObject(pen);
    }

    void* old_font = SelectObject(
        device_context,
        g_dialogFont_004390d8_00405320);
    SetBkMode(device_context, 1);
    SetTextAlign(device_context, 6);

    unsigned long* clear = reinterpret_cast<unsigned long*>(condition_text);
    for (int index = 0; index < 10; ++index) {
        clear[index] = 0;
    }

    LoadStringA(
        g_resourceModule,
        static_cast<unsigned int>(
            static_cast<JourneyConditionState_0042ad80_ProductWip*>(
                g_journeyState)
                ->condition_id +
            0x80),
        condition_text,
        0x27);

    int label_left = state->gauge_left;
    int label_base = state->label_bottom_base;
    label_left -= 0x0f;
    int label_top = label_base + 5;
    label_base += 0x16;
    label_rect.left = label_left;
    int label_right = state->gauge_right;
    label_rect.top = label_top;
    label_right += 0x0f;
    label_rect.right = label_right;
    label_rect.bottom = label_base;
    FillRect(
        device_context,
        &label_rect,
        g_sharedDialogBackgroundBrush_004390c0);

    condition = static_cast<JourneyConditionState_0042ad80_ProductWip*>(
                    g_journeyState)
                    ->condition_id;
    old_color = GetTextColor(device_context);
    if (condition == 5) {
        SetTextColor(device_context, 0x000000fful);
    } else if (condition == 4) {
        SetTextColor(device_context, 0x0000007ful);
    } else if (condition == 3) {
        SetTextColor(device_context, 0x007f00fful);
    } else if (condition == 2) {
        SetTextColor(device_context, 0x007f007ful);
    } else if (condition == 1) {
        SetTextColor(device_context, 0x007f0000ul);
    } else {
        SetTextColor(device_context, 0x00ff0000ul);
    }

    TextOutA(
        device_context,
        label_rect.left + ((label_rect.right - label_rect.left) / 2),
        label_rect.top,
        condition_text,
        strlen(condition_text));
    SetTextColor(device_context, old_color);
    SelectObject(device_context, old_font);
}

#pragma optimize("", on)
#pragma code_seg()
