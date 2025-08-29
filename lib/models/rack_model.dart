class RackModel {
  final String rackName;
  final List<ItemModel> items;
  final List<ItemModel> submittedItems;

  RackModel({
    required this.rackName,
    required this.items,
    List<ItemModel>? submittedItems,
  }) : submittedItems = submittedItems ?? [];

  // Factory constructor from JSON
  factory RackModel.fromJson(Map<String, dynamic> json) {
    return RackModel(
      rackName: json['rackName'] ?? '',
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => ItemModel.fromJson(item))
          .toList() ?? [],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'rackName': rackName,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  // Get available (not submitted) items
  List<ItemModel> get availableItems {
    final submittedItemNames = submittedItems.map((item) => item.itemName).toSet();
    return items.where((item) => !submittedItemNames.contains(item.itemName)).toList();
  }

  // Check if item is submitted
  bool isItemSubmitted(String itemName) {
    return submittedItems.any((item) => item.itemName == itemName);
  }

  // Move item to submitted
  RackModel submitItem(ItemModel item) {
    if (isItemSubmitted(item.itemName)) {
      return this; // Already submitted
    }
    
    return RackModel(
      rackName: rackName,
      items: items,
      submittedItems: [...submittedItems, item],
    );
  }

  // Copy with method
  RackModel copyWith({
    String? rackName,
    List<ItemModel>? items,
    List<ItemModel>? submittedItems,
  }) {
    return RackModel(
      rackName: rackName ?? this.rackName,
      items: items ?? this.items,
      submittedItems: submittedItems ?? this.submittedItems,
    );
  }

  @override
  String toString() {
    return 'RackModel(rackName: $rackName, items: ${items.length}, submitted: ${submittedItems.length})';
  }
}

class ItemModel {
  final String itemName;
  final int quantity;
  final List<BatchInfo> batches;

  ItemModel({
    required this.itemName,
    required this.quantity,
    required this.batches,
  });

  // Factory constructor from JSON
  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      itemName: json['itemName'] ?? '',
      quantity: json['quantity'] ?? 0,
      batches: (json['batches'] as List<dynamic>?)
          ?.map((batch) => BatchInfo.fromJson(batch))
          .toList() ?? [],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'itemName': itemName,
      'quantity': quantity,
      'batches': batches.map((batch) => batch.toJson()).toList(),
    };
  }

  // Get batch numbers for matching
  List<String> get batchNumbers {
    return batches.map((batch) => batch.batchNumber).toList();
  }

  // Get expiry dates for matching
  List<String> get expiryDates {
    return batches.map((batch) => batch.expiryDate).toList();
  }

  // Get batches expiring soon (within 30 days)
  List<BatchInfo> get batchesExpiringSoon {
    final now = DateTime.now();
    return batches.where((batch) {
      try {
        final expiryDate = DateTime.parse(batch.expiryDate);
        final difference = expiryDate.difference(now).inDays;
        return difference <= 30 && difference >= 0;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  // Get expired batches
  List<BatchInfo> get expiredBatches {
    final now = DateTime.now();
    return batches.where((batch) {
      try {
        final expiryDate = DateTime.parse(batch.expiryDate);
        return expiryDate.isBefore(now);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  @override
  String toString() {
    return 'ItemModel(itemName: $itemName, quantity: $quantity, batches: ${batches.length})';
  }
}

class BatchInfo {
  final String batchNumber;
  final String expiryDate;

  BatchInfo({
    required this.batchNumber,
    required this.expiryDate,
  });

  // Factory constructor from JSON
  factory BatchInfo.fromJson(Map<String, dynamic> json) {
    return BatchInfo(
      batchNumber: json['batchNumber'] ?? '',
      expiryDate: json['expiryDate'] ?? '',
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'batchNumber': batchNumber,
      'expiryDate': expiryDate,
    };
  }

  // Check if batch is expired
  bool get isExpired {
    try {
      final expiryDateTime = DateTime.parse(expiryDate);
      return expiryDateTime.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  // Check if batch is expiring soon (within 30 days)
  bool get isExpiringSoon {
    try {
      final expiryDateTime = DateTime.parse(expiryDate);
      final difference = expiryDateTime.difference(DateTime.now()).inDays;
      return difference <= 30 && difference >= 0;
    } catch (e) {
      return false;
    }
  }

  // Get days until expiry
  int get daysUntilExpiry {
    try {
      final expiryDateTime = DateTime.parse(expiryDate);
      return expiryDateTime.difference(DateTime.now()).inDays;
    } catch (e) {
      return -1;
    }
  }

  @override
  String toString() {
    return 'BatchInfo(batchNumber: $batchNumber, expiryDate: $expiryDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BatchInfo &&
           other.batchNumber == batchNumber &&
           other.expiryDate == expiryDate;
  }

  @override
  int get hashCode => batchNumber.hashCode ^ expiryDate.hashCode;
}
