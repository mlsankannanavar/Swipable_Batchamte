import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'logging_service.dart';

class OCRService {
  static final LoggingService _logger = LoggingService();
  late TextRecognizer _textRecognizer;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    try {
      _textRecognizer = TextRecognizer();
      _isInitialized = true;
      _logger.logApp('OCR Service initialized successfully');
    } catch (e) {
      _logger.logError('Failed to initialize OCR Service', error: e);
      rethrow;
    }
  }

  Future<String?> processImage(String imagePath) async {
    if (!_isInitialized) {
      throw Exception('OCR Service not initialized');
    }

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      _logger.logApp('OCR processing completed: ${recognizedText.text.length} characters extracted');
      return recognizedText.text;
    } catch (e) {
      _logger.logError('OCR processing failed', error: e);
      return null;
    }
  }

  Future<List<String>> processImageLines(String imagePath) async {
    if (!_isInitialized) {
      throw Exception('OCR Service not initialized');
    }

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      final lines = recognizedText.blocks
        .expand((block) => block.lines)
        .map((line) => line.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
      
      _logger.logApp('OCR processing completed: ${lines.length} lines extracted');
      return lines;
    } catch (e) {
      _logger.logError('OCR line processing failed', error: e);
      return [];
    }
  }

  Future<String?> extractTextFromImage(String imagePath) async {
    return await processImage(imagePath);
  }

  void dispose() {
    if (_isInitialized) {
      _textRecognizer.close();
      _isInitialized = false;
      _logger.logApp('OCR Service disposed');
    }
  }
}
