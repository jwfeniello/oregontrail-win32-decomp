#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

struct PositionedBitmap_00405d90;

struct PositionedBitmapOwner_00405d90 {
    PositionedBitmap_00405d90* bitmap;

    void OtDestroyOwnedPositionedBitmap_RealCpp();
};

extern "C" void __fastcall OtFreePositionedBitmapDependencyCall_00406240(
    PositionedBitmap_00405d90* bitmap);
void __cdecl operator delete(void* block);

#pragma optimize("s", off)
#pragma optimize("t", on)

void PositionedBitmapOwner_00405d90::
    OtDestroyOwnedPositionedBitmap_RealCpp()
{
    PositionedBitmap_00405d90* owned_bitmap = bitmap;
    if (owned_bitmap != 0) {
        OtFreePositionedBitmapDependencyCall_00406240(owned_bitmap);
        ::operator delete(owned_bitmap);
    }
}

#pragma optimize("", on)
