import 'package:flutter/material.dart';

class RetailDashboard extends StatelessWidget {
  const RetailDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue[50],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store_mall_directory, size: 80, color: Colors.blue),
            const SizedBox(height: 16),
            const Text('Retail Dashboard', style: TextStyle(fontSize: 24)),
            const Text('Feature Focus: Barcode Scanning, High Volume'),
          ],
        ),
      ),
    );
  }
}
