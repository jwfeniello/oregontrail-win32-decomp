#ifndef OTWIN_ACTIVE_TEXT_RUNTIME_H
#define OTWIN_ACTIVE_TEXT_RUNTIME_H

// Product-owned active-text storage.  The unsuffixed recovery-era symbol is
// still owned by an _exact translation unit, so product code uses this single
// canonical slot until that staging definition can be retired.
extern "C" void* g_activeTextGlobalHandle_Product;

extern "C" void __cdecl OtReleaseCachedGlobalHandle_Product_0040f840();

#endif
