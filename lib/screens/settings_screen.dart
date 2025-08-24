import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/logging_provider.dart';
import '../providers/batch_provider.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import 'log_viewer_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    _logScreenAccess();
  }

  void _logScreenAccess() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
      loggingProvider.logApp('Settings screen accessed');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Settings'),
      elevation: 0,
      actions: [
        IconButton(
          onPressed: _showAbout,
          icon: const Icon(Icons.info_outline),
          tooltip: 'About',
        ),
      ],
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Application Settings Section
        _buildSectionHeader('Application'),
        _buildAppSettingsSection(),
        
        const SizedBox(height: 24),
        
        // Scanning Settings Section
        _buildSectionHeader('Scanning'),
        _buildScanningSettingsSection(),
        
        const SizedBox(height: 24),
        
        // Logging Settings Section
        _buildSectionHeader('Logging & Debug'),
        _buildLoggingSettingsSection(),
        
        const SizedBox(height: 24),
        
        // Data Management Section
        _buildSectionHeader('Data Management'),
        _buildDataManagementSection(),
        
        const SizedBox(height: 24),
        
        // API Settings Section
        _buildSectionHeader('API Configuration'),
        _buildApiSettingsSection(),
        
        const SizedBox(height: 24),
        
        // Support Section
        _buildSectionHeader('Support'),
        _buildSupportSection(),
        
        const SizedBox(height: 32),
        
        // App Information
        _buildAppInfo(),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildAppSettingsSection() {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        return Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Use dark theme'),
                value: appState.isDarkMode,
                onChanged: (value) {
                  appState.setDarkMode(value);
                  _logSettingChange('Dark Mode', value);
                },
                secondary: const Icon(Icons.dark_mode),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Auto-refresh'),
                subtitle: const Text('Automatically refresh data'),
                value: appState.isAutoRefreshEnabled,
                onChanged: (value) {
                  appState.setAutoRefresh(value);
                  _logSettingChange('Auto-refresh', value);
                },
                secondary: const Icon(Icons.refresh),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Language'),
                subtitle: const Text('English'),
                leading: const Icon(Icons.language),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showLanguageSettings,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScanningSettingsSection() {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        return Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Auto-scan'),
                subtitle: const Text('Automatically scan detected QR codes'),
                value: appState.isAutoScanEnabled,
                onChanged: (value) {
                  appState.setAutoScan(value);
                  _logSettingChange('Auto-scan', value);
                },
                secondary: const Icon(Icons.qr_code_scanner),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Vibrate on scan'),
                subtitle: const Text('Vibrate when QR code is detected'),
                value: appState.isVibrateEnabled,
                onChanged: (value) {
                  appState.setVibrate(value);
                  _logSettingChange('Vibrate on scan', value);
                },
                secondary: const Icon(Icons.vibration),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Beep on scan'),
                subtitle: const Text('Play sound when QR code is detected'),
                value: appState.isBeepEnabled,
                onChanged: (value) {
                  appState.setBeep(value);
                  _logSettingChange('Beep on scan', value);
                },
                secondary: const Icon(Icons.volume_up),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('OCR Language'),
                subtitle: const Text('English'),
                leading: const Icon(Icons.text_fields),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showOCRLanguageSettings,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoggingSettingsSection() {
    return Consumer<LoggingProvider>(
      builder: (context, loggingProvider, child) {
        return Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Enable detailed logging'),
                subtitle: const Text('Log all API requests and responses'),
                value: loggingProvider.isDetailedLoggingEnabled,
                onChanged: (value) {
                  loggingProvider.setDetailedLogging(value);
                  _logSettingChange('Detailed logging', value);
                },
                secondary: const Icon(Icons.bug_report),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Auto-export logs'),
                subtitle: const Text('Automatically export logs daily'),
                value: loggingProvider.isAutoExportEnabled,
                onChanged: (value) {
                  loggingProvider.setAutoExport(value);
                  _logSettingChange('Auto-export logs', value);
                },
                secondary: const Icon(Icons.upload),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Log retention'),
                subtitle: Text('Keep logs for ${loggingProvider.logRetentionDays} days'),
                leading: const Icon(Icons.schedule),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showLogRetentionSettings,
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('View logs'),
                subtitle: Text('${loggingProvider.totalLogsCount} logs stored'),
                leading: const Icon(Icons.terminal),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _navigateToLogViewer,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDataManagementSection() {
    return Consumer<BatchProvider>(
      builder: (context, batchProvider, child) {
        return Card(
          child: Column(
            children: [
              ListTile(
                title: const Text('Export batch data'),
                subtitle: Text('${batchProvider.totalScannedBatches} batches stored'),
                leading: const Icon(Icons.download),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _exportBatchData,
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Import batch data'),
                subtitle: const Text('Import from CSV or JSON file'),
                leading: const Icon(Icons.upload),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _importBatchData,
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Clear all data'),
                subtitle: const Text('Remove all scanned batches and logs'),
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showClearDataConfirmation,
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Auto-backup'),
                subtitle: const Text('Automatically backup data'),
                value: batchProvider.isAutoBackupEnabled,
                onChanged: (value) {
                  batchProvider.setAutoBackup(value);
                  _logSettingChange('Auto-backup', value);
                },
                secondary: const Icon(Icons.backup),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildApiSettingsSection() {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        return Card(
          child: Column(
            children: [
              ListTile(
                title: const Text('API Endpoint'),
                subtitle: Text(appState.apiBaseUrl),
                leading: const Icon(Icons.api),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      appState.isApiHealthy ? Icons.check_circle : Icons.error,
                      color: appState.isApiHealthy ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
                onTap: _showApiSettings,
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Test connection'),
                subtitle: const Text('Check API health status'),
                leading: const Icon(Icons.network_check),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _testApiConnection,
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Request timeout'),
                subtitle: Text('${Constants.apiTimeout}ms'),
                leading: const Icon(Icons.timer),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showTimeoutSettings,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSupportSection() {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: const Text('Help & FAQ'),
            subtitle: const Text('Common questions and solutions'),
            leading: const Icon(Icons.help),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showHelp,
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Report issue'),
            subtitle: const Text('Send feedback or report a problem'),
            leading: const Icon(Icons.bug_report),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _reportIssue,
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Contact support'),
            subtitle: const Text('Get in touch with our team'),
            leading: const Icon(Icons.support),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _contactSupport,
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Rate app'),
            subtitle: const Text('Leave a review on the app store'),
            leading: const Icon(Icons.star),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _rateApp,
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Image.asset(
              'assets/logo/icon.png',
              width: 64,
              height: 64,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.medical_services,
                size: 64,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'BatchMate',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Version 1.0.0 (Build 1)',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Pharmaceutical batch scanning and management with comprehensive logging.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '© 2024 BatchMate. All rights reserved.',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Event handlers
  void _logSettingChange(String setting, dynamic value) {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.logApp('Setting changed: $setting', data: {
      'setting': setting,
      'newValue': value,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void _showLanguageSettings() {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.logApp('Language settings opened');

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select Language',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              title: const Text('English'),
              trailing: const Icon(Icons.check, color: Colors.green),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Spanish'),
              subtitle: const Text('Coming soon'),
              enabled: false,
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('French'),
              subtitle: const Text('Coming soon'),
              enabled: false,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showOCRLanguageSettings() {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.logApp('OCR language settings opened');

    // Implementation for OCR language selection
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('OCR Language'),
        content: const Text('OCR language settings will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogRetentionSettings() {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.logApp('Log retention settings opened');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Retention'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How long should logs be kept?'),
            const SizedBox(height: 16),
            ...['7 days', '30 days', '90 days', 'Forever'].map((option) =>
              RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: '${loggingProvider.logRetentionDays} days',
                onChanged: (value) {
                  // Update retention setting
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _navigateToLogViewer() {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.logApp('Navigate to log viewer from settings');

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LogViewerScreen()),
    );
  }

  void _exportBatchData() async {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    final batchProvider = Provider.of<BatchProvider>(context, listen: false);

    loggingProvider.logApp('Exporting batch data from settings');

    try {
      await batchProvider.exportBatchData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Batch data exported successfully')),
        );
      }
    } catch (e) {
      loggingProvider.logError('Failed to export batch data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  void _importBatchData() {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.logApp('Import batch data requested');

    // Implementation for importing batch data
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data'),
        content: const Text('Import functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showClearDataConfirmation() {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.logApp('Clear data confirmation requested');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete:\n'
          '• All scanned batches\n'
          '• All application logs\n'
          '• All user preferences\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _clearAllData() async {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    final batchProvider = Provider.of<BatchProvider>(context, listen: false);
    final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);

    loggingProvider.logApp('Clearing all application data');

    try {
      // Clear all data
      await batchProvider.clearAllBatches();
      loggingProvider.clearLogs();
      appStateProvider.resetSettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared successfully')),
        );
      }
    } catch (e) {
      loggingProvider.logError('Failed to clear data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Clear failed: $e')),
        );
      }
    }
  }

  void _showApiSettings() {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
    
    loggingProvider.logApp('API settings opened');

    final TextEditingController urlController = TextEditingController(
      text: appStateProvider.apiBaseUrl,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Configuration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'API Base URL:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                hintText: 'https://api.example.com/',
                prefixIcon: const Icon(Icons.link),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                helperText: 'Enter the base URL for API endpoints',
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  appStateProvider.isApiHealthy ? Icons.check_circle : Icons.error_outline,
                  color: appStateProvider.isApiHealthy ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  appStateProvider.isApiHealthy 
                      ? 'API is healthy' 
                      : 'API connection failed',
                  style: TextStyle(
                    color: appStateProvider.isApiHealthy ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await appStateProvider.resetApiBaseUrl();
                urlController.text = appStateProvider.apiBaseUrl;
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('API URL reset to default')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to reset: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Reset'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUrl = urlController.text.trim();
              if (newUrl.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('URL cannot be empty')),
                );
                return;
              }

              try {
                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const AlertDialog(
                    content: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Updating API URL...'),
                      ],
                    ),
                  ),
                );

                await appStateProvider.updateApiBaseUrl(newUrl);
                
                if (mounted) {
                  Navigator.pop(context); // Close loading
                  Navigator.pop(context); // Close settings dialog
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('API URL updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context); // Close loading
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update API URL: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _testApiConnection() async {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);

    loggingProvider.logNetwork('Testing API connection from settings');

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Testing connection...'),
          ],
        ),
      ),
    );

    try {
      // Test the connection
      await appStateProvider.checkApiHealth();
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: Icon(
              appStateProvider.isApiHealthy ? Icons.check_circle : Icons.error,
              color: appStateProvider.isApiHealthy ? Colors.green : Colors.red,
              size: 48,
            ),
            title: Text(appStateProvider.isApiHealthy ? 'Connection Success' : 'Connection Failed'),
            content: Text(
              appStateProvider.isApiHealthy 
                ? 'API is responding normally'
                : 'Unable to connect to the API server',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      loggingProvider.logError('API connection test failed: $e');
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.error, color: Colors.red, size: 48),
            title: const Text('Connection Error'),
            content: Text('Failed to test connection: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showTimeoutSettings() {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.logApp('Timeout settings opened');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Timeout'),
        content: const Text('Timeout configuration will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.logApp('Help section opened');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & FAQ'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Frequently Asked Questions',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Q: How do I scan a QR code?'),
              Text('A: Use the QR Scanner from the home screen.'),
              SizedBox(height: 8),
              Text('Q: How do I view application logs?'),
              Text('A: Go to Settings > Logging & Debug > View logs.'),
              SizedBox(height: 8),
              Text('Q: How do I export batch data?'),
              Text('A: Go to Settings > Data Management > Export batch data.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _reportIssue() {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.logApp('Issue reporting opened');

    // Implementation for issue reporting
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Issue'),
        content: const Text('Issue reporting functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _contactSupport() {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.logApp('Contact support opened');

    // Implementation for contacting support
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Text('Support contact information will be provided here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _rateApp() {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.logApp('Rate app requested');

    // Implementation for app rating
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate BatchMate'),
        content: const Text('Thank you for using BatchMate! Please rate us on the app store.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Open app store rating
            },
            child: const Text('Rate Now'),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.logApp('About dialog opened');

    showAboutDialog(
      context: context,
      applicationName: 'BatchMate',
      applicationVersion: '1.0.0',
      applicationIcon: Image.asset(
        'assets/logo/icon.png',
        width: 48,
        height: 48,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.medical_services,
          size: 48,
          color: AppColors.primary,
        ),
      ),
      children: [
        const Text(
          'BatchMate is a comprehensive pharmaceutical batch scanning and management application with detailed logging capabilities.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Features:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const Text('• QR Code Scanning'),
        const Text('• OCR Text Recognition'),
        const Text('• Comprehensive Logging'),
        const Text('• Batch Management'),
        const Text('• API Integration'),
      ],
    );
  }
}
