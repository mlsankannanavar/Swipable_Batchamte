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
  
  // Local partial submission tracking
  // Map of sessionId -> rackName -> itemName -> submittedQuantity
  Map<String, Map<String, Map<String, int>>> _partialSubmissions = {};

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
      
      // Load partial submissions from storage
      await _loadPartialSubmissions();
      
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
        
        // Apply local partial submissions to freshly loaded data
        _applyPartialSubmissions();
        
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

  // Submit an item with selected batch (move from available to submitted)
  Future<void> submitItemWithBatch(ItemModel item, String selectedBatch) async {
    if (_currentSession == null || _selectedRackName == null) {
      _logger.logWarning('Cannot submit item - no session or rack selected');
      return;
    }

    try {
      // Create a copy of the item with the selected batch
      final updatedItem = item.copyWith(
        selectedBatch: selectedBatch,
        isSubmitted: true,
      );
      
      // Update the session model
      _currentSession = _currentSession!.submitItemInRack(_selectedRackName!, updatedItem);
      
      // Save updated session to local storage
      await _saveSessionToLocal();
      
      _logger.logApp('Item submitted with batch successfully',
          level: LogLevel.success,
          data: {
            'itemName': item.itemName,
            'selectedBatch': selectedBatch,
            'rackName': _selectedRackName,
            'sessionId': _currentSession!.sessionId,
          });
      
      notifyListeners();
    } catch (e, stackTrace) {
      _logger.logError('Failed to submit item with batch: ${item.itemName} in rack $_selectedRackName',
          error: e,
          stackTrace: stackTrace);
      rethrow;
    }
  }

  // Submit item with partial quantity
  Future<void> submitItemPartially(String itemName, int submittedQuantity) async {
    if (_currentSession == null || _selectedRackName == null) {
      _logger.logWarning('Cannot submit item partially - no session or rack selected');
      return;
    }

    try {
      final sessionId = _currentSession!.sessionId;
      
      // Update local partial submission tracking
      if (!_partialSubmissions.containsKey(sessionId)) {
        _partialSubmissions[sessionId] = {};
      }
      if (!_partialSubmissions[sessionId]!.containsKey(_selectedRackName!)) {
        _partialSubmissions[sessionId]![_selectedRackName!] = {};
      }
      
      // Add to existing partial submission (accumulate)
      final existingQuantity = _partialSubmissions[sessionId]![_selectedRackName!]![itemName] ?? 0;
      _partialSubmissions[sessionId]![_selectedRackName!]![itemName] = existingQuantity + submittedQuantity;
      
      // Apply partial submissions to current session
      _applyPartialSubmissions();
      
      // Save updated session to local storage
      await _saveSessionToLocal();
      
      _logger.logApp('Item submitted partially successfully',
          level: LogLevel.success,
          data: {
            'itemName': itemName,
            'submittedQuantity': submittedQuantity,
            'totalSubmitted': _partialSubmissions[sessionId]![_selectedRackName!]![itemName],
            'rackName': _selectedRackName,
            'sessionId': sessionId,
          });
      
      notifyListeners();
    } catch (e, stackTrace) {
      _logger.logError('Failed to submit item partially: $itemName in rack $_selectedRackName',
          error: e,
          stackTrace: stackTrace);
      rethrow;
    }
  }
  
  // Apply local partial submissions to current session
  void _applyPartialSubmissions() {
    if (_currentSession == null) return;
    
    final sessionId = _currentSession!.sessionId;
    if (!_partialSubmissions.containsKey(sessionId)) return;
    
    final sessionPartialSubmissions = _partialSubmissions[sessionId]!;
    final itemsToRemove = <String, List<String>>{}; // rack -> list of items to remove
    
    // Create a new session with partial submissions applied
    final updatedRacks = _currentSession!.racks.map((rack) {
      if (sessionPartialSubmissions.containsKey(rack.rackName)) {
        final rackPartialSubmissions = sessionPartialSubmissions[rack.rackName]!;
        
        final updatedItems = rack.items.map((item) {
          if (rackPartialSubmissions.containsKey(item.itemName)) {
            final totalSubmitted = rackPartialSubmissions[item.itemName]!;
            final isFullySubmitted = totalSubmitted >= item.quantity;
            
            // Mark items for removal if fully submitted
            if (isFullySubmitted) {
              itemsToRemove.putIfAbsent(rack.rackName, () => []).add(item.itemName);
            }
            
            return item.copyWith(
              submittedQuantity: totalSubmitted,
              isSubmitted: isFullySubmitted,
            );
          }
          return item;
        }).toList();
        
        return rack.copyWith(items: updatedItems);
      }
      return rack;
    }).toList();
    
    _currentSession = _currentSession!.copyWith(racks: updatedRacks);
    
    // Clean up fully submitted items from partial submissions
    for (final rackName in itemsToRemove.keys) {
      for (final itemName in itemsToRemove[rackName]!) {
        _partialSubmissions[sessionId]?[rackName]?.remove(itemName);
      }
      if (_partialSubmissions[sessionId]?[rackName]?.isEmpty == true) {
        _partialSubmissions[sessionId]?.remove(rackName);
      }
    }
    if (_partialSubmissions[sessionId]?.isEmpty == true) {
      _partialSubmissions.remove(sessionId);
    }
  }
  
  // Get partial submission quantity for an item
  int getPartialSubmissionQuantity(String itemName) {
    if (_currentSession == null || _selectedRackName == null) return 0;
    
    final sessionId = _currentSession!.sessionId;
    return _partialSubmissions[sessionId]?[_selectedRackName!]?[itemName] ?? 0;
  }
  
  // Clear partial submission for an item (when fully submitted)
  Future<void> clearPartialSubmission(String itemName) async {
    if (_currentSession == null || _selectedRackName == null) return;
    
    final sessionId = _currentSession!.sessionId;
    _partialSubmissions[sessionId]?[_selectedRackName!]?.remove(itemName);
    
    // Clean up empty maps
    if (_partialSubmissions[sessionId]?[_selectedRackName!]?.isEmpty == true) {
      _partialSubmissions[sessionId]?.remove(_selectedRackName!);
    }
    if (_partialSubmissions[sessionId]?.isEmpty == true) {
      _partialSubmissions.remove(sessionId);
    }
    
    await _savePartialSubmissions();
    _logger.logApp('Partial submission cleared for item: $itemName');
  }

  // Clear all partial submissions (useful when starting fresh)
  Future<void> clearAllPartialSubmissions() async {
    try {
      _partialSubmissions.clear();
      
      // Remove from storage as well
      if (_sessionBox != null) {
        await _sessionBox!.delete('partial_submissions');
        _logger.logApp('All partial submissions cleared from storage');
      }
      
      _logger.logApp('All partial submission data cleared completely');
      notifyListeners();
    } catch (e, stackTrace) {
      _logger.logError('Error clearing partial submissions', error: e, stackTrace: stackTrace);
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

  // Clear current session - comprehensive cleanup
  Future<void> clearSession() async {
    try {
      // Clear in-memory data
      _currentSession = null;
      _selectedRackName = null;
      _setLoadingState(SessionLoadingState.idle);
      _errorMessage = null;
      
      // Clear partial submissions data (both in-memory and stored)
      _partialSubmissions.clear();
      
      // Clear cached session data from storage
      if (_sessionBox != null) {
        await _sessionBox!.clear();
        _logger.logApp('Cleared cached session data from storage');
      }
      
      _logger.logApp('Session and all partial submission data cleared completely');
      notifyListeners();
    } catch (e, stackTrace) {
      _logger.logError('Error clearing session', error: e, stackTrace: stackTrace);
    }
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
        
        // Apply partial submissions to cached data
        _applyPartialSubmissions();
        
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
      
      // Also save partial submissions
      await _savePartialSubmissions();
      
      _logger.logApp('Session saved to local storage');
    } catch (e, stackTrace) {
      _logger.logError('Failed to save session to local storage',
          error: e, stackTrace: stackTrace);
    }
  }
  
  // Save partial submissions to local storage
  Future<void> _savePartialSubmissions() async {
    if (_sessionBox != null) {
      try {
        await _sessionBox!.put('partial_submissions', jsonEncode(_partialSubmissions));
        _logger.logApp('Partial submissions saved to local storage');
      } catch (e, stackTrace) {
        _logger.logError('Failed to save partial submissions to local storage',
            error: e, stackTrace: stackTrace);
      }
    }
  }
  
  // Load partial submissions from local storage
  Future<void> _loadPartialSubmissions() async {
    if (_sessionBox != null) {
      try {
        final partialSubmissionsStr = _sessionBox!.get('partial_submissions');
        if (partialSubmissionsStr != null) {
          final decoded = jsonDecode(partialSubmissionsStr) as Map<String, dynamic>;
          _partialSubmissions = decoded.map((sessionId, sessionData) {
            final sessionMap = sessionData as Map<String, dynamic>;
            return MapEntry(
              sessionId,
              sessionMap.map((rackName, rackData) {
                final rackMap = rackData as Map<String, dynamic>;
                return MapEntry(
                  rackName,
                  rackMap.map((itemName, quantity) => MapEntry(itemName, quantity as int)),
                );
              }),
            );
          });
          _logger.logApp('Partial submissions loaded from local storage');
        }
      } catch (e, stackTrace) {
        _logger.logError('Failed to load partial submissions from local storage',
            error: e, stackTrace: stackTrace);
        _partialSubmissions = {}; // Reset on error
      }
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
