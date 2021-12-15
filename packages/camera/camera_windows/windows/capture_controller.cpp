// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "capture_controller.h"

#include <d3d11.h>
#include <wincodec.h>
#include <wrl/client.h>

#include <cassert>
#include <memory>
#include <system_error>

#include "string_utils.h"

namespace camera_windows {
using Microsoft::WRL::ComPtr;

struct FlutterDesktop_Pixel {
  BYTE r = 0;
  BYTE g = 0;
  BYTE b = 0;
  BYTE a = 0;
};

struct MFVideoFormat_RGB32_Pixel {
  BYTE b = 0;
  BYTE g = 0;
  BYTE r = 0;
  BYTE x = 0;
};

const uint32_t event_timeout_ms = INFINITE;
// const uint32_t event_timeout_ms = 2000;  // Two seconds

CaptureController::CaptureController(){};
CaptureController::~CaptureController() { ResetCaptureController(); };

HRESULT BuildMediaTypeForVideoPreview(IMFMediaType *src_media_type,
                                      IMFMediaType **preview_media_type) {
  Release(preview_media_type);
  IMFMediaType *new_media_type = nullptr;

  HRESULT hr = MFCreateMediaType(&new_media_type);

  // First clone everything from original media type
  if (SUCCEEDED(hr)) {
    hr = src_media_type->CopyAllItems(new_media_type);
  }

  if (SUCCEEDED(hr)) {
    // Change subtype to requested
    hr = new_media_type->SetGUID(MF_MT_SUBTYPE, MFVideoFormat_RGB32);
  }

  if (SUCCEEDED(hr)) {
    hr = new_media_type->SetUINT32(MF_MT_ALL_SAMPLES_INDEPENDENT, TRUE);
  }

  if (SUCCEEDED(hr)) {
    *preview_media_type = new_media_type;
    (*preview_media_type)->AddRef();
  }

  Release(&new_media_type);
  return hr;
}

// Creates media type for photo capture for jpeg images
HRESULT BuildMediaTypeForPhotoCapture(IMFMediaType *src_media_type,
                                      IMFMediaType **photo_media_type,
                                      GUID image_format) {
  Release(photo_media_type);
  IMFMediaType *new_media_type = nullptr;

  HRESULT hr = MFCreateMediaType(&new_media_type);

  // First clone everything from original media type
  if (SUCCEEDED(hr)) {
    hr = src_media_type->CopyAllItems(new_media_type);
  }

  if (SUCCEEDED(hr)) {
    hr = new_media_type->SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Image);
  }

  if (SUCCEEDED(hr)) {
    hr = new_media_type->SetGUID(MF_MT_SUBTYPE, image_format);
  }

  if (SUCCEEDED(hr)) {
    *photo_media_type = new_media_type;
    (*photo_media_type)->AddRef();
  }

  Release(&new_media_type);
  return hr;
}

// Creates media type for video capture
HRESULT BuildMediaTypeForVideoCapture(IMFMediaType *src_media_type,
                                      IMFMediaType **video_record_media_type,
                                      GUID capture_format) {
  Release(video_record_media_type);
  IMFMediaType *new_media_type = nullptr;

  HRESULT hr = MFCreateMediaType(&new_media_type);

  // First clone everything from original media type
  if (SUCCEEDED(hr)) {
    hr = src_media_type->CopyAllItems(new_media_type);
  }

  if (SUCCEEDED(hr)) {
    hr = new_media_type->SetGUID(MF_MT_SUBTYPE, capture_format);
  }

  if (SUCCEEDED(hr)) {
    *video_record_media_type = new_media_type;
    (*video_record_media_type)->AddRef();
  }

  Release(&new_media_type);
  return hr;
}

// Queries interface object from collection
template <class Q>
HRESULT GetCollectionObject(IMFCollection *pCollection, DWORD index,
                            Q **ppObj) {
  IUnknown *pUnk;
  HRESULT hr = pCollection->GetElement(index, &pUnk);
  if (SUCCEEDED(hr)) {
    hr = pUnk->QueryInterface(IID_PPV_ARGS(ppObj));
    pUnk->Release();
  }
  return hr;
}

