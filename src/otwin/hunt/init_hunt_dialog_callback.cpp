// Product-reachable semantic DLGPROC for OtInitHuntDialogProc @ 0x00414d00.

#include "../app/dialog_callback_runtime.h"
#include "hunt_runtime_state.h"
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
extern "C" __declspec(dllimport) long __stdcall DefWindowProcA(
    OtDialogHandle_Product window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" __declspec(dllimport) int __stdcall ScreenToClient(
    OtDialogHandle_Product window,
    OtDialogPoint_Product* point);
extern "C" __declspec(dllimport) int __stdcall PostMessageA(
    OtDialogHandle_Product window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" __declspec(dllimport) long __stdcall SendMessageA(
    OtDialogHandle_Product window,
    unsigned int message,
    unsigned int wparam,
    long lparam);
extern "C" __declspec(dllimport) unsigned int __stdcall timeEndPeriod(
    unsigned int period);
extern "C" __declspec(dllimport) unsigned long __stdcall timeGetTime();
extern "C" __declspec(dllimport) int __stdcall sndPlaySoundA(
    const char* sound,
    unsigned int flags);

#pragma comment(lib, "winmm.lib")

extern "C" void* g_resourceModule;
extern "C" int DAT_004390e8;

extern "C" void __cdecl OtSetupInitHuntDialog_00015380_RealCpp(
    OtDialogHandle_Product dialog);
extern "C" void __fastcall OtFreeRawIndexedBitmap_RealCpp(void* bitmap);

#pragma pack(push, 1)
struct HuntState_00412dd0 {
    char reserved_000[0x17c];
    HuntSprite_004122b0_Product* sprite_slots[20];

    int OtAllocateOrderedHuntSpriteSlot_00412dd0_RealCpp(
        int draw_order_key);
};
#pragma pack(pop)

static void OtReplaceHuntBackground_Product_004155b0(
    OtDialogHandle_Product dialog,
    HuntRuntimeState_004122b0_Product* state)
{
    OtDialogPaintStruct_Product paint;
    OtDialogDeviceContext_Product dc = BeginPaint(dialog, &paint);
    RawIndexedBitmap_00410490_Product* background;

    OtSelectDialogPalette_Product(dc);
    if (state->frame_buffer != 0) {
        OtFreeRawIndexedBitmap_RealCpp(state->frame_buffer);
        operator delete(state->frame_buffer);
        state->frame_buffer = 0;
    }

    background = new RawIndexedBitmap_00410490_Product(
        g_resourceModule,
        0x0244,
        0x0132,
        reinterpret_cast<const void*>(
            state->OtCurrentHuntSceneResourceId_00413030()));
    state->frame_buffer =
        reinterpret_cast<HuntRawIndexedBitmap_004122b0_Product*>(background);
    if (background != 0) {
        background->OtBlitRawIndexedBitmap_Product_004105a0(dc, 0x14, 0x1e);
    }
    state->active_round = 1;
    EndPaint(dialog, &paint);
}

static void OtPaintHuntDialog_Product_00414d00(
    OtDialogHandle_Product dialog,
    HuntRuntimeState_004122b0_Product* state)
{
    int slot;

    if (state == 0) {
        return;
    }
    if (state->render_context != 0) {
        ReleaseDC(dialog, state->render_context);
    }
    OtReplaceHuntBackground_Product_004155b0(dialog, state);
    state->render_context = GetDC(dialog);
    OtSelectDialogPalette_Product(state->render_context);
    for (slot = 0; slot < 20; ++slot) {
        state->OtRedrawHuntSpriteSlot_Product(state->render_context, slot);
    }
}

static void OtCycleHuntScene_Product_00414d00(
    HuntRuntimeState_004122b0_Product* state)
{
    int slot;
    RawIndexedBitmap_00410490_Product* background;

    ++state->scene_variant_offset;
    if (state->scene_variant_offset > 2) {
        state->scene_variant_offset = 0;
    }

    if (state->frame_buffer != 0) {
        OtFreeRawIndexedBitmap_RealCpp(state->frame_buffer);
        operator delete(state->frame_buffer);
    }
    background = new RawIndexedBitmap_00410490_Product(
        g_resourceModule,
        0x0244,
        0x0132,
        reinterpret_cast<const void*>(
            state->OtCurrentHuntSceneResourceId_00413030()));
    state->frame_buffer =
        reinterpret_cast<HuntRawIndexedBitmap_004122b0_Product*>(background);
    if (background != 0 && state->render_context != 0) {
        background->OtBlitRawIndexedBitmap_Product_004105a0(
            state->render_context,
            0x14,
            0x1e);
    }
    for (slot = 0; slot < 20; ++slot) {
        state->sprite_slots[slot]->state = 0;
    }
    state->last_shot_tick = 0;
}

