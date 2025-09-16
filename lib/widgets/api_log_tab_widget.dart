import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/log_entry_model.dart';
import '../widgets/api_call_card_widget.dart';
import '../utils/app_colors.dart';

class ApiLogTabWidget extends StatefulWidget {
  final String tabName;
  final List<LogEntry> logs;
  final VoidCallback onRefresh;

  const ApiLogTabWidget({
    super.key,
    required this.tabName,
    required this.logs,
    required this.onRefresh,
  });

  @override
  State<ApiLogTabWidget> createState() => _ApiLogTabWidgetState();
}

class _ApiLogTabWidgetState extends State<ApiLogTabWidget> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ApiCallPair> _groupLogsIntoPairs() {
    final pairs = <ApiCallPair>[];
    final requestLogs = <LogEntry>[];
    final responseLogs = <LogEntry>[];

    // Separate request and response logs
    for (final log in widget.logs) {
      if (log.category == 'API-OUT') {
        requestLogs.add(log);
      } else if (log.category == 'API-IN') {
        responseLogs.add(log);
      }
    }

    // Group requests with their corresponding responses
    for (final request in requestLogs) {
      LogEntry? matchingResponse;
      
      // Find the response that matches this request (same URL and close timestamp)
      for (final response in responseLogs) {
        if (request.url == response.url && 
            response.timestamp.isAfter(request.timestamp) &&
            response.timestamp.difference(request.timestamp).inMinutes < 2) {
          matchingResponse = response;
          break;
        }
      }

      pairs.add(ApiCallPair(
        request: request,
        response: matchingResponse,
        endpoint: _extractEndpoint(request.url ?? ''),
        method: _extractMethod(request.message),
        timestamp: request.timestamp,
      ));

      if (matchingResponse != null) {
        responseLogs.remove(matchingResponse);
      }
    }

    // Add any orphaned responses
    for (final response in responseLogs) {
      pairs.add(ApiCallPair(
        request: null,
        response: response,
        endpoint: _extractEndpoint(response.url ?? ''),
        method: _extractMethod(response.message),
        timestamp: response.timestamp,
      ));
    }

    // Sort by timestamp (newest first)
    pairs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Filter by search query if any
    if (_searchQuery.isNotEmpty) {
      return pairs.where((pair) {
        final searchLower = _searchQuery.toLowerCase();
        return pair.endpoint.toLowerCase().contains(searchLower) ||
               pair.method.toLowerCase().contains(searchLower) ||
               (pair.request?.message.toLowerCase().contains(searchLower) ?? false) ||
               (pair.response?.message.toLowerCase().contains(searchLower) ?? false);
      }).toList();
    }

    return pairs;
  }

  String _extractEndpoint(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.path;
    } catch (e) {
      return url;
    }
  }

  String _extractMethod(String message) {
    final parts = message.split(' ');
    return parts.isNotEmpty ? parts.first : 'UNKNOWN';
  }

  @override
  Widget build(BuildContext context) {
    final pairs = _groupLogsIntoPairs();

    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search ${widget.tabName.toLowerCase()} logs...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${pairs.length} calls',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),

        // API calls list
        Expanded(
          child: pairs.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () async {
                    widget.onRefresh();
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: pairs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ApiCallCardWidget(
                          pair: pairs[index],
                          onTap: () => _showApiCallDetails(pairs[index]),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.api_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No ${widget.tabName} API calls yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'API calls will appear here when they are made',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _showApiCallDetails(ApiCallPair pair) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ApiCallDetailsSheet(pair: pair),
    );
  }
}

// Data class for API call pairs
class ApiCallPair {
  final LogEntry? request;
  final LogEntry? response;
  final String endpoint;
  final String method;
  final DateTime timestamp;

  ApiCallPair({
    this.request,
    this.response,
    required this.endpoint,
    required this.method,
    required this.timestamp,
  });

  bool get isSuccess {
    if (response?.statusCode != null) {
      return response!.statusCode! >= 200 && response!.statusCode! < 300;
    }
    return false;
  }

  bool get isError {
    if (response?.statusCode != null) {
      return response!.statusCode! >= 400;
    }
    return request != null && response == null; // Request without response is also an error
  }

  Duration? get duration => response?.duration;
  int? get statusCode => response?.statusCode;
}

// Details sheet widget
class ApiCallDetailsSheet extends StatelessWidget {
  final ApiCallPair pair;

  const ApiCallDetailsSheet({super.key, required this.pair});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${pair.method} ${pair.endpoint}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87, // Explicit color for headers
                            ),
                          ),
                          Text(
                            pair.timestamp.toString().substring(0, 19),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54, // Change from grey to black54 for visibility
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (pair.statusCode != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: pair.isSuccess ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          pair.statusCode.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (pair.request != null) ...[
                        _buildSection('Request', pair.request!),
                        const SizedBox(height: 24),
                      ],
                      if (pair.response != null) ...[
                        _buildSection('Response', pair.response!),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, LogEntry log) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87, // Explicit color for main titles
          ),
        ),
        const SizedBox(height: 12),

        if (log.headers != null && log.headers!.isNotEmpty) ...[
          _buildSubSection('Headers', log.headers),
          const SizedBox(height: 16),
        ],

        if (log.requestBody != null) ...[
          _buildSubSection('Request Body', log.requestBody),
          const SizedBox(height: 16),
        ],

        if (log.responseBody != null) ...[
          _buildSubSection('Response Body', log.responseBody),
        ],
      ],
    );
  }

  Widget _buildSubSection(String title, dynamic data) {
    String displayData;
    try {
      if (data is String) {
        displayData = data;
      } else {
        displayData = JsonEncoder.withIndent('  ').convert(data);
      }
    } catch (e) {
      displayData = data.toString();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87, // Explicit color for section titles
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: displayData));
                // Could show a snackbar here
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: SelectableText(
            displayData,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Colors.black, // Explicit black color for better visibility
            ),
          ),
        ),
      ],
    );
  }
}