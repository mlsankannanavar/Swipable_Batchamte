import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/log_entry_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/log_level.dart';

class LoggingService extends ChangeNotifier {
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  LoggingService._internal();

  Box<Map<dynamic, dynamic>>? _logsBox;
  final List<LogEntry> _logs = [];
  bool _isInitialized = false;
  int _maxLogs = Constants.maxLogsCount;
  bool _enableLogging = Constants.defaultEnableLogging;

  // Getters
  List<LogEntry> get logs => List.unmodifiable(_logs);
  bool get isInitialized => _isInitialized;
  int get logCount => _logs.length;
  bool get hasLogs => _logs.isNotEmpty;
  bool get hasErrors => _logs.any((log) => log.level == LogLevel.error);
  bool get hasNewErrors => _logs.where((log) => log.level == LogLevel.error)
      .any((log) => DateTime.now().difference(log.timestamp).inMinutes < 5);
  int get maxLogs => _maxLogs;
  bool get enableLogging => _enableLogging;

  // Initialize the logging service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logsBox = await Hive.openBox<Map<dynamic, dynamic>>(Constants.logsBoxKey);
      await _loadLogsFromStorage();
      _isInitialized = true;
      
      log(LogEntry.app(
        message: 'Logging service initialized successfully',
        level: LogLevel.info,
        data: {'maxLogs': _maxLogs, 'enableLogging': _enableLogging},
      ));
    } catch (e) {
      debugPrint('Failed to initialize logging service: $e');
    }
  }

  // Main logging method
  void log(LogEntry entry) {
    if (!_enableLogging) return;

    _logs.add(entry);
    
    // Maintain maximum log count
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }

    // Save to storage
    _saveLogToStorage(entry);
    
    // Notify listeners
    notifyListeners();

    // Debug print in development
    if (kDebugMode) {
      debugPrint(entry.toLogString());
    }
  }

  // Convenience methods for different log types
  void logApiRequest(String method, String url, {
    Map<String, String>? headers,
    dynamic body,
  }) {
    log(LogEntry.apiRequest(
      method: method,
      url: url,
      headers: headers,
      body: body,
    ));
  }

  void logApiResponse(String method, String url, int statusCode, Duration duration, {
    Map<String, String>? headers,
    dynamic body,
  }) {
    log(LogEntry.apiResponse(
      method: method,
      url: url,
      statusCode: statusCode,
      duration: duration,
      headers: headers,
      body: body,
    ));
  }

  void logQrScan(String message, {String? qrData, bool success = true}) {
    log(LogEntry.qrScan(
      message: message,
      qrData: qrData,
      success: success,
    ));
  }

  void logOcr(String message, {
    String? extractedText,
    double? confidence,
    bool success = true,
  }) {
    log(LogEntry.ocr(
      message: message,
      extractedText: extractedText,
      confidence: confidence,
      success: success,
    ));
  }

  void logError(String message, {
    Object? error,
    StackTrace? stackTrace,
    String category = 'ERROR',
  }) {
    log(LogEntry.error(
      message: message,
      error: error,
      stackTrace: stackTrace,
      category: category,
    ));
  }

  void logApp(String message, {
    LogLevel level = LogLevel.info,
    Map<String, dynamic>? data,
    Map<String, dynamic>? additionalData,
  }) {
    log(LogEntry.app(
      message: message,
      level: level,
      data: data ?? additionalData,
    ));
  }

  // Alias methods for different naming conventions
  void logQRScan(String message, {String? qrData, bool success = true}) {
    logQrScan(message, qrData: qrData, success: success);
  }

  void logOCR(String message, {
    String? extractedText,
    double? confidence,
    bool success = true,
  }) {
    logOcr(message, 
        extractedText: extractedText, 
        confidence: confidence, 
        success: success);
  }

  void logWarning(String message, {Map<String, dynamic>? additionalData}) {
    logApp(message, level: LogLevel.warning, additionalData: additionalData);
  }

  void logNetwork(String message, {
    LogLevel level = LogLevel.info,
    Map<String, dynamic>? data,
  }) {
    log(LogEntry.network(
      message: message,
      level: level,
      data: data,
    ));
  }

  // Filter logs by level
  List<LogEntry> getLogsByLevel(LogLevel level) {
    return _logs.where((log) => log.level == level).toList();
  }

  // Filter logs by category
  List<LogEntry> getLogsByCategory(String category) {
    return _logs.where((log) => log.category == category).toList();
  }

  // Search logs
  List<LogEntry> searchLogs(String query) {
    if (query.isEmpty) return logs;
    
    final lowerQuery = query.toLowerCase();
    return _logs.where((log) => 
      log.message.toLowerCase().contains(lowerQuery) ||
      log.category.toLowerCase().contains(lowerQuery) ||
      (log.data?.toString().toLowerCase().contains(lowerQuery) ?? false)
    ).toList();
  }

  // Filter logs by time range
  List<LogEntry> getLogsByTimeRange(DateTime start, DateTime end) {
    return _logs.where((log) => 
      log.timestamp.isAfter(start) && log.timestamp.isBefore(end)
    ).toList();
  }

  // Get recent logs (last N minutes)
  List<LogEntry> getRecentLogs(int minutes) {
    final cutoff = DateTime.now().subtract(Duration(minutes: minutes));
    return _logs.where((log) => log.timestamp.isAfter(cutoff)).toList();
  }

  // Clear all logs
  void clearLogs() {
    _logs.clear();
    _logsBox?.clear();
    notifyListeners();
    
    log(LogEntry.app(
      message: 'All logs cleared',
      level: LogLevel.info,
    ));
  }

  // Export logs to string
  String exportLogsAsString({List<LogEntry>? specificLogs}) {
    final logsToExport = specificLogs ?? _logs;
    final buffer = StringBuffer();
    
    buffer.writeln('BatchMate Application Logs');
    buffer.writeln('Generated: ${Helpers.formatDateTime(DateTime.now())}');
    buffer.writeln('Total Logs: ${logsToExport.length}');
    buffer.writeln('=' * 50);
    buffer.writeln();
    
    for (final log in logsToExport) {
      buffer.writeln(log.toLogString());
      buffer.writeln();
    }
    
    return buffer.toString();
  }

  // Export logs to file and share
  Future<void> exportLogs({List<LogEntry>? specificLogs}) async {
    try {
      final logsString = exportLogsAsString(specificLogs: specificLogs);
      final fileName = Helpers.generateLogFileName();
      
      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      
      // Write logs to file
      await file.writeAsString(logsString);
      
      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'BatchMate Application Logs',
        subject: 'BatchMate Logs - ${Helpers.formatDateOnly(DateTime.now())}',
      );
      
      logApp('Logs exported successfully', data: {'fileName': fileName});
    } catch (e, stackTrace) {
      logError('Failed to export logs', error: e, stackTrace: stackTrace);
    }
  }

  // Settings management
  void setMaxLogs(int maxLogs) {
    _maxLogs = maxLogs;
    
    // Trim logs if necessary
    if (_logs.length > _maxLogs) {
      final excess = _logs.length - _maxLogs;
      _logs.removeRange(0, excess);
      notifyListeners();
    }
    
    logApp('Max logs setting updated', data: {'maxLogs': maxLogs});
  }

  void setEnableLogging(bool enable) {
    _enableLogging = enable;
    logApp('Logging ${enable ? 'enabled' : 'disabled'}');
  }

  // Private methods
  Future<void> _loadLogsFromStorage() async {
    if (_logsBox == null) return;

    try {
      final storedLogs = _logsBox!.values.toList();
      _logs.clear();
      
      for (final logMap in storedLogs) {
        try {
          final log = LogEntry.fromMap(Map<String, dynamic>.from(logMap));
          _logs.add(log);
        } catch (e) {
          debugPrint('Failed to parse stored log: $e');
        }
      }
      
      // Sort by timestamp
      _logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      // Maintain max logs count
      if (_logs.length > _maxLogs) {
        final excess = _logs.length - _maxLogs;
        _logs.removeRange(0, excess);
        await _trimStoredLogs();
      }
    } catch (e) {
      debugPrint('Failed to load logs from storage: $e');
    }
  }

  Future<void> _saveLogToStorage(LogEntry entry) async {
    if (_logsBox == null) return;

    try {
      await _logsBox!.put(entry.id, entry.toMap());
    } catch (e) {
      debugPrint('Failed to save log to storage: $e');
    }
  }

  Future<void> _trimStoredLogs() async {
    if (_logsBox == null) return;

    try {
      await _logsBox!.clear();
      for (final log in _logs) {
        await _logsBox!.put(log.id, log.toMap());
      }
    } catch (e) {
      debugPrint('Failed to trim stored logs: $e');
    }
  }

  // Statistics
  Map<LogLevel, int> getLogCountByLevel() {
    final counts = <LogLevel, int>{};
    for (final level in LogLevel.values) {
      counts[level] = _logs.where((log) => log.level == level).length;
    }
    return counts;
  }

  Map<String, int> getLogCountByCategory() {
    final counts = <String, int>{};
    for (final log in _logs) {
      counts[log.category] = (counts[log.category] ?? 0) + 1;
    }
    return counts;
  }

  // Performance monitoring
  void logPerformance(String operation, Duration duration, {
    Map<String, dynamic>? additionalData,
  }) {
    final data = <String, dynamic>{
      'operation': operation,
      'duration_ms': duration.inMilliseconds,
      'duration_formatted': Helpers.formatDuration(duration),
      ...?additionalData,
    };

    final level = duration.inMilliseconds > 5000 
        ? LogLevel.warning 
        : LogLevel.info;

    log(LogEntry.app(
      message: 'Performance: $operation completed in ${Helpers.formatDuration(duration)}',
      level: level,
      data: data,
    ));
  }

  @override
  void dispose() {
    _logsBox?.close();
    super.dispose();
  }
}
