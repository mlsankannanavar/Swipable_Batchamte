import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/session_provider.dart';
import '../providers/logging_provider.dart';
import '../services/api_service.dart';
import '../widgets/connection_status_widget.dart';
import '../utils/app_colors.dart';
import 'qr_scanner_screen.dart';
import 'batch_history_screen.dart';
import 'settings_screen.dart';
import 'log_viewer_screen.dart';

class NewHomeScreen extends StatefulWidget {
  const NewHomeScreen({super.key});

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _initializeApp();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    setState(() {
      _selectedIndex = _tabController.index;
    });
  }

  void _initializeApp() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
      final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);

      // Log app initialization
      loggingProvider.logApp('New Home screen initialized');

      // Initialize providers
      appStateProvider.initialize();

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
      appBar: AppBar(
        title: const Text(
          'BatchMate',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          // Connection status
          const Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: ConnectionStatusWidget(),
          ),
          // Kebab menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuSelection,
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'logs',
                child: ListTile(
                  leading: Icon(Icons.receipt_long),
                  title: Text('View Logs'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'about',
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('About'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.qr_code_scanner),
              text: 'QR Scanner',
            ),
            Tab(
              icon: Icon(Icons.inventory),
              text: 'Batch History',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // QR Scanner Tab
          _buildQRScannerTab(),
          // Batch History Tab
          _buildBatchHistoryTab(),
        ],
      ),
      // Bottom edge logs button (alternative to kebab menu)
      floatingActionButton: _selectedIndex == 0 
          ? FloatingActionButton.small(
              onPressed: () => _navigateToLogs(),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              tooltip: 'View Logs',
              child: const Icon(Icons.receipt_long, size: 20),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildQRScannerTab() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          
          // QR Scanner Icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.qr_code_scanner,
              size: 80,
              color: AppColors.primary,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Title
          const Text(
            'Start New Session',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Description
          const Text(
            'Scan a QR code to start a new batch session and load rack information',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 48),
          
          // QR Scanner Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _navigateToQRScanner,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.qr_code_scanner, size: 24),
              label: const Text(
                'Scan QR Code',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Current session info (if any)
          Consumer<SessionProvider>(
            builder: (context, sessionProvider, child) {
              if (sessionProvider.hasSession) {
                return _buildCurrentSessionInfo(sessionProvider);
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBatchHistoryTab() {
    return Consumer<SessionProvider>(
      builder: (context, sessionProvider, child) {
        if (!sessionProvider.hasSession) {
          return _buildNoSessionState();
        }
        
        // Show the batch history screen content
        return const BatchHistoryScreen();
      },
    );
  }

  Widget _buildCurrentSessionInfo(SessionProvider sessionProvider) {
    final session = sessionProvider.currentSession!;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Active Session',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Store: ${session.storeId}',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
          Text(
            'Unit: ${session.unitCode}',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
          Text(
            'Racks: ${session.racks.length} | Items: ${session.totalItems}',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _tabController.animateTo(1); // Switch to Batch History tab
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('View Batch History'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSessionState() {
    return Container(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'No Active Session',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Scan a QR code to start a new session and view batch information',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              _tabController.animateTo(0); // Switch to QR Scanner tab
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan QR Code'),
          ),
        ],
      ),
    );
  }

  void _navigateToQRScanner() {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.logApp('Navigating to QR scanner');

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );
  }

  void _navigateToLogs() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LogViewerScreen()),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'logs':
        _navigateToLogs();
        break;
      case 'settings':
        _navigateToSettings();
        break;
      case 'about':
        _showAboutDialog();
        break;
    }
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'BatchMate',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2025 Medha Analytics',
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 16.0),
          child: Text(
            'A pharmaceutical batch tracking application with OCR and QR code scanning capabilities.',
          ),
        ),
      ],
    );
  }
}
