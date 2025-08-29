import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import '../models/session_details_model.dart';
import '../models/rack_model.dart';
import '../services/api_service.dart';
import '../services/logging_service.dart';
import '../utils/constants.dart';
import '../utils/log_level.dart';

enum SessionLoadingState { idle, loading, loaded, error }

class SessionProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final LoggingService _logger = LoggingService();
  
  Box<String>? _sessionBox;
  SessionDetailsModel? _currentSession;
  SessionLoadingState _loadingState = SessionLoadingState.idle;
  String? _selectedRackName;
  String? _errorMessage;
  DateTime? _lastLoadTime;
  Duration? _lastLoadDuration;
  bool _isInitialized = false;

  // Getters
  SessionDetailsModel? get currentSession => _currentSession;
  SessionLoadingState get loadingState => _loadingState;
  String? get selectedRackName => _selectedRackName;
  String? get errorMessage => _errorMessage;
  DateTime? get lastLoadTime => _lastLoadTime;
  Duration? get lastLoadDuration => _lastLoadDuration;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _loadingState == SessionLoadingState.loading;
  bool get hasError => _loadingState == SessionLoadingState.error;
  bool get hasSession => _currentSession != null;
  bool get hasSelectedRack => _selectedRackName != null && selectedRack != null;

  // Current session info
  String? get currentSessionId => _currentSession?.sessionId;
  List<String> get rackNames => _currentSession?.rackNames ?? [];
  RackModel? get selectedRack => _selectedRackName != null 
      ? _currentSession?.getRackByName(_selectedRackName!) 
      : null;

  // Selected rack info
  List<ItemModel> get availableItems => selectedRack?.availableItems ?? [];
  List<ItemModel> get submittedItems => selectedRack?.submittedItems ?? [];
  int get availableItemsCount => availableItems.length;
  int get submittedItemsCount => submittedItems.length;

  // Session statistics
  int get totalRacks => _currentSession?.racks.length ?? 0;
  int get totalItems => _currentSession?.totalItems ?? 0;
  int get totalAvailableItems => _currentSession?.totalAvailableItems ?? 0;
  int get totalSubmittedItems => _currentSession?.totalSubmittedItems ?? 0;

  SessionProvider() {
    _initializeProvider();
  }

  // Initialize the provider
  Future<void> _initializeProvider() async {
    try {
      _logger.logApp('Initializing SessionProvider');
      
      // Initialize Hive box for session storage
      _sessionBox = await Hive.openBox<String>(Constants.sessionBoxKey);
      
      // Load cached session if available
      await _loadCachedSession();
      
      _isInitialized = true;
      _logger.logApp('SessionProvider initialized successfully',
          data: {'hasSession': hasSession});
      
      notifyListeners();
    } catch (e, stackTrace) {
      _logger.logError('Failed to initialize SessionProvider',
          error: e, stackTrace: stackTrace);
    }
  }

  // Load session for a given session ID
  Future<void> loadSession(String sessionId, {bool forceRefresh = false}) async {
    if (_currentSession?.sessionId == sessionId && !forceRefresh) {
      _logger.logApp('Using cached session',
          additionalData: {'sessionId': sessionId});
      return;
    }

    _setLoadingState(SessionLoadingState.loading);
    _errorMessage = null;

    try {
      final stopwatch = Stopwatch()..start();

      // Load from API
      final response = await _apiService.getSessionDetails(sessionId);
      stopwatch.stop();

      if (response.success && response.sessionDetails != null) {
        _currentSession = response.sessionDetails;
        _lastLoadTime = DateTime.now();
        _lastLoadDuration = stopwatch.elapsed;

        // Set default rack selection (first rack)
        if (_currentSession!.racks.isNotEmpty) {
          _selectedRackName = _currentSession!.racks.first.rackName;
        }

        // Save to local storage
        await _saveSessionToLocal();

        _setLoadingState(SessionLoadingState.loaded);
        _logger.logApp('Session loaded successfully',
            data: {
              'sessionId': sessionId,
              'racks': _currentSession!.racks.length,
              'totalItems': _currentSession!.totalItems,
              'duration': stopwatch.elapsed.inMilliseconds,
            });
      } else {
        // Fallback to cached session
        await _loadCachedSession();
        _setErrorMessage(response.error ?? 'Failed to load session');
        _setLoadingState(SessionLoadingState.error);
        
        _logger.logWarning('Failed to load session from API, using cached data',
            additionalData: {
              'sessionId': sessionId,
              'error': response.error,
            });
      }
    } catch (e, stackTrace) {
      await _loadCachedSession();
      _setErrorMessage(e.toString());
      _setLoadingState(SessionLoadingState.error);
      
      _logger.logError('Exception while loading session',
          error: e,
          stackTrace: stackTrace);
    }

    notifyListeners();
  }

  // Select a rack
  void selectRack(String rackName) {
    if (_currentSession?.getRackByName(rackName) != null) {
      _selectedRackName = rackName;
      
      _logger.logApp('Rack selected',
          data: {
            'rackName': rackName,
            'availableItems': availableItemsCount,
            'submittedItems': submittedItemsCount,
          });
      
      notifyListeners();
    } else {
      _logger.logWarning('Attempted to select non-existent rack',
          additionalData: {'rackName': rackName});
    }
  }

  // Submit an item (move from available to submitted)
  Future<void> submitItem(ItemModel item) async {
    if (_currentSession == null || _selectedRackName == null) {
      _logger.logWarning('Cannot submit item - no session or rack selected');
      return;
    }

    try {
      // Update the session model
      _currentSession = _currentSession!.submitItemInRack(_selectedRackName!, item);
      
      // Save updated session to local storage
      await _saveSessionToLocal();
      
      _logger.logApp('Item submitted successfully',
          level: LogLevel.success,
          data: {
            'itemName': item.itemName,
            'rackName': _selectedRackName,
            'sessionId': _currentSession!.sessionId,
          });
      
      notifyListeners();
    } catch (e, stackTrace) {
      _logger.logError('Failed to submit item: ${item.itemName} in rack $_selectedRackName',
          error: e,
          stackTrace: stackTrace);
      rethrow;
    }
  }

  // Get item by name from selected rack
  ItemModel? getItemByName(String itemName) {
    return selectedRack?.items.firstWhere(
      (item) => item.itemName == itemName,
      orElse: () => throw StateError('Item not found'),
    );
  }

  // Check if item is submitted
  bool isItemSubmitted(String itemName) {
    return selectedRack?.isItemSubmitted(itemName) ?? false;
  }

  // Clear current session
  void clearSession() {
    _currentSession = null;
    _selectedRackName = null;
    _setLoadingState(SessionLoadingState.idle);
    _errorMessage = null;
    
    _logger.logApp('Session cleared');
    notifyListeners();
  }

  // Retry loading current session
  Future<void> retryLoadSession() async {
    if (_currentSession?.sessionId != null) {
      await loadSession(_currentSession!.sessionId, forceRefresh: true);
    } else {
      _logger.logApp('Cannot retry session loading - no session ID',
          level: LogLevel.warning);
    }
  }

  // Private helper methods
  void _setLoadingState(SessionLoadingState state) {
    _loadingState = state;
  }

  void _setErrorMessage(String message) {
    _errorMessage = message;
  }

  // Load cached session from local storage
  Future<void> _loadCachedSession() async {
    try {
      if (_sessionBox == null) return;

      final sessionData = _sessionBox!.get('current_session');
      if (sessionData != null) {
        final sessionMap = jsonDecode(sessionData) as Map<String, dynamic>;
        _currentSession = SessionDetailsModel.fromJson(
          sessionMap, 
          sessionMap['sessionId'] ?? 'unknown'
        );
        
        // Restore rack selection
        final selectedRack = _sessionBox!.get('selected_rack');
        _selectedRackName = selectedRack;
        
        _logger.logApp('Cached session loaded',
            data: {
              'sessionId': _currentSession?.sessionId,
              'selectedRack': _selectedRackName,
            });
      }
    } catch (e, stackTrace) {
      _logger.logError('Failed to load cached session',
          error: e, stackTrace: stackTrace);
    }
  }

  // Save session to local storage
  Future<void> _saveSessionToLocal() async {
    try {
      if (_sessionBox == null || _currentSession == null) return;

      await _sessionBox!.put('current_session', jsonEncode(_currentSession!.toJson()));
      
      if (_selectedRackName != null) {
        await _sessionBox!.put('selected_rack', _selectedRackName!);
      }
      
      _logger.logApp('Session saved to local storage');
    } catch (e, stackTrace) {
      _logger.logError('Failed to save session to local storage',
          error: e, stackTrace: stackTrace);
    }
  }

  // Get session summary statistics
  Map<String, dynamic> getSessionStats() {
    return _currentSession?.summaryStats ?? {
      'totalRacks': 0,
      'totalItems': 0,
      'totalAvailableItems': 0,
      'totalSubmittedItems': 0,
      'totalBatches': 0,
      'expiredBatches': 0,
      'expiringSoonBatches': 0,
    };
  }

  @override
  void dispose() {
    _sessionBox?.close();
    super.dispose();
  }
}
