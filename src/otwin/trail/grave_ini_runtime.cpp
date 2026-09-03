// Canonical product storage for the grave-record INI keys and file name.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

#pragma code_seg(".otsem")

// VC4 has no const_seg pragma. allocate() places these true const arrays in
// the already-isolated semantic section without perturbing ordinary .rdata.
extern "C" __declspec(allocate(".otsem"))
const char g_oregonIniFileName[] = "oregon.ini";
extern "C" __declspec(allocate(".otsem"))
const char g_emptyString_004395ac[] = "";
extern "C" __declspec(allocate(".otsem"))
const char g_epitaph_00439bd8[] = "Epitaph";
extern "C" __declspec(allocate(".otsem"))
const char g_graveName_00439be0[] = "GraveName";
extern "C" __declspec(allocate(".otsem"))
const char g_graveMilesToNext_00439bec[] = "GraveMilesToNext";
extern "C" __declspec(allocate(".otsem"))
const char g_graveNextLandmark_00439c00[] = "GraveNextLandmark";
extern "C" __declspec(allocate(".otsem"))
const char g_graveLastLandmark_00439c14[] = "GraveLastLandmark";
extern "C" __declspec(allocate(".otsem"))
const char g_zoneFormat_00439c28[] = "Zone %d";
extern "C" __declspec(allocate(".otsem"))
const char g_graveIntegerFormat_00439c30[] = "%d";

#pragma code_seg()

#pragma data_seg(".otdat")

extern "C" __declspec(allocate(".otdat"))
const char* PTR_s_oregon_ini_004390dc = g_oregonIniFileName;

#pragma data_seg()
