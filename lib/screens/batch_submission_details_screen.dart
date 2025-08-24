import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/logging_provider.dart';
import '../utils/app_colors.dart';
import '../utils/helpers.dart';
import 'dart:typed_data';

class BatchSubmissionDetailsScreen extends StatefulWidget {
  final dynamic submittedBatch;

  const BatchSubmissionDetailsScreen({
    super.key,
    required this.submittedBatch,
  });

  @override
  State<BatchSubmissionDetailsScreen> createState() => _BatchSubmissionDetailsScreenState();
}

class _BatchSubmissionDetailsScreenState extends State<BatchSubmissionDetailsScreen> {
  @override
  void initState() {
    super.initState();
    _logScreenAccess();
  }

  void _logScreenAccess() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
      loggingProvider.logApp('Batch submission details screen accessed', data: {
        'batchNumber': widget.submittedBatch['batchNumber']
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('Batch ${widget.submittedBatch['batchNumber'] ?? 'Details'}'),
      elevation: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textColor,
      actions: [
        IconButton(
          onPressed: _shareDetails,
          icon: const Icon(Icons.share),
          tooltip: 'Share Details',
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildCapturedImage(),
          const SizedBox(height: 24),
          _buildExtractionDetails(),
          const SizedBox(height: 24),
          _buildMatchingDetails(),
          const SizedBox(height: 24),
          _buildSubmissionDetails(),
          const SizedBox(height: 24),
          _buildTimingDetails(),
          const SizedBox(height: 24),
          _buildApiDetails(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Submission Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Batch Number', widget.submittedBatch['batchNumber'] ?? 'Unknown'),
            _buildInfoRow('Product', widget.submittedBatch['itemName'] ?? 'Unknown'),
            _buildInfoRow('Quantity Submitted', '${widget.submittedBatch['quantity'] ?? 'Unknown'}'),
            _buildInfoRow('Submission Status', 
              widget.submittedBatch['submissionSummary']?['submissionStatus'] ?? 'Completed Successfully'),
            _buildInfoRow('Submitted At', _formatDateTime(widget.submittedBatch['submittedAt'])),
          ],
        ),
      ),
    );
  }

