import 'package:hive_flutter/hive_flutter.dart';

import '../models/scan_models.dart';

/// Local storage repository backed by Hive for offline-first scan history.
class ScanStorageRepository {
  static const String _boxName = 'scan_history';

  Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<Map>(_boxName);
    }
  }

  Box<Map> get _box => Hive.box<Map>(_boxName);

  Future<void> saveScan(ScanResultData scan) async {
    await _box.put(scan.id, scan.toMap());
  }

  Future<bool> containsRawContent(String rawContent) async {
    final normalized = rawContent.trim();
    return _box.values.any(
      (item) => (item['rawContent'] as String?)?.trim() == normalized,
    );
  }

  Future<List<ScanResultData>> fetchAllScans() async {
    final items = _box.values
        .map((item) => ScanResultData.fromMap(item))
        .toList(growable: false)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  Future<ScanResultData?> fetchScanById(String id) async {
    final value = _box.get(id);
    if (value == null) return null;
    return ScanResultData.fromMap(value);
  }

  Future<void> deleteScan(String id) async {
    await _box.delete(id);
  }
}
