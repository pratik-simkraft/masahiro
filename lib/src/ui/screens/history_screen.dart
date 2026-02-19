import 'package:flutter/material.dart';

import '../../models/scan_models.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({
    super.key,
    required this.scans,
    required this.onDelete,
  });

  final List<ScanResultData> scans;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan History')),
      body: ListView.builder(
        itemCount: scans.length,
        itemBuilder: (_, index) {
          final scan = scans[index];
          return ListTile(
            title: Text(scan.type.name.toUpperCase()),
            subtitle: Text(
              scan.rawContent,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => onDelete(scan.id),
            ),
            onTap: () => Navigator.pushNamed(
              context,
              '/detail',
              arguments: scan,
            ),
          );
        },
      ),
    );
  }
}
