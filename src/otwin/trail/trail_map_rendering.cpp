// Semantic trail-map segment drawing register-shape trials.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

#include "trail_runtime.h"

extern "C" __declspec(dllimport) int __stdcall MoveToEx(
    void* dc,
    int x,
    int y,
    void* previous_point);
extern "C" __declspec(dllimport) int __stdcall LineTo(
    void* dc,
    int x,
    int y);

extern "C" int (__stdcall *PTR_MoveToEx_00405fb0_44pct)(
    void* dc,
    int x,
    int y,
    void* previous_point) = MoveToEx;
extern "C" int (__stdcall *PTR_LineTo_00405fb0_44pct)(
    void* dc,
    int x,
    int y) = LineTo;

#pragma comment(lib, "gdi32.lib")

#pragma pack(push, 1)
struct TrailMapPoint_00405fb0_44pct {
    short x;
    short y;
};

struct TrailMapDisplay_00405fb0_44pct {
    char reserved_00[0x28];
    TrailMapPoint_00405fb0_44pct* progress_points;

    void OtDrawTrailMapProgressSegmentAlt1_00405fb0_44pct(
        void* dc,
        int previous_index,
        int current_index);
    void OtDrawTrailMapProgressSegmentAlt2_00405fb0_44pct(
        void* dc,
        int previous_index,
        int current_index);
    void OtDrawTrailMapProgressSegmentAlt3_00405fb0_44pct(
        void* dc,
        int previous_index,
        int current_index);
    void OtDrawTrailMapProgressSegmentAlt4_00405fb0_44pct(
        void* dc,
        int previous_index,
        int current_index);
    void OtDrawTrailMapProgressSegmentAlt5_00405fb0_44pct(
        void* dc,
        int previous_index,
        int current_index);
    void OtDrawTrailMapProgressSegmentAlt6_00405fb0_44pct(
        void* dc,
        int previous_index,
        int current_index);
    void OtDrawTrailMapProgressSegmentAlt7_00405fb0_44pct(
        void* dc,
        int previous_index,
        int current_index);
    void OtDrawTrailMapProgressSegmentAlt8_00405fb0_44pct(
        void* dc,
        int previous_index,
        int current_index);
    void OtDrawTrailMapProgressSegmentAlt9_00405fb0_44pct(
        void* dc,
        int previous_index,
        int current_index);
    void OtDrawTrailMapProgressSegmentAlt10_00405fb0_44pct(
        void* dc,
        int previous_index,
        int current_index);
    void OtDrawTrailMapProgressSegmentAlt11_00405fb0_44pct(
        void* dc,
        int previous_index,
        int current_index);
    void OtDrawTrailMapProgressSegmentAlt12_00405fb0_44pct(
        void* dc,
        int previous_index,
        int current_index);
    void OtDrawTrailMapProgressSegmentAlt13_00405fb0_44pct(
        void* dc,
        int previous_index,
        int current_index);
    void OtDrawTrailMapProgressSegmentAlt14_00405fb0_44pct(
        void* dc,
        int previous_index,
        int current_index);
    void OtDrawTrailMapProgressSegmentAlt15_00405fb0_44pct(
        void* dc,
        int previous_index,
        int current_index);
    void OtDrawTrailMapProgressSegmentAlt16_00405fb0_44pct(
        void* dc,
        int previous_index,
        int current_index);
    void OtDrawTrailMapProgressSegmentAlt17_00405fb0_44pct(
        void* dc,
        int previous_index,
        int current_index);
    void OtDrawTrailMapProgressSegmentAlt18_00405fb0_44pct(
        void* dc,
        int previous_index,
        int current_index);
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

/**
 * Purpose: draw a visible trail-map progress segment between two route points.
 *
 * Parameters:
 * - dc: destination device context that receives MoveToEx and LineTo calls.
 * - previous_index: route-point index used as the line start.
 * - current_index: route-point index used as the line end; zeroed points are skipped.
 */
void TrailMapDisplay_00405fb0_44pct::OtDrawTrailMapProgressSegmentAlt1_00405fb0_44pct(
    void* dc,
    int previous_index,
    int current_index)
{
    register TrailMapDisplay_00405fb0_44pct* view = this;
    register int index = current_index;
    TrailMapPoint_00405fb0_44pct* current_point = view->progress_points + index;

    if (current_point->x != 0 && current_point->y != 0) {
        TrailMapPoint_00405fb0_44pct* previous_point = view->progress_points + previous_index;
        PTR_MoveToEx_00405fb0_44pct(dc, previous_point->x, previous_point->y, 0);

        TrailMapPoint_00405fb0_44pct* points = view->progress_points;
        int y = points[index].y;
        int x = points[index].x;
        PTR_LineTo_00405fb0_44pct(dc, x, y);
    }
}

/**
 * Purpose: draw a visible trail-map progress segment between two route points.
 *
 * Parameters:
 * - dc: destination device context that receives MoveToEx and LineTo calls.
 * - previous_index: route-point index used as the line start.
 * - current_index: route-point index used as the line end; zeroed points are skipped.
 */
void TrailMapDisplay_00405fb0_44pct::OtDrawTrailMapProgressSegmentAlt2_00405fb0_44pct(
    void* dc,
    int previous_index,
    int current_index)
{
    register TrailMapDisplay_00405fb0_44pct* view = this;
    register int index = current_index;
    TrailMapPoint_00405fb0_44pct* current_point = view->progress_points + index;

    if (current_point->x != 0 && current_point->y != 0) {
        TrailMapPoint_00405fb0_44pct* previous_point = view->progress_points + previous_index;
        PTR_MoveToEx_00405fb0_44pct(dc, previous_point->x, previous_point->y, 0);

        short* point_words = reinterpret_cast<short*>(view->progress_points + index);
        int y = point_words[1];
        int x = point_words[0];
        PTR_LineTo_00405fb0_44pct(dc, x, y);
    }
}

/**
 * Purpose: draw a visible trail-map progress segment between two route points.
 *
 * Parameters:
 * - dc: destination device context that receives MoveToEx and LineTo calls.
 * - previous_index: route-point index used as the line start.
 * - current_index: route-point index used as the line end; zeroed points are skipped.
 */
void TrailMapDisplay_00405fb0_44pct::OtDrawTrailMapProgressSegmentAlt3_00405fb0_44pct(
    void* dc,
    int previous_index,
    int current_index)
{
    register TrailMapDisplay_00405fb0_44pct* view = this;
    register int index = current_index;
    TrailMapPoint_00405fb0_44pct* current_point = view->progress_points + index;

    if (current_point->x != 0 && current_point->y != 0) {
        TrailMapPoint_00405fb0_44pct* previous_point = view->progress_points + previous_index;
        PTR_MoveToEx_00405fb0_44pct(dc, previous_point->x, previous_point->y, 0);

        register int y = current_point->y;
        register int x = current_point->x;
        PTR_LineTo_00405fb0_44pct(dc, x, y);
    }
}

/**
 * Purpose: draw a visible trail-map progress segment between two route points.
 *
 * Parameters:
 * - dc: destination device context that receives MoveToEx and LineTo calls.
 * - previous_index: route-point index used as the line start.
 * - current_index: route-point index used as the line end; zeroed points are skipped.
 */
void TrailMapDisplay_00405fb0_44pct::OtDrawTrailMapProgressSegmentAlt4_00405fb0_44pct(
    void* dc,
    int previous_index,
    int current_index)
{
    register TrailMapDisplay_00405fb0_44pct* view = this;
    register int index = current_index;
    TrailMapPoint_00405fb0_44pct* current_point = view->progress_points + index;

    if (current_point->x != 0 && current_point->y != 0) {
        TrailMapPoint_00405fb0_44pct* previous_point = view->progress_points + previous_index;
        PTR_MoveToEx_00405fb0_44pct(dc, previous_point->x, previous_point->y, 0);

        TrailMapPoint_00405fb0_44pct* points = view->progress_points;
        int x = points[index].x;
        int y = points[index].y;
        PTR_LineTo_00405fb0_44pct(dc, x, y);
    }
}

/**
 * Purpose: draw a visible trail-map progress segment between two route points.
 *
 * Parameters:
 * - dc: destination device context that receives MoveToEx and LineTo calls.
 * - previous_index: route-point index used as the line start.
 * - current_index: route-point index used as the line end; zeroed points are skipped.
 */
void TrailMapDisplay_00405fb0_44pct::OtDrawTrailMapProgressSegmentAlt5_00405fb0_44pct(
    void* dc,
    int previous_index,
    int current_index)
{
    register TrailMapDisplay_00405fb0_44pct* view = this;
    register int index = current_index;
    TrailMapPoint_00405fb0_44pct* current_point = view->progress_points + index;

    if (current_point->x != 0 && current_point->y != 0) {
        TrailMapPoint_00405fb0_44pct* previous_point = view->progress_points + previous_index;
        PTR_MoveToEx_00405fb0_44pct(dc, previous_point->x, previous_point->y, 0);

        register int x = current_point->x;
        register int y = current_point->y;
        PTR_LineTo_00405fb0_44pct(dc, x, y);
    }
}

/**
 * Purpose: draw a visible trail-map progress segment between two route points.
 *
 * Parameters:
 * - dc: destination device context that receives MoveToEx and LineTo calls.
 * - previous_index: route-point index used as the line start.
 * - current_index: route-point index used as the line end; zeroed points are skipped.
 */
void TrailMapDisplay_00405fb0_44pct::OtDrawTrailMapProgressSegmentAlt6_00405fb0_44pct(
    void* dc,
    int previous_index,
    int current_index)
{
    register TrailMapDisplay_00405fb0_44pct* view = this;
    register void* draw_dc = dc;
    short* point = reinterpret_cast<short*>(view->progress_points + current_index);

    if (point[0] != 0 && point[1] != 0) {
        point = reinterpret_cast<short*>(view->progress_points + previous_index);
        PTR_MoveToEx_00405fb0_44pct(draw_dc, point[0], point[1], 0);

        point = reinterpret_cast<short*>(view->progress_points + current_index);
        register int y = point[1];
        register int x = point[0];
        PTR_LineTo_00405fb0_44pct(draw_dc, x, y);
    }
}

/**
 * Purpose: draw a visible trail-map progress segment between two route points.
 *
 * Parameters:
 * - dc: destination device context that receives MoveToEx and LineTo calls.
 * - previous_index: route-point index used as the line start.
 * - current_index: route-point index used as the line end; zeroed points are skipped.
 */
void TrailMapDisplay_00405fb0_44pct::OtDrawTrailMapProgressSegmentAlt7_00405fb0_44pct(
    void* dc,
    int previous_index,
    int current_index)
{
    register TrailMapDisplay_00405fb0_44pct* view = this;
    register void* draw_dc = dc;
    short* point = reinterpret_cast<short*>(view->progress_points + current_index);

    if (point[0] != 0 && point[1] != 0) {
        point = reinterpret_cast<short*>(view->progress_points + previous_index);
        PTR_MoveToEx_00405fb0_44pct(draw_dc, point[0], point[1], 0);

        point = reinterpret_cast<short*>(view->progress_points + current_index);
        register int x = point[0];
        register int y = point[1];
        PTR_LineTo_00405fb0_44pct(draw_dc, x, y);
    }
}

/**
 * Purpose: draw a visible trail-map progress segment between two route points.
 *
 * Parameters:
 * - dc: destination device context that receives MoveToEx and LineTo calls.
 * - previous_index: route-point index used as the line start.
 * - current_index: route-point index used as the line end; zeroed points are skipped.
 */
void TrailMapDisplay_00405fb0_44pct::OtDrawTrailMapProgressSegmentAlt8_00405fb0_44pct(
    void* dc,
    int previous_index,
    int current_index)
{
    register TrailMapDisplay_00405fb0_44pct* view = this;
    register void* draw_dc = dc;
    short* point = reinterpret_cast<short*>(view->progress_points + current_index);

    if (point[0] != 0 && point[1] != 0) {
        point = reinterpret_cast<short*>(view->progress_points + previous_index);
        PTR_MoveToEx_00405fb0_44pct(draw_dc, point[0], point[1], 0);

        point = reinterpret_cast<short*>(view->progress_points + current_index);
        register int x;
        register int y;
        y = point[1];
        x = point[0];
        PTR_LineTo_00405fb0_44pct(draw_dc, x, y);
    }
}

/**
 * Purpose: draw a visible trail-map progress segment between two route points.
 *
 * Parameters:
 * - dc: destination device context that receives MoveToEx and LineTo calls.
 * - previous_index: route-point index used as the line start.
 * - current_index: route-point index used as the line end; zeroed points are skipped.
 */
void TrailMapDisplay_00405fb0_44pct::OtDrawTrailMapProgressSegmentAlt9_00405fb0_44pct(
    void* dc,
    int previous_index,
    int current_index)
{
    register TrailMapDisplay_00405fb0_44pct* view = this;
    register void* draw_dc = dc;
    short* point = reinterpret_cast<short*>(view->progress_points + current_index);

    if (point[0] != 0 && point[1] != 0) {
        point = reinterpret_cast<short*>(view->progress_points + previous_index);
        PTR_MoveToEx_00405fb0_44pct(draw_dc, point[0], point[1], 0);

        point = reinterpret_cast<short*>(view->progress_points + current_index);
        register int y;
        register int x;
        x = point[0];
        y = point[1];
        PTR_LineTo_00405fb0_44pct(draw_dc, x, y);
    }
}

// Alt10: reassign points after reading y; should let VC4 reuse the same
// register (lea reg,[reg+index*4]) instead of allocating a new one.
void TrailMapDisplay_00405fb0_44pct::OtDrawTrailMapProgressSegmentAlt10_00405fb0_44pct(
    void* dc,
    int previous_index,
    int current_index)
{
    register TrailMapDisplay_00405fb0_44pct* view = this;
    register int index = current_index;
    TrailMapPoint_00405fb0_44pct* current_point = view->progress_points + index;

    if (current_point->x != 0 && current_point->y != 0) {
        TrailMapPoint_00405fb0_44pct* previous_point = view->progress_points + previous_index;
        PTR_MoveToEx_00405fb0_44pct(dc, previous_point->x, previous_point->y, 0);

        TrailMapPoint_00405fb0_44pct* points = view->progress_points;
        int y = points[index].y;
        points = points + index;
        int x = points->x;
        PTR_LineTo_00405fb0_44pct(dc, x, y);
    }
}

// Alt11: inline the second-call args fully without any local pointer,
// letting VC4's CSE drive both addr loads.
void TrailMapDisplay_00405fb0_44pct::OtDrawTrailMapProgressSegmentAlt11_00405fb0_44pct(
    void* dc,
    int previous_index,
    int current_index)
{
    register TrailMapDisplay_00405fb0_44pct* view = this;
    register int index = current_index;
    TrailMapPoint_00405fb0_44pct* current_point = view->progress_points + index;

    if (current_point->x != 0 && current_point->y != 0) {
        TrailMapPoint_00405fb0_44pct* previous_point = view->progress_points + previous_index;
        PTR_MoveToEx_00405fb0_44pct(dc, previous_point->x, previous_point->y, 0);

        PTR_LineTo_00405fb0_44pct(
            dc,
            view->progress_points[index].x,
            view->progress_points[index].y);
    }
}

// Alt12: read y via indexed addressing, then take &current_point
// via reassignment of an existing local — the explicit overwrite is
// what the original ASM does (lea eax, [eax+esi*4]).
void TrailMapDisplay_00405fb0_44pct::OtDrawTrailMapProgressSegmentAlt12_00405fb0_44pct(
    void* dc,
    int previous_index,
    int current_index)
{
    register TrailMapDisplay_00405fb0_44pct* view = this;
    register int index = current_index;
    TrailMapPoint_00405fb0_44pct* current_point = view->progress_points + index;

    if (current_point->x != 0 && current_point->y != 0) {
        TrailMapPoint_00405fb0_44pct* previous_point = view->progress_points + previous_index;
        PTR_MoveToEx_00405fb0_44pct(dc, previous_point->x, previous_point->y, 0);

        // Re-derive current_point so its lifetime spans the next two reads.
        TrailMapPoint_00405fb0_44pct* arr = view->progress_points;
        int y = arr[index].y;
        TrailMapPoint_00405fb0_44pct* p = &arr[index];
        int x = p->x;
        PTR_LineTo_00405fb0_44pct(dc, x, y);
    }
}

// Alt13: use raw short-word indexing for the second reload so VC4 can pick
// the original's `mov eax,[points]; movsx ecx,[eax+esi*4+2]; lea eax,[eax+esi*4]`
// pattern instead of introducing a second pointer base in ECX.
void TrailMapDisplay_00405fb0_44pct::OtDrawTrailMapProgressSegmentAlt13_00405fb0_44pct(
    void* dc,
    int previous_index,
    int current_index)
{
    register TrailMapDisplay_00405fb0_44pct* view = this;
    register int index = current_index;
    TrailMapPoint_00405fb0_44pct* current_point = view->progress_points + index;

    if (current_point->x != 0 && current_point->y != 0) {
        TrailMapPoint_00405fb0_44pct* previous_point =
            view->progress_points + previous_index;
        PTR_MoveToEx_00405fb0_44pct(dc, previous_point->x, previous_point->y, 0);

        short* points = reinterpret_cast<short*>(view->progress_points);
        PTR_LineTo_00405fb0_44pct(
            dc,
            points[index * 2],
            points[index * 2 + 1]);
    }
}

// Alt14: materialize the scaled short-word index explicitly before the call.
void TrailMapDisplay_00405fb0_44pct::OtDrawTrailMapProgressSegmentAlt14_00405fb0_44pct(
    void* dc,
    int previous_index,
    int current_index)
{
    register TrailMapDisplay_00405fb0_44pct* view = this;
    register int index = current_index;
    TrailMapPoint_00405fb0_44pct* current_point = view->progress_points + index;

    if (current_point->x != 0 && current_point->y != 0) {
        TrailMapPoint_00405fb0_44pct* previous_point =
            view->progress_points + previous_index;
        PTR_MoveToEx_00405fb0_44pct(dc, previous_point->x, previous_point->y, 0);

        short* points = reinterpret_cast<short*>(view->progress_points);
        int word_index = index * 2;
        PTR_LineTo_00405fb0_44pct(
            dc,
            points[word_index],
            points[word_index + 1]);
    }
}

void TrailMapDisplay_00405fb0_44pct::OtDrawTrailMapProgressSegmentAlt15_00405fb0_44pct(
    void* dc,
    int previous_index,
    int current_index)
{
    register TrailMapDisplay_00405fb0_44pct* view = this;
    register int index = current_index;
    TrailMapPoint_00405fb0_44pct* current_point = view->progress_points + index;

    if (current_point->x != 0 && current_point->y != 0) {
        TrailMapPoint_00405fb0_44pct* previous_point =
            view->progress_points + previous_index;
        MoveToEx(dc, previous_point->x, previous_point->y, 0);

        TrailMapPoint_00405fb0_44pct* points = view->progress_points;
        int y = points[index].y;
        int x = points[index].x;
        LineTo(dc, x, y);
    }
}

void TrailMapDisplay_00405fb0_44pct::OtDrawTrailMapProgressSegmentAlt16_00405fb0_44pct(
    void* dc,
    int previous_index,
    int current_index)
{
    register int index = current_index;
    register TrailMapDisplay_00405fb0_44pct* view = this;
    TrailMapPoint_00405fb0_44pct* current_point = view->progress_points + index;

    if (current_point->x != 0 && current_point->y != 0) {
        TrailMapPoint_00405fb0_44pct* previous_point =
            view->progress_points + previous_index;
        MoveToEx(dc, previous_point->x, previous_point->y, 0);

        TrailMapPoint_00405fb0_44pct* points = view->progress_points;
        int y = points[index].y;
        int x = points[index].x;
        LineTo(dc, x, y);
    }
}

void TrailMapDisplay_00405fb0_44pct::OtDrawTrailMapProgressSegmentAlt17_00405fb0_44pct(
    void* dc,
    int previous_index,
    int current_index)
{
    TrailMapDisplay_00405fb0_44pct* view = this;
    register int index = current_index;
    TrailMapPoint_00405fb0_44pct* current_point = view->progress_points + index;

    if (current_point->x != 0 && current_point->y != 0) {
        TrailMapPoint_00405fb0_44pct* previous_point =
            view->progress_points + previous_index;
        MoveToEx(dc, previous_point->x, previous_point->y, 0);

        TrailMapPoint_00405fb0_44pct* points = view->progress_points;
        int y = points[index].y;
        int x = points[index].x;
        LineTo(dc, x, y);
    }
}

void TrailMapDisplay_00405fb0_44pct::OtDrawTrailMapProgressSegmentAlt18_00405fb0_44pct(
    void* dc,
    int previous_index,
    int current_index)
{
    register TrailMapDisplay_00405fb0_44pct* view = this;
    int index = current_index;
    TrailMapPoint_00405fb0_44pct* current_point = view->progress_points + index;

    if (current_point->x != 0 && current_point->y != 0) {
        TrailMapPoint_00405fb0_44pct* previous_point =
            view->progress_points + previous_index;
        MoveToEx(dc, previous_point->x, previous_point->y, 0);

        TrailMapPoint_00405fb0_44pct* points = view->progress_points;
        int y = points[index].y;
        int x = points[index].x;
        LineTo(dc, x, y);
    }
}
