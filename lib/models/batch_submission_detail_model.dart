import 'dart:typed_data';

/// Comprehensive model for batch submission details
class BatchSubmissionDetail {
  final String submissionId;
  final String sessionId;
  final DateTime submissionTimestamp;
  
  // Basic batch information
  final String batchNumber;
  final String itemName;
  final String? expiryDate;
  final int requestedQuantity;
  final int submittedQuantity;
  final String? rackName; // Add rack information
  final String? rackLocation; // Add rack location info
  
  // OCR and matching data
  final String extractedText;
  final Uint8List? capturedImage;
  final int ocrConfidence;
  final String matchType; // 'top_match', 'alternative_match', 'manual'
  final double matchConfidence;
  final String? matchedBatchId;
  
  // Performance metrics
  final int ocrProcessingTimeMs;
  final int batchMatchingTimeMs;
  final int apiSubmissionTimeMs;
  final int totalProcessingTimeMs;
  final int charactersDetected;
  
  // API details
  final Map<String, dynamic> apiPayload;
  final Map<String, dynamic>? apiResponse;
  final int apiResponseCode;
  final String apiEndpoint;
  final int dataSizeBytes;
  final String submissionStatus;
  
  // Additional metadata
  final List<String>? alternativeMatches;
  final String? errorMessage;
  final int retryCount;

  BatchSubmissionDetail({
    required this.submissionId,
    required this.sessionId,
    required this.submissionTimestamp,
    required this.batchNumber,
    required this.itemName,
    this.expiryDate,
    required this.requestedQuantity,
    required this.submittedQuantity,
    this.rackName,
    this.rackLocation,
    required this.extractedText,
    this.capturedImage,
    required this.ocrConfidence,
    required this.matchType,
    required this.matchConfidence,
    this.matchedBatchId,
    required this.ocrProcessingTimeMs,
    required this.batchMatchingTimeMs,
    required this.apiSubmissionTimeMs,
    required this.totalProcessingTimeMs,
    required this.charactersDetected,
    required this.apiPayload,
    this.apiResponse,
    required this.apiResponseCode,
    required this.apiEndpoint,
    required this.dataSizeBytes,
    required this.submissionStatus,
    this.alternativeMatches,
    this.errorMessage,
    this.retryCount = 0,
  });

