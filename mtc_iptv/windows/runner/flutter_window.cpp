#include "flutter_window.h"

#include <optional>
#include <set>
#include <string>

#include <flutter/standard_method_codec.h>

#include "flutter/generated_plugin_registrant.h"

namespace {

std::set<HWND>& RaisedDialogs() {
  static std::set<HWND> raised;
  return raised;
}

BOOL CALLBACK RaiseIfNewDialog(HWND hwnd, LPARAM count) {
  DWORD pid = 0;
  ::GetWindowThreadProcessId(hwnd, &pid);
  if (pid != ::GetCurrentProcessId() || !::IsWindowVisible(hwnd)) return TRUE;
  wchar_t cls[64] = {0};
  ::GetClassNameW(hwnd, cls, 64);
  if (wcscmp(cls, L"#32770") != 0) return TRUE;
  if (!RaisedDialogs().insert(hwnd).second) return TRUE;  // already raised once
  const UINT flags = SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW;
  ::SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0, flags);
  ::SetWindowPos(hwnd, HWND_NOTOPMOST, 0, 0, 0, 0, flags);
  ::SetForegroundWindow(hwnd);
  FLASHWINFO fi = {sizeof(fi), hwnd, FLASHW_TRAY | FLASHW_TIMERNOFG, 3, 0};
  ::FlashWindowEx(&fi);
  ++*reinterpret_cast<int*>(count);
  return TRUE;
}

}  // namespace

int RaiseNewDialogs() {
  int count = 0;
  ::EnumWindows(RaiseIfNewDialog, reinterpret_cast<LPARAM>(&count));
  return count;
}

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  instance_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "mtc/instance",
      &flutter::StandardMethodCodec::GetInstance());
  // "raiseUpdater": WinSparkle opens its dialogs (#32770) from its own thread and Windows leaves them
  // BEHIND our window, so "Update now" looked like it did nothing (owner report, 2026-10-16).
  // Bring each new dialog of this process to the front exactly once.
  instance_channel_->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() != "raiseUpdater") {
          result->NotImplemented();
          return;
        }
        result->Success(flutter::EncodableValue(RaiseNewDialogs()));
      });
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    // --hidden: started with Windows for the admin scheduler; the window stays hidden
    // until opened from the tray icon (spec 9.10 H2).
    if (wcsstr(GetCommandLineW(), L"--hidden") == nullptr) {
      this->Show();
    }
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
    case WM_COPYDATA: {
      auto cds = reinterpret_cast<PCOPYDATASTRUCT>(lparam);
      if (cds != nullptr && cds->dwData == kInstanceArgsMessage && cds->lpData != nullptr && instance_channel_) {
        std::wstring cmd(static_cast<const wchar_t*>(cds->lpData));
        int len = ::WideCharToMultiByte(CP_UTF8, 0, cmd.c_str(), -1, nullptr, 0, nullptr, nullptr);
        std::string utf8(len > 0 ? len - 1 : 0, '\0');
        if (len > 1) ::WideCharToMultiByte(CP_UTF8, 0, cmd.c_str(), -1, utf8.data(), len, nullptr, nullptr);
        instance_channel_->InvokeMethod("args", std::make_unique<flutter::EncodableValue>(utf8));
        return TRUE;
      }
      break;
    }
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
