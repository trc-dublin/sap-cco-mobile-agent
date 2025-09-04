class ReceiptItem {
  final String itemCode;
  final String description;
  final double quantity;
  final double price;
  final double discount;
  final double totalLineAmount;

  const ReceiptItem({
    required this.itemCode,
    required this.description,
    required this.quantity,
    required this.price,
    required this.discount,
    required this.totalLineAmount,
  });

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      itemCode: json['itemCode'] as String,
      description: json['description'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      totalLineAmount: (json['totalLineAmount'] as num).toDouble(),
    );
  }
}

class CurrentReceiptResponse {
  final bool success;
  final String message;
  final String? receiptId;
  final List<ReceiptItem> items;
  final int itemCount;
  final double totalAmount;
  final int timestamp;

  const CurrentReceiptResponse({
    required this.success,
    required this.message,
    this.receiptId,
    required this.items,
    required this.itemCount,
    required this.totalAmount,
    required this.timestamp,
  });

  factory CurrentReceiptResponse.fromJson(Map<String, dynamic> json) {
    return CurrentReceiptResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      receiptId: json['receiptId'] as String?,
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => ReceiptItem.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      itemCount: json['itemCount'] as int,
      totalAmount: double.parse(json['totalAmount'].toString()),
      timestamp: json['timestamp'] as int,
    );
  }

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);
}