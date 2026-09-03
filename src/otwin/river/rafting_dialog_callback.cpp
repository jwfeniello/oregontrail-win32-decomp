// Product-reachable semantic DLGPROC for OtRaftingDialogProc @ 0x00427340.

#include "../app/dialog_callback_runtime.h"
#include "river_trade_dialog_state.h"
#include "../graphics/raw_indexed_bitmap_runtime.h"
#include "../graphics/sprite_blitter_runtime.h"

extern "C" __declspec(dllimport) long __stdcall GetWindowLongA(
    OtDialogHandle_Product window,
    int index);
extern "C" __declspec(dllimport) long __stdcall SetWindowLongA(
    OtDialogHandle_Product window,
    int index,
    long value);
extern "C" __declspec(dllimport) OtDialogHandle_Product __stdcall GetParent(
    OtDialogHandle_Product window);
extern "C" __declspec(dllimport) OtDialogDeviceContext_Product __stdcall GetDC(
    OtDialogHandle_Product window);
extern "C" __declspec(dllimport) int __stdcall ReleaseDC(
    OtDialogHandle_Product window,
    OtDialogDeviceContext_Product dc);
extern "C" __declspec(dllimport) int __stdcall PostMessageA(
    OtDialogHandle_Product window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" __declspec(dllimport) int __stdcall IsWindowVisible(
    OtDialogHandle_Product window);
extern "C" __declspec(dllimport) int __stdcall IsIconic(
    OtDialogHandle_Product window);
extern "C" __declspec(dllimport) unsigned long __stdcall timeGetTime();
extern "C" __declspec(dllimport) unsigned int __stdcall timeEndPeriod(
    unsigned int period);
extern "C" __declspec(dllimport) unsigned int __stdcall GetPaletteEntries(
    void* palette,
    unsigned int first_entry,
    unsigned int entry_count,
    void* entries);
extern "C" __declspec(dllimport) int __stdcall AnimatePalette(
    void* palette,
    unsigned int first_entry,
    unsigned int entry_count,
    const void* entries);
extern "C" __declspec(dllimport) int __stdcall PeekMessageA(
    void* message,
    OtDialogHandle_Product window,
    unsigned int first_message,
    unsigned int last_message,
    unsigned int remove_message);
extern "C" __declspec(dllimport) int __stdcall TranslateAcceleratorA(
    OtDialogHandle_Product window,
    void* accelerator,
    void* message);
extern "C" __declspec(dllimport) int __stdcall IsDialogMessageA(
    OtDialogHandle_Product dialog,
    void* message);
extern "C" __declspec(dllimport) int __stdcall TranslateMessage(
    const void* message);
extern "C" __declspec(dllimport) long __stdcall DispatchMessageA(
    const void* message);
extern "C" __declspec(dllimport) int __stdcall sndPlaySoundA(
    const char* sound,
    unsigned int flags);

#pragma comment(lib, "winmm.lib")

struct RaftingJourneyState_004270b0;

extern "C" int g_cdMediaMode_00439108;
extern "C" int DAT_004390e8;
extern "C" unsigned int g_wavePlaybackActive_0040d110;
extern "C" void* g_mainAccelerator_00402ed0;
extern "C" RaftingJourneyState_004270b0* g_journeyState;

extern "C" void __cdecl
OtTradeOfferListCursor_000277b0_20260604_SetupDialog(
    OtDialogHandle_Product dialog);
extern "C" void __cdecl OtRiver_DrawTradeBitmap_RealCpp(
    OtDialogHandle_Product dialog,
    void* state);
extern "C" int __cdecl OtSelectDialogCursor_0040d530_RealCpp(
    int busy,
    OtDialogHandle_Product window);
extern "C" void __cdecl OtOpenWaveAudioFile_0000d110_RealCpp(
    OtDialogHandle_Product owner,
    const char* path);
extern "C" void __cdecl OtPlayWaveAudioDirectImport_0040d3e0_RealCpp();
extern "C" void __cdecl OtCloseWaveAudioDevice_0040d0a0_RealCpp();
extern "C" short __fastcall OtCountLivingPartyMembers_RealCpp(
    const void* party);
extern "C" int __cdecl OtRunSharedMessageDialog_00401e70_RealCpp(
    OtDialogHandle_Product parent,
    void* message_text,
    void* caption_text,
    int use_alternate_template);
