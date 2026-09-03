#ifndef OTWIN_TRAIL_EVENT_CONTEXT_SOURCE_H
#define OTWIN_TRAIL_EVENT_CONTEXT_SOURCE_H

#pragma pack(push, 1)
struct TrailEventContextSource_004163c0 {
    char reserved_00[6];
    unsigned short message_count;
    char reserved_08[8];
    unsigned short variant_text_ids[4];
    char reserved_18[8];
    unsigned short field_20;
    unsigned short field_22;
    unsigned short field_24;
    unsigned short field_26;

    void OtPrimeActiveTrailEventContext_004163c0_RealCpp();
};
#pragma pack(pop)

#endif
