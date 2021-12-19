// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "camera_plugin.h"

#include <flutter/flutter_view.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <mfapi.h>
#include <mfidl.h>
#include <shlobj.h>
#include <shobjidl.h>
#include <windows.h>

//#include <wrl.h>

#include <cassert>
#include <chrono>
#include <memory>
// #include <string>
// #include <vector>

#include "device_info.h"
#include "string_utils.h"

namespace camera_windows {

namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

// Channel events
const char kChannelName[] = "plugins.flutter.io/camera";

const char kAvailableCamerasMethod[] = "availableCameras";
const char kCreateMethod[] = "create";
const char kInitializeMethod[] = "initialize";
const char kTakePictureMethod[] = "takePicture";
const char kStartVideoRecordingMethod[] = "startVideoRecording";
const char kStopVideoRecordingMethod[] = "stopVideoRecording";
const char kPausePreview[] = "pausePreview";
const char kResumePreview[] = "resumePreview";
const char kDisposeMethod[] = "dispose";

// Camera channel events
const char kCameraMethodChannelBaseName[] = "flutter.io/cameraPlugin/camera";
const char kInitializedMethod[] = "initialized";

const char kCameraNameKey[] = "cameraName";
const char kResolutionPresetKey[] = "resolutionPreset";
const char kEnableAudioKey[] = "enableAudio";

const char kCameraIdKey[] = "cameraId";
const char kMaxVideoDurationKey[] = "maxVideoDuration";

const char kResolutionPresetValueLow[] = "low";
const char kResolutionPresetValueMedium[] = "medium";
const char kResolutionPresetValueHigh[] = "high";
const char kResolutionPresetValueVeryHigh[] = "veryHigh";
const char kResolutionPresetValueUltraHigh[] = "ultraHigh";
const char kResolutionPresetValueMax[] = "max";

const std::string kPictureCaptureExtension = "jpeg";
const std::string kVideoCaptureExtension = "mp4";

// Looks for |key| in |map|, returning the associated value if it is present, or
// a nullptr if not.
const EncodableValue *ValueOrNull(const EncodableMap &map, const char *key) {
  auto it = map.find(EncodableValue(key));
  if (it == map.end()) {
    return nullptr;
  }
  return &(it->second);
}

// Parses resolution preset argument to enum value
ResolutionPreset ParseResolutionPreset(const std::string &resolution_preset) {
  if (resolution_preset.compare(kResolutionPresetValueLow) == 0) {
    return ResolutionPreset::RESOLUTION_PRESET_LOW;
  } else if (resolution_preset.compare(kResolutionPresetValueMedium) == 0) {
    return ResolutionPreset::RESOLUTION_PRESET_MEDIUM;
  } else if (resolution_preset.compare(kResolutionPresetValueHigh) == 0) {
    return ResolutionPreset::RESOLUTION_PRESET_HIGH;
  } else if (resolution_preset.compare(kResolutionPresetValueVeryHigh) == 0) {
    return ResolutionPreset::RESOLUTION_PRESET_VERY_HIGH;
  } else if (resolution_preset.compare(kResolutionPresetValueUltraHigh) == 0) {
    return ResolutionPreset::RESOLUTION_PRESET_ULTRA_HIGH;
  } else if (resolution_preset.compare(kResolutionPresetValueMax) == 0) {
    return ResolutionPreset::RESOLUTION_PRESET_MAX;
  }
  return ResolutionPreset::RESOLUTION_PRESET_AUTO;
}

bool HasCurrentTextureId(int64_t current_camera_id, const EncodableMap &args) {
  const auto *texture_id =
      std::get_if<std::int64_t>(ValueOrNull(args, kCameraIdKey));

  if (!texture_id) {
    return false;
  }
  return current_camera_id == *texture_id;
}

std::unique_ptr<flutter::MethodChannel<>> BuildChannelForCamera(
    flutter::PluginRegistrarWindows *registrar, int64_t current_texture_id) {
  auto channel_name = std::string(kCameraMethodChannelBaseName) +
                      std::to_string(current_texture_id);

  return std::make_unique<flutter::MethodChannel<>>(
      registrar->messenger(), channel_name,
      &flutter::StandardMethodCodec::GetInstance());
}

std::unique_ptr<CaptureDeviceInfo> GetDeviceInfo(IMFActivate *device) {
  assert(device);
  auto deviceInfo = std::make_unique<CaptureDeviceInfo>();
  wchar_t *name;
  UINT32 name_size;

  HRESULT hr = device->GetAllocatedString(MF_DEVSOURCE_ATTRIBUTE_FRIENDLY_NAME,
                                          &name, &name_size);
  if (SUCCEEDED(hr)) {
    wchar_t *id;
    UINT32 id_size;
    hr = device->GetAllocatedString(
        MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE_VIDCAP_SYMBOLIC_LINK, &id, &id_size);

    if (SUCCEEDED(hr)) {
      deviceInfo->display_name = Utf8FromUtf16(std::wstring(name, name_size));
      deviceInfo->device_id = Utf8FromUtf16(std::wstring(id, id_size));
    }

    ::CoTaskMemFree(id);
  }

  ::CoTaskMemFree(name);
  return deviceInfo;
}

std::string GetCurrentTimeString() {
  std::chrono::system_clock::duration now =
      std::chrono::system_clock::now().time_since_epoch();

  auto s = std::chrono::duration_cast<std::chrono::seconds>(now).count();
  auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(now).count();

  struct tm newtime;
  localtime_s(&newtime, &s);

  std::string time_start = "";
  time_start.resize(80);
  size_t len =
      strftime(&time_start[0], time_start.size(), "%Y_%m%d_%H%M%S_", &newtime);
  if (len > 0) {
    time_start.resize(len);
  }

  // Add milliseconds
  return time_start + std::to_string(ms - s * 1000);
}

bool GetFilePathForPicture(std::string &filename) {
  wchar_t *known_folder_path = nullptr;
  HRESULT hr = SHGetKnownFolderPath(FOLDERID_Pictures, KF_FLAG_CREATE, nullptr,
                                    &known_folder_path);

  if (SUCCEEDED(hr)) {
    std::string path = Utf8FromUtf16(std::wstring(known_folder_path));

    filename = path + "\\" + "PhotoCapture_" + GetCurrentTimeString() + "." +
               kPictureCaptureExtension;
  }

  return SUCCEEDED(hr);
}

bool GetFilePathForVideo(std::string &filename) {
  wchar_t *known_folder_path = nullptr;
  HRESULT hr = SHGetKnownFolderPath(FOLDERID_Videos, KF_FLAG_CREATE, nullptr,
                                    &known_folder_path);

  if (SUCCEEDED(hr)) {
    std::string path = Utf8FromUtf16(std::wstring(known_folder_path));

    filename = path + "\\" + "VideoCapture_" + GetCurrentTimeString() + "." +
               kVideoCaptureExtension;
  }

  return SUCCEEDED(hr);
}

void GetAvailableCameras(CaptureController &capture_controller,
                         std::unique_ptr<flutter::MethodResult<>> result) {
  // Enumerate devices.
  IMFActivate **devices;
  UINT32 count;
  if (!capture_controller.EnumerateVideoCaptureDeviceSources(&devices,
                                                             &count)) {
    result->Error("System error", "Failed to get available cameras");
    CoTaskMemFree(devices);
    return;
  }

  if (count == 0) {
    result->Success(EncodableValue(EncodableList()));
    CoTaskMemFree(devices);
    return;
  }

  // Format found devices to the response
  EncodableList devices_list;
  for (UINT32 i = 0; i < count; ++i) {
    auto deviceInfo = GetDeviceInfo(devices[i]);
    auto deviceName = GetUniqueDeviceName(std::move(deviceInfo));

    // TODO: get lens facing info and sensor orientation from devices
    devices_list.push_back(EncodableMap({
        {EncodableValue("name"), EncodableValue(deviceName)},
        {EncodableValue("lensFacing"), EncodableValue("front")},
        {EncodableValue("sensorOrientation"), EncodableValue(0)},
    }));
  }

  CoTaskMemFree(devices);
  result->Success(std::move(EncodableValue(devices_list)));
}

}  // namespace

