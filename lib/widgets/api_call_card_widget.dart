import 'package:flutter/material.dart';
import '../widgets/api_log_tab_widget.dart';

class ApiCallCardWidget extends StatelessWidget {
  final ApiCallPair pair;
  final VoidCallback onTap;

  const ApiCallCardWidget({
    super.key,
    required this.pair,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with method, endpoint and status
              Row(
                children: [
                  // HTTP method badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getMethodColor(),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      pair.method,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Endpoint
                  Expanded(
                    child: Text(
                      pair.endpoint,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Status code badge (if available)
                  if (pair.statusCode != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        pair.statusCode.toString(),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Details row
              Row(
                children: [
                  // Timestamp
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.black87,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimestamp(pair.timestamp),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                  
                  // Duration (if available)
                  if (pair.duration != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: Colors.black87,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${pair.duration!.inMilliseconds}ms',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                  
                  const Spacer(),
                  
                  // Status indicator
                  _buildStatusIndicator(),
                ],
              ),
              
              // Request/Response status
              const SizedBox(height: 8),
              Row(
                children: [
                  if (pair.request != null) ...[
                    Icon(
                      Icons.arrow_upward,
                      size: 14,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Request',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  
                  if (pair.request != null && pair.response != null) ...[
                    const SizedBox(width: 16),
                  ],
                  
                  if (pair.response != null) ...[
                    Icon(
                      Icons.arrow_downward,
                      size: 14,
                      color: _getStatusColor(),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Response',
                      style: TextStyle(
                        fontSize: 11,
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w500,
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

  Widget _buildStatusIndicator() {
    if (pair.response == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            size: 16,
            color: Colors.orange.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            'Pending',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          pair.isSuccess ? Icons.check_circle : Icons.error,
          size: 16,
          color: _getStatusColor(),
        ),
        const SizedBox(width: 4),
        Text(
          pair.isSuccess ? 'Success' : 'Error',
          style: TextStyle(
            fontSize: 12,
            color: pair.isSuccess ? Colors.green : Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getMethodColor() {
    switch (pair.method.toUpperCase()) {
      case 'GET':
        return Colors.green;
      case 'POST':
        return Colors.blue;
      case 'PUT':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      case 'PATCH':
        return Colors.purple;
      default:
        return Colors.black54;
    }
  }

  Color _getStatusColor() {
    if (pair.statusCode == null) {
      return Colors.orange;
    }
    
    if (pair.isSuccess) {
      return Colors.green;
    } else if (pair.isError) {
      return Colors.red;
    } else {
      return Colors.orange;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inMinutes < 1) {
      return 'Now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}