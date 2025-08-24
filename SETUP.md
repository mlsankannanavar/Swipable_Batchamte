# 🚀 BatchMate - GitHub Setup Guide

## Quick Setup (Automated)

### Option 1: PowerShell (Recommended)
```powershell
# Navigate to project directory
cd "c:\Users\358344\OneDrive - Narayana Health\Desktop\Innovation1\batchmate_app"

# Run the setup script
.\setup-git.ps1
```

### Option 2: Command Prompt
```cmd
# Navigate to project directory
cd "c:\Users\358344\OneDrive - Narayana Health\Desktop\Innovation1\batchmate_app"

# Run the setup script
setup-git.bat
```

## Manual Setup (Step by Step)

If you prefer to run commands manually:

### 1. Initialize Git Repository
```bash
cd "c:\Users\358344\OneDrive - Narayana Health\Desktop\Innovation1\batchmate_app"
git init
```

### 2. Add Remote Repository
```bash
git remote add origin https://github.com/mlsankannanavar/myapp.git
```

### 3. Create Main Branch
```bash
git checkout -b main
```

### 4. Add All Files
```bash
git add .
```

### 5. Commit Files
```bash
git commit -m "feat: Initial commit - BatchMate Flutter app with comprehensive logging

✨ Features:
- 🔍 QR Code scanning with mobile_scanner
- 📝 OCR text recognition with ML Kit  
- 📊 Comprehensive logging system (8 categories, 5 levels)
- 🔄 API integration with detailed request/response logging
- 📱 7 complete screens with Material Design 3
- ⚙️ Advanced settings and configuration
- 💾 Hive database for persistent storage
- 🎨 Real-time log viewer with search and export
- 🏗️ Clean architecture with Provider state management
- 🚀 GitHub Actions for automated APK builds"
```

### 6. Push to GitHub
```bash
git push -u origin main
```

## 📱 APK Build Process

Once pushed to GitHub, the automated workflow will:

### Automatic Actions
- ✅ **Build Debug APK**: For testing and development
- ✅ **Build Release APK**: Production-ready version
- ✅ **Build App Bundle**: For Google Play Store
- ✅ **Run Tests**: Automated testing
- ✅ **Code Analysis**: Flutter analyze
- ✅ **Create Release**: Automatic GitHub release with downloadable files

### Download Locations

#### Option 1: GitHub Actions Artifacts
1. Go to: https://github.com/mlsankannanavar/myapp/actions
2. Click on the latest workflow run
3. Scroll down to "Artifacts" section
4. Download:
   - `batchmate-debug-apk` - Debug version
   - `batchmate-release-apk` - Production version
   - `batchmate-app-bundle` - Play Store version

#### Option 2: GitHub Releases
1. Go to: https://github.com/mlsankannanavar/myapp/releases
2. Download the latest release files:
   - `batchmate-debug.apk`
   - `batchmate-release.apk`
   - `batchmate-release.aab`

## 📋 Build Status

Check build status with the badge:
[![Build and Release APK](https://github.com/mlsankannanavar/myapp/actions/workflows/build-apk.yml/badge.svg)](https://github.com/mlsankannanavar/myapp/actions/workflows/build-apk.yml)

## 🔧 Troubleshooting

### Authentication Issues
If you get authentication errors:

```bash
# Configure git credentials
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Use personal access token for authentication
# When prompted for password, use your GitHub Personal Access Token
```

### Permission Issues
If you don't have access to the repository:
1. Make sure you have write access to https://github.com/mlsankannanavar/myapp
2. Check if the repository exists
3. Verify your GitHub credentials

### Build Failures
If GitHub Actions build fails:
1. Check the Actions tab for error details
2. Common issues:
   - Missing dependencies in pubspec.yaml
   - Syntax errors in Dart code
   - Flutter version compatibility

## 🎯 What's Included

The complete BatchMate application includes:

### 📁 Project Structure
```
batchmate_app/
├── .github/workflows/build-apk.yml    # GitHub Actions workflow
├── lib/
│   ├── main.dart                      # App entry point
│   ├── utils/                         # App utilities
│   ├── models/                        # Data models
│   ├── services/                      # Business logic
│   ├── providers/                     # State management
│   ├── widgets/                       # UI components
│   └── screens/                       # App screens
├── pubspec.yaml                       # Dependencies
├── README.md                          # Documentation
├── .gitignore                         # Git ignore rules
├── setup-git.ps1                      # PowerShell setup
└── setup-git.bat                      # Batch setup
```

### 🔍 Features Included
- **QR Code Scanning**: Real-time scanning with camera
- **OCR Text Recognition**: Extract text from images
- **Comprehensive Logging**: 8 categories, 5 levels, real-time viewer
- **API Integration**: RESTful API with detailed logging
- **Batch Management**: Complete pharmaceutical batch tracking
- **Settings**: Extensive configuration options
- **Material Design 3**: Modern UI/UX
- **State Management**: Provider pattern
- **Local Storage**: Hive database
- **Export Functions**: Log and data export

### 🚀 Ready for Production
- Clean architecture
- Error handling
- Performance optimized
- Comprehensive testing
- Automated CI/CD
- Professional documentation

## 🎉 Success!

Once setup is complete, your BatchMate app will be:
- ✅ Hosted on GitHub: https://github.com/mlsankannanavar/myapp
- ✅ Automatically building APKs via GitHub Actions
- ✅ Ready for download and installation
- ✅ Production-ready with comprehensive logging

Happy coding! 🚀
