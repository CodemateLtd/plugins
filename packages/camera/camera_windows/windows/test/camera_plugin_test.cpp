// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <flutter/method_call.h>
#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>
#include <flutter/texture_registrar.h>
#include <gmock/gmock.h>
#include <gtest/gtest.h>
#include <windows.h>

#include <functional>
#include <memory>
#include <string>

#include "mocks.h"

namespace camera_windows {
namespace test {

using flutter::EncodableMap;
using flutter::EncodableValue;
using ::testing::_;
using ::testing::DoAll;
using ::testing::EndsWith;
using ::testing::Eq;
using ::testing::Pointee;
using ::testing::Return;

TEST(CameraPlugin, AvailableCamerasHandlerSuccessIfNoCameras) {
  std::unique_ptr<MockTextureRegistrar> texture_registrar_ =
      std::make_unique<MockTextureRegistrar>();
  std::unique_ptr<MockBinaryMessenger> messenger_ =
      std::make_unique<MockBinaryMessenger>();
  std::unique_ptr<MockCameraFactory> camera_factory_ =
      std::make_unique<MockCameraFactory>();
  std::unique_ptr<MockMethodResult> result =
      std::make_unique<MockMethodResult>();

  MockCameraPlugin plugin(texture_registrar_.get(), messenger_.get(),
                          std::move(camera_factory_));

  EXPECT_CALL(plugin, EnumerateVideoCaptureDeviceSources)
      .Times(1)
      .WillOnce([](IMFActivate*** devices, UINT32* count) {
        *count = 0U;
        *devices = static_cast<IMFActivate**>(
            CoTaskMemAlloc(sizeof(IMFActivate*) * (*count)));
        return true;
      });

  EXPECT_CALL(*result, ErrorInternal).Times(0);
  EXPECT_CALL(*result, SuccessInternal).Times(1);

  plugin.HandleMethodCall(
      flutter::MethodCall("availableCameras",
                          std::make_unique<EncodableValue>()),
      std::move(result));
}

TEST(CameraPlugin, AvailableCamerasHandlerErrorIfFailsToEnumerateDevices) {
  std::unique_ptr<MockTextureRegistrar> texture_registrar_ =
      std::make_unique<MockTextureRegistrar>();
  std::unique_ptr<MockBinaryMessenger> messenger_ =
      std::make_unique<MockBinaryMessenger>();
  std::unique_ptr<MockCameraFactory> camera_factory_ =
      std::make_unique<MockCameraFactory>();
  std::unique_ptr<MockMethodResult> result =
      std::make_unique<MockMethodResult>();

  MockCameraPlugin plugin(texture_registrar_.get(), messenger_.get(),
                          std::move(camera_factory_));

  EXPECT_CALL(plugin, EnumerateVideoCaptureDeviceSources)
      .Times(1)
      .WillOnce([](IMFActivate*** devices, UINT32* count) { return false; });

  EXPECT_CALL(*result, ErrorInternal).Times(1);
  EXPECT_CALL(*result, SuccessInternal).Times(0);

  plugin.HandleMethodCall(
      flutter::MethodCall("availableCameras",
                          std::make_unique<EncodableValue>()),
      std::move(result));
}

TEST(CameraPlugin, CreateHandlerCallsInitCamera) {
  std::unique_ptr<MockMethodResult> result =
      std::make_unique<MockMethodResult>();
  std::unique_ptr<MockTextureRegistrar> texture_registrar_ =
      std::make_unique<MockTextureRegistrar>();
  std::unique_ptr<MockBinaryMessenger> messenger_ =
      std::make_unique<MockBinaryMessenger>();
  std::unique_ptr<MockCameraFactory> camera_factory_ =
      std::make_unique<MockCameraFactory>();
  std::unique_ptr<MockCamera> camera =
      std::make_unique<MockCamera>(MOCK_DEVICE_ID);

  EXPECT_CALL(*camera,
              HasPendingResultByType(Eq(PendingResultType::CREATE_CAMERA)))
      .Times(1)
      .WillOnce(Return(false));

  EXPECT_CALL(*camera,
              AddPendingResult(Eq(PendingResultType::CREATE_CAMERA), _))
      .Times(1)
      .WillOnce([cam = camera.get()](PendingResultType type,
                                     std::unique_ptr<MethodResult<>> result) {
        cam->pending_result_ = std::move(result);
        return true;
      });
  EXPECT_CALL(*camera, InitCamera)
      .Times(1)
      .WillOnce([cam = camera.get()](
                    flutter::TextureRegistrar* texture_registrar,
                    flutter::BinaryMessenger* messenger, bool enable_audio,
                    ResolutionPreset resolution_preset) {
        assert(cam->pending_result_);
        return cam->pending_result_->Success(EncodableValue(1));
      });

  // Move mocked camera to the factory to be passed
  // for plugin with CreateCamera function
  camera_factory_->pending_camera_ = std::move(camera);

  EXPECT_CALL(*camera_factory_, CreateCamera(MOCK_DEVICE_ID));

  EXPECT_CALL(*result, ErrorInternal).Times(0);
  EXPECT_CALL(*result, SuccessInternal(Pointee(EncodableValue(1))));

  CameraPlugin plugin(texture_registrar_.get(), messenger_.get(),
                      std::move(camera_factory_));
  EncodableMap args = {
      {EncodableValue("cameraName"), EncodableValue(MOCK_CAMERA_NAME)},
      {EncodableValue("resolutionPreset"), EncodableValue(nullptr)},
      {EncodableValue("enableAudio"), EncodableValue(true)},
  };

  plugin.HandleMethodCall(
      flutter::MethodCall("create",
                          std::make_unique<EncodableValue>(EncodableMap(args))),
      std::move(result));
}

TEST(CameraPlugin, CreateHandlerErrorOnInvalidDeviceId) {
  std::unique_ptr<MockMethodResult> result =
      std::make_unique<MockMethodResult>();
  std::unique_ptr<MockTextureRegistrar> texture_registrar_ =
      std::make_unique<MockTextureRegistrar>();
  std::unique_ptr<MockBinaryMessenger> messenger_ =
      std::make_unique<MockBinaryMessenger>();
  std::unique_ptr<MockCameraFactory> camera_factory_ =
      std::make_unique<MockCameraFactory>();

  CameraPlugin plugin(texture_registrar_.get(), messenger_.get(),
                      std::move(camera_factory_));
  EncodableMap args = {
      {EncodableValue("cameraName"), EncodableValue(MOCK_INVALID_CAMERA_NAME)},
      {EncodableValue("resolutionPreset"), EncodableValue(nullptr)},
      {EncodableValue("enableAudio"), EncodableValue(true)},
  };

  EXPECT_CALL(*result, ErrorInternal).Times(1);

  plugin.HandleMethodCall(
      flutter::MethodCall("create",
                          std::make_unique<EncodableValue>(EncodableMap(args))),
      std::move(result));
}

TEST(CameraPlugin, CreateHandlerErrorOnExistingDeviceId) {
  std::unique_ptr<MockMethodResult> first_create_result =
      std::make_unique<MockMethodResult>();
  std::unique_ptr<MockMethodResult> second_create_result =
      std::make_unique<MockMethodResult>();
  std::unique_ptr<MockTextureRegistrar> texture_registrar_ =
      std::make_unique<MockTextureRegistrar>();
  std::unique_ptr<MockBinaryMessenger> messenger_ =
      std::make_unique<MockBinaryMessenger>();
  std::unique_ptr<MockCameraFactory> camera_factory_ =
      std::make_unique<MockCameraFactory>();
  std::unique_ptr<MockCamera> camera =
      std::make_unique<MockCamera>(MOCK_DEVICE_ID);

  EXPECT_CALL(*camera,
              HasPendingResultByType(Eq(PendingResultType::CREATE_CAMERA)))
      .Times(1)
      .WillOnce(Return(false));

  EXPECT_CALL(*camera,
              AddPendingResult(Eq(PendingResultType::CREATE_CAMERA), _))
      .Times(1)
      .WillOnce([cam = camera.get()](PendingResultType type,
                                     std::unique_ptr<MethodResult<>> result) {
        cam->pending_result_ = std::move(result);
        return true;
      });
  EXPECT_CALL(*camera, InitCamera)
      .Times(1)
      .WillOnce([cam = camera.get()](
                    flutter::TextureRegistrar* texture_registrar,
                    flutter::BinaryMessenger* messenger, bool enable_audio,
                    ResolutionPreset resolution_preset) {
        assert(cam->pending_result_);
        return cam->pending_result_->Success(EncodableValue(1));
      });

  EXPECT_CALL(*camera, HasDeviceId(Eq(MOCK_DEVICE_ID)))
      .Times(1)
      .WillOnce([cam = camera.get()](std::string& device_id) {
        return cam->device_id_ == device_id;
      });

  // Move mocked camera to the factory to be passed
  // for plugin with CreateCamera function
  camera_factory_->pending_camera_ = std::move(camera);

  EXPECT_CALL(*camera_factory_, CreateCamera(MOCK_DEVICE_ID));

  EXPECT_CALL(*first_create_result, ErrorInternal).Times(0);
  EXPECT_CALL(*first_create_result,
              SuccessInternal(Pointee(EncodableValue(1))));

  CameraPlugin plugin(texture_registrar_.get(), messenger_.get(),
                      std::move(camera_factory_));
  EncodableMap args = {
      {EncodableValue("cameraName"), EncodableValue(MOCK_CAMERA_NAME)},
      {EncodableValue("resolutionPreset"), EncodableValue(nullptr)},
      {EncodableValue("enableAudio"), EncodableValue(true)},
  };

  plugin.HandleMethodCall(
      flutter::MethodCall("create",
                          std::make_unique<EncodableValue>(EncodableMap(args))),
      std::move(first_create_result));

  EXPECT_CALL(*second_create_result, ErrorInternal).Times(1);
  EXPECT_CALL(*second_create_result, SuccessInternal).Times(0);

  plugin.HandleMethodCall(
      flutter::MethodCall("create",
                          std::make_unique<EncodableValue>(EncodableMap(args))),
      std::move(second_create_result));
}

TEST(CameraPlugin, InitializeHandlerCallStartPreview) {
  int64_t mock_camera_id = 1234;

  std::unique_ptr<MockMethodResult> initialize_result =
      std::make_unique<MockMethodResult>();

  std::unique_ptr<MockCamera> camera =
      std::make_unique<MockCamera>(MOCK_DEVICE_ID);

  std::unique_ptr<MockCaptureController> capture_controller =
      std::make_unique<MockCaptureController>();

  EXPECT_CALL(*camera, HasCameraId(Eq(mock_camera_id)))
      .Times(1)
      .WillOnce([cam = camera.get()](int64_t camera_id) {
        return cam->camera_id_ == camera_id;
      });

  EXPECT_CALL(*camera,
              HasPendingResultByType(Eq(PendingResultType::INITIALIZE)))
      .Times(1)
      .WillOnce(Return(false));

  EXPECT_CALL(*camera, AddPendingResult(Eq(PendingResultType::INITIALIZE), _))
      .Times(1)
      .WillOnce([cam = camera.get()](PendingResultType type,
                                     std::unique_ptr<MethodResult<>> result) {
        cam->pending_result_ = std::move(result);
        return true;
      });

  EXPECT_CALL(*camera, GetCaptureController)
      .Times(1)
      .WillOnce([cam = camera.get()]() {
        assert(cam->pending_result_);
        return cam->capture_controller_.get();
      });

  EXPECT_CALL(*capture_controller, StartPreview())
      .Times(1)
      .WillOnce([cam = camera.get()]() {
        assert(cam->pending_result_);
        return cam->pending_result_->Success();
      });

  camera->camera_id_ = mock_camera_id;
  camera->capture_controller_ = std::move(capture_controller);

  MockCameraPlugin plugin(std::make_unique<MockTextureRegistrar>().get(),
                          std::make_unique<MockBinaryMessenger>().get(),
                          std::make_unique<MockCameraFactory>());

  // Add mocked camera to plugins camera list
  plugin.AddCamera(std::move(camera));

  EXPECT_CALL(*initialize_result, ErrorInternal).Times(0);
  EXPECT_CALL(*initialize_result, SuccessInternal).Times(1);

  EncodableMap args = {
      {EncodableValue("cameraId"), EncodableValue(mock_camera_id)},
  };

  plugin.HandleMethodCall(
      flutter::MethodCall("initialize",
                          std::make_unique<EncodableValue>(EncodableMap(args))),
      std::move(initialize_result));
}

TEST(CameraPlugin, InitializeHandlerErrorOnInvalidCameraId) {
  int64_t mock_camera_id = 1234;
  int64_t missing_camera_id = 5678;

  std::unique_ptr<MockMethodResult> initialize_result =
      std::make_unique<MockMethodResult>();

  std::unique_ptr<MockCamera> camera =
      std::make_unique<MockCamera>(MOCK_DEVICE_ID);

  std::unique_ptr<MockCaptureController> capture_controller =
      std::make_unique<MockCaptureController>();

  EXPECT_CALL(*camera, HasCameraId)
      .Times(1)
      .WillOnce([cam = camera.get()](int64_t camera_id) {
        return cam->camera_id_ == camera_id;
      });

  EXPECT_CALL(*camera, HasPendingResultByType).Times(0);
  EXPECT_CALL(*camera, AddPendingResult).Times(0);
  EXPECT_CALL(*camera, GetCaptureController).Times(0);
  EXPECT_CALL(*capture_controller, StartPreview).Times(0);

  camera->camera_id_ = mock_camera_id;

  MockCameraPlugin plugin(std::make_unique<MockTextureRegistrar>().get(),
                          std::make_unique<MockBinaryMessenger>().get(),
                          std::make_unique<MockCameraFactory>());

  // Add mocked camera to plugins camera list
  plugin.AddCamera(std::move(camera));

  EXPECT_CALL(*initialize_result, ErrorInternal).Times(1);
  EXPECT_CALL(*initialize_result, SuccessInternal).Times(0);

  EncodableMap args = {
      {EncodableValue("cameraId"), EncodableValue(missing_camera_id)},
  };

  plugin.HandleMethodCall(
      flutter::MethodCall("initialize",
                          std::make_unique<EncodableValue>(EncodableMap(args))),
      std::move(initialize_result));
}

TEST(CameraPlugin, TakePictureHandlerCallsTakePictureWithPath) {
  int64_t mock_camera_id = 1234;

  std::unique_ptr<MockMethodResult> initialize_result =
      std::make_unique<MockMethodResult>();

  std::unique_ptr<MockCamera> camera =
      std::make_unique<MockCamera>(MOCK_DEVICE_ID);

  std::unique_ptr<MockCaptureController> capture_controller =
      std::make_unique<MockCaptureController>();

  EXPECT_CALL(*camera, HasCameraId(Eq(mock_camera_id)))
      .Times(1)
      .WillOnce([cam = camera.get()](int64_t camera_id) {
        return cam->camera_id_ == camera_id;
      });

  EXPECT_CALL(*camera,
              HasPendingResultByType(Eq(PendingResultType::TAKE_PICTURE)))
      .Times(1)
      .WillOnce(Return(false));

  EXPECT_CALL(*camera, AddPendingResult(Eq(PendingResultType::TAKE_PICTURE), _))
      .Times(1)
      .WillOnce([cam = camera.get()](PendingResultType type,
                                     std::unique_ptr<MethodResult<>> result) {
        cam->pending_result_ = std::move(result);
        return true;
      });

  EXPECT_CALL(*camera, GetCaptureController)
      .Times(1)
      .WillOnce([cam = camera.get()]() {
        assert(cam->pending_result_);
        return cam->capture_controller_.get();
      });

  EXPECT_CALL(*capture_controller, TakePicture(EndsWith(".jpeg")))
      .Times(1)
      .WillOnce([cam = camera.get()](const std::string filepath) {
        assert(cam->pending_result_);
        return cam->pending_result_->Success();
      });

  camera->camera_id_ = mock_camera_id;
  camera->capture_controller_ = std::move(capture_controller);

  MockCameraPlugin plugin(std::make_unique<MockTextureRegistrar>().get(),
                          std::make_unique<MockBinaryMessenger>().get(),
                          std::make_unique<MockCameraFactory>());

  // Add mocked camera to plugins camera list
  plugin.AddCamera(std::move(camera));

  EXPECT_CALL(*initialize_result, ErrorInternal).Times(0);
  EXPECT_CALL(*initialize_result, SuccessInternal).Times(1);

  EncodableMap args = {
      {EncodableValue("cameraId"), EncodableValue(mock_camera_id)},
  };

  plugin.HandleMethodCall(
      flutter::MethodCall("takePicture",
                          std::make_unique<EncodableValue>(EncodableMap(args))),
      std::move(initialize_result));
}

TEST(CameraPlugin, TakePictureHandlerErrorOnInvalidCameraId) {
  int64_t mock_camera_id = 1234;
  int64_t missing_camera_id = 5678;

  std::unique_ptr<MockMethodResult> initialize_result =
      std::make_unique<MockMethodResult>();

  std::unique_ptr<MockCamera> camera =
      std::make_unique<MockCamera>(MOCK_DEVICE_ID);

  std::unique_ptr<MockCaptureController> capture_controller =
      std::make_unique<MockCaptureController>();

  EXPECT_CALL(*camera, HasCameraId)
      .Times(1)
      .WillOnce([cam = camera.get()](int64_t camera_id) {
        return cam->camera_id_ == camera_id;
      });

  EXPECT_CALL(*camera, HasPendingResultByType).Times(0);
  EXPECT_CALL(*camera, AddPendingResult).Times(0);
  EXPECT_CALL(*camera, GetCaptureController).Times(0);
  EXPECT_CALL(*capture_controller, TakePicture).Times(0);

  camera->camera_id_ = mock_camera_id;

  MockCameraPlugin plugin(std::make_unique<MockTextureRegistrar>().get(),
                          std::make_unique<MockBinaryMessenger>().get(),
                          std::make_unique<MockCameraFactory>());

  // Add mocked camera to plugins camera list
  plugin.AddCamera(std::move(camera));

  EXPECT_CALL(*initialize_result, ErrorInternal).Times(1);
  EXPECT_CALL(*initialize_result, SuccessInternal).Times(0);

  EncodableMap args = {
      {EncodableValue("cameraId"), EncodableValue(missing_camera_id)},
  };

  plugin.HandleMethodCall(
      flutter::MethodCall("takePicture",
                          std::make_unique<EncodableValue>(EncodableMap(args))),
      std::move(initialize_result));
}

TEST(CameraPlugin, StartVideoRecordingHandlerCallsStartRecordWithPath) {
  int64_t mock_camera_id = 1234;

  std::unique_ptr<MockMethodResult> initialize_result =
      std::make_unique<MockMethodResult>();

  std::unique_ptr<MockCamera> camera =
      std::make_unique<MockCamera>(MOCK_DEVICE_ID);

  std::unique_ptr<MockCaptureController> capture_controller =
      std::make_unique<MockCaptureController>();

  EXPECT_CALL(*camera, HasCameraId(Eq(mock_camera_id)))
      .Times(1)
      .WillOnce([cam = camera.get()](int64_t camera_id) {
        return cam->camera_id_ == camera_id;
      });

  EXPECT_CALL(*camera,
              HasPendingResultByType(Eq(PendingResultType::START_RECORD)))
      .Times(1)
      .WillOnce(Return(false));

  EXPECT_CALL(*camera, AddPendingResult(Eq(PendingResultType::START_RECORD), _))
      .Times(1)
      .WillOnce([cam = camera.get()](PendingResultType type,
                                     std::unique_ptr<MethodResult<>> result) {
        cam->pending_result_ = std::move(result);
        return true;
      });

  EXPECT_CALL(*camera, GetCaptureController)
      .Times(1)
      .WillOnce([cam = camera.get()]() {
        assert(cam->pending_result_);
        return cam->capture_controller_.get();
      });

  EXPECT_CALL(*capture_controller, StartRecord(EndsWith(".mp4"), -1))
      .Times(1)
      .WillOnce([cam = camera.get()](const std::string filepath,
                                     int64_t max_video_duration_ms) {
        assert(cam->pending_result_);
        return cam->pending_result_->Success();
      });

  camera->camera_id_ = mock_camera_id;
  camera->capture_controller_ = std::move(capture_controller);

  MockCameraPlugin plugin(std::make_unique<MockTextureRegistrar>().get(),
                          std::make_unique<MockBinaryMessenger>().get(),
                          std::make_unique<MockCameraFactory>());

  // Add mocked camera to plugins camera list
  plugin.AddCamera(std::move(camera));

  EXPECT_CALL(*initialize_result, ErrorInternal).Times(0);
  EXPECT_CALL(*initialize_result, SuccessInternal).Times(1);

  EncodableMap args = {
      {EncodableValue("cameraId"), EncodableValue(mock_camera_id)},
  };

  plugin.HandleMethodCall(
      flutter::MethodCall("startVideoRecording",
                          std::make_unique<EncodableValue>(EncodableMap(args))),
      std::move(initialize_result));
}

TEST(CameraPlugin,
     StartVideoRecordingHandlerCallsStartRecordWithPathAndCaptureDuration) {
  int64_t mock_camera_id = 1234;
  int32_t mock_video_duration = 100000;

  std::unique_ptr<MockMethodResult> initialize_result =
      std::make_unique<MockMethodResult>();

  std::unique_ptr<MockCamera> camera =
      std::make_unique<MockCamera>(MOCK_DEVICE_ID);

  std::unique_ptr<MockCaptureController> capture_controller =
      std::make_unique<MockCaptureController>();

  EXPECT_CALL(*camera, HasCameraId(Eq(mock_camera_id)))
      .Times(1)
      .WillOnce([cam = camera.get()](int64_t camera_id) {
        return cam->camera_id_ == camera_id;
      });

  EXPECT_CALL(*camera,
              HasPendingResultByType(Eq(PendingResultType::START_RECORD)))
      .Times(1)
      .WillOnce(Return(false));

  EXPECT_CALL(*camera, AddPendingResult(Eq(PendingResultType::START_RECORD), _))
      .Times(1)
      .WillOnce([cam = camera.get()](PendingResultType type,
                                     std::unique_ptr<MethodResult<>> result) {
        cam->pending_result_ = std::move(result);
        return true;
      });

  EXPECT_CALL(*camera, GetCaptureController)
      .Times(1)
      .WillOnce([cam = camera.get()]() {
        assert(cam->pending_result_);
        return cam->capture_controller_.get();
      });

  EXPECT_CALL(*capture_controller,
              StartRecord(EndsWith(".mp4"), Eq(mock_video_duration)))
      .Times(1)
      .WillOnce([cam = camera.get()](const std::string filepath,
                                     int64_t max_video_duration_ms) {
        assert(cam->pending_result_);
        return cam->pending_result_->Success();
      });

  camera->camera_id_ = mock_camera_id;
  camera->capture_controller_ = std::move(capture_controller);

  MockCameraPlugin plugin(std::make_unique<MockTextureRegistrar>().get(),
                          std::make_unique<MockBinaryMessenger>().get(),
                          std::make_unique<MockCameraFactory>());

  // Add mocked camera to plugins camera list
  plugin.AddCamera(std::move(camera));

  EXPECT_CALL(*initialize_result, ErrorInternal).Times(0);
  EXPECT_CALL(*initialize_result, SuccessInternal).Times(1);

  EncodableMap args = {
      {EncodableValue("cameraId"), EncodableValue(mock_camera_id)},
      {EncodableValue("maxVideoDuration"), EncodableValue(mock_video_duration)},
  };

  plugin.HandleMethodCall(
      flutter::MethodCall("startVideoRecording",
                          std::make_unique<EncodableValue>(EncodableMap(args))),
      std::move(initialize_result));
}

TEST(CameraPlugin, StartVideoRecordingHandlerErrorOnInvalidCameraId) {
  int64_t mock_camera_id = 1234;
  int64_t missing_camera_id = 5678;

  std::unique_ptr<MockMethodResult> initialize_result =
      std::make_unique<MockMethodResult>();

  std::unique_ptr<MockCamera> camera =
      std::make_unique<MockCamera>(MOCK_DEVICE_ID);

  std::unique_ptr<MockCaptureController> capture_controller =
      std::make_unique<MockCaptureController>();

  EXPECT_CALL(*camera, HasCameraId)
      .Times(1)
      .WillOnce([cam = camera.get()](int64_t camera_id) {
        return cam->camera_id_ == camera_id;
      });

  EXPECT_CALL(*camera, HasPendingResultByType).Times(0);
  EXPECT_CALL(*camera, AddPendingResult).Times(0);
  EXPECT_CALL(*camera, GetCaptureController).Times(0);
  EXPECT_CALL(*capture_controller, StartRecord(_, -1)).Times(0);

  camera->camera_id_ = mock_camera_id;

  MockCameraPlugin plugin(std::make_unique<MockTextureRegistrar>().get(),
                          std::make_unique<MockBinaryMessenger>().get(),
                          std::make_unique<MockCameraFactory>());

  // Add mocked camera to plugins camera list
  plugin.AddCamera(std::move(camera));

  EXPECT_CALL(*initialize_result, ErrorInternal).Times(1);
  EXPECT_CALL(*initialize_result, SuccessInternal).Times(0);

  EncodableMap args = {
      {EncodableValue("cameraId"), EncodableValue(missing_camera_id)},
  };

  plugin.HandleMethodCall(
      flutter::MethodCall("startVideoRecording",
                          std::make_unique<EncodableValue>(EncodableMap(args))),
      std::move(initialize_result));
}

TEST(CameraPlugin, StopVideoRecordingHandlerCallsStopRecord) {
  int64_t mock_camera_id = 1234;

  std::unique_ptr<MockMethodResult> initialize_result =
      std::make_unique<MockMethodResult>();

  std::unique_ptr<MockCamera> camera =
      std::make_unique<MockCamera>(MOCK_DEVICE_ID);

  std::unique_ptr<MockCaptureController> capture_controller =
      std::make_unique<MockCaptureController>();

  EXPECT_CALL(*camera, HasCameraId(Eq(mock_camera_id)))
      .Times(1)
      .WillOnce([cam = camera.get()](int64_t camera_id) {
        return cam->camera_id_ == camera_id;
      });

  EXPECT_CALL(*camera,
              HasPendingResultByType(Eq(PendingResultType::STOP_RECORD)))
      .Times(1)
      .WillOnce(Return(false));

  EXPECT_CALL(*camera, AddPendingResult(Eq(PendingResultType::STOP_RECORD), _))
      .Times(1)
      .WillOnce([cam = camera.get()](PendingResultType type,
                                     std::unique_ptr<MethodResult<>> result) {
        cam->pending_result_ = std::move(result);
        return true;
      });

  EXPECT_CALL(*camera, GetCaptureController)
      .Times(1)
      .WillOnce([cam = camera.get()]() {
        assert(cam->pending_result_);
        return cam->capture_controller_.get();
      });

  EXPECT_CALL(*capture_controller, StopRecord)
      .Times(1)
      .WillOnce([cam = camera.get()]() {
        assert(cam->pending_result_);
        return cam->pending_result_->Success();
      });

  camera->camera_id_ = mock_camera_id;
  camera->capture_controller_ = std::move(capture_controller);

  MockCameraPlugin plugin(std::make_unique<MockTextureRegistrar>().get(),
                          std::make_unique<MockBinaryMessenger>().get(),
                          std::make_unique<MockCameraFactory>());

  // Add mocked camera to plugins camera list
  plugin.AddCamera(std::move(camera));

  EXPECT_CALL(*initialize_result, ErrorInternal).Times(0);
  EXPECT_CALL(*initialize_result, SuccessInternal).Times(1);

  EncodableMap args = {
      {EncodableValue("cameraId"), EncodableValue(mock_camera_id)},
  };

  plugin.HandleMethodCall(
      flutter::MethodCall("stopVideoRecording",
                          std::make_unique<EncodableValue>(EncodableMap(args))),
      std::move(initialize_result));
}

TEST(CameraPlugin, StopVideoRecordingHandlerErrorOnInvalidCameraId) {
  int64_t mock_camera_id = 1234;
  int64_t missing_camera_id = 5678;

  std::unique_ptr<MockMethodResult> initialize_result =
      std::make_unique<MockMethodResult>();

  std::unique_ptr<MockCamera> camera =
      std::make_unique<MockCamera>(MOCK_DEVICE_ID);

  std::unique_ptr<MockCaptureController> capture_controller =
      std::make_unique<MockCaptureController>();

  EXPECT_CALL(*camera, HasCameraId)
      .Times(1)
      .WillOnce([cam = camera.get()](int64_t camera_id) {
        return cam->camera_id_ == camera_id;
      });

  EXPECT_CALL(*camera, HasPendingResultByType).Times(0);
  EXPECT_CALL(*camera, AddPendingResult).Times(0);
  EXPECT_CALL(*camera, GetCaptureController).Times(0);
  EXPECT_CALL(*capture_controller, StopRecord).Times(0);

  camera->camera_id_ = mock_camera_id;

  MockCameraPlugin plugin(std::make_unique<MockTextureRegistrar>().get(),
                          std::make_unique<MockBinaryMessenger>().get(),
                          std::make_unique<MockCameraFactory>());

  // Add mocked camera to plugins camera list
  plugin.AddCamera(std::move(camera));

  EXPECT_CALL(*initialize_result, ErrorInternal).Times(1);
  EXPECT_CALL(*initialize_result, SuccessInternal).Times(0);

  EncodableMap args = {
      {EncodableValue("cameraId"), EncodableValue(missing_camera_id)},
  };

  plugin.HandleMethodCall(
      flutter::MethodCall("stopVideoRecording",
                          std::make_unique<EncodableValue>(EncodableMap(args))),
      std::move(initialize_result));
}

TEST(CameraPlugin, ResumePreviewHandlerCallsResumePreview) {
  int64_t mock_camera_id = 1234;

  std::unique_ptr<MockMethodResult> initialize_result =
      std::make_unique<MockMethodResult>();

  std::unique_ptr<MockCamera> camera =
      std::make_unique<MockCamera>(MOCK_DEVICE_ID);

  std::unique_ptr<MockCaptureController> capture_controller =
      std::make_unique<MockCaptureController>();

  EXPECT_CALL(*camera, HasCameraId(Eq(mock_camera_id)))
      .Times(1)
      .WillOnce([cam = camera.get()](int64_t camera_id) {
        return cam->camera_id_ == camera_id;
      });

  EXPECT_CALL(*camera,
              HasPendingResultByType(Eq(PendingResultType::RESUME_PREVIEW)))
      .Times(1)
      .WillOnce(Return(false));

  EXPECT_CALL(*camera,
              AddPendingResult(Eq(PendingResultType::RESUME_PREVIEW), _))
      .Times(1)
      .WillOnce([cam = camera.get()](PendingResultType type,
                                     std::unique_ptr<MethodResult<>> result) {
        cam->pending_result_ = std::move(result);
        return true;
      });

  EXPECT_CALL(*camera, GetCaptureController)
      .Times(1)
      .WillOnce([cam = camera.get()]() {
        assert(cam->pending_result_);
        return cam->capture_controller_.get();
      });

  EXPECT_CALL(*capture_controller, ResumePreview)
      .Times(1)
      .WillOnce([cam = camera.get()]() {
        assert(cam->pending_result_);
        return cam->pending_result_->Success();
      });

  camera->camera_id_ = mock_camera_id;
  camera->capture_controller_ = std::move(capture_controller);

  MockCameraPlugin plugin(std::make_unique<MockTextureRegistrar>().get(),
                          std::make_unique<MockBinaryMessenger>().get(),
                          std::make_unique<MockCameraFactory>());

  // Add mocked camera to plugins camera list
  plugin.AddCamera(std::move(camera));

  EXPECT_CALL(*initialize_result, ErrorInternal).Times(0);
  EXPECT_CALL(*initialize_result, SuccessInternal).Times(1);

  EncodableMap args = {
      {EncodableValue("cameraId"), EncodableValue(mock_camera_id)},
  };

  plugin.HandleMethodCall(
      flutter::MethodCall("resumePreview",
                          std::make_unique<EncodableValue>(EncodableMap(args))),
      std::move(initialize_result));
}

TEST(CameraPlugin, ResumePreviewHandlerErrorOnInvalidCameraId) {
  int64_t mock_camera_id = 1234;
  int64_t missing_camera_id = 5678;

  std::unique_ptr<MockMethodResult> initialize_result =
      std::make_unique<MockMethodResult>();

  std::unique_ptr<MockCamera> camera =
      std::make_unique<MockCamera>(MOCK_DEVICE_ID);

  std::unique_ptr<MockCaptureController> capture_controller =
      std::make_unique<MockCaptureController>();

  EXPECT_CALL(*camera, HasCameraId)
      .Times(1)
      .WillOnce([cam = camera.get()](int64_t camera_id) {
        return cam->camera_id_ == camera_id;
      });

  EXPECT_CALL(*camera, HasPendingResultByType).Times(0);
  EXPECT_CALL(*camera, AddPendingResult).Times(0);
  EXPECT_CALL(*camera, GetCaptureController).Times(0);
  EXPECT_CALL(*capture_controller, ResumePreview).Times(0);

  camera->camera_id_ = mock_camera_id;

  MockCameraPlugin plugin(std::make_unique<MockTextureRegistrar>().get(),
                          std::make_unique<MockBinaryMessenger>().get(),
                          std::make_unique<MockCameraFactory>());

  // Add mocked camera to plugins camera list
  plugin.AddCamera(std::move(camera));

  EXPECT_CALL(*initialize_result, ErrorInternal).Times(1);
  EXPECT_CALL(*initialize_result, SuccessInternal).Times(0);

  EncodableMap args = {
      {EncodableValue("cameraId"), EncodableValue(missing_camera_id)},
  };

  plugin.HandleMethodCall(
      flutter::MethodCall("resumePreview",
                          std::make_unique<EncodableValue>(EncodableMap(args))),
      std::move(initialize_result));
}

TEST(CameraPlugin, PausePreviewHandlerCallsPausePreview) {
  int64_t mock_camera_id = 1234;

  std::unique_ptr<MockMethodResult> initialize_result =
      std::make_unique<MockMethodResult>();

  std::unique_ptr<MockCamera> camera =
      std::make_unique<MockCamera>(MOCK_DEVICE_ID);

  std::unique_ptr<MockCaptureController> capture_controller =
      std::make_unique<MockCaptureController>();

  EXPECT_CALL(*camera, HasCameraId(Eq(mock_camera_id)))
      .Times(1)
      .WillOnce([cam = camera.get()](int64_t camera_id) {
        return cam->camera_id_ == camera_id;
      });

  EXPECT_CALL(*camera,
              HasPendingResultByType(Eq(PendingResultType::PAUSE_PREVIEW)))
      .Times(1)
      .WillOnce(Return(false));

  EXPECT_CALL(*camera,
              AddPendingResult(Eq(PendingResultType::PAUSE_PREVIEW), _))
      .Times(1)
      .WillOnce([cam = camera.get()](PendingResultType type,
                                     std::unique_ptr<MethodResult<>> result) {
        cam->pending_result_ = std::move(result);
        return true;
      });

  EXPECT_CALL(*camera, GetCaptureController)
      .Times(1)
      .WillOnce([cam = camera.get()]() {
        assert(cam->pending_result_);
        return cam->capture_controller_.get();
      });

  EXPECT_CALL(*capture_controller, PausePreview)
      .Times(1)
      .WillOnce([cam = camera.get()]() {
        assert(cam->pending_result_);
        return cam->pending_result_->Success();
      });

  camera->camera_id_ = mock_camera_id;
  camera->capture_controller_ = std::move(capture_controller);

  MockCameraPlugin plugin(std::make_unique<MockTextureRegistrar>().get(),
                          std::make_unique<MockBinaryMessenger>().get(),
                          std::make_unique<MockCameraFactory>());

  // Add mocked camera to plugins camera list
  plugin.AddCamera(std::move(camera));

  EXPECT_CALL(*initialize_result, ErrorInternal).Times(0);
  EXPECT_CALL(*initialize_result, SuccessInternal).Times(1);

  EncodableMap args = {
      {EncodableValue("cameraId"), EncodableValue(mock_camera_id)},
  };

  plugin.HandleMethodCall(
      flutter::MethodCall("pausePreview",
                          std::make_unique<EncodableValue>(EncodableMap(args))),
      std::move(initialize_result));
}

TEST(CameraPlugin, PausePreviewHandlerErrorOnInvalidCameraId) {
  int64_t mock_camera_id = 1234;
  int64_t missing_camera_id = 5678;

  std::unique_ptr<MockMethodResult> initialize_result =
      std::make_unique<MockMethodResult>();

  std::unique_ptr<MockCamera> camera =
      std::make_unique<MockCamera>(MOCK_DEVICE_ID);

  std::unique_ptr<MockCaptureController> capture_controller =
      std::make_unique<MockCaptureController>();

  EXPECT_CALL(*camera, HasCameraId)
      .Times(1)
      .WillOnce([cam = camera.get()](int64_t camera_id) {
        return cam->camera_id_ == camera_id;
      });

  EXPECT_CALL(*camera, HasPendingResultByType).Times(0);
  EXPECT_CALL(*camera, AddPendingResult).Times(0);
  EXPECT_CALL(*camera, GetCaptureController).Times(0);
  EXPECT_CALL(*capture_controller, PausePreview).Times(0);

  camera->camera_id_ = mock_camera_id;

  MockCameraPlugin plugin(std::make_unique<MockTextureRegistrar>().get(),
                          std::make_unique<MockBinaryMessenger>().get(),
                          std::make_unique<MockCameraFactory>());

  // Add mocked camera to plugins camera list
  plugin.AddCamera(std::move(camera));

  EXPECT_CALL(*initialize_result, ErrorInternal).Times(1);
  EXPECT_CALL(*initialize_result, SuccessInternal).Times(0);

  EncodableMap args = {
      {EncodableValue("cameraId"), EncodableValue(missing_camera_id)},
  };

  plugin.HandleMethodCall(
      flutter::MethodCall("pausePreview",
                          std::make_unique<EncodableValue>(EncodableMap(args))),
      std::move(initialize_result));
}

}  // namespace test
}  // namespace camera_windows
