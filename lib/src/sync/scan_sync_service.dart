import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../models/scan_models.dart';

/// API sync service with offline queue + connectivity based retry.
class ScanSyncService {
  ScanSyncService({
    http.Client? client,
    Connectivity? connectivity,
  })  : _client = client ?? http.Client(),
        _connectivity = connectivity ?? Connectivity();

  static const String _queueBoxName = 'scan_sync_queue';
  static const String _apiUrl = 'https://example.com/api/scans';

  final http.Client _client;
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isProcessing = false;

  Future<void> init() async {
    if (!Hive.isBoxOpen(_queueBoxName)) {
      await Hive.openBox<Map>(_queueBoxName);
    }

    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      if (results.any((item) => item != ConnectivityResult.none)) {
        processQueue();
      }
    });
  }

  Box<Map> get _queueBox => Hive.box<Map>(_queueBoxName);

  /// Non-blocking send; queues when offline/failure and retries later.
  Future<void> sendScan(ScanResultData scan) async {
    final payload = _buildPayload(scan);
    final connected = await _isConnected();

    if (!connected) {
      await _enqueue(scan.id, payload);
      return;
    }

    final success = await _postPayload(payload);
    if (!success) {
      await _enqueue(scan.id, payload);
    }
  }

  Future<void> processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;
    try {
      final connected = await _isConnected();
      if (!connected) return;

      final keys = _queueBox.keys.cast<String>().toList(growable: false);
      for (final id in keys) {
        final payload = _queueBox.get(id);
        if (payload == null) continue;
        final success = await _postPayload(Map<String, dynamic>.from(payload));
        if (success) {
          await _queueBox.delete(id);
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  Map<String, dynamic> _buildPayload(ScanResultData scan) {
    return {
      'rawContent': scan.rawContent,
      'type': scan.type.name,
      'timestamp': scan.timestamp.toIso8601String(),
      'platform': defaultTargetPlatform.name,
    };
  }

  Future<void> _enqueue(String id, Map<String, dynamic> payload) async {
    if (_queueBox.containsKey(id)) return;
    await _queueBox.put(id, payload);
  }

  Future<bool> _postPayload(Map<String, dynamic> payload) async {
    try {
      final response = await _client.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (error) {
      debugPrint('Scan upload failed: $error');
      return false;
    }
  }

  Future<bool> _isConnected() async {
    final connectivity = await _connectivity.checkConnectivity();
    return connectivity.any((item) => item != ConnectivityResult.none);
  }

  Future<void> dispose() async {
    await _connectivitySub?.cancel();
    _client.close();
  }
}
