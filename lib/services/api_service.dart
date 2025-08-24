import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/api_response_model.dart';
import '../models/health_response_model.dart';
import '../models/batch_model.dart';
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
    return await post(endpoint, body: body);
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

  // Dispose resources
  void dispose() {
    _client.close();
  }
}
