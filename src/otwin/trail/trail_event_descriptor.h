#ifndef OTWIN_TRAIL_EVENT_DESCRIPTOR_H
#define OTWIN_TRAIL_EVENT_DESCRIPTOR_H

#pragma pack(push, 1)
struct TrailEventDescriptor_00416320 {
    const void* dispatch_table;
    unsigned long descriptor_dwords[9];
    unsigned short descriptor_tail;

    TrailEventDescriptor_00416320(unsigned int resource_id);
};
#pragma pack(pop)

typedef char OtTrailEventDescriptorMustBe0x2a[
    sizeof(TrailEventDescriptor_00416320) == 0x2a ? 1 : -1];

#endif
