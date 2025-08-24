class BatchModel {
  final String id;
  final String batchId;
  final String sessionId;
  final String? productName; // legacy
  final String? itemName; // new API field
  final String? manufacturingDate;
  final String? expiryDate;
  final String? batchNumber;
  final String? lotNumber;
  final String? manufacturer;
  final String? status;
  final bool isFavorite;
  final DateTime scannedAt;
  final Map<String, dynamic>? additionalInfo;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BatchModel({
    String? id,
    required this.batchId,
    required this.sessionId,
  this.productName,
  this.itemName,
    this.manufacturingDate,
    this.expiryDate,
    this.batchNumber,
    this.lotNumber,
    this.manufacturer,
    this.status = 'Active',
    this.isFavorite = false,
    DateTime? scannedAt,
    this.additionalInfo,
    DateTime? createdAt,
    this.updatedAt,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       scannedAt = scannedAt ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  // Factory constructor from JSON (legacy format)
  factory BatchModel.fromJson(Map<String, dynamic> json, String sessionId) {
    return BatchModel(
      id: json['id']?.toString(),
      batchId: json['batch_id']?.toString() ?? '',
      sessionId: sessionId,
  productName: json['product_name']?.toString(),
  itemName: json['item_name']?.toString(),
      manufacturingDate: json['manufacturing_date']?.toString(),
      expiryDate: json['expiry_date']?.toString(),
  batchNumber: json['batch_number']?.toString() ?? json['batch_id']?.toString(),
      lotNumber: json['lot_number']?.toString(),
      manufacturer: json['manufacturer']?.toString(),
      status: json['status']?.toString() ?? 'Active',
      isFavorite: json['is_favorite'] as bool? ?? false,
      scannedAt: json['scanned_at'] != null 
        ? DateTime.tryParse(json['scanned_at'].toString()) ?? DateTime.now()
        : DateTime.now(),
      additionalInfo: json['additional_info'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null 
        ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
        : DateTime.now(),
      updatedAt: json['updated_at'] != null 
        ? DateTime.tryParse(json['updated_at'].toString())
        : null,
    );
  }

  // Factory constructor from new API response format
  factory BatchModel.fromNewApiResponse(String batchNumber, Map<String, dynamic> batchData, String sessionId) {
    return BatchModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      batchId: batchNumber,
      sessionId: sessionId,
      itemName: batchData['item_name']?.toString(),
      expiryDate: batchData['expiry_date']?.toString(),
      batchNumber: batchNumber,
      status: 'Active',
      scannedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batch_id': batchId,
      'session_id': sessionId,
      'product_name': productName,
      'item_name': itemName,
      'manufacturing_date': manufacturingDate,
      'expiry_date': expiryDate,
      'batch_number': batchNumber,
      'lot_number': lotNumber,
      'manufacturer': manufacturer,
      'status': status,
      'is_favorite': isFavorite,
      'scanned_at': scannedAt.toIso8601String(),
      'additional_info': additionalInfo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Convert to Map for local storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'batchId': batchId,
      'sessionId': sessionId,
      'productName': productName,
      'itemName': itemName,
      'manufacturingDate': manufacturingDate,
      'expiryDate': expiryDate,
      'batchNumber': batchNumber,
      'lotNumber': lotNumber,
      'manufacturer': manufacturer,
      'status': status,
      'isFavorite': isFavorite,
      'scannedAt': scannedAt.millisecondsSinceEpoch,
      'additionalInfo': additionalInfo,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  // Factory constructor from Map (local storage)
  factory BatchModel.fromMap(Map<String, dynamic> map) {
    return BatchModel(
      id: map['id'],
      batchId: map['batchId'] ?? '',
      sessionId: map['sessionId'] ?? '',
  productName: map['productName'],
  itemName: map['itemName'],
      manufacturingDate: map['manufacturingDate'],
      expiryDate: map['expiryDate'],
      batchNumber: map['batchNumber'],
      lotNumber: map['lotNumber'],
      manufacturer: map['manufacturer'],
      status: map['status'] ?? 'Active',
      isFavorite: map['isFavorite'] ?? false,
      scannedAt: DateTime.fromMillisecondsSinceEpoch(map['scannedAt'] ?? DateTime.now().millisecondsSinceEpoch),
      additionalInfo: map['additionalInfo'] != null 
          ? Map<String, dynamic>.from(map['additionalInfo']) 
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt']) 
          : null,
    );
  }

  // Helper methods
  bool get isExpired {
    if (expiryDate == null) return false;
    try {
      final expiry = DateTime.parse(expiryDate!);
      return expiry.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  int get daysUntilExpiry {
    if (expiryDate == null) return -1;
    try {
      final expiry = DateTime.parse(expiryDate!);
      final difference = expiry.difference(DateTime.now());
      return difference.inDays;
    } catch (e) {
      return -1;
    }
  }

  String get expiryStatus {
    if (expiryDate == null) return 'Unknown';
    final days = daysUntilExpiry;
    if (days < 0) return 'Expired';
    if (days == 0) return 'Expires Today';
    if (days <= 30) return 'Expires in $days days';
    return 'Valid';
  }

  bool get hasCompleteInfo {
    return batchId.isNotEmpty &&
           productName != null &&
           expiryDate != null &&
           lotNumber != null;
  }

  String get displayName {
    if (itemName != null && itemName!.isNotEmpty) {
      return itemName!;
    }
    if (productName != null && productName!.isNotEmpty) {
      return productName!;
    }
    if (lotNumber != null && lotNumber!.isNotEmpty) {
      return 'Lot: $lotNumber';
    }
    return 'Batch: $batchId';
  }

  // Copy with method
  BatchModel copyWith({
    String? batchId,
    String? sessionId,
    String? productName,
    String? manufacturingDate,
    String? expiryDate,
    String? lotNumber,
    String? manufacturer,
    Map<String, dynamic>? additionalInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BatchModel(
      batchId: batchId ?? this.batchId,
      sessionId: sessionId ?? this.sessionId,
      productName: productName ?? this.productName,
      manufacturingDate: manufacturingDate ?? this.manufacturingDate,
      expiryDate: expiryDate ?? this.expiryDate,
      lotNumber: lotNumber ?? this.lotNumber,
      manufacturer: manufacturer ?? this.manufacturer,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'BatchModel(batchId: $batchId, sessionId: $sessionId, productName: $productName, expiryDate: $expiryDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BatchModel &&
           other.batchId == batchId &&
           other.sessionId == sessionId;
  }

  @override
  int get hashCode => batchId.hashCode ^ sessionId.hashCode;
}
