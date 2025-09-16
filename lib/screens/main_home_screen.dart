import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/batch_provider.dart';
import '../providers/logging_provider.dart';
import '../providers/session_provider.dart';
import '../screens/qr_scanner_screen.dart';
import '../screens/ocr_scanner_screen.dart';
import '../screens/log_viewer_screen.dart';
import '../screens/api_log_viewer_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/batch_submission_details_screen.dart';
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

  TabController _getTabController() {
    if (_tabController == null) {
      _tabController = TabController(length: 2, vsync: this);
      _tabController!.addListener(() {
        // Refresh UI when tab changes to ensure submitted items are updated
        if (mounted) {
          setState(() {});
        }
      });
    }
    return _tabController!;
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
          content: const Text('Are you sure you want to clear the current session? This will remove all session data, submitted batches, logs, and return to QR scanner.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Clear session, batch data, and logs completely
                final batchProvider = Provider.of<BatchProvider>(context, listen: false);
                final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
                
                await sessionProvider.clearSession();
                await batchProvider.clearSession();
                loggingProvider.clearLogs(); // Clear all logs when session is cleared
                
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
    return Consumer4<AppStateProvider, LoggingProvider, SessionProvider, BatchProvider>(
      builder: (context, appStateProvider, loggingProvider, sessionProvider, batchProvider, child) {
        final bool hasSession = sessionProvider.currentSession != null;
        
        // Sync session between providers when session is loaded
        if (hasSession && sessionProvider.currentSessionId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (batchProvider.currentSessionId != sessionProvider.currentSessionId) {
              await batchProvider.loadBatchesForSession(sessionProvider.currentSessionId!);
            }
          });
        }
        
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
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Row(
              children: [
                // App logo/icon on the left
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/logo/icon.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // BatchMate text
                Text(
                  'BatchMate',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Connection status with smaller font
                const ConnectionStatusWidget(fontSize: 10),
              ],
            ),
            titleSpacing: 16,
            // Show tabs only when session is loaded
            bottom: hasSession 
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(48.0),
                  child: Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: TabBar(
                      controller: _getTabController(),
                      indicatorColor: AppColors.primary,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                      tabs: const [
                        Tab(text: 'Available Items'),
                        Tab(text: 'Submitted Items'),
                      ],
                    ),
                  ),
                )
              : null,
            actions: [
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
                    case 'api_logs':
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ApiLogViewerScreen()));
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
                  const PopupMenuItem<String>(
                    value: 'api_logs',
                    child: ListTile(
                      leading: Icon(Icons.api),
                      title: Text('API Logs'),
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
                controller: _getTabController(),
                children: [
                  _buildAvailableItemsScreen(sessionProvider),
                  _buildSubmittedItemsScreen(sessionProvider, batchProvider),
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
              color: AppColors.primary,
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 8,
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
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    '📦 Select Rack', 
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
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
              items: (() {
                // Sort racks and convert to DropdownMenuItem
                final sortedRacks = session.racks.toList()
                  ..sort((a, b) => _compareLocators(a.rackName, b.rackName));
                return sortedRacks.map((rack) {
                  final hasAvailableItems = rack.availableItems.length > 0;
                  return DropdownMenuItem<String>(
                    value: rack.rackName,
                    enabled: hasAvailableItems, // Disable if no available items
                    child: Row(
                      children: [
                        Icon(Icons.inventory_2, 
                            color: hasAvailableItems ? AppColors.primary : Colors.grey.shade400, 
                            size: 20),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              rack.rackName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: hasAvailableItems ? Colors.black : Colors.grey.shade400,
                              ),
                            ),
                            Text(
                              '${rack.availableItems.length} available',
                              style: TextStyle(
                                color: hasAvailableItems ? Colors.black54 : Colors.grey.shade400,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList();
              })(),
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

  Widget _buildSubmittedItemsScreen(SessionProvider sessionProvider, BatchProvider batchProvider) {
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
              color: Colors.green,
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 8,
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
                      color: Colors.green, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    '✅ Select Rack', 
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.green,
                size: 24,
              ),
              items: (() {
                // Sort racks and convert to DropdownMenuItem
                final sortedRacks = session.racks.toList()
                  ..sort((a, b) => _compareLocators(a.rackName, b.rackName));
                return sortedRacks.map((rack) {
                  final hasSubmittedItems = rack.submittedItems.length > 0;
                  return DropdownMenuItem<String>(
                    value: rack.rackName,
                    enabled: hasSubmittedItems, // Disable if no submitted items
                    child: Row(
                      children: [
                        Icon(Icons.inventory_2, 
                            color: hasSubmittedItems ? AppColors.primary : Colors.grey.shade400, 
                            size: 20),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              rack.rackName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: hasSubmittedItems ? Colors.black : Colors.grey.shade400,
                              ),
                            ),
                            Text(
                              '${rack.submittedItems.length} submitted',
                              style: TextStyle(
                                color: hasSubmittedItems ? Colors.grey.shade600 : Colors.grey.shade400,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList();
              })(),
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
          child: _buildItemsList(sessionProvider, true, batchProvider),
        ),
      ],
    );
  }

  Widget _buildItemsList(SessionProvider sessionProvider, bool showSubmitted, [BatchProvider? batchProvider]) {
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
      // Show individual batch submissions from selected rack
      // Each submission will appear as a separate entry
      if (batchProvider == null) {
        return const Center(child: Text('Batch provider not available'));
      }
      final submittedBatches = batchProvider.getSubmittedBatches();
      
      // Filter submitted batches by selected rack and add submission details
      itemsToShow = submittedBatches.where((batch) {
        // Check if the submitted batch belongs to the selected rack
        final batchRackName = batch['submissionDetail']?['rackName'] ?? batch['rackName'];
        return batchRackName == selectedRack.rackName;
      }).map((batch) {
        // Convert each batch submission to display format
        final submissionDetail = batch['submissionDetail'];
        return {
          'itemName': batch['itemName'] ?? submissionDetail?['itemName'] ?? 'Unknown Item',
          'quantity': batch['quantity'] ?? 0,
          'batchNumber': batch['batchNumber'] ?? 'Unknown Batch',
          'locator': submissionDetail?['locator'] ?? batch['locator'] ?? '',
          'rackName': submissionDetail?['rackName'] ?? batch['rackName'] ?? '',
          'submissionTime': batch['submissionTime'] ?? DateTime.now().millisecondsSinceEpoch,
          'confidence': batch['confidence'] ?? 0.0,
          'isIndividualSubmission': true,
          'submissionDetail': submissionDetail,
        };
      }).toList();
      
      // Sort by submission time (most recent first)
      itemsToShow.sort((a, b) {
        final timeA = a['submissionTime'] as int;
        final timeB = b['submissionTime'] as int;
        return timeB.compareTo(timeA); // Descending order (newest first)
      });
    } else {
      // Show available items from selected rack, including partially submitted items
      itemsToShow = selectedRack.items.where((item) {
        // Show item if it has remaining quantity (not fully submitted)
        final remainingQty = item.remainingQuantity;
        return remainingQty > 0;
      }).toList();
      
      // Sort available items by locator position
      itemsToShow.sort((a, b) {
        final locatorA = a.locator ?? '';
        final locatorB = b.locator ?? '';
        return _compareLocators(locatorA, locatorB);
      });
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
    String itemName;
    String quantityText;
    String? selectedBatch;
    String? locator;

    if (isSubmitted) {
      // Handle individual batch submissions
      itemName = item['itemName'] ?? 'Unknown Item';
      final submittedQty = item['quantity']?.toString() ?? '0';
      final batchNumber = item['batchNumber'] ?? 'Unknown Batch';
      final confidence = item['confidence'] ?? 0.0;
      final isIndividualSubmission = item['isIndividualSubmission'] ?? false;
      
      if (isIndividualSubmission) {
        // Show individual submission details with batch number
        quantityText = 'Submitted: $submittedQty\nBatch: $batchNumber';
        if (confidence > 0) {
          quantityText += '\nConfidence: ${confidence.toStringAsFixed(0)}%';
        }
      } else {
        // Fallback for older format
        quantityText = 'Submitted: $submittedQty';
      }
      
      selectedBatch = batchNumber;
      locator = item['locator'];
    } else {
      // Handle regular rack item data - show requested and remaining
      itemName = item.itemName ?? 'Unknown Item';
      final requestedQty = item.quantity ?? 0;
      final submittedQty = item.submittedQuantity ?? 0;
      final remainingQty = requestedQty - submittedQty;
      
      if (submittedQty > 0) {
        // Show both requested and remaining if partially submitted
        quantityText = 'Requested: $requestedQty\nRemaining: $remainingQty';
      } else {
        // Show only requested if nothing submitted yet
        quantityText = 'Requested: $requestedQty';
      }
      
      locator = item.locator;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: () {
        if (isSubmitted) {
          return Colors.green.shade50; // Light green background for submitted items
        } else {
          // For available items, check if partially submitted
          final requestedQty = item.quantity ?? 0;
          final submittedQty = item.submittedQuantity ?? 0;
          if (submittedQty > 0 && submittedQty < requestedQty) {
            return Colors.orange.shade50; // Light orange background for partially submitted
          } else {
            return Colors.blue.shade50; // Light blue background for available items
          }
        }
      }(),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: () {
              if (isSubmitted) {
                return Colors.green.withOpacity(0.3);
              } else {
                // For available items, check if partially submitted
                final requestedQty = item.quantity ?? 0;
                final submittedQty = item.submittedQuantity ?? 0;
                if (submittedQty > 0 && submittedQty < requestedQty) {
                  return Colors.orange.withOpacity(0.3); // Orange border for partially submitted
                } else {
                  return AppColors.primary.withOpacity(0.3); // Primary border for available items
                }
              }
            }(),
            width: 1.0,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: () {
            if (!isSubmitted) {
              // Only allow tapping on available items with remaining quantity
              final requestedQty = item.quantity ?? 0;
              final submittedQty = item.submittedQuantity ?? 0;
              final remainingQty = requestedQty - submittedQty;
              
              if (remainingQty > 0) {
                _openOCRScanner(item);
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Main row with icon, content, and buttons
                Row(
                  children: [
                    // Status icon
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: () {
                          if (isSubmitted) {
                            return Colors.green;
                          } else {
                            // For available items, check if partially submitted
                            final requestedQty = item.quantity ?? 0;
                            final submittedQty = item.submittedQuantity ?? 0;
                            if (submittedQty > 0 && submittedQty < requestedQty) {
                              return Colors.orange; // Partially submitted
                            } else {
                              return AppColors.primary; // Not submitted
                            }
                          }
                        }(),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        () {
                          if (isSubmitted) {
                            return Icons.check;
                          } else {
                            // For available items, check if partially submitted
                            final requestedQty = item.quantity ?? 0;
                            final submittedQty = item.submittedQuantity ?? 0;
                            if (submittedQty > 0 && submittedQty < requestedQty) {
                              return Icons.timelapse; // Partially submitted
                            } else {
                              return Icons.qr_code_scanner; // Not submitted
                            }
                          }
                        }(),
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Expanded content area
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Item name - continuous in one row then wrap
                          Text(
                            itemName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black, // Make item name black for visibility
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // Quantity with larger font and support for multi-line
                          Text(
                            quantityText,
                            style: TextStyle(
                              fontSize: 16, // Increased from 14
                              fontWeight: FontWeight.w600,
                              color: Colors.black87, // Changed from grey to black87 for visibility
                            ),
                            maxLines: 3, // Allow for 3 lines to show batch and confidence info
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Show submission timestamp for individual submissions
                          if (isSubmitted && item['isIndividualSubmission'] == true) ...[
                            const SizedBox(height: 4),
                            Text(
                              _formatSubmissionTime(item['submissionTime']),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                          // Batch info for submitted items only
                          if (isSubmitted && selectedBatch != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Batch: $selectedBatch',
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
                    // More Details button for submitted items
                    if (isSubmitted) ...[
                      Consumer<AppStateProvider>(
                        builder: (context, appState, child) {
                          return Column(
                            children: [
                              // Only show More Details button if setting is enabled
                              if (appState.showMoreDetailsButton) ...[
                                ElevatedButton.icon(
                                  onPressed: () => _openSubmissionDetails(item),
                                  icon: const Icon(Icons.info_outline, size: 16),
                                  label: const Text('More Details'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ],
                ),
                // Locator at bottom right
                if (locator != null && locator.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Loc: $locator',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }  void _openOCRScanner(dynamic item) {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.logApp('Opening OCR scanner for item: ${item.itemName}');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OCRScannerScreen(selectedItem: item),
      ),
    ).then((result) {
      if (result != null && result is Map<String, dynamic>) {
        final success = result['success'] as bool? ?? false;
        final selectedBatch = result['selectedBatch'] as String?;
        
        if (success && selectedBatch != null) {
          // Force refresh the UI by triggering a rebuild
          setState(() {});
          
          // Stay on available items tab so user can continue with next item
          _getTabController().animateTo(0);
        }
      }
      
      // Always refresh the UI after returning from OCR scanner
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _openSubmissionDetails(Map<String, dynamic> submittedBatch) {
    // Navigate to submission details screen with the submitted batch data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BatchSubmissionDetailsScreen(
          submittedBatch: submittedBatch,
        ),
      ),
    );
  }

  /// Compare locator strings for sorting
  /// Handles alphanumeric sorting for locator positions like A1, A2, B1, B2, etc.
  int _compareLocators(String locatorA, String locatorB) {
    if (locatorA.isEmpty && locatorB.isEmpty) return 0;
    if (locatorA.isEmpty) return 1; // Empty locators go to the end
    if (locatorB.isEmpty) return -1;
    
    // Extract alphabetic and numeric parts
    final regExp = RegExp(r'^([A-Za-z]*)(\d*)(.*)$');
    final matchA = regExp.firstMatch(locatorA);
    final matchB = regExp.firstMatch(locatorB);
    
    if (matchA == null || matchB == null) {
      // Fallback to simple string comparison
      return locatorA.compareTo(locatorB);
    }
    
    final alphaA = matchA.group(1) ?? '';
    final alphaB = matchB.group(1) ?? '';
    final numA = int.tryParse(matchA.group(2) ?? '') ?? 0;
    final numB = int.tryParse(matchB.group(2) ?? '') ?? 0;
    final restA = matchA.group(3) ?? '';
    final restB = matchB.group(3) ?? '';
    
    // First compare alphabetic parts
    final alphaComparison = alphaA.compareTo(alphaB);
    if (alphaComparison != 0) {
      return alphaComparison;
    }
    
    // Then compare numeric parts
    final numComparison = numA.compareTo(numB);
    if (numComparison != 0) {
      return numComparison;
    }
    
    // Finally compare the rest
    return restA.compareTo(restB);
  }

  // Helper method to format submission timestamp
  String _formatSubmissionTime(dynamic submissionTime) {
    try {
      DateTime dateTime;
      if (submissionTime is int) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(submissionTime);
      } else if (submissionTime is String) {
        dateTime = DateTime.parse(submissionTime);
      } else {
        return 'Recently submitted';
      }
      
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} min ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return 'Recently submitted';
    }
  }
}
