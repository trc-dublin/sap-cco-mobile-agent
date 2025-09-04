import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/scan_item.dart';
import '../providers/scanner_provider.dart';
import '../providers/settings_provider.dart';

class ScanHistoryList extends StatelessWidget {
  final List<ScanItem> items;

  const ScanHistoryList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, HH:mm');
    
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          child: ListTile(
            leading: _buildStatusIcon(item.status),
            title: Text(
              item.itemName ?? item.barcode,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Barcode: ${item.barcode}'),
                Text('Quantity: ${item.quantity}'),
                Text(dateFormat.format(item.timestamp)),
                if (item.errorMessage != null)
                  Text(
                    item.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            trailing: _buildTrailingWidget(context, item),
            onTap: () => _showItemDetails(context, item),
          ),
        );
      },
    );
  }

  Widget _buildStatusIcon(ScanStatus status) {
    switch (status) {
      case ScanStatus.success:
        return const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.check, color: Colors.white),
        );
      case ScanStatus.error:
        return const CircleAvatar(
          backgroundColor: Colors.red,
          child: Icon(Icons.error, color: Colors.white),
        );
      case ScanStatus.pending:
        return const CircleAvatar(
          backgroundColor: Colors.orange,
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        );
    }
  }

  Widget _buildTrailingWidget(BuildContext context, ScanItem item) {
    if (item.status == ScanStatus.error) {
      return IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: () {
          final scannerProvider = context.read<ScannerProvider>();
          final settings = context.read<SettingsProvider>();
          scannerProvider.retryItem(item, settings.apiBaseUrl);
        },
      );
    }
    return PopupMenuButton<String>(
      onSelected: (value) => _handleMenuAction(context, value, item),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit),
              SizedBox(width: 8),
              Text('Edit Quantity'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete),
              SizedBox(width: 8),
              Text('Delete'),
            ],
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(BuildContext context, String action, ScanItem item) {
    switch (action) {
      case 'edit':
        _showEditQuantityDialog(context, item);
        break;
      case 'delete':
        context.read<ScannerProvider>().removeItem(item);
        break;
    }
  }

  void _showItemDetails(BuildContext context, ScanItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.itemName ?? 'Item Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow('Barcode', item.barcode),
            _DetailRow('Quantity', item.quantity.toString()),
            _DetailRow('Status', item.status.name.toUpperCase()),
            _DetailRow('Timestamp', DateFormat('yyyy-MM-dd HH:mm:ss').format(item.timestamp)),
            if (item.description != null)
              _DetailRow('Description', item.description!),
            if (item.errorMessage != null)
              _DetailRow('Error', item.errorMessage!, isError: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditQuantityDialog(BuildContext context, ScanItem item) {
    final controller = TextEditingController(text: item.quantity.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Quantity'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Quantity',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final quantity = int.tryParse(controller.text);
              if (quantity != null && quantity > 0) {
                context.read<ScannerProvider>().updateItemQuantity(item, quantity);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isError;

  const _DetailRow(this.label, this.value, {this.isError = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isError ? Theme.of(context).colorScheme.error : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}