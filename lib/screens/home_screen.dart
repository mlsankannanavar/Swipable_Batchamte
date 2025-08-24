import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/batch_provider.dart';
import '../providers/logging_provider.dart';
import '../services/api_service.dart';
import '../widgets/connection_status_widget.dart';
import '../widgets/batch_card_widget.dart';
import '../widgets/loading_widget.dart';
import '../utils/app_colors.dart';
import 'qr_scanner_screen.dart';
import 'batch_list_screen.dart';
import 'ocr_scanner_screen.dart';
import 'settings_screen.dart';
import 'log_viewer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  void _initializeApp() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
      final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);

      // Log app initialization
      loggingProvider.logApp('Home screen initialized');

      // Initialize providers
      appStateProvider.initialize();
      // Note: Don't load batches until QR is scanned

      // Check API health
      _checkApiHealth();
    });
  }

  Future<void> _checkApiHealth() async {
    final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);

    try {
      loggingProvider.logNetwork('Checking API health');
      
      final apiService = ApiService();
      final healthResponse = await apiService.checkHealth();
      final isHealthy = healthResponse.isSuccess;
      
      appStateProvider.setApiHealthy(isHealthy);
      
      if (isHealthy) {
        loggingProvider.logSuccess('API health check passed');
      } else {
        loggingProvider.logWarning('API health check failed');
      }
    } catch (e) {
      loggingProvider.logError('API health check error: $e');
      appStateProvider.setApiHealthy(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _buildBody(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                'assets/logo/icon.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.medical_services, size: 24, color: AppColors.primary);
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Medha AI - Batchmate',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.buttonText,
      elevation: 0,
      actions: [
        Consumer<AppStateProvider>(
          builder: (context, appState, child) {
            return IconButton(
              onPressed: _refreshData,
              icon: appState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.refresh),
              tooltip: 'Refresh',
            );
          },
        ),
        IconButton(
          onPressed: () => _navigateToSettings(),
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
        ),
      ],
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Status
            const ConnectionStatusWidget(),
            
            const SizedBox(height: 24),
            
            // Quick Actions
            _buildQuickActions(),
            
            const SizedBox(height: 24),
            
            // Statistics Overview
            _buildStatisticsOverview(),
            
            const SizedBox(height: 24),
            
            // Recent Batches
            _buildRecentBatches(),
            
            const SizedBox(height: 24),
            
            // Recent Activity
            _buildRecentActivity(),
            
            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildActionCard(
              'QR Scanner',
              'Scan batch QR codes',
              Icons.qr_code_scanner,
              AppColors.primary,
              () => _navigateToQRScanner(),
            ),
            _buildActionCard(
              'OCR Scanner',
              'Extract text from images',
              Icons.text_fields,
              AppColors.secondary,
              () => _navigateToOCRScanner(),
            ),
            _buildActionCard(
              'Batch History',
              'View all scanned batches',
              Icons.history,
              Colors.green.shade600,
              () => _navigateToBatchList(),
            ),
            _buildActionCard(
              'View Logs',
              'Application logs & debug',
              Icons.terminal,
              Colors.orange.shade600,
              () => _navigateToLogViewer(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsOverview() {
    return Consumer2<BatchProvider, LoggingProvider>(
      builder: (context, batchProvider, loggingProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Scans',
                    batchProvider.totalScans.toString(),
                    Icons.qr_code_scanner,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Today\'s Logs',
                    loggingProvider.getTodaysLogCount().toString(),
                    Icons.today,
                    Colors.green.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Errors',
                    batchProvider.errorCount.toString(),
                    Icons.error_outline,
                    AppColors.logError,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Consumer<AppStateProvider>(
                    builder: (context, appState, child) {
                      return _buildStatCard(
                        'Submissions',
                        batchProvider.successfulSubmissions.toString(),
                        Icons.check_circle_outline,
                        Colors.green.shade600,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBatches() {
    return Consumer<BatchProvider>(
      builder: (context, batchProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Session Batches',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (batchProvider.hasSession)
                      Text(
                        'Session: ${batchProvider.currentSessionId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontFamily: 'monospace',
                        ),
                      ),
                  ],
                ),
                if (batchProvider.hasBatches)
                  TextButton(
                    onPressed: () => _navigateToBatchList(),
                    child: const Text('View All'),
                  )
                else
                  TextButton(
                    onPressed: () => _navigateToQRScanner(),
                    child: const Text('Scan QR'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (batchProvider.isLoading)
              const SizedBox(
                height: 120,
                child: LoadingWidget(
                  message: 'Loading batches...',
                ),
              )
            else if (!batchProvider.hasSession)
              _buildEmptyState(
                'No Active Session',
                'Scan a QR code to start a session and load batch information',
                Icons.qr_code_scanner,
                () => _navigateToQRScanner(),
                'Scan QR Code',
              )
            else if (!batchProvider.hasBatches)
              _buildEmptyState(
                'No Batches Available',
                'No batches found for this session.',
                Icons.inventory_outlined,
                null,
                null,
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: batchProvider.batches.length > 3 ? 3 : batchProvider.batches.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return BatchCardWidget(
                    batch: batchProvider.batches[index],
                    onTap: () => _onBatchTapped(batchProvider.batches[index]),
                    compact: true,
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildRecentActivity() {
    return Consumer<LoggingProvider>(
      builder: (context, loggingProvider, child) {
        final recentLogs = loggingProvider.getRecentLogs(60); // Last hour

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (recentLogs.isNotEmpty)
                  TextButton(
                    onPressed: () => _navigateToLogViewer(),
                    child: const Text('View Logs'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (recentLogs.isEmpty)
              _buildEmptyState(
                'No recent activity',
                'Activity logs will appear here',
                Icons.timeline,
                () => _navigateToLogViewer(),
                'View Logs',
              )
            else
              Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(8),
                  itemCount: recentLogs.length > 5 ? 5 : recentLogs.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final log = recentLogs[index];
                    return ListTile(
                      dense: true,
                      leading: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getLogLevelColor(log.level),
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(
                        log.message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        '${log.category} • ${log.formattedTimestamp}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      onTap: () => _navigateToLogViewer(),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? onAction,
    String? actionText,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            // Only show button if action and text are provided
            if (onAction != null && actionText != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: Icon(icon),
                label: Text(actionText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Navigation methods
  void _navigateToQRScanner() {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.logApp('Navigating to QR scanner');
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );
  }

  void _navigateToOCRScanner() {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.logApp('Navigating to OCR scanner');
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OCRScannerScreen()),
    );
  }

  void _navigateToBatchList() {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.logApp('Navigating to batch list');
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BatchListScreen()),
    );
  }

  void _navigateToSettings() {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.logApp('Navigating to settings');
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _navigateToLogViewer() {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.logApp('Navigating to log viewer');
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LogViewerScreen()),
    );
  }

  // Event handlers
  Future<void> _refreshData() async {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.logApp('Refreshing home screen data');

    await Future.wait([
      _checkApiHealth(),
      // Note: Don't auto-load batches, require QR scan
    ]);
  }

  void _onBatchTapped(batch) {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.logApp('Batch tapped from home screen', data: {'batchId': batch.id});
    
    // Navigate to batch details or show dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Batch ${batch.batchNumber}'),
        content: const Text('Batch details will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getLogLevelColor(level) {
    switch (level.toString()) {
      case 'LogLevel.info':
        return AppColors.logInfo;
      case 'LogLevel.success':
        return AppColors.logSuccess;
      case 'LogLevel.warning':
        return AppColors.logWarning;
      case 'LogLevel.error':
        return AppColors.logError;
      case 'LogLevel.debug':
        return AppColors.logDebug;
      default:
        return Colors.grey;
    }
  }
}