// static
void CameraPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<>>(
      registrar->messenger(), kChannelName,
      &flutter::StandardMethodCodec::GetInstance());

  std::unique_ptr<CameraPlugin> plugin = std::make_unique<CameraPlugin>(
      registrar, std::make_unique<CaptureController>());

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

CameraPlugin::CameraPlugin(
    flutter::PluginRegistrarWindows *registrar,
    std::unique_ptr<CaptureController> capture_controller)
    : registrar_(registrar),
      capture_controller_(std::move(capture_controller)) {
  // Register plugin as capture controller listener;
  if (capture_controller_) {
    capture_controller_->SetCaptureControllerListener(this);
  }
}

// TODO: make sure everything is cleared
CameraPlugin::~CameraPlugin() { ClearPendingResults(); }

void CameraPlugin::HandleMethodCall(
    const flutter::MethodCall<> &method_call,
    std::unique_ptr<flutter::MethodResult<>> result) {
  const std::string &method_name = method_call.method_name();

  if (method_name.compare(kAvailableCamerasMethod) == 0) {
    return GetAvailableCameras(*capture_controller_, std::move(result));
  } else if (method_name.compare(kCreateMethod) == 0) {
    const auto *arguments =
        std::get_if<flutter::EncodableMap>(method_call.arguments());
    assert(arguments);

    return CreateCameraMethodHandler(*arguments, std::move(result));
  } else if (method_name.compare(kInitializeMethod) == 0) {
    const auto *arguments =
        std::get_if<flutter::EncodableMap>(method_call.arguments());
    assert(arguments);

    return this->InitializeMethodHandler(*arguments, std::move(result));
  } else if (method_name.compare(kTakePictureMethod) == 0) {
    const auto *arguments =
        std::get_if<flutter::EncodableMap>(method_call.arguments());
    assert(arguments);

    return TakePictureMethodHandler(*arguments, std::move(result));
  } else if (method_name.compare(kStartVideoRecordingMethod) == 0) {
    const auto *arguments =
        std::get_if<flutter::EncodableMap>(method_call.arguments());
    assert(arguments);

    return StartVideoRecordingMethodHandler(*arguments, std::move(result));
  } else if (method_name.compare(kStopVideoRecordingMethod) == 0) {
    const auto *arguments =
        std::get_if<flutter::EncodableMap>(method_call.arguments());
    assert(arguments);

    return StopVideoRecordingMethodHandler(*arguments, std::move(result));
  } else if (method_name.compare(kPausePreview) == 0) {
    const auto *arguments =
        std::get_if<flutter::EncodableMap>(method_call.arguments());
    assert(arguments);

    return PausePreviewMethodHandler(*arguments, std::move(result));
  } else if (method_name.compare(kResumePreview) == 0) {
    const auto *arguments =
        std::get_if<flutter::EncodableMap>(method_call.arguments());
    assert(arguments);

    return ResumePreviewMethodHandler(*arguments, std::move(result));
  } else if (method_name.compare(kDisposeMethod) == 0) {
    const auto *arguments =
        std::get_if<flutter::EncodableMap>(method_call.arguments());
    assert(arguments);

    return DisposeMethodHandler(*arguments, std::move(result));
  } else {
    result->NotImplemented();
  }
}

