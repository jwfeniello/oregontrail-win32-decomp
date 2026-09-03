// Canonical storage and teardown for the 34 startup trail-event objects.

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error "This Product source must be compiled with 32-bit MSVC."
#endif

extern "C" void* OtTrailEventObjectPointers_00418c50[34] = {0};

void __cdecl operator delete(void* block);

#pragma optimize("s", off)
#pragma optimize("t", on)

extern "C" void __cdecl OtDeleteTrailEventObjectTable_RealCpp()
{
    void** event_object = OtTrailEventObjectPointers_00418c50;

    do {
        void* object = *event_object;
        ++event_object;
        ::operator delete(object);
    } while (event_object <= &OtTrailEventObjectPointers_00418c50[33]);
}

#pragma optimize("", on)
