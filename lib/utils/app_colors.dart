import 'package:flutter/material.dart';

class AppColors {
  // Professional Dark Theme - Corporate Colors
  static const Color primary = Color(0xFF6B7280); // Professional grey
  static const Color primaryHover = Color(0xFF4B5563); // Darker grey hover
  static const Color secondary = Color(0xFF10B981); // Professional green accent
  
  // Accent colors for actions and highlights
  static const Color accent = Color(0xFF3B82F6); // Professional blue
  static const Color accentSecondary = Color(0xFF8B5CF6); // Professional purple
  
  // Status colors - Professional palette
  static const Color success = Color(0xFF10B981); // Professional green
  static const Color error = Color(0xFFEF4444); // Professional red
  static const Color warning = Color(0xFFF59E0B); // Professional amber
  static const Color info = Color(0xFF3B82F6); // Professional blue
  
  // Light theme colors (Professional light mode)
  static const Color backgroundLight = Color(0xFFF8FAFC); // Very light grey
  static const Color textColorLight = Color(0xFF000000); // Black text for maximum visibility
  static const Color textSecondaryLight = Color(0xDE000000); // Black87 for secondary text visibility
  static const Color surfaceLight = Color(0xFFFFFFFF); // Pure white
  static const Color onSurfaceLight = Color(0xFF000000); // Black text on white surface
  static const Color cardBackgroundLight = Color(0xFFFFFFFF); // Pure white
  
  // Dark theme colors (Professional dark mode - default)
  static const Color backgroundDark = Color(0xFF0F172A); // Deep slate background
  static const Color textColorDark = Color(0xFFFFFFFF); // Pure white text for dark theme
  static const Color textSecondaryDark = Color(0xFFFFFFFF); // White secondary text for dark theme
  static const Color surfaceDark = Color(0xFF1E293B); // Dark slate surface
  static const Color onSurfaceDark = Color(0xFFF1F5F9); // Light slate
  static const Color cardBackgroundDark = Color(0xFF334155); // Slate card background
  
  // Additional professional greys
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);
  
  // Adaptive colors based on brightness
  static Color getBackgroundColor(bool isDark) => isDark ? backgroundDark : backgroundLight;
  static Color getTextColor(bool isDark) => isDark ? textColorDark : textColorLight;
  static Color getTextSecondaryColor(bool isDark) => isDark ? textSecondaryDark : textSecondaryLight;
  static Color getSurfaceColor(bool isDark) => isDark ? surfaceDark : surfaceLight;
  static Color getOnSurfaceColor(bool isDark) => isDark ? onSurfaceDark : onSurfaceLight;
  static Color getCardBackgroundColor(bool isDark) => isDark ? cardBackgroundDark : cardBackgroundLight;
  
  // Legacy colors for backward compatibility
  static const Color background = backgroundLight; // Default to light theme for better visibility
  static const Color textColor = textColorLight; // Default to black text
  static const Color textSecondary = textSecondaryLight; // Default to black87 secondary text
  
  // Button colors - Professional theme
  static const Color buttonColor = Color(0xFF3B82F6); // Professional blue buttons
  static const Color buttonHover = Color(0xFF2563EB); // Darker blue hover
  static const Color buttonSecondary = Color(0xFF6B7280); // Grey secondary buttons
  static const Color buttonSecondaryHover = Color(0xFF4B5563); // Darker grey hover
  
  // Border colors - Professional theme
  static const Color borderColor = Color(0xFFE5E7EB); // Light border
  static const Color borderColorDark = Color(0xFF475569); // Professional dark border
  
  static Color getBorderColor(bool isDark) => isDark ? borderColorDark : borderColor;
  
  // Legacy colors for compatibility - Updated to professional theme
  static const Color primaryLight = Color(0xFF94A3B8); // Light slate
  static const Color primaryDark = Color(0xFF1E293B); // Dark slate
  
  // Log level colors - Professional theme
  static const Color logInfo = Color(0xFF3B82F6); // Professional blue
  static const Color logSuccess = Color(0xFF10B981); // Professional green
  static const Color logWarning = Color(0xFFF59E0B); // Professional amber
  static const Color logError = Color(0xFFEF4444); // Professional red
  static const Color logDebug = Color(0xFF8B5CF6); // Professional purple
  
  // Surface colors - Professional theme
  static const Color surface = Color(0xFF1E293B); // Dark slate surface
  static const Color onSurface = Color(0xFF000000); // Black text on light surfaces
  static const Color onSurfaceVariant = Color(0x8A000000); // Black54 for variant text
  
  // Status colors - Professional theme
  static const Color connected = Color(0xFF10B981); // Professional green
  static const Color disconnected = Color(0xFFEF4444); // Professional red
  static const Color connecting = Color(0xFFF59E0B); // Professional amber
  
  // Card colors - Professional theme
  static const Color cardBackground = Color(0xFF334155); // Slate card background
  static const Color cardShadow = Color(0x40000000); // Darker shadow for professional look
  static const Color cardShadowDark = Color(0x60000000); // Even darker shadow for dark theme
  
  static Color getCardShadow(bool isDark) => isDark ? cardShadowDark : cardShadow;
  
  // Button text - Professional theme
  static const Color buttonText = Color(0xFFF1F5F9); // Light slate text on buttons
  static const Color buttonDisabled = Color(0xFF64748B); // Medium slate for disabled
  
  // Text colors - Professional theme
  static const Color textPrimary = Color(0xFF000000); // Black primary text for visibility
  static const Color textHint = Color(0x61000000); // Black38 for hint text (lighter but still visible)
  
  // Border colors - Professional theme
  static const Color border = Color(0xFF475569); // Slate border
  static const Color borderFocused = Color(0xFF3B82F6); // Professional blue focus
  
  // Scanner colors - Professional theme
  static const Color scannerFrame = Color(0xFF10B981); // Professional green frame
  static const Color scannerOverlay = Color(0x80000000); // Dark overlay
  
  // Log button colors - Professional theme
  static const Color logButtonBackground = Color(0xE6334155); // Slate with opacity
  static const Color logButtonIcon = Color(0xFFF1F5F9); // Light slate icon
  static const Color logButtonBadge = Color(0xFFEF4444); // Professional red badge
  
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
