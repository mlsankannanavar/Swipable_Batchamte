import 'package:flutter/material.dart';
import '../models/batch_model.dart';
import '../utils/app_colors.dart';
import '../utils/helpers.dart';

class BatchCardWidget extends StatelessWidget {
  final BatchModel batch;
  final VoidCallback? onTap;
  final bool showExpiryStatus;
  final bool compact;

  const BatchCardWidget({
    super.key,
    required this.batch,
    this.onTap,
    this.showExpiryStatus = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactCard(context);
    }
    return _buildFullCard(context);
  }

  Widget _buildFullCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
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
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          batch.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Batch: ${batch.batchId}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontFamily: 'monospace',
                          ),
                        ),
                        if (batch.itemName != null)
                          Text(
                            batch.itemName!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (showExpiryStatus)
                    _buildExpiryStatusChip(),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Batch details
              _buildBatchDetails(),
              
              // Additional info if available
              if (batch.additionalInfo != null && batch.additionalInfo!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildAdditionalInfo(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 1,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _getStatusColor().withOpacity(0.2),
          child: Icon(
            _getStatusIcon(),
            color: _getStatusColor(),
            size: 20,
          ),
        ),
        title: Text(
          batch.displayName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Batch: ${batch.batchId}',
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
            if (batch.expiryDate != null)
              Text(
                'Expires: ${_formatDate(batch.expiryDate!)}',
                style: TextStyle(
                  fontSize: 11,
                  color: _getStatusColor(),
                ),
              ),
            if (batch.itemName != null)
              Text(
                batch.itemName!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: showExpiryStatus ? _buildCompactStatusIndicator() : null,
        dense: true,
      ),
    );
  }

  Widget _buildExpiryStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            size: 12,
            color: _getStatusColor(),
          ),
          const SizedBox(width: 4),
          Text(
            batch.expiryStatus,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _getStatusColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatusIndicator() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: _getStatusColor(),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildBatchDetails() {
    return Column(
      children: [
        if (batch.lotNumber != null)
          _buildDetailRow(Icons.inventory, 'Lot Number', batch.lotNumber!),
        
        if (batch.manufacturingDate != null)
          _buildDetailRow(Icons.factory, 'Manufacturing Date', 
              _formatDate(batch.manufacturingDate!)),
        
        if (batch.expiryDate != null)
          _buildDetailRow(Icons.schedule, 'Expiry Date', 
              _formatDate(batch.expiryDate!)),
        
        if (batch.manufacturer != null)
          _buildDetailRow(Icons.business, 'Manufacturer', batch.manufacturer!),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
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
          Text(
            'Additional Information',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          ...batch.additionalInfo!.entries.map((entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Text(
              '${Helpers.camelCaseToTitle(entry.key)}: ${entry.value}',
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          )),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (batch.isExpired) {
      return AppColors.logError;
    } else if (batch.daysUntilExpiry >= 0 && batch.daysUntilExpiry <= 30) {
      return AppColors.logWarning;
    } else {
      return AppColors.logSuccess;
    }
  }

  IconData _getStatusIcon() {
    if (batch.isExpired) {
      return Icons.error;
    } else if (batch.daysUntilExpiry >= 0 && batch.daysUntilExpiry <= 30) {
      return Icons.warning;
    } else {
      return Icons.check_circle;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return Helpers.formatDateOnly(date);
    } catch (e) {
      return dateString;
    }
  }
}

// Batch statistics widget
class BatchStatisticsWidget extends StatelessWidget {
  final Map<String, int> statistics;
  final bool compact;

  const BatchStatisticsWidget({
    super.key,
    required this.statistics,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactStats();
    }
    return _buildFullStats();
  }

  Widget _buildCompactStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem('Total', statistics['total'] ?? 0, AppColors.logInfo),
        _buildStatItem('Valid', statistics['valid'] ?? 0, AppColors.logSuccess),
        _buildStatItem('Warning', statistics['expiringSoon'] ?? 0, AppColors.logWarning),
        _buildStatItem('Expired', statistics['expired'] ?? 0, AppColors.logError),
      ],
    );
  }

  Widget _buildFullStats() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Batch Statistics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatCard('Total Batches', statistics['total'] ?? 0, AppColors.logInfo, Icons.inventory)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard('Valid', statistics['valid'] ?? 0, AppColors.logSuccess, Icons.check_circle)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildStatCard('Expiring Soon', statistics['expiringSoon'] ?? 0, AppColors.logWarning, Icons.warning)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard('Expired', statistics['expired'] ?? 0, AppColors.logError, Icons.error)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
