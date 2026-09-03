// Product implementations for ABI-preserving trail-event dependency calls.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

#include "food_spoilage_event_types.h"
#include "trail_event_context_source.h"
#include "trail_event_text_runtime.h"

#pragma pack(push, 1)
struct LossEventAdjustmentList_0041a660_ProductWip {
    short entries[13];

    void OtApplyLossEventAdjustmentList_0041a660_ProductWip();
};

struct EventAdjustmentList_00418040_20260604 {
    short entries[13];

    EventAdjustmentList_00418040_20260604();
    void OtApplyLossEventAdjustmentListDependency_20260604();
    short OtFormatEventAdjustmentListDependency_20260604(
        const char* person_event_text);
};
#pragma pack(pop)

#pragma code_seg(".otsem")

// Existing Product callers construct the adjustment list as a short array.
// Preserve that interface while routing the work through the recovered method.
extern "C" void __cdecl OtApplyLossEventAdjustmentList_0041a660_ProductWip(
    short* entries)
{
    reinterpret_cast<LossEventAdjustmentList_0041a660_ProductWip*>(entries)->
        OtApplyLossEventAdjustmentList_0041a660_ProductWip();
}

void TrailEventRunner_00417a10::
    OtPrimeActiveTrailEventContextDependency_00417a10()
{
    reinterpret_cast<TrailEventContextSource_004163c0*>(this)->
        OtPrimeActiveTrailEventContext_004163c0_RealCpp();
}

void TrailEventTextState_00417a10::
    OtFormatGameMessageTextDependency_00417a10(int string_id)
{
    reinterpret_cast<TrailEventTextRuntime_0041aac0_20260603*>(this)->
        OtFormatGameMessageText_0001ac80_ProductWip(string_id);
}

void EventAdjustmentList_00418040_20260604::
    OtApplyLossEventAdjustmentListDependency_20260604()
{
    OtApplyLossEventAdjustmentList_0041a660_ProductWip(entries);
}

#pragma code_seg()
