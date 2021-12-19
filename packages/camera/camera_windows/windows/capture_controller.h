// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef PACKAGES_CAMERA_CAMERA_WINDOWS_WINDOWS_CAPTURE_CONTROLLER_H_
#define PACKAGES_CAMERA_CAMERA_WINDOWS_WINDOWS_CAPTURE_CONTROLLER_H_

#include <d3d11.h>
//#include <d3d12.h>
#include <flutter/texture_registrar.h>
#include <mfapi.h>
#include <mfcaptureengine.h>
#include <mferror.h>
#include <mfidl.h>
#include <windows.h>

#include <memory>
#include <string>

#include "capture_controller_listener.h"
namespace camera_windows {

enum ResolutionPreset {
  /// AUTO
  RESOLUTION_PRESET_AUTO,

  /// 240p (320x240)
  RESOLUTION_PRESET_LOW,

  /// 480p (720x480)
  RESOLUTION_PRESET_MEDIUM,

  /// 720p (1280x720)
  RESOLUTION_PRESET_HIGH,

  /// 1080p (1920x1080)
  RESOLUTION_PRESET_VERY_HIGH,

  /// 2160p (4096x2160)
  RESOLUTION_PRESET_ULTRA_HIGH,

  /// The highest resolution available.
  RESOLUTION_PRESET_MAX,
};

template <class T>
void Release(T** ppT) {
  static_assert(std::is_base_of<IUnknown, T>::value,
                "T must inherit from IUnknown");
  if (*ppT) {
    (*ppT)->Release();
    *ppT = NULL;
  }
}

class CaptureController {
  class CaptureEngineListener : public IMFCaptureEngineOnSampleCallback,
                                public IMFCaptureEngineOnEventCallback {
   public:
    CaptureEngineListener(CaptureController* capture_controller)
        : ref_(1), capture_controller_(capture_controller) {}

    ~CaptureEngineListener(){};

    // IUnknown
    STDMETHODIMP_(ULONG) AddRef();
    STDMETHODIMP_(ULONG) Release();
    STDMETHODIMP_(HRESULT) QueryInterface(const IID& riid, void** ppv);

    // IMFCaptureEngineOnEventCallback
    STDMETHODIMP OnEvent(IMFMediaEvent* pEvent);

    // IMFCaptureEngineOnSampleCallback
    STDMETHODIMP_(HRESULT) OnSample(IMFSample* pSample);

   private:
    CaptureController* capture_controller_;
    volatile ULONG ref_;
  };

 public:
  static bool EnumerateVideoCaptureDeviceSources(IMFActivate*** devices,
                                                 UINT32* count);

  CaptureController();
  virtual ~CaptureController();

  void SetCaptureControllerListener(CaptureControllerListener* listener) {
    capture_controller_listener_ = listener;
  };

  bool IsInitialized() { return initialized_; }
  bool CaptureEngineInitializing() {
    return capture_engine_initialization_pending_;
  }
  bool InitializingPreview() { return initializing_preview_; }
  bool IsPreviewing() { return previewing_; }
  void ResetCaptureEngineState();

  uint8_t* GetSourceBuffer(uint32_t current_length);
  void OnBufferUpdate();

  void CreateCaptureDevice(flutter::TextureRegistrar* texture_registrar,
                           const std::string& device_id, bool enable_audio,
                           ResolutionPreset resolution_preset);

  int64_t GetTextureId() { return texture_id_; }
  uint32_t GetPreviewWidth() { return preview_frame_width_; }
  uint32_t GetPreviewHeight() { return preview_frame_height_; }
  uint32_t GetMaxPreviewHeight();

  // Actions
  void StartPreview(bool initializing_preview);
  void StopPreview();
  void StartRecord(const std::string& filepath, int64_t max_capture_duration);
  void StopRecord();
  void TakePicture(const std::string filepath);

  // Handlers for CaptureEngineListener events
  void OnCaptureEngineInitialized(bool success);
  void OnCaptureEngineError();
  void OnPicture(bool success);
  void OnPreviewStarted(bool success, bool initializing_preview);
  void OnPreviewStopped(bool success);
  void OnRecordStarted(bool success);
  void OnRecordStopped(bool success);

 private:
  CaptureControllerListener* capture_controller_listener_ = nullptr;
  bool initialized_ = false;
  bool enable_audio_record_ = false;

  ResolutionPreset resolution_preset_ =
      ResolutionPreset::RESOLUTION_PRESET_MEDIUM;

  // CaptureEngine objects
  bool capture_engine_initialization_pending_ = false;
  IMFCaptureEngine* capture_engine_ = nullptr;
  CaptureEngineListener* capture_engine_callback_handler_ = nullptr;

  IMFDXGIDeviceManager* dxgi_device_manager_ = nullptr;
  ID3D11Device* dx11_device_ = nullptr;
  // ID3D12Device* dx12_device_ = nullptr;
  UINT dx_device_reset_token_ = 0;

  // Sources
  IMFMediaSource* video_source_ = nullptr;
  IMFMediaSource* audio_source_ = nullptr;

  // Texture
  int64_t texture_id_ = -1;
  flutter::TextureRegistrar* texture_registrar_ = nullptr;
  std::unique_ptr<flutter::TextureVariant> texture_;

  // TODO: add release_callback and clear buffer if needed
  FlutterDesktopPixelBuffer flutter_desktop_pixel_buffer_ = {};
  uint32_t source_buffer_size_ = 0;
  std::unique_ptr<uint8_t[]> source_buffer_data_ = nullptr;
  std::unique_ptr<uint8_t[]> dest_buffer_ = nullptr;
  uint32_t bytes_per_pixel_ = 4;  // MFVideoFormat_RGB32

  // Preview
  bool initializing_preview_ = false;

  bool preview_pending_ = false;
  bool previewing_ = false;
  uint32_t preview_frame_width_ = 0;
  uint32_t preview_frame_height_ = 0;
  IMFMediaType* base_preview_media_type = nullptr;
  IMFCapturePreviewSink* preview_sink_ = nullptr;

  // Photo / Record
  bool pending_image_capture_ = false;
  bool record_pending_ = false;
  bool recording_ = false;
  int64_t max_capture_duration_ = -1;

  uint32_t capture_frame_width_ = 0;
  uint32_t capture_frame_height_ = 0;
  IMFMediaType* base_capture_media_type = nullptr;
  IMFCapturePhotoSink* photo_sink_ = nullptr;
  IMFCaptureRecordSink* record_sink_ = nullptr;
  std::string pending_picture_path_ = "";
  std::string pending_record_path_ = "";

  HRESULT CreateDefaultAudioCaptureSource();
  HRESULT CreateVideoCaptureSourceForDevice(const std::string& video_device_id);
  HRESULT CreateD3DManagerWithDX11Device();

  HRESULT CreateCaptureEngine(const std::string& video_device_id);

  HRESULT FindBaseMediaTypes();
  HRESULT InitPreviewSink();
  HRESULT InitPhotoSink(const std::string& filepath);
  HRESULT InitRecordSink(const std::string& filepath);

  const FlutterDesktopPixelBuffer* ConvertPixelBufferForFlutter(size_t width,
                                                                size_t height);
};
}  // namespace camera_windows

#endif  // PACKAGES_CAMERA_CAMERA_WINDOWS_WINDOWS_CAPTURE_CONTROLLER_H_
