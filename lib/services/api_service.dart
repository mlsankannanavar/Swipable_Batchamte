import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/api_response_model.dart';
import '../models/health_response_model.dart';
import '../models/batch_model.dart';
import '../models/session_details_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/log_level.dart';
import 'logging_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final LoggingService _logger = LoggingService();
  final http.Client _client = http.Client();

  // Base configuration - now dynamic
  String _baseUrl = Constants.baseUrl;
  String get baseUrl => _baseUrl;

  /// Update the base URL for all API calls
  void updateBaseUrl(String newBaseUrl) {
    _baseUrl = newBaseUrl;
    _logger.logNetwork('API base URL updated to: $newBaseUrl');
  }
  Duration get timeout => Constants.apiTimeout;
  Map<String, String> get defaultHeaders => Helpers.getDefaultHeaders();

  // Health check endpoint
  Future<ApiResponse<HealthResponseModel>> checkHealth() async {
    const endpoint = Constants.healthEndpoint;
    final url = '$baseUrl$endpoint';
    final stopwatch = Stopwatch()..start();

    // Log the outgoing request
    _logger.logApiRequest('GET', url, headers: defaultHeaders);

    try {
      // Check network connectivity first
      final connectivityResults = await Connectivity().checkConnectivity();
      if (connectivityResults.contains(ConnectivityResult.none) || connectivityResults.isEmpty) {
        _logger.logNetwork('No network connectivity', level: LogLevel.error);
        throw const SocketException('No network connection');
      }

      final response = await _client
          .get(Uri.parse(url), headers: defaultHeaders)
          .timeout(timeout);

      stopwatch.stop();

      // Log the response
      _logger.logApiResponse('GET', url, response.statusCode, stopwatch.elapsed,
          headers: response.headers, body: response.body);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        final healthResponse = HealthResponseModel.fromJson(jsonData);
        
        _logger.logApp('Health check successful',
            level: LogLevel.success,
            data: {'status': healthResponse.status, 'duration': stopwatch.elapsed.inMilliseconds});

        return ApiResponse.success(
          data: healthResponse,
          statusCode: response.statusCode,
          headers: response.headers,
          duration: stopwatch.elapsed,
        );
      } else {
        final errorMessage = 'Health check failed with status ${response.statusCode}';
        _logger.logError(errorMessage);
        
        return ApiResponse.error(
          error: errorMessage,
          statusCode: response.statusCode,
          headers: response.headers,
          duration: stopwatch.elapsed,
        );
      }
    } on SocketException catch (e, stackTrace) {
      stopwatch.stop();
      _logger.logError('Network error during health check',
          error: e, stackTrace: stackTrace);
      return ApiResponse.error(
        error: 'Network connection failed: ${e.message}',
        duration: stopwatch.elapsed,
      );
    } on HttpException catch (e, stackTrace) {
      stopwatch.stop();
      _logger.logError('HTTP error during health check',
          error: e, stackTrace: stackTrace);
      return ApiResponse.error(
        error: 'HTTP error: ${e.message}',
        duration: stopwatch.elapsed,
      );
    } on FormatException catch (e, stackTrace) {
      stopwatch.stop();
      _logger.logError('JSON parsing error during health check',
          error: e, stackTrace: stackTrace);
      return ApiResponse.error(
        error: 'Invalid response format',
        duration: stopwatch.elapsed,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      _logger.logError('Unexpected error during health check',
          error: e, stackTrace: stackTrace);
      return ApiResponse.error(
        error: 'Unexpected error: ${e.toString()}',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Submit final batch result to backend
  Future<ApiResponse<Map<String, dynamic>>> submitMobileBatch({
    required String sessionId,
    required String batchNumber,
    required int quantity,
    required String captureId,
    required int confidence,
    required String matchType,
    required int submitTimestamp,
    required String extractedText,
    required bool selectedFromOptions,
    List<String>? alternativeMatches,
    // Additional fields for logging
    String? salesOrder,
    String? purchaseOrder,
    String? unitId,
    String? storeId,
    String? rackNum,
    String? locatorInfo,
    String? itemName,
    int? requestedQuantity,
    List<int>? imageBytes,
    int? processingTime,
  }) async {
    final endpoint = '/api/submit-mobile-batch/$sessionId';
    final body = {
      'batchNumber': batchNumber,
      'quantity': quantity,
      'captureId': captureId,
      'confidence': confidence,
      'matchType': matchType,
      'submitTimestamp': submitTimestamp,
      'extractedText': extractedText,
      'selectedFromOptions': selectedFromOptions,
      'alternativeMatches': alternativeMatches ?? [],
    };
    
    // Submit the batch first
    final result = await post(endpoint, body: body);
    
    // Then submit to logging API asynchronously in background (don't await)
    _submitMobileLogAsync(
      sessionId: sessionId,
      salesOrder: salesOrder,
      purchaseOrder: purchaseOrder,
      unitId: unitId,
      storeId: storeId,
      rackNum: rackNum,
      locatorInfo: locatorInfo,
      itemName: itemName,
      batchNumber: batchNumber,
      requestedQuantity: requestedQuantity,
      submittedQuantity: quantity,
      ocrConfidence: confidence,
      imageBytes: imageBytes,
      extractedText: extractedText,
      processingTime: processingTime,
      matchType: matchType,
      responseCode: result.statusCode ?? 0,
    );
    
    return result;
  }

  /// Submit mobile log data to the logging API
  Future<ApiResponse<Map<String, dynamic>>> submitMobileLog({
    required String sessionId,
    String? salesOrder,
    String? purchaseOrder,
    String? unitId,
    String? storeId,
    String? rackNum,
    String? locatorInfo,
    String? itemName,
    String? batchNumber,
    int? requestedQuantity,
    int? submittedQuantity,
    int? ocrConfidence,
    List<int>? imageBytes,
    String? extractedText,
    int? processingTime,
    String? matchType,
    int? responseCode,
  }) async {
    final endpoint = '/api/submit-mobile-log';
    final stopwatch = Stopwatch()..start();
    
    _logger.logApp('MOBILE_LOG_START: Initiating mobile log submission', data: {
      'sessionId': sessionId,
      'batchNumber': batchNumber,
      'itemName': itemName,
      'endpoint': endpoint,
      'startTime': DateTime.now().toIso8601String(),
    });
    
    String? base64Image;
    int imageEncodingTimeMs = 0;
    if (imageBytes != null && imageBytes.isNotEmpty) {
      final imageStopwatch = Stopwatch()..start();
      try {
        base64Image = base64.encode(imageBytes);
        imageStopwatch.stop();
        imageEncodingTimeMs = imageStopwatch.elapsed.inMilliseconds;
        
        _logger.logApp('MOBILE_LOG_IMAGE: Image encoded successfully', data: {
          'originalSizeBytes': imageBytes.length,
          'base64SizeBytes': base64Image.length,
          'encodingTimeMs': imageEncodingTimeMs,
          'compressionRatio': (imageBytes.length / base64Image.length * 100).toStringAsFixed(2),
        });
      } catch (e) {
        imageStopwatch.stop();
        _logger.logError('MOBILE_LOG_IMAGE_ERROR: Failed to encode image for logging', 
          error: e, 
          category: 'MOBILE_LOG_IMAGE');
      }
    }
    
    final body = {
      'User': 'NH User', // Hardcoded as requested
      'Session_Id': sessionId,
      'SalesOrder': salesOrder ?? '',
      'PurchaseOrder': purchaseOrder ?? '',
      'Unit_Id': unitId ?? '',
      'Store_Id': storeId ?? '',
      'Rack_Num': rackNum ?? '',
      'Locator_Info': locatorInfo ?? '',
      'Item_Name': itemName ?? '',
      'Batch_Number': batchNumber ?? '',
      'Requested_Quantity': requestedQuantity ?? 0,
      'Submitted_Quantity': submittedQuantity ?? 0,
      'OCR_Confidence': ocrConfidence ?? 0,
      'Image': base64Image ?? '',
      'Extracted_Text': extractedText ?? '',
      'Processing_Time': processingTime ?? 0,
      'Match_Type': matchType ?? '',
      'Response_Code': responseCode ?? 0,
      'Timestamp': DateTime.now().toIso8601String(),
    };
    
    // Calculate payload size
    final payloadJson = json.encode(body);
    final payloadSizeBytes = payloadJson.length;
    
    _logger.logApp('MOBILE_LOG_PAYLOAD: Payload prepared for submission', data: {
      'sessionId': sessionId,
      'batchNumber': batchNumber,
      'itemName': itemName,
      'payloadSizeBytes': payloadSizeBytes,
      'payloadSizeKB': (payloadSizeBytes / 1024).toStringAsFixed(2),
      'hasImage': base64Image != null && base64Image.isNotEmpty,
      'imageSizeBytes': base64Image?.length ?? 0,
      'extractedTextLength': extractedText?.length ?? 0,
      'ocrConfidence': ocrConfidence,
      'processingTime': processingTime,
      'matchType': matchType,
      'responseCode': responseCode,
      'salesOrder': salesOrder,
      'purchaseOrder': purchaseOrder,
      'unitId': unitId,
      'storeId': storeId,
      'rackNum': rackNum,
      'imageEncodingTimeMs': imageEncodingTimeMs,
    });
    
    try {
      final result = await post(endpoint, body: body);
      stopwatch.stop();
      
      if (result.isSuccess) {
        _logger.logApp('MOBILE_LOG_SUCCESS: Mobile log submitted successfully', 
          level: LogLevel.success,
          data: {
            'sessionId': sessionId,
            'batchNumber': batchNumber,
            'itemName': itemName,
            'endpoint': endpoint,
            'statusCode': result.statusCode,
            'totalTimeMs': stopwatch.elapsed.inMilliseconds,
            'payloadSizeBytes': payloadSizeBytes,
            'responseData': result.data,
            'serverResponse': result.data?.toString() ?? 'No response data',
          });
      } else {
        _logger.logError('MOBILE_LOG_FAILURE: Mobile log submission failed', 
          error: result.error ?? 'Unknown error',
          category: 'MOBILE_LOG');
      }
      
      return result;
    } catch (e, stackTrace) {
      stopwatch.stop();
      _logger.logError('MOBILE_LOG_EXCEPTION: Exception during mobile log submission', 
        error: e, 
        stackTrace: stackTrace,
        category: 'MOBILE_LOG');
      
      return ApiResponse<Map<String, dynamic>>.error(
        error: 'Mobile log submission failed: ${e.toString()}',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Submit mobile log data asynchronously in background
  void _submitMobileLogAsync({
    required String sessionId,
    String? salesOrder,
    String? purchaseOrder,
    String? unitId,
    String? storeId,
    String? rackNum,
    String? locatorInfo,
    String? itemName,
    String? batchNumber,
    int? requestedQuantity,
    int? submittedQuantity,
    int? ocrConfidence,
    List<int>? imageBytes,
    String? extractedText,
    int? processingTime,
    String? matchType,
    int? responseCode,
  }) {
    final asyncStartTime = DateTime.now();
    
    _logger.logApp('MOBILE_LOG_ASYNC_START: Starting background mobile log submission', data: {
      'sessionId': sessionId,
      'batchNumber': batchNumber,
      'itemName': itemName,
      'asyncStartTime': asyncStartTime.toIso8601String(),
      'originalResponseCode': responseCode,
      'hasImageData': imageBytes != null && imageBytes.isNotEmpty,
      'imageSizeBytes': imageBytes?.length ?? 0,
      'extractedTextLength': extractedText?.length ?? 0,
    });
    
    // Fire and forget - don't await this call
    submitMobileLog(
      sessionId: sessionId,
      salesOrder: salesOrder,
      purchaseOrder: purchaseOrder,
      unitId: unitId,
      storeId: storeId,
      rackNum: rackNum,
      locatorInfo: locatorInfo,
      itemName: itemName,
      batchNumber: batchNumber,
      requestedQuantity: requestedQuantity,
      submittedQuantity: submittedQuantity,
      ocrConfidence: ocrConfidence,
      imageBytes: imageBytes,
      extractedText: extractedText,
      processingTime: processingTime,
      matchType: matchType,
      responseCode: responseCode,
    ).then((result) {
      final asyncEndTime = DateTime.now();
      final asyncDurationMs = asyncEndTime.difference(asyncStartTime).inMilliseconds;
      
      _logger.logApp('MOBILE_LOG_ASYNC_COMPLETE: Background mobile log submission completed', 
        level: result.isSuccess ? LogLevel.success : LogLevel.error,
        data: {
          'sessionId': sessionId,
          'batchNumber': batchNumber,
          'itemName': itemName,
          'asyncStartTime': asyncStartTime.toIso8601String(),
          'asyncEndTime': asyncEndTime.toIso8601String(),
          'asyncDurationMs': asyncDurationMs,
          'success': result.isSuccess,
          'statusCode': result.statusCode,
          'resultMessage': result.message,
          'resultError': result.error,
          'backgroundSubmissionStatus': result.isSuccess ? 'COMPLETED_SUCCESSFULLY' : 'FAILED',
        });
    }).catchError((error, stackTrace) {
      final asyncEndTime = DateTime.now();
      final asyncDurationMs = asyncEndTime.difference(asyncStartTime).inMilliseconds;
      
      _logger.logApp('MOBILE_LOG_ASYNC_ERROR_DETAILS: Background mobile log failed with details', data: {
        'sessionId': sessionId,
        'batchNumber': batchNumber,
        'asyncDurationMs': asyncDurationMs,
        'errorType': error.runtimeType.toString(),
      });
      
      // Log error but don't fail the main submission
      _logger.logError('MOBILE_LOG_ASYNC_ERROR: Background mobile log submission failed', 
        error: error, 
        stackTrace: stackTrace,
        category: 'MOBILE_LOG_ASYNC');
      
      // Don't return anything from catchError for void method
      return null;
    });
  }

  // Get filtered batches for a session
  Future<BatchListResponse> getFilteredBatches(String sessionId) async {
    final endpoint = '${Constants.filteredBatchesEndpoint}/$sessionId';
    final url = '$baseUrl$endpoint';
    final stopwatch = Stopwatch()..start();

    // Log the outgoing request
    _logger.logApiRequest('GET', url, headers: defaultHeaders);

    try {
      // Validate session ID
      if (!Helpers.isValidSessionId(sessionId)) {
        throw ArgumentError('Invalid session ID: $sessionId');
      }

      // Check network connectivity
      final connectivityResults = await Connectivity().checkConnectivity();
      if (connectivityResults.contains(ConnectivityResult.none) || connectivityResults.isEmpty) {
        _logger.logNetwork('No network connectivity', level: LogLevel.error);
        throw const SocketException('No network connection');
      }

      final response = await _client
          .get(Uri.parse(url), headers: defaultHeaders)
          .timeout(timeout);

      stopwatch.stop();

      // Log the response
      _logger.logApiResponse('GET', url, response.statusCode, stopwatch.elapsed,
          headers: response.headers, body: response.body);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        
        // Create API response first
        final apiResponse = ApiResponse.success(
          data: jsonData,
          statusCode: response.statusCode,
          headers: response.headers,
          duration: stopwatch.elapsed,
        );

        // Check if this is the new API format (has 'batchData' field)
        BatchListResponse batchResponse;
        if (jsonData.containsKey('batchData') && jsonData.containsKey('sessionDetails')) {
          // Use new API format parser
          batchResponse = BatchListResponse.fromNewApiFormat(apiResponse);
        } else {
          // Use legacy format parser
          batchResponse = BatchListResponse.fromApiResponse(apiResponse);
        }
        
        _logger.logApp('Batch data loaded successfully',
            level: LogLevel.success,
            data: {
              'sessionId': sessionId,
              'batchCount': batchResponse.batchCount,
              'hasSessionDetails': batchResponse.sessionDetails != null,
              'duration': stopwatch.elapsed.inMilliseconds
            });

        return batchResponse;
      } else {
        String errorMessage;
        try {
          final errorData = json.decode(response.body) as Map<String, dynamic>;
          errorMessage = errorData['message'] ?? errorData['error'] ?? 
                        'Failed to load batches';
        } catch (e) {
          errorMessage = 'Failed to load batches (${response.statusCode})';
        }
        
        _logger.logError('Batch loading failed', 
            error: errorMessage);

        return BatchListResponse(
          success: false,
          error: errorMessage,
          statusCode: response.statusCode,
          headers: response.headers,
          duration: stopwatch.elapsed,
        );
      }
    } on ArgumentError catch (e, stackTrace) {
      stopwatch.stop();
      _logger.logError('Invalid session ID',
          error: e, stackTrace: stackTrace);
      return BatchListResponse(
        success: false,
        error: 'Invalid session ID: ${e.message}',
        duration: stopwatch.elapsed,
      );
    } on SocketException catch (e, stackTrace) {
      stopwatch.stop();
      _logger.logError('Network error during batch loading',
          error: e, stackTrace: stackTrace);
      return BatchListResponse(
        success: false,
        error: 'Network connection failed: ${e.message}',
        duration: stopwatch.elapsed,
      );
    } on HttpException catch (e, stackTrace) {
      stopwatch.stop();
      _logger.logError('HTTP error during batch loading',
          error: e, stackTrace: stackTrace);
      return BatchListResponse(
        success: false,
        error: 'HTTP error: ${e.message}',
        duration: stopwatch.elapsed,
      );
    } on FormatException catch (e, stackTrace) {
      stopwatch.stop();
      _logger.logError('JSON parsing error during batch loading',
          error: e, stackTrace: stackTrace);
      return BatchListResponse(
        success: false,
        error: 'Invalid response format',
        duration: stopwatch.elapsed,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      _logger.logError('Unexpected error during batch loading',
          error: e, stackTrace: stackTrace);
      return BatchListResponse(
        success: false,
        error: 'Unexpected error: ${e.toString()}',
        duration: stopwatch.elapsed,
      );
    }
  }

  // Generic GET request with logging
  Future<ApiResponse<Map<String, dynamic>>> get(String endpoint, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async {
    final Uri uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: queryParameters,
    );
    final requestHeaders = {...defaultHeaders, ...?headers};
    final stopwatch = Stopwatch()..start();

    _logger.logApiRequest('GET', uri.toString(), headers: requestHeaders);

    try {
      final response = await _client
          .get(uri, headers: requestHeaders)
          .timeout(timeout);

      stopwatch.stop();

      _logger.logApiResponse('GET', uri.toString(), response.statusCode, 
          stopwatch.elapsed, headers: response.headers, body: response.body);

      return ApiResponse.fromHttpResponse(
        response,
        stopwatch.elapsed,
        parser: (json) => json,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      _logger.logError('GET request failed',
          error: e, stackTrace: stackTrace);
      return ApiResponse.error(
        error: e.toString(),
        duration: stopwatch.elapsed,
      );
    }
  }

  // Generic POST request with logging
  Future<ApiResponse<Map<String, dynamic>>> post(String endpoint, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    final url = '$baseUrl$endpoint';
    final requestHeaders = {...defaultHeaders, ...?headers};
    final requestBody = body != null ? json.encode(body) : null;
    final stopwatch = Stopwatch()..start();

    _logger.logApiRequest('POST', url, 
        headers: requestHeaders, body: requestBody);

    try {
      final response = await _client
          .post(Uri.parse(url), headers: requestHeaders, body: requestBody)
          .timeout(timeout);

      stopwatch.stop();

      _logger.logApiResponse('POST', url, response.statusCode, 
          stopwatch.elapsed, headers: response.headers, body: response.body);

      return ApiResponse.fromHttpResponse(
        response,
        stopwatch.elapsed,
        parser: (json) => json,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      _logger.logError('POST request failed',
          error: e, stackTrace: stackTrace);
      return ApiResponse.error(
        error: e.toString(),
        duration: stopwatch.elapsed,
      );
    }
  }

  // Generic PUT request with logging
  Future<ApiResponse<Map<String, dynamic>>> put(String endpoint, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    final url = '$baseUrl$endpoint';
    final requestHeaders = {...defaultHeaders, ...?headers};
    final requestBody = body != null ? json.encode(body) : null;
    final stopwatch = Stopwatch()..start();

    _logger.logApiRequest('PUT', url, 
        headers: requestHeaders, body: requestBody);

    try {
      final response = await _client
          .put(Uri.parse(url), headers: requestHeaders, body: requestBody)
          .timeout(timeout);

      stopwatch.stop();

      _logger.logApiResponse('PUT', url, response.statusCode, 
          stopwatch.elapsed, headers: response.headers, body: response.body);

      return ApiResponse.fromHttpResponse(
        response,
        stopwatch.elapsed,
        parser: (json) => json,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      _logger.logError('PUT request failed',
          error: e, stackTrace: stackTrace);
      return ApiResponse.error(
        error: e.toString(),
        duration: stopwatch.elapsed,
      );
    }
  }

  // Generic DELETE request with logging
  Future<ApiResponse<Map<String, dynamic>>> delete(String endpoint, {
    Map<String, String>? headers,
  }) async {
    final url = '$baseUrl$endpoint';
    final requestHeaders = {...defaultHeaders, ...?headers};
    final stopwatch = Stopwatch()..start();

    _logger.logApiRequest('DELETE', url, headers: requestHeaders);

    try {
      final response = await _client
          .delete(Uri.parse(url), headers: requestHeaders)
          .timeout(timeout);

      stopwatch.stop();

      _logger.logApiResponse('DELETE', url, response.statusCode, 
          stopwatch.elapsed, headers: response.headers, body: response.body);

      return ApiResponse.fromHttpResponse(
        response,
        stopwatch.elapsed,
        parser: (json) => json,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      _logger.logError('DELETE request failed',
          error: e, stackTrace: stackTrace);
      return ApiResponse.error(
        error: e.toString(),
        duration: stopwatch.elapsed,
      );
    }
  }

  // Test connectivity
  Future<bool> testConnectivity() async {
    try {
      final response = await checkHealth();
      return response.isSuccess;
    } catch (e) {
      _logger.logNetwork('Connectivity test failed', 
          level: LogLevel.error, data: {'error': e.toString()});
      return false;
    }
  }

  // Batch operations with retry logic
  Future<BatchListResponse> getBatchesWithRetry(String sessionId, {
    int maxRetries = Constants.maxRetryAttempts,
    Duration retryDelay = Constants.networkRetryDelay,
  }) async {
    _logger.logApp('Starting batch fetch with retry logic',
        data: {'sessionId': sessionId, 'maxRetries': maxRetries});

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      _logger.logApp('Batch fetch attempt $attempt/$maxRetries');
      
      final response = await getFilteredBatches(sessionId);
      
      if (response.isSuccess) {
        _logger.logApp('Batch fetch successful on attempt $attempt');
        return response;
      }

      if (attempt < maxRetries) {
        _logger.logApp('Batch fetch failed, retrying in ${retryDelay.inSeconds}s',
            level: LogLevel.warning);
        await Future.delayed(retryDelay);
      }
    }

    _logger.logError('Batch fetch failed after $maxRetries attempts');
    return BatchListResponse(
      success: false,
      error: 'Failed to load batches after $maxRetries attempts',
    );
  }

  // Alias for getFilteredBatches for compatibility
  Future<ApiResponse<List<BatchModel>>> getBatches(String sessionId) async {
    final response = await getFilteredBatches(sessionId);
    return ApiResponse<List<BatchModel>>(
      success: response.success,
      data: response.batches,
      message: response.error,
      statusCode: response.success ? 200 : 500,
    );
  }

  // Get session details with new hierarchical structure (racks/items/batches)
  Future<SessionDetailsResponse> getSessionDetails(String sessionId) async {
    final endpoint = '${Constants.filteredBatchesEndpoint}/$sessionId';
    final url = '$baseUrl$endpoint';
    final stopwatch = Stopwatch()..start();

    // Log the outgoing request
    _logger.logApiRequest('GET', url, headers: defaultHeaders);

    try {
      // Validate session ID
      if (!Helpers.isValidSessionId(sessionId)) {
        throw ArgumentError('Invalid session ID: $sessionId');
      }

      // Check network connectivity
      final connectivityResults = await Connectivity().checkConnectivity();
      if (connectivityResults.contains(ConnectivityResult.none) || connectivityResults.isEmpty) {
        _logger.logNetwork('No network connectivity', level: LogLevel.error);
        throw const SocketException('No network connection');
      }

      final response = await _client
          .get(Uri.parse(url), headers: defaultHeaders)
          .timeout(timeout);

      stopwatch.stop();

      // Log the response
      _logger.logApiResponse('GET', url, response.statusCode, stopwatch.elapsed,
          headers: response.headers, body: response.body);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        
        // Check if this is the new hierarchical API format
        if (jsonData.containsKey('racks') && 
            jsonData.containsKey('unitCode') && 
            jsonData.containsKey('storeId')) {
          
          final sessionDetails = SessionDetailsModel.fromJson(jsonData, sessionId);
          
          _logger.logApp('Session details loaded successfully',
              level: LogLevel.success,
              data: {
                'sessionId': sessionId,
                'rackCount': sessionDetails.racks.length,
                'totalItems': sessionDetails.totalItems,
                'duration': stopwatch.elapsed.inMilliseconds
              });

          return SessionDetailsResponse(
            success: true,
            data: sessionDetails,
            statusCode: response.statusCode,
            headers: response.headers,
            duration: stopwatch.elapsed,
          );
        } else {
          // Fallback for legacy format
          _logger.logApp('Legacy API format detected, converting to session details',
              level: LogLevel.warning);
          
          return SessionDetailsResponse(
            success: false,
            error: 'Legacy API format not supported for session details',
            statusCode: response.statusCode,
            headers: response.headers,
            duration: stopwatch.elapsed,
          );
        }
      } else {
        String errorMessage;
        try {
          final errorData = json.decode(response.body) as Map<String, dynamic>;
          errorMessage = errorData['message'] ?? errorData['error'] ?? 
                        'Failed to load session details';
        } catch (e) {
          errorMessage = 'Failed to load session details (${response.statusCode})';
        }
        
        _logger.logError('Session details loading failed', 
            error: errorMessage);

        return SessionDetailsResponse(
          success: false,
          error: errorMessage,
          statusCode: response.statusCode,
          headers: response.headers,
          duration: stopwatch.elapsed,
        );
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      _logger.logError('Exception while loading session details',
          error: e, stackTrace: stackTrace);
      
      return SessionDetailsResponse(
        success: false,
        error: 'Failed to load session details: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  // Dispose resources
  void dispose() {
    _client.close();
  }
}
