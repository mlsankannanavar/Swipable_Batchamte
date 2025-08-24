import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/logging_service.dart';
import '../models/health_response_model.dart';
import '../utils/constants.dart';
import '../utils/log_level.dart';

enum AppStatus { initializing, ready, error }
enum ConnectionStatus { connected, disconnected, checking }

class AppStateProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final LoggingService _logger = LoggingService();
  
  AppStatus _appStatus = AppStatus.initializing;
  ConnectionStatus _connectionStatus = ConnectionStatus.checking;
  HealthResponseModel? _serverHealth;
  String? _currentSessionId;
  DateTime? _lastHealthCheck;
  bool _isInitialized = false;
  String? _errorMessage;
  String _apiBaseUrl = Constants.apiBaseUrl;

  // Constants for shared preferences
  static const String _apiBaseUrlKey = 'api_base_url';

  // Getters
  AppStatus get appStatus => _appStatus;
  ConnectionStatus get connectionStatus => _connectionStatus;
  HealthResponseModel? get serverHealth => _serverHealth;
  String? get currentSessionId => _currentSessionId;
  DateTime? get lastHealthCheck => _lastHealthCheck;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _connectionStatus == ConnectionStatus.connected;
  bool get isServerHealthy => _serverHealth?.isHealthy ?? false;
  String get apiBaseUrl => _apiBaseUrl;
  bool get isApiHealthy => isConnected && isServerHealthy;

  AppStateProvider() {
    _initializeApp();
    _startPeriodicHealthCheck();
    _listenToConnectivityChanges();
  }

  // Initialize the application
  Future<void> _initializeApp() async {
    try {
      _logger.logApp('Initializing application', level: LogLevel.info);
      _setAppStatus(AppStatus.initializing);

      // Initialize logging service
      await _logger.initialize();
      
      // Load API base URL from preferences
      await loadApiBaseUrl();
      
      // Update API service with loaded URL
      _apiService.updateBaseUrl(_apiBaseUrl);
      
      // Check initial connectivity
      await _checkConnectivity();
      
      // Perform initial health check
      await checkServerHealth();
      
      _isInitialized = true;
      _setAppStatus(AppStatus.ready);
      
      _logger.logApp('Application initialized successfully', 
          level: LogLevel.success,
          data: {
            'connectionStatus': _connectionStatus.name,
            'serverHealthy': isServerHealthy,
          });
    } catch (e, stackTrace) {
      _logger.logError('Failed to initialize application',
          error: e, stackTrace: stackTrace);
      _setAppStatus(AppStatus.error);
      _setErrorMessage('Failed to initialize application: ${e.toString()}');
    }
  }

  // Check server health
  Future<void> checkServerHealth() async {
    _logger.logApp('Checking server health');
    
    try {
      final stopwatch = Stopwatch()..start();
      final response = await _apiService.checkHealth();
      stopwatch.stop();

      _lastHealthCheck = DateTime.now();

      if (response.isSuccess && response.data != null) {
        _serverHealth = response.data!;
        _setConnectionStatus(ConnectionStatus.connected);
        
        _logger.logApp('Server health check successful',
            level: LogLevel.success,
            data: {
              'status': _serverHealth!.status,
              'duration': stopwatch.elapsed.inMilliseconds,
              'timestamp': _serverHealth!.timestamp.toIso8601String(),
            });
      } else {
        _serverHealth = null;
        _setConnectionStatus(ConnectionStatus.disconnected);
        
        _logger.logApp('Server health check failed',
            level: LogLevel.error,
            data: {
              'error': response.error,
              'statusCode': response.statusCode,
              'duration': stopwatch.elapsed.inMilliseconds,
            });
      }
    } catch (e, stackTrace) {
      _serverHealth = null;
      _setConnectionStatus(ConnectionStatus.disconnected);
      _logger.logError('Server health check error',
          error: e, stackTrace: stackTrace);
    }
  }

  // Check network connectivity
  Future<void> _checkConnectivity() async {
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      
      if (connectivityResults.contains(ConnectivityResult.none) || connectivityResults.isEmpty) {
        _setConnectionStatus(ConnectionStatus.disconnected);
        _logger.logNetwork('No network connection', level: LogLevel.warning);
      } else {
        _logger.logNetwork('Network connection available',
            data: {'types': connectivityResults.map((r) => r.name).toList()});
        // Don't automatically set to connected, wait for health check
      }
    } catch (e, stackTrace) {
      _logger.logError('Failed to check connectivity',
          error: e, stackTrace: stackTrace, category: 'NETWORK');
    }
  }

  // Listen to connectivity changes
  void _listenToConnectivityChanges() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _logger.logNetwork('Connectivity changed to ${results.map((r) => r.name).join(', ')}');
      
      if (results.contains(ConnectivityResult.none) || results.isEmpty) {
        _setConnectionStatus(ConnectionStatus.disconnected);
      } else {
        // Check server health when connectivity is restored
        _setConnectionStatus(ConnectionStatus.checking);
        checkServerHealth();
      }
    });
  }

  // Start periodic health checks
  void _startPeriodicHealthCheck() {
    Future.delayed(Constants.connectionCheckInterval, () async {
      if (_isInitialized) {
        await checkServerHealth();
        _startPeriodicHealthCheck(); // Schedule next check
      }
    });
  }

  // Set current session ID
  void setSessionId(String sessionId) {
    _currentSessionId = sessionId;
    _logger.logApp('Session ID set',
        data: {'sessionId': sessionId});
    notifyListeners();
  }

  // Clear session
  void clearSession() {
    final oldSessionId = _currentSessionId;
    _currentSessionId = null;
    _logger.logApp('Session cleared',
        data: {'previousSessionId': oldSessionId});
    notifyListeners();
  }

  // Retry connection
  Future<void> retryConnection() async {
    _logger.logApp('Retrying connection');
    _setConnectionStatus(ConnectionStatus.checking);
    await _checkConnectivity();
    await checkServerHealth();
  }

  // Private setters with logging
  void _setAppStatus(AppStatus status) {
    if (_appStatus != status) {
      final oldStatus = _appStatus;
      _appStatus = status;
      _logger.logApp('App status changed',
          data: {
            'from': oldStatus.name,
            'to': status.name,
          });
      notifyListeners();
    }
  }

  void _setConnectionStatus(ConnectionStatus status) {
    if (_connectionStatus != status) {
      final oldStatus = _connectionStatus;
      _connectionStatus = status;
      _logger.logNetwork('Connection status changed',
          data: {
            'from': oldStatus.name,
            'to': status.name,
          });
      notifyListeners();
    }
  }

  void _setErrorMessage(String? message) {
    _errorMessage = message;
    if (message != null) {
      _logger.logError('App error occurred', error: message);
    }
    notifyListeners();
  }

  // Get connection status info
  Map<String, dynamic> getConnectionInfo() {
    return {
      'appStatus': _appStatus.name,
      'connectionStatus': _connectionStatus.name,
      'isConnected': isConnected,
      'isServerHealthy': isServerHealthy,
      'serverStatus': _serverHealth?.status,
      'lastHealthCheck': _lastHealthCheck?.toIso8601String(),
      'currentSession': _currentSessionId,
      'errorMessage': _errorMessage,
    };
  }

  // Performance monitoring
  void logScreenNavigation(String screenName, {Duration? loadTime}) {
    _logger.logApp('Screen navigation',
        data: {
          'screen': screenName,
          'timestamp': DateTime.now().toIso8601String(),
          'loadTime': loadTime?.inMilliseconds,
        });
  }

  void logUserAction(String action, {Map<String, dynamic>? data}) {
    _logger.logApp('User action: $action',
        data: {
          'action': action,
          'timestamp': DateTime.now().toIso8601String(),
          ...?data,
        });
  }

  // Error handling
  void handleError(String message, {Object? error, StackTrace? stackTrace}) {
    _setErrorMessage(message);
    _logger.logError(message, error: error, stackTrace: stackTrace);
  }

  void clearError() {
    _setErrorMessage(null);
  }

  // App lifecycle
  void onAppResumed() {
    _logger.logApp('App resumed');
    // Check connectivity and server health when app resumes
    checkServerHealth();
  }

  void onAppPaused() {
    _logger.logApp('App paused');
  }

  void onAppDetached() {
    _logger.logApp('App detached');
  }

  // Settings and configuration
  Duration get healthCheckInterval => Constants.connectionCheckInterval;
  int get maxRetryAttempts => Constants.maxRetryAttempts;

  // Public initialization method
  Future<void> initialize() async {
    await _initializeApp();
  }

  // Set API health status
  void setApiHealthy(bool healthy) {
    _setConnectionStatus(healthy ? ConnectionStatus.connected : ConnectionStatus.disconnected);
  }

  // API Base URL Management
  Future<void> loadApiBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _apiBaseUrl = prefs.getString(_apiBaseUrlKey) ?? Constants.apiBaseUrl;
      _logger.logApp('Loaded API base URL: $_apiBaseUrl');
      notifyListeners();
    } catch (e) {
      _logger.logError('Failed to load API base URL', error: e);
    }
  }

  Future<void> updateApiBaseUrl(String newUrl) async {
    try {
      // Validate URL format
      if (!newUrl.startsWith('http://') && !newUrl.startsWith('https://')) {
        throw ArgumentError('URL must start with http:// or https://');
      }
      
      // Ensure URL ends with /
      if (!newUrl.endsWith('/')) {
        newUrl = '$newUrl/';
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_apiBaseUrlKey, newUrl);
      
      _apiBaseUrl = newUrl;
      _logger.logApp('Updated API base URL to: $newUrl');
      
      // Update API service base URL
      _apiService.updateBaseUrl(newUrl);
      
      // Re-check API health with new URL
      await checkApiHealth();
      
      notifyListeners();
    } catch (e) {
      _logger.logError('Failed to update API base URL', error: e);
      throw e;
    }
  }

  Future<void> resetApiBaseUrl() async {
    await updateApiBaseUrl(Constants.apiBaseUrl);
  }

  // Loading state
  bool get isLoading => _appStatus == AppStatus.initializing;

  // UI Settings
  bool _isDarkMode = false;
  bool _isAutoRefreshEnabled = true;
  bool _isAutoScanEnabled = false;
  bool _isVibrateEnabled = true;
  bool _isBeepEnabled = true;

  bool get isDarkMode => _isDarkMode;
  bool get isAutoRefreshEnabled => _isAutoRefreshEnabled;
  bool get isAutoScanEnabled => _isAutoScanEnabled;
  bool get isVibrateEnabled => _isVibrateEnabled;
  bool get isBeepEnabled => _isBeepEnabled;

  void setDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  void setAutoRefresh(bool value) {
    _isAutoRefreshEnabled = value;
    notifyListeners();
  }

  void setAutoScan(bool value) {
    _isAutoScanEnabled = value;
    notifyListeners();
  }

  void setVibrate(bool value) {
    _isVibrateEnabled = value;
    notifyListeners();
  }

  void setBeep(bool value) {
    _isBeepEnabled = value;
    notifyListeners();
  }

  // Reset all settings to defaults
  void resetSettings() {
    _isDarkMode = false;
    _isAutoRefreshEnabled = true;
    _isAutoScanEnabled = false;
    _isVibrateEnabled = true;
    _isBeepEnabled = true;
    notifyListeners();
  }

  // Check API health manually
  Future<void> checkApiHealth() async {
    await checkServerHealth();
  }

  @override
  void dispose() {
    _logger.logApp('AppStateProvider disposed');
    super.dispose();
  }
}
