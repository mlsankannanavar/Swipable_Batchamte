# BatchMate - Pharmaceutical Batch Scanner

[![Build and Release APK](https://github.com/mlsankannanavar/myapp/actions/workflows/build-apk.yml/badge.svg)](https://github.com/mlsankannanavar/myapp/actions/workflows/build-apk.yml)

A comprehensive Flutter application for pharmaceutical batch scanning and management with extensive logging capabilities.

## 📱 Features

### Core Functionality
- **🔍 QR Code Scanning**: Real-time QR code detection and processing
- **📝 OCR Text Recognition**: Extract text from images using ML Kit
- **📊 Batch Management**: Comprehensive batch tracking and history
- **🔄 API Integration**: RESTful API with detailed logging
- **⚙️ Settings Management**: Extensive configuration options

### Comprehensive Logging System
- **📋 8 Log Categories**: API-OUT, API-IN, QR-SCAN, OCR, ERROR, NETWORK, APP, DATABASE
- **🎨 5 Log Levels**: Info, Success, Warning, Error, Debug (color-coded)
- **🔄 Real-time Updates**: Live log streaming with auto-scroll
- **🔍 Advanced Search**: Filter logs by level, category, and text search
- **📤 Export Functionality**: Export filtered logs in multiple formats
- **💾 Persistent Storage**: Hive database with configurable retention policies

## 🏗️ Architecture

### Clean Architecture Implementation
```
lib/
├── main.dart                 # Application entry point
├── utils/                    # Utilities and constants
│   ├── app_colors.dart      # Color scheme
│   ├── constants.dart       # App constants
│   ├── helpers.dart         # Helper functions
│   └── logger.dart          # Debug logger
├── models/                   # Data models
│   ├── log_entry_model.dart # Log entry structure
│   ├── batch_model.dart     # Batch data model
│   ├── health_response_model.dart
│   └── api_response_model.dart
├── services/                 # Business logic services
│   ├── logging_service.dart # Core logging functionality
│   ├── api_service.dart     # HTTP client with logging
│   ├── qr_scanner_service.dart
│   └── ocr_service.dart
├── providers/                # State management
│   ├── logging_provider.dart
│   ├── app_state_provider.dart
│   └── batch_provider.dart
├── widgets/                  # Reusable UI components
│   ├── log_button_widget.dart
│   ├── log_entry_widget.dart
│   ├── connection_status_widget.dart
│   ├── batch_card_widget.dart
│   ├── loading_widget.dart
│   └── error_widget.dart
└── screens/                  # Application screens
    ├── splash_screen.dart
    ├── home_screen.dart
    ├── qr_scanner_screen.dart
    ├── batch_list_screen.dart
    ├── ocr_scanner_screen.dart
    ├── settings_screen.dart
    └── log_viewer_screen.dart
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.24.0 or later)
- Dart SDK (3.5.0 or later)
- Android Studio / VS Code
- Android device or emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/mlsankannanavar/myapp.git
   cd myapp
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API settings**
   Update the API endpoint in `lib/utils/constants.dart`:
   ```dart
   static const String apiBaseUrl = 'https://your-api-endpoint.com';
   ```

4. **Run the application**
   ```bash
   flutter run
   ```

## 📦 Download APK

### Latest Release
Download the latest APK from the [Releases](https://github.com/mlsankannanavar/myapp/releases) page:

- **batchmate-release.apk**: Production ready APK for installation
- **batchmate-debug.apk**: Debug version for development
- **batchmate-release.aab**: App Bundle for Google Play Store

### Installation Instructions
1. Download the `batchmate-release.apk` file
2. On your Android device, go to Settings > Security
3. Enable "Install from unknown sources" or "Allow from this source"
4. Open the downloaded APK file and follow installation prompts

## 🔧 Configuration

### API Configuration
The app connects to a backend API for batch data processing. Configure the following in `lib/utils/constants.dart`:

```dart
class Constants {
  static const String apiBaseUrl = 'https://backend-batchmate.medha-analytics.ai/';
  static const int apiTimeout = 30000; // 30 seconds
  static const String appVersion = '1.0.0';
}
```

### Logging Configuration
Logging is configurable through the settings screen:
- **Log Levels**: Enable/disable specific log levels
- **Categories**: Filter by API, QR scanning, OCR, etc.
- **Retention**: Configure how long logs are kept
- **Export**: Automatic daily exports available

## 📊 Logging Details

### Log Categories
- **API-OUT**: Outgoing API requests with full payload
- **API-IN**: Incoming API responses with status codes
- **QR-SCAN**: QR code detection and processing
- **OCR**: Text recognition operations
- **ERROR**: Application errors with stack traces
- **NETWORK**: Network connectivity and health
- **APP**: General application events
- **DATABASE**: Local storage operations

### Log Levels
- **🔵 INFO**: General information
- **🟢 SUCCESS**: Successful operations
- **🟡 WARNING**: Warning conditions
- **🔴 ERROR**: Error conditions
- **🟣 DEBUG**: Debug information

## 🛠️ Development

### Building the APK

#### Local Build
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle for Play Store
flutter build appbundle --release
```

#### GitHub Actions
The repository includes GitHub Actions workflow that automatically:
- Builds debug and release APKs
- Runs tests and code analysis
- Creates releases with downloadable artifacts
- Uploads to GitHub Releases

### Testing
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run integration tests
flutter drive --target=test_driver/app.dart
```

### Code Quality
```bash
# Analyze code
flutter analyze

# Format code
flutter format .

# Check for outdated dependencies
flutter pub outdated
```

## 📱 Screenshots

| Home Screen | QR Scanner | Log Viewer | Settings |
|-------------|------------|------------|----------|
| Dashboard with quick actions | Real-time QR scanning | Comprehensive log management | Extensive configuration |

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- Create an issue in this repository
- Check the [Wiki](https://github.com/mlsankannanavar/myapp/wiki) for documentation
- Review the in-app help section

## 🔄 Changelog

### Version 1.0.0
- Initial release with comprehensive logging system
- QR code scanning functionality
- OCR text recognition
- Batch management system
- API integration with detailed logging
- Settings and configuration management

## 🏆 Acknowledgments

- Flutter team for the amazing framework
- Material Design team for design guidelines
- Contributors and testers

---

**Built with ❤️ using Flutter**
