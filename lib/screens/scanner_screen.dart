import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/scanner_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/manual_entry_dialog.dart';
import '../widgets/scan_history_list.dart';
import '../widgets/quantity_confirmation_dialog.dart';
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
  bool _isScannerActive = false;
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
    if (!_isScanning && _isScannerActive && capture.barcodes.isNotEmpty) {
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

      // Auto-stop scanning after successful scan
      setState(() {
        _isScanning = false;
        _isScannerActive = false;
      });
    }
  }

  Future<void> _processBarcode(String barcode) async {
    final settings = context.read<SettingsProvider>();
    
    // Create item but don't submit yet
    final item = ScanItem(
      barcode: barcode,
      timestamp: DateTime.now(),
      quantity: settings.defaultQuantity,
    );

    // Show professional quantity confirmation dialog
    await _showQuantityConfirmationDialog(item);
  }

  Future<void> _showQuantityConfirmationDialog(ScanItem item) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => QuantityConfirmationDialog(item: item),
    );

    if (result == true && mounted) {
      // User confirmed, submit the item
      final scannerProvider = context.read<ScannerProvider>();
      final settings = context.read<SettingsProvider>();
      await scannerProvider.addItem(item, settings.apiBaseUrl);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item added: ${item.barcode} (Qty: ${item.quantity})'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
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

  void _startScanning() {
    setState(() {
      _isScannerActive = true;
    });
  }

  void _stopScanning() {
    setState(() {
      _isScannerActive = false;
      _isScanning = false;
    });
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
          ? null // We'll add the scan button directly in the scanner view
          : null,
    );
  }

  Widget _buildScannerView() {
    return Consumer<ScannerProvider>(
      builder: (context, scannerProvider, child) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Camera preview area
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          if (_scannerController != null && _isScannerActive)
                            MobileScanner(
                              controller: _scannerController!,
                              onDetect: _handleBarcodeDetection,
                            )
                          else
                            Container(
                              color: Colors.grey[900],
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.qr_code_scanner,
                                      size: 80,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _isScannerActive ? 'Initializing camera...' : 'Press scan button to start',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
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
                                      style: TextStyle(color: Colors.white, fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // Scanning overlay when active
                          if (_isScannerActive && !_isScanning)
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.green, width: 2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.green, width: 2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Place barcode here',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Scan status
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Items scanned: ${scannerProvider.scanHistory.length}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                if (scannerProvider.lastScanError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      scannerProvider.lastScanError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 16),
                // Action buttons
                Row(
                  children: [
                    // Big Scan Button
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isScanning 
                            ? null 
                            : (_isScannerActive ? _stopScanning : _startScanning),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isScannerActive 
                              ? Colors.red
                              : Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _isScannerActive ? 'STOP SCAN' : 'START SCAN',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Manual Entry Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _showManualEntryDialog,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Manual Entry',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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