extern "C" char* __cdecl
OtWelcomePartyNameCommit_20260605_Wip();

#pragma pack(push, 1)
struct RaftingState_00426740 {
    void OtRiver_RenderRaftSpriteRow_00426740_RealCpp(
        void* dc,
        int slot);
};

struct RaftAnimationState_00426ad0 {
    void OtRiver_TickRaftAnimation_00426ad0_RealCpp(void* dc);
};

struct RaftingState_00426b70 {
    void OtRiver_BeginRaftSession_00426b70_RealCpp();
};

struct RaftingObstacleAdvanceState_00426880 {
    int OtRaftingObstacleAdvance_00426880_RealCpp(void* dc);
};

struct RaftingDialogState_00426680 {
    void OtDestroyRaftingDialogState_00426680_RealCpp();
};

struct RaftingJourneyState_004270b0 {
    char reserved_000[0x116];
    short member_state[5];
};

struct RaftPaletteEntry_Product {
    unsigned char red;
    unsigned char green;
    unsigned char blue;
    unsigned char flags;
};

struct RaftMessage_Product {
    OtDialogHandle_Product window;
    unsigned int message;
    unsigned int wparam;
    long lparam;
    unsigned long time;
    OtDialogPoint_Product point;
};
#pragma pack(pop)

typedef char OtRaftMessageSizeMustBe1c[
    sizeof(RaftMessage_Product) == 0x1c ? 1 : -1];

static const char g_raftingWaterRushWave_00427340[] = "wtrrush.wav";
static char g_raftingEndText_00427340[] =
    "You made it down the river!";
static char g_raftingEndCaption_00427340[] = "Rafting End";
static char g_raftingRockCaption_004270b0[] =
    "You hit a rock!";

static void OtPaintRaftingDialog_Product_00427340(
    OtDialogHandle_Product dialog,
    RiverTradeDialogState_004277b0_20260604* state)
{
    int slot;

    if (state == 0) {
        return;
    }
    if (state->dc != 0) {
        ReleaseDC(dialog, state->dc);
    }
    OtRiver_DrawTradeBitmap_RealCpp(dialog, state);
    state->dc = GetDC(dialog);
    OtSelectDialogPalette_Product(state->dc);
    for (slot = 0; slot < 4; ++slot) {
        reinterpret_cast<RaftingState_00426740*>(state)->
            OtRiver_RenderRaftSpriteRow_00426740_RealCpp(state->dc, slot);
    }

    state->summary_sprite->OtExtractSpriteRegionToBuffer_Product_00410840(
        state->raw_background,
        reinterpret_cast<unsigned char*>(state->scratch_bits));
    state->summary_sprite->OtCompositeSpriteIntoBuffer_Product_00410a30(
        state->summary_sprite,
        reinterpret_cast<unsigned char*>(state->scratch_bits),
        state->raw_background);
    state->summary_sprite->OtBlitSpriteBuffer_Product_004106e0(
        state->dc,
        state->raw_background,
        state->scratch_bits);
}

static int OtRaftSpritesOverlap_Product_00427340(
    const SpriteBlitter_00410660_Product* raft,
    const SpriteBlitter_00410660_Product* obstacle)
{
    int raft_right = raft->requested_x + raft->source_width - 1;
    int raft_bottom = raft->requested_y + raft->source_height - 1;
    int obstacle_right =
        obstacle->requested_x + obstacle->source_width - 1;
    int obstacle_bottom =
        obstacle->requested_y + obstacle->source_height - 1;

    return raft->requested_x <= obstacle_right - 10 &&
           raft_right >= obstacle->requested_x + 10 &&
           raft->requested_y <= obstacle_bottom - 10 &&
           raft_bottom >= obstacle->requested_y + 10;
}

