import 'dart:typed_data';
import 'package:flutter/material.dart';

/// ESC/POS Commands for thermal printers
class EscPosCommands {
  // Initialize printer
  static final Uint8List init = Uint8List.fromList([0x1B, 0x40]);
  
  // Text formatting
  static final Uint8List alignLeft = Uint8List.fromList([0x1B, 0x61, 0x00]);
  static final Uint8List alignCenter = Uint8List.fromList([0x1B, 0x61, 0x01]);
  static final Uint8List alignRight = Uint8List.fromList([0x1B, 0x61, 0x02]);
  
  static final Uint8List boldOn = Uint8List.fromList([0x1B, 0x45, 0x01]);
  static final Uint8List boldOff = Uint8List.fromList([0x1B, 0x45, 0x00]);
  
  static final Uint8List doubleHeight = Uint8List.fromList([0x1B, 0x21, 0x10]);
  static final Uint8List doubleWidth = Uint8List.fromList([0x1B, 0x21, 0x20]);
  static final Uint8List normalSize = Uint8List.fromList([0x1B, 0x21, 0x00]);
  static final Uint8List largeSize = Uint8List.fromList([0x1B, 0x21, 0x30]);
  
  // Paper
  static final Uint8List feedLine = Uint8List.fromList([0x0A]);
  static final Uint8List feedLines3 = Uint8List.fromList([0x1B, 0x64, 0x03]);
  static final Uint8List feedLines5 = Uint8List.fromList([0x1B, 0x64, 0x05]);
  static final Uint8List cut = Uint8List.fromList([0x1D, 0x56, 0x00]);
  static final Uint8List partialCut = Uint8List.fromList([0x1D, 0x56, 0x01]);
  
  // Drawer
  static final Uint8List openDrawer = Uint8List.fromList([0x1B, 0x70, 0x00, 0x19, 0xFA]);
}

/// Receipt line item
class ReceiptItem {
  final String name;
  final int quantity;
  final double price;
  final double total;
  
  ReceiptItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.total,
  });
}

/// Receipt data model
class Receipt {
  final String storeName;
  final String storeAddress;
  final String orderNumber;
  final DateTime dateTime;
  final List<ReceiptItem> items;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final double cashReceived;
  final double change;
  final String paymentMethod;
  final String? customerName;
  final String? cashierName;
  
  Receipt({
    required this.storeName,
    required this.storeAddress,
    required this.orderNumber,
    required this.dateTime,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.total,
    required this.cashReceived,
    required this.change,
    required this.paymentMethod,
    this.customerName,
    this.cashierName,
  });
}

/// Printer service for ESC/POS thermal printers
class PrinterService {
  // Simulated printer status
  bool _isConnected = false;
  String? _printerName;
  
  bool get isConnected => _isConnected;
  String? get printerName => _printerName;
  
  /// Build receipt bytes for ESC/POS printer
  Uint8List buildReceiptBytes(Receipt receipt) {
    final bytes = BytesBuilder();
    
    // Initialize
    bytes.add(EscPosCommands.init);
    
    // Store Header
    bytes.add(EscPosCommands.alignCenter);
    bytes.add(EscPosCommands.largeSize);
    bytes.add(_textToBytes(receipt.storeName));
    bytes.add(EscPosCommands.feedLine);
    
    bytes.add(EscPosCommands.normalSize);
    bytes.add(_textToBytes(receipt.storeAddress));
    bytes.add(EscPosCommands.feedLine);
    bytes.add(EscPosCommands.feedLine);
    
    // Order Info
    bytes.add(EscPosCommands.alignLeft);
    bytes.add(_textToBytes('Order: #${receipt.orderNumber}'));
    bytes.add(EscPosCommands.feedLine);
    bytes.add(_textToBytes('Date: ${_formatDate(receipt.dateTime)}'));
    bytes.add(EscPosCommands.feedLine);
    bytes.add(_textToBytes('Time: ${_formatTime(receipt.dateTime)}'));
    bytes.add(EscPosCommands.feedLine);
    if (receipt.cashierName != null) {
      bytes.add(_textToBytes('Cashier: ${receipt.cashierName}'));
      bytes.add(EscPosCommands.feedLine);
    }
    if (receipt.customerName != null) {
      bytes.add(_textToBytes('Customer: ${receipt.customerName}'));
      bytes.add(EscPosCommands.feedLine);
    }
    
    // Separator
    bytes.add(_textToBytes('--------------------------------'));
    bytes.add(EscPosCommands.feedLine);
    
    // Items
    for (final item in receipt.items) {
      // Item name
      bytes.add(_textToBytes(item.name));
      bytes.add(EscPosCommands.feedLine);
      
      // Qty x Price = Total (right aligned math)
      final qtyPrice = '  ${item.quantity} x ${_formatCurrency(item.price)}';
      final total = _formatCurrency(item.total);
      final spaces = 32 - qtyPrice.length - total.length;
      bytes.add(_textToBytes('$qtyPrice${' ' * (spaces > 0 ? spaces : 1)}$total'));
      bytes.add(EscPosCommands.feedLine);
    }
    
    // Separator
    bytes.add(_textToBytes('--------------------------------'));
    bytes.add(EscPosCommands.feedLine);
    
    // Totals
    bytes.add(_buildTotalLine('Subtotal', receipt.subtotal));
    if (receipt.discount > 0) {
      bytes.add(_buildTotalLine('Discount', -receipt.discount));
    }
    bytes.add(_buildTotalLine('Tax (11%)', receipt.tax));
    bytes.add(EscPosCommands.feedLine);
    
    // Grand Total
    bytes.add(EscPosCommands.boldOn);
    bytes.add(EscPosCommands.doubleHeight);
    bytes.add(_buildTotalLine('TOTAL', receipt.total));
    bytes.add(EscPosCommands.normalSize);
    bytes.add(EscPosCommands.boldOff);
    bytes.add(EscPosCommands.feedLine);
    
    // Payment
    bytes.add(_textToBytes('Payment: ${receipt.paymentMethod}'));
    bytes.add(EscPosCommands.feedLine);
    if (receipt.paymentMethod == 'Cash') {
      bytes.add(_buildTotalLine('Cash', receipt.cashReceived));
      bytes.add(_buildTotalLine('Change', receipt.change));
    }
    
    // Footer
    bytes.add(EscPosCommands.feedLine);
    bytes.add(EscPosCommands.alignCenter);
    bytes.add(_textToBytes('--------------------------------'));
    bytes.add(EscPosCommands.feedLine);
    bytes.add(_textToBytes('Thank you for shopping!'));
    bytes.add(EscPosCommands.feedLine);
    bytes.add(_textToBytes('Please come again'));
    bytes.add(EscPosCommands.feedLine);
    
    // Feed and cut
    bytes.add(EscPosCommands.feedLines5);
    bytes.add(EscPosCommands.partialCut);
    
    return bytes.toBytes();
  }
  
