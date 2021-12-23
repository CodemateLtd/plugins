// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef PACKAGES_CAMERA_CAMERA_WINDOWS_WINDOWS_CAMERA_PLUGIN_H_
#define PACKAGES_CAMERA_CAMERA_WINDOWS_WINDOWS_CAMERA_PLUGIN_H_

#include <flutter/flutter_view.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <functional>

#include "camera.h"
#include "capture_controller.h"
#include "capture_controller_listener.h"

namespace camera_windows {
using flutter::MethodResult;

class CameraPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  CameraPlugin(flutter::PluginRegistrarWindows *registrar);

  virtual ~CameraPlugin();

  // Disallow copy and move.
  CameraPlugin(const CameraPlugin &) = delete;
  CameraPlugin &operator=(const CameraPlugin &) = delete;

  // Called when a method is called on plugin channel;
  void HandleMethodCall(const flutter::MethodCall<> &method_call,
                        std::unique_ptr<MethodResult<>> result);

 private:
  // Method handlers
  void CreateCameraMethodHandler(const EncodableMap &args,
                                 std::unique_ptr<MethodResult<>> result);

  void InitializeMethodHandler(const EncodableMap &args,
                               std::unique_ptr<MethodResult<>> result);

  void TakePictureMethodHandler(const EncodableMap &args,
                                std::unique_ptr<MethodResult<>> result);

  void StartVideoRecordingMethodHandler(const EncodableMap &args,
                                        std::unique_ptr<MethodResult<>> result);

  void StopVideoRecordingMethodHandler(const EncodableMap &args,
                                       std::unique_ptr<MethodResult<>> result);

  void ResumePreviewMethodHandler(const EncodableMap &args,
                                  std::unique_ptr<MethodResult<>> result);

  void PausePreviewMethodHandler(const EncodableMap &args,
                                 std::unique_ptr<MethodResult<>> result);

  void DisposeMethodHandler(const EncodableMap &args,
                            std::unique_ptr<MethodResult<>> result);

  Camera *GetCameraByDeviceId(std::string &device_id);
  Camera *GetCameraByCameraId(int64_t camera_id);
  void DisposeCameraByCameraId(int64_t camera_id);

  std::vector<std::unique_ptr<Camera>> cameras_;
  flutter::PluginRegistrarWindows *registrar_;
};

}  // namespace camera_windows

#endif  // PACKAGES_CAMERA_CAMERA_WINDOWS_WINDOWS_CAMERA_PLUGIN_H_
