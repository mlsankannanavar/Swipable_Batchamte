import 'package:uuid/uuid.dart';
import '../utils/log_level.dart';

class LogEntry {
  final String id;
  final DateTime timestamp;
  final LogLevel level;
  final String category;
  final String message;
  final Map<String, dynamic>? data;
  final Duration? duration;
  final String? url;
  final int? statusCode;
  final Map<String, String>? headers;
  final dynamic requestBody;
  final dynamic responseBody;
  final Object? error;
  final StackTrace? stackTrace;

  LogEntry({
    String? id,
    required this.timestamp,
    required this.level,
    required this.category,
    required this.message,
    this.data,
    this.duration,
    this.url,
    this.statusCode,
    this.headers,
    this.requestBody,
    this.responseBody,
    this.error,
    this.stackTrace,
  }) : id = id ?? const Uuid().v4();

  // Factory constructors for different log types
  factory LogEntry.apiRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    dynamic body,
  }) {
    return LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.info,
      category: 'API-OUT',
      message: '$method $url',
      url: url,
      headers: headers,
      requestBody: body,
      data: {
        'method': method,
        'url': url,
        'headers': headers,
        'body': body,
      },
    );
  }

  factory LogEntry.apiResponse({
    required String method,
    required String url,
    required int statusCode,
    required Duration duration,
    Map<String, String>? headers,
    dynamic body,
  }) {
    final level = statusCode >= 200 && statusCode < 300 
        ? LogLevel.success 
        : statusCode >= 400 
            ? LogLevel.error 
            : LogLevel.warning;

    return LogEntry(
      timestamp: DateTime.now(),
      level: level,
      category: 'API-IN',
      message: '$method $url - $statusCode ${_getStatusText(statusCode)} (${duration.inMilliseconds}ms)',
      url: url,
      statusCode: statusCode,
      duration: duration,
      headers: headers,
      responseBody: body,
      data: {
        'method': method,
        'url': url,
        'statusCode': statusCode,
        'duration': duration.inMilliseconds,
        'headers': headers,
        'body': body,
      },
    );
  }

  factory LogEntry.qrScan({
    required String message,
    String? qrData,
    bool success = true,
  }) {
    return LogEntry(
      timestamp: DateTime.now(),
      level: success ? LogLevel.success : LogLevel.error,
      category: 'QR-SCAN',
      message: message,
      data: qrData != null ? {'qrData': qrData} : null,
    );
  }

  factory LogEntry.ocr({
    required String message,
    String? extractedText,
    double? confidence,
    bool success = true,
  }) {
    return LogEntry(
      timestamp: DateTime.now(),
      level: success ? LogLevel.success : LogLevel.error,
      category: 'OCR',
      message: message,
      data: {
        if (extractedText != null) 'extractedText': extractedText,
        if (confidence != null) 'confidence': confidence,
      },
    );
  }

  factory LogEntry.error({
    required String message,
    Object? error,
    StackTrace? stackTrace,
    String category = 'ERROR',
  }) {
    return LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.error,
      category: category,
      message: message,
      error: error,
      stackTrace: stackTrace,
      data: {
        'error': error?.toString(),
        'stackTrace': stackTrace?.toString(),
      },
    );
  }

  factory LogEntry.app({
    required String message,
    LogLevel level = LogLevel.info,
    Map<String, dynamic>? data,
  }) {
    return LogEntry(
      timestamp: DateTime.now(),
      level: level,
      category: 'APP',
      message: message,
      data: data,
    );
  }

  factory LogEntry.network({
    required String message,
    LogLevel level = LogLevel.info,
    Map<String, dynamic>? data,
  }) {
    return LogEntry(
      timestamp: DateTime.now(),
      level: level,
      category: 'NETWORK',
      message: message,
      data: data,
    );
  }

  // Convert to/from Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'level': level.toString(),
      'category': category,
      'message': message,
      'data': data,
      'duration': duration?.inMilliseconds,
      'url': url,
      'statusCode': statusCode,
      'headers': headers,
      'requestBody': requestBody?.toString(),
      'responseBody': responseBody?.toString(),
      'error': error?.toString(),
      'stackTrace': stackTrace?.toString(),
    };
  }

  factory LogEntry.fromMap(Map<String, dynamic> map) {
    return LogEntry(
      id: map['id'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      level: LogLevel.values.firstWhere(
        (e) => e.toString() == map['level'],
        orElse: () => LogLevel.info,
      ),
      category: map['category'],
      message: map['message'],
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
      duration: map['duration'] != null 
          ? Duration(milliseconds: map['duration']) 
          : null,
      url: map['url'],
      statusCode: map['statusCode'],
      headers: map['headers'] != null 
          ? Map<String, String>.from(map['headers']) 
          : null,
      requestBody: map['requestBody'],
      responseBody: map['responseBody'],
      error: map['error'],
      stackTrace: map['stackTrace'] != null 
          ? StackTrace.fromString(map['stackTrace']) 
          : null,
    );
  }

  // Helper methods
  String get levelText => level.name.toUpperCase();
  
  String get formattedTimestamp {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}:'
           '${timestamp.second.toString().padLeft(2, '0')}.'
           '${timestamp.millisecond.toString().padLeft(3, '0')}';
  }

  String get fullFormattedTimestamp {
    return '${timestamp.year}-'
           '${timestamp.month.toString().padLeft(2, '0')}-'
           '${timestamp.day.toString().padLeft(2, '0')} '
           '$formattedTimestamp';
  }

  bool get hasError => error != null;
  bool get hasStackTrace => stackTrace != null;
  bool get hasData => data != null && data!.isNotEmpty;
  bool get isApiLog => category.startsWith('API');
  bool get isErrorLog => level == LogLevel.error;

  String toLogString() {
    final buffer = StringBuffer();
    buffer.writeln('[$fullFormattedTimestamp] [$levelText] [$category] $message');
    
    if (hasData) {
      buffer.writeln('Data: $data');
    }
    
    if (hasError) {
      buffer.writeln('Error: $error');
    }
    
    if (hasStackTrace) {
      buffer.writeln('Stack Trace: $stackTrace');
    }
    
    return buffer.toString();
  }

  static String _getStatusText(int statusCode) {
    switch (statusCode) {
      case 200: return 'OK';
      case 201: return 'Created';
      case 400: return 'Bad Request';
      case 401: return 'Unauthorized';
      case 403: return 'Forbidden';
      case 404: return 'Not Found';
      case 500: return 'Internal Server Error';
      case 502: return 'Bad Gateway';
      case 503: return 'Service Unavailable';
      case 504: return 'Gateway Timeout';
      default: return 'Unknown';
    }
  }

  @override
  String toString() {
    return 'LogEntry(id: $id, timestamp: $timestamp, level: $level, category: $category, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LogEntry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
