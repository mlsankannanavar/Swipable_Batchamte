import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/logging_provider.dart';
import '../models/log_entry_model.dart';
import '../widgets/api_log_tab_widget.dart';
import '../utils/app_colors.dart';

class ApiLogViewerScreen extends StatefulWidget {
  const ApiLogViewerScreen({super.key});

  @override
  State<ApiLogViewerScreen> createState() => _ApiLogViewerScreenState();
}

class _ApiLogViewerScreenState extends State<ApiLogViewerScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabNames = [
    'Health Check',
    'Filtered Batches', 
    'Submit',
    'Mobile Log'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabNames.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Map<String, List<LogEntry>> _filterApiLogsByEndpoint(List<LogEntry> logs) {
    final filteredLogs = <String, List<LogEntry>>{};
    
    // Initialize empty lists for each endpoint
    for (final tabName in _tabNames) {
      filteredLogs[tabName] = [];
    }

    // Filter logs by endpoint patterns
    for (final log in logs) {
      if (log.category == 'API-OUT' || log.category == 'API-IN') {
        final url = log.url?.toLowerCase() ?? '';
        
        if (url.contains('/health')) {
          filteredLogs['Health Check']!.add(log);
        } else if (url.contains('/api/filtered-batches')) {
          filteredLogs['Filtered Batches']!.add(log);
        } else if (url.contains('/api/submit-mobile-batch')) {
          filteredLogs['Submit']!.add(log);
        } else if (url.contains('/api/submit-mobile-log')) {
          filteredLogs['Mobile Log']!.add(log);
        }
      }
    }

    return filteredLogs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'API Logs',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          tabs: _tabNames.map((name) => Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getTabIcon(name), size: 18),
                const SizedBox(width: 8),
                Text(name),
              ],
            ),
          )).toList(),
        ),
      ),
      body: Consumer<LoggingProvider>(
        builder: (context, loggingProvider, child) {
          final allLogs = loggingProvider.logs;
          final filteredLogs = _filterApiLogsByEndpoint(allLogs);

          return TabBarView(
            controller: _tabController,
            children: _tabNames.map((tabName) {
              final logs = filteredLogs[tabName] ?? [];
              return ApiLogTabWidget(
                tabName: tabName,
                logs: logs,
                onRefresh: () async {
                  // Refresh logs if needed
                  setState(() {});
                },
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Clear API Logs'),
              content: const Text('Are you sure you want to clear all API logs? This action cannot be undone.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    loggingProvider.clearLogs();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('API logs cleared')),
                    );
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Clear'),
                ),
              ],
            ),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.clear_all),
      ),
    );
  }

  IconData _getTabIcon(String tabName) {
    switch (tabName) {
      case 'Health Check':
        return Icons.health_and_safety_outlined;
      case 'Filtered Batches':
        return Icons.filter_list_outlined;
      case 'Submit':
        return Icons.send_outlined;
      case 'Mobile Log':
        return Icons.phone_android_outlined;
      default:
        return Icons.api_outlined;
    }
  }
}