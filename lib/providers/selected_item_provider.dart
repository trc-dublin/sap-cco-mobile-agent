import 'package:flutter/material.dart';
import '../models/receipt_models.dart';

class SelectedItemProvider extends ChangeNotifier {
  ReceiptItem? _selectedItem;
  String? _selectionContext;
  DateTime? _selectionTime;

  ReceiptItem? get selectedItem => _selectedItem;
  String? get selectionContext => _selectionContext;
  DateTime? get selectionTime => _selectionTime;
  bool get hasSelectedItem => _selectedItem != null;

  void selectItem(ReceiptItem item, {String context = 'transaction'}) {
    _selectedItem = item;
    _selectionContext = context;
    _selectionTime = DateTime.now();
    notifyListeners();
  }

  void clearSelection() {
    _selectedItem = null;
    _selectionContext = null;
    _selectionTime = null;
    notifyListeners();
  }

  Map<String, dynamic> getSelectedItemContext() {
    if (_selectedItem == null) return {};

    return {
      'selectedItem': {
        'itemCode': _selectedItem!.itemCode,
        'description': _selectedItem!.description,
        'quantity': _selectedItem!.quantity,
        'price': _selectedItem!.price,
        'discount': _selectedItem!.discount,
        'totalLineAmount': _selectedItem!.totalLineAmount,
      },
      'selectionContext': _selectionContext,
      'selectionTime': _selectionTime?.toIso8601String(),
      'contextMessage': _generateContextMessage(),
    };
  }

  String _generateContextMessage() {
    if (_selectedItem == null) return '';

    final timeAgo = _selectionTime != null 
        ? _formatTimeAgo(DateTime.now().difference(_selectionTime!))
        : '';

    return 'Currently discussing: ${_selectedItem!.description} '
           '(SKU: ${_selectedItem!.itemCode}, Qty: ${_selectedItem!.quantity}, '
           'Price: \$${_selectedItem!.price.toStringAsFixed(2)}) '
           'selected from $_selectionContext $timeAgo.';
  }

  String _formatTimeAgo(Duration difference) {
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String getDisplayText() {
    if (_selectedItem == null) return 'No item selected';
    
    return '${_selectedItem!.description} (${_selectedItem!.itemCode})';
  }
}