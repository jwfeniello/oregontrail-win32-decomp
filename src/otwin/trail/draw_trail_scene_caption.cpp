// Semantic candidate for OtDrawTrailSceneCaption (0x0042af80).

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

extern "C" void* g_journeyState;
extern "C" void* g_resourceModule;
extern "C" void* g_sharedDialogBackgroundBrush_004390c0;
extern "C" void* g_dialogFont_004390d8_00405320;

extern "C" __declspec(dllimport) int __stdcall FillRect(
    void* dc,
    const void* rect,
    void* brush);
extern "C" __declspec(dllimport) int __stdcall SetBkMode(
    void* dc,
    int mode);
extern "C" __declspec(dllimport) unsigned long __stdcall SetTextColor(
    void* dc,
    unsigned long color);
extern "C" __declspec(dllimport) void* __stdcall SelectObject(
    void* dc,
    void* object);
extern "C" __declspec(dllimport) unsigned int __stdcall SetTextAlign(
    void* dc,
    unsigned int flags);
extern "C" __declspec(dllimport) int __stdcall LoadStringA(
    void* module,
    unsigned int resource_id,
    char* buffer,
    int buffer_length);
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
        int clip_x,
        int clip_y);
};

struct TrailSceneCaptionJourney_0042af80 {
    char reserved_000[0x50];
    short scene_index;
};

struct TrailSceneCaptionRect_0042af80 {
    int left;
    int top;
    int right;
    int bottom;
};

struct TrailSceneCaptionState_0042af80 {
    char reserved_000[0x790];
    int caption_left_base;
    char reserved_794[0x24];
    int text_left;
    int reserved_7bc;
    int text_right;
    int caption_top_base;
    char reserved_7c8[0x1d0];
    int caption_right_base;

    void OtDrawTrailSceneCaption_0042af80_RealCpp(void* dc);
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

void TrailSceneCaptionState_0042af80::OtDrawTrailSceneCaption_0042af80_RealCpp(
    void* dc)
{
    register void* device_context = dc;
    register TrailSceneCaptionState_0042af80* state = this;
    void* old_font;
    TrailSceneCaptionRect_0042af80 caption_rect;
    char caption_text[40];

    reinterpret_cast<PositionedBitmap_0040b7b0_Semantic*>(
        reinterpret_cast<char*>(state) +
        0x7a0 +
        (static_cast<int>(
            reinterpret_cast<TrailSceneCaptionJourney_0042af80*>(
                g_journeyState)->scene_index) * 5 * 8))
        ->OtBlitWrappedPositionedBitmap_0040b7b0_Semantic(
            device_context,
            0,
            0);

    caption_rect.left = state->caption_left_base + 3;
    caption_rect.right = state->caption_right_base - 15;
    caption_rect.top = state->caption_top_base + 5;
    caption_rect.bottom = caption_rect.top + 0x16;
    FillRect(
        device_context,
        &caption_rect,
        g_sharedDialogBackgroundBrush_004390c0);

    SetBkMode(device_context, 1);
    SetTextColor(device_context, 0);
    old_font = SelectObject(
        device_context,
        g_dialogFont_004390d8_00405320);
    register unsigned int old_align =
        SetTextAlign(device_context, 6);

    unsigned long* clear = reinterpret_cast<unsigned long*>(caption_text);
    for (int i = 0; i < 10; ++i) {
        clear[i] = 0;
    }

    LoadStringA(
        g_resourceModule,
        static_cast<unsigned int>(
            static_cast<int>(
                reinterpret_cast<TrailSceneCaptionJourney_0042af80*>(
                    g_journeyState)->scene_index) + 0x70),
        caption_text,
        0x27);

    TextOutA(
        device_context,
        state->text_left + ((state->text_right - state->text_left) / 2),
        state->caption_top_base + 5,
        caption_text,
        strlen(caption_text));

    SetTextAlign(device_context, old_align);
    SelectObject(device_context, old_font);
}

#pragma optimize("", on)
