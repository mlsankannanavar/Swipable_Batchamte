import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/logging_provider.dart';
import '../models/log_entry_model.dart';
import '../widgets/log_entry_widget.dart';
import '../widgets/loading_widget.dart';
import '../utils/app_colors.dart';
import '../utils/log_level.dart';

class LogViewerScreen extends StatefulWidget {
  final ScrollController? scrollController;
  final bool isBottomSheet;

  const LogViewerScreen({
    super.key,
    this.scrollController,
    this.isBottomSheet = false,
  });

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _listScrollController;
  late TextEditingController _searchController;
  
  LogLevel? _selectedLevel;
  String? _selectedCategory;
  bool _autoScroll = true;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _listScrollController = widget.scrollController ?? ScrollController();
    _searchController = TextEditingController();
    
    // Auto-scroll to bottom when new logs arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    if (widget.scrollController == null) {
      _listScrollController.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isBottomSheet ? Colors.transparent : null,
      appBar: widget.isBottomSheet ? null : _buildAppBar(),
      body: widget.isBottomSheet ? _buildBottomSheetContent() : _buildContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Application Logs'),
      elevation: 0,
      actions: [
        IconButton(
          onPressed: _toggleSearch,
          icon: Icon(_showSearch ? Icons.search_off : Icons.search),
          tooltip: 'Search logs',
        ),
        IconButton(
          onPressed: _showFilterDialog,
          icon: const Icon(Icons.filter_list),
          tooltip: 'Filter logs',
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.share),
                  SizedBox(width: 8),
                  Text('Export Logs'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.clear_all),
                  SizedBox(width: 8),
                  Text('Clear Logs'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'autoscroll',
              child: Row(
                children: [
                  Icon(_autoScroll ? Icons.pause : Icons.play_arrow),
                  const SizedBox(width: 8),
                  Text(_autoScroll ? 'Pause Auto-scroll' : 'Resume Auto-scroll'),
                ],
              ),
            ),
          ],
        ),
      ],
      bottom: _showSearch ? _buildSearchBar() : _buildFilterChips(),
    );
  }

  Widget _buildBottomSheetContent() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Application Logs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _toggleSearch,
                  icon: Icon(_showSearch ? Icons.search_off : Icons.search),
                  iconSize: 20,
                ),
                IconButton(
                  onPressed: _showFilterDialog,
                  icon: const Icon(Icons.filter_list),
                  iconSize: 20,
                ),
              ],
            ),
          ),
          
          if (_showSearch) 
            Container(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search logs...',
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
            ),
          
          // Filter chips
          _buildFilterChips(),
          
          // Content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildLogsList(),
        _buildStatistics(),
      ],
    );
  }

  PreferredSizeWidget? _buildSearchBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search logs...',
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
      ),
    );
  }

  PreferredSizeWidget _buildFilterChips() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Consumer<LoggingProvider>(
        builder: (context, loggingProvider, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Tab bar
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: Colors.grey,
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: const [
                      Tab(text: 'Logs'),
                      Tab(text: 'Statistics'),
                    ],
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Level filters
                  ...LogLevel.values.map((level) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(level.name.toUpperCase()),
                      selected: _selectedLevel == level,
                      selectedColor: _getLevelColor(level).withOpacity(0.2),
                      checkmarkColor: _getLevelColor(level),
                      onSelected: (selected) => _setLevelFilter(selected ? level : null),
                      avatar: _selectedLevel == level ? null : Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getLevelColor(level),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  )),
                  
                  const SizedBox(width: 8),
                  
                  // Clear filters button
                  if (_selectedLevel != null || _selectedCategory != null || _searchController.text.isNotEmpty)
                    ActionChip(
                      label: const Text('Clear'),
                      onPressed: _clearAllFilters,
                      backgroundColor: Colors.grey.shade200,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogsList() {
    return Consumer<LoggingProvider>(
      builder: (context, loggingProvider, child) {
        if (!loggingProvider.isInitialized) {
          return const LoadingWidget(
            message: 'Initializing logging service...',
          );
        }

        final logs = loggingProvider.filteredLogs;

        if (logs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.terminal,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No logs available',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Logs will appear here as you use the app',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        // Auto-scroll when new logs arrive
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_autoScroll && _listScrollController.hasClients) {
            _scrollToBottom();
          }
        });

        return ListView.builder(
          controller: _listScrollController,
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            return LogEntryWidget(
              logEntry: logs[index],
              onTap: () => _onLogEntryTapped(logs[index]),
              onCopy: () => _onLogEntryCopied(logs[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildStatistics() {
    return Consumer<LoggingProvider>(
      builder: (context, loggingProvider, child) {
        final levelCounts = loggingProvider.getLogCountByLevel();
        final categoryCounts = loggingProvider.getAllLogCountsByCategory();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Log Levels Statistics
              _buildStatisticsCard(
                'Log Levels',
                levelCounts.entries.map((entry) => 
                  _buildStatItem(
                    entry.key.name.toUpperCase(),
                    entry.value,
                    _getLevelColor(entry.key),
                  )
                ).toList(),
              ),
              
              const SizedBox(height: 16),
              
              // Categories Statistics
              _buildStatisticsCard(
                'Categories',
                categoryCounts.entries.map((entry) => 
                  _buildStatItem(
                    entry.key,
                    entry.value,
                    _getCategoryColor(entry.key),
                  )
                ).toList(),
              ),
              
              const SizedBox(height: 16),
              
              // Recent Activity
              _buildRecentActivity(loggingProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatisticsCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            count.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(LoggingProvider loggingProvider) {
    final recentLogs = loggingProvider.getRecentLogs(30); // Last 30 minutes
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity (Last 30 minutes)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (recentLogs.isEmpty)
              const Text(
                'No recent activity',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...recentLogs.take(5).map((log) => ListTile(
                dense: true,
                leading: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getLevelColor(log.level),
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(
                  log.message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
                subtitle: Text(
                  log.formattedTimestamp,
                  style: const TextStyle(fontSize: 10),
                ),
                trailing: Text(
                  log.category,
                  style: TextStyle(
                    fontSize: 10,
                    color: _getCategoryColor(log.category),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }

  // Event handlers
  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _clearSearch();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  void _onSearchChanged(String query) {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.setSearchQuery(query);
  }

  void _setLevelFilter(LogLevel? level) {
    setState(() {
      _selectedLevel = level;
    });
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.setLevelFilter(level);
  }

  void _clearAllFilters() {
    setState(() {
      _selectedLevel = null;
      _selectedCategory = null;
      _searchController.clear();
    });
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.clearFilters();
  }

  void _showFilterDialog() {
    // Implementation for advanced filter dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Options'),
        content: const Text('Advanced filtering options will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    
    switch (action) {
      case 'export':
        loggingProvider.exportFilteredLogs();
        break;
      case 'clear':
        _showClearConfirmation();
        break;
      case 'autoscroll':
        setState(() {
          _autoScroll = !_autoScroll;
        });
        loggingProvider.setAutoScroll(_autoScroll);
        break;
    }
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Logs'),
        content: const Text('Are you sure you want to clear all logs? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
              loggingProvider.clearLogs();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _onLogEntryTapped(LogEntry logEntry) {
    // Log the interaction
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.logApp('Log entry expanded', data: {'logId': logEntry.id});
  }

  void _onLogEntryCopied(LogEntry logEntry) {
    // Log the copy action
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.logApp('Log entry copied', data: {'logId': logEntry.id});
  }

  void _scrollToBottom() {
    if (_listScrollController.hasClients) {
      _listScrollController.animateTo(
        _listScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Helper methods for colors
  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return AppColors.logInfo;
      case LogLevel.success:
        return AppColors.logSuccess;
      case LogLevel.warning:
        return AppColors.logWarning;
      case LogLevel.error:
        return AppColors.logError;
      case LogLevel.fatal:
        return AppColors.logError; // Use same color as error
      case LogLevel.debug:
        return AppColors.logDebug;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'API-OUT':
      case 'API-IN':
        return Colors.blue.shade700;
      case 'QR-SCAN':
        return Colors.green.shade700;
      case 'OCR':
        return Colors.purple.shade700;
      case 'ERROR':
        return AppColors.logError;
      case 'NETWORK':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}
