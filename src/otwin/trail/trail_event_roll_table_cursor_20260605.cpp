// Product semantic source for the subclass-shaped trail-event table
// initializer.  The verifier's 0x0041896d row is the final constructor window
// inside OtInitTrailEventTable_00018230_RealCpp.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

#include "trail_event_descriptor.h"
#include "trail_event_dispatch_tables.h"

void* __cdecl operator new(unsigned int bytes);
extern "C" void* __cdecl memset(
    void* destination,
    int value,
    unsigned int count);

#pragma intrinsic(memset)

typedef TrailEventDescriptor_00416320 TrailEventCtorBase_1896d;

#pragma pack(push, 1)
struct TrailEvent7080_1896d : TrailEventCtorBase_1896d {
    TrailEvent7080_1896d(unsigned int resource_id)
        : TrailEventCtorBase_1896d(resource_id)
    {
        dispatch_table = &g_te_vt_7080_1896d;
    }
};

struct TrailEvent7020_1896d : TrailEventCtorBase_1896d {
    TrailEvent7020_1896d()
        : TrailEventCtorBase_1896d(0x1f)
    {
        dispatch_table = &g_te_vt_7020_1896d;
    }
};

struct TrailEvent70f8_1896d : TrailEventCtorBase_1896d {
    TrailEvent70f8_1896d()
        : TrailEventCtorBase_1896d(0x22)
    {
        dispatch_table = &g_te_vt_70f8_1896d;
    }
};

struct TrailEvent70b0_1896d : TrailEventCtorBase_1896d {
    TrailEvent70b0_1896d()
        : TrailEventCtorBase_1896d(0x21)
    {
        dispatch_table = &g_te_vt_70b0_1896d;
    }
};

struct TrailEvent7050_1896d : TrailEventCtorBase_1896d {
    TrailEvent7050_1896d()
        : TrailEventCtorBase_1896d(0x20)
    {
        dispatch_table = &g_te_vt_7050_1896d;
    }
};

struct TrailEventLargeBase_1896d : TrailEventCtorBase_1896d {
    unsigned long extra_dwords[5];

    TrailEventLargeBase_1896d(unsigned int resource_id)
        : TrailEventCtorBase_1896d(resource_id)
    {
    }
};

struct TrailEventSingleBase_1896d : TrailEventCtorBase_1896d {
    unsigned long extra_dword;

    TrailEventSingleBase_1896d(unsigned int resource_id)
        : TrailEventCtorBase_1896d(resource_id)
    {
    }
};

#define DEFINE_TRAIL_EVENT_COMPACT_1896D(class_name, resource_id, vtable_name) \
struct class_name : TrailEventCtorBase_1896d { \
    class_name() : TrailEventCtorBase_1896d(resource_id) \
    { \
        dispatch_table = &vtable_name; \
    } \
}

#define DEFINE_TRAIL_EVENT_LARGE_ZERO_1896D(class_name, resource_id, vtable_name) \
struct class_name : TrailEventLargeBase_1896d { \
    class_name() : TrailEventLargeBase_1896d(resource_id) \
    { \
        dispatch_table = &vtable_name; \
        memset(extra_dwords, 0, sizeof(extra_dwords)); \
    } \
}

struct TrailEvent7068_1896d : TrailEventSingleBase_1896d {
    TrailEvent7068_1896d()
        : TrailEventSingleBase_1896d(0x04)
    {
        dispatch_table = &g_te_vt_7068_1896d;
        extra_dword = 1;
    }
};

