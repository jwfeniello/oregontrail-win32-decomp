// Semantic recovery candidate for OtFormatLocationArrivalMessage @ 0x00424e80.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

extern "C" void* g_resourceModule;
extern "C" __declspec(dllimport) int __stdcall LoadStringA(
    void* instance,
    unsigned int string_id,
    char* buffer,
    int buffer_max);
extern "C" short* __fastcall OtClearEventAdjustmentList_RealCpp(
    short* adjustments);

struct TrailEventTextRuntime_0041aac0_20260603 {
    char* OtFormatGameMessageText_0001ac80_ProductWip(int string_id);
};

#pragma pack(push, 1)
struct EventAdjustmentListFormatter_00424e80 {
    char fields[0x1c];

    void OtFormatEventAdjustmentListDependency_00424e80();
};

struct TrailEventTextArgument_00424e80 {
    void* first_argument;

    void OtSetTrailEventTextDependency_00424e80(int string_id);
};

struct RouteDescriptor_00424e80 {
    unsigned short route_stop_index;

    char* OtFormatLocationArrivalMessage_00424e80_RealCpp();
};

struct LocationArrivalMessageFrame_00424e80 {
    char location_name[0x28];
    char reserved_28[0x0c];
    EventAdjustmentListFormatter_00424e80 adjustments;
};
#pragma pack(pop)

extern "C" TrailEventTextArgument_00424e80 g_trailEventRuntimeState;
#define g_trailEventFollowupText \
    (reinterpret_cast<char*>(&g_trailEventRuntimeState) + 0x1fc)

#pragma code_seg(".otsem")
void EventAdjustmentListFormatter_00424e80::
    OtFormatEventAdjustmentListDependency_00424e80()
{
    OtClearEventAdjustmentList_RealCpp(
        reinterpret_cast<short*>(fields));
}

void TrailEventTextArgument_00424e80::OtSetTrailEventTextDependency_00424e80(
    int string_id)
{
    reinterpret_cast<TrailEventTextRuntime_0041aac0_20260603*>(this)->
        OtFormatGameMessageText_0001ac80_ProductWip(string_id);
}
#pragma code_seg()

#pragma optimize("s", off)
#pragma optimize("t", on)

char* RouteDescriptor_00424e80::OtFormatLocationArrivalMessage_00424e80_RealCpp()
{
    LocationArrivalMessageFrame_00424e80 frame;

    frame.adjustments.OtFormatEventAdjustmentListDependency_00424e80();
    LoadStringA(
        g_resourceModule,
        ((unsigned int)route_stop_index + 0x0d) << 4,
        frame.location_name,
        0x28);

    g_trailEventRuntimeState.first_argument = frame.location_name;

    switch (route_stop_index) {
    case 1:
    case 2:
    case 7:
    case 9:
    case 12:
    case 14:
        g_trailEventRuntimeState.OtSetTrailEventTextDependency_00424e80(
            0x047f);
        break;

    case 3:
    case 4:
    case 5:
    case 6:
    case 8:
    case 10:
    case 11:
    case 13:
    case 15:
    case 16:
        g_trailEventRuntimeState.OtSetTrailEventTextDependency_00424e80(
            0x0480);
        break;
    }

    return const_cast<char*>(g_trailEventFollowupText);
}

#pragma optimize("", on)
