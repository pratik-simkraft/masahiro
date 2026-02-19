import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/scan_models.dart';
import '../../scanner/qr_scanner_service.dart';
import '../../scanner/qr_scanner_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.scannerService,
    required this.onScan,
  });

  final QrScannerService scannerService;
  final ValueChanged<ScanResultData> onScan;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Masahiro Scanner')),
      body: Stack(
        children: [
          Positioned.fill(
            child: QrScannerWidget(
              service: scannerService,
              onScan: onScan,
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FilledButton.icon(
                  onPressed: () async {
                    final result = await scannerService.scanFromGallery();
                    if (result != null) onScan(result);
                  },
                  icon: const Icon(Icons.photo),
                  label: const Text('Gallery'),
                ),
                FilledButton.icon(
                  onPressed: scannerService.toggleTorchManually,
                  icon: const Icon(Icons.flash_on),
                  label: const Text('Flash'),
                ),
                IconButton(
                  onPressed: () => Navigator.pushNamed(context, '/history'),
                  icon: const Icon(Icons.history),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final status = await Permission.camera.status;
          if (!context.mounted || status.isGranted) return;
          _showStrictPermissionDialog(context);
        },
        label: const Text('Permission Help'),
        icon: const Icon(Icons.warning),
      ),
    );
  }

  void _showStrictPermissionDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('ERROR'),
        content: const Text('Camera access is required.'),
        actions: [
          TextButton(
            onPressed: () => openAppSettings(),
            child: const Text('Open Settings'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
