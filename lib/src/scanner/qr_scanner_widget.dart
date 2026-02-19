import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/scan_models.dart';
import 'qr_scanner_service.dart';

/// Reusable scanner widget with lifecycle, strict permission alert and fallback.
class QrScannerWidget extends StatefulWidget {
  const QrScannerWidget({
    super.key,
    required this.service,
    required this.onScan,
  });

  final QrScannerService service;
  final Future<void> Function(ScanResultData) onScan;

  @override
  State<QrScannerWidget> createState() => _QrScannerWidgetState();
}

class _QrScannerWidgetState extends State<QrScannerWidget>
    with WidgetsBindingObserver {
  bool _permissionGranted = false;
  bool _isScanInProgress = false;
  String? _lastScannedRawContent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    final status = await widget.service.requestCameraPermission();
    if (!mounted) return;

    if (!status.isGranted) {
      _showPermissionError();
      setState(() => _permissionGranted = false);
      return;
    }

    setState(() => _permissionGranted = true);
    widget.service.startAutoLightMonitoring();
    await widget.service.resumeCamera();
  }

  void _showPermissionError() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('ERROR'),
        content: const Text('Camera access is required.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_permissionGranted) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      widget.service.pauseCamera();
    }
    if (state == AppLifecycleState.resumed) {
      widget.service.resumeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionGranted) {
      return const Center(child: Text('Camera unavailable. Use gallery scan.'));
    }

    return MobileScanner(
      controller: widget.service.controller,
      onDetect: (capture) async {
        if (_isScanInProgress) return;

        final result = widget.service.fromBarcodeCapture(capture);
        if (result == null) return;
        if (_lastScannedRawContent == result.rawContent) return;

        _lastScannedRawContent = result.rawContent;
        _isScanInProgress = true;
        await widget.service.pauseCamera();
        try {
          await widget.onScan(result);
        } finally {
          if (mounted) {
            _isScanInProgress = false;
            await widget.service.resumeCamera();
          }
        }
      },
    );
  }
}
