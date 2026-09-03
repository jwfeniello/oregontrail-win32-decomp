#ifndef OTWIN_TRAIL_EVENT_DISPATCH_TABLES_H
#define OTWIN_TRAIL_EVENT_DISPATCH_TABLES_H

#include "trail_event_runtime_abi.h"

// ABI-only declarations for methods implemented by the individual Product
// event-handler translation units.  Each class uses VC4's four-byte
// single-inheritance member-function-pointer representation.
class TrailEventRunner_00416c50 {
public:
    void OtRunPartyRecoveryEvent_RealCpp();
    void OtRunBlizzardEvent_RealCpp();
    void OtRunDustStormEvent_RealCpp();
    void OtRunHeavyFogEvent_RealCpp();
    void OtRunNoWaterEvent_RealCpp();
    void OtRunSevereStormEvent_RealCpp();
    void OtRunGraveSiteEvent_RealCpp();
    void OtRunBadWaterEvent_RealCpp();
    void OtRunHailStormEvent_RealCpp();
    void OtRunTrailImpassableEvent_RealCpp();
    void OtRunWanderingOxEvent_RealCpp();
    void OtRunLostTrailEvent_RealCpp();
    void OtRunLostPartyMemberEvent_RealCpp();
    void OtRunNoGrassForOxenEvent_RealCpp();
    void OtRunRoughTrailEvent_RealCpp();
    void OtRunBrokenArmEvent_RealCpp();
    void OtRunBrokenLegEvent_RealCpp();
    void OtRunSnakeBiteEvent_RealCpp();
    void OtRunSnowboundWagonEvent_RealCpp();
    void OtRunWrongTrailEvent_RealCpp();
    void OtRunOxSickEvent_RealCpp();
    void OtRunBrokenWagonWheelEvent_RealCpp();
    void OtRunBrokenWagonAxleEvent_RealCpp();
    void OtRunBrokenWagonTongueEvent_RealCpp();
    void OtRunWildFruitEvent_RealCpp();
};

class TrailEventRunner_004164f0_20260716 {
public:
    void OtRunOxDeathEvent_20260716_RealCpp();
};

class TrailEventRunner_00416680_Product {
public:
    void OtRunSlaughterOxForFoodEvent_00416680_ProductWip();
};

class TrailEventRunner_004168d0_20260604 {
public:
    void OtRunPartyDeathEvent_20260604_RealCpp();
};

class TrailEventRunner_00416e40_Product {
public:
    void OtRunAbandonedWagonEvent_00416e40_RealCpp();
};

class TrailEventRunner_00417520 {
public:
    void OtRunIndianFoodGiftEvent_00017520_RealCpp();
};

class TrailEventRunner_00417a10 {
public:
    void OtRunFoodSpoilageEvent_00417a10_RealCpp();
};

class TrailEventRunner_00417b90_20260603 {
public:
    void OtRunIllnessEvent_RealCpp();
};

class TrailEventRunner_00417de0_20260605 {
public:
    void OtRunTheftEventSlotPointer_20260605_ReccmpWip();
};

class TrailEventRunner_00418040_20260604 {
public:
    void OtRunWagonFireEvent_20260604_RealCpp();
};

extern "C" void __cdecl OtSetUnimplementedEventMessage_RealCpp();

struct g_te_vt_7010_1896d_type {
    void (TrailEventPendingStateImplementation_00416460::*set_pending)(int);
    void (__cdecl *run_event)();
};
extern "C" const g_te_vt_7010_1896d_type g_te_vt_7010_1896d;

#define DECLARE_TRAIL_EVENT_DISPATCH_TABLE(symbol, setter_class, runner_class) \
    struct symbol##_type { \
        void (setter_class::*set_pending)(int); \
        void (runner_class::*run_event)(); \
    }; \
    extern "C" const symbol##_type symbol