HRESULT BuildMediaTypeForAudioCapture(IMFMediaType **audio_record_media_type) {
  Release(audio_record_media_type);

  IMFAttributes *audio_output_attributes = nullptr;
  IMFCollection *available_output_types = nullptr;
  IMFMediaType *src_media_type = nullptr;
  IMFMediaType *new_media_type = nullptr;
  DWORD mt_count = 0;

  HRESULT hr = MFCreateAttributes(&audio_output_attributes, 1);

  if (SUCCEEDED(hr)) {
    // Enumerate only low latency audio outputs
    hr = audio_output_attributes->SetUINT32(MF_LOW_LATENCY, TRUE);
  }

  if (SUCCEEDED(hr)) {
    DWORD mft_flags = (MFT_ENUM_FLAG_ALL & (~MFT_ENUM_FLAG_FIELDOFUSE)) |
                      MFT_ENUM_FLAG_SORTANDFILTER;

    hr = MFTranscodeGetAudioOutputAvailableTypes(MFAudioFormat_AAC, mft_flags,
                                                 audio_output_attributes,
                                                 &available_output_types);
  }

  if (SUCCEEDED(hr)) {
    hr = GetCollectionObject(available_output_types, 0, &src_media_type);
  }

  if (SUCCEEDED(hr)) {
    hr = available_output_types->GetElementCount(&mt_count);
  }

  if (mt_count == 0) {
    // No sources found
    hr = E_FAIL;
  }

  // Create new media type to copy original media type to
  if (SUCCEEDED(hr)) {
    hr = MFCreateMediaType(&new_media_type);
  }

  if (SUCCEEDED(hr)) {
    hr = src_media_type->CopyAllItems(new_media_type);
  }

  if (SUCCEEDED(hr)) {
    // Point target media type to new media type
    *audio_record_media_type = new_media_type;
    (*audio_record_media_type)->AddRef();
  }

  Release(&audio_output_attributes);
  Release(&available_output_types);
  Release(&src_media_type);
  Release(&new_media_type);

  return hr;
}

bool CaptureController::EnumerateVideoCaptureDeviceSources(
    IMFActivate ***devices, UINT32 *count) {
  IMFAttributes *attributes = nullptr;

  HRESULT hr = MFCreateAttributes(&attributes, 1);

  if (SUCCEEDED(hr)) {
    hr = attributes->SetGUID(MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE,
                             MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE_VIDCAP_GUID);
  }

  if (SUCCEEDED(hr)) {
    hr = MFEnumDeviceSources(attributes, devices, count);
  }

  Release(&attributes);
  return SUCCEEDED(hr);
}

// Uses first audio source to capture audio. Enumerating audio sources via
// platform interface is not supported.
HRESULT CaptureController::CreateDefaultAudioCaptureSource() {
  this->audio_source_ = nullptr;
  IMFActivate **devices = nullptr;
  UINT32 count = 0;

  IMFAttributes *attributes = nullptr;
  HRESULT hr = MFCreateAttributes(&attributes, 1);

  if (SUCCEEDED(hr)) {
    hr = attributes->SetGUID(MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE,
                             MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE_AUDCAP_GUID);
  }

  if (SUCCEEDED(hr)) {
    hr = MFEnumDeviceSources(attributes, &devices, &count);
  }

  Release(&attributes);

  if (SUCCEEDED(hr) && count > 0) {
    wchar_t *audio_device_id;
    UINT32 audio_device_id_size;

    // Use first audio device
    hr = devices[0]->GetAllocatedString(
        MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE_AUDCAP_ENDPOINT_ID, &audio_device_id,
        &audio_device_id_size);

    if (SUCCEEDED(hr)) {
      IMFAttributes *audio_capture_source_attributes = nullptr;
      hr = MFCreateAttributes(&audio_capture_source_attributes, 2);

      if (SUCCEEDED(hr)) {
        hr = audio_capture_source_attributes->SetGUID(
            MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE,
            MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE_AUDCAP_GUID);
      }

      if (SUCCEEDED(hr)) {
        hr = audio_capture_source_attributes->SetString(
            MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE_AUDCAP_ENDPOINT_ID,
            audio_device_id);
      }

      if (SUCCEEDED(hr)) {
        hr = MFCreateDeviceSource(audio_capture_source_attributes,
                                  &this->audio_source_);
      }
      Release(&audio_capture_source_attributes);
    }

    ::CoTaskMemFree(audio_device_id);
  }

  CoTaskMemFree(devices);

  return hr;
}

