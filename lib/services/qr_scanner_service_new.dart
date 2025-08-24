import 'package:mobile_scanner/mobile_scanner.dart';
import 'logging_service.dart';

class QRScannerService {
  static final LoggingService _logger = LoggingService();
  late MobileScannerController _controller;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  MobileScannerController get controller => _controller;

  Future<void> initialize() async {
    try {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        torchEnabled: false,
      );
      _isInitialized = true;
      _logger.logApp('QR Scanner Service initialized successfully');
    } catch (e) {
      _logger.logError('Failed to initialize QR Scanner Service', error: e);
      rethrow;
    }
  }

  Future<void> start() async {
    if (!_isInitialized) {
      throw Exception('QR Scanner Service not initialized');
    }

    try {
      await _controller.start();
      _logger.logApp('QR Scanner started');
    } catch (e) {
      _logger.logError('Failed to start QR Scanner', error: e);
      rethrow;
    }
  }

  Future<void> stop() async {
    if (!_isInitialized) return;

    try {
      await _controller.stop();
      _logger.logApp('QR Scanner stopped');
    } catch (e) {
      _logger.logError('Failed to stop QR Scanner', error: e);
    }
  }

  Future<void> toggleTorch() async {
    if (!_isInitialized) return;

    try {
      await _controller.toggleTorch();
      _logger.logApp('QR Scanner torch toggled');
    } catch (e) {
      _logger.logError('Failed to toggle torch', error: e);
    }
  }

  Future<void> switchCamera() async {
    if (!_isInitialized) return;

    try {
      await _controller.switchCamera();
      _logger.logApp('QR Scanner camera switched');
    } catch (e) {
      _logger.logError('Failed to switch camera', error: e);
    }
  }

  bool validateQRContent(String content) {
    if (content.isEmpty) {
      _logger.logWarning('QR code validation failed: empty content');
      return false;
    }
    
    // Add your validation logic here
    return true;
  }

  String processQRCode(String content) {
    // Process and return the QR code content
    return content;
  }

  void dispose() {
    if (_isInitialized) {
      _controller.dispose();
      _isInitialized = false;
      _logger.logApp('QR Scanner Service disposed');
    }
  }
}