static int OtResolveRaftObstacleCollision_Product_00426ed0(
    RiverTradeDialogState_004277b0_20260604* state,
    void* dc)
{
    SpriteBlitter_00410660_Product* raft = state->loss_sprites[0];
    int result = 0;
    int slot;

    for (slot = 1; slot < 4; ++slot) {
        SpriteBlitter_00410660_Product* obstacle =
            state->loss_sprites[slot];
        if (obstacle->active_state != 0 &&
            OtRaftSpritesOverlap_Product_00427340(raft, obstacle)) {
            int raft_center =
                raft->requested_x + (raft->source_width >> 1);
            int obstacle_center =
                obstacle->requested_x + (obstacle->source_width >> 1);
            raft->source_frame =
                raft_center < obstacle_center ? 3 : 5;
            reinterpret_cast<RaftingState_00426740*>(state)->
                OtRiver_RenderRaftSpriteRow_00426740_RealCpp(dc, 0);
            result = slot;
            if (DAT_004390e8 != 0) {
                if (g_cdMediaMode_00439108 != 0) {
                    OtCloseWaveAudioDevice_0040d0a0_RealCpp();
                }
                sndPlaySoundA(0, 0);
                sndPlaySoundA(
                    reinterpret_cast<const char*>(state->resource_c22_bits),
                    5);
            }
        }
    }
    return result;
}

void RiverTradeDialogState_004277b0_20260604::
    OtMoveRaftTowardPointer_Product_004267b0(
        void* dc,
        int target_x)
{
    SpriteBlitter_00410660_Product* raft = loss_sprites[0];
    unsigned long now = timeGetTime();

    if (now - *reinterpret_cast<unsigned long*>(raft) <
        static_cast<unsigned long>(raft->resource_handle_or_state)) {
        return;
    }
    *reinterpret_cast<unsigned long*>(raft) = now;
    if (target_x < raft->requested_x && raft->requested_x > 0x14) {
        raft->requested_x = static_cast<short>(raft->requested_x - 5);
        raft->source_frame = 2;
    } else if (target_x > raft->requested_x + raft->source_width &&
               raft->requested_x + raft->source_width < 0x1a4) {
        raft->requested_x = static_cast<short>(raft->requested_x + 5);
        raft->source_frame = 0;
    } else {
        raft->source_frame = 1;
    }
    field_50 =
        OtResolveRaftObstacleCollision_Product_00426ed0(this, dc);
    reinterpret_cast<RaftingState_00426740*>(this)->
        OtRiver_RenderRaftSpriteRow_00426740_RealCpp(dc, 0);
}

void RiverTradeDialogState_004277b0_20260604::
    OtAdvanceRaftObstacles_Product_00426c20(void* dc)
{
    RiverTradeDialogState_004277b0_20260604* state = this;
    static const short top_x[12] = {
        0x0af, 0x0c8, 0x0e1, 0x0f0, 0x0fa, 0x0ff,
        0x109, 0x10e, 0x118, 0x122, 0x136, 0x154
    };
    static const short bottom_x[12] = {
        0x037, 0x055, 0x073, 0x091, 0x0af, 0x0f0,
        0x118, 0x127, 0x145, 0x163, 0x181, 0x19f
    };
    unsigned long now = timeGetTime();
    int slot;

    for (slot = 1; slot < 4; ++slot) {
        SpriteBlitter_00410660_Product* obstacle = state->loss_sprites[slot];
        int course;
        int travel;

        if (obstacle->active_state == 0 ||
            now - *reinterpret_cast<unsigned long*>(obstacle) <=
                static_cast<unsigned long>(
                    obstacle->resource_handle_or_state)) {
            continue;
        }
        *reinterpret_cast<unsigned long*>(obstacle) = now;
        if (obstacle->requested_y < 0x46) {
            obstacle->requested_y =
                static_cast<short>(obstacle->requested_y + 3);
            obstacle->source_frame = 6;
        } else if (obstacle->requested_y < 0x6e) {
            obstacle->requested_y =
                static_cast<short>(obstacle->requested_y + 5);
            obstacle->source_frame = 4;
        } else {
            obstacle->requested_y =
                static_cast<short>(obstacle->requested_y + 7);
            obstacle->source_frame = obstacle->requested_y < 0x91 ? 2 : 0;
        }

        course = obstacle->previous_x;
        if (course < 0 || course > 11) {
            course = 0;
        }
        travel = obstacle->requested_y - 10;
        obstacle->requested_x = static_cast<short>(
            top_x[course] +
            ((bottom_x[course] - top_x[course]) * travel) / 0x10a);
        if (obstacle->requested_x + obstacle->source_width > 0x1ae) {
            obstacle->requested_x =
                static_cast<short>(0x1ae - obstacle->source_width);
        }

        if (obstacle->requested_y < 0x114) {
            state->field_50 =
                OtResolveRaftObstacleCollision_Product_00426ed0(
                    state,
                    dc);
        }
        reinterpret_cast<RaftingState_00426740*>(state)->
            OtRiver_RenderRaftSpriteRow_00426740_RealCpp(dc, slot);
        if (obstacle->requested_y >= 0x114) {
            obstacle->active_state = 0;
        }
    }
}