HRESULT CaptureController::CreateVideoCaptureSourceForDevice(
    const std::string &video_device_id) {
  this->video_source_ = nullptr;

  IMFAttributes *video_capture_source_attributes = nullptr;

  HRESULT hr = MFCreateAttributes(&video_capture_source_attributes, 2);

  if (SUCCEEDED(hr)) {
    hr = video_capture_source_attributes->SetGUID(
        MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE,
        MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE_VIDCAP_GUID);
  }

  if (SUCCEEDED(hr)) {
    hr = video_capture_source_attributes->SetString(
        MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE_VIDCAP_SYMBOLIC_LINK,
        Utf16FromUtf8(video_device_id).c_str());
  }

  if (SUCCEEDED(hr)) {
    hr = MFCreateDeviceSource(video_capture_source_attributes,
                              &this->video_source_);
  }

  Release(&video_capture_source_attributes);

  return hr;
}

HRESULT CaptureController::CreateD3DManagerWithDX11Device() {
  HRESULT hr = S_OK;

  /*
  D3D_FEATURE_LEVEL feature_level;

  static const D3D_FEATURE_LEVEL allowed_feature_levels[] = {
      D3D_FEATURE_LEVEL_11_1, D3D_FEATURE_LEVEL_11_0, D3D_FEATURE_LEVEL_10_1,
      D3D_FEATURE_LEVEL_10_0, D3D_FEATURE_LEVEL_9_3,  D3D_FEATURE_LEVEL_9_2,
      D3D_FEATURE_LEVEL_9_1};

  hr = D3D11CreateDevice(nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr,
                         D3D11_CREATE_DEVICE_VIDEO_SUPPORT,
  allowed_feature_levels, ARRAYSIZE(allowed_feature_levels), D3D11_SDK_VERSION,
                         &dx11_device_, &feature_level,nullptr );
  */

  hr = D3D11CreateDevice(nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr,
                         D3D11_CREATE_DEVICE_VIDEO_SUPPORT, nullptr, 0,
                         D3D11_SDK_VERSION, &dx11_device_, nullptr, nullptr);

  if (SUCCEEDED(hr)) {
    // Enable multithread protection
    ID3D10Multithread *multi_thread;
    hr = dx11_device_->QueryInterface(IID_PPV_ARGS(&multi_thread));
    if (SUCCEEDED(hr)) {
      multi_thread->SetMultithreadProtected(TRUE);
    }
    Release(&multi_thread);
  }

  if (SUCCEEDED(hr)) {
    hr = MFCreateDXGIDeviceManager(&dx_device_reset_token_,
                                   &dxgi_device_manager_);
  }

  if (SUCCEEDED(hr)) {
    hr =
        dxgi_device_manager_->ResetDevice(dx11_device_, dx_device_reset_token_);
  }

  return hr;
}

// TODO: Check if DX12 device can be used with flutter and if yes, finalize
// commented out function below
/* HRESULT CaptureController::CreateD3DManagerWithDX12() {
  HRESULT hr = S_OK;
  D3D_FEATURE_LEVEL min_feature_level = D3D_FEATURE_LEVEL_9_1;

  hr = D3D12CreateDevice(nullptr,min_feature_level,);

  if (SUCCEEDED(hr)) {
    hr = MFCreateDXGIDeviceManager(&dx_device_reset_token_,
                                   &dxgi_device_manager_);
  }

  if (SUCCEEDED(hr)) {
    hr = dxgi_device_manager_->ResetDevice(dx11_device_,
                                           dx_device_reset_token_);
  }

  Release(&device_context);
  return hr;
} */

bool CaptureController::CreateCaptureEngine(
    const std::string &video_device_id) {
  HRESULT hr = S_OK;
  IMFAttributes *attributes = nullptr;
  IMFCaptureEngineClassFactory *capture_engine_factory = nullptr;

  // Reset existing state
  ResetCaptureController();

  if (!capture_engine_callback_) {
    capture_engine_callback_ = new CaptureEngineCallback(this);
    capture_engine_callback_->AddRef();
  }

  if (SUCCEEDED(hr)) {
    hr = CreateD3DManagerWithDX11Device();
  }

  if (SUCCEEDED(hr)) {
    hr = MFCreateAttributes(&attributes, 1);
  }

  if (SUCCEEDED(hr)) {
    hr = attributes->SetUnknown(MF_CAPTURE_ENGINE_D3D_MANAGER,
                                dxgi_device_manager_);
  }

  if (SUCCEEDED(hr)) {
    hr = CoCreateInstance(CLSID_MFCaptureEngineClassFactory, nullptr,
                          CLSCTX_INPROC_SERVER,
                          IID_PPV_ARGS(&capture_engine_factory));
  }

  if (SUCCEEDED(hr)) {
    // Create CaptureEngine.
    hr = capture_engine_factory->CreateInstance(CLSID_MFCaptureEngine,
                                                IID_PPV_ARGS(&capture_engine_));
  }

  if (SUCCEEDED(hr)) {
    hr = CreateVideoCaptureSourceForDevice(video_device_id);
  }

  if (enable_audio_record_) {
    if (SUCCEEDED(hr)) {
      hr = CreateDefaultAudioCaptureSource();
    }
  }

  if (SUCCEEDED(hr)) {
    hr = capture_engine_->Initialize(capture_engine_callback_, attributes,
                                     audio_source_, video_source_);
  }

  if (!SUCCEEDED(hr)) {
    // Reset everything if creation of capture engine failed
    ResetCaptureController();
  }

  return SUCCEEDED(hr);
}

