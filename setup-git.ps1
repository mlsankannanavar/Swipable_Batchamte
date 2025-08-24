# BatchMate - Git Setup and Push Script
# Run this script in PowerShell from the project root directory

Write-Host "🚀 BatchMate - Setting up Git Repository" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

# Check if git is installed
try {
    git --version | Out-Null
    Write-Host "✅ Git is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ Git is not installed. Please install Git first." -ForegroundColor Red
    exit 1
}

# Initialize git repository if not already initialized
if (-not (Test-Path ".git")) {
    Write-Host "📁 Initializing Git repository..." -ForegroundColor Yellow
    git init
    Write-Host "✅ Git repository initialized" -ForegroundColor Green
} else {
    Write-Host "✅ Git repository already exists" -ForegroundColor Green
}

# Add remote origin
Write-Host "🌐 Adding remote origin..." -ForegroundColor Yellow
git remote remove origin 2>$null
git remote add origin https://github.com/mlsankannanavar/myapp.git
Write-Host "✅ Remote origin added" -ForegroundColor Green

# Create and checkout main branch
Write-Host "🌿 Setting up main branch..." -ForegroundColor Yellow
git checkout -b main 2>$null
Write-Host "✅ Main branch ready" -ForegroundColor Green

# Add all files
Write-Host "📝 Adding all files to git..." -ForegroundColor Yellow
git add .
Write-Host "✅ Files added to staging area" -ForegroundColor Green

# Check git status
Write-Host "📊 Git status:" -ForegroundColor Cyan
git status --short

# Commit the files
Write-Host "💾 Committing files..." -ForegroundColor Yellow
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
- 🚀 GitHub Actions for automated APK builds

📦 Project Structure:
- Complete Flutter app with pubspec.yaml
- Services: API, Logging, QR Scanner, OCR
- Providers: App State, Batch, Logging
- Widgets: Reusable UI components
- Screens: Splash, Home, QR Scanner, OCR Scanner, Batch List, Log Viewer, Settings
- Utils: Colors, Constants, Helpers, Logger

🔧 CI/CD:
- GitHub Actions workflow for APK builds
- Automated releases with artifacts
- Debug and release APK generation"

Write-Host "✅ Files committed successfully" -ForegroundColor Green

# Push to GitHub
Write-Host "🚀 Pushing to GitHub..." -ForegroundColor Yellow
Write-Host "Note: You may need to authenticate with GitHub" -ForegroundColor Cyan

try {
    git push -u origin main
    Write-Host "✅ Successfully pushed to GitHub!" -ForegroundColor Green
    Write-Host "" -ForegroundColor White
    Write-Host "🎉 Repository setup complete!" -ForegroundColor Green
    Write-Host "📱 Your BatchMate app is now on GitHub: https://github.com/mlsankannanavar/myapp" -ForegroundColor Cyan
    Write-Host "" -ForegroundColor White
    Write-Host "🔄 GitHub Actions will automatically:" -ForegroundColor Yellow
    Write-Host "   • Build debug and release APKs" -ForegroundColor White
    Write-Host "   • Run tests and code analysis" -ForegroundColor White
    Write-Host "   • Create releases with downloadable APKs" -ForegroundColor White
    Write-Host "   • Upload artifacts for easy download" -ForegroundColor White
    Write-Host "" -ForegroundColor White
    Write-Host "📥 To download APKs:" -ForegroundColor Green
    Write-Host "   1. Go to: https://github.com/mlsankannanavar/myapp/actions" -ForegroundColor White
    Write-Host "   2. Click on the latest workflow run" -ForegroundColor White
    Write-Host "   3. Download artifacts or check releases" -ForegroundColor White
    Write-Host "" -ForegroundColor White
} catch {
    Write-Host "❌ Push failed. Please check your GitHub credentials." -ForegroundColor Red
    Write-Host "💡 Try running: git push -u origin main" -ForegroundColor Yellow
    Write-Host "💡 Make sure you have access to the repository" -ForegroundColor Yellow
}

Write-Host "" -ForegroundColor White
Write-Host "📋 Next Steps:" -ForegroundColor Green
Write-Host "1. 🌐 Visit: https://github.com/mlsankannanavar/myapp" -ForegroundColor White
Write-Host "2. 🔄 Check Actions tab for build progress" -ForegroundColor White
Write-Host "3. 📱 Download APK from Releases or Actions artifacts" -ForegroundColor White
Write-Host "4. ⚙️ Configure API endpoint in lib/utils/constants.dart if needed" -ForegroundColor White
Write-Host "" -ForegroundColor White
Write-Host "🎯 Happy coding! Your BatchMate app is ready for production!" -ForegroundColor Green
