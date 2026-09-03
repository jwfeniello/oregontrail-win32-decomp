#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

struct TradeDialogPositionedBitmapSlotMemberEhRecovery {
    char bytes[0x28];

    ~TradeDialogPositionedBitmapSlotMemberEhRecovery();
};

struct PositionedBitmapFree_0040b760_42pct {
    void OtFreePositionedBitmapAlt5_0040b760_42pct();
};

TradeDialogPositionedBitmapSlotMemberEhRecovery::
    ~TradeDialogPositionedBitmapSlotMemberEhRecovery()
{
    reinterpret_cast<PositionedBitmapFree_0040b760_42pct*>(this)->
        OtFreePositionedBitmapAlt5_0040b760_42pct();
}

extern "C" long __stdcall OtGetTradeDialogBitmapOwnerForEhRecovery(
    void* window,
    int index)
{
    (void)index;
    return (long)window;
}

extern "C" void __cdecl OtReleaseTradeDialogBitmapOwnerForEhRecovery(void* owner)
{
    (void)owner;
}