  /// Create from JSON
  factory BatchSubmissionDetail.fromJson(Map<String, dynamic> json) {
    return BatchSubmissionDetail(
      submissionId: json['submissionId'] ?? '',
      sessionId: json['sessionId'] ?? '',
      submissionTimestamp: DateTime.fromMillisecondsSinceEpoch(
        json['submissionTimestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      batchNumber: json['batchNumber'] ?? '',
      itemName: json['itemName'] ?? '',
      expiryDate: json['expiryDate'],
      requestedQuantity: json['requestedQuantity'] ?? 0,
      submittedQuantity: json['submittedQuantity'] ?? 0,
      rackName: json['rackName'],
      rackLocation: json['rackLocation'],
      extractedText: json['extractedText'] ?? '',
      capturedImage: json['capturedImage'] != null 
          ? Uint8List.fromList(List<int>.from(json['capturedImage']))
          : null,
      ocrConfidence: json['ocrConfidence'] ?? 0,
      matchType: json['matchType'] ?? '',
      matchConfidence: (json['matchConfidence'] ?? 0.0).toDouble(),
      matchedBatchId: json['matchedBatchId'],
      ocrProcessingTimeMs: json['ocrProcessingTimeMs'] ?? 0,
      batchMatchingTimeMs: json['batchMatchingTimeMs'] ?? 0,
      apiSubmissionTimeMs: json['apiSubmissionTimeMs'] ?? 0,
      totalProcessingTimeMs: json['totalProcessingTimeMs'] ?? 0,
      charactersDetected: json['charactersDetected'] ?? 0,
      apiPayload: json['apiPayload'] ?? {},
      apiResponse: json['apiResponse'],
      apiResponseCode: json['apiResponseCode'] ?? 0,
      apiEndpoint: json['apiEndpoint'] ?? '',
      dataSizeBytes: json['dataSizeBytes'] ?? 0,
      submissionStatus: json['submissionStatus'] ?? '',
      alternativeMatches: json['alternativeMatches'] != null
          ? List<String>.from(json['alternativeMatches'])
          : null,
      errorMessage: json['errorMessage'],
      retryCount: json['retryCount'] ?? 0,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'submissionId': submissionId,
      'sessionId': sessionId,
      'submissionTimestamp': submissionTimestamp.millisecondsSinceEpoch,
      'batchNumber': batchNumber,
      'itemName': itemName,
      'expiryDate': expiryDate,
      'requestedQuantity': requestedQuantity,
      'submittedQuantity': submittedQuantity,
      'rackName': rackName,
      'rackLocation': rackLocation,
      'extractedText': extractedText,
      'capturedImage': capturedImage?.toList(),
      'ocrConfidence': ocrConfidence,
      'matchType': matchType,
      'matchConfidence': matchConfidence,
      'matchedBatchId': matchedBatchId,
      'ocrProcessingTimeMs': ocrProcessingTimeMs,
      'batchMatchingTimeMs': batchMatchingTimeMs,
      'apiSubmissionTimeMs': apiSubmissionTimeMs,
      'totalProcessingTimeMs': totalProcessingTimeMs,
      'charactersDetected': charactersDetected,
      'apiPayload': apiPayload,
      'apiResponse': apiResponse,
      'apiResponseCode': apiResponseCode,
      'apiEndpoint': apiEndpoint,
      'dataSizeBytes': dataSizeBytes,
      'submissionStatus': submissionStatus,
      'alternativeMatches': alternativeMatches,
      'errorMessage': errorMessage,
      'retryCount': retryCount,
    };
  }

  /// Get formatted submission time
  String get formattedSubmissionTime {
    return '${submissionTimestamp.day}/${submissionTimestamp.month}/${submissionTimestamp.year} ${submissionTimestamp.hour}:${submissionTimestamp.minute.toString().padLeft(2, '0')}';
  }

  /// Get status color based on submission status
  String get statusColor {
    switch (submissionStatus.toLowerCase()) {
      case 'completed successfully':
      case 'success':
        return 'green';
      case 'failed':
      case 'error':
        return 'red';
      case 'pending':
      case 'processing':
        return 'orange';
      default:
        return 'grey';
    }
  }

  /// Get performance summary
  String get performanceSummary {
    return 'OCR: ${ocrProcessingTimeMs}ms, Matching: ${batchMatchingTimeMs}ms, API: ${apiSubmissionTimeMs}ms';
  }

  /// Copy with updated fields
  BatchSubmissionDetail copyWith({
    String? submissionId,
    String? sessionId,
    DateTime? submissionTimestamp,
    String? batchNumber,
    String? itemName,
    String? expiryDate,
    int? requestedQuantity,
    int? submittedQuantity,
    String? extractedText,
    Uint8List? capturedImage,
    int? ocrConfidence,
    String? matchType,
    double? matchConfidence,
    String? matchedBatchId,
    int? ocrProcessingTimeMs,
    int? batchMatchingTimeMs,
    int? apiSubmissionTimeMs,
    int? totalProcessingTimeMs,
    int? charactersDetected,
    Map<String, dynamic>? apiPayload,
    Map<String, dynamic>? apiResponse,
    int? apiResponseCode,
    String? apiEndpoint,
    int? dataSizeBytes,
    String? submissionStatus,
    List<String>? alternativeMatches,
    String? errorMessage,
    int? retryCount,
  }) {
    return BatchSubmissionDetail(
      submissionId: submissionId ?? this.submissionId,
      sessionId: sessionId ?? this.sessionId,
      submissionTimestamp: submissionTimestamp ?? this.submissionTimestamp,
      batchNumber: batchNumber ?? this.batchNumber,
      itemName: itemName ?? this.itemName,
      expiryDate: expiryDate ?? this.expiryDate,
      requestedQuantity: requestedQuantity ?? this.requestedQuantity,
      submittedQuantity: submittedQuantity ?? this.submittedQuantity,
      extractedText: extractedText ?? this.extractedText,
      capturedImage: capturedImage ?? this.capturedImage,
      ocrConfidence: ocrConfidence ?? this.ocrConfidence,
      matchType: matchType ?? this.matchType,
      matchConfidence: matchConfidence ?? this.matchConfidence,
      matchedBatchId: matchedBatchId ?? this.matchedBatchId,
      ocrProcessingTimeMs: ocrProcessingTimeMs ?? this.ocrProcessingTimeMs,
      batchMatchingTimeMs: batchMatchingTimeMs ?? this.batchMatchingTimeMs,
      apiSubmissionTimeMs: apiSubmissionTimeMs ?? this.apiSubmissionTimeMs,
      totalProcessingTimeMs: totalProcessingTimeMs ?? this.totalProcessingTimeMs,
      charactersDetected: charactersDetected ?? this.charactersDetected,
      apiPayload: apiPayload ?? this.apiPayload,
      apiResponse: apiResponse ?? this.apiResponse,
      apiResponseCode: apiResponseCode ?? this.apiResponseCode,
      apiEndpoint: apiEndpoint ?? this.apiEndpoint,
      dataSizeBytes: dataSizeBytes ?? this.dataSizeBytes,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      alternativeMatches: alternativeMatches ?? this.alternativeMatches,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}
