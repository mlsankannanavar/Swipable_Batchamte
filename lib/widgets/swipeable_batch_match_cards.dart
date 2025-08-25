import 'package:flutter/material.dart';
import '../models/batch_match_model.dart';
import '../utils/app_colors.dart';

class SwipeableBatchMatchCards extends StatefulWidget {
  final List<BatchMatch> matches;
  final Function(BatchMatch, int quantity) onSubmit;
  final VoidCallback onRetake;
  final VoidCallback onClose;

  const SwipeableBatchMatchCards({
    Key? key,
    required this.matches,
    required this.onSubmit,
    required this.onRetake,
    required this.onClose,
  }) : super(key: key);

  @override
  State<SwipeableBatchMatchCards> createState() => _SwipeableBatchMatchCardsState();
}

class _SwipeableBatchMatchCardsState extends State<SwipeableBatchMatchCards> {
  late PageController _pageController;
  int _currentIndex = 0;
  final Map<int, TextEditingController> _quantityControllers = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Initialize quantity controllers with prefilled values
    for (int i = 0; i < widget.matches.length; i++) {
      _quantityControllers[i] = TextEditingController(
        text: widget.matches[i].requestedQuantity.toString(),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _quantityControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return AnimatedPadding(
          duration: Duration(milliseconds: 300),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
          children: [
            // Drag handle
            Container(
              padding: EdgeInsets.only(top: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Header with current position indicator
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Match ${_currentIndex + 1} of ${widget.matches.length}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: Icon(Icons.close, color: AppColors.textSecondary, size: 28),
                  ),
                ],
              ),
            ),
            
            // Swipeable cards
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.horizontal, // Changed to horizontal for better UX
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: widget.matches.length,
                itemBuilder: (context, index) {
                  return _buildMatchCard(widget.matches[index], index);
                },
              ),
            ),
            
            // Swipe instruction and page indicators
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Navigation buttons
                  if (widget.matches.length > 1) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Previous button
                        IconButton(
                          onPressed: _currentIndex > 0 
                            ? () {
                                _pageController.previousPage(
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            : null,
                          icon: Icon(
                            Icons.chevron_left,
                            size: 30,
                            color: _currentIndex > 0 
                              ? AppColors.primary 
                              : Colors.grey[400],
                          ),
                        ),
                        
                        // Page indicators
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            widget.matches.length,
                            (index) => Container(
                              margin: EdgeInsets.symmetric(horizontal: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: index == _currentIndex 
                                  ? AppColors.primary 
                                  : Colors.grey[300],
                              ),
                            ),
                          ),
                        ),
                        
                        // Next button
                        IconButton(
                          onPressed: _currentIndex < widget.matches.length - 1
                            ? () {
                                _pageController.nextPage(
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            : null,
                          icon: Icon(
                            Icons.chevron_right,
                            size: 30,
                            color: _currentIndex < widget.matches.length - 1
                              ? AppColors.primary 
                              : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                  ] else ...[
                    // Page indicators for single match
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.matches.length,
                        (index) => Container(
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == _currentIndex 
                              ? AppColors.primary 
                              : Colors.grey[300],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      widget.matches.length > 1 
                        ? (_currentIndex < widget.matches.length - 1 
                          ? 'Swipe left/right for more matches' 
                          : 'Last match')
                        : 'Single match found',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        ),
        );
      },
    );
  }

  Widget _buildMatchCard(BatchMatch match, int index) {
    final quantityController = _quantityControllers[index]!;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(14), // Reduced from 20
          physics: ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 28, // Account for reduced padding
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rank indicator - more compact
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getRankColor(match.rank),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Rank: ${match.rankDisplay}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12, // Reduced from 14
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Spacer(),
                    // Confidence badge - more compact
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getConfidenceColor(match.confidence),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${match.confidence.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11, // Reduced from 12
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16), // Reduced from 24
                
                // Match information card
                Container(
                  padding: EdgeInsets.all(16), // Reduced from 20
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10), // Reduced from 12
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('Item Name:', match.itemName, isImportant: true),
                      _buildInfoRow('Batch Number:', match.batchNumber, isImportant: true),
                      _buildInfoRow('Expiry Date:', match.expiryDate, isImportant: true),
                      _buildInfoRow('Requested Qty:', '${match.requestedQuantity}'),
                      
                      // Order information section
                      if (match.purchaseOrderNumber != null || match.saleOrderNumber != null) ...[
                        SizedBox(height: 8), // Reduced from 12
                        Divider(color: Colors.grey[300]),
                        SizedBox(height: 8), // Reduced from 12
                        Text(
                          'Order Information',
                          style: TextStyle(
                            fontSize: 14, // Reduced from 16
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8), // Reduced from 12
                        if (match.purchaseOrderNumber != null)
                          _buildInfoRow('Purchase Order:', match.purchaseOrderNumber!),
                        if (match.saleOrderNumber != null)
                          _buildInfoRow('Sale Order:', match.saleOrderNumber!),
                      ],
                    ],
                  ),
                ),
                
                SizedBox(height: 16), // Reduced from 24
                
                // Quantity input section
                Container(
                  padding: EdgeInsets.all(16), // Reduced from 20
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10), // Reduced from 12
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter Quantity to Submit:',
                        style: TextStyle(
                          fontSize: 14, // Reduced from 16
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8), // Reduced from 12
                      TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        autofocus: false,
                        style: TextStyle(
                          fontSize: 16, // Reduced from 18
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8), // Reduced from 10
                            borderSide: BorderSide(color: Colors.blue[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.primary, width: 2),
                          ),
                          hintText: 'Enter quantity',
                          prefixIcon: Icon(
                            Icons.inventory_2_outlined, 
                            color: AppColors.primary,
                          ),
                          suffixText: 'units',
                          suffixStyle: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12), // Reduced padding
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 16), // Reduced from 24
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleSubmit(match, quantityController),
                        icon: Icon(Icons.check_circle_outline, color: Colors.white),
                        label: Text(
                          'Submit',
                          style: TextStyle(
                            fontSize: 14, // Reduced from 16
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(vertical: 12), // Reduced from 14
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8), // Reduced from 10
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    SizedBox(width: 10), // Reduced from 12
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onRetake,
                        icon: Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                        label: Text(
                          'Retake',
                          style: TextStyle(
                            fontSize: 14, // Reduced from 16
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12), // Reduced from 14
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Bottom padding for keyboard clearance
                SizedBox(height: 40), // Reduced from 60
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isImportant = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isImportant ? 13 : 12,
                fontWeight: isImportant ? FontWeight.w700 : FontWeight.w600,
                color: isImportant ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 80) return Colors.green;
    if (confidence >= 60) return Colors.orange;
    return Colors.red;
  }

  void _handleSubmit(BatchMatch match, TextEditingController controller) {
    final quantity = int.tryParse(controller.text) ?? 0;
    if (quantity > 0) {
      widget.onSubmit(match, quantity);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid quantity'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
