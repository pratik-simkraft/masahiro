import 'package:flutter/material.dart';

import 'src/models/scan_models.dart';
import 'src/scanner/qr_scanner_service.dart';
import 'src/storage/scan_storage_repository.dart';
import 'src/sync/scan_sync_service.dart';
import 'src/ui/screens/history_screen.dart';
import 'src/ui/screens/home_screen.dart';
import 'src/ui/screens/scan_detail_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageRepository = ScanStorageRepository();
  await storageRepository.init();

  final syncService = ScanSyncService();
  await syncService.init();

  runApp(
    MasahiroApp(
      storageRepository: storageRepository,
      syncService: syncService,
    ),
  );
}

class MasahiroApp extends StatefulWidget {
  const MasahiroApp({
    super.key,
    required this.storageRepository,
    required this.syncService,
  });

  final ScanStorageRepository storageRepository;
  final ScanSyncService syncService;

  @override
  State<MasahiroApp> createState() => _MasahiroAppState();
}

class _MasahiroAppState extends State<MasahiroApp> {
  late final QrScannerService _scannerService;
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();
  List<ScanResultData> _scans = const [];

  @override
  void initState() {
    super.initState();
    _scannerService = QrScannerService();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final scans = await widget.storageRepository.fetchAllScans();
    if (!mounted) return;
    setState(() => _scans = scans);
  }

  Future<void> _handleScan(ScanResultData scan) async {
    final alreadyScanned = await widget.storageRepository.containsRawContent(
      scan.rawContent,
    );

    if (alreadyScanned) {
      _messengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Already scanned. Not added to history.')),
      );
      return;
    }

    await widget.storageRepository.saveScan(scan);
    await widget.syncService.sendScan(scan);
    await _loadHistory();

    _messengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('Scan completed successfully.')),
    );
  }

  Future<void> _handleDelete(String id) async {
    await widget.storageRepository.deleteScan(id);
    await _loadHistory();
  }

  @override
  void dispose() {
    _scannerService.dispose();
    widget.syncService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _messengerKey,
      title: 'Masahiro',
      themeMode: ThemeMode.system,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      routes: {
        '/': (_) => HomeScreen(
              scannerService: _scannerService,
              onScan: _handleScan,
            ),
        '/history': (_) => HistoryScreen(scans: _scans, onDelete: _handleDelete),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/detail') {
          final scan = settings.arguments! as ScanResultData;
          return MaterialPageRoute(
            builder: (_) => ScanDetailScreen(scan: scan),
          );
        }
        return null;
      },
    );
  }
}
