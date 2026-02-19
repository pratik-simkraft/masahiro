import 'package:flutter/material.dart';

import '../../models/scan_models.dart';

class ScanDetailScreen extends StatelessWidget {
  const ScanDetailScreen({super.key, required this.scan});

  final ScanResultData scan;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${scan.type.name}'),
            const SizedBox(height: 8),
            Text('Timestamp: ${scan.timestamp.toIso8601String()}'),
            const SizedBox(height: 8),
            const Text('Content:'),
            const SizedBox(height: 4),
            SelectableText(scan.rawContent),
          ],
        ),
      ),
    );
  }
}
