import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Helpers {
  // Date and Time formatting
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(dateTime);
  }
  
  static String formatTimeOnly(DateTime dateTime) {
    return DateFormat('HH:mm:ss.SSS').format(dateTime);
  }
  
  static String formatDateOnly(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }
  
  // Alias for formatDateOnly for compatibility
  static String formatDate(DateTime dateTime) {
    return formatDateOnly(dateTime);
  }
  
  static String formatForExport(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd_HH-mm-ss').format(dateTime);
  }
  
  static String formatDuration(Duration duration) {
    if (duration.inMilliseconds < 1000) {
      return '${duration.inMilliseconds}ms';
    } else if (duration.inSeconds < 60) {
      return '${duration.inSeconds}.${(duration.inMilliseconds % 1000).toString().padLeft(3, '0')}s';
    } else {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    }
  }
  
  // String utilities
  static String truncateString(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
  
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
  
  static String camelCaseToTitle(String text) {
    return text.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(1)}',
    ).trim();
  }
  
  // Data formatting
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  static String formatJson(Map<String, dynamic> json) {
    try {
      return json.toString();
    } catch (e) {
      return 'Invalid JSON';
    }
  }
  
  // Validation utilities
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
  
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  static bool isValidSessionId(String sessionId) {
    // Valid session IDs start with 'medha-' or 'session_' and have minimum length
    return sessionId.isNotEmpty && 
           sessionId.length >= 8 && 
           (sessionId.startsWith('medha-') || sessionId.startsWith('session_'));
  }
  
  // Network utilities
  static Map<String, String> getDefaultHeaders() {
    return {
      'Content-Type': 'application/json',
      'User-Agent': 'BatchMate/1.0.0',
      'Accept': 'application/json',
    };
  }
  
  static String getHttpStatusMessage(int statusCode) {
    switch (statusCode) {
      case 200:
        return 'OK';
      case 201:
        return 'Created';
      case 400:
        return 'Bad Request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not Found';
      case 500:
        return 'Internal Server Error';
      case 502:
        return 'Bad Gateway';
      case 503:
        return 'Service Unavailable';
      case 504:
        return 'Gateway Timeout';
      default:
        return 'Unknown Status';
    }
  }
  
  // Error handling utilities
  static String getErrorMessage(dynamic error) {
    if (error == null) return 'Unknown error occurred';
    return error.toString();
  }
  
  static String getStackTraceString(StackTrace? stackTrace) {
    if (stackTrace == null) return 'No stack trace available';
    return stackTrace.toString();
  }
  
  // UI utilities
  static String getInitials(String name) {
    if (name.isEmpty) return 'NA';
    final words = name.split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }
    return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'.toUpperCase();
  }
  
  static double getScreenWidth(context) {
    return MediaQuery.of(context).size.width;
  }
  
  static double getScreenHeight(context) {
    return MediaQuery.of(context).size.height;
  }
  
  static bool isTablet(context) {
    return MediaQuery.of(context).size.width > 600;
  }
  
  // Log utilities
  static String formatLogEntry(DateTime timestamp, String level, String category, String message) {
    return '[${formatDateTime(timestamp)}] [$level] [$category] $message';
  }
  
  static String formatLogWithData(DateTime timestamp, String level, String category, String message, Map<String, dynamic>? data) {
    final baseLog = formatLogEntry(timestamp, level, category, message);
    if (data == null || data.isEmpty) return baseLog;
    
    final dataString = data.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(', ');
    
    return '$baseLog\nData: {$dataString}';
  }
  
  // Batch utilities
  static bool isExpired(String expiryDate) {
    try {
      final expiry = DateTime.parse(expiryDate);
      return expiry.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }
  
  static int getDaysUntilExpiry(String expiryDate) {
    try {
      final expiry = DateTime.parse(expiryDate);
      final difference = expiry.difference(DateTime.now());
      return difference.inDays;
    } catch (e) {
      return -1;
    }
  }
  
  // Debouncing utility
  static void debounce(Function() function, {Duration delay = const Duration(milliseconds: 300)}) {
    Future.delayed(delay, function);
  }
  
  // File operations utilities
  static String sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }
  
  static String generateLogFileName() {
    final timestamp = formatForExport(DateTime.now());
    return 'batchmate_logs_$timestamp.txt';
  }
}
