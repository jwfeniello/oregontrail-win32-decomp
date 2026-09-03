// Product-tree semantic closure for FUN_00405320_00005320.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "user32.lib")

typedef void* HDC_00405320;
typedef void* HFONT_00405320;
typedef void* HWND_00405320;

#pragma pack(push, 1)
struct LogFontA_00405320 {
    long height;
    long width;
    long escapement;
    long orientation;
    long weight;
    unsigned char italic;
    unsigned char underline;
    unsigned char strike_out;
    unsigned char char_set;
    unsigned char out_precision;
    unsigned char clip_precision;
    unsigned char quality;
    unsigned char pitch_and_family;
    char face_name[32];
};

struct TextMetricA_00405320 {
    long height;
    long ascent;
    long descent;
    long internal_leading;
    long external_leading;
    long average_char_width;
    long max_char_width;
    long weight;
    long overhang;
    long digitized_aspect_x;
    long digitized_aspect_y;
    unsigned char first_char;
    unsigned char last_char;
    unsigned char default_char;
    unsigned char break_char;
    unsigned char italic;
    unsigned char underlined;
    unsigned char struck_out;
    unsigned char pitch_and_family;
    unsigned char char_set;
};

struct ApplicationOptionMenuStateSync_00405320 {
    char reserved_00[4];
    HWND_00405320 main_window;

    void OtOptionMenuStateSync_00405320_RealCpp();
};
#pragma pack(pop)

extern "C" char* __cdecl strncpy(
    char* destination,
    const char* source,
    unsigned int max_count);

extern "C" __declspec(dllimport) HFONT_00405320 __stdcall CreateFontIndirectA(
    const LogFontA_00405320* log_font);
extern "C" __declspec(dllimport) HDC_00405320 __stdcall GetDC(
    HWND_00405320 window);
extern "C" __declspec(dllimport) void* __stdcall SelectObject(
    HDC_00405320 dc,
    HFONT_00405320 object);
extern "C" __declspec(dllimport) int __stdcall GetTextMetricsA(
    HDC_00405320 dc,
    TextMetricA_00405320* metrics);
extern "C" __declspec(dllimport) int __stdcall MessageBoxA(
    HWND_00405320 owner,
    const char* text,
    const char* caption,
    unsigned int type);
extern "C" __declspec(dllimport) int __stdcall ReleaseDC(
    HWND_00405320 window,
    HDC_00405320 dc);

extern "C" HFONT_00405320 g_optionMenuFont_004390d4_00405320 = 0;
extern "C" HFONT_00405320 g_dialogFont_004390d8_00405320 = 0;
extern "C" const char g_optionFontFaceName_004394cc_00405320[] = "MS Sans Serif";
extern "C" const char g_smallFontWarningText_00439378_00405320[] =
    "This program requires small fonts.";
extern "C" const char g_warningCaption_004394c0_00405320[] = "Warning";

#pragma optimize("s", off)
#pragma optimize("t", on)

void ApplicationOptionMenuStateSync_00405320::
    OtOptionMenuStateSync_00405320_RealCpp()
{
    LogFontA_00405320 log_font;
    TextMetricA_00405320 text_metrics;
    register ApplicationOptionMenuStateSync_00405320* state = this;
    register int font_height = 0x10;
    register int zero = 0;
    HDC_00405320 dc;

    log_font.height = 20;
    log_font.width = font_height;
    log_font.escapement = zero;
    log_font.orientation = zero;
    log_font.italic = (unsigned char)zero;
    log_font.underline = (unsigned char)zero;
    log_font.strike_out = (unsigned char)zero;
    log_font.char_set = (unsigned char)zero;
    log_font.weight = 600;
    log_font.out_precision = 6;
    log_font.clip_precision = 0x80;
    log_font.quality = 2;
    log_font.pitch_and_family = 0x20;
    strncpy(
        log_font.face_name,
        g_optionFontFaceName_004394cc_00405320,
        0x1f);

    g_optionMenuFont_004390d4_00405320 = CreateFontIndirectA(&log_font);
    log_font.height = font_height;
    log_font.width = 10;
    log_font.weight = 500;
    g_dialogFont_004390d8_00405320 = CreateFontIndirectA(&log_font);

    dc = GetDC(state->main_window);
    SelectObject(dc, g_optionMenuFont_004390d4_00405320);
    GetTextMetricsA(dc, &text_metrics);

    if (text_metrics.height != 20) {
        MessageBoxA(
            (HWND_00405320)zero,
            g_smallFontWarningText_00439378_00405320,
            g_warningCaption_004394c0_00405320,
            0x30);
    }

    ReleaseDC(state->main_window, dc);
}

#pragma optimize("", on)
