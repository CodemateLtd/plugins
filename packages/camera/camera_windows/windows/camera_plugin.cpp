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

// Camera channel events
const char kCameraMethodChannelBaseName[] = "flutter.io/cameraPlugin/camera";
const char kInitializedMethod[] = "initialized";

const char kCameraNameKey[] = "cameraName";
const char kResolutionPresetKey[] = "resolutionPreset";
const char kEnableAudioKey[] = "enableAudio";

const char kCameraIdKey[] = "cameraId";

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
    flutter::PluginRegistrarWindows &registrar, int64_t current_texture_id) {
  auto channel_name = std::string(kCameraMethodChannelBaseName) +
                      std::to_string(current_texture_id);

  return std::make_unique<flutter::MethodChannel<>>(
      registrar.messenger(), channel_name,
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

void CreateCameraMethodHandler(
    flutter::PluginRegistrarWindows &registrar,
    CaptureController &capture_controller, const EncodableMap &args,
    std::unique_ptr<flutter::MethodResult<>> result) {
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

  // TODO: support multiple camera streams with multiple capture_controllers
  auto texture_id = capture_controller.InitializeCaptureController(
      registrar.texture_registrar(), deviceInfo->device_id, *enable_audio,
      resolutionPreset);

  if (texture_id >= 0) {
    return result->Success(EncodableMap(
        {{EncodableValue("cameraId"), EncodableValue(texture_id)}}));
  }

  return result->Error("System error", "Failed to create camera");
}

void InitializeMethodHandler(flutter::PluginRegistrarWindows &registrar,
                             CaptureController &capture_controller,
                             const EncodableMap &args,
                             std::unique_ptr<flutter::MethodResult<>> result) {
  auto current_texture_id = capture_controller.GetTextureId();
  if (!HasCurrentTextureId(current_texture_id, args)) {
    return result->Error("System error", "CameraId mismatch");
  }

  capture_controller.StartPreview();

  result->Success();

  auto channel_name = std::string(kCameraMethodChannelBaseName) +
                      std::to_string(current_texture_id);

  auto channel = BuildChannelForCamera(registrar, current_texture_id);

  std::unique_ptr<EncodableValue> initialized_message_data =
      std::make_unique<EncodableValue>(EncodableMap(
          {{EncodableValue("previewWidth"),
            EncodableValue((float)capture_controller.GetPreviewWidth())},
           {EncodableValue("previewHeight"),
            EncodableValue((float)capture_controller.GetPreviewHeight())},
           {EncodableValue("exposureMode"), EncodableValue("auto")},
           {EncodableValue("exposurePointSupported"), EncodableValue(false)},
           {EncodableValue("focusMode"), EncodableValue("auto")},
           {EncodableValue("focusPointSupported"), EncodableValue(false)}}));

  channel->InvokeMethod(kInitializedMethod,
                        std::move(initialized_message_data));

  printf("CameraChannelName: %s\n", channel_name.c_str());
  fflush(stdout);
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

void TakePictureMethodHandler(CaptureController &capture_controller,
                              const EncodableMap &args,
                              std::unique_ptr<flutter::MethodResult<>> result) {
  if (!HasCurrentTextureId(capture_controller.GetTextureId(), args)) {
    return result->Error("System error", "CameraId mismatch");
  }

  std::string path;
  if (GetFilePathForPicture(path)) {
    auto str_path = std::string(path);
    if (capture_controller.TakePicture(str_path)) {
      return result->Success(EncodableValue(str_path));
    } else {
      return result->Error("System error", "Failed to take picture");
    }

  } else {
    return result->Error("System error", "Failed to get path for picture");
  }
}

void StartVideoRecordingMethodHandler(
    CaptureController &capture_controller, const EncodableMap &args,
    std::unique_ptr<flutter::MethodResult<>> result) {
  if (!HasCurrentTextureId(capture_controller.GetTextureId(), args)) {
    return result->Error("System error", "CameraId mismatch");
  }

  std::string path;
  if (GetFilePathForVideo(path)) {
    auto str_path = std::string(path);
    if (capture_controller.StartRecord(str_path)) {
      return result->Success();
    } else {
      return result->Error("System error", "Failed to start video record");
    }

  } else {
    return result->Error("System error",
                         "Failed to get path for video capture");
  }
}

void StopVideoRecordingMethodHandler(
    flutter::PluginRegistrarWindows &registrar,
    CaptureController &capture_controller, const EncodableMap &args,
    std::unique_ptr<flutter::MethodResult<>> result) {
  auto current_texture_id = capture_controller.GetTextureId();
  if (!HasCurrentTextureId(current_texture_id, args)) {
    return result->Error("System error", "CameraId mismatch");
  }

  auto path = capture_controller.StopRecord();
  if (path.empty()) {
    return result->Error("System error", "Failed to capture video");
  } else {
    return result->Success(EncodableValue(path));
  }
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
      capture_controller_(std::move(capture_controller)) {}

CameraPlugin::~CameraPlugin() = default;

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

    return CreateCameraMethodHandler(*registrar_, *capture_controller_,
                                     *arguments, std::move(result));
  } else if (method_name.compare(kInitializeMethod) == 0) {
    const auto *arguments =
        std::get_if<flutter::EncodableMap>(method_call.arguments());
    assert(arguments);

    return InitializeMethodHandler(*registrar_, *capture_controller_,
                                   *arguments, std::move(result));
  } else if (method_name.compare(kTakePictureMethod) == 0) {
    const auto *arguments =
        std::get_if<flutter::EncodableMap>(method_call.arguments());
    assert(arguments);

    return TakePictureMethodHandler(*capture_controller_, *arguments,
                                    std::move(result));
  } else if (method_name.compare(kStartVideoRecordingMethod) == 0) {
    const auto *arguments =
        std::get_if<flutter::EncodableMap>(method_call.arguments());
    assert(arguments);

    return StartVideoRecordingMethodHandler(*capture_controller_, *arguments,
                                            std::move(result));
  } else if (method_name.compare(kStopVideoRecordingMethod) == 0) {
    const auto *arguments =
        std::get_if<flutter::EncodableMap>(method_call.arguments());
    assert(arguments);

    return StopVideoRecordingMethodHandler(*registrar_, *capture_controller_,
                                           *arguments, std::move(result));
  }

  else {
    result->NotImplemented();
  }
}

}  // namespace camera_windows
