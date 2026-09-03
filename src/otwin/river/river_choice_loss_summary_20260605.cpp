// Product WIP for the river/trade dialog-state constructor at 0x00426270.
//
// The source shape is the retained ProbeB recovery, now wired to real product
// raw-bitmap and sprite constructors instead of empty recovery helpers.

#include "river_trade_dialog_state.h"
#include "../graphics/raw_indexed_bitmap_runtime.h"
#include "../graphics/sprite_blitter_runtime.h"

typedef void* RiverModuleHandle_00426270;
typedef void* RiverResourceInfo_00426270;

extern "C" __declspec(dllimport) RiverGlobalHandle_00426270 __stdcall
    GlobalAlloc(unsigned int flags, unsigned long bytes);
extern "C" __declspec(dllimport) void* __stdcall GlobalLock(
    RiverGlobalHandle_00426270 handle);
extern "C" __declspec(dllimport) RiverResourceInfo_00426270 __stdcall
    FindResourceA(
        RiverModuleHandle_00426270 module,
        const void* resource_name,
        const void* resource_type);
extern "C" __declspec(dllimport) RiverGlobalHandle_00426270 __stdcall
    LoadResource(
        RiverModuleHandle_00426270 module,
        RiverResourceInfo_00426270 resource_info);
extern "C" __declspec(dllimport) void* __stdcall LockResource(
    RiverGlobalHandle_00426270 resource_data);

#pragma comment(lib, "kernel32.lib")

extern "C" void* g_resourceModule;
extern "C" void* __cdecl OtAllocateNewBlock_RealCpp(unsigned int bytes);

#pragma pack(push, 1)
struct RiverBitmapInfoHeader_00426270_Product {
    unsigned long size;
    long width;
    long height;
    unsigned short planes;
    unsigned short bit_count;
    unsigned long compression;
    unsigned long size_image;
    long x_pels_per_meter;
    long y_pels_per_meter;
    unsigned long colors_used;
    unsigned long colors_important;
};

struct RiverBitmapInfo_00426270_Product {
    RiverBitmapInfoHeader_00426270_Product header;
    unsigned short palette[256];
};
#pragma pack(pop)

#pragma code_seg(".otsem")
void* __cdecl RawIndexedBitmap_00410490_Product::operator new(
    unsigned int bytes)
{
    return OtAllocateNewBlock_RealCpp(bytes);
}

void* __cdecl SpriteBlitter_00410660_Product::operator new(
    unsigned int bytes)
{
    return OtAllocateNewBlock_RealCpp(bytes);
}

#pragma optimize("s", off)
#pragma optimize("t", on)