static void OtHandleHuntShot_Product_00414620(
    HuntRuntimeState_004122b0_Product* state)
{
    int x = state->shot_x - 0x14;
    int y = state->shot_y - 0x1e;
    int slot;
    int scan;
    short trajectory = 0;
    HuntSprite_004122b0_Product* projectile;

    state->shot_x = x;
    state->shot_y = y;
    if (x <= 0 || x >= 0x244 || y <= 0 || y >= 0x122) {
        return;
    }
    if (state->bullets_available == 0) {
        if (DAT_004390e8 != 0) {
            sndPlaySoundA(0, 0);
            sndPlaySoundA(state->sound_data[1], 5);
        }
        return;
    }

    for (scan = 0; scan < 19; ++scan) {
        if (state->sprite_slots[scan]->state == 0) {
            break;
        }
        if (state->sprite_slots[scan]->state == 99) {
            return;
        }
    }

    slot = reinterpret_cast<HuntState_00412dd0*>(state)->
        OtAllocateOrderedHuntSpriteSlot_00412dd0_RealCpp(0);
    if (slot == -1) {
        return;
    }

    projectile = state->sprite_slots[slot];
    projectile->draw_order_key = 0;
    projectile->state = 99;
    projectile->source_pixels =
        reinterpret_cast<unsigned char*>(state->projectile_pixels);
    projectile->width = 5;
    projectile->height = 5;
    projectile->source_columns_per_row = 1;
    projectile->animation_frame = 0;
    projectile->transparent_index = 0x00e1;
    projectile->tick_interval = 0x0b;
    projectile->target_type = 99;
    projectile->y = 0x0122;
    projectile->x = 0x0121;

    x -= 0x0121;
    y -= 0x0122;
    if (x < -2 || x > 2) {
        if (x < 1) {
            trajectory = y <= x ? 2 : 1;
        } else {
            trajectory = x <= -y ? 3 : 4;
        }
    }
    projectile->trajectory_mode = trajectory;
    if (trajectory != 0) {
        state->projectile_slope = (y * 1000) / x;
        state->projectile_intercept =
            state->shot_y + (state->shot_x * state->projectile_slope) / -1000;
    }
    reinterpret_cast<SpriteBlitter_00410660_Product*>(projectile)->
        OtResetSpriteBlitterBitmapInfo_Product_004107b0();

    for (scan = 0; scan < 19; ++scan) {
        HuntSprite_004122b0_Product* target = state->sprite_slots[scan];
        if (target->state == 0) {
            break;
        }
        if (target->state == 4 || target->state == 6) {
            target->state = 1;
            target->trajectory_mode = 0;
            if (static_cast<int>(target->x + (target->width >> 1)) < 0x122) {
                target->trajectory_mode = 1;
            }
        }
    }
    if (DAT_004390e8 != 0) {
        sndPlaySoundA(0, 0);
        sndPlaySoundA(state->sound_data[0], 5);
    }
    --state->bullets_available;
    ++state->bullets_fired;
    state->last_shot_tick = timeGetTime();
}

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" int __stdcall OtInitHuntDialogProc_00014d00_Wip(
    OtDialogHandle_Product dialog,
    unsigned int message,
    unsigned int wparam,
    long lparam)
{
    HuntRuntimeState_004122b0_Product* state =
        reinterpret_cast<HuntRuntimeState_004122b0_Product*>(
            GetWindowLongA(dialog, 8));

    switch (message) {
    case 0x0002:
        timeEndPeriod(15);
        if (state != 0) {
            if (state->render_context != 0) {
                ReleaseDC(dialog, state->render_context);
                state->render_context = 0;
            }
            delete state;
            SetWindowLongA(dialog, 8, 0);
        }
        g_activeScreenDialogWindow_00404dd0 = 0;
        return 0;

    case 0x000f:
        OtSetDialogBusyCursor_Product();
        OtPaintHuntDialog_Product_00414d00(dialog, state);
        OtRestoreDialogArrowCursor_Product();
        return 0;

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
        if (state != 0 && state->cursor_state == 0x20) {
            SetCursor(state->hunt_cursor);
            return 1;
        }
        if (state != 0 && state->cursor_state == 0x40) {
            SetCursor(state->default_cursor);
            return 1;
        }
        return static_cast<int>(DefWindowProcA(dialog, message, wparam, lparam));

    case 0x002b:
        if (state == 0) {
            return 0;
        }
        if ((wparam & 0xffff) == 0x0900) {
            return OtDrawOwnedBitmapButton_Product(
                reinterpret_cast<OtDialogDrawItem_Product*>(lparam),
                reinterpret_cast<PositionedBitmapDescriptorState_0040ba40*>(
                    &state->bitmap_0bc),
                reinterpret_cast<PositionedBitmapDescriptorState_0040ba40*>(
                    &state->bitmap_0e4));
        }
        if ((wparam & 0xffff) == 0x0901) {
            return OtDrawOwnedBitmapButton_Product(
                reinterpret_cast<OtDialogDrawItem_Product*>(lparam),
                reinterpret_cast<PositionedBitmapDescriptorState_0040ba40*>(
                    &state->bitmap_10c),
                reinterpret_cast<PositionedBitmapDescriptorState_0040ba40*>(
                    &state->bitmap_134));
        }
        return 1;

    case 0x0084:
        if (DefWindowProcA(dialog, message, wparam, lparam) == 1 && state != 0) {
            OtDialogPoint_Product point;
            point.x = static_cast<short>(lparam & 0xffff);
            point.y = static_cast<short>((lparam >> 16) & 0xffff);
            ScreenToClient(dialog, &point);
            if (state->active_round == 1 &&
                point.x >= 0x15 && point.x <= 0x256 &&
                point.y >= 0x1f && point.y <= 0x14e) {
                state->cursor_state = 0x20;
            } else {
                state->cursor_state = 0x40;
            }
        } else if (state != 0) {
            state->cursor_state = 0;
        }
        return 0;

    case 0x0110:
        OtSetDialogBusyCursor_Product();
        g_activeScreenDialogWindow_00404dd0 = dialog;
        OtSetupInitHuntDialog_00015380_RealCpp(dialog);
        return 0;

    case 0x0111:
        if (state != 0 && (wparam & 0xffff) == 0x0900) {
            OtCycleHuntScene_Product_00414d00(state);
            return 1;
        }
        if (state != 0 && (wparam & 0xffff) == 0x0901) {
            state->round_done = 1;
            return 1;
        }
        return 0;

    case 0x0136:
        return reinterpret_cast<int>(g_sharedDialogBackgroundBrush_004390c0);

    case 0x0201:
    case 0x0204:
    case 0x0207:
        if (state != 0) {
            state->shot_x = static_cast<unsigned short>(lparam & 0xffff);
            state->shot_y = static_cast<unsigned short>((lparam >> 16) & 0xffff);
            OtHandleHuntShot_Product_00414620(state);
        }
        return 1;

    case 0x0464:
    case 0x0465:
        sndPlaySoundA(0, 0);
        if (state != 0) {
            state->round_running = 0;
        }
        return 1;

    case 0x0466:
    case 0x0467:
        if (state != 0) {
            state->round_running = 1;
        }
        return 1;

    case 0x0473:
        if (state != 0 &&
            state->OtRunHuntRoundLoop_00414ba0_Product(dialog) == 1) {
            int* results = new int[4];
            results[0] = state->meat_pounds;
            results[1] = state->bullets_fired;
            results[2] = 0;
            results[3] = 0;
            SendMessageA(GetParent(dialog), 0x0474, 0,
                         reinterpret_cast<long>(results));
            PostMessageA(GetParent(dialog), 0x0472, 0, 0);
        }
        return 1;
    }

    return 0;
}

#pragma optimize("", on)