void CaptureController::ResetCaptureController() {
  initialized_ = false;
  if (previewing_) {
    StopPreview();
  }

  if (recording_) {
    StopRecord();
  }

  // Photo capture
  if (photo_capture_event_ != nullptr) {
    CloseHandle(photo_capture_event_);
    photo_capture_event_ = nullptr;
  }

  // Video capture (record)
  if (video_capture_event_ != nullptr) {
    CloseHandle(video_capture_event_);
    video_capture_event_ = nullptr;
  }

  pending_picture_ = false;
  Release(&photo_sink_);

  // Preview
  Release(&preview_sink_);

  // Record
  Release(&record_sink_);

  // CaptureEngine
  Release(&capture_engine_callback_);
  Release(&capture_engine_);

  Release(&audio_source_);
  Release(&video_source_);

  Release(&base_preview_media_type);
  Release(&base_capture_media_type);

  if (dxgi_device_manager_) {
    dxgi_device_manager_->ResetDevice(dx11_device_, dx_device_reset_token_);
  }
  Release(&dxgi_device_manager_);
  Release(&dx11_device_);

  // Texture
  if (texture_registrar_ && texture_id_ > -1) {
    texture_registrar_->UnregisterTexture(texture_id_);
  }
}

uint8_t *CaptureController::GetSourceBuffer(uint32_t current_length) {
  if (this->source_buffer_data_ == nullptr ||
      this->source_buffer_size_ != current_length) {
    // Update source buffer size
    this->source_buffer_data_ = nullptr;
    this->source_buffer_data_ = std::make_unique<uint8_t[]>(current_length);
    this->source_buffer_size_ = current_length;
  }
  return this->source_buffer_data_.get();
}

void CaptureController::OnBufferUpdate() {
  if (this->texture_registrar_ && this->texture_id_ >= 0) {
    this->texture_registrar_->MarkTextureFrameAvailable(this->texture_id_);
  }
}

int64_t CaptureController::InitializeCaptureController(
    flutter::TextureRegistrar *texture_registrar, const std::string &device_id,
    bool enable_audio, ResolutionPreset resolution_preset) {
  if (initialized_ && texture_id_ >= 0) {
    return this->texture_id_;
  }

  resolution_preset_ = resolution_preset;

  if (!this->CreateCaptureEngine(device_id)) {
    return -1;
  }

  this->texture_registrar_ = texture_registrar;

  // Create flutter desktop pixelbuffer texture;
  texture_ =
      std::make_unique<flutter::TextureVariant>(flutter::PixelBufferTexture(
          [this](size_t width,
                 size_t height) -> const FlutterDesktopPixelBuffer * {
            return this->ConvertPixelBufferForFlutter(width, height);
          }));

  this->texture_id_ = texture_registrar->RegisterTexture(texture_.get());
  enable_audio_record_ = enable_audio;
  initialized_ = true;
  return this->texture_id_;
}

