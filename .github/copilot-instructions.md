# Copilot Instructions for BatchMate Mobile App

## Project Overview
BatchMate is a Flutter mobile app for pharmaceutical batch scanning, OCR, fuzzy batch matching, expiry validation, and API submission. The app is architected for reliability, real-time updates, and robust logging.

## Architecture & Key Components
- **lib/main.dart**: App entry, provider setup, Hive initialization.
- **lib/services/**: Core business logic (API, QR, OCR, logging).
- **lib/providers/**: State management (BatchProvider, LoggingProvider, AppStateProvider).
- **lib/models/**: Data models for batches, logs, API responses.
- **lib/widgets/**: UI components (batch cards, log buttons, status widgets).
- **lib/screens/**: App screens (home, scanner, batch list, log viewer).

## Critical Workflows
- **QR Scan → Session Init**: Scan QR, extract sessionId, call `GET /api/filtered-batches/{sessionId}`, cache batches locally.
- **OCR & Matching**: Use ML Kit to extract text, run fuzzy batch matching (Levenshtein + sliding window), validate expiry using generated date formats.
- **Result Submission**: POST results to `/api/submit-mobile-batch/{sessionId}` with batch, quantity, confidence, and extracted text.
- **Logging**: All major actions are logged with category/level via `LoggingService`.

## Patterns & Conventions
- **State**: All UI stats (dashboard/log counts) are dynamic via providers—no hardcoded counts.
- **Local Storage**: Batches are cached with all possible expiry date formats for robust matching.
- **Matching**: Use similarity threshold (≥75%) and expiry validation for match decisions. See `findBestBatchMatch` logic.
- **Error Handling**: All API/OCR/network errors are logged and surfaced in the UI.
- **UI Flows**: Three main match scenarios—Exact Match, Multiple Matches, No Match—drive user prompts and actions.

## Build, Test, Debug
- **Build**: `flutter build apk` (Android), `flutter build ios` (iOS)
- **Analyze**: `flutter analyze` (static analysis)
- **Run**: `flutter run` (device/emulator)
- **CI/CD**: GitHub Actions workflow in `.github/workflows/build-apk.yml` builds and releases APK.

## Integration Points
- **ML Kit**: Used for OCR in `lib/services/ocr_service.dart` (Android integration via Kotlin if needed).
- **API**: All endpoints and payloads are documented in README and code comments.
- **Provider**: State flows from providers to widgets/screens; always use provider values for UI state.

## Examples
- **QR Scan**: See `QrScannerService.processScannedCode` for sessionId extraction and API call.
- **Batch Matching**: See matching logic in `lib/services/ocr_service.dart` and `lib/providers/batch_provider.dart`.
- **Expiry Validation**: Date formats generated and checked for robust matching.
- **Result Submission**: See API POST logic in `lib/services/api_service.dart`.

## Project-Specific Advice
- Never hardcode dashboard/log counts—always use provider/state.
- When adding new batch fields, update expiry date format generation for matching.
- All logging should use `LoggingService` with proper category/level.
- For new API endpoints, document request/response formats in code comments and README.

## Key Files
- `lib/services/qr_scanner_service.dart`: QR scan/session logic
- `lib/services/ocr_service.dart`: OCR and matching
- `lib/services/api_service.dart`: API integration
- `lib/providers/batch_provider.dart`: Batch state and matching
- `lib/widgets/log_button_widget.dart`: Dynamic log count UI

---

If any section is unclear or missing, please provide feedback for iterative improvement.
