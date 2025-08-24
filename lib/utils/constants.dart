class Constants {
  // API Configuration
  static const String baseUrl = 'https://test-backend-batchmate.medha-analytics.ai/';
  static const String apiBaseUrl = baseUrl; // Alias for compatibility
  static const String healthEndpoint = 'health';
  static const String filteredBatchesEndpoint = 'api/filtered-batches';
  
  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // App Information
  static const String appName = 'BatchMate';
  static const String appVersion = '1.0.0';
  static const String userAgent = '$appName/$appVersion';
  
  // Local Storage Keys
  static const String logsBoxKey = 'logs_box';
  static const String settingsBoxKey = 'settings_box';
  static const String batchDataBoxKey = 'batch_data_box';
  
  // Settings Keys
  static const String enableLoggingKey = 'enable_logging';
  static const String logLevelKey = 'log_level';
  static const String maxLogsKey = 'max_logs';
  static const String autoScrollLogsKey = 'auto_scroll_logs';
  
  // Default Values
  static const int maxLogsCount = 1000;
  static const bool defaultAutoScroll = true;
  static const bool defaultEnableLogging = true;
  
  // QR Scanner Configuration
  static const Duration qrScannerTimeout = Duration(seconds: 30);
  static const String qrScannerTitle = 'Scan QR Code for Session';
  static const String qrScannerSubtitle = 'Position the QR code within the frame';
  
  // OCR Configuration
  static const String ocrTitle = 'Scan Batch Information';
  static const String ocrSubtitle = 'Capture clear image of batch details';
  static const double ocrConfidenceThreshold = 0.7;
  
  // Network Status
  static const Duration connectionCheckInterval = Duration(seconds: 5);
  static const Duration networkRetryDelay = Duration(seconds: 3);
  static const int maxRetryAttempts = 3;
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double cardElevation = 2.0;
  static const double borderRadius = 12.0;
  static const double iconSize = 24.0;
  static const double fabSize = 56.0;
  static const double smallFabSize = 40.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Splash Screen
  static const Duration splashDuration = Duration(seconds: 3);
  
  // Log Categories
  static const String logCategoryApi = 'API';
  static const String logCategoryApiOut = 'API-OUT';
  static const String logCategoryApiIn = 'API-IN';
  static const String logCategoryQrScan = 'QR-SCAN';
  static const String logCategoryOcr = 'OCR';
  static const String logCategoryError = 'ERROR';
  static const String logCategoryApp = 'APP';
  static const String logCategoryUi = 'UI';
  static const String logCategoryNetwork = 'NETWORK';
  
  // Error Messages
  static const String networkErrorMessage = 'No internet connection available';
  static const String serverErrorMessage = 'Server error occurred';
  static const String timeoutErrorMessage = 'Request timeout';
  static const String unknownErrorMessage = 'An unknown error occurred';
  static const String permissionDeniedMessage = 'Permission denied';
  static const String cameraErrorMessage = 'Camera error occurred';
  static const String qrScanErrorMessage = 'QR scan failed';
  static const String ocrErrorMessage = 'Text recognition failed';
  
  // Success Messages
  static const String qrScanSuccessMessage = 'QR code scanned successfully';
  static const String batchDataLoadedMessage = 'Batch data loaded successfully';
  static const String ocrSuccessMessage = 'Text extracted successfully';
  static const String apiSuccessMessage = 'API request completed successfully';
  
  // Permissions
  static const String cameraPermission = 'camera';
  static const String storagePermission = 'storage';
  
  // File Operations
  static const String logFilePrefix = 'batchmate_logs_';
  static const String logFileExtension = '.txt';
  static const String exportDateFormat = 'yyyy-MM-dd_HH-mm-ss';
  
  // HTTP Headers
  static const String contentTypeHeader = 'Content-Type';
  static const String userAgentHeader = 'User-Agent';
  static const String acceptHeader = 'Accept';
  static const String authorizationHeader = 'Authorization';
  
  // Content Types
  static const String jsonContentType = 'application/json';
  static const String formDataContentType = 'multipart/form-data';
  
  // Session Management
  static const Duration sessionTimeout = Duration(hours: 8);
  static const String sessionIdKey = 'session_id';
  static const String lastSessionKey = 'last_session';
}
