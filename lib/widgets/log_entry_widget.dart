import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/log_entry_model.dart';
import '../utils/app_colors.dart';
import '../utils/helpers.dart';
import '../utils/log_level.dart';

class LogEntryWidget extends StatefulWidget {
  final LogEntry logEntry;
  final bool isExpanded;
  final VoidCallback? onTap;
  final VoidCallback? onCopy;

  const LogEntryWidget({
    super.key,
    required this.logEntry,
    this.isExpanded = false,
    this.onTap,
    this.onCopy,
  });

  @override
  State<LogEntryWidget> createState() => _LogEntryWidgetState();
}

class _LogEntryWidgetState extends State<LogEntryWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      elevation: 1,
      child: InkWell(
        onTap: _toggleExpanded,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              if (_isExpanded) ...[
                const SizedBox(height: 8),
                AnimatedBuilder(
                  animation: _expandAnimation,
                  builder: (context, child) => SizeTransition(
                    sizeFactor: _expandAnimation,
                    child: _buildExpandedContent(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Log level indicator
        _buildLevelIndicator(),
        const SizedBox(width: 8),
        
        // Timestamp
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            widget.logEntry.formattedTimestamp,
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: Colors.grey,
            ),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Category
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _getCategoryColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _getCategoryColor().withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            widget.logEntry.category,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _getCategoryColor(),
            ),
          ),
        ),
        
        const Spacer(),
        
        // Copy button
        IconButton(
          onPressed: _copyLogEntry,
          icon: const Icon(Icons.copy, size: 16),
          iconSize: 16,
          constraints: const BoxConstraints(
            minHeight: 24,
            minWidth: 24,
          ),
          padding: EdgeInsets.zero,
          tooltip: 'Copy log entry',
        ),
        
        // Expand/collapse icon
        Icon(
          _isExpanded ? Icons.expand_less : Icons.expand_more,
          size: 16,
          color: Colors.grey,
        ),
      ],
    );
  }

  Widget _buildLevelIndicator() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: _getLevelColor(),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main message
          _buildMessageSection(),
          
          // Data section
          if (widget.logEntry.hasData) ...[
            const SizedBox(height: 12),
            _buildDataSection(),
          ],
          
          // API specific information
          if (widget.logEntry.isApiLog) ...[
            const SizedBox(height: 12),
            _buildApiSection(),
          ],
          
          // Error information
          if (widget.logEntry.hasError) ...[
            const SizedBox(height: 12),
            _buildErrorSection(),
          ],
          
          // Stack trace
          if (widget.logEntry.hasStackTrace) ...[
            const SizedBox(height: 12),
            _buildStackTraceSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.message,
              size: 14,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              'Message',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            widget.logEntry.message,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.data_object,
              size: 14,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              'Data',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            _formatData(widget.logEntry.data!),
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApiSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.api,
              size: 14,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              'API Details',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.logEntry.url != null) ...[
                Text(
                  'URL: ${widget.logEntry.url}',
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 4),
              ],
              if (widget.logEntry.statusCode != null) ...[
                Text(
                  'Status: ${widget.logEntry.statusCode} ${Helpers.getHttpStatusMessage(widget.logEntry.statusCode!)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: _getStatusCodeColor(widget.logEntry.statusCode!),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              if (widget.logEntry.duration != null) ...[
                Text(
                  'Duration: ${Helpers.formatDuration(widget.logEntry.duration!)}',
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 4),
              ],
              if (widget.logEntry.headers != null) ...[
                const Text(
                  'Headers:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                ...widget.logEntry.headers!.entries.map((entry) => Text(
                  '  ${entry.key}: ${entry.value}',
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                )),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.error,
              size: 14,
              color: AppColors.logError,
            ),
            SizedBox(width: 6),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.logError,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.logError.withOpacity(0.05),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.logError.withOpacity(0.2)),
          ),
          child: Text(
            widget.logEntry.error.toString(),
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: AppColors.logError,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStackTraceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.bug_report,
              size: 14,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              'Stack Trace',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 200),
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                widget.logEntry.stackTrace.toString(),
                style: const TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
    widget.onTap?.call();
  }

  void _copyLogEntry() {
    final logText = widget.logEntry.toLogString();
    Clipboard.setData(ClipboardData(text: logText));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Log entry copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
    
    widget.onCopy?.call();
  }

  Color _getLevelColor() {
    switch (widget.logEntry.level) {
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

  Color _getCategoryColor() {
    switch (widget.logEntry.category) {
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

  Color _getStatusCodeColor(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) {
      return AppColors.logSuccess;
    } else if (statusCode >= 300 && statusCode < 400) {
      return AppColors.logWarning;
    } else if (statusCode >= 400) {
      return AppColors.logError;
    }
    return Colors.grey;
  }

  String _formatData(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    data.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    return buffer.toString().trim();
  }
}
