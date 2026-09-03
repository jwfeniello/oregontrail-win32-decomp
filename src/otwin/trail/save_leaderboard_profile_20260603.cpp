// Product-tree semantic closure for FUN_0042ff00_0002ff00.
//
// Saves the trail leaderboard entries to oregon.ini's "List of Legends"
// section. The local-string setup and loop shape are intentionally kept in
// the VC4-friendly order that matches the original release code.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include <string.h>

#pragma intrinsic(memcpy, memset)

struct TrailLeaderboardProfileEntry_0042ff00 {
    char name[20];
    char score[11];
};

struct TrailLeaderboardProfileList_0042ff00 {
    int count;
    TrailLeaderboardProfileEntry_0042ff00 entries[10];

    void OtSaveLeaderboardProfile_0042ff00_RealCpp();
};

struct TrailLeaderboardEntry_0042fc30 {
    char name[20];
    char score[11];
};

struct TrailLeaderboardList_0042fc30 {
    int count;
    TrailLeaderboardEntry_0042fc30 entries[10];

    int OtInsertRankedScore_0042fc30_RealCpp(
        const char* name,
        int score);
    void OtRemoveRankedScoreAt_0042fd20_ProductDependency(int index);
    void OtSaveLeaderboardProfile_0042ff00_ProductDependency();
};

extern "C" char* __cdecl _itoa(int value, char* buffer, int radix);
extern "C" __declspec(dllimport) int __stdcall WritePrivateProfileStringA(
    const char* section,
    const char* key,
    const char* value,
    const char* file_name);

extern "C" const char g_leaderboardProfileSection_0042ff00[] =
    "List of Legends";
extern "C" const char g_leaderboardProfileEntryKey_0042ff00[] =
    "legend";
extern "C" const char g_leaderboardProfileScratchText_0042ff00[] =
    "name score";
extern "C" const char g_leaderboardProfileCountKey_0042ff00[] =
    "number";
extern "C" const char* g_leaderboardProfilePath_0042ff00 = 0;

#pragma optimize("s", off)
#pragma optimize("t", on)

void TrailLeaderboardProfileList_0042ff00::OtSaveLeaderboardProfile_0042ff00_RealCpp()
{
    register TrailLeaderboardProfileList_0042ff00* list = this;
    register char* entry;
    register int index;
    char legend_key[8];
    char score_text[32];
    char section[16];

    memcpy(section, g_leaderboardProfileSection_0042ff00, sizeof(section));
    memcpy(legend_key, g_leaderboardProfileEntryKey_0042ff00, sizeof(legend_key));
    memcpy(score_text, g_leaderboardProfileScratchText_0042ff00, 31);

    _itoa(list->count, score_text, 10);
    WritePrivateProfileStringA(
        section,
        g_leaderboardProfileCountKey_0042ff00,
        score_text,
        g_leaderboardProfilePath_0042ff00);

    index = 0;
    if (list->count > index) {
        entry = list->entries[0].name;
        do {
            _itoa(index, legend_key + 6, 10);
            memset(score_text, 0, 30);
            strncpy(score_text, entry, 20);
            entry += sizeof(TrailLeaderboardProfileEntry_0042ff00);
            strncat(score_text, entry - 11, 10);
            WritePrivateProfileStringA(
                section,
                legend_key,
                score_text,
                g_leaderboardProfilePath_0042ff00);
            ++index;
        } while (index < list->count);
    }
}

void TrailLeaderboardList_0042fc30::
    OtRemoveRankedScoreAt_0042fd20_ProductDependency(int index)
{
    register TrailLeaderboardList_0042fc30* list = this;

    if (index < list->count) {
        while (index + 1 < list->count) {
            list->entries[index] = list->entries[index + 1];
            ++index;
        }

        --list->count;
        memset(
            &list->entries[list->count],
            0,
            sizeof(TrailLeaderboardEntry_0042fc30));
    }
}

#pragma optimize("", on)

#pragma code_seg(".otsem")
void TrailLeaderboardList_0042fc30::
    OtSaveLeaderboardProfile_0042ff00_ProductDependency()
{
    reinterpret_cast<TrailLeaderboardProfileList_0042ff00*>(this)->
        OtSaveLeaderboardProfile_0042ff00_RealCpp();
}
#pragma code_seg()
