#ifndef RUNNER_IDENTITY_H_
#define RUNNER_IDENTITY_H_

// Viewer app (every published build) vs. MTC-iPTv SuperAdmin (admin program, built by
// scripts/build-superadmin.ps1 with MTC_SUPERADMIN=1). Different window class and mutex,
// so both can run side by side on the owner's PC.
#ifdef MTC_SUPERADMIN
constexpr const wchar_t kAppTitle[] = L"MTC-iPTv SuperAdmin";
constexpr const wchar_t kAppWindowClass[] = L"MTC_IPTV_SUPERADMIN_WINDOW";
constexpr const wchar_t kInstanceMutexName[] = L"Local\\MTC-iPTv-SuperAdmin-SingleInstance";
#else
constexpr const wchar_t kAppTitle[] = L"MTC-iPTv";
constexpr const wchar_t kAppWindowClass[] = L"MTC_IPTV_WINDOW";
constexpr const wchar_t kInstanceMutexName[] = L"Local\\MTC-iPTv-SingleInstance";
#endif

#endif  // RUNNER_IDENTITY_H_