// Creates and initializes capture controller
// and MFCaptureEngine for requested device
// TODO: support multiple camera streams with multiple
// capture_controllers and pending results
void CameraPlugin::CreateCameraMethodHandler(
    const EncodableMap &args, std::unique_ptr<flutter::MethodResult<>> result) {
  // Parse enableAudio argument
  const auto *enable_audio =
      std::get_if<bool>(ValueOrNull(args, kEnableAudioKey));
  if (!enable_audio) {
    return result->Error("System error",
                         std::string(kEnableAudioKey) + " argument missing");
  }

  // Parse cameraName argument
  const auto *device_name =
      std::get_if<std::string>(ValueOrNull(args, kCameraNameKey));
  if (!device_name) {
    return result->Error("System error",
                         std::string(kCameraNameKey) + " argument missing");
  }
  auto deviceInfo = ParseDeviceInfoFromDeviceName(*device_name);

  // Parse resolutionPreset argument
  const auto *resolution_preset =
      std::get_if<std::string>(ValueOrNull(args, kResolutionPresetKey));
  ResolutionPreset resolutionPreset;
  if (resolution_preset) {
    resolutionPreset = ParseResolutionPreset(*resolution_preset);
  } else {
    resolutionPreset = ResolutionPreset::RESOLUTION_PRESET_AUTO;
  }

  if (HasPendingResultByType(PendingResultType::CREATE_CAMERA)) {
    return result->Error("Failed to create camera",
                         "Pending camera creation already exists");
  }

  if (AddPendingResult(PendingResultType::CREATE_CAMERA, std::move(result))) {
    capture_controller_->CreateCaptureDevice(registrar_->texture_registrar(),
                                             deviceInfo->device_id,
                                             *enable_audio, resolutionPreset);
  }
}