#pragma optimize("s", off)
#pragma optimize("t", on)
#pragma optimize("y", on)

int RiverTradeDialogState_004277b0_20260604::
    OtRunRaftingRoundLoop_Product_004270b0(void* dialog)
{
    int result = 1;
    register int collision_handled = 0;
    RaftMessage_Product message;
    RaftPaletteEntry_Product entries[8];

    GetPaletteEntries(g_gamePalette, 0x71, 8, entries);
    reserved_30 = 0;
    if (g_cdMediaMode_00439108 != 0 && DAT_004390e8 != 0) {
        OtOpenWaveAudioFile_0000d110_RealCpp(
            dialog,
            g_raftingWaterRushWave_00427340);
        OtPlayWaveAudioDirectImport_0040d3e0_RealCpp();
    }

    while (sound_started == 0) {
        if (PeekMessageA(&message, 0, 0, 0, 0) != 0) {
            if (message.message == 0x12) {
                sound_started = 1;
                result = 0;
            } else {
                PeekMessageA(&message, 0, 0, 0, 1);
                if (TranslateAcceleratorA(
                        message.window,
                        g_mainAccelerator_00402ed0,
                        &message) == 0 &&
                    IsDialogMessageA(dialog, &message) == 0) {
                    TranslateMessage(&message);
                    DispatchMessageA(&message);
                }
            }
        } else if (audio_mode == 1) {
            unsigned long now = timeGetTime();
            if (now - static_cast<unsigned long>(reserved_30) > 0x78) {
                reserved_30 = static_cast<int>(now);
                RaftPaletteEntry_Product first = entries[0];
                int index;
                for (index = 0; index < 7; ++index) {
                    entries[index] = entries[index + 1];
                }
                entries[7] = first;
                AnimatePalette(g_gamePalette, 0x71, 8, entries);
            }
            if (field_50 == 0) {
                OtMoveRaftTowardPointer_Product_004267b0(
                    dc,
                    mouse_x - 0x30);
                reinterpret_cast<RaftAnimationState_00426ad0*>(this)->
                    OtRiver_TickRaftAnimation_00426ad0_RealCpp(dc);
                sound_started =
                    reinterpret_cast<RaftingObstacleAdvanceState_00426880*>(
                        this)->OtRaftingObstacleAdvance_00426880_RealCpp(dc);
                reinterpret_cast<RaftingState_00426b70*>(this)->
                    OtRiver_BeginRaftSession_00426b70_RealCpp();
                OtAdvanceRaftObstacles_Product_00426c20(dc);
                collision_handled = 0;
            } else if (!collision_handled) {
                collision_handled = 1;
                char* collision_message =
                    OtWelcomePartyNameCommit_20260605_Wip();
                OtRunSharedMessageDialog_00401e70_RealCpp(
                    dialog,
                    collision_message,
                    g_raftingRockCaption_004270b0,
                    0);
                sndPlaySoundA(0, 0);
                if (g_journeyState->member_state[0] != 0x0f) {
                    if (g_cdMediaMode_00439108 != 0 &&
                        DAT_004390e8 != 0) {
                        OtOpenWaveAudioFile_0000d110_RealCpp(
                            dialog,
                            g_raftingWaterRushWave_00427340);
                        OtPlayWaveAudioDirectImport_0040d3e0_RealCpp();
                    }
                    loss_sprites[0]->source_frame = 1;
                    loss_sprites[field_50]->active_state = 0;
                    loss_sprites[field_50]->
                        OtExtractSpriteRegionToBuffer_Product_00410840(
                            raw_background,
                            reinterpret_cast<unsigned char*>(scratch_bits));
                    loss_sprites[0]->
                        OtCompositeSpriteIntoBuffer_Product_00410a30(
                            loss_sprites[field_50],
                            reinterpret_cast<unsigned char*>(scratch_bits),
                            raw_background);
                    loss_sprites[field_50]->
                        OtBlitSpriteBuffer_Product_004106e0(
                            dc,
                            raw_background,
                            scratch_bits);
                    field_4c = static_cast<int>(timeGetTime());
                } else {
                    sound_started = 1;
                }
                field_50 = 0;
            }
        }
    }

    sndPlaySoundA(0, 9);
    if (g_cdMediaMode_00439108 != 0) {
        OtCloseWaveAudioDevice_0040d0a0_RealCpp();
    }
    return result;
}

