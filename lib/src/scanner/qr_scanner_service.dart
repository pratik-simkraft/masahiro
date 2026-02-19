import 'dart:async';

import 'package:ambient_light/ambient_light.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../models/scan_models.dart';

/// Isolated scanner service for camera, gallery decode, permissions and flash.
class QrScannerService {
  QrScannerService({MobileScannerController? controller, AmbientLight? ambientLight})
      : _controller =
            controller ?? MobileScannerController(formats: [BarcodeFormat.qrCode]),
        _ambientLight = ambientLight ?? AmbientLight();

  final MobileScannerController _controller;
  final AmbientLight _ambientLight;
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  StreamSubscription<int>? _lightSubscription;
  bool _userSetTorch = false;
  bool _autoTorchEnabled = false;

  MobileScannerController get controller => _controller;

  Future<PermissionStatus> requestCameraPermission() => Permission.camera.request();

  Future<bool> isCameraPermissionGranted() async => Permission.camera.isGranted;

  /// Starts ambient light monitoring and auto-enables torch when light is low.
  void startAutoLightMonitoring({int luxThreshold = 20}) {
    _lightSubscription?.cancel();
    _lightSubscription = _ambientLight.ambientLightStream.listen((lux) {
      if (_userSetTorch) return;
      final lowLight = lux <= luxThreshold;
      if (lowLight && !_autoTorchEnabled) {
        _controller.toggleTorch();
        _autoTorchEnabled = true;
      } else if (!lowLight && _autoTorchEnabled) {
        _controller.toggleTorch();
        _autoTorchEnabled = false;
      }
    });
  }

  Future<void> stopAutoLightMonitoring() async {
    await _lightSubscription?.cancel();
    _lightSubscription = null;
  }

  Future<void> toggleTorchManually() async {
    _userSetTorch = true;
    await _controller.toggleTorch();
  }

  Future<ScanResultData?> scanFromGallery() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;

    final capture = await _controller.analyzeImage(file.path);
    if (capture == null || capture.barcodes.isEmpty) return null;

    final value = capture.barcodes.first.rawValue;
    if (value == null || value.isEmpty) return null;

    return ScanResultData(
      id: _uuid.v4(),
      rawContent: value,
      type: detectQrDataType(value),
      timestamp: DateTime.now(),
    );
  }

  ScanResultData? fromBarcodeCapture(BarcodeCapture capture) {
    if (capture.barcodes.isEmpty) return null;
    final value = capture.barcodes.first.rawValue;
    if (value == null || value.isEmpty) return null;

    return ScanResultData(
      id: _uuid.v4(),
      rawContent: value,
      type: detectQrDataType(value),
      timestamp: DateTime.now(),
    );
  }

  Future<void> pauseCamera() => _controller.stop();

  Future<void> resumeCamera() => _controller.start();

  Future<void> dispose() async {
    await stopAutoLightMonitoring();
    await _controller.dispose();
  }
}
