// Trail leaderboard profile loader recovered from Oregon32.exe.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This source must be compiled with 32-bit MSVC."
#endif

#include <string.h>

#pragma intrinsic(strcmp)

extern "C" __declspec(dllimport) unsigned long __stdcall
GetPrivateProfileStringA(
    const char* section,
    const char* key,
    const char* default_text,
    char* result,
    unsigned long result_chars,
    const char* file_name);
extern "C" char* __cdecl _itoa(int value, char* buffer, int radix);
extern "C" int __cdecl OtAtoi_RealCpp(const char* text);

extern "C" const char g_leaderboardProfileSection_0042ff00[];
extern "C" const char g_leaderboardProfileCountKey_0042ff00[];
extern "C" const char* g_leaderboardProfilePath_0042ff00;

// The original keeps a writable "legend " key template and replaces the
// trailing space with the decimal entry index for each profile read.
extern "C" char g_trailScoreEntryKeyBuffer_0042fda0[8] = "legend ";
extern "C" const char g_trailScoreMissingEntry_0042fda0[] = "error";
extern "C" const char g_trailScoreMissingCount_0042fda0[] = "no";

#pragma pack(push, 1)
struct TrailLeaderboardEntry_0042fda0 {
    char name[20];
    char score[11];
};

struct TrailGameScoreList_0042fc30 {
    int count;
    TrailLeaderboardEntry_0042fda0 entries[10];

    int OtLoadScoreList_0042fda0_RealCpp();
};

struct TrailOverlayCaptionState_0042fe90 {
    int OtFormatTrailOverlayCaption_RealCpp();
};

struct TrailLeaderboardProfileList_0042ff00 {
    void OtSaveLeaderboardProfile_0042ff00_RealCpp();
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

int TrailGameScoreList_0042fc30::OtLoadScoreList_0042fda0_RealCpp()
{
    register TrailGameScoreList_0042fc30* list = this;
    register int loaded = 1;
    char count_text[4];
    register char* entry;
    register int index;

    GetPrivateProfileStringA(
        g_leaderboardProfileSection_0042ff00,
        g_leaderboardProfileCountKey_0042ff00,
        g_trailScoreMissingCount_0042fda0,
        count_text,
        3,
        g_leaderboardProfilePath_0042ff00);

    if (strcmp(count_text, g_trailScoreMissingCount_0042fda0) == 0) {
        reinterpret_cast<TrailOverlayCaptionState_0042fe90*>(list)
            ->OtFormatTrailOverlayCaption_RealCpp();
        reinterpret_cast<TrailLeaderboardProfileList_0042ff00*>(list)
            ->OtSaveLeaderboardProfile_0042ff00_RealCpp();
        goto done;
    }

    list->count = OtAtoi_RealCpp(count_text);
    if (list->count > 10) {
        list->count = 10;
    }

    index = 0;
    if (list->count > 0) {
        entry = list->entries[0].name;
        do {
            _itoa(index, g_trailScoreEntryKeyBuffer_0042fda0 + 6, 10);
            if (GetPrivateProfileStringA(
                    g_leaderboardProfileSection_0042ff00,
                    g_trailScoreEntryKeyBuffer_0042fda0,
                    g_trailScoreMissingEntry_0042fda0,
                    entry,
                    sizeof(TrailLeaderboardEntry_0042fda0),
                    g_leaderboardProfilePath_0042ff00) == 0) {
                loaded = 0;
            }
            entry += sizeof(TrailLeaderboardEntry_0042fda0);
            ++index;
        } while (index < list->count);
    }

done:
    return loaded;
}

#pragma optimize("", on)
