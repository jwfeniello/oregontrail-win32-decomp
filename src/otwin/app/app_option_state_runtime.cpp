// Canonical Product storage for the application/media option state loaded by
// the startup option flow and consumed across the UI, audio, hunt, and trail
// subsystems.  These are the original contiguous DAT_004390e0..f4 option
// slots plus DAT_00439108's installed-media mode.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

extern "C" int DAT_004390e0 = 0;
extern "C" int DAT_004390e4 = 0;
extern "C" int DAT_004390e8 = 0;
extern "C" int g_titleThemeEnabled_004390ec = 0;
extern "C" int g_trailLeaderboardEnabled_004390f0 = 0;
extern "C" int g_graveSitesEnabled_004390f4 = 0;
extern "C" int g_cdMediaMode_00439108 = 0;
