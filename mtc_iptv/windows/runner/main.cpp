#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <string>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Single instance: a second launch (e.g. a mtciptv://watch/<id> link, or the desktop icon while
  // the app sits in the tray) hands its command line to the running window and exits.
  HANDLE instance_mutex = ::CreateMutexW(nullptr, TRUE, L"Local\\MTC-iPTv-SingleInstance");
  if (instance_mutex != nullptr && ::GetLastError() == ERROR_ALREADY_EXISTS) {
    HWND existing = ::FindWindowW(L"MTC_IPTV_WINDOW", nullptr);
    std::wstring cmd = command_line ? command_line : L"";
    COPYDATASTRUCT cds;
    cds.dwData = kInstanceArgsMessage;
    cds.cbData = static_cast<DWORD>((cmd.size() + 1) * sizeof(wchar_t));
    cds.lpData = const_cast<wchar_t*>(cmd.c_str());
    DWORD_PTR handled = 0;
    if (existing != nullptr &&
        ::SendMessageTimeoutW(existing, WM_COPYDATA, 0, reinterpret_cast<LPARAM>(&cds), SMTO_ABORTIFHUNG, 3000, &handled) != 0 &&
        handled == TRUE) {
      ::SetForegroundWindow(existing);
      ::CloseHandle(instance_mutex);
      return EXIT_SUCCESS;
    }
    // No live window answered (e.g. the old copy is closing after an update): start normally.
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"MTC-iPTv", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
