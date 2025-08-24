import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/logging_provider.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/log_level.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _animationController.forward();
  }

  Future<void> _initializeApp() async {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);

    // Log app startup
    loggingProvider.logApp('Application starting up', level: LogLevel.info);

    // Wait for minimum splash duration
    await Future.delayed(Constants.splashDuration);

    // Wait for app initialization
    while (!appStateProvider.isInitialized) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    loggingProvider.logApp('Application startup completed', level: LogLevel.success);

    // Navigate to home screen
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Consumer2<AppStateProvider, LoggingProvider>(
        builder: (context, appState, logging, child) {
          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // App Logo
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Image.asset(
                                      'assets/logo/icon.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.medical_services,
                                          size: 60,
                                          color: AppColors.primary,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 32),
                                
                                // App Name
                                const Text(
                                  'Medha AI - Batchmate',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textColor,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                
                                const SizedBox(height: 8),
                                
                                // App Subtitle
                                const Text(
                                  'Pharmaceutical Batch Management',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                // Loading and Status Indicators
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      // Loading Indicator
                      const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 3,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Status Text
                      Text(
                        _getStatusText(appState.appStatus),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Connection Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getConnectionIcon(appState.connectionStatus),
                            color: _getConnectionColor(appState.connectionStatus),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getConnectionText(appState.connectionStatus),
                            style: TextStyle(
                              color: _getConnectionColor(appState.connectionStatus),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Version Info
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    'Version ${Constants.appVersion}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getStatusText(AppStatus status) {
    switch (status) {
      case AppStatus.initializing:
        return 'Initializing application...';
      case AppStatus.ready:
        return 'Ready to launch';
      case AppStatus.error:
        return 'Initialization failed';
    }
  }

  IconData _getConnectionIcon(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return Icons.cloud_done;
      case ConnectionStatus.disconnected:
        return Icons.cloud_off;
      case ConnectionStatus.checking:
        return Icons.cloud_sync;
    }
  }

  Color _getConnectionColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return Colors.greenAccent;
      case ConnectionStatus.disconnected:
        return Colors.redAccent;
      case ConnectionStatus.checking:
        return Colors.orangeAccent;
    }
  }

  String _getConnectionText(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return 'Server Connected';
      case ConnectionStatus.disconnected:
        return 'Server Disconnected';
      case ConnectionStatus.checking:
        return 'Checking Connection';
    }
  }
}