const FlutterDesktopPixelBuffer *
CaptureController::ConvertPixelBufferForFlutter(size_t width, size_t height) {
  if (this->source_buffer_data_ && this->source_buffer_size_ > 0 &&
      this->preview_frame_width_ > 0 && this->preview_frame_height_ > 0) {
    // printf("Flutter destination size: %zd,%zd\n", width, height);
    // fflush(stdout);

    // This is how texture buffer is copied as glTextImage
    // gl_.glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, pixel_buffer->width,
    //                pixel_buffer->height, 0, GL_RGBA, GL_UNSIGNED_BYTE,
    //                pixel_buffer->buffer);

    uint32_t pixels_total =
        this->preview_frame_width_ * this->preview_frame_height_;
    dest_buffer_ = std::make_unique<uint8_t[]>(pixels_total * 4);

    MFVideoFormat_RGB32_Pixel *src =
        (MFVideoFormat_RGB32_Pixel *)this->source_buffer_data_.get();
    FlutterDesktop_Pixel *dst = (FlutterDesktop_Pixel *)dest_buffer_.get();

    for (uint32_t i = 0; i < pixels_total; i++) {
      dst[i].r = src[i].r;
      dst[i].g = src[i].g;
      dst[i].b = src[i].b;
      dst[i].a = 255;
    }

    this->flutter_desktop_pixel_buffer_.buffer = dest_buffer_.get();
    this->flutter_desktop_pixel_buffer_.width = this->preview_frame_width_;
    this->flutter_desktop_pixel_buffer_.height = this->preview_frame_height_;
    // this->flutter_desktop_pixel_buffer_.release_context = this;
    // this->flutter_desktop_pixel_buffer_.release_callback =
    //     [](void *release_context) {
    //       std::cout << "Should release pixel buffer\n";
    //     };
    return &this->flutter_desktop_pixel_buffer_;
  }
  return nullptr;
}

bool CaptureController::TakePicture(const std::string filepath) {
  if (!initialized_ && pending_picture_) {
    return false;
  }

  HRESULT hr = InitPhotoSink(filepath);

  if (SUCCEEDED(hr) && !photo_capture_event_) {
    // Init photo event handle
    photo_capture_event_ = CreateEvent(nullptr, false, false, nullptr);
  } else {
    ResetEvent(photo_capture_event_);
  }

  if (SUCCEEDED(hr)) {
    pending_picture_ = true;
    hr = capture_engine_->TakePhoto();
  }

  if (SUCCEEDED(hr)) {
    // FIXME: use asyncronoys camera_platform_interface implementation
    // This is blocking the main thread
    WaitForSingleObject(photo_capture_event_, event_timeout_ms);
    printf("Photo Taken: success %d\n", photo_capture_success_);
    fflush(stdout);
    return photo_capture_success_;
  }

  pending_picture_ = false;
  return SUCCEEDED(hr);
}

void CaptureController::OnPicture(bool success) {
  photo_capture_success_ = success;
  if (pending_picture_ && photo_capture_event_) {
    SetEvent(photo_capture_event_);
  }
  pending_picture_ = false;
}

void CaptureController::OnRecordStarted(bool success) { recording_ = success; };

void CaptureController::OnRecordStopped(bool success) {
  video_capture_success_ = success;

  printf("OnRecordStopped: success: %d\n", video_capture_success_);
  fflush(stdout);

  if (recording_ && video_capture_event_) {
    SetEvent(video_capture_event_);
  }
  recording_ = false;
}

bool CaptureController::StartRecord(const std::string &filepath) {
  if (!initialized_ && recording_ == true) {
    return false;
  }

  HRESULT hr = InitRecordSink(filepath);

  if (SUCCEEDED(hr)) {
    pending_record_path_ = filepath;

    hr = capture_engine_->StartRecord();
  }

  return SUCCEEDED(hr);
}

std::string CaptureController::StopRecord() {
  if (!initialized_ && recording_ == false) {
    return "";
  }
  video_capture_success_ = false;

  HRESULT hr = capture_engine_->StopRecord(true, false);

  if (SUCCEEDED(hr) && !video_capture_event_) {
    // Init video capture event handle
    video_capture_event_ = CreateEvent(nullptr, false, false, nullptr);
  } else {
    ResetEvent(video_capture_event_);
  }

  if (SUCCEEDED(hr)) {
    // FIXME: use asyncronoys camera_platform_interface implementation
    // This is blocking the main thread
    WaitForSingleObject(video_capture_event_, event_timeout_ms);
    printf("Video capture success: %d\n", video_capture_success_);
    fflush(stdout);
  }

  if (video_capture_success_) {
    return pending_record_path_;
  }
  return "";
}

uint32_t CaptureController::GetMaxPreviewHeight() {
  switch (resolution_preset_) {
    case RESOLUTION_PRESET_LOW:
      return 240;
      break;
    case RESOLUTION_PRESET_MEDIUM:
      return 480;
      break;
    case RESOLUTION_PRESET_HIGH:
      return 720;
      break;
    case RESOLUTION_PRESET_VERY_HIGH:
      return 1080;
      break;
    case RESOLUTION_PRESET_ULTRA_HIGH:
      return 2160;
      break;
    case RESOLUTION_PRESET_AUTO:
    default:
      // no limit
      return 0xffffffff;
      break;
  }
}

