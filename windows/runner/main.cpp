#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

// Single-instance guard: a second launch restores the existing window
// (including a hidden-to-tray one) instead of starting a new app process
// (which would lose track of running instance processes).
namespace {
constexpr const wchar_t kSingleInstanceMutex[] =
    L"Local\\ErisPulseApp.SingleInstance";
}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  HANDLE single_mutex =
      CreateMutexW(nullptr, TRUE, kSingleInstanceMutex);
  if (single_mutex != nullptr && GetLastError() == ERROR_ALREADY_EXISTS) {
    // App already running: restore and focus its window, then exit.
    HWND existing =
        FindWindowW(L"FLUTTER_RUNNER_WIN32_WINDOW", L"ErisPulse App");
    if (existing != nullptr) {
      ShowWindow(existing, SW_RESTORE);
      SetForegroundWindow(existing);
    }
    return 0;
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
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
  if (!window.Create(L"ErisPulse App", origin, size)) {
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
