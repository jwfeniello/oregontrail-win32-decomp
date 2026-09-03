// Semantic recovery candidate for OtCheckDiskFreeSpaceForSave @ 0x0040c7e0.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This match-candidate file must be compiled with 32-bit MSVC."
#endif

extern "C" __declspec(dllimport) int __stdcall GetDiskFreeSpaceA(
    const char* root_path,
    long* sectors_per_cluster,
    long* bytes_per_sector,
    long* free_clusters,
    long* total_clusters);
extern "C" __declspec(dllimport) int __stdcall MessageBeep(unsigned int type);
extern "C" __declspec(dllimport) int __stdcall MessageBoxA(
    void* owner,
    const char* text,
    const char* caption,
    unsigned int type);
extern "C" int __cdecl printf(const char* format, ...);
extern "C" void __cdecl exit(int exit_code);

#pragma comment(lib, "kernel32.lib")
#pragma comment(lib, "user32.lib")

extern "C" char g_diskFullSaveText_0040c7e0[] =
    "The disk is too full to save your file.";
extern "C" char g_diskFullCaption_0040c7e0[] = "Disk Full";
extern "C" char g_getDiskFreeSpaceFailureText_0040c7e0[] =
    "Error in GetDiskFreeSpace call";

#pragma pack(push, 1)
struct DiskFreeSpaceFrame_0040c7e0 {
    char root_path[4];
    long free_clusters;
    long bytes_per_sector;
    long sectors_per_cluster;
    long total_clusters;
};
#pragma pack(pop)

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" int __cdecl OtCheckDiskFreeSpaceForSave_0040c7e0_RealCpp(
    char drive_letter,
    long required_bytes)
{
    DiskFreeSpaceFrame_0040c7e0 frame;

    frame.root_path[0] = drive_letter;
    frame.root_path[1] = ':';
    frame.root_path[2] = '\\';
    frame.root_path[3] = '\0';

    if (!GetDiskFreeSpaceA(
            frame.root_path,
            &frame.sectors_per_cluster,
            &frame.bytes_per_sector,
            &frame.free_clusters,
            &frame.total_clusters)) {
        printf(g_getDiskFreeSpaceFailureText_0040c7e0);
        exit(1);
    }

    if ((frame.free_clusters * frame.bytes_per_sector *
         frame.sectors_per_cluster) < required_bytes) {
        MessageBeep(0x30);
        MessageBoxA(
            0,
            g_diskFullSaveText_0040c7e0,
            g_diskFullCaption_0040c7e0,
            0x30);
        return 0;
    }

    return 1;
}

#pragma optimize("", on)
