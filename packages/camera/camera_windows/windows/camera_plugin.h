// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef PACKAGES_CAMERA_CAMERA_WINDOWS_WINDOWS_CAMERA_PLUGIN_H_
#define PACKAGES_CAMERA_CAMERA_WINDOWS_WINDOWS_CAMERA_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <functional>

#include "capture_controller.h"

namespace camera_windows {

// Abstraction for accessing the Flutter view's root window, to allow for faking
// in unit tests without creating fake window hierarchies, as well as to work
// around https://github.com/flutter/flutter/issues/90694.
using FlutterRootWindowProvider = std::function<HWND()>;

class CameraPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  CameraPlugin(flutter::PluginRegistrarWindows *registrar,
               std::unique_ptr<CaptureController> capture_controller);

  virtual ~CameraPlugin();

  // Called when a method is called on plugin channel;
  void HandleMethodCall(const flutter::MethodCall<> &method_call,
                        std::unique_ptr<flutter::MethodResult<>> result);

 private:
  flutter::PluginRegistrarWindows *registrar_;
  std::unique_ptr<CaptureController> capture_controller_;
};

}  // namespace camera_windows

#endif  // PACKAGES_CAMERA_CAMERA_WINDOWS_WINDOWS_CAMERA_PLUGIN_H_
