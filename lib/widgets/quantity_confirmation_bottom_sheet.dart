import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/scan_item.dart';

class QuantityConfirmationBottomSheet extends StatefulWidget {
  final ScanItem item;

  const QuantityConfirmationBottomSheet({super.key, required this.item});

  @override
  State<QuantityConfirmationBottomSheet> createState() => _QuantityConfirmationBottomSheetState();
}

class _QuantityConfirmationBottomSheetState extends State<QuantityConfirmationBottomSheet>
    with SingleTickerProviderStateMixin {
  late TextEditingController _quantityController;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: widget.item.quantity.toString());
    
    // Setup slide animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _incrementQuantity() {
    final currentValue = int.tryParse(_quantityController.text) ?? 1;
    _quantityController.text = (currentValue + 1).toString();
    HapticFeedback.lightImpact();
    _clearError();
  }

  void _decrementQuantity() {
    final currentValue = int.tryParse(_quantityController.text) ?? 1;
    if (currentValue > 1) {
      _quantityController.text = (currentValue - 1).toString();
      HapticFeedback.lightImpact();
      _clearError();
    }
  }

  void _setQuickQuantity(int quantity) {
    _quantityController.text = quantity.toString();
    HapticFeedback.selectionClick();
    _clearError();
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  Future<void> _onConfirm() async {
    final quantityText = _quantityController.text.trim();
    
    if (quantityText.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a quantity';
      });
      return;
    }

    final quantity = int.tryParse(quantityText);
    if (quantity == null || quantity <= 0) {
      setState(() {
        _errorMessage = 'Please enter a valid quantity (1 or more)';
      });
      return;
    }

    if (quantity > 9999) {
      setState(() {
        _errorMessage = 'Quantity cannot exceed 9999';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Update the item quantity
    widget.item.quantity = quantity;

    // Add a small delay for better UX
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _onCancel() async {
    HapticFeedback.lightImpact();
    
    // Slide down animation
    await _animationController.reverse();
    
    if (mounted) {
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: mediaQuery.size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Compact header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.qr_code_2,
                        size: 22,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Item Scanned',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Confirm quantity to add',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // Barcode display
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.qr_code,
                                    size: 16,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Barcode',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.item.barcode,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Quantity section title
                        Text(
                          'Enter Quantity',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Quantity controls
                        Row(
                          children: [
                            // Decrease button
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _decrementQuantity,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Icon(
                                    Icons.remove,
                                    color: theme.colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 16),
                            
                            // Quantity input
                            Expanded(
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _errorMessage != null 
                                        ? theme.colorScheme.error 
                                        : theme.colorScheme.outline,
                                    width: 2,
                                  ),
                                ),
                                child: TextField(
                                  controller: _quantityController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                  ],
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: '1',
                                  ),
                                  onChanged: (value) => _clearError(),
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 16),
                            
                            // Increase button
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _incrementQuantity,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Icon(
                                    Icons.add,
                                    color: theme.colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Quick select
                        Text(
                          'Quick Select',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [1, 5, 10, 25, 50, 100].map((qty) {
                            return SizedBox(
                              width: 50,
                              height: 40,
                              child: FilledButton.tonal(
                                onPressed: () => _setQuickQuantity(qty),
                                style: FilledButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  qty.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        
                        // Error message
                        if (_errorMessage != null)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: theme.colorScheme.onErrorContainer,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Fixed action buttons at bottom
              Container(
                padding: EdgeInsets.fromLTRB(20, 16, 20, mediaQuery.padding.bottom + 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // Add button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _onConfirm,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.colorScheme.onPrimary,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_shopping_cart,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Add to Inventory',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Cancel button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _onCancel,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}