HRESULT CaptureController::FindBaseMediaTypes() {
  if (!initialized_) {
    return E_FAIL;
  }

  IMFCaptureSource *source = nullptr;
  HRESULT hr = capture_engine_->GetSource(&source);

  if (SUCCEEDED(hr)) {
    IMFMediaType *media_type = nullptr;
    uint32_t max_height = GetMaxPreviewHeight();

    // Loop native media types
    for (int i = 0;; i++) {
      // Release media type if exists from previous loop;
      Release(&media_type);

      if (FAILED(source->GetAvailableDeviceMediaType(
              (DWORD)
                  MF_CAPTURE_ENGINE_PREFERRED_SOURCE_STREAM_FOR_VIDEO_PREVIEW,
              i, &media_type))) {
        break;
      }

      uint32_t frame_width;
      uint32_t frame_height;
      if (SUCCEEDED(MFGetAttributeSize(media_type, MF_MT_FRAME_SIZE,
                                       &frame_width, &frame_height))) {
        // Update media type for photo and record capture
        if (capture_frame_width_ < frame_width ||
            capture_frame_height_ < frame_height) {
          // Release old base type if allocated
          Release(&base_capture_media_type);

          base_capture_media_type = media_type;
          base_capture_media_type->AddRef();

          capture_frame_width_ = frame_width;
          capture_frame_height_ = frame_height;
        }

        // Update media type for preview
        if (frame_height <= max_height &&
            (preview_frame_width_ < frame_width ||
             preview_frame_height_ < frame_height)) {
          // Release old base type if allocated
          Release(&base_preview_media_type);

          base_preview_media_type = media_type;
          base_preview_media_type->AddRef();

          preview_frame_width_ = frame_width;
          preview_frame_height_ = frame_height;
        }

        printf("Available frame size: width: %d, height: %d\n", frame_width,
               frame_height);
        fflush(stdout);
      }
    }
    Release(&media_type);

    if (base_preview_media_type && base_capture_media_type) {
      hr = S_OK;
    } else {
      hr = E_FAIL;
    }
  }

  Release(&source);
  return hr;
}

HRESULT CaptureController::InitPreviewSink() {
  if (!initialized_) {
    return E_FAIL;
  }

  HRESULT hr = S_OK;
  if (preview_sink_) {
    return hr;
  }

  IMFMediaType *preview_media_type = nullptr;
  IMFCaptureSink *capture_sink = nullptr;

  // Get sink with preview type;
  hr = capture_engine_->GetSink(MF_CAPTURE_ENGINE_SINK_TYPE_PREVIEW,
                                &capture_sink);

  if (SUCCEEDED(hr)) {
    hr = capture_sink->QueryInterface(IID_PPV_ARGS(&preview_sink_));
  }

  Release(&capture_sink);

  if (SUCCEEDED(hr) && !base_preview_media_type) {
    hr = FindBaseMediaTypes();
  }

  if (SUCCEEDED(hr)) {
    hr = BuildMediaTypeForVideoPreview(base_preview_media_type,
                                       &preview_media_type);
  }

  if (SUCCEEDED(hr)) {
    DWORD preview_sink_stream_index;
    hr = preview_sink_->AddStream(
        (DWORD)MF_CAPTURE_ENGINE_PREFERRED_SOURCE_STREAM_FOR_VIDEO_PREVIEW,
        preview_media_type, nullptr, &preview_sink_stream_index);

    if (SUCCEEDED(hr)) {
      hr = preview_sink_->SetSampleCallback(preview_sink_stream_index,
                                            capture_engine_callback_);
    }
  }

  return hr;
}

HRESULT CaptureController::InitPhotoSink(const std::string &filepath) {
  HRESULT hr = S_OK;

  if (photo_sink_) {
    // If photo sink already exists, only update output filename
    hr = photo_sink_->SetOutputFileName(Utf16FromUtf8(filepath).c_str());
    return hr;
  }

  IMFMediaType *photo_media_type = nullptr;
  IMFCaptureSink *capture_sink = nullptr;

  // Get sink with photo type;
  hr = capture_engine_->GetSink(MF_CAPTURE_ENGINE_SINK_TYPE_PHOTO,
                                &capture_sink);

  if (SUCCEEDED(hr)) {
    hr = capture_sink->QueryInterface(IID_PPV_ARGS(&photo_sink_));
  }

  Release(&capture_sink);

  if (SUCCEEDED(hr) && !base_capture_media_type) {
    hr = FindBaseMediaTypes();
  }

  if (SUCCEEDED(hr)) {
    hr = BuildMediaTypeForPhotoCapture(
        base_capture_media_type, &photo_media_type, GUID_ContainerFormatJpeg);
  }

  if (SUCCEEDED(hr)) {
    // Remove existing streams if available
    hr = photo_sink_->RemoveAllStreams();
  }

  if (SUCCEEDED(hr)) {
    DWORD dwSinkStreamIndex;
    hr = photo_sink_->AddStream(
        (DWORD)MF_CAPTURE_ENGINE_PREFERRED_SOURCE_STREAM_FOR_PHOTO,
        photo_media_type, nullptr, &dwSinkStreamIndex);
  }

  Release(&photo_media_type);

  if (SUCCEEDED(hr)) {
    hr = photo_sink_->SetOutputFileName(Utf16FromUtf8(filepath).c_str());
  }

  return hr;
}

