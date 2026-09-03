// Product-tree semantic recovery of the trail leaderboard insertion routine at
// 0x0042fc30.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include <stdlib.h>
#include <string.h>
#include <windows.h>

#pragma intrinsic(memset)

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

extern "C" const char g_rankedScoreNameFormat_0042fc30[] = "%-20s";
extern "C" const char g_rankedScoreValueFormat_0042fc30[] = "%10d";

#pragma optimize("s", off)
#pragma optimize("t", on)

int TrailLeaderboardList_0042fc30::OtInsertRankedScore_0042fc30_RealCpp(
    const char* name,
    int score)
{
    register TrailLeaderboardList_0042fc30* list = this;
    register char* score_text = list->entries[0].score;
    int inserted = 0;
    int index = 0;
    int old_count;

    do {
        int parsed_score = atol(score_text);
        if (score > parsed_score) {
            inserted = 1;
        } else {
            score_text += sizeof(TrailLeaderboardEntry_0042fc30);
            ++index;
        }
    } while (index < list->count && inserted == 0);

    if (list->count < 9) {
        inserted = 1;
    }

    if (inserted != 0) {
        if (list->count == 10) {
            list->OtRemoveRankedScoreAt_0042fd20_ProductDependency(
                list->count - 1);
        }

        old_count = ++list->count;
        --old_count;
        while (old_count > index) {
            list->entries[old_count] = list->entries[old_count - 1];
            --old_count;
        }

        memset(
            &list->entries[index],
            0,
            sizeof(TrailLeaderboardEntry_0042fc30));
        wsprintfA(
            list->entries[index].name,
            g_rankedScoreNameFormat_0042fc30,
            name);
        wsprintfA(
            list->entries[index].score,
            g_rankedScoreValueFormat_0042fc30,
            score);
        list->OtSaveLeaderboardProfile_0042ff00_ProductDependency();
    }

    return inserted;
}

#pragma optimize("", on)
