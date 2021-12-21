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

#include "capture_controller.h"
#include "capture_controller_listener.h"

namespace camera_windows {

using flutter::EncodableMap;
using flutter::MethodResult;

enum PendingResultType {
  CREATE_CAMERA,
  INITIALIZE,
  TAKE_PICTURE,
  START_RECORD,
  STOP_RECORD,
  PAUSE_PREVIEW,
  RESUME_PREVIEW,
};

class CameraPlugin : public flutter::Plugin, public CaptureControllerListener {
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

  // From CaptureControllerListener
  void OnCreateCaptureEngineSucceeded(int64_t texture_id) override;
  void OnCreateCaptureEngineFailed(const std::string &error) override;
  void OnStartPreviewSucceeded(int32_t width, int32_t height) override;
  void OnStartPreviewFailed(const std::string &error) override;
  void OnStopPreviewSucceeded() override;
  void OnStopPreviewFailed(const std::string &error) override;
  void OnResumePreviewSucceeded() override;
  void OnResumePreviewFailed(const std::string &error) override;
  void OnStartRecordSucceeded() override;
  void OnStartRecordFailed(const std::string &error) override;
  void OnStopRecordSucceeded(const std::string &filepath) override;
  void OnStopRecordFailed(const std::string &error) override;
  void OnPictureSuccess(const std::string &filepath) override;
  void OnPictureFailed(const std::string &error) override;

 private:
  // Pending results
  std::map<PendingResultType, std::unique_ptr<MethodResult<>>> pending_results_;
  bool HasPendingResultByType(PendingResultType type);
  std::unique_ptr<MethodResult<>> GetPendingResultByType(
      PendingResultType type);
  bool AddPendingResult(PendingResultType type,
                        std::unique_ptr<MethodResult<>> result);
  void ClearPendingResultByType(PendingResultType type);
  void ClearPendingResults();

  // Method handlers
  void CreateCameraMethodHandler(const EncodableMap &args,
                                 std::unique_ptr<MethodResult<>> result);

  void InitializeMethodHandler(const EncodableMap &args,
                               std::unique_ptr<MethodResult<>> result);

  void TakePictureMethodHandler(const EncodableMap &args,
                                std::unique_ptr<MethodResult<>> result);

  void StartVideoRecordingMethodHandler(
      const EncodableMap &args,
      std::unique_ptr<flutter::MethodResult<>> result);

  void StopVideoRecordingMethodHandler(
      const EncodableMap &args,
      std::unique_ptr<flutter::MethodResult<>> result);

  void ResumePreviewMethodHandler(
      const EncodableMap &args,
      std::unique_ptr<flutter::MethodResult<>> result);

  void PausePreviewMethodHandler(
      const EncodableMap &args,
      std::unique_ptr<flutter::MethodResult<>> result);

  void DisposeMethodHandler(const EncodableMap &args,
                            std::unique_ptr<MethodResult<>> result);

  flutter::PluginRegistrarWindows *registrar_;
  std::unique_ptr<CaptureController> capture_controller_;
};

}  // namespace camera_windows

#endif  // PACKAGES_CAMERA_CAMERA_WINDOWS_WINDOWS_CAMERA_PLUGIN_H_