HRESULT CaptureController::InitRecordSink(const std::string &filepath) {
  HRESULT hr = S_OK;

  if (record_sink_) {
    // If record sink already exists, only update output filename
    hr = record_sink_->SetOutputFileName(Utf16FromUtf8(filepath).c_str());
    return hr;
  }

  IMFMediaType *video_record_media_type = nullptr;
  IMFCaptureSink *capture_sink = nullptr;

  // Get sink with record type;
  hr = capture_engine_->GetSink(MF_CAPTURE_ENGINE_SINK_TYPE_RECORD,
                                &capture_sink);

  if (SUCCEEDED(hr)) {
    hr = capture_sink->QueryInterface(IID_PPV_ARGS(&record_sink_));
  }

  if (SUCCEEDED(hr) && !base_capture_media_type) {
    hr = FindBaseMediaTypes();
  }

  if (SUCCEEDED(hr)) {
    // Remove existing streams if available
    hr = record_sink_->RemoveAllStreams();
  }

  if (SUCCEEDED(hr)) {
    hr = BuildMediaTypeForVideoCapture(
        base_capture_media_type, &video_record_media_type, MFVideoFormat_H264);
  }

  if (SUCCEEDED(hr)) {
    DWORD video_record_sink_stream_index;
    hr = record_sink_->AddStream(
        (DWORD)MF_CAPTURE_ENGINE_PREFERRED_SOURCE_STREAM_FOR_VIDEO_RECORD,
        video_record_media_type, nullptr, &video_record_sink_stream_index);
  }

  IMFMediaType *audio_record_media_type = nullptr;
  if (SUCCEEDED(hr)) {
    HRESULT audio_capture_hr = S_OK;
    audio_capture_hr = BuildMediaTypeForAudioCapture(&audio_record_media_type);

    if (SUCCEEDED(audio_capture_hr)) {
      DWORD audio_record_sink_stream_index;
      hr = record_sink_->AddStream(
          (DWORD)MF_CAPTURE_ENGINE_PREFERRED_SOURCE_STREAM_FOR_AUDIO,
          audio_record_media_type, nullptr, &audio_record_sink_stream_index);
    }
  }

  if (SUCCEEDED(hr)) {
    hr = record_sink_->SetOutputFileName(Utf16FromUtf8(filepath).c_str());
  }

  Release(&capture_sink);
  Release(&video_record_media_type);
  Release(&audio_record_media_type);
  return hr;
}

bool CaptureController::StopPreview() {
  if (!initialized_ || !previewing_) {
    return true;
  }

  HRESULT hr = capture_engine_->StopPreview();
  if (SUCCEEDED(hr)) {
    previewing_ = false;
  }
  return SUCCEEDED(hr);
}

bool CaptureController::StartPreview() {
  if (!initialized_) {
    return false;
  }

  if (previewing_ == true) {
    return true;
  }
  HRESULT hr = InitPreviewSink();

  if (SUCCEEDED(hr)) {
    hr = capture_engine_->StartPreview();
  }

  if (SUCCEEDED(hr)) {
    previewing_ = true;
  }

  return hr;
}

