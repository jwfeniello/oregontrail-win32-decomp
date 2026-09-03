// Product-tree semantic closure for OtPopulateTitleLeaderboard @ 0x0041c210.
//
// The measured dialog-population routine comes first and retains the VC4
// source shape of the original.  Its profile-loading dependency follows it in
// the same semantic code segment and performs real oregon.ini reads.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include <string.h>

#pragma intrinsic(memset)

typedef void* HWND_0041c210_Product;
typedef void* HMODULE_0041c210_Product;

extern "C" __declspec(dllimport) int __cdecl wsprintfA(
    char* buffer,
    const char* format,
    ...);
extern "C" __declspec(dllimport) HWND_0041c210_Product __stdcall GetDlgItem(
    HWND_0041c210_Product dialog,
    int control_id);
extern "C" __declspec(dllimport) int __stdcall SetWindowTextA(
    HWND_0041c210_Product window,
    const char* text);
extern "C" __declspec(dllimport) int __stdcall LoadStringA(
    HMODULE_0041c210_Product instance,
    unsigned int string_id,
    char* buffer,
    int max_chars);
extern "C" __declspec(dllimport) unsigned long __stdcall
GetPrivateProfileStringA(
    const char* section,
    const char* key,
    const char* default_text,
    char* result,
    unsigned long result_chars,
    const char* file_name);

extern "C" char* __cdecl strncat(
    char* destination,
    const char* source,
    unsigned int count);
extern "C" long __cdecl atol(const char* text);
extern "C" char* __cdecl _itoa(int value, char* buffer, int radix);

extern "C" void* g_resourceModule;
extern "C" const char g_leaderboardProfileSection_0042ff00[];
extern "C" const char g_leaderboardProfileEntryKey_0042ff00[];
extern "C" const char g_leaderboardProfileCountKey_0042ff00[];
extern "C" const char* g_leaderboardProfilePath_0042ff00;

extern "C" const char g_titleLeaderboardRankFormat_0041c210_Product[] =
    "%2d. ";
extern "C" const char g_titleLeaderboardEmptyText_0041c210_Product[1] = {0};

struct TitleLeaderboardScratch_0041c210_Product {
    char rank_prefix[12];
    char text[88];
};

struct TrailGameListEntry_0041c210 {
    char primary[20];
    char secondary[11];
};

struct TrailGameScoreList_0042fc30 {
    int count;
    TrailGameListEntry_0041c210 entries[10];

    int OtLoadScoreList_0041c210_Product();
};

struct TitleDialogState_0041c210_Product {
    char reserved_000[0xf0];
    TrailGameScoreList_0042fc30 score_list;
};

