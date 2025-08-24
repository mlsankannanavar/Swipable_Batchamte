import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/helpers.dart';
import '../utils/log_level.dart';
import 'logging_service.dart';

class QrScannerService extends ChangeNotifier {
  static final QrScannerService _instance = QrScannerService._internal();
  factory QrScannerService() => _instance;
  QrScannerService._internal();

  final LoggingService _logger = LoggingService();
  MobileScannerController? _controller;
  bool _isInitialized = false;
  bool _isScanning = false;
  String? _lastScannedCode;
  DateTime? _lastScanTime;
  String? _scannedData;

  // Getters
  MobileScannerController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  bool get isScanning => _isScanning;
  String? get lastScannedCode => _lastScannedCode;
  DateTime? get lastScanTime => _lastScanTime;
  String? get scannedData => _scannedData;

  // Initialize the QR scanner
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _logger.logQrScan('Initializing QR scanner');

      // Check camera permission
      final permissionStatus = await _checkCameraPermission();
      if (!permissionStatus) {
        _logger.logQrScan('Camera permission denied', success: false);
        return false;
      }

      // Initialize the controller
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        torchEnabled: false,
      );

      _isInitialized = true;
      _logger.logQrScan('QR scanner initialized successfully');
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      _logger.logError('Failed to initialize QR scanner',
          error: e, stackTrace: stackTrace, category: 'QR-SCAN');
      return false;
    }
  }

  // Start scanning
  Future<bool> startScanning() async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    try {
      await _controller?.start();
      _isScanning = true;
      _logger.logQrScan('QR scanning started');
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      _logger.logError('Failed to start QR scanning',
          error: e, stackTrace: stackTrace, category: 'QR-SCAN');
      return false;
    }
  }

  // Stop scanning
  Future<void> stopScanning() async {
    try {
      await _controller?.stop();
      _isScanning = false;
      _logger.logQrScan('QR scanning stopped');
      notifyListeners();
    } catch (e, stackTrace) {
      _logger.logError('Error stopping QR scanner',
          error: e, stackTrace: stackTrace, category: 'QR-SCAN');
    }
  }

  // Process scanned QR code
  void processScannedCode(BarcodeCapture capture) {
    try {
      final codes = capture.barcodes;
      if (codes.isEmpty) {
        _logger.logQrScan('No QR codes detected in capture', success: false);
        return;
      }

      final code = codes.first;
      final rawValue = code.rawValue;

      if (rawValue == null || rawValue.isEmpty) {
        _logger.logQrScan('Empty QR code detected', success: false);
        return;
      }

      // Prevent duplicate scans within a short time frame
      if (_isDuplicateScan(rawValue)) {
        _logger.logQrScan('Duplicate QR code scan ignored', 
            qrData: rawValue, success: false);
        return;
      }

      _lastScannedCode = rawValue;
      _lastScanTime = DateTime.now();

      _logger.logQrScan('QR code scanned successfully', 
          qrData: rawValue, success: true);

      // Validate the scanned code
      if (_isValidSessionId(rawValue)) {
        _logger.logQrScan('Valid session ID detected', 
            qrData: rawValue, success: true);
        
        // Return the scanned session ID so it can be used by calling code
        _scannedData = rawValue;
        notifyListeners();
      } else {
        _logger.logQrScan('Invalid session ID format', 
            qrData: rawValue, success: false);
      }
    } catch (e, stackTrace) {
      _logger.logError('Error processing scanned QR code',
          error: e, stackTrace: stackTrace, category: 'QR-SCAN');
    }
  }

  // Toggle flashlight
  Future<void> toggleFlashlight() async {
    try {
      if (_controller != null) {
        await _controller!.toggleTorch();
        final torchState = _controller!.torchEnabled;
        _logger.logQrScan('Flashlight ${torchState ? 'enabled' : 'disabled'}');
        notifyListeners();
      }
    } catch (e, stackTrace) {
      _logger.logError('Failed to toggle flashlight',
          error: e, stackTrace: stackTrace, category: 'QR-SCAN');
    }
  }

  // Switch camera
  Future<void> switchCamera() async {
    try {
      if (_controller != null) {
        await _controller!.switchCamera();
        _logger.logQrScan('Camera switched');
        notifyListeners();
      }
    } catch (e, stackTrace) {
      _logger.logError('Failed to switch camera',
          error: e, stackTrace: stackTrace, category: 'QR-SCAN');
    }
  }

  // Get camera permission
  Future<bool> _checkCameraPermission() async {
    try {
      PermissionStatus status = await Permission.camera.status;
      
      _logger.logQrScan('Camera permission status: ${status.name}');

      if (status == PermissionStatus.denied) {
        status = await Permission.camera.request();
        _logger.logQrScan('Camera permission requested: ${status.name}');
      }

      if (status == PermissionStatus.permanentlyDenied) {
        _logger.logQrScan('Camera permission permanently denied',
            success: false);
        return false;
      }

      final granted = status == PermissionStatus.granted;
      _logger.logQrScan('Camera permission ${granted ? 'granted' : 'denied'}',
          success: granted);
      
      return granted;
    } catch (e, stackTrace) {
      _logger.logError('Error checking camera permission',
          error: e, stackTrace: stackTrace, category: 'QR-SCAN');
      return false;
    }
  }

  // Check if this is a duplicate scan
  bool _isDuplicateScan(String code) {
    if (_lastScannedCode == null || _lastScanTime == null) {
      return false;
    }

    final timeDifference = DateTime.now().difference(_lastScanTime!);
    return _lastScannedCode == code && timeDifference.inSeconds < 2;
  }

  // Validate session ID format
  bool _isValidSessionId(String sessionId) {
    return Helpers.isValidSessionId(sessionId);
  }

  // Reset scanner state
  void reset() {
    _lastScannedCode = null;
    _lastScanTime = null;
    _logger.logQrScan('QR scanner state reset');
    notifyListeners();
  }

  // Get scanner status info
  Map<String, dynamic> getStatusInfo() {
    return {
      'isInitialized': _isInitialized,
      'isScanning': _isScanning,
      'lastScannedCode': _lastScannedCode,
      'lastScanTime': _lastScanTime?.toIso8601String(),
      'torchEnabled': _controller?.torchEnabled ?? false,
      'cameraFacing': _controller?.facing.name ?? 'unknown',
    };
  }

  // Validate QR code content
  bool validateQrContent(String content) {
    if (content.isEmpty) {
      _logger.logQrScan('QR code validation failed: empty content',
          success: false);
      return false;
    }

    // Add specific validation logic here based on your requirements
    // For now, we'll just check if it's a valid session ID
    final isValid = _isValidSessionId(content);
    
    _logger.logQrScan('QR code validation ${isValid ? 'passed' : 'failed'}',
        qrData: content, success: isValid);

    return isValid;
  }

  // Error handling for scanner errors
  void handleScannerError(Object error, StackTrace? stackTrace) {
    _logger.logError('QR scanner error occurred',
        error: error, stackTrace: stackTrace, category: 'QR-SCAN');
    
    _isScanning = false;
    notifyListeners();
  }

  // Performance monitoring
  void logScanPerformance(Duration scanDuration) {
    _logger.logApp('QR scan performance',
        level: LogLevel.info,
        data: {
          'scanDuration': scanDuration.inMilliseconds,
          'scanDurationFormatted': Helpers.formatDuration(scanDuration),
        });
  }

  // Dispose resources
  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    _isScanning = false;
    _logger.logQrScan('QR scanner disposed');
    super.dispose();
  }

  // Get available cameras
  Future<List<CameraFacing>> getAvailableCameras() async {
    try {
      // This is a simplified implementation
      // In a real app, you might want to check actual camera availability
      return [CameraFacing.back, CameraFacing.front];
    } catch (e, stackTrace) {
      _logger.logError('Failed to get available cameras',
          error: e, stackTrace: stackTrace, category: 'QR-SCAN');
      return [CameraFacing.back];
    }
  }

  // Check if flashlight is available
  Future<bool> isFlashlightAvailable() async {
    try {
      // This would typically check device capabilities
      // For now, we'll assume it's available on most devices
      return true;
    } catch (e) {
      _logger.logQrScan('Failed to check flashlight availability',
          success: false);
      return false;
    }
  }
}
