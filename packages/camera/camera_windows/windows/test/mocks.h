// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef PACKAGES_CAMERA_CAMERA_WINDOWS_WINDOWS_TEST_MOCKS_H_
#define PACKAGES_CAMERA_CAMERA_WINDOWS_WINDOWS_TEST_MOCKS_H_

#include <flutter/method_call.h>
#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>
#include <flutter/texture_registrar.h>
#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "camera.h"
#include "camera_plugin.h"

namespace camera_windows {
namespace test {

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;
using ::testing::_;
using ::testing::ByMove;
using ::testing::DoAll;
using ::testing::EndsWith;
using ::testing::Eq;
using ::testing::Pointee;
using ::testing::Return;
using ::testing::SetArgPointee;

class MockMethodResult : public flutter::MethodResult<> {
 public:
  MOCK_METHOD(void, SuccessInternal, (const EncodableValue* result),
              (override));
  MOCK_METHOD(void, ErrorInternal,
              (const std::string& error_code, const std::string& error_message,
               const EncodableValue* details),
              (override));
  MOCK_METHOD(void, NotImplementedInternal, (), (override));
};

class MockTextureRegistrar : public flutter::TextureRegistrar {
 public:
  MockTextureRegistrar() {
    ON_CALL(*this, RegisterTexture)
        .WillByDefault([this](flutter::TextureVariant* texture) -> int64_t {
          this->texture_id = 1000;
          return this->texture_id;
        });
    ON_CALL(*this, UnregisterTexture)
        .WillByDefault([this](int64_t tid) -> bool {
          if (tid == this->texture_id) {
            this->texture_id = -1;
            return true;
          }
          return false;
        });
    ON_CALL(*this, MarkTextureFrameAvailable)
        .WillByDefault([this](int64_t tid) -> bool {
          if (tid == this->texture_id) {
            return true;
          }
          return false;
        });
  }
  MOCK_METHOD(int64_t, RegisterTexture, (flutter::TextureVariant * texture),
              (override));

  MOCK_METHOD(bool, UnregisterTexture, (int64_t), (override));
  MOCK_METHOD(bool, MarkTextureFrameAvailable, (int64_t), (override));
  int64_t texture_id = -1;
};

class MockCameraFactory : public CameraFactory {
 public:
  MockCameraFactory() {
    ON_CALL(*this, CreateCamera).WillByDefault([this]() {
      assert(this->pending_camera_);
      return std::move(this->pending_camera_);
    });
  }

  MOCK_METHOD(std::unique_ptr<Camera>, CreateCamera,
              (const std::string& device_id), (override));

  std::unique_ptr<Camera> pending_camera_;
};

class MockCamera : public CameraImpl {
 public:
  MockCamera(const std::string& device_id)
      : device_id_(device_id), CameraImpl(device_id){};
  ~MockCamera() = default;

  MockCamera(const MockCamera&) = delete;
  MockCamera& operator=(const MockCamera&) = delete;

  void DelegateToReal() {
    ON_CALL(*this, AddPendingResult)
        .WillByDefault([this](PendingResultType type,
                              std::unique_ptr<MethodResult<>> result) {
          return CameraImpl::AddPendingResult(type, std::move(result));
        });
    ON_CALL(*this, HasPendingResultByType)
        .WillByDefault([this](PendingResultType type) {
          return CameraImpl::HasPendingResultByType(type);
        });
    ON_CALL(*this, OnCreateCaptureEngineSucceeded)
        .WillByDefault([this](int64_t texture_id) {
          CameraImpl::OnCreateCaptureEngineSucceeded(texture_id);
        });

    ON_CALL(*this, GetPendingResultByType)
        .WillByDefault([this](PendingResultType type) {
          return CameraImpl::GetPendingResultByType(type);
        });
  }

  MOCK_METHOD(void, OnCreateCaptureEngineSucceeded, (int64_t texture_id),
              (override));
  MOCK_METHOD(std::unique_ptr<flutter::MethodResult<>>, GetPendingResultByType,
              (PendingResultType type));
  MOCK_METHOD(void, OnCreateCaptureEngineFailed, (const std::string& error),
              (override));

  MOCK_METHOD(void, OnStartPreviewSucceeded, (int32_t width, int32_t height),
              (override));
  MOCK_METHOD(void, OnStartPreviewFailed, (const std::string& error),
              (override));