DEFINE_TRAIL_EVENT_LARGE_ZERO_1896D(TrailEvent7110_1896d, 0x01, g_te_vt_7110_1896d);
DEFINE_TRAIL_EVENT_COMPACT_1896D(TrailEvent7120_1896d, 0x02, g_te_vt_7120_1896d);
DEFINE_TRAIL_EVENT_LARGE_ZERO_1896D(TrailEvent70c8_1896d, 0x03, g_te_vt_70c8_1896d);
DEFINE_TRAIL_EVENT_COMPACT_1896D(TrailEvent7098_1896d, 0x05, g_te_vt_7098_1896d);
DEFINE_TRAIL_EVENT_COMPACT_1896D(TrailEvent7088_1896d, 0x06, g_te_vt_7088_1896d);
DEFINE_TRAIL_EVENT_COMPACT_1896D(TrailEvent7030_1896d, 0x07, g_te_vt_7030_1896d);
DEFINE_TRAIL_EVENT_COMPACT_1896D(TrailEvent7100_1896d, 0x08, g_te_vt_7100_1896d);
DEFINE_TRAIL_EVENT_COMPACT_1896D(TrailEvent70b8_1896d, 0x09, g_te_vt_70b8_1896d);
DEFINE_TRAIL_EVENT_COMPACT_1896D(TrailEvent7058_1896d, 0x0a, g_te_vt_7058_1896d);
DEFINE_TRAIL_EVENT_COMPACT_1896D(TrailEvent7078_1896d, 0x0c, g_te_vt_7078_1896d);
DEFINE_TRAIL_EVENT_COMPACT_1896D(TrailEvent70d8_1896d, 0x0b, g_te_vt_70d8_1896d);
DEFINE_TRAIL_EVENT_COMPACT_1896D(TrailEvent7028_1896d, 0x0d, g_te_vt_7028_1896d);
DEFINE_TRAIL_EVENT_COMPACT_1896D(TrailEvent70f0_1896d, 0x0e, g_te_vt_70f0_1896d);
DEFINE_TRAIL_EVENT_COMPACT_1896D(TrailEvent70a8_1896d, 0x0f, g_te_vt_70a8_1896d);
DEFINE_TRAIL_EVENT_COMPACT_1896D(TrailEvent7048_1896d, 0x10, g_te_vt_7048_1896d);
DEFINE_TRAIL_EVENT_COMPACT_1896D(TrailEvent70e8_1896d, 0x11, g_te_vt_70e8_1896d);
DEFINE_TRAIL_EVENT_COMPACT_1896D(TrailEvent70a0_1896d, 0x12, g_te_vt_70a0_1896d);
DEFINE_TRAIL_EVENT_COMPACT_1896D(TrailEvent7040_1896d, 0x13, g_te_vt_7040_1896d);
DEFINE_TRAIL_EVENT_COMPACT_1896D(TrailEvent70d0_1896d, 0x14, g_te_vt_70d0_1896d);
DEFINE_TRAIL_EVENT_COMPACT_1896D(TrailEvent7070_1896d, 0x15, g_te_vt_7070_1896d);
DEFINE_TRAIL_EVENT_COMPACT_1896D(TrailEvent7018_1896d, 0x16, g_te_vt_7018_1896d);
DEFINE_TRAIL_EVENT_COMPACT_1896D(TrailEvent70e0_1896d, 0x17, g_te_vt_70e0_1896d);
DEFINE_TRAIL_EVENT_COMPACT_1896D(TrailEvent7090_1896d, 0x18, g_te_vt_7090_1896d);
DEFINE_TRAIL_EVENT_COMPACT_1896D(TrailEvent7038_1896d, 0x19, g_te_vt_7038_1896d);
DEFINE_TRAIL_EVENT_COMPACT_1896D(TrailEvent7108_1896d, 0x1a, g_te_vt_7108_1896d);
DEFINE_TRAIL_EVENT_COMPACT_1896D(TrailEvent70c0_1896d, 0x1b, g_te_vt_70c0_1896d);
DEFINE_TRAIL_EVENT_COMPACT_1896D(TrailEvent7060_1896d, 0x1c, g_te_vt_7060_1896d);
DEFINE_TRAIL_EVENT_COMPACT_1896D(TrailEvent7118_1896d, 0x1d, g_te_vt_7118_1896d);
#pragma pack(pop)