  Uint8List _buildTotalLine(String label, double amount) {
    final builder = BytesBuilder();
    final amountStr = _formatCurrency(amount);
    final spaces = 32 - label.length - amountStr.length;
    builder.add(_textToBytes('$label${' ' * (spaces > 0 ? spaces : 1)}$amountStr'));
    builder.add(EscPosCommands.feedLine);
    return builder.toBytes();
  }
  
  Uint8List _textToBytes(String text) {
    return Uint8List.fromList(text.codeUnits);
  }
  
  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
  
  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
  
  String _formatCurrency(double amount) {
    if (amount < 0) {
      return '-Rp ${(-amount).toStringAsFixed(0)}';
    }
    return 'Rp ${amount.toStringAsFixed(0)}';
  }
  
  /// Simulate printer connection (for demo)
  Future<bool> connectPrinter(String printerName) async {
    // In real implementation, this would use flutter_blue_plus or similar
    await Future.delayed(const Duration(seconds: 1));
    _isConnected = true;
    _printerName = printerName;
    return true;
  }
  
  /// Disconnect printer
  Future<void> disconnectPrinter() async {
    _isConnected = false;
    _printerName = null;
  }
  
  /// Print receipt (simulated for demo)
  Future<bool> printReceipt(Receipt receipt) async {
    if (!_isConnected) {
      debugPrint('Printer not connected');
      return false;
    }
    
    final bytes = buildReceiptBytes(receipt);
    debugPrint('Printing ${bytes.length} bytes to $_printerName');
    
    // In real implementation, send bytes via Bluetooth
    await Future.delayed(const Duration(seconds: 2));
    
    return true;
  }
  
  /// Open cash drawer
  Future<bool> openCashDrawer() async {
    if (!_isConnected) return false;
    
    // Send drawer open command
    debugPrint('Opening cash drawer');
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }
  
  /// Get preview text of receipt (for screen display)
  String getReceiptPreview(Receipt receipt) {
    final buffer = StringBuffer();
    
    buffer.writeln('================================');
    buffer.writeln('        ${receipt.storeName}');
    buffer.writeln('     ${receipt.storeAddress}');
    buffer.writeln('================================');
    buffer.writeln('Order: #${receipt.orderNumber}');
    buffer.writeln('Date: ${_formatDate(receipt.dateTime)}');
    buffer.writeln('Time: ${_formatTime(receipt.dateTime)}');
    if (receipt.cashierName != null) {
      buffer.writeln('Cashier: ${receipt.cashierName}');
    }
    buffer.writeln('--------------------------------');
    
    for (final item in receipt.items) {
      buffer.writeln(item.name);
      final qtyPrice = '  ${item.quantity} x ${_formatCurrency(item.price)}';
      final total = _formatCurrency(item.total);
      buffer.writeln('$qtyPrice${' ' * (20 - qtyPrice.length)}$total');
    }
    
    buffer.writeln('--------------------------------');
    buffer.writeln('Subtotal:          ${_formatCurrency(receipt.subtotal)}');
    if (receipt.discount > 0) {
      buffer.writeln('Discount:         -${_formatCurrency(receipt.discount)}');
    }
    buffer.writeln('Tax (11%):          ${_formatCurrency(receipt.tax)}');
    buffer.writeln('================================');
    buffer.writeln('TOTAL:             ${_formatCurrency(receipt.total)}');
    buffer.writeln('================================');
    buffer.writeln('Payment: ${receipt.paymentMethod}');
    if (receipt.paymentMethod == 'Cash') {
      buffer.writeln('Cash:              ${_formatCurrency(receipt.cashReceived)}');
      buffer.writeln('Change:            ${_formatCurrency(receipt.change)}');
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('     Thank you for shopping!');
    buffer.writeln('       Please come again');
    buffer.writeln('================================');
    
    return buffer.toString();
  }
}
