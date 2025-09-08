import 'package:flutter/material.dart';

class AppColors {
  // Organization primary colors - Better visibility
  static const Color primary = Color(0xFF2196F3); // Blue primary (was white)
  static const Color primaryHover = Color(0xFF1976D2); // Darker blue hover
  static const Color secondary = Color(0xFF03DAC6); // Teal secondary
  
  // Status colors
  static const Color success = Color(0xFF10b981); // Green
  static const Color error = Color(0xFFef4444); // Red
  
  // Background and text
  static const Color background = Color(0xFFf5f5f5); // Light gray background
  static const Color textColor = Color(0xFF212121); // Dark text
  static const Color textSecondary = Color(0xFF757575); // Gray text
  
  // Button colors - Better contrast
  static const Color buttonColor = Color(0xFF2196F3); // Blue buttons
  static const Color buttonHover = Color(0xFF1976D2); // Darker blue hover
  
  // Border
  static const Color borderColor = Color(0xFFe5e7eb); // Light border
  
  // Legacy colors for compatibility
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color primaryDark = Color(0xFF0D47A1);
  
  // Log level colors
  static const Color logInfo = Color(0xFF2196F3);
  static const Color logSuccess = Color(0xFF10b981);
  static const Color logWarning = Color(0xFFFF9800);
  static const Color logError = Color(0xFFef4444);
  static const Color logDebug = Color(0xFF9C27B0);
  
  // Surface colors
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF212121);
  static const Color onSurfaceVariant = Color(0xFF757575);
  
  // Status colors
  static const Color connected = Color(0xFF10b981);
  static const Color disconnected = Color(0xFFef4444);
  static const Color connecting = Color(0xFFFF9800);
  
  // Card colors
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardShadow = Color(0x1A000000);
  
  // Button text
  static const Color buttonText = Color(0xFFFFFFFF); // White text on colored buttons
  static const Color buttonDisabled = Color(0xFFBDBDBD);
  
  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textHint = Color(0xFFBDBDBD);
  
  // Border colors
  static const Color border = Color(0xFFe5e7eb);
  static const Color borderFocused = Color(0xFF2196F3);
  
  // Scanner colors
  static const Color scannerFrame = Color(0xFF10b981);
  static const Color scannerOverlay = Color(0x80000000);
  
  // Log button colors
  static const Color logButtonBackground = Color(0xD9000000);
  static const Color logButtonIcon = Color(0xFFFFFFFF);
  static const Color logButtonBadge = Color(0xFFF44336);
}
