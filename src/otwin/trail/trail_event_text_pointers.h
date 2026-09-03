#ifndef OTWIN_TRAIL_EVENT_TEXT_POINTERS_H
#define OTWIN_TRAIL_EVENT_TEXT_POINTERS_H

#pragma pack(push, 1)
struct TrailEventTextPointers {
    const char* primary;
    const char* secondary;
};
#pragma pack(pop)

extern "C" TrailEventTextPointers g_trailEventTextPointers;

#endif
