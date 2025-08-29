import 'rack_model.dart';

class SessionDetailsModel {
  final String unitCode;
  final String storeId;
  final String salesOrderNumber;
  final String purchaseOrderNumber;
  final List<RackModel> racks;
  final String sessionId;
  final DateTime loadedAt;

  SessionDetailsModel({
    required this.unitCode,
    required this.storeId,
    required this.salesOrderNumber,
    required this.purchaseOrderNumber,
    required this.racks,
    required this.sessionId,
    DateTime? loadedAt,
  }) : loadedAt = loadedAt ?? DateTime.now();

  // Factory constructor from JSON
  factory SessionDetailsModel.fromJson(Map<String, dynamic> json, String sessionId) {
    return SessionDetailsModel(
      unitCode: json['unitCode'] ?? '',
      storeId: json['storeId'] ?? '',
      salesOrderNumber: json['salesOrderNumber'] ?? '',
      purchaseOrderNumber: json['purchaseOrderNumber'] ?? '',
      sessionId: sessionId,
      racks: (json['racks'] as List<dynamic>?)
          ?.map((rack) => RackModel.fromJson(rack))
          .toList() ?? [],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'unitCode': unitCode,
      'storeId': storeId,
      'salesOrderNumber': salesOrderNumber,
      'purchaseOrderNumber': purchaseOrderNumber,
      'racks': racks.map((rack) => rack.toJson()).toList(),
      'sessionId': sessionId,
      'loadedAt': loadedAt.toIso8601String(),
    };
  }

  // Get rack by name
  RackModel? getRackByName(String rackName) {
    try {
      return racks.firstWhere((rack) => rack.rackName == rackName);
    } catch (e) {
      return null;
    }
  }

  // Get all rack names
  List<String> get rackNames {
    return racks.map((rack) => rack.rackName).toList();
  }

  // Get first rack (default selection)
  RackModel? get firstRack {
    return racks.isNotEmpty ? racks.first : null;
  }

  // Get total items across all racks
  int get totalItems {
    return racks.fold(0, (sum, rack) => sum + rack.items.length);
  }

  // Get total available items across all racks
  int get totalAvailableItems {
    return racks.fold(0, (sum, rack) => sum + rack.availableItems.length);
  }

  // Get total submitted items across all racks
  int get totalSubmittedItems {
    return racks.fold(0, (sum, rack) => sum + rack.submittedItems.length);
  }

  // Update rack with submitted item
  SessionDetailsModel submitItemInRack(String rackName, ItemModel item) {
    final updatedRacks = racks.map((rack) {
      if (rack.rackName == rackName) {
        return rack.submitItem(item);
      }
      return rack;
    }).toList();

    return copyWith(racks: updatedRacks);
  }

  // Get summary statistics
  Map<String, dynamic> get summaryStats {
    int totalBatches = 0;
    int expiredBatches = 0;
    int expiringSoonBatches = 0;

    for (final rack in racks) {
      for (final item in rack.items) {
        totalBatches += item.batches.length;
        expiredBatches += item.expiredBatches.length;
        expiringSoonBatches += item.batchesExpiringSoon.length;
      }
    }

    return {
      'totalRacks': racks.length,
      'totalItems': totalItems,
      'totalAvailableItems': totalAvailableItems,
      'totalSubmittedItems': totalSubmittedItems,
      'totalBatches': totalBatches,
      'expiredBatches': expiredBatches,
      'expiringSoonBatches': expiringSoonBatches,
    };
  }

  // Copy with method
  SessionDetailsModel copyWith({
    String? unitCode,
    String? storeId,
    String? salesOrderNumber,
    String? purchaseOrderNumber,
    List<RackModel>? racks,
    String? sessionId,
    DateTime? loadedAt,
  }) {
    return SessionDetailsModel(
      unitCode: unitCode ?? this.unitCode,
      storeId: storeId ?? this.storeId,
      salesOrderNumber: salesOrderNumber ?? this.salesOrderNumber,
      purchaseOrderNumber: purchaseOrderNumber ?? this.purchaseOrderNumber,
      racks: racks ?? this.racks,
      sessionId: sessionId ?? this.sessionId,
      loadedAt: loadedAt ?? this.loadedAt,
    );
  }

  @override
  String toString() {
    return 'SessionDetailsModel(sessionId: $sessionId, racks: ${racks.length}, totalItems: $totalItems)';
  }
}
