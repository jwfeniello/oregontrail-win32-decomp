#ifndef OTWIN_TRAIL_FOOD_SPOILAGE_EVENT_TYPES_H
#define OTWIN_TRAIL_FOOD_SPOILAGE_EVENT_TYPES_H

#pragma pack(push, 1)
struct TrailEventTextState_00417a10 {
    void* first_argument;

    void OtFormatGameMessageTextDependency_00417a10(int string_id);
};

struct TrailEventRunner_00417a10 {
    char reserved_00[6];
    short message_count;

    void OtPrimeActiveTrailEventContextDependency_00417a10();
    void OtRunFoodSpoilageEvent_00417a10_RealCpp();
};
#pragma pack(pop)

#endif