#pragma code_seg(".otsem")
#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" int __cdecl OtPopulateTitleLeaderboard_0041c210_Product(
    HWND_0041c210_Product dialog,
    TitleDialogState_0041c210_Product* state)
{
    TrailGameScoreList_0042fc30* score_list;
    TitleLeaderboardScratch_0041c210_Product scratch;

    score_list = &state->score_list;
    score_list->OtLoadScoreList_0041c210_Product();

    {
        register const char* primary_text;
        register int row;

        row = 0;
        if (score_list->count > row) {
            register HWND_0041c210_Product owner = dialog;
            primary_text = ((const char*)state) + 0xf4;
            do {
                int rank_number;

                memset(&scratch, 0, sizeof(scratch));
                row += 0x3fc;
                rank_number = row - 0x3fb;
                wsprintfA(
                    scratch.rank_prefix,
                    g_titleLeaderboardRankFormat_0041c210_Product,
                    rank_number);
                strncat(scratch.rank_prefix, primary_text, 20);
                SetWindowTextA(
                    GetDlgItem(owner, row),
                    scratch.rank_prefix);

                row = rank_number;
                primary_text += sizeof(TrailGameListEntry_0041c210);
            } while (score_list->count > row);
        }
    }

    {
        register HWND_0041c210_Product owner = dialog;
        register int row = score_list->count;
        while (row < 10) {
            SetWindowTextA(
                GetDlgItem(owner, row + 0x3fc),
                g_titleLeaderboardEmptyText_0041c210_Product);
            ++row;
        }
    }

    {
        register const char* secondary_text;
        register int row;

        row = 0;
        if (score_list->count > row) {
            secondary_text = ((const char*)state) + 0x108;
            do {
                memset(&scratch, 0, sizeof(scratch));
                if (atol(secondary_text) > 5999) {
                    LoadStringA(
                        (HMODULE_0041c210_Product)g_resourceModule,
                        0x20a,
                        scratch.rank_prefix,
                        100);
                } else if (atol(secondary_text) > 3999) {
                    LoadStringA(
                        (HMODULE_0041c210_Product)g_resourceModule,
                        0x209,
                        scratch.rank_prefix,
                        100);
                } else {
                    LoadStringA(
                        (HMODULE_0041c210_Product)g_resourceModule,
                        0x208,
                        scratch.rank_prefix,
                        100);
                }

                SetWindowTextA(
                    GetDlgItem(dialog, row + 0x406),
                    scratch.rank_prefix);
                secondary_text += sizeof(TrailGameListEntry_0041c210);
                ++row;
            } while (score_list->count > row);
        }
    }

    {
        register HWND_0041c210_Product owner = dialog;
        register int row = score_list->count;
        while (row < 10) {
            SetWindowTextA(
                GetDlgItem(owner, row + 0x406),
                g_titleLeaderboardEmptyText_0041c210_Product);
            ++row;
        }
    }

    {
        register const char* secondary_text;
        register int row = 0;
        if (score_list->count > row) {
            register HWND_0041c210_Product owner = dialog;
            secondary_text = ((const char*)state) + 0x108;
            do {
                SetWindowTextA(
                    GetDlgItem(owner, row + 0x410),
                    secondary_text);
                secondary_text += sizeof(TrailGameListEntry_0041c210);
                ++row;
            } while (score_list->count > row);
        }
    }

    {
        register HWND_0041c210_Product owner = dialog;
        register int row = score_list->count;
        while (row < 10) {
            SetWindowTextA(
                GetDlgItem(owner, row + 0x410),
                g_titleLeaderboardEmptyText_0041c210_Product);
            ++row;
        }
    }

    return *(int*)scratch.rank_prefix;
}

int TrailGameScoreList_0042fc30::OtLoadScoreList_0041c210_Product()
{
    char count_text[12];
    char legend_key[8];
    int requested_count;
    int index;

    count = 0;
    memset(entries, 0, sizeof(entries));

    if (g_leaderboardProfilePath_0042ff00 == 0 ||
        g_leaderboardProfilePath_0042ff00[0] == 0) {
        return 0;
    }

    memset(count_text, 0, sizeof(count_text));
    if (GetPrivateProfileStringA(
            g_leaderboardProfileSection_0042ff00,
            g_leaderboardProfileCountKey_0042ff00,
            g_titleLeaderboardEmptyText_0041c210_Product,
            count_text,
            sizeof(count_text),
            g_leaderboardProfilePath_0042ff00) == 0) {
        return 0;
    }

    requested_count = (int)atol(count_text);
    if (requested_count < 0) {
        requested_count = 0;
    } else if (requested_count > 10) {
        requested_count = 10;
    }

    memcpy(
        legend_key,
        g_leaderboardProfileEntryKey_0042ff00,
        sizeof(legend_key) - 1);
    legend_key[sizeof(legend_key) - 1] = 0;

    index = 0;
    while (index < requested_count) {
        _itoa(index, legend_key + 6, 10);
        if (GetPrivateProfileStringA(
                g_leaderboardProfileSection_0042ff00,
                legend_key,
                g_titleLeaderboardEmptyText_0041c210_Product,
                entries[index].primary,
                sizeof(TrailGameListEntry_0041c210),
                g_leaderboardProfilePath_0042ff00) == 0) {
            count = 0;
            memset(entries, 0, sizeof(entries));
            return 0;
        }

        ++count;
        ++index;
    }

    return 1;
}

#pragma optimize("", on)
#pragma code_seg()