  Widget _buildCapturedImage() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Captured Image',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (widget.submittedBatch['capturedImage'] != null) ...[
              GestureDetector(
                onTap: () => _showFullScreenImage(),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Image.memory(
                          widget.submittedBatch['capturedImage'],
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.image_not_supported, color: Colors.grey),
                            );
                          },
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.zoom_in, color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'Tap to enlarge',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No image available', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExtractionDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.text_fields, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'OCR Extraction Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Extracted Text', 
              widget.submittedBatch['ocrExtractionDetails']?['extractedText'] ?? 'N/A'),
            _buildInfoRow('OCR Confidence', 
              '${widget.submittedBatch['ocrExtractionDetails']?['ocrConfidencePercent'] ?? 'N/A'}%'),
            _buildInfoRow('Text Processing Time', 
              '${widget.submittedBatch['ocrExtractionDetails']?['textProcessingTimeMs'] ?? 'N/A'} ms'),
            _buildInfoRow('Characters Detected', 
              '${widget.submittedBatch['ocrExtractionDetails']?['charactersDetected'] ?? 0}'),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchingDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.search, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Batch Matching Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Match Type', 
              widget.submittedBatch['batchMatchingDetails']?['matchType'] ?? 'Unknown'),
            _buildInfoRow('Match Confidence', 
              '${widget.submittedBatch['batchMatchingDetails']?['matchConfidencePercent'] ?? 'N/A'}%'),
            _buildInfoRow('Matched Batch', 
              widget.submittedBatch['batchMatchingDetails']?['matchedBatchId'] ?? 'N/A'),
            _buildInfoRow('Matching Duration', 
              '${widget.submittedBatch['batchMatchingDetails']?['matchingDurationMs'] ?? 'N/A'} ms'),
            if (widget.submittedBatch['alternativeMatches'] != null && 
                (widget.submittedBatch['alternativeMatches'] as List).isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Alternative Matches:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              ...(widget.submittedBatch['alternativeMatches'] as List).map((match) =>
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 2),
                  child: Text('• $match', style: const TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_upload, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'API Submission Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Session ID', widget.submittedBatch['sessionId'] ?? 'N/A'),
            _buildInfoRow('Capture ID', 
              widget.submittedBatch['apiSubmissionDetails']?['captureId'] ?? 'N/A'),
            _buildInfoRow('Selected from Options', 
              widget.submittedBatch['apiSubmissionDetails']?['selectedFromOptions'] ?? 'N/A'),
            _buildInfoRow('Submission Duration', 
              '${widget.submittedBatch['apiSubmissionDetails']?['submissionDurationMs'] ?? 'N/A'} ms'),
            _buildInfoRow('API Response Code', 
              '${widget.submittedBatch['apiSubmissionDetails']?['apiResponseCode'] ?? 'N/A'}'),
            _buildInfoRow('API Response Code', '${widget.submittedBatch['apiResponseCode'] ?? 'N/A'}'),
          ],
        ),
      ),
    );
  }

  Widget _buildTimingDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Performance Metrics',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTimingRow('OCR Processing', 
              widget.submittedBatch['performanceMetrics']?['ocrProcessingTimeMs']),
            _buildTimingRow('Batch Matching', 
              widget.submittedBatch['performanceMetrics']?['batchMatchingTimeMs']),
            _buildTimingRow('API Submission', 
              widget.submittedBatch['performanceMetrics']?['apiSubmissionTimeMs']),
            const Divider(),
            _buildTimingRow('Total Processing', 
              widget.submittedBatch['performanceMetrics']?['totalProcessingTimeMs'] ?? _calculateTotalTime(), 
              isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildApiDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.api, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'API Communication Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Endpoint Used', 
              widget.submittedBatch['apiCommunicationDetails']?['endpointUsed'] ?? '/api/submit-mobile-batch/${widget.submittedBatch['sessionId'] ?? 'N/A'}'),
            _buildInfoRow('Request Method', 
              widget.submittedBatch['apiCommunicationDetails']?['requestMethod'] ?? 'POST'),
            _buildInfoRow('Response Status', 
              '${widget.submittedBatch['apiCommunicationDetails']?['responseStatus'] ?? 'N/A'}'),
            _buildInfoRow('Response Time', 
              widget.submittedBatch['apiCommunicationDetails']?['responseTimeMs'] ?? 'N/A ms'),
            _buildInfoRow('Data Size Sent', 
              '${widget.submittedBatch['apiCommunicationDetails']?['dataSizeBytes'] ?? _calculateDataSize()} bytes'),
            _buildInfoRow('Timestamp', 
              _formatDateTime(widget.submittedBatch['apiCommunicationDetails']?['timestamp'] ?? widget.submittedBatch['submittedAt'])),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingRow(String label, dynamic duration, {bool isTotal = false}) {
    final durationMs = duration is int ? duration : (duration is String ? int.tryParse(duration) ?? 0 : 0);
    final color = isTotal ? AppColors.primary : Colors.black87;
    final fontWeight = isTotal ? FontWeight.bold : FontWeight.normal;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: fontWeight, color: color),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Text(
                  '${durationMs}ms',
                  style: TextStyle(color: color, fontWeight: fontWeight),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: durationMs / 2000, // Assuming max 2 seconds for visualization
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getPerformanceColor(durationMs),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPerformanceColor(int durationMs) {
    if (durationMs < 500) return Colors.green;
    if (durationMs < 1000) return Colors.orange;
    return Colors.red;
  }

  int _calculateTotalTime() {
    // Try to get from performance metrics first
    final performanceMetrics = widget.submittedBatch['performanceMetrics'];
    if (performanceMetrics is Map) {
      final total = performanceMetrics['totalProcessingTimeMs'];
      if (total is int) return total;
      
      // Calculate from individual metrics
      int calculated = 0;
      final ocr = performanceMetrics['ocrProcessingTimeMs'];
      final matching = performanceMetrics['batchMatchingTimeMs'];
      final api = performanceMetrics['apiSubmissionTimeMs'];
      
      if (ocr is int) calculated += ocr;
      if (matching is int) calculated += matching;
      if (api is int) calculated += api;
      
      if (calculated > 0) return calculated;
    }
    
    // Fallback to old structure
    final extraction = widget.submittedBatch['extractionDuration'];
    final matching = widget.submittedBatch['matchingDuration'];
    final submission = widget.submittedBatch['submissionDuration'];
    
    int total = 0;
    if (extraction is int) total += extraction;
    if (matching is int) total += matching;
    if (submission is int) total += submission;
    
    return total;
  }

  String _calculateDataSize() {
    // Rough estimation of the data sent to API
    int size = 0;
    
    // Add sizes for various fields
    size += (widget.submittedBatch['batchNumber']?.toString().length ?? 0) * 2; // UTF-8 encoding
    size += (widget.submittedBatch['extractedText']?.toString().length ?? 0) * 2;
    size += 100; // Other JSON fields
    
    // Add image size if available
    if (widget.submittedBatch['capturedImage'] is Uint8List) {
      size += (widget.submittedBatch['capturedImage'] as Uint8List).length;
    }
    
    return size.toString();
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return 'N/A';
    
    try {
      DateTime dt;
      if (dateTime is String) {
        dt = DateTime.parse(dateTime);
      } else if (dateTime is DateTime) {
        dt = dateTime;
      } else {
        return dateTime.toString();
      }
      
      return Helpers.formatDateTime(dt);
    } catch (e) {
      return dateTime.toString();
    }
  }

  void _showFullScreenImage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text('Captured Image'),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.memory(
                widget.submittedBatch['capturedImage'],
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _shareDetails() {
    // TODO: Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }
}
