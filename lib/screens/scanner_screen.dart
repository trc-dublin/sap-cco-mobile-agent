import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/scanner_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/manual_entry_dialog.dart';
import '../widgets/scan_history_list.dart';
import '../models/scan_item.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  MobileScannerController? _scannerController;
  bool _isScanning = false;
  bool _torchEnabled = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeScanner();
  }

  void _initializeScanner() {
    _scannerController = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false,
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 1000,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  void _handleBarcodeDetection(BarcodeCapture capture) async {
    if (!_isScanning && capture.barcodes.isNotEmpty) {
      setState(() {
        _isScanning = true;
      });

      final barcode = capture.barcodes.first;
      if (barcode.rawValue != null) {
        final settings = context.read<SettingsProvider>();
        if (settings.vibrationEnabled) {
          // Add vibration feedback
        }
        if (settings.scanSoundEnabled) {
          // Play scan sound
        }

        await _processBarcode(barcode.rawValue!);
      }

      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _processBarcode(String barcode) async {
    final scannerProvider = context.read<ScannerProvider>();
    final settings = context.read<SettingsProvider>();
    
    final item = ScanItem(
      barcode: barcode,
      timestamp: DateTime.now(),
      quantity: settings.defaultQuantity,
    );

    await scannerProvider.addItem(item, settings.apiBaseUrl);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item scanned: $barcode'),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Adjust Quantity',
            onPressed: () => _showQuantityDialog(item),
          ),
        ),
      );
    }
  }

  void _showQuantityDialog(ScanItem item) {
    showDialog(
      context: context,
      builder: (context) => QuantityAdjustmentDialog(item: item),
    );
  }

  void _showManualEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => const ManualEntryDialog(),
    );
  }

  void _toggleTorch() {
    setState(() {
      _torchEnabled = !_torchEnabled;
    });
    _scannerController?.toggleTorch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Scan', icon: Icon(Icons.camera_alt)),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_torchEnabled ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleTorch,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildScannerView(),
          _buildHistoryView(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _showManualEntryDialog,
              label: const Text('Manual Entry'),
              icon: const Icon(Icons.keyboard),
            )
          : null,
    );
  }

  Widget _buildScannerView() {
    return Consumer<ScannerProvider>(
      builder: (context, scannerProvider, child) {
        return Stack(
          children: [
            if (_scannerController != null)
              MobileScanner(
                controller: _scannerController!,
                onDetect: _handleBarcodeDetection,
              )
            else
              const Center(
                child: CircularProgressIndicator(),
              ),
            if (_isScanning)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Processing barcode...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Items scanned: ${scannerProvider.scanHistory.length}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (scannerProvider.lastScanError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            scannerProvider.lastScanError!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHistoryView() {
    return Consumer<ScannerProvider>(
      builder: (context, scannerProvider, child) {
        if (scannerProvider.scanHistory.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No scan history yet'),
              ],
            ),
          );
        }
        return ScanHistoryList(items: scannerProvider.scanHistory);
      },
    );
  }
}

class QuantityAdjustmentDialog extends StatefulWidget {
  final ScanItem item;

  const QuantityAdjustmentDialog({super.key, required this.item});

  @override
  State<QuantityAdjustmentDialog> createState() => _QuantityAdjustmentDialogState();
}

class _QuantityAdjustmentDialogState extends State<QuantityAdjustmentDialog> {
  late TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: widget.item.quantity.toString());
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adjust Quantity'),
      content: TextField(
        controller: _quantityController,
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
            final quantity = int.tryParse(_quantityController.text);
            if (quantity != null && quantity > 0) {
              context.read<ScannerProvider>().updateItemQuantity(widget.item, quantity);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}