void CameraPlugin::InitializeMethodHandler(
    const EncodableMap &args, std::unique_ptr<flutter::MethodResult<>> result) {
  auto current_texture_id = capture_controller_->GetTextureId();
  if (!HasCurrentTextureId(current_texture_id, args)) {
    return result->Error("Failed to initialize", "Camera id mismatch");
  }

  if (HasPendingResultByType(PendingResultType::INITIALIZE)) {
    return result->Error("Failed to initialize",
                         "Initialize method already called");
  }

  if (AddPendingResult(PendingResultType::INITIALIZE, std::move(result))) {
    capture_controller_->StartPreview(true);
  }
}

void CameraPlugin::PausePreviewMethodHandler(
    const EncodableMap &args, std::unique_ptr<flutter::MethodResult<>> result) {
  auto current_texture_id = capture_controller_->GetTextureId();
  if (!HasCurrentTextureId(current_texture_id, args)) {
    return result->Error("Failed to initialize", "Camera id mismatch");
  }

  if (HasPendingResultByType(PendingResultType::PAUSE_PREVIEW)) {
    return result->Error("Failed to initialize",
                         "Pause preview method already called");
  }

  if (AddPendingResult(PendingResultType::PAUSE_PREVIEW, std::move(result))) {
    // Capture engine does not really have pause feature...
    // so preview is stopped instead.
    capture_controller_->StopPreview();
  }
}

void CameraPlugin::ResumePreviewMethodHandler(
    const EncodableMap &args, std::unique_ptr<flutter::MethodResult<>> result) {
  auto current_texture_id = capture_controller_->GetTextureId();
  if (!HasCurrentTextureId(current_texture_id, args)) {
    return result->Error("Failed to initialize", "Camera id mismatch");
  }

  if (HasPendingResultByType(PendingResultType::RESUME_PREVIEW)) {
    return result->Error("Failed to initialize",
                         "Resume preview method already called");
  }

  if (AddPendingResult(PendingResultType::RESUME_PREVIEW, std::move(result))) {
    // Capture engine does not really have pause feature...
    // so preview is started instead
    capture_controller_->StartPreview(false);
  }
}

void CameraPlugin::StartVideoRecordingMethodHandler(
    const EncodableMap &args, std::unique_ptr<flutter::MethodResult<>> result) {
  if (!HasCurrentTextureId(capture_controller_->GetTextureId(), args)) {
    return result->Error("System error", "CameraId mismatch");
  }
  if (HasPendingResultByType(PendingResultType::START_RECORD)) {
    return result->Error("Failed to start video recording",
                         "Video recording starting already");
  }

  // Get max video duration
  int64_t max_capture_duration = -1;
  const auto *requested_max_capture_duration =
      std::get_if<std::int64_t>(ValueOrNull(args, kMaxVideoDurationKey));

  if (requested_max_capture_duration) {
    max_capture_duration = *requested_max_capture_duration;
  }

  std::string path;
  if (GetFilePathForVideo(path)) {
    if (AddPendingResult(PendingResultType::START_RECORD, std::move(result))) {
      auto str_path = std::string(path);
      capture_controller_->StartRecord(str_path, max_capture_duration);
    }
  } else {
    return result->Error("System error",
                         "Failed to get path for video capture");
  }
}
void CameraPlugin::StopVideoRecordingMethodHandler(
    const EncodableMap &args, std::unique_ptr<flutter::MethodResult<>> result) {
  auto current_texture_id = capture_controller_->GetTextureId();
  if (!HasCurrentTextureId(current_texture_id, args)) {
    return result->Error("System error", "CameraId mismatch");
  }
  if (HasPendingResultByType(PendingResultType::STOP_RECORD)) {
    return result->Error("Failed to stop video recording",
                         "Video recording stopping already");
  }
  if (AddPendingResult(PendingResultType::STOP_RECORD, std::move(result))) {
    capture_controller_->StopRecord();
  }
}

void CameraPlugin::TakePictureMethodHandler(
    const EncodableMap &args, std::unique_ptr<flutter::MethodResult<>> result) {
  if (!HasCurrentTextureId(capture_controller_->GetTextureId(), args)) {
    return result->Error("System error", "CameraId mismatch");
  }

  AddPendingResult(PendingResultType::TAKE_PICTURE, std::move(result));

  std::string path;
  if (GetFilePathForPicture(path)) {
    capture_controller_->TakePicture(path);
  } else {
    this->OnPictureFailed("Failed to get path for picture");
  }
}

void CameraPlugin::DisposeMethodHandler(
    const EncodableMap &args, std::unique_ptr<flutter::MethodResult<>> result) {
  if (!HasCurrentTextureId(capture_controller_->GetTextureId(), args)) {
    return result->Error("System error", "CameraId mismatch");
  }

  ClearPendingResults();

  // TODO: Capture errors
  capture_controller_->ResetCaptureEngineState();
  result->Success();
}

// Adds pending result to the pending_results map.
// If result already exists, call result error handler
bool CameraPlugin::AddPendingResult(
    PendingResultType type, std::unique_ptr<flutter::MethodResult<>> result) {
  assert(result);
  auto it = pending_results_.find(type);
  if (it != pending_results_.end()) {
    result->Error("Duplicate request", "Method handler already called");
    return false;
  }

  pending_results_.insert(std::make_pair(type, std::move(result)));
  return true;
}

std::unique_ptr<flutter::MethodResult<>> CameraPlugin::GetPendingResultByType(
    PendingResultType type) {
  auto it = pending_results_.find(type);
  if (it == pending_results_.end()) {
    return nullptr;
  }
  auto result = std::move(it->second);
  pending_results_.erase(it);
  return result;
}

bool CameraPlugin::HasPendingResultByType(PendingResultType type) {
  auto it = pending_results_.find(type);
  if (it == pending_results_.end()) {
    return false;
  }
  return it->second != nullptr;
}

void CameraPlugin::ClearPendingResultByType(PendingResultType type) {
  auto pending_result = GetPendingResultByType(type);
  if (pending_result) {
    pending_result->Error("Plugin disposed",
                          "Plugin disposed before request was handled");
  }
}

void CameraPlugin::ClearPendingResults() {
  ClearPendingResultByType(PendingResultType::CREATE_CAMERA);
  ClearPendingResultByType(PendingResultType::INITIALIZE);
  ClearPendingResultByType(PendingResultType::PAUSE_PREVIEW);
  ClearPendingResultByType(PendingResultType::RESUME_PREVIEW);
  ClearPendingResultByType(PendingResultType::START_RECORD);
  ClearPendingResultByType(PendingResultType::STOP_RECORD);
  ClearPendingResultByType(PendingResultType::TAKE_PICTURE);
}

// TODO: Create common base handler function for alll success and error cases
// below From CaptureControllerListener
void CameraPlugin::OnCreateCaptureEngineSucceeded(int64_t texture_id) {
  auto pending_result =
      GetPendingResultByType(PendingResultType::CREATE_CAMERA);
  if (pending_result) {
    pending_result->Success(EncodableMap(
        {{EncodableValue("cameraId"), EncodableValue(texture_id)}}));
  }
}