extern "C" void* OtTrailEventObjectPointers_00418c50[34];

#pragma optimize("s", off)
#pragma optimize("t", on)

// The subclasses retain the original allocation sizes and constructor order,
// while every base constructor now loads the real type-0x3e8 descriptor and
// every installed table entry points at a live Product dispatch function.
extern "C" void __cdecl OtInitTrailEventTable_00018230_RealCpp()
{
    OtTrailEventObjectPointers_00418c50[0x00] = new TrailEvent7110_1896d;
    OtTrailEventObjectPointers_00418c50[0x01] = new TrailEvent7120_1896d;
    OtTrailEventObjectPointers_00418c50[0x02] = new TrailEvent70c8_1896d;
    OtTrailEventObjectPointers_00418c50[0x03] = new TrailEvent7068_1896d;
    OtTrailEventObjectPointers_00418c50[0x04] = new TrailEvent7098_1896d;
    OtTrailEventObjectPointers_00418c50[0x05] = new TrailEvent7088_1896d;
    OtTrailEventObjectPointers_00418c50[0x06] = new TrailEvent7030_1896d;
    OtTrailEventObjectPointers_00418c50[0x07] = new TrailEvent7100_1896d;
    OtTrailEventObjectPointers_00418c50[0x08] = new TrailEvent70b8_1896d;
    OtTrailEventObjectPointers_00418c50[0x09] = new TrailEvent7058_1896d;
    OtTrailEventObjectPointers_00418c50[0x0b] = new TrailEvent7078_1896d;
    OtTrailEventObjectPointers_00418c50[0x0a] = new TrailEvent70d8_1896d;
    OtTrailEventObjectPointers_00418c50[0x0c] = new TrailEvent7028_1896d;
    OtTrailEventObjectPointers_00418c50[0x0d] = new TrailEvent70f0_1896d;
    OtTrailEventObjectPointers_00418c50[0x0e] = new TrailEvent70a8_1896d;
    OtTrailEventObjectPointers_00418c50[0x0f] = new TrailEvent7048_1896d;
    OtTrailEventObjectPointers_00418c50[0x10] = new TrailEvent70e8_1896d;
    OtTrailEventObjectPointers_00418c50[0x11] = new TrailEvent70a0_1896d;
    OtTrailEventObjectPointers_00418c50[0x12] = new TrailEvent7040_1896d;
    OtTrailEventObjectPointers_00418c50[0x13] = new TrailEvent70d0_1896d;
    OtTrailEventObjectPointers_00418c50[0x14] = new TrailEvent7070_1896d;
    OtTrailEventObjectPointers_00418c50[0x15] = new TrailEvent7018_1896d;
    OtTrailEventObjectPointers_00418c50[0x16] = new TrailEvent70e0_1896d;
    OtTrailEventObjectPointers_00418c50[0x17] = new TrailEvent7090_1896d;
    OtTrailEventObjectPointers_00418c50[0x18] = new TrailEvent7038_1896d;
    OtTrailEventObjectPointers_00418c50[0x19] = new TrailEvent7108_1896d;
    OtTrailEventObjectPointers_00418c50[0x1a] = new TrailEvent70c0_1896d;
    OtTrailEventObjectPointers_00418c50[0x1b] = new TrailEvent7060_1896d;
    OtTrailEventObjectPointers_00418c50[0x1c] = new TrailEvent7118_1896d;
    OtTrailEventObjectPointers_00418c50[0x1d] =
        new TrailEvent7080_1896d(0x1e);
    OtTrailEventObjectPointers_00418c50[0x1e] = new TrailEvent7020_1896d;
    OtTrailEventObjectPointers_00418c50[0x21] = new TrailEvent70f8_1896d;
    OtTrailEventObjectPointers_00418c50[0x20] = new TrailEvent70b0_1896d;
    OtTrailEventObjectPointers_00418c50[0x1f] = new TrailEvent7050_1896d;
}

#pragma optimize("", on)
