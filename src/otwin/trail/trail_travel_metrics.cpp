// Trail travel-metrics recomputation for the trail-game journey state.
//
// `OtRecomputeTrailTravelMetrics` updates per-day distance, weather/terrain-
// affected effective distance, and food-cost values on the journey state from
// a global daily-multiplier scaling.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

// Forward-declare the journey-state struct that lives at g_journeyState.
// Full layout is in app/utility_stubs.cpp; we only need the addresses here.
struct JourneyState_00416380;

extern "C" JourneyState_00416380* g_journeyState;
extern "C" int g_dailyTravelDistanceScale = 0;

// VC4 with /O1 defaults to size-favoring codegen (imul reg, reg, imm). The
// original was compiled with speed-favoring codegen, which uses shl + LEA
// multiplication chains. These pragmas force the speed pattern within /O1.
#pragma optimize("s", off)
#pragma optimize("t", on)

// Original: 0x0042ddc0, 192 bytes, 55 instructions.
//
// Mask covers four abs32 sites for the two globals:
//   bytes 22-25:   abs32 of g_dailyTravelDistanceScale (mov eax, [g_daily_multiplier])
//   bytes 67-70:   abs32 of g_dailyTravelDistanceScale (mov edx, [g_daily_multiplier])
//   bytes 85-88:   abs32 of g_journeyState (mov edx, [g_journey_state])
//   bytes 140-143: abs32 of g_journeyState (mov eax, [g_journey_state])
//
// Structural notes (from byte-shape matching against original):
//   - g_dailyTravelDistanceScale is referenced 3 times in source but emits only 2 abs32
//     sites: VC4/O1 keeps the first load in EAX and reuses through LEA chains
//     (eax*5*5*5 = eax*125, then *4 via shl gives *500); the second load is a
//     fresh fetch into EDX after IDIV clobbers EAX.
//   - g_journeyState emits 2 abs32 sites for 3 source references: the third is
//     served from a register that survived between the if-chains.
//   - Conditional uses `<= 2` (jge encoding) not `< 3` (jg) -- semantically
//     equivalent, different jcc opcode.
//   - Final if/else is symmetric so VC4 shares the function epilogue.

extern "C" __declspec(dllexport) void __fastcall
OtRecomputeTrailTravelMetrics_0042ddc0_RealCpp(int param_1)
{
    int dist;

    *(unsigned int *)(param_1 + 0xa3c) = 0x19;
    *(unsigned int *)(param_1 + 0xa40) = 0x6e;

    dist = (g_dailyTravelDistanceScale * 500) / 0x32;
    *(int *)(param_1 + 0xa34) = dist;

    if (*(int *)(param_1 + 0xa54) <= 2) {
        *(unsigned int *)(param_1 + 0xa38) = g_dailyTravelDistanceScale * 9;
    } else {
        *(unsigned int *)(param_1 + 0xa38) = g_dailyTravelDistanceScale * 3;
    }

    if (*(short *)((char*)g_journeyState + 0x92) == 0) {
        *(unsigned int *)(param_1 + 0xa4c) = dist * 2;
    } else if (*(short *)((char*)g_journeyState + 0x92) == 1) {
        *(unsigned int *)(param_1 + 0xa4c) =
            (*(unsigned int *)(param_1 + 0xa38) >> 2) + dist * 2;
    } else {
        *(unsigned int *)(param_1 + 0xa4c) =
            dist * 2 + *(unsigned int *)(param_1 + 0xa38);
    }

    if (*(short *)((char*)g_journeyState + 0x88) == 0) {
        *(unsigned int *)(param_1 + 0xa50) =
            *(unsigned int *)(param_1 + 0xa4c) / 0x14;
    } else {
        *(unsigned int *)(param_1 + 0xa50) =
            *(unsigned int *)(param_1 + 0xa4c) /
            (unsigned int)(int)*(short *)((char*)g_journeyState + 0x88);
    }
}