  MOCK_METHOD(void, OnResumePreviewSucceeded, (), (override));
  MOCK_METHOD(void, OnResumePreviewFailed, (const std::string& error),
              (override));

  MOCK_METHOD(void, OnPausePreviewSucceeded, (), (override));
  MOCK_METHOD(void, OnPausePreviewFailed, (const std::string& error),
              (override));

  MOCK_METHOD(void, OnStartRecordSucceeded, (), (override));
  MOCK_METHOD(void, OnStartRecordFailed, (const std::string& error),
              (override));

  MOCK_METHOD(void, OnStopRecordSucceeded, (const std::string& filepath),
              (override));
  MOCK_METHOD(void, OnStopRecordFailed, (const std::string& error), (override));

  MOCK_METHOD(void, OnPictureSuccess, (const std::string& filepath),
              (override));
  MOCK_METHOD(void, OnPictureFailed, (const std::string& error), (override));

  MOCK_METHOD(bool, HasDeviceId, (std::string & device_id), (override));
  MOCK_METHOD(bool, HasCameraId, (int64_t camera_id), (override));

  MOCK_METHOD(bool, AddPendingResult,
              (PendingResultType type, std::unique_ptr<MethodResult<>> result),
              (override));
  MOCK_METHOD(bool, HasPendingResultByType, (PendingResultType type),
              (override));

  MOCK_METHOD(camera_windows::CaptureController*, GetCaptureController, (),
              (override));

  MOCK_METHOD(void, InitCamera,
              (flutter::TextureRegistrar * texture_registrar, bool enable_audio,
               ResolutionPreset resolution_preset),
              (override));

  std::unique_ptr<CaptureController> capture_controller_;
  std::unique_ptr<MethodResult<>> pending_result_;
  std::string device_id_;
  int64_t camera_id_ = -1;
};

class MockCaptureController : public CaptureController {
 public:
  MOCK_METHOD(void, CreateCaptureDevice,
              (flutter::TextureRegistrar * texture_registrar,
               const std::string& device_id, bool enable_audio,
               ResolutionPreset resolution_preset),
              (override));

  MOCK_METHOD(int64_t, GetTextureId, (), (override));
  MOCK_METHOD(uint32_t, GetPreviewWidth, (), (override));
  MOCK_METHOD(uint32_t, GetPreviewHeight, (), (override));

  // Actions
  MOCK_METHOD(void, StartPreview, (), (override));
  MOCK_METHOD(void, StopPreview, (), (override));
  MOCK_METHOD(void, ResumePreview, (), (override));
  MOCK_METHOD(void, PausePreview, (), (override));
  MOCK_METHOD(void, StartRecord,
              (const std::string& filepath, int64_t max_capture_duration),
              (override));
  MOCK_METHOD(void, StopRecord, (), (override));
  MOCK_METHOD(void, TakePicture, (const std::string filepath), (override));
};

// MockCameraPlugin extends CameraPlugin behaviour a bit to allow adding cameras
// without creating them first with create message handler and mocking static
// system calls
class MockCameraPlugin : public CameraPlugin {
 public:
  MockCameraPlugin(flutter::TextureRegistrar* texture_registrar)
      : CameraPlugin(texture_registrar){};

  // Creates a plugin instance with the given CameraFactory instance.
  // Exists for unit testing with mock implementations.
  MockCameraPlugin(flutter::TextureRegistrar* texture_registrar,
                   std::unique_ptr<CameraFactory> camera_factory)
      : CameraPlugin(texture_registrar, std::move(camera_factory)){};

  MockCameraPlugin(const MockCameraPlugin&) = delete;
  MockCameraPlugin& operator=(const MockCameraPlugin&) = delete;

  MOCK_METHOD(bool, EnumerateVideoCaptureDeviceSources,
              (IMFActivate * **devices, UINT32* count), (override));

  // Helper to add camera without creating it via CameraFactory for testing
  // purposes
  void AddCamera(std::unique_ptr<Camera> camera) {
    cameras_.push_back(std::move(camera));
  }
};

#define MOCK_DEVICE_ID "mock_device_id"
#define MOCK_CAMERA_NAME "mock_camera_name <" MOCK_DEVICE_ID ">"
#define MOCK_INVALID_CAMERA_NAME "invalid_camera_name"
}  // namespace
}  // namespace test
}  // namespace camera_windows

#endif  // PACKAGES_CAMERA_CAMERA_WINDOWS_WINDOWS_TEST_MOCKS_H_
