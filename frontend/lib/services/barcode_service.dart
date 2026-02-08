import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Barcode scanner service for product lookup
class BarcodeService {
  // Barcode to Product ID mapping (simulated database)
  static final Map<String, String> _barcodeDatabase = {
    '8991234567890': '1',  // Fresh Whole Milk 1L
    '8991234567891': '2',  // Whole Wheat Bread
    '8991234567892': '3',  // Coca Cola 500ml
    '8991234567893': '4',  // Snickers Bar
    '8991234567894': '5',  // Dove Soap Bar
    '8991234567895': '6',  // Red Apples (kg)
    '8991234567896': '7',  // Lays Classic
    '8991234567897': '8',  // Head & Shoulders
    '8991234567898': '9',  // Tomato Soup Can
    '8991234567899': '10', // Mineral Water 1L
    '8991234567900': '11', // Rice 25kg
    '8991234567901': '12', // LPG Cylinder
    '8991234567902': '13', // Egg Tray (30)
  };

  /// Look up product ID by barcode
  static String? getProductIdByBarcode(String barcode) {
    return _barcodeDatabase[barcode];
  }

  /// Add new barcode mapping
  static void addBarcodeMapping(String barcode, String productId) {
    _barcodeDatabase[barcode] = productId;
  }

  /// Check if barcode exists
  static bool barcodeExists(String barcode) {
    return _barcodeDatabase.containsKey(barcode);
  }

  /// Get all barcodes for a product
  static List<String> getBarcodesForProduct(String productId) {
    return _barcodeDatabase.entries
        .where((entry) => entry.value == productId)
        .map((entry) => entry.key)
        .toList();
  }
}

/// Keyboard barcode scanner listener
/// Most USB barcode scanners act as keyboard input
class KeyboardBarcodeListener extends StatefulWidget {
  final Widget child;
  final Function(String barcode) onBarcodeScanned;
  final int scanTimeoutMs;

  const KeyboardBarcodeListener({
    super.key,
    required this.child,
    required this.onBarcodeScanned,
    this.scanTimeoutMs = 100,
  });

  @override
  State<KeyboardBarcodeListener> createState() => _KeyboardBarcodeListenerState();
}

class _KeyboardBarcodeListenerState extends State<KeyboardBarcodeListener> {
  final StringBuffer _barcodeBuffer = StringBuffer();
  DateTime _lastKeyTime = DateTime.now();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;

    final now = DateTime.now();
    final timeDiff = now.difference(_lastKeyTime).inMilliseconds;
    
    // If too much time passed, clear buffer (manual typing vs scanner)
    if (timeDiff > widget.scanTimeoutMs && _barcodeBuffer.isNotEmpty) {
      _barcodeBuffer.clear();
    }
    
    _lastKeyTime = now;

    // Handle Enter key (end of barcode)
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_barcodeBuffer.length >= 8) {
        // Valid barcode length (EAN-8 or longer)
        widget.onBarcodeScanned(_barcodeBuffer.toString());
      }
      _barcodeBuffer.clear();
      return;
    }

    // Add numeric characters to buffer
    final char = event.character;
    if (char != null && RegExp(r'[0-9]').hasMatch(char)) {
      _barcodeBuffer.write(char);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: widget.child,
    );
  }
}

/// Barcode scanner dialog for manual entry or camera scan
class BarcodeScannerDialog extends StatefulWidget {
  final Function(String barcode) onBarcodeScanned;

  const BarcodeScannerDialog({super.key, required this.onBarcodeScanned});

  @override
  State<BarcodeScannerDialog> createState() => _BarcodeScannerDialogState();
}

class _BarcodeScannerDialogState extends State<BarcodeScannerDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isScanning = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitBarcode() {
    final barcode = _controller.text.trim();
    if (barcode.length >= 8) {
      widget.onBarcodeScanned(barcode);
      Navigator.pop(context);
    }
  }

  void _startCameraScan() {
    setState(() => _isScanning = true);
    
    // Simulate camera scan (in real implementation, use mobile_scanner package)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isScanning = false);
        // Simulate finding a barcode
        widget.onBarcodeScanned('8991234567892');
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E2E),
      title: Row(
        children: const [
          Icon(Icons.qr_code_scanner, color: Color(0xFF3B82F6)),
          SizedBox(width: 12),
          Text('Scan Barcode', style: TextStyle(color: Colors.white)),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Camera preview placeholder
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: _isScanning
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          CircularProgressIndicator(color: Color(0xFF3B82F6)),
                          SizedBox(height: 16),
                          Text('Scanning...', style: TextStyle(color: Colors.white)),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt, color: Colors.white54, size: 48),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _startCameraScan,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start Camera'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            const Row(
              children: [
                Expanded(child: Divider(color: Colors.white24)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR', style: TextStyle(color: Colors.white54)),
                ),
                Expanded(child: Divider(color: Colors.white24)),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Manual entry
            TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter barcode manually',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF2A2A3E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Color(0xFF3B82F6)),
                  onPressed: _submitBarcode,
                ),
              ),
              onSubmitted: (_) => _submitBarcode(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitBarcode,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

/// Quick barcode lookup widget for retail dashboard
class BarcodeSearchField extends StatelessWidget {
  final Function(String barcode) onBarcodeScanned;

  const BarcodeSearchField({super.key, required this.onBarcodeScanned});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3A3A4E)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.qr_code_scanner, color: Colors.white54, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Scan or enter barcode...',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: onBarcodeScanned,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.white54, size: 20),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => BarcodeScannerDialog(
                  onBarcodeScanned: onBarcodeScanned,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
