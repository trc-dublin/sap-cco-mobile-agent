import 'package:flutter/foundation.dart';
import '../models/scan_item.dart';
import '../services/api_service.dart';

class ScannerProvider extends ChangeNotifier {
  final List<ScanItem> _scanHistory = [];
  bool _isProcessing = false;
  String? _lastScanError;
  final ApiService _apiService = ApiService();

  List<ScanItem> get scanHistory => List.unmodifiable(_scanHistory);
  bool get isProcessing => _isProcessing;
  String? get lastScanError => _lastScanError;

  Future<void> addItem(ScanItem item, String apiUrl) async {
    _isProcessing = true;
    _lastScanError = null;
    notifyListeners();

    try {
      final success = await _apiService.addItem(
        itemCode: item.barcode,
        quantity: item.quantity,
        apiUrl: apiUrl,
      );

      if (success) {
        _scanHistory.insert(0, item);
        item.status = ScanStatus.success;
      } else {
        item.status = ScanStatus.error;
        _lastScanError = 'Failed to add item to inventory';
      }
    } catch (e) {
      item.status = ScanStatus.error;
      _lastScanError = e.toString();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void updateItemQuantity(ScanItem item, int quantity) {
    final index = _scanHistory.indexOf(item);
    if (index != -1) {
      _scanHistory[index].quantity = quantity;
      notifyListeners();
    }
  }

  void removeItem(ScanItem item) {
    _scanHistory.remove(item);
    notifyListeners();
  }

  void clearHistory() {
    _scanHistory.clear();
    _lastScanError = null;
    notifyListeners();
  }

  void retryItem(ScanItem item, String apiUrl) async {
    item.status = ScanStatus.pending;
    notifyListeners();
    await addItem(item, apiUrl);
  }
}