// Method from IUnknown
STDMETHODIMP_(ULONG) CaptureController::CaptureEngineCallback::AddRef() {
  return InterlockedIncrement(&ref_);
}
// Method from IUnknown
STDMETHODIMP_(ULONG) CaptureController::CaptureEngineCallback::Release() {
  LONG ref = InterlockedDecrement(&ref_);
  if (ref == 0) {
    delete this;
  }
  return ref;
}
// Method from IUnknown
STDMETHODIMP_(HRESULT)
CaptureController::CaptureEngineCallback::QueryInterface(const IID &riid,
                                                         void **ppv) {
  HRESULT hr = E_NOINTERFACE;
  *ppv = nullptr;

  if (riid == IID_IMFCaptureEngineOnEventCallback) {
    *ppv = static_cast<IMFCaptureEngineOnEventCallback *>(this);
    ((IUnknown *)*ppv)->AddRef();
    hr = S_OK;
  } else if (riid == IID_IMFCaptureEngineOnSampleCallback) {
    *ppv = static_cast<IMFCaptureEngineOnSampleCallback *>(this);
    ((IUnknown *)*ppv)->AddRef();
    hr = S_OK;
  }

  return hr;
}

STDMETHODIMP CaptureController::CaptureEngineCallback::OnEvent(
    IMFMediaEvent *event) {
  HRESULT event_hr;
  HRESULT hr = event->GetStatus(&event_hr);

  if (!capture_controller_->IsInitialized()) {
    return event_hr;
  }

  if (SUCCEEDED(hr)) {
    GUID extended_type_guid;
    hr = event->GetExtendedType(&extended_type_guid);
    if (SUCCEEDED(hr)) {
      if (extended_type_guid == MF_CAPTURE_ENGINE_ERROR) {
        printf("Got engine error event\n");
        fflush(stdout);
        // capture_controller_->OnCaptureEngineInitialized(SUCCEEDED(event_hr));
      } else if (extended_type_guid == MF_CAPTURE_ENGINE_INITIALIZED) {
        // capture_controller_->OnCaptureEngineInitialized(SUCCEEDED(event_hr));
      } else if (extended_type_guid == MF_CAPTURE_ENGINE_PREVIEW_STARTED) {
        // capture_controller_->OnPreviewStarted(SUCCEEDED(event_hr));
      } else if (extended_type_guid == MF_CAPTURE_ENGINE_PREVIEW_STOPPED) {
        // capture_controller_->OnPreviewStopped(SUCCEEDED(event_hr));
      } else if (extended_type_guid == MF_CAPTURE_ENGINE_RECORD_STARTED) {
        capture_controller_->OnRecordStarted(SUCCEEDED(event_hr));
      } else if (extended_type_guid == MF_CAPTURE_ENGINE_RECORD_STOPPED) {
        capture_controller_->OnRecordStopped(SUCCEEDED(event_hr));
      } else if (extended_type_guid == MF_CAPTURE_ENGINE_PHOTO_TAKEN) {
        capture_controller_->OnPicture(SUCCEEDED(event_hr));
      } else {
        LPOLESTR str;
        if (SUCCEEDED(StringFromCLSID(extended_type_guid, &str))) {
          std::wstring event_type((wchar_t *)str);

          // print unhandled event type here
          printf("Got unhandled capture event: %s\n",
                 Utf8FromUtf16(event_type).c_str());
          fflush(stdout);
        }
        CoTaskMemFree(str);
      }
    }
  }

  if (FAILED(event_hr)) {
    std::string message = std::system_category().message(event_hr);

    printf("Got capture event error: %s\n", message.c_str());
    fflush(stdout);
  }

  return event_hr;
}

// Method from IMFCaptureEngineOnSampleCallback
HRESULT CaptureController::CaptureEngineCallback::OnSample(IMFSample *sample) {
  // std::cout << "Got sample\n";
  HRESULT hr = S_OK;

  if (this->capture_controller_ == nullptr ||
      !this->capture_controller_->IsInitialized() ||
      !this->capture_controller_->IsPreviewing()) {
    // no texture target available or not previewing
    return hr;
  }

  if (SUCCEEDED(hr) && sample) {
    IMFMediaBuffer *buffer = nullptr;
    hr = sample->ConvertToContiguousBuffer(&buffer);

    // Draw the frame.
    if (SUCCEEDED(hr)) {
      DWORD max_length = 0;
      DWORD current_length = 0;
      uint8_t *data;
      if (SUCCEEDED(buffer->Lock(&data, &max_length, &current_length))) {
        uint8_t *src_buffer =
            this->capture_controller_->GetSourceBuffer(current_length);
        if (src_buffer) {
          CopyMemory(src_buffer, data, current_length);
        }
      }
      hr = buffer->Unlock();
      if (SUCCEEDED(hr)) {
        this->capture_controller_->OnBufferUpdate();
      }
    }

    if (buffer) {
      buffer->Release();
      buffer = nullptr;
    }
  }
  return hr;
}

}  // namespace camera_windows
