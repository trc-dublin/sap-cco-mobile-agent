enum ScanStatus { pending, success, error }

class ScanItem {
  final String id;
  final String barcode;
  final DateTime timestamp;
  int quantity;
  ScanStatus status;
  String? itemName;
  String? description;
  String? errorMessage;

  ScanItem({
    String? id,
    required this.barcode,
    required this.timestamp,
    this.quantity = 1,
    this.status = ScanStatus.pending,
    this.itemName,
    this.description,
    this.errorMessage,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barcode': barcode,
      'timestamp': timestamp.toIso8601String(),
      'quantity': quantity,
      'status': status.index,
      'itemName': itemName,
      'description': description,
      'errorMessage': errorMessage,
    };
  }

  factory ScanItem.fromJson(Map<String, dynamic> json) {
    return ScanItem(
      id: json['id'],
      barcode: json['barcode'],
      timestamp: DateTime.parse(json['timestamp']),
      quantity: json['quantity'] ?? 1,
      status: ScanStatus.values[json['status'] ?? 0],
      itemName: json['itemName'],
      description: json['description'],
      errorMessage: json['errorMessage'],
    );
  }
}