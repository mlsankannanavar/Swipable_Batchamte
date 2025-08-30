import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/logging_provider.dart';
import '../providers/session_provider.dart';
import '../screens/qr_scanner_screen.dart';
import '../screens/ocr_scanner_screen.dart';
import '../screens/log_viewer_screen.dart';
import '../screens/settings_screen.dart';
import '../utils/app_colors.dart';
import '../widgets/connection_status_widget.dart';
import '../services/api_service.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({Key? key}) : super(key: key);

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  String? _selectedRackId;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _initializeApp() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);

      // Log app initialization
      loggingProvider.logApp('App initialized - Main Home Screen');
      
      // Check API health
      _checkApiHealth();
    });
  }

  Future<void> _checkApiHealth() async {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);

    try {
      loggingProvider.logNetwork('Checking API health');
      
      final apiService = ApiService();
      final healthResponse = await apiService.checkHealth();
      final isHealthy = healthResponse.isSuccess;
      
      if (isHealthy) {
        loggingProvider.logSuccess('API health check passed');
      } else {
        loggingProvider.logWarning('API health check failed');
      }
    } catch (e) {
      loggingProvider.logError('API health check error: $e');
    }
  }

  void _clearSession(SessionProvider sessionProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Session'),
          content: const Text('Are you sure you want to clear the current session? This will remove all session data and return to QR scanner.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                sessionProvider.clearSession();
                Navigator.of(context).pop();
                setState(() {
                  _tabController?.dispose();
                  _tabController = null;
                  _selectedRackId = null;
                });
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<AppStateProvider, LoggingProvider, SessionProvider>(
      builder: (context, appStateProvider, loggingProvider, sessionProvider, child) {
        final bool hasSession = sessionProvider.currentSession != null;
        
        // Initialize tab controller when session is first loaded
        if (hasSession && _tabController == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _tabController = TabController(length: 2, vsync: this);
            });
          });
        }
        
        return Scaffold(
          backgroundColor: AppColors.primary,
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: Text(
              'BatchMate',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            // Show tabs only when session is loaded
            bottom: hasSession 
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(48.0),
                  child: Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController ??= TabController(length: 2, vsync: this),
                      indicatorColor: AppColors.primary,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: Colors.grey,
                      tabs: const [
                        Tab(text: 'Available Items'),
                        Tab(text: 'Submitted Items'),
                      ],
                    ),
                  ),
                )
              : null,
            actions: [
              const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: ConnectionStatusWidget(),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: AppColors.primary),
                onSelected: (String value) {
                  switch (value) {
                    case 'settings':
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                      break;
                    case 'logs':
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const LogViewerScreen()));
                      break;
                    case 'clear_session':
                      if (hasSession) {
                        _clearSession(sessionProvider);
                      }
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'settings',
                    child: ListTile(
                      leading: Icon(Icons.settings),
                      title: Text('Settings'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'logs',
                    child: ListTile(
                      leading: Icon(Icons.receipt_long),
                      title: Text('View Logs'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  if (hasSession) ...[
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'clear_session',
                      child: ListTile(
                        leading: Icon(Icons.clear, color: Colors.red),
                        title: Text('Clear Session', style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          body: hasSession 
            ? TabBarView(
                controller: _tabController,
                children: [
                  _buildAvailableItemsScreen(sessionProvider),
                  _buildSubmittedItemsScreen(sessionProvider),
                ],
              )
            : _buildWelcomeScreen(sessionProvider),
        );
      },
    );
  }

  Widget _buildWelcomeScreen(SessionProvider sessionProvider) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App Logo/Icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.qr_code_scanner,
              size: 80,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Welcome Title
          const Text(
            'Welcome to BatchMate',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Subtitle
          const Text(
            'Scan a QR code to start managing your pharmaceutical batches',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Scan QR Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _navigateToQRScanner,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
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
          
          // Additional info
          const Text(
            'Make sure your QR code contains session information',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white60,
            ),
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

  Widget _buildAvailableItemsScreen(SessionProvider sessionProvider) {
    final session = sessionProvider.currentSession;
    if (session == null) return const Center(child: Text('No session data'));

    return Column(
      children: [
        // Improved Rack Dropdown
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRackId,
              hint: Row(
                children: [
                  Icon(Icons.inventory_2_outlined, 
                      color: Colors.grey.shade600, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Select Rack', 
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.primary,
                size: 24,
              ),
              items: session.racks.map((rack) {
                return DropdownMenuItem<String>(
                  value: rack.rackName,
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2, 
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            rack.rackName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${rack.items.length} items',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _selectedRackId = value;
                  });
                  sessionProvider.selectRack(value);
                }
              },
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              elevation: 8,
            ),
          ),
        ),
        
        // Available Items List
        Expanded(
          child: _selectedRackId == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select a rack to view items',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
            : _buildItemsList(sessionProvider, false),
        ),
      ],
    );
  }

  Widget _buildSubmittedItemsScreen(SessionProvider sessionProvider) {
    final session = sessionProvider.currentSession;
    if (session == null) return const Center(child: Text('No session data'));

    return Column(
      children: [
        // Rack Dropdown (same as Available Items)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRackId,
              hint: Row(
                children: [
                  Icon(Icons.inventory_2_outlined, 
                      color: Colors.grey.shade600, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Select Rack', 
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.primary,
                size: 24,
              ),
              items: session.racks.map((rack) {
                return DropdownMenuItem<String>(
                  value: rack.rackName,
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2, 
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            rack.rackName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${rack.items.length} items',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _selectedRackId = value;
                  });
                }
              },
            ),
          ),
        ),
        
        // Submitted Items List
        Expanded(
          child: _buildItemsList(sessionProvider, true),
        ),
      ],
    );
  }

  Widget _buildItemsList(SessionProvider sessionProvider, bool showSubmitted) {
    final session = sessionProvider.currentSession;
    if (session == null) return const Center(child: Text('No session data'));

    final selectedRack = _selectedRackId != null 
        ? session.racks.firstWhere((rack) => rack.rackName == _selectedRackId) 
        : null;

    // For both tabs, require a rack to be selected
    if (selectedRack == null) {
      return const Center(child: Text('Please select a rack to view items'));
    }

    List<dynamic> itemsToShow;
    if (showSubmitted) {
      // Show submitted items from selected rack only
      itemsToShow = selectedRack.items.where((item) => item.isSubmitted).toList();
    } else {
      // Show available items from selected rack
      itemsToShow = selectedRack.items.where((item) => !item.isSubmitted).toList();
    }

    if (itemsToShow.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              showSubmitted ? Icons.check_circle_outline : Icons.inventory_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(width: 16),
            Text(
              showSubmitted 
                ? 'No items submitted from ${selectedRack.rackName} yet' 
                : 'No available items in ${selectedRack.rackName}',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: itemsToShow.length,
      itemBuilder: (context, index) {
        final item = itemsToShow[index];
        return _buildItemCard(item, sessionProvider, showSubmitted);
      },
    );
  }

  Widget _buildItemCard(dynamic item, SessionProvider sessionProvider, bool isSubmitted) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: isSubmitted ? null : () => _openOCRScanner(item),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.itemName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Quantity: ${item.quantity}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          'Batches: ${item.batches.length}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (isSubmitted && item.selectedBatch != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Batch: ${item.selectedBatch}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isSubmitted) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Submitted',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openOCRScanner(dynamic item) {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.logApp('Opening OCR scanner for item: ${item.itemName}');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OCRScannerScreen(selectedItem: item),
      ),
    ).then((result) {
      if (result != null && result is Map<String, dynamic>) {
        final selectedBatch = result['selectedBatch'] as String?;
        if (selectedBatch != null) {
          // Mark item as submitted and move to submitted tab
          final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
          sessionProvider.submitItemWithBatch(item, selectedBatch);
          
          // Switch to submitted items tab
          _tabController?.animateTo(1);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.itemName} submitted successfully with batch $selectedBatch!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });
  }
}
