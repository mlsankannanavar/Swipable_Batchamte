import 'package:flutter/material.dart';

class AppColors {
  // Organization primary colors - Better visibility
  static const Color primary = Color(0xFF2196F3); // Blue primary (was white)
  static const Color primaryHover = Color(0xFF1976D2); // Darker blue hover
  static const Color secondary = Color(0xFF03DAC6); // Teal secondary
  
  // Status colors
  static const Color success = Color(0xFF10b981); // Green
  static const Color error = Color(0xFFef4444); // Red
  
  // Light theme colors
  static const Color backgroundLight = Color(0xFFf5f5f5); // Light gray background
  static const Color textColorLight = Color(0xFF212121); // Dark text
  static const Color textSecondaryLight = Color(0xFF757575); // Gray text
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color onSurfaceLight = Color(0xFF212121);
  static const Color cardBackgroundLight = Color(0xFFFFFFFF);
  
  // Dark theme colors
  static const Color backgroundDark = Color(0xFF121212); // Dark background
  static const Color textColorDark = Color(0xFFFFFFFF); // Light text
  static const Color textSecondaryDark = Color(0xFFB0BEC5); // Light gray text
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color onSurfaceDark = Color(0xFFFFFFFF);
  static const Color cardBackgroundDark = Color(0xFF2A2A2A);
  
  // Adaptive colors based on brightness
  static Color getBackgroundColor(bool isDark) => isDark ? backgroundDark : backgroundLight;
  static Color getTextColor(bool isDark) => isDark ? textColorDark : textColorLight;
  static Color getTextSecondaryColor(bool isDark) => isDark ? textSecondaryDark : textSecondaryLight;
  static Color getSurfaceColor(bool isDark) => isDark ? surfaceDark : surfaceLight;
  static Color getOnSurfaceColor(bool isDark) => isDark ? onSurfaceDark : onSurfaceLight;
  static Color getCardBackgroundColor(bool isDark) => isDark ? cardBackgroundDark : cardBackgroundLight;
  
  // Legacy colors for backward compatibility
  static const Color background = backgroundLight;
  static const Color textColor = textColorLight;
  static const Color textSecondary = textSecondaryLight;
  
  // Button colors - Better contrast
  static const Color buttonColor = Color(0xFF2196F3); // Blue buttons
  static const Color buttonHover = Color(0xFF1976D2); // Darker blue hover
  
  // Border
  static const Color borderColor = Color(0xFFe5e7eb); // Light border
  static const Color borderColorDark = Color(0xFF424242); // Dark border
  
  static Color getBorderColor(bool isDark) => isDark ? borderColorDark : borderColor;
  
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
  static const Color cardShadowDark = Color(0x3A000000);
  
  static Color getCardShadow(bool isDark) => isDark ? cardShadowDark : cardShadow;
  
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
  
  // Helper method to get theme-aware colors from context
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
  
  // Context-aware color getters
  static Color backgroundFor(BuildContext context) => getBackgroundColor(isDarkMode(context));
  static Color textFor(BuildContext context) => getTextColor(isDarkMode(context));
  static Color textSecondaryFor(BuildContext context) => getTextSecondaryColor(isDarkMode(context));
  static Color surfaceFor(BuildContext context) => getSurfaceColor(isDarkMode(context));
  static Color onSurfaceFor(BuildContext context) => getOnSurfaceColor(isDarkMode(context));
  static Color cardBackgroundFor(BuildContext context) => getCardBackgroundColor(isDarkMode(context));
  static Color borderFor(BuildContext context) => getBorderColor(isDarkMode(context));
  static Color cardShadowFor(BuildContext context) => getCardShadow(isDarkMode(context));
}
