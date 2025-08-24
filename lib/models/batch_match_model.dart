import 'batch_model.dart';

class BatchMatch {
  final String batchNumber;
  final String itemName;
  final String expiryDate;
  final double confidence;
  final int requestedQuantity;
  final int rank;
  final String? itemCode;
  final String? purchaseOrderNumber;
  final String? saleOrderNumber;

  BatchMatch({
    required this.batchNumber,
    required this.itemName,
    required this.expiryDate,
    required this.confidence,
    required this.requestedQuantity,
    required this.rank,
    this.itemCode,
    this.purchaseOrderNumber,
    this.saleOrderNumber,
  });

  factory BatchMatch.fromBatchModel(
    BatchModel batch,
    double confidence,
    int rank,
    int requestedQuantity,
    String? itemCode, {
    String? purchaseOrderNumber,
    String? saleOrderNumber,
  }) {
    return BatchMatch(
      batchNumber: batch.batchNumber ?? batch.batchId,
      itemName: batch.itemName ?? batch.productName ?? '',
      expiryDate: batch.expiryDate ?? '',
      confidence: confidence,
      rank: rank,
      requestedQuantity: requestedQuantity,
      itemCode: itemCode,
      purchaseOrderNumber: purchaseOrderNumber,
      saleOrderNumber: saleOrderNumber,
    );
  }

  String get rankDisplay {
    switch (rank) {
      case 1:
        return '1st';
      case 2:
        return '2nd';
      case 3:
        return '3rd';
      default:
        return '${rank}th';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'batchNumber': batchNumber,
      'itemName': itemName,
      'expiryDate': expiryDate,
      'confidence': confidence,
      'requestedQuantity': requestedQuantity,
      'rank': rank,
      'itemCode': itemCode,
      'purchaseOrderNumber': purchaseOrderNumber,
      'saleOrderNumber': saleOrderNumber,
    };
  }

  factory BatchMatch.fromJson(Map<String, dynamic> json) {
    return BatchMatch(
      batchNumber: json['batchNumber'] ?? '',
      itemName: json['itemName'] ?? '',
      expiryDate: json['expiryDate'] ?? '',
      confidence: (json['confidence'] ?? 0).toDouble(),
      requestedQuantity: json['requestedQuantity'] ?? 0,
      rank: json['rank'] ?? 1,
      itemCode: json['itemCode'],
      purchaseOrderNumber: json['purchaseOrderNumber'],
      saleOrderNumber: json['saleOrderNumber'],
    );
  }
}
