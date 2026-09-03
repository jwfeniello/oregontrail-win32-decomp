#ifndef OTWIN_TRAIL_EVENT_RUNTIME_ABI_H
#define OTWIN_TRAIL_EVENT_RUNTIME_ABI_H

// Shared ABI prefix for the descriptor-backed trail-event objects.  Runtime
// callers use the abstract first-slot interface, while the actual first-slot
// implementation is deliberately nonvirtual so VC4 can place its direct
// four-byte member-function pointer in the recovered dispatch tables.
#pragma pack(push, 1)
struct TrailEventDispatchInterface_00418c70 {
    virtual void OtSetTrailEventPendingState_RealCpp(int pending_value);
};

struct TrailEventPendingStateImplementation_00416460 {
    void* dispatch_table;
    char reserved_04[4];
    short pending;

    void OtSetTrailEventPendingState_RealCpp(int pending_value);
};

struct PartyFollowupEventObject_004165c0 {
    virtual void OtSetTrailEventPendingState_RealCpp(int pending_value);
    char reserved_04[4];
    short pending;
    char reserved_0a[0x20];
    int member_followup_flags[5];

    void OtSetPartyRecoveryEventPendingState_RealCpp(int pending_value);
    void OtSetPartyDeathEventPendingState_RealCpp(int pending_value);
};
#pragma pack(pop)

typedef char OtTrailEventDispatchInterfaceMustBeFourBytes[
    sizeof(TrailEventDispatchInterface_00418c70) == 4 ? 1 : -1];
typedef char OtTrailEventPendingPrefixMustBeTenBytes[
    sizeof(TrailEventPendingStateImplementation_00416460) == 10 ? 1 : -1];

#endif
