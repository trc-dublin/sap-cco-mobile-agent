import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scanner_provider.dart';
import '../providers/settings_provider.dart';
import '../models/scan_item.dart';

class ManualEntryDialog extends StatefulWidget {
  const ManualEntryDialog({super.key});

  @override
  State<ManualEntryDialog> createState() => _ManualEntryDialogState();
}

class _ManualEntryDialogState extends State<ManualEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _itemCodeController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  
  int _selectedInputType = 0;
  final List<String> _inputTypes = ['Item Code', 'Barcode', 'Description Search'];

  @override
  void dispose() {
    _itemCodeController.dispose();
    _barcodeController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final scannerProvider = context.read<ScannerProvider>();
      final settings = context.read<SettingsProvider>();

      String code = '';
      switch (_selectedInputType) {
        case 0:
          code = _itemCodeController.text;
          break;
        case 1:
          code = _barcodeController.text;
          break;
        case 2:
          code = _descriptionController.text;
          break;
      }

      final item = ScanItem(
        barcode: code,
        timestamp: DateTime.now(),
        quantity: int.tryParse(_quantityController.text) ?? 1,
        description: _selectedInputType == 2 ? _descriptionController.text : null,
      );

      Navigator.of(context).pop();
      await scannerProvider.addItem(item, settings.apiBaseUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manual Entry'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<int>(
                segments: _inputTypes.asMap().entries.map((entry) {
                  return ButtonSegment(
                    value: entry.key,
                    label: Text(entry.value, style: const TextStyle(fontSize: 12)),
                  );
                }).toList(),
                selected: {_selectedInputType},
                onSelectionChanged: (Set<int> newSelection) {
                  setState(() {
                    _selectedInputType = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_selectedInputType == 0)
                TextFormField(
                  controller: _itemCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Item Code',
                    border: OutlineInputBorder(),
                    hintText: 'Enter item code',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an item code';
                    }
                    return null;
                  },
                ),
              if (_selectedInputType == 1)
                TextFormField(
                  controller: _barcodeController,
                  decoration: const InputDecoration(
                    labelText: 'Barcode Number',
                    border: OutlineInputBorder(),
                    hintText: 'Enter barcode number',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a barcode number';
                    }
                    return null;
                  },
                ),
              if (_selectedInputType == 2)
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Item Description',
                    border: OutlineInputBorder(),
                    hintText: 'Enter partial description',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    if (value.length < 3) {
                      return 'Description must be at least 3 characters';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter quantity';
                  }
                  final quantity = int.tryParse(value);
                  if (quantity == null || quantity <= 0) {
                    return 'Please enter a valid quantity';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Add Item'),
        ),
      ],
    );
  }
}