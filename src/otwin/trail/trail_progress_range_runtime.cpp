// Canonical Product implementation of OtComputeTrailProgressRange @ 0x0042c0b0.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This product source must be compiled with 32-bit MSVC."
#endif

#pragma pack(push, 1)
struct JourneyState_0042c0b0_Product {
    char reserved_00[0x5c];
    short current_route_mile;
    char reserved_5e[0x2a];
    short route_progress_total;
    short route_progress_marker;
};

struct TrailProgressView_0042c0b0_Product {
    char reserved_000[0xa48];
    unsigned long elapsed_progress_units;
    unsigned long total_progress_units;

    void OtComputeTrailProgressRange_0042c0b0_Product(
        int* first_mile,
        int* last_mile);
};
#pragma pack(pop)

extern "C" JourneyState_0042c0b0_Product* g_journeyState;

#pragma code_seg(".otsem")
#pragma optimize("s", off)
#pragma optimize("t", on)

void TrailProgressView_0042c0b0_Product::
    OtComputeTrailProgressRange_0042c0b0_Product(
        int* first_mile,
        int* last_mile)
{
    int marker = g_journeyState->route_progress_marker;

    if (marker < 0) {
        marker = 0;
    }

    int first =
        marker -
        static_cast<int>(
            static_cast<unsigned long>(
                g_journeyState->route_progress_total *
                elapsed_progress_units) /
            total_progress_units);
    *first_mile = first;

    if (first < 0) {
        *first_mile = 0;
    }

    *last_mile =
        g_journeyState->current_route_mile - *first_mile + marker;
}

#pragma optimize("", on)
#pragma code_seg()
