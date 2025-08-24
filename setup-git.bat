@echo off
title BatchMate - Git Setup and Push Script
color 0A

echo.
echo ========================================
echo 🚀 BatchMate - Setting up Git Repository
echo ========================================
echo.

REM Check if git is installed
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Git is not installed. Please install Git first.
    pause
    exit /b 1
)
echo ✅ Git is installed

REM Initialize git repository if not already initialized
if not exist ".git" (
    echo 📁 Initializing Git repository...
    git init
    echo ✅ Git repository initialized
) else (
    echo ✅ Git repository already exists
)

REM Add remote origin
echo 🌐 Adding remote origin...
git remote remove origin >nul 2>&1
git remote add origin https://github.com/mlsankannanavar/myapp.git
echo ✅ Remote origin added

REM Create and checkout main branch
echo 🌿 Setting up main branch...
git checkout -b main >nul 2>&1
echo ✅ Main branch ready

REM Add all files
echo 📝 Adding all files to git...
git add .
echo ✅ Files added to staging area

REM Show git status
echo.
echo 📊 Git status:
git status --short

REM Commit the files
echo.
echo 💾 Committing files...
git commit -m "feat: Initial commit - BatchMate Flutter app with comprehensive logging"
echo ✅ Files committed successfully

REM Push to GitHub
echo.
echo 🚀 Pushing to GitHub...
echo Note: You may need to authenticate with GitHub
git push -u origin main

if %errorlevel% equ 0 (
    echo.
    echo ✅ Successfully pushed to GitHub!
    echo.
    echo 🎉 Repository setup complete!
    echo 📱 Your BatchMate app is now on GitHub: https://github.com/mlsankannanavar/myapp
    echo.
    echo 🔄 GitHub Actions will automatically:
    echo    • Build debug and release APKs
    echo    • Run tests and code analysis  
    echo    • Create releases with downloadable APKs
    echo    • Upload artifacts for easy download
    echo.
    echo 📥 To download APKs:
    echo    1. Go to: https://github.com/mlsankannanavar/myapp/actions
    echo    2. Click on the latest workflow run
    echo    3. Download artifacts or check releases
    echo.
    echo 📋 Next Steps:
    echo 1. 🌐 Visit: https://github.com/mlsankannanavar/myapp  
    echo 2. 🔄 Check Actions tab for build progress
    echo 3. 📱 Download APK from Releases or Actions artifacts
    echo 4. ⚙️ Configure API endpoint in lib/utils/constants.dart if needed
    echo.
    echo 🎯 Happy coding! Your BatchMate app is ready for production!
) else (
    echo.
    echo ❌ Push failed. Please check your GitHub credentials.
    echo 💡 Try running: git push -u origin main
    echo 💡 Make sure you have access to the repository
)

echo.
pause
