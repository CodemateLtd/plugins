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
  class CaptureEngineCallback : public IMFCaptureEngineOnSampleCallback,
                                public IMFCaptureEngineOnEventCallback {
   public:
    CaptureEngineCallback(CaptureController* capture_controller)
        : ref_(1), capture_controller_(capture_controller) {}
    CaptureController* capture_controller_;

    // IUnknown
    STDMETHODIMP_(ULONG) AddRef();
    STDMETHODIMP_(ULONG) Release();
    STDMETHODIMP_(HRESULT) QueryInterface(const IID& riid, void** ppv);

    // IMFCaptureEngineOnEventCallback
    STDMETHODIMP OnEvent(IMFMediaEvent* pEvent);

    // IMFCaptureEngineOnSampleCallback
    STDMETHODIMP_(HRESULT) OnSample(IMFSample* pSample);

   private:
    volatile ULONG ref_;
  };

 public:
  CaptureController();
  virtual ~CaptureController();

  bool IsInitialized() { return initialized_; }
  bool IsPreviewing() { return previewing_; }
  // bool IsTakingPicture() { return pending_picture_; }
  void ResetCaptureController();

  uint8_t* GetSourceBuffer(uint32_t current_length);

  void OnBufferUpdate();

  int64_t InitializeCaptureController(
      flutter::TextureRegistrar* texture_registrar,
      const std::string& device_id, bool enable_audio,
      ResolutionPreset resolution_preset);

  bool EnumerateVideoCaptureDeviceSources(IMFActivate*** devices,
                                          UINT32* count);
  HRESULT PrepareVideoCaptureAttributes(IMFAttributes** attributes, int count);
  int64_t GetTextureId() { return texture_id_; }
  uint32_t GetPreviewWidth() { return preview_frame_width_; }
  uint32_t GetPreviewHeight() { return preview_frame_height_; }
  uint32_t GetMaxPreviewHeight();

  bool StartPreview();
  bool StopPreview();
  bool StartRecord(const std::string& filepath);
  std::string StopRecord();

  bool TakePicture(const std::string filepath);
  void OnPicture(bool success);
  void OnRecordStarted(bool success);
  void OnRecordStopped(bool success);

 private:
  bool initialized_ = false;
  bool enable_audio_record_ = false;

  ResolutionPreset resolution_preset_ =
      ResolutionPreset::RESOLUTION_PRESET_MEDIUM;

  // CaptureEngine objects
  IMFCaptureEngine* capture_engine_ = nullptr;
  std::unique_ptr<CaptureEngineCallback> capture_engine_callback_ = nullptr;
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
  FlutterDesktopPixelBuffer flutter_desktop_pixel_buffer_;
  uint32_t source_buffer_size_ = 0;
  std::unique_ptr<uint8_t[]> source_buffer_data_ = nullptr;
  std::unique_ptr<uint8_t[]> dest_buffer = nullptr;
  uint32_t bytes_per_pixel_ = 4;  // MFVideoFormat_RGB32

  // Preview
  bool previewing_ = false;
  uint32_t preview_frame_width_ = 0;
  uint32_t preview_frame_height_ = 0;
  IMFMediaType* base_preview_media_type = nullptr;
  IMFCapturePreviewSink* preview_sink_ = nullptr;

  // Photo / Record
  bool recording_ = false;
  bool pending_picture_ = false;
  bool photo_capture_success_ = false;
  bool video_capture_success_ = false;
  uint32_t capture_frame_width_ = 0;
  uint32_t capture_frame_height_ = 0;
  IMFMediaType* base_capture_media_type = nullptr;
  IMFCapturePhotoSink* photo_sink_ = nullptr;
  IMFCaptureRecordSink* record_sink_ = nullptr;
  std::string pending_record_path_ = "";

  // TODO: capturing photos/video with CaptureEngine is asynchronous, this is
  // used to force this to synchronous request. To fix this
  // camera_platform_interface implementation must be written separately for
  // windows to handle asynchronous photo requests
  HANDLE photo_capture_event_ = nullptr;
  HANDLE video_capture_event_ = nullptr;

  HRESULT CreateDefaultAudioCaptureSource();
  HRESULT PrepareAudioCaptureAttributes(IMFAttributes** attributes, int count);
  HRESULT CreateVideoCaptureSourceForDevice(const std::string& video_device_id);
  HRESULT CreateD3DManagerWithDX11Device();

  bool CreateCaptureEngine(const std::string& video_device_id);

  HRESULT FindBaseMediaTypes();

  HRESULT InitPreviewSink();
  HRESULT InitPhotoSink(const std::string& filepath);
  HRESULT InitRecordSink(const std::string& filepath);

  // bool CreateDeviceSourceReader(const std::string& device_id);
  // bool PrepareSourceReaderAttributes(IMFAttributes** attributes);

  const FlutterDesktopPixelBuffer* ConvertPixelBufferForFlutter(size_t width,
                                                                size_t height);
};
}  // namespace camera_windows

#endif  // PACKAGES_CAMERA_CAMERA_WINDOWS_WINDOWS_CAPTURE_CONTROLLER_H_
