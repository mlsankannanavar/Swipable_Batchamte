import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../models/rack_model.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../utils/app_colors.dart';
import 'ocr_scanner_screen.dart';

class BatchHistoryScreen extends StatefulWidget {
  const BatchHistoryScreen({super.key});

  @override
  State<BatchHistoryScreen> createState() => _BatchHistoryScreenState();
}

class _BatchHistoryScreenState extends State<BatchHistoryScreen> {
  String? _selectedRack;

  @override
  void initState() {
    super.initState();
    
    // Set default rack selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
      if (sessionProvider.hasSession && sessionProvider.rackNames.isNotEmpty) {
        setState(() {
          _selectedRack = sessionProvider.rackNames.first;
        });
        sessionProvider.selectRack(_selectedRack!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, sessionProvider, child) {
        if (sessionProvider.isLoading) {
          return const LoadingWidget(message: 'Loading batch information...');
        }

        if (sessionProvider.hasError) {
          return CustomErrorWidget(
            title: 'Loading Error',
            message: sessionProvider.errorMessage ?? 'Failed to load batch information',
            onRetry: () => sessionProvider.retryLoadSession(),
          );
        }

        if (!sessionProvider.hasSession) {
          return _buildNoSessionState();
        }

        return _buildBatchHistoryContent(sessionProvider);
      },
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
        ],
      ),
    );
  }

  Widget _buildBatchHistoryContent(SessionProvider sessionProvider) {
    return Column(
      children: [
        // Rack Selection Dropdown
        _buildRackSelector(sessionProvider),
        
        // Items List
        Expanded(
          child: _buildItemsList(sessionProvider),
        ),
      ],
    );
  }

  Widget _buildRackSelector(SessionProvider sessionProvider) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRack,
          hint: const Text('Select Rack'),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: sessionProvider.rackNames.map((String rackName) {
            return DropdownMenuItem<String>(
              value: rackName,
              child: Text(
                rackName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedRack = newValue;
              });
              sessionProvider.selectRack(newValue);
            }
          },
        ),
      ),
    );
  }

  Widget _buildItemsList(SessionProvider sessionProvider) {
    if (_selectedRack == null || !sessionProvider.hasSelectedRack) {
      return const Center(
        child: Text(
          'Select a rack to view items',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    final availableItems = sessionProvider.availableItems;
    final submittedItems = sessionProvider.submittedItems;

    if (availableItems.isEmpty && submittedItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No items found in this rack',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      children: [
        // Available Items Section
        if (availableItems.isNotEmpty) ...[
          _buildSectionHeader(
            'Available Items (${availableItems.length})',
            Icons.inventory_outlined,
            AppColors.primary,
          ),
          const SizedBox(height: 8),
          ...availableItems.map((item) => _buildItemCard(item, sessionProvider, false)),
          const SizedBox(height: 16),
        ],
        
        // Submitted Items Section
        if (submittedItems.isNotEmpty) ...[
          _buildSectionHeader(
            'Submitted Items (${submittedItems.length})',
            Icons.check_circle_outline,
            AppColors.success,
          ),
          const SizedBox(height: 8),
          ...submittedItems.map((item) => _buildItemCard(item, sessionProvider, true)),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(ItemModel item, SessionProvider sessionProvider, bool isSubmitted) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: isSubmitted ? null : () => _openOCRScanner(item),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.itemName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (isSubmitted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'SUBMITTED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Quantity
              Row(
                children: [
                  const Icon(Icons.inventory, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Requested Quantity: ${item.quantity}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Action buttons
              Row(
                children: [
                  // More Info Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showItemDetails(item, sessionProvider),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                      ),
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: const Text('More'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openOCRScanner(ItemModel item) {
    // Navigate to OCR scanner
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OCRScannerScreen(),
      ),
    ).then((result) {
      if (result != null && result is Map<String, dynamic>) {
        final selectedBatch = result['selectedBatch'] as String?;
        if (selectedBatch != null) {
          // Handle batch submission
          final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
          sessionProvider.submitItemWithBatch(item, selectedBatch);
          
          // Show success message
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

  void _showItemDetails(ItemModel item, SessionProvider sessionProvider) {
    final session = sessionProvider.currentSession!;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              Text(
                item.itemName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Session details
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Purchase Order', session.purchaseOrderNumber),
                      _buildDetailRow('Sales Order', session.salesOrderNumber),
                      _buildDetailRow('Unit Code', session.unitCode),
                      _buildDetailRow('Store ID', session.storeId),
                      _buildDetailRow('Requested Quantity', item.quantity.toString()),
                      
                      const SizedBox(height: 20),
                      const Text(
                        'Available Batches',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Batch information
                      ...item.batches.map((batch) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                batch.batchNumber,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 16,
                                    color: batch.isExpired
                                        ? AppColors.error
                                        : batch.isExpiringSoon
                                            ? AppColors.logWarning
                                            : AppColors.success,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Expires: ${batch.expiryDate}',
                                    style: TextStyle(
                                      color: batch.isExpired
                                          ? AppColors.error
                                          : batch.isExpiringSoon
                                              ? AppColors.logWarning
                                              : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              if (batch.isExpired || batch.isExpiringSoon)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: batch.isExpired
                                        ? AppColors.error.withOpacity(0.1)
                                        : AppColors.logWarning.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    batch.isExpired 
                                        ? 'EXPIRED' 
                                        : 'EXPIRES SOON',
                                    style: TextStyle(
                                      color: batch.isExpired 
                                          ? AppColors.error 
                                          : AppColors.logWarning,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )).toList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
