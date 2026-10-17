#ifndef RUNNER_IDENTITY_H_
#define RUNNER_IDENTITY_H_

// MTC-iPTv SuperAdmin (the NEW admin program, superadmin/). Its window class and single-instance
// mutex differ from BOTH the viewer app ("MTC_IPTV_WINDOW") and the interim SuperAdmin built from
// mtc_iptv/ ("MTC_IPTV_SUPERADMIN_WINDOW"), so all three can run side by side on the owner's PC.
// The data folder is chosen in Dart (lib/core/app_paths.dart): %APPDATA%\MTC-Group\mtc_superadmin2,
// never the ProductName-derived folder the interim program uses.
constexpr const wchar_t kAppTitle[] = L"MTC-iPTv SuperAdmin";
constexpr const wchar_t kAppWindowClass[] = L"MTC_SUPERADMIN2_WINDOW";
constexpr const wchar_t kInstanceMutexName[] = L"Local\\MTC-iPTv-SuperAdmin2-SingleInstance";

// Smallest useful window (wide-screen admin layout: sidebar + table + side panel).
constexpr int kMinWindowWidth = 1100;
constexpr int kMinWindowHeight = 680;

#endif  // RUNNER_IDENTITY_H_
