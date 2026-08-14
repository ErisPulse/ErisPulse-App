#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <shellapi.h>

#include "win32_window.h"

// A window that hosts a Flutter view, a system tray icon and a method channel
// (`erispulse/window`) used by Dart to control the window lifecycle:
//
//   - WM_CLOSE is intercepted and forwarded to Dart (`onCloseRequest`);
//     Dart decides (minimize to tray / stop instances & exit) and calls back
//     `hideToTray` or `quit`.
//   - Tray icon: left click restores the window; right click shows a context
//     menu (open / exit).
//   - `quit` destroys the window (deferred via a posted message so it never
//     runs inside the channel callback itself).
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                          LPARAM const lparam) noexcept override;

 private:
  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

  // Channel to Dart (`erispulse/window`).
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;

  // Tray icon data (valid while the icon is registered).
  NOTIFYICONDATAW tray_icon_ = {};

  static constexpr UINT kTrayIconId = 1;
  static constexpr UINT kTrayCallbackMessage = WM_APP + 1;
  // Posted to actually destroy the window (quit path), so destruction never
  // happens inside a method-channel callback.
  static constexpr UINT kQuitMessage = WM_APP + 2;

  void HandleChannelCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void CreateTrayIcon();
  void RemoveTrayIcon();
  void RestoreFromTray();
  void ShowTrayMenu(HWND hwnd);
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
