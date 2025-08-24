import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/batch_provider.dart';
import '../providers/logging_provider.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../utils/app_colors.dart';
import 'home_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with SingleTickerProviderStateMixin {
  late MobileScannerController _scannerController;
  late AnimationController _animationController;
  late Animation<double> _scanLineAnimation;
  
  bool _isProcessing = false;
  bool _hasPermission = false;
  bool _isFlashOn = false;
  String? _lastScannedCode;
  DateTime? _lastScanTime;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
    _setupAnimations();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _initializeScanner() {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    
    // Request camera permission
    _requestCameraPermission();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scanLineAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat(reverse: true);
  }

  Future<void> _requestCameraPermission() async {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    
    try {
      loggingProvider.logApp('Requesting camera permission for QR scanner');
      
      // The mobile_scanner package handles permissions internally
      setState(() {
        _hasPermission = true;
      });
      
      loggingProvider.logSuccess('Camera permission granted');
    } catch (e) {
      loggingProvider.logError('Camera permission error: $e');
      setState(() {
        _hasPermission = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomSheet: _buildBottomSheet(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('QR Scanner'),
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: _toggleFlash,
          icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
          tooltip: 'Toggle Flash',
        ),
        IconButton(
          onPressed: _switchCamera,
          icon: const Icon(Icons.flip_camera_android),
          tooltip: 'Switch Camera',
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (!_hasPermission) {
      return _buildPermissionDenied();
    }

    return Stack(
      children: [
        // Camera Preview
        MobileScanner(
          controller: _scannerController,
          onDetect: _onQRCodeDetected,
          errorBuilder: (context, error, child) {
            return CustomErrorWidget(
              title: 'Scanner Error',
              message: 'Error: ${error.errorCode}',
              onRetry: _restartScanner,
            );
          },
        ),
        
        // Scanning Overlay
        _buildScanningOverlay(),
        
        // Processing Indicator
        if (_isProcessing) _buildProcessingOverlay(),
      ],
    );
  }

  Widget _buildScanningOverlay() {
    return CustomPaint(
      painter: QRScannerOverlayPainter(),
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: SizedBox(
            width: 250,
            height: 250,
            child: Stack(
              children: [
                // Corner brackets
                _buildCornerBrackets(),
                
                // Scanning line animation
                AnimatedBuilder(
                  animation: _scanLineAnimation,
                  builder: (context, child) {
                    return Positioned(
                      left: 0,
                      right: 0,
                      top: _scanLineAnimation.value * 220,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppColors.primary.withOpacity(0.8),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCornerBrackets() {
    return Stack(
      children: [
        // Top-left
        Positioned(
          top: 0,
          left: 0,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.primary, width: 3),
                left: BorderSide(color: AppColors.primary, width: 3),
              ),
            ),
          ),
        ),
        // Top-right
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.primary, width: 3),
                right: BorderSide(color: AppColors.primary, width: 3),
              ),
            ),
          ),
        ),
        // Bottom-left
        Positioned(
          bottom: 0,
          left: 0,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.primary, width: 3),
                left: BorderSide(color: AppColors.primary, width: 3),
              ),
            ),
          ),
        ),
        // Bottom-right
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.primary, width: 3),
                right: BorderSide(color: AppColors.primary, width: 3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: const Center(
        child: LoadingWidget(
          message: 'Processing QR code...',
        ),
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            const Text(
              'Camera Permission Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Please grant camera permission to scan QR codes',
              style: TextStyle(
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _requestCameraPermission,
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheet() {
    return Container(
      height: 120,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Position the QR code within the frame',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'The scanner will automatically detect and process QR codes',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Event handlers
  void _onQRCodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final qrCode = barcode.rawValue;

    if (qrCode == null || qrCode.isEmpty) return;

    // Check for duplicate scan within 3 seconds
    final now = DateTime.now();
    if (_lastScannedCode == qrCode && 
        _lastScanTime != null && 
        now.difference(_lastScanTime!).inSeconds < 3) {
      return;
    }

    _lastScannedCode = qrCode;
    _lastScanTime = now;

    setState(() {
      _isProcessing = true;
    });

    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    final batchProvider = Provider.of<BatchProvider>(context, listen: false);

    try {
      loggingProvider.logQRScan('QR code detected', qrData: qrCode);

      // Extract session ID from QR code (assuming QR contains session ID)
      String sessionId = qrCode.trim();
      
      // If QR code contains a URL, extract session ID from it
      if (qrCode.contains('sessionId=')) {
        final uri = Uri.tryParse(qrCode);
        if (uri != null) {
          sessionId = uri.queryParameters['sessionId'] ?? qrCode;
        }
      } else if (qrCode.contains('/')) {
        // If it's a path like /session/ABC123, extract the last part
        final parts = qrCode.split('/');
        sessionId = parts.last;
      }
      
      loggingProvider.logApp('Extracted session ID: $sessionId');
      
      // Load batches for this session
      await batchProvider.loadBatchesForSession(sessionId);
      
      loggingProvider.logSuccess('Session loaded successfully');
      
      // Show success dialog and navigate
      _showSuccessDialog(sessionId);
    } catch (e) {
      loggingProvider.logError('QR scan error: $e', stackTrace: StackTrace.current);
      batchProvider.incrementErrorCount();
      _showErrorDialog('Failed to process QR code: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _toggleFlash() async {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    
    try {
      await _scannerController.toggleTorch();
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
      
      loggingProvider.logApp('Flash ${_isFlashOn ? 'enabled' : 'disabled'}');
    } catch (e) {
      loggingProvider.logError('Failed to toggle flash: $e');
    }
  }

  void _switchCamera() async {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    
    try {
      await _scannerController.switchCamera();
      loggingProvider.logApp('Camera switched');
    } catch (e) {
      loggingProvider.logError('Failed to switch camera: $e');
    }
  }

  void _restartScanner() async {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    
    try {
      await _scannerController.start();
      loggingProvider.logApp('Scanner restarted');
    } catch (e) {
      loggingProvider.logError('Failed to restart scanner: $e');
    }
  }

  void _showSuccessDialog(String sessionId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Consumer<BatchProvider>(
        builder: (context, batchProvider, child) {
          return AlertDialog(
            icon: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 48,
            ),
            title: const Text('Session Started'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('QR code scanned successfully!'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session ID: $sessionId',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Batches loaded: ${batchProvider.batchCount}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  // Navigate to home screen and clear the entire navigation stack
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.buttonText,
                ),
                child: const Text('Continue to Home'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.error,
          color: Colors.red,
          size: 48,
        ),
        title: const Text('Scan Error'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Try Again'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to previous screen
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

// Custom painter for QR scanner overlay
class QRScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Calculate the cutout rectangle (scanning area)
    final cutoutRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 250,
      height: 250,
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