RiverTradeDialogState_004277b0_20260604::
    RiverTradeDialogState_004277b0_20260604()
{
    int setup[20];
    int sprite_number;
    RiverTradeDialogState_004277b0_20260604* state = this;
    int zero = 0;
    int index;
    SpriteBlitter_00410660_Product** sprite_slot;

    state->field_4c = zero;
    state->field_50 = zero;
    state->raw_background = ::new RawIndexedBitmap_00410490_Product(
        g_resourceModule,
        0x21d,
        0x180,
        (const void*)0x0bb8);

    state->scratch_handle = GlobalAlloc(0x40, 30000);
    state->scratch_bits = GlobalLock(state->scratch_handle);

    state->resource_c22_handle = LoadResource(
        g_resourceModule,
        FindResourceA(g_resourceModule, (const void*)0x0c22, (const void*)10));
    state->resource_c22_bits = LockResource(state->resource_c22_handle);

    state->resource_c21_handle = LoadResource(
        g_resourceModule,
        FindResourceA(g_resourceModule, (const void*)0x0c21, (const void*)10));
    state->resource_c21_bits = LockResource(state->resource_c21_handle);

    state->bitmap_info_handle = GlobalAlloc(0, 0x428);
    state->bitmap_info = (RiverBitmapInfo_00426270_Product*)GlobalLock(
        state->bitmap_info_handle);
    state->bitmap_info->header.size = 0x28;
    state->bitmap_info->header.planes = 1;
    state->bitmap_info->header.bit_count = 8;
    state->bitmap_info->header.width = 0x240;
    state->bitmap_info->header.height = 0x98;
    state->bitmap_info->header.compression = zero;
    state->bitmap_info->header.size_image = 0x15600;
    state->bitmap_info->header.x_pels_per_meter = zero;
    state->bitmap_info->header.y_pels_per_meter = zero;
    state->bitmap_info->header.colors_important = zero;
    state->bitmap_info->header.colors_used = 0x100;

    index = 0;
    {
        unsigned short* palette =
            (unsigned short*)((char*)state->bitmap_info +
                              state->bitmap_info->header.size);
        do {
            *palette = (short)index;
            ++palette;
            ++index;
        } while (index < 0x100);
    }

    {
        unsigned int sprite_count = 0;
        sprite_slot = state->loss_sprites;
        state->field_48 = zero;
        state->field_44 = zero;
        do {
            *sprite_slot = ::new SpriteBlitter_00410660_Product;
            ++sprite_slot;
            ++sprite_count;
        } while (sprite_count < 4);
    }

    state->summary_sprite = ::new SpriteBlitter_00410660_Product;

    {
        const void* resource_name = (const void*)0x0c1c;
        RiverGlobalHandle_00426270* resource_slot =
            state->resource_handles;
        do {
            *resource_slot = 0;
            *resource_slot = LoadResource(
                g_resourceModule,
                FindResourceA(g_resourceModule, resource_name, (const void*)10));
            resource_slot[5] = (RiverGlobalHandle_00426270)
                LockResource(*resource_slot);
            resource_name = (const void*)((char*)resource_name + 1);
            ++resource_slot;
        } while (resource_name < (const void*)0x0c21);
    }

    setup[0] = 0x48;
    setup[1] = 0x36;
    setup[2] = 0x2d;
    setup[3] = 0x3e;
    setup[5] = 0x3d;
    setup[6] = 0x18;
    setup[7] = 0x17;
    setup[8] = 0x1c;
    setup[10] = 6;
    setup[4] = 0x0b;
    setup[9] = 0x0b;
    setup[14] = 1;
    setup[15] = 0x32;
    setup[11] = 7;
    setup[12] = 7;
    setup[19] = 800;
    setup[13] = 7;
    setup[16] = 0x7d;
    setup[17] = 0x7d;
    sprite_number = 0;
    index = 0;
    setup[18] = 0x7d;
    sprite_slot = state->loss_sprites;
    do {
        (*sprite_slot)->source_width = (short)*(int*)((char*)setup + index);
        (*sprite_slot)->source_height =
            (short)*(int*)((char*)setup + index + 0x14);
        (*sprite_slot)->source_pixels =
            (unsigned char*)sprite_slot[-0x1a];
        (*sprite_slot)->source_columns_per_row =
            (short)*(int*)((char*)setup + index + 0x28);
        (*sprite_slot)->resource_handle_or_state =
            *(int*)((char*)setup + index + 0x3c);
        (*sprite_slot)->mode_or_variant = (short)sprite_number;
        *(unsigned short*)&(*sprite_slot)->transparent_index = 0x17;
        (*sprite_slot)->horizontal_flip = 0;
        (*sprite_slot)->source_frame = 0;
        (*sprite_slot)->requested_x = 0;
        (*sprite_slot)->requested_y = 0;
        (*sprite_slot)->active_state = 0;
        (*sprite_slot)->OtResetSpriteBlitterBitmapInfo_Product_004107b0();
        ++sprite_number;
        ++sprite_slot;
        index += 4;
    } while (index < 0x10);

    state->loss_sprites[0]->requested_x = 0x0fa;
    state->loss_sprites[0]->requested_y = 0x0d2;
    state->loss_sprites[0]->active_state = 1;
    state->loss_sprites[0]->OtResetSpriteBlitterBitmapInfo_Product_004107b0();

    state->zero_after_init = 0;
    state->summary_sprite->requested_y = 0x16a;
    state->summary_sprite->requested_x = 0;
    state->summary_sprite->active_state = 1;
    state->summary_sprite->source_width = 0x0b;
    state->summary_sprite->source_height = 0x0b;
    state->summary_sprite->source_pixels =
        (unsigned char*)state->locked_resources[4];
    state->summary_sprite->source_columns_per_row = 1;
    state->summary_sprite->resource_handle_or_state = 800;
    state->summary_sprite->mode_or_variant = 4;
    *(unsigned short*)&state->summary_sprite->transparent_index = 0x17;
    state->summary_sprite->horizontal_flip = 0;
    state->summary_sprite->source_frame = 0;
    state->summary_sprite->OtResetSpriteBlitterBitmapInfo_Product_004107b0();
}

#pragma optimize("", on)
#pragma code_seg()
