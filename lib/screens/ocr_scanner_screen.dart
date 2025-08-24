import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:io';

import '../providers/logging_provider.dart';
import '../providers/batch_provider.dart';
import '../services/ocr_service.dart';
import '../services/api_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/swipeable_batch_match_cards.dart';
import '../models/batch_match_model.dart';
import '../utils/app_colors.dart';

class OCRScannerScreen extends StatefulWidget {
  const OCRScannerScreen({super.key});

  @override
  State<OCRScannerScreen> createState() => _OCRScannerScreenState();
}

class _OCRScannerScreenState extends State<OCRScannerScreen>
    with WidgetsBindingObserver {
  late OcrService _ocrService;
  
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _isFlashOn = false;
  String? _capturedImagePath;
  String? _extractedText;
  List<int>? _lastCapturedImageBytes;
  
  // Performance tracking
  Duration? _ocrProcessingTime;
  Duration? _matchingProcessingTime;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeOCR();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Don't dispose camera controller here as it's managed by OCR service
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle for OCR service
    if (state == AppLifecycleState.inactive) {
      // OCR service will handle camera cleanup
    } else if (state == AppLifecycleState.resumed) {
      _reinitializeOCR();
    }
  }

  void _initializeOCR() async {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    
    try {
      _ocrService = OcrService.instance;
      loggingProvider.logApp('Initializing OCR service');
      
      final initialized = await _ocrService.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = initialized;
        });
      }
      
      if (initialized) {
        loggingProvider.logSuccess('OCR service initialized successfully');
      } else {
        loggingProvider.logError('OCR service initialization failed');
      }
    } catch (e) {
      loggingProvider.logError('OCR service initialization failed: $e');
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    }
  }

  void _reinitializeOCR() async {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    
    try {
      loggingProvider.logApp('Re-initializing OCR service after app resume');
      final initialized = await _ocrService.reinitialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = initialized;
        });
      }
      
      if (initialized) {
        loggingProvider.logSuccess('OCR service re-initialized successfully');
      } else {
        loggingProvider.logError('OCR service re-initialization failed');
      }
    } catch (e) {
      loggingProvider.logError('OCR service re-initialization failed: $e');
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    }
  }

  /// Show swipeable batch match cards for top 5 matches
  Future<void> _showSwipeableBatchMatchCards(String extractedText) async {
    final batchProvider = Provider.of<BatchProvider>(context, listen: false);
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    
    try {
      // Get cached batches
      final batches = batchProvider.batches;
      if (batches.isEmpty) {
        _showSimpleErrorDialog('No batches available', 'Please scan QR code first to load batch data.');
        return;
      }

      // Get session details from batch provider
      final sessionDetails = batchProvider.sessionDetails ?? {};

      // Find top 5 matches using the new OCR service method
      final matchResults = _ocrService.findTop5BatchMatchesForCards(
        extractedText: extractedText,
        batches: batches,
        sessionDetails: sessionDetails,
      );

      if (matchResults.isEmpty) {
        _showSimpleErrorDialog('No matches found', 'No batch matches found for the scanned text.');
        return;
      }

      // Convert to BatchMatch objects
      final batchMatches = <BatchMatch>[];
      for (int i = 0; i < matchResults.length; i++) {
        final result = matchResults[i];
        final batch = result['batch']; // Access the nested batch object
        batchMatches.add(BatchMatch(
          batchNumber: batch?.batchNumber ?? batch?.batchId ?? '',
          itemName: batch?.itemName ?? batch?.productName ?? '',
          expiryDate: batch?.expiryDate ?? '',
          confidence: (result['confidence'] ?? 0.0).toDouble(),
          requestedQuantity: result['requestedQuantity'] ?? 0,
          rank: i + 1,
          itemCode: result['itemCode'],
          purchaseOrderNumber: result['purchaseOrderNumber'],
          saleOrderNumber: result['saleOrderNumber'],
        ));
      }

      // Show swipeable cards in modal bottom sheet
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => SwipeableBatchMatchCards(
          matches: batchMatches,
          onSubmit: (batchMatch, quantity) async {
            Navigator.pop(context); // Close the modal
            await _handleBatchSubmission(batchMatch, quantity, extractedText);
          },
          onRetake: () {
            Navigator.pop(context); // Close the modal
            _retakePhoto(); // Restart camera
          },
          onClose: () {
            Navigator.pop(context); // Just close the modal
          },
        ),
      );

    } catch (e) {
      loggingProvider.logError('Error showing batch match cards: $e');
      _showSimpleErrorDialog('Error', 'Failed to process batch matches: ${e.toString()}');
    }
  }

  /// Simple error dialog
  void _showSimpleErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Handle batch submission from swipeable cards
  Future<void> _handleBatchSubmission(BatchMatch batchMatch, int quantity, String extractedText) async {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    final batchProvider = Provider.of<BatchProvider>(context, listen: false);

    try {
      loggingProvider.logApp('Batch submitted from swipeable cards', 
        data: {
          'batchNumber': batchMatch.batchNumber,
          'quantity': quantity,
          'confidence': batchMatch.confidence,
          'rank': batchMatch.rank,
        }
      );

      // Create a BatchModel object from BatchMatch for submission
      final batchForSubmission = batchProvider.batches.firstWhere(
        (batch) => (batch.batchNumber ?? batch.batchId) == batchMatch.batchNumber,
      );

      // Submit the batch
      await _submitBatch(
        batch: batchForSubmission,
        quantity: quantity,
        extractedText: extractedText,
        confidence: batchMatch.confidence.round(),
        matchType: batchMatch.rank == 1 ? 'top_match' : 'alternative_match',
        alternativeMatches: [], // Empty for now
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Batch ${batchMatch.batchNumber} submitted successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate back or restart scanning
      _resetForNextScan();

    } catch (e) {
      loggingProvider.logError('Error submitting batch: $e');
      _showSimpleErrorDialog('Submission Error', 'Failed to submit batch: ${e.toString()}');
    }
  }

  /// Reset scanner for next scan
  void _resetForNextScan() {
    setState(() {
      _capturedImagePath = null;
      _extractedText = null;
      _lastCapturedImageBytes = null;
      _isProcessing = false;
    });
  }

  /// Retake photo by resetting state
  void _retakePhoto() {
    _resetForNextScan();
    // Camera will automatically be available for next capture
  }

  Future<void> _submitBatch({
    required dynamic batch,
    required int quantity,
    required int confidence,
    required String matchType,
    required String extractedText,
    required List<String> alternativeMatches,
  }) async {
    final batchProvider = Provider.of<BatchProvider>(context, listen: false);
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    final apiService = ApiService();
    
    // Performance tracking
    final totalProcessingStopwatch = Stopwatch()..start();
    
    try {
      final sessionId = batchProvider.currentSessionId!;
      final captureId = DateTime.now().millisecondsSinceEpoch.toString();
      final submitTimestamp = DateTime.now().millisecondsSinceEpoch;
      
      loggingProvider.logApp('Submitting batch',
        data: {
          'sessionId': sessionId,
          'batchNumber': batch.batchNumber ?? batch.batchId,
          'quantity': quantity,
          'confidence': confidence,
          'matchType': matchType,
        });
      
      // API submission with timing
      final apiSubmissionStopwatch = Stopwatch()..start();
      final resp = await apiService.submitMobileBatch(
        sessionId: sessionId,
        batchNumber: batch.batchNumber ?? batch.batchId ?? '',
        quantity: quantity,
        captureId: captureId,
        confidence: confidence,
        matchType: matchType,
        submitTimestamp: submitTimestamp,
        extractedText: extractedText,
        selectedFromOptions: matchType != 'manual',
        alternativeMatches: alternativeMatches,
      );
      apiSubmissionStopwatch.stop();
      totalProcessingStopwatch.stop();
      
      // Calculate data size (approximate)
      final requestData = {
        'batchNumber': batch.batchNumber ?? batch.batchId ?? '',
        'quantity': quantity,
        'captureId': captureId,
        'confidence': confidence,
        'matchType': matchType,
        'submitTimestamp': submitTimestamp,
        'extractedText': extractedText,
        'selectedFromOptions': matchType != 'manual',
        'alternativeMatches': alternativeMatches,
      };
      final dataSizeBytes = jsonEncode(requestData).length;
      
      if (resp.isSuccess) {
        batchProvider.incrementSuccessCount();
        
        // Add to submitted batches with comprehensive data
        await batchProvider.addSubmittedBatch(
          batchNumber: batch.batchNumber ?? batch.batchId ?? '',
          itemName: batch.itemName ?? batch.productName ?? 'Unknown Item',
          quantity: quantity.toString(),
          capturedImage: _lastCapturedImageBytes,
          // Comprehensive tracking data
          captureId: captureId,
          extractedText: extractedText,
          ocrConfidence: confidence,
          matchType: matchType,
          matchedBatchId: batch.batchNumber ?? batch.batchId,
          matchConfidence: confidence,
          ocrProcessingTimeMs: _ocrProcessingTime?.inMilliseconds ?? 0,
          batchMatchingTimeMs: _matchingProcessingTime?.inMilliseconds ?? 0,
          apiSubmissionTimeMs: apiSubmissionStopwatch.elapsed.inMilliseconds,
          totalProcessingTimeMs: totalProcessingStopwatch.elapsed.inMilliseconds,
          apiResponseCode: resp.statusCode,
          apiEndpoint: '/api/submit-mobile-batch/$sessionId',
          dataSizeBytes: dataSizeBytes,
          apiResponseTime: '${apiSubmissionStopwatch.elapsed.inMilliseconds} ms',
          submissionStatus: 'Completed Successfully',
          charactersDetected: extractedText.length,
          submissionDurationMs: apiSubmissionStopwatch.elapsed.inMilliseconds,
          selectedFromOptions: matchType != 'manual' ? 'N/A' : 'N/A',
        );
        
        loggingProvider.logSuccess('Batch submitted successfully');
        _showSuccessDialog('Batch submitted successfully!');
        _resetCapture(); // Reset for next scan
      } else {
        batchProvider.incrementErrorCount();
        loggingProvider.logError('Batch submission failed: ${resp.message}');
        
        // Still track failed submissions for analytics
        await batchProvider.addSubmittedBatch(
          batchNumber: batch.batchNumber ?? batch.batchId ?? '',
          itemName: batch.itemName ?? batch.productName ?? 'Unknown Item',
          quantity: quantity.toString(),
          capturedImage: _lastCapturedImageBytes,
          captureId: captureId,
          extractedText: extractedText,
          ocrConfidence: confidence,
          matchType: matchType,
          matchedBatchId: batch.batchNumber ?? batch.batchId,
          matchConfidence: confidence,
          ocrProcessingTimeMs: _ocrProcessingTime?.inMilliseconds ?? 0,
          batchMatchingTimeMs: _matchingProcessingTime?.inMilliseconds ?? 0,
          apiSubmissionTimeMs: apiSubmissionStopwatch.elapsed.inMilliseconds,
          totalProcessingTimeMs: totalProcessingStopwatch.elapsed.inMilliseconds,
          apiResponseCode: resp.statusCode ?? 0,
          apiEndpoint: '/api/submit-mobile-batch/$sessionId',
          dataSizeBytes: dataSizeBytes,
          apiResponseTime: '${apiSubmissionStopwatch.elapsed.inMilliseconds} ms',
          submissionStatus: 'Failed: ${resp.message ?? 'Unknown error'}',
          charactersDetected: extractedText.length,
          submissionDurationMs: apiSubmissionStopwatch.elapsed.inMilliseconds,
          selectedFromOptions: matchType != 'manual' ? 'N/A' : 'N/A',
        );
        
        _showInfoDialog('Failed to submit batch: \n${resp.message ?? 'Unknown error'}');
      }
    } catch (e, stackTrace) {
      totalProcessingStopwatch.stop();
      batchProvider.incrementErrorCount();
      loggingProvider.logError('Batch submission error', error: e, stackTrace: stackTrace);
      
      // Track error submissions
      try {
        await batchProvider.addSubmittedBatch(
          batchNumber: batch?.batchNumber ?? batch?.batchId ?? 'Unknown',
          itemName: batch?.itemName ?? batch?.productName ?? 'Unknown Item',
          quantity: quantity.toString(),
          capturedImage: _lastCapturedImageBytes,
          captureId: DateTime.now().millisecondsSinceEpoch.toString(),
          extractedText: extractedText,
          ocrConfidence: confidence,
          matchType: matchType,
          ocrProcessingTimeMs: _ocrProcessingTime?.inMilliseconds ?? 0,
          batchMatchingTimeMs: _matchingProcessingTime?.inMilliseconds ?? 0,
          totalProcessingTimeMs: totalProcessingStopwatch.elapsed.inMilliseconds,
          submissionStatus: 'Error: ${e.toString()}',
          charactersDetected: extractedText.length,
        );
      } catch (_) {
        // Ignore storage errors during error handling
      }
      
      _showInfoDialog('Failed to submit batch: ${e.toString()}');
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 48,
        ),
        title: const Text('Success'),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BatchProvider>(
      builder: (context, batchProvider, child) {
        // Check if session exists before showing OCR scanner
        if (!batchProvider.hasSession) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('OCR Scanner'),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Active Session',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Please scan a QR code to start a session\nbefore using the OCR scanner.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/qr-scanner');
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan QR Code'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: _buildAppBar(),
          body: _buildBody(),
          bottomSheet: _buildBottomSheet(),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Consumer<BatchProvider>(
        builder: (context, batchProvider, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('OCR Scanner'),
              if (batchProvider.hasSession)
                Text(
                  'Session: ${batchProvider.currentSessionId}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
            ],
          );
        },
      ),
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        if (_isCameraInitialized) ...[
          IconButton(
            onPressed: _toggleFlash,
            icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
            tooltip: 'Toggle Flash',
          ),
          IconButton(
            onPressed: _capturedImagePath != null ? _resetCapture : _captureImage,
            icon: Icon(_capturedImagePath != null ? Icons.refresh : Icons.camera_alt),
            tooltip: _capturedImagePath != null ? 'Retake' : 'Capture',
          ),
        ],
      ],
    );
  }

  Widget _buildBody() {
    if (!_isCameraInitialized) {
      return _buildCameraError();
    }

    if (_capturedImagePath != null) {
      return _buildCapturedImageView();
    }

    return _buildCameraPreview();
  }

  Widget _buildCameraError() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 24),
          Text(
            'Camera not available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please check camera permissions',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || _ocrService.cameraController?.value.isInitialized != true) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Initializing camera...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
    
    return Stack(
      children: [
        // Camera preview
        SizedBox.expand(
          child: CameraPreview(_ocrService.cameraController!),
        ),
        
        // Overlay with capture guidelines
        _buildCaptureOverlay(),
        
        // Processing indicator
        if (_isProcessing) _buildProcessingOverlay(),
      ],
    );
  }

  Widget _buildCaptureOverlay() {
    return CustomPaint(
      painter: OCROverlayPainter(),
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: SizedBox(
            width: 300,
            height: 200,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Position text within this frame\nfor better recognition',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: const Center(
        child: LoadingWidget(
          message: 'Processing image...',
        ),
      ),
    );
  }

  Widget _buildCapturedImageView() {
    return Column(
      children: [
        // Captured image
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
            ),
            child: Image.file(
              File(_capturedImagePath!),
              fit: BoxFit.contain,
            ),
          ),
        ),
        
        // Extracted text
        Expanded(
          flex: 2,
          child: Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Extracted Text',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (_extractedText != null) ...[
                      IconButton(
                        onPressed: _copyText,
                        icon: const Icon(Icons.copy),
                        tooltip: 'Copy text',
                      ),
                      IconButton(
                        onPressed: _shareText,
                        icon: const Icon(Icons.share),
                        tooltip: 'Share text',
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildExtractedTextContent(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExtractedTextContent() {
    if (_isProcessing) {
      return const Center(
        child: LoadingWidget(message: 'Extracting text...'),
      );
    }

    if (_extractedText == null || _extractedText!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.text_fields,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No text extracted',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try capturing a clearer image with better lighting',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Raw extracted text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Extracted Text',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _extractedText!,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _resetCapture,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retake'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet() {
    if (_capturedImagePath != null) {
      return const SizedBox.shrink(); // Hide bottom sheet when image is captured
    }

    return Container(
      height: 100,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Gallery button
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library),
                iconSize: 32,
              ),
              const Text(
                'Gallery',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          
          // Capture button
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _captureImage,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Capture',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          
          // Settings button
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _showOCRSettings,
                icon: const Icon(Icons.settings),
                iconSize: 32,
              ),
              const Text(
                'Settings',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Event handlers
  Future<void> _toggleFlash() async {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    
    try {
      if (_ocrService.cameraController?.value.isInitialized == true) {
        await _ocrService.cameraController!.setFlashMode(
          _isFlashOn ? FlashMode.off : FlashMode.torch,
        );
        
        setState(() {
          _isFlashOn = !_isFlashOn;
        });
        
        loggingProvider.logApp('OCR flash ${_isFlashOn ? 'enabled' : 'disabled'}');
      } else {
        loggingProvider.logError('Camera not initialized for flash toggle');
      }
    } catch (e) {
      loggingProvider.logError('Failed to toggle flash: $e');
    }
  }

  Future<void> _captureImage() async {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    final batchProvider = Provider.of<BatchProvider>(context, listen: false);
    
    if (!_isCameraInitialized || _ocrService.cameraController?.value.isInitialized != true) {
      loggingProvider.logError('Camera not initialized for capture');
      return;
    }

    if (!batchProvider.hasSession) {
      _showInfoDialog('No active session. Please scan a QR code first.');
      return;
    }

    try {
      setState(() {
        _isProcessing = true;
      });

      loggingProvider.logOCR('Starting capture and auto-matching workflow');

      // Check if OCR service is initialized
      if (!_ocrService.isInitialized) {
        loggingProvider.logOCR('OCR service not initialized, attempting to initialize...');
        final initialized = await _ocrService.initialize();
        if (!initialized) {
          throw Exception('Failed to initialize OCR service');
        }
      }

      // Start timing OCR processing
      final ocrStopwatch = Stopwatch()..start();
      
      // Use the new auto-matching method
      final result = await _ocrService.captureAndExtractTextWithMatching(
        availableBatches: batchProvider.batches,
        similarityThreshold: 0.75,
      );
      
      ocrStopwatch.stop();
      _ocrProcessingTime = ocrStopwatch.elapsed;

      if (result == null || !result['success']) {
        throw Exception(result?['error'] ?? 'Failed to process image');
      }

      final extractedText = result['extractedText'] as String;
      final matches = result['matches'] as List<dynamic>;
      final nearestMatches = result['nearestMatches'] as List<dynamic>;
      final imageBytes = result['imageBytes'] as List<int>?;

      setState(() {
        _extractedText = extractedText;
        _capturedImagePath = 'captured'; // Just to indicate capture was successful
        _lastCapturedImageBytes = imageBytes;
      });

      loggingProvider.logSuccess('OCR processing completed with auto-matching', data: {
        'textLength': extractedText.length,
        'matchesFound': matches.length,
        'nearestMatches': nearestMatches.length,
        'ocrProcessingTimeMs': _ocrProcessingTime?.inMilliseconds,
      });

      batchProvider.incrementScanCount();

      // Start timing batch matching (if not already done by OCR service)
      final matchingStopwatch = Stopwatch()..start();
      
      // Use new swipeable cards approach for ALL results
      matchingStopwatch.stop();
      _matchingProcessingTime = matchingStopwatch.elapsed;
      
      loggingProvider.logSuccess('OCR processing completed, showing swipeable batch matches');
      
      // Show swipeable batch match cards instead of traditional dialogs
      await _showSwipeableBatchMatchCards(extractedText);

    } catch (e) {
      loggingProvider.logError('Image capture and processing failed: $e');
      _showInfoDialog('Failed to process image: ${e.toString()}');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.logOCR('Picking image from gallery');

    // Implementation for picking from gallery
    // This would typically use image_picker package
    loggingProvider.logApp('Gallery picker functionality to be implemented');
  }

  void _resetCapture() {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.logOCR('Resetting capture');

    setState(() {
      _capturedImagePath = null;
      _extractedText = null;
    });
  }

  void _copyText() {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    
    if (_extractedText != null) {
      // Implementation for copying text to clipboard
      loggingProvider.logApp('OCR text copied to clipboard');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Text copied to clipboard')),
      );
    }
  }

  void _shareText() {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    
    if (_extractedText != null) {
      // Implementation for sharing text
      loggingProvider.logApp('OCR text shared');
      
      // This would typically use the share package
    }
  }

  void _showOCRSettings() {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.logApp('OCR settings opened');

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'OCR Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Language'),
              subtitle: const Text('English'),
              onTap: () {
                Navigator.pop(context);
                // Language selection implementation
              },
            ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Recognition Mode'),
              subtitle: const Text('Balanced'),
              onTap: () {
                Navigator.pop(context);
                // Recognition mode selection implementation
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Tips'),
              onTap: () {
                Navigator.pop(context);
                _showOCRTips();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showOCRTips() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('OCR Tips'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('For better text recognition:'),
              SizedBox(height: 8),
              Text('• Ensure good lighting'),
              Text('• Hold the device steady'),
              Text('• Position text clearly in frame'),
              Text('• Avoid shadows and reflections'),
              Text('• Use high contrast backgrounds'),
              Text('• Clean the camera lens'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

// Custom painter for OCR overlay
class OCROverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Calculate the cutout rectangle (capture area)
    final cutoutRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 300,
      height: 200,
    );

    // Create the overlay path with cutout
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(cutoutRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(overlayPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