#pragma optimize("", on)

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" int __stdcall OtRaftingDialogProc_00027340_Wip(
    OtDialogHandle_Product dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam)
{
    RiverTradeDialogState_004277b0_20260604* state =
        reinterpret_cast<RiverTradeDialogState_004277b0_20260604*>(
            GetWindowLongA(dialog, 8));

    switch (message) {
    case 0x0002:
        if (state != 0) {
            if (state->dc != 0) {
                ReleaseDC(dialog, state->dc);
                state->dc = 0;
            }
            reinterpret_cast<RaftingDialogState_00426680*>(state)->
                OtDestroyRaftingDialogState_00426680_RealCpp();
            operator delete(state);
            SetWindowLongA(dialog, 8, 0);
        }
        timeEndPeriod(15);
        g_activeScreenDialogWindow_00404dd0 = 0;
        return 1;

    case 0x000f:
        OtSetDialogBusyCursor_Product();
        OtPaintRaftingDialog_Product_00427340(dialog, state);
        OtRestoreDialogArrowCursor_Product();
        return 1;

    case 0x0014:
        OtSelectDialogPalette_Product(
            reinterpret_cast<OtDialogDeviceContext_Product>(wparam));
        {
            OtDialogRect_Product rect;
            GetClientRect(dialog, &rect);
            FillRect(
                reinterpret_cast<OtDialogDeviceContext_Product>(wparam),
                &rect,
                g_sharedDialogBackgroundBrush_004390c0);
        }
        return 1;

    case 0x0020:
        return OtSelectDialogCursor_0040d530_RealCpp(
            g_appBusyCursorActive_Product_004034d0,
            reinterpret_cast<OtDialogHandle_Product>(wparam));

    case 0x0110:
        OtSetDialogBusyCursor_Product();
        g_activeScreenDialogWindow_00404dd0 = dialog;
        OtTradeOfferListCursor_000277b0_20260604_SetupDialog(dialog);
        return 0;

    case 0x0200:
        if (state != 0) {
            state->mouse_x = static_cast<unsigned short>(lparam & 0xffff);
        }
        return 0;

    case 0x03b9:
        if (g_cdMediaMode_00439108 != 0 && DAT_004390e8 != 0) {
            OtPlayWaveAudioDirectImport_0040d3e0_RealCpp();
        }
        return 1;

    case 0x0464:
    case 0x0465:
        if (state != 0) {
            state->audio_mode = 0;
        }
        if (g_cdMediaMode_00439108 != 0) {
            OtCloseWaveAudioDevice_0040d0a0_RealCpp();
        }
        sndPlaySoundA(0, 0);
        return 1;

    case 0x0466:
    case 0x0467:
        if (state != 0) {
            state->audio_mode = 1;
        }
        if (IsWindowVisible(dialog) != 0 &&
            IsIconic(GetParent(dialog)) == 0 &&
            g_cdMediaMode_00439108 != 0 &&
            DAT_004390e8 != 0 &&
            g_wavePlaybackActive_0040d110 == 0) {
            OtOpenWaveAudioFile_0000d110_RealCpp(
                dialog,
                g_raftingWaterRushWave_00427340);
            OtPlayWaveAudioDirectImport_0040d3e0_RealCpp();
        }
        return 1;

    case 0x0475:
        if (state != 0 &&
            state->OtRunRaftingRoundLoop_Product_004270b0(dialog) != 0) {
            if (OtCountLivingPartyMembers_RealCpp(g_journeyState) > 0) {
                OtRunSharedMessageDialog_00401e70_RealCpp(
                    dialog,
                    g_raftingEndText_00427340,
                    g_raftingEndCaption_00427340,
                    0);
            }
            PostMessageA(GetParent(dialog), 0x0476, 0, 0);
        }
        return 1;
    }

    return 0;
}

#pragma optimize("", on)