DECLARE_TRAIL_EVENT_DISPATCH_TABLE(g_te_vt_7110_1896d, PartyFollowupEventObject_004165c0, TrailEventRunner_004168d0_20260604);
DECLARE_TRAIL_EVENT_DISPATCH_TABLE(g_te_vt_7120_1896d, TrailEventPendingStateImplementation_00416460, TrailEventRunner_004164f0_20260716);
DECLARE_TRAIL_EVENT_DISPATCH_TABLE(g_te_vt_70c8_1896d, PartyFollowupEventObject_004165c0, TrailEventRunner_00416c50);
DECLARE_TRAIL_EVENT_DISPATCH_TABLE(g_te_vt_7068_1896d, TrailEventPendingStateImplementation_00416460, TrailEventRunner_00416680_Product);
DECLARE_TRAIL_EVENT_DISPATCH_TABLE(g_te_vt_7098_1896d, TrailEventPendingStateImplementation_00416460, TrailEventRunner_00416c50);
DECLARE_TRAIL_EVENT_DISPATCH_TABLE(g_te_vt_7088_1896d, TrailEventPendingStateImplementation_00416460, TrailEventRunner_00416c50);
DECLARE_TRAIL_EVENT_DISPATCH_TABLE(g_te_vt_7030_1896d, TrailEventPendingStateImplementation_00416460, TrailEventRunner_00416c50);
DECLARE_TRAIL_EVENT_DISPATCH_TABLE(g_te_vt_7100_1896d, TrailEventPendingStateImplementation_00416460, TrailEventRunner_00416c50);
DECLARE_TRAIL_EVENT_DISPATCH_TABLE(g_te_vt_70b8_1896d, TrailEventPendingStateImplementation_00416460, TrailEventRunner_00416c50);
DECLARE_TRAIL_EVENT_DISPATCH_TABLE(g_te_vt_7058_1896d, TrailEventPendingStateImplementation_00416460, TrailEventRunner_00416c50);
DECLARE_TRAIL_EVENT_DISPATCH_TABLE(g_te_vt_70d8_1896d, TrailEventPendingStateImplementation_00416460, TrailEventRunner_00416c50);
DECLARE_TRAIL_EVENT_DISPATCH_TABLE(g_te_vt_7078_1896d, TrailEventPendingStateImplementation_00416460, TrailEventRunner_00416c50);
DECLARE_TRAIL_EVENT_DISPATCH_TABLE(g_te_vt_7028_1896d, TrailEventPendingStateImplementation_00416460, TrailEventRunner_00416e40_Product);
DECLARE_TRAIL_EVENT_DISPATCH_TABLE(g_te_vt_70f0_1896d, TrailEventPendingStateImplementation_00416460, TrailEventRunner_00416c50);
DECLARE_TRAIL_EVENT_DISPATCH_TABLE(g_te_vt_70a8_1896d, TrailEventPendingStateImplementation_00416460, TrailEventRunner_00416c50);
DECLARE_TRAIL_EVENT_DISPATCH_TABLE(g_te_vt_7048_1896d, TrailEventPendingStateImplementation_00416460, TrailEventRunner_00416c50);
DECLARE_TRAIL_EVENT_DISPATCH_TABLE(g_te_vt_70e8_1896d, TrailEventPendingStateImplementation_00416460, TrailEventRunner_00416c50);
DECLARE_TRAIL_EVENT_DISPATCH_TABLE(g_te_vt_70a0_1896d, TrailEventPendingStateImplementation_00416460, TrailEventRunner_00416c50);
DECLARE_TRAIL_EVENT_DISPATCH_TABLE(g_te_vt_7040_1896d, TrailEventPendingStateImplementation_00416460, TrailEventRunner_00416c50);
DECLARE_TRAIL_EVENT_DISPATCH_TABLE(g_te_vt_70d0_1896d, TrailEventPendingStateImplementation_00416460, TrailEventRunner_00416c50);
DECLARE_TRAIL_EVENT_DISPATCH_TABLE(g_te_vt_7070_1896d, TrailEventPendingStateImplementation_00416460, TrailEventRunner_00416c50);
DECLARE_TRAIL_EVENT_DISPATCH_TABLE(g_te_vt_7018_1896d, TrailEventPendingStateImplementation_00416460, TrailEventRunner_00417520);
DECLARE_TRAIL_EVENT_DISPATCH_TABLE(g_te_vt_70e0_1896d, TrailEventPendingStateImplementation_00416460, TrailEventRunner_00416c50);
DECLARE_TRAIL_EVENT_DISPATCH_TABLE(g_te_vt_7090_1896d, TrailEventPendingStateImplementation_00416460, TrailEventRunner_00416c50);
DECLARE_TRAIL_EVENT_DISPATCH_TABLE(g_te_vt_7038_1896d, TrailEventPendingStateImplementation_00416460, TrailEventRunner_00416c50);
DECLARE_TRAIL_EVENT_DISPATCH_TABLE(g_te_vt_7108_1896d, TrailEventPendingStateImplementation_00416460, TrailEventRunner_00416c50);
DECLARE_TRAIL_EVENT_DISPATCH_TABLE(g_te_vt_70c0_1896d, TrailEventPendingStateImplementation_00416460, TrailEventRunner_00416c50);
DECLARE_TRAIL_EVENT_DISPATCH_TABLE(g_te_vt_7060_1896d, TrailEventPendingStateImplementation_00416460, TrailEventRunner_00416c50);
DECLARE_TRAIL_EVENT_DISPATCH_TABLE(g_te_vt_7118_1896d, TrailEventPendingStateImplementation_00416460, TrailEventRunner_00416c50);
DECLARE_TRAIL_EVENT_DISPATCH_TABLE(g_te_vt_7080_1896d, TrailEventPendingStateImplementation_00416460, TrailEventRunner_00417a10);
DECLARE_TRAIL_EVENT_DISPATCH_TABLE(g_te_vt_7020_1896d, TrailEventPendingStateImplementation_00416460, TrailEventRunner_00416c50);
DECLARE_TRAIL_EVENT_DISPATCH_TABLE(g_te_vt_7050_1896d, TrailEventPendingStateImplementation_00416460, TrailEventRunner_00418040_20260604);
DECLARE_TRAIL_EVENT_DISPATCH_TABLE(g_te_vt_70b0_1896d, TrailEventPendingStateImplementation_00416460, TrailEventRunner_00417de0_20260605);
DECLARE_TRAIL_EVENT_DISPATCH_TABLE(g_te_vt_70f8_1896d, TrailEventPendingStateImplementation_00416460, TrailEventRunner_00417b90_20260603);

#undef DECLARE_TRAIL_EVENT_DISPATCH_TABLE

#endif