// From CaptureControllerListener
void CameraPlugin::OnCreateCaptureEngineFailed(const std::string &error) {
  auto pending_result =
      GetPendingResultByType(PendingResultType::CREATE_CAMERA);
  if (pending_result) {
    pending_result->Error("Failed to create camera", error);
  }
}

// From CaptureControllerListener
void CameraPlugin::OnStartPreviewSucceeded(int32_t width, int32_t height) {
  auto pending_result = GetPendingResultByType(PendingResultType::INITIALIZE);
  if (pending_result) {
    pending_result->Success(EncodableValue(EncodableMap({
        {EncodableValue("previewWidth"), EncodableValue((float)width)},
        {EncodableValue("previewHeight"), EncodableValue((float)height)},
    })));
  }
};

// From CaptureControllerListener
void CameraPlugin::OnStartPreviewFailed(const std::string &error) {
  auto pending_result = GetPendingResultByType(PendingResultType::INITIALIZE);
  if (pending_result) {
    pending_result->Error("Failed to initialize", error);
  }
};

// From CaptureControllerListener
void CameraPlugin::OnResumePreviewSucceeded() {
  auto pending_result =
      GetPendingResultByType(PendingResultType::RESUME_PREVIEW);
  if (pending_result) {
    pending_result->Success();
  }
}

// From CaptureControllerListener
void CameraPlugin::OnResumePreviewFailed(const std::string &error) {
  auto pending_result =
      GetPendingResultByType(PendingResultType::RESUME_PREVIEW);
  if (pending_result) {
    pending_result->Error("Failed to resume preview", error);
  }
}

// From CaptureControllerListener
void CameraPlugin::OnStopPreviewSucceeded() {
  auto pending_result =
      GetPendingResultByType(PendingResultType::PAUSE_PREVIEW);
  if (pending_result) {
    pending_result->Success();
  }
}

// From CaptureControllerListener
void CameraPlugin::OnStopPreviewFailed(const std::string &error) {
  auto pending_result =
      GetPendingResultByType(PendingResultType::PAUSE_PREVIEW);
  if (pending_result) {
    pending_result->Error("Failed to pause preview", error);
  }
}

// From CaptureControllerListener
void CameraPlugin::OnStartRecordSucceeded() {
  auto pending_result = GetPendingResultByType(PendingResultType::START_RECORD);
  if (pending_result) {
    pending_result->Success();
  }
};

// From CaptureControllerListener
void CameraPlugin::OnStartRecordFailed(const std::string &error) {
  auto pending_result = GetPendingResultByType(PendingResultType::START_RECORD);
  if (pending_result) {
    pending_result->Error("System error", "Failed to start video video");
  }
};

// From CaptureControllerListener
void CameraPlugin::OnStopRecordSucceeded(const std::string &filepath) {
  auto pending_result = GetPendingResultByType(PendingResultType::STOP_RECORD);
  if (pending_result) {
    pending_result->Success(EncodableValue(filepath));
  }
};

// From CaptureControllerListener
void CameraPlugin::OnStopRecordFailed(const std::string &error) {
  auto pending_result = GetPendingResultByType(PendingResultType::STOP_RECORD);
  if (pending_result) {
    pending_result->Error("System error", "Failed to capture video");
  }
};

// From CaptureControllerListener
void CameraPlugin::OnPictureSuccess(const std::string &filepath) {
  auto pending_result = GetPendingResultByType(PendingResultType::TAKE_PICTURE);
  if (pending_result) {
    pending_result->Success(EncodableValue(filepath));
  }
};

// From CaptureControllerListener
void CameraPlugin::OnPictureFailed(const std::string &error) {
  auto pending_take_picture_result =
      GetPendingResultByType(PendingResultType::TAKE_PICTURE);
  if (pending_take_picture_result) {
    pending_take_picture_result->Error("Failed to take picture", error);
  }
};

}  // namespace camera_windows
