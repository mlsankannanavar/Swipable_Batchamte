import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/batch_provider.dart';
import '../providers/logging_provider.dart';
import '../models/batch_model.dart';
import '../widgets/batch_card_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../utils/app_colors.dart';
import '../utils/helpers.dart';
import 'batch_submission_details_screen.dart';

class BatchListScreen extends StatefulWidget {
  const BatchListScreen({super.key});

  @override
  State<BatchListScreen> createState() => _BatchListScreenState();
}

class _BatchListScreenState extends State<BatchListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _searchController;
  late ScrollController _scrollController;
  
  String _searchQuery = '';
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Changed from 3 to 2
    _searchController = TextEditingController();
    _scrollController = ScrollController();
    
    // Add listener to rebuild when tab changes
    _tabController.addListener(() {
      setState(() {});
    });
    
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
      final batchProvider = Provider.of<BatchProvider>(context, listen: false);
      
      loggingProvider.logApp('Batch list screen initialized');
      batchProvider.loadBatchHistory();
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
      title: const Text('Batch History'),
      elevation: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textColor,
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.secondary,
        labelColor: AppColors.textColor,
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(text: 'Available Batches'),
          Tab(text: 'Scanned/Submitted'),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _toggleView,
          icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
          tooltip: _isGridView ? 'List View' : 'Grid View',
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'search',
              child: Row(
                children: [
                  Icon(Icons.search),
                  SizedBox(width: 8),
                  Text('Search'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download),
                  SizedBox(width: 8),
                  Text('Export'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Search bar
        if (_searchQuery.isNotEmpty || _searchController.text.isNotEmpty)
          _buildSearchBar(),
        
        // Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAvailableBatches(),
              _buildScannedSubmitted(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search batches...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.clear),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildListView(List<BatchModel> batches) {
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: batches.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return BatchCardWidget(
          batch: batches[index],
          onTap: () => _onBatchTapped(batches[index]),
        );
      },
    );
  }

  Widget _buildGridView(List<BatchModel> batches) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: batches.length,
      itemBuilder: (context, index) {
        return BatchCardWidget(
          batch: batches[index],
          onTap: () => _onBatchTapped(batches[index]),
          compact: true,
        );
      },
    );
  }

  Widget _buildAvailableBatches() {
    return Consumer<BatchProvider>(
      builder: (context, batchProvider, child) {
        if (batchProvider.isLoading) {
          return const LoadingWidget(message: 'Loading available batches...');
        }

        if (batchProvider.errorMessage != null) {
          return CustomErrorWidget(
            title: 'Error Loading Batches',
            message: batchProvider.errorMessage!,
            onRetry: () => batchProvider.loadBatchesForCurrentSession(),
          );
        }

        final availableBatches = batchProvider.batches;

        if (availableBatches.isEmpty) {
          return _buildEmptyAvailableState();
        }

        return RefreshIndicator(
          onRefresh: () => batchProvider.loadBatchesForCurrentSession(),
          child: _isGridView
              ? _buildGridView(availableBatches)
              : _buildListView(availableBatches),
        );
      },
    );
  }

  Widget _buildScannedSubmitted() {
    return Consumer<BatchProvider>(
      builder: (context, batchProvider, child) {
        final submittedBatches = batchProvider.getSubmittedBatches();

        if (submittedBatches.isEmpty) {
          return _buildEmptySubmittedState();
        }

        return RefreshIndicator(
          onRefresh: () => batchProvider.loadSubmittedBatches(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: submittedBatches.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildSubmittedBatchCard(submittedBatches[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildSubmittedBatchCard(dynamic submittedBatch) {
    return Card(
      color: AppColors.cardBackground,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Batch: ${submittedBatch['batchNumber'] ?? 'Unknown'}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Item: ${submittedBatch['itemName'] ?? 'Unknown'}'),
            Text('Quantity: ${submittedBatch['quantity'] ?? 'Unknown'}'),
            Text('Submitted: ${submittedBatch['submittedAt'] ?? 'Unknown'}'),
            const SizedBox(height: 12),
            // Action buttons row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showBatchSubmissionDetails(submittedBatch),
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('View Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
                if (submittedBatch['capturedImage'] != null)
                  TextButton.icon(
                    onPressed: () => _showFullScreenImage(submittedBatch['capturedImage']),
                    icon: const Icon(Icons.zoom_in, size: 16),
                    label: const Text('View Image'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            if (submittedBatch['capturedImage'] != null) ...[
              const SizedBox(height: 8),
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    submittedBatch['capturedImage'],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.image_not_supported, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAvailableState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Available Batches',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scan a QR code to load batches for a session',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySubmittedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.upload_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Submitted Batches',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start scanning and submitting batches to see them here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Event handlers
  void _toggleView() {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    
    setState(() {
      _isGridView = !_isGridView;
    });
    
    loggingProvider.logApp('Batch list view toggled', data: {
      'viewType': _isGridView ? 'grid' : 'list'
    });
  }

  void _handleMenuAction(String action) {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.logApp('Batch list menu action', data: {'action': action});

    switch (action) {
      case 'search':
        _showSearchDialog();
        break;
      case 'export':
        _exportBatches();
        break;
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  void _onBatchTapped(BatchModel batch) {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.logApp('Batch details viewed', data: {'batchId': batch.id});

    _showBatchDetails(batch);
  }

  void _showFullScreenImage(dynamic imageData) {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.logApp('Full screen image viewer opened');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text('Captured Image'),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                onPressed: () {
                  // TODO: Implement share functionality if needed
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share functionality coming soon')),
                  );
                },
                icon: const Icon(Icons.share),
                tooltip: 'Share Image',
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.memory(
                imageData,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Unable to load image',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showBatchSubmissionDetails(dynamic submittedBatch) {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.logApp('Batch submission details viewed', data: {
      'batchNumber': submittedBatch['batchNumber']
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BatchSubmissionDetailsScreen(
          submittedBatch: submittedBatch,
        ),
      ),
    );
  }

  // Helper methods
  
  // Dialog methods
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Batches'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Enter search terms...',
            border: OutlineInputBorder(),
          ),
          onChanged: _onSearchChanged,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showBatchDetails(BatchModel batch) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Batch ${batch.batchNumber}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Product', batch.productName),
              _buildDetailRow('Manufacturer', batch.manufacturer),
              _buildDetailRow('Batch Number', batch.batchNumber),
              _buildDetailRow('Manufacturing Date', batch.manufacturingDate),
              _buildDetailRow('Expiry Date', batch.expiryDate),
              _buildDetailRow('Status', batch.status),
              _buildDetailRow('Scanned', Helpers.formatDateTime(batch.scannedAt)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _shareBatch(batch);
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _exportBatches() {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    final batchProvider = Provider.of<BatchProvider>(context, listen: false);
    
    loggingProvider.logApp('Exporting batch data');
    
    // Implementation for exporting batch data
    batchProvider.exportBatchData();
  }

  void _shareBatch(BatchModel batch) {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.logApp('Sharing batch data', data: {'batchId': batch.id});
    
    // Implementation for sharing individual batch
    // This would typically use the share package
  }
}
