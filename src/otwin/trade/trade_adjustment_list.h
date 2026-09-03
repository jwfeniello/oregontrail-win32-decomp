#ifndef OTWIN_TRADE_TRADE_ADJUSTMENT_LIST_H
#define OTWIN_TRADE_TRADE_ADJUSTMENT_LIST_H

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This recovered Product state requires 32-bit Microsoft C++."
#endif

#pragma pack(push, 1)
struct TradeAdjustmentList_00427d70 {
    short adjustments[13];

    static void* __cdecl operator new(unsigned int size);
    TradeAdjustmentList_00427d70();
    void OtApplyEventAdjustmentList_Product_0041a430();
    void OtApplyLossEventAdjustmentList_Product_0041a660();

    // Original callers load this with the adjustment-list address and pass
    // both shorts on the stack. The method does not inspect member storage,
    // but its genuine ABI is __thiscall with eight callee-cleaned argument
    // bytes, not a free __stdcall function.
    int OtWouldExceedInventoryLimit_0041a960_RealCpp(
        short inventory_kind,
        short added_count);
};
#pragma pack(pop)

typedef char OtTradeAdjustmentListSizeMustBe01a[
    sizeof(TradeAdjustmentList_00427d70) == 0x1a ? 1 : -1];

#endif
