import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _cameraInfo = 'Unknown';
  List<CameraDescription> _cameras = <CameraDescription>[];
  int _cameraId = -1;
  bool _initialized = false;
  bool _recording = false;
  Size? _previewSize;

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    getAvailableCameras();
  }

  // Fetches list of available cameras from camera_windows plugin
  Future<void> getAvailableCameras() async {
    String cameraInfo;
    List<CameraDescription> cameras = <CameraDescription>[];

    try {
      cameras = await CameraPlatform.instance.availableCameras();
      if (cameras.isEmpty) {
        cameraInfo = 'No available cameras';
      } else {
        cameraInfo = "Found camera: ${cameras.first.name}";
      }
    } on PlatformException {
      cameraInfo = 'Failed to get cameras';
    }

    if (!mounted) return;

    setState(() {
      _cameras = cameras;
      _cameraInfo = cameraInfo;
    });
  }

  /// Initializes the camera on the device.
  void initializeFirstCamera() async {
    assert(_cameras.isNotEmpty);
    assert(!_initialized);
    try {
      Completer<CameraInitializedEvent> _initializeCompleter = Completer();

      final CameraDescription camera = _cameras.first;

      final cameraId = await CameraPlatform.instance.createCamera(
        camera,
        ResolutionPreset.veryHigh,
        enableAudio: true,
      );

      unawaited(CameraPlatform.instance
          .onCameraInitialized(cameraId)
          .first
          .then((event) {
        _initializeCompleter.complete(event);
      }));

      await CameraPlatform.instance.initializeCamera(
        cameraId,
        imageFormatGroup: ImageFormatGroup.unknown,
      );

      _previewSize = await _initializeCompleter.future
          .then((CameraInitializedEvent event) => Size(
                event.previewWidth,
                event.previewHeight,
              ));

      setState(() {
        _initialized = true;
        _cameraId = cameraId;
        _cameraInfo = "Capturing camera: ${camera.name}";
      });
    } on PlatformException catch (e) {
      setState(() {
        _initialized = false;
        _cameraId = -1;
        _cameraInfo = "Failed to initialize camera: ${e.code}: ${e.message}";
      });
    }
  }

  void disposeCurrentCamera() async {
    assert(_cameraId > 0);
    assert(_initialized);
    try {
      await CameraPlatform.instance.dispose(_cameraId);
      setState(() {
        _initialized = false;
        _cameraId = -1;
        _cameraInfo = "Camera disposed";
        _previewSize = null;
      });
      getAvailableCameras();
    } on PlatformException catch (e) {
      setState(() {
        _cameraInfo = "Failed to dispose camera: ${e.code}: ${e.message}";
      });
    }
  }

  Widget buildPreview() {
    return CameraPlatform.instance.buildPreview(_cameraId);
  }

  void takePicture() async {
    XFile _file = await CameraPlatform.instance.takePicture(_cameraId);
    if (!await launch("file:${_file.path}")) {
      throw 'Could not open file: "${_file.path}"';
    }
  }

  void toggleRecord() async {
    if (_initialized && _cameraId > 0) {
      if (!_recording) {
        await CameraPlatform.instance.startVideoRecording(_cameraId);
      } else {
        XFile _file =
            await CameraPlatform.instance.stopVideoRecording(_cameraId);

        if (!await launch("file:${_file.path}")) {
          throw 'Could not open file: "${_file.path}"';
        }
      }
      setState(() {
        _recording = !_recording;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: ListView(children: [
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: Text(_cameraInfo)),
          if (_cameras.isNotEmpty)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton(
                  onPressed: _initialized
                      ? disposeCurrentCamera
                      : initializeFirstCamera,
                  child:
                      Text(_initialized ? "Dispose camera" : "Create camera")),
              const SizedBox(width: 5),
              ElevatedButton(
                onPressed: _initialized ? takePicture : null,
                child: const Text("Take picture"),
              ),
              const SizedBox(width: 5),
              ElevatedButton(
                  onPressed: _initialized ? toggleRecord : null,
                  child: Text(_recording ? "Stop recording" : "Record Video"))
            ]),
          const SizedBox(height: 5),
          if (_initialized && _cameraId > 0 && _previewSize != null)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 500),
                      child: AspectRatio(
                          aspectRatio:
                              (_previewSize!.width / _previewSize!.height),
                          child: buildPreview()),
                    ))),
          if (_previewSize != null)
            Center(
                child: Text(
                    "Preview size: ${_previewSize!.width.toStringAsFixed(0)}x${_previewSize!.height.toStringAsFixed(0)}"))
        ]),
      ),
    );
  }
}
