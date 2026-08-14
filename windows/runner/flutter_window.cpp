#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"
#include "resource.h"

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
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // Window lifecycle channel: Dart listens for `onCloseRequest` and calls
  // back `hideToTray` / `quit` / `restore`.
  channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "erispulse/window",
          &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        this->HandleChannelCall(call, std::move(result));
      });

  CreateTrayIcon();

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  RemoveTrayIcon();

  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

void FlutterWindow::HandleChannelCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (call.method_name() == "hideToTray") {
    ShowWindow(GetHandle(), SW_HIDE);
    result->Success();
  } else if (call.method_name() == "quit") {
    // Reply first, then defer destruction via a posted message: destroying
    // the window (and the engine) inside the channel callback is unsafe.
    result->Success();
    PostMessage(GetHandle(), kQuitMessage, 0, 0);
  } else if (call.method_name() == "restore") {
    RestoreFromTray();
    result->Success();
  } else {
    result->NotImplemented();
  }
}

void FlutterWindow::CreateTrayIcon() {
  tray_icon_ = {};
  tray_icon_.cbSize = sizeof(tray_icon_);
  tray_icon_.hWnd = GetHandle();
  tray_icon_.uID = kTrayIconId;
  tray_icon_.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP;
  tray_icon_.uCallbackMessage = kTrayCallbackMessage;
  tray_icon_.hIcon = LoadIcon(GetModuleHandle(nullptr),
                              MAKEINTRESOURCE(IDI_APP_ICON));
  wcscpy_s(tray_icon_.szTip, L"ErisPulse");
  Shell_NotifyIconW(NIM_ADD, &tray_icon_);
}

void FlutterWindow::RemoveTrayIcon() {
  if (tray_icon_.hWnd != nullptr) {
    Shell_NotifyIconW(NIM_DELETE, &tray_icon_);
    tray_icon_ = {};
  }
}

void FlutterWindow::RestoreFromTray() {
  HWND hwnd = GetHandle();
  if (hwnd == nullptr) {
    return;
  }
  ShowWindow(hwnd, SW_RESTORE);
  SetForegroundWindow(hwnd);
}

void FlutterWindow::ShowTrayMenu(HWND hwnd) {
  POINT pt;
  GetCursorPos(&pt);
  HMENU menu = CreatePopupMenu();
  AppendMenuW(menu, MF_STRING, 1001, L"打开 ErisPulse");
  AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
  AppendMenuW(menu, MF_STRING, 1002, L"退出");
  // Required so the menu dismisses when clicking elsewhere.
  SetForegroundWindow(hwnd);
  int cmd = TrackPopupMenu(menu,
                           TPM_RIGHTBUTTON | TPM_RETURNCMD | TPM_NONOTIFY,
                           pt.x, pt.y, 0, hwnd, nullptr);
  PostMessage(hwnd, WM_NULL, 0, 0);
  DestroyMenu(menu);
  if (cmd == 1001) {
    RestoreFromTray();
  } else if (cmd == 1002) {
    // Exit from tray: let Dart stop all instances first (no close dialog).
    if (channel_) {
      channel_->InvokeMethod("onExitRequest", nullptr);
    } else {
      PostMessage(hwnd, kQuitMessage, 0, 0);
    }
  }
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
    // Close (title bar X / Alt+F4): ask Dart what to do. Dart replies via
    // `hideToTray` or `quit`. If the channel is not ready yet (very early),
    // fall through to the default behavior (destroy).
    case WM_CLOSE:
      if (channel_) {
        channel_->InvokeMethod("onCloseRequest", nullptr);
        return 0;
      }
      break;

    case kQuitMessage:
      DestroyWindow(hwnd);
      return 0;

    case kTrayCallbackMessage: {
      if (lparam == WM_LBUTTONUP || lparam == WM_LBUTTONDBLCLK) {
        RestoreFromTray();
      } else if (lparam == WM_RBUTTONUP) {
        ShowTrayMenu(hwnd);
      }
      return 0;
    }

    case WM_DESTROY:
      RemoveTrayIcon();
      break;

    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
