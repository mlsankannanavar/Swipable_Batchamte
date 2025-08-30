import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../providers/logging_provider.dart';
import '../models/log_entry_model.dart';

class DetailedLogViewerScreen extends StatefulWidget {
  const DetailedLogViewerScreen({super.key});

  @override
  State<DetailedLogViewerScreen> createState() => _DetailedLogViewerScreenState();
}

class _DetailedLogViewerScreenState extends State<DetailedLogViewerScreen> {
  final ScrollController _scrollController = ScrollController();
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _copyAllLogs(List<LogEntry> logs) {
    final logText = logs.map((log) {
      return '${_formatTimestamp(log.timestamp)} [${log.level.name.toUpperCase()}] ${log.category}: ${log.message}';
    }).join('\n');
    
    Clipboard.setData(ClipboardData(text: logText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All logs copied to clipboard')),
    );
  }

  void _clearLogs() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Logs'),
          content: const Text('Are you sure you want to clear all logs? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Provider.of<LoggingProvider>(context, listen: false).clearLogs();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All logs cleared')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }

  Color _getLogColor(LogEntry log) {
    switch (log.level.name.toLowerCase()) {
      case 'error':
        return Colors.red.shade100;
      case 'warning':
        return Colors.orange.shade100;
      case 'success':
        return Colors.green.shade100;
      case 'network':
        return Colors.blue.shade100;
      case 'app':
        return Colors.purple.shade100;
      case 'batch':
        return Colors.cyan.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getLogTextColor(LogEntry log) {
    switch (log.level.name.toLowerCase()) {
      case 'error':
        return Colors.red.shade800;
      case 'warning':
        return Colors.orange.shade800;
      case 'success':
        return Colors.green.shade800;
      case 'network':
        return Colors.blue.shade800;
      case 'app':
        return Colors.purple.shade800;
      case 'batch':
        return Colors.cyan.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}.${timestamp.millisecond.toString().padLeft(3, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Detailed Logs'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _scrollToTop,
            icon: const Icon(Icons.keyboard_arrow_up),
            tooltip: 'Scroll to Top',
          ),
          IconButton(
            onPressed: _scrollToBottom,
            icon: const Icon(Icons.keyboard_arrow_down),
            tooltip: 'Scroll to Bottom',
          ),
          Consumer<LoggingProvider>(
            builder: (context, loggingProvider, child) {
              return IconButton(
                onPressed: () => _copyAllLogs(loggingProvider.filteredLogs),
                icon: const Icon(Icons.copy),
                tooltip: 'Copy All Logs',
              );
            },
          ),
          IconButton(
            onPressed: _clearLogs,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear All Logs',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade900,
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search logs...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchText = '';
                          });
                        },
                        icon: const Icon(Icons.clear, color: Colors.grey),
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value.toLowerCase();
                });
              },
            ),
          ),
          
          // Log entries
          Expanded(
            child: Consumer<LoggingProvider>(
              builder: (context, loggingProvider, child) {
                final allLogs = loggingProvider.logs;
                final filteredLogs = _searchText.isEmpty
                    ? allLogs
                    : allLogs.where((log) {
                        return log.message.toLowerCase().contains(_searchText) ||
                            log.category.toLowerCase().contains(_searchText) ||
                            log.level.name.toLowerCase().contains(_searchText);
                      }).toList();

                if (filteredLogs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.article_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No logs available',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: filteredLogs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final log = filteredLogs[index];
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: _getLogColor(log),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _getLogTextColor(log).withOpacity(0.3)),
                      ),
                      child: InkWell(
                        onTap: () {
                          // Copy single log entry
                          final logText = '${_formatTimestamp(log.timestamp)} [${log.level.name.toUpperCase()}] ${log.category}: ${log.message}';
                          Clipboard.setData(ClipboardData(text: logText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Log entry copied to clipboard'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header row
                              Row(
                                children: [
                                  // Log level badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getLogTextColor(log),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      log.level.name.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Category
                                  Expanded(
                                    child: Text(
                                      log.category,
                                      style: TextStyle(
                                        color: _getLogTextColor(log),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  // Timestamp
                                  Text(
                                    _formatTimestamp(log.timestamp),
                                    style: TextStyle(
                                      color: _getLogTextColor(log).withOpacity(0.7),
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Log message
                              Text(
                                log.message,
                                style: TextStyle(
                                  color: _getLogTextColor(log),
                                  fontSize: 14,
                                  height: 1.3,
                                ),
                              ),
                              // Additional data if present
                              if (log.data != null && log.data!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _getLogTextColor(log).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Data: ${log.data.toString()}',
                                      style: TextStyle(
                                        color: _getLogTextColor(log).withOpacity(0.8),
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      
      // Stats footer
      bottomNavigationBar: Consumer<LoggingProvider>(
        builder: (context, loggingProvider, child) {
          final totalLogs = loggingProvider.logs.length;
          final filteredCount = _searchText.isEmpty ? totalLogs : loggingProvider.logs.where((log) {
            return log.message.toLowerCase().contains(_searchText) ||
                log.category.toLowerCase().contains(_searchText) ||
                log.level.name.toLowerCase().contains(_searchText);
          }).length;
          
          return Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade900,
            child: Text(
              'Showing $filteredCount of $totalLogs log entries',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          );
        },
      ),
    );
  }
}
