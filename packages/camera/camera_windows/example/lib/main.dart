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

  Widget? _texture;

  bool _initialized = false;
  bool _recording = false;

  Size? _previewSize;

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    initCameraList().then((value) {
      debugPrint("Got list of available cameras: ${_cameras.isNotEmpty}");
      if (_cameras.isNotEmpty) {
        initializeCamera();
      }
    });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initCameraList() async {
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
  ///
  /// Throws a [CameraException] if the initialization fails.
  Future<void> initializeCamera() async {
    try {
      Completer<CameraInitializedEvent> _initializeCompleter = Completer();

      _cameraId = await CameraPlatform.instance.createCamera(
        _cameras.first,
        ResolutionPreset.veryHigh,
        enableAudio: true,
      );

      debugPrint("Got camera id: $_cameraId");

      unawaited(CameraPlatform.instance
          .onCameraInitialized(_cameraId)
          .first
          .then((event) {
        _initializeCompleter.complete(event);
      }));

      await CameraPlatform.instance.initializeCamera(
        _cameraId,
        imageFormatGroup: ImageFormatGroup.unknown,
      );

      debugPrint("Camera (${_cameraId}) initialized");

      _previewSize = await _initializeCompleter.future
          .then((CameraInitializedEvent event) => Size(
                event.previewWidth,
                event.previewHeight,
              ));

      debugPrint("PreviewSize $_previewSize");

      setState(() {
        _initialized = true;
        _texture = CameraPlatform.instance.buildPreview(_cameraId);
      });
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  void TakePicture() async {
    XFile _file = await CameraPlatform.instance.takePicture(_cameraId);
    debugPrint("File path: ${_file.path}, length: ${await _file.length()}");
    if (!await launch("file:${_file.path}"))
      throw 'Could not open file: "${_file.path}"';
  }

  void ToggleRecord() async {
    if (_initialized && _cameraId > 0) {
      if (!_recording) {
        await CameraPlatform.instance.startVideoRecording(_cameraId);
      } else {
        XFile _file =
            await CameraPlatform.instance.stopVideoRecording(_cameraId);

        debugPrint(
            "Video capture file path: ${_file.path}, length: ${await _file.length()}");
        if (!await launch("file:${_file.path}"))
          throw 'Could not open file: "${_file.path}"';
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
          Text('Camerainfo: $_cameraInfo'),
          SizedBox(height: 5),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            TextButton(
                onPressed: _initialized ? TakePicture : null,
                child: Text("Take picture")),
            SizedBox(width: 5),
            TextButton(
                onPressed: _initialized ? ToggleRecord : null,
                child: Text(_recording ? "Stop recording" : "Record Video"))
          ]),
          SizedBox(height: 5),
          if (_texture != null && _preview_size != null)
            Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Align(
                    alignment: Alignment.center,
                    child: Container(
                        height: 500,
                        width: 500 *
                            (_preview_size!.width / _preview_size!.height),
                        child: _texture!))),
          if (_preview_size != null)
            Center(
                child: Text(
                    "Preview size: ${_preview_size!.width.toStringAsFixed(0)}x${_preview_size!.height.toStringAsFixed(0)}"))
        ]),
      ),
    );
  }
}
