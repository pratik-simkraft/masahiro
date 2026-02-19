import 'dart:convert';

enum QrDataType { url, text, vcard, wifi, email, phone, sms, geo, unknown }

QrDataType detectQrDataType(String raw) {
  final value = raw.trim();
  final upper = value.toUpperCase();

  if (value.startsWith('http://') || value.startsWith('https://')) {
    return QrDataType.url;
  }
  if (upper.startsWith('BEGIN:VCARD')) return QrDataType.vcard;
  if (upper.startsWith('WIFI:')) return QrDataType.wifi;
  if (upper.startsWith('MAILTO:') || upper.startsWith('MATMSG:')) {
    return QrDataType.email;
  }
  if (upper.startsWith('TEL:')) return QrDataType.phone;
  if (upper.startsWith('SMSTO:') || upper.startsWith('SMS:')) return QrDataType.sms;
  if (upper.startsWith('GEO:')) return QrDataType.geo;

  final parsedUri = Uri.tryParse(value);
  if (parsedUri != null && parsedUri.hasScheme && parsedUri.host.isNotEmpty) {
    return QrDataType.url;
  }

  return value.isEmpty ? QrDataType.unknown : QrDataType.text;
}

class ScanResultData {
  const ScanResultData({
    required this.id,
    required this.rawContent,
    required this.type,
    required this.timestamp,
  });

  final String id;
  final String rawContent;
  final QrDataType type;
  final DateTime timestamp;

  ScanResultData copyWith({
    String? id,
    String? rawContent,
    QrDataType? type,
    DateTime? timestamp,
  }) {
    return ScanResultData(
      id: id ?? this.id,
      rawContent: rawContent ?? this.rawContent,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rawContent': rawContent,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ScanResultData.fromMap(Map<dynamic, dynamic> map) {
    return ScanResultData(
      id: map['id'] as String,
      rawContent: map['rawContent'] as String,
      type: QrDataType.values.firstWhere(
        (item) => item.name == map['type'],
        orElse: () => QrDataType.unknown,
      ),
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory ScanResultData.fromJson(String source) =>
      ScanResultData.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
