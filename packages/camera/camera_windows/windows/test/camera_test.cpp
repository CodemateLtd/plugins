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

TEST(Camera, AddPendingResultReturnsErrorForDuplicates) {
  std::unique_ptr<MockCamera> camera =
      std::make_unique<MockCamera>(MOCK_DEVICE_ID);
  std::unique_ptr<MockMethodResult> first_pending_result =
      std::make_unique<MockMethodResult>();
  std::unique_ptr<MockMethodResult> second_pending_result =
      std::make_unique<MockMethodResult>();

  camera->DelegateToReal();

  EXPECT_CALL(*camera, AddPendingResult).Times(2);
  EXPECT_CALL(*camera, GetPendingResultByType).Times(1);
  EXPECT_CALL(*first_pending_result, ErrorInternal).Times(0);
  EXPECT_CALL(*first_pending_result, SuccessInternal);
  EXPECT_CALL(*second_pending_result, ErrorInternal).Times(1);

  camera->AddPendingResult(PendingResultType::CREATE_CAMERA,
                           std::move(first_pending_result));

  // This should fail
  camera->AddPendingResult(PendingResultType::CREATE_CAMERA,
                           std::move(second_pending_result));

  // Get pending result and mark it as succeeded
  camera->GetPendingResultByType(PendingResultType::CREATE_CAMERA)->Success();
}

TEST(Camera, OnCreateCaptureEngineSucceededReturnCameraId) {
  std::unique_ptr<MockCamera> camera =
      std::make_unique<MockCamera>(MOCK_DEVICE_ID);
  std::unique_ptr<MockMethodResult> result =
      std::make_unique<MockMethodResult>();

  camera->DelegateToReal();

  const int64_t texture_id = 12345;

  EXPECT_CALL(*camera, AddPendingResult).Times(1);
  EXPECT_CALL(*camera, OnCreateCaptureEngineSucceeded).Times(1);
  EXPECT_CALL(*result, ErrorInternal).Times(0);
  EXPECT_CALL(
      *result,
      SuccessInternal(Pointee(EncodableValue(EncodableMap(
          {{EncodableValue("cameraId"), EncodableValue(texture_id)}})))));

  camera->AddPendingResult(PendingResultType::CREATE_CAMERA, std::move(result));

  camera->OnCreateCaptureEngineSucceeded(texture_id);
}

}  // namespace test
}  // namespace camera_windows
