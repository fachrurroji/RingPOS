import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';

// Settings state
final printerConnectedProvider = StateProvider<bool>((ref) => false);
final printerNameProvider = StateProvider<String?>((ref) => null);
final taxRateProvider = StateProvider<double>((ref) => 11.0);
final currencyProvider = StateProvider<String>((ref) => 'IDR');
final receiptFooterProvider = StateProvider<String>((ref) => 'Thank you for shopping!');

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: AppTheme.secondaryDark,
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(title: 'Store Information'),
                  _SettingsCard(
                    children: [
                      _TextField(
                        label: 'Store Name',
                        value: 'RingPOS Demo Store',
                        onChanged: (v) {},
                      ),
                      const SizedBox(height: 16),
                      _TextField(
                        label: 'Store Address',
                        value: 'Jl. Sudirman No. 123, Jakarta',
                        onChanged: (v) {},
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      _TextField(
                        label: 'Phone Number',
                        value: '+62 21 1234567',
                        onChanged: (v) {},
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  _SectionTitle(title: 'Tax & Currency'),
                  _SettingsCard(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _TextField(
                              label: 'Tax Rate (%)',
                              value: ref.watch(taxRateProvider).toString(),
                              onChanged: (v) {
                                final rate = double.tryParse(v);
                                if (rate != null) {
                                  ref.read(taxRateProvider.notifier).state = rate;
                                }
                              },
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _DropdownField(
                              label: 'Currency',
                              value: ref.watch(currencyProvider),
                              items: const ['IDR', 'USD', 'MYR', 'SGD'],
                              onChanged: (v) {
                                if (v != null) {
                                  ref.read(currencyProvider.notifier).state = v;
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  _SectionTitle(title: 'Receipt Settings'),
                  _SettingsCard(
                    children: [
                      _TextField(
                        label: 'Receipt Footer Message',
                        value: ref.watch(receiptFooterProvider),
                        onChanged: (v) => ref.read(receiptFooterProvider.notifier).state = v,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      _SwitchTile(
                        title: 'Auto-print receipt',
                        subtitle: 'Print receipt automatically after payment',
                        value: true,
                        onChanged: (v) {},
                      ),
                      _SwitchTile(
                        title: 'Print item details',
                        subtitle: 'Show individual item prices on receipt',
                        value: true,
                        onChanged: (v) {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 24),
            
            // Right Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(title: 'Printer'),
                  _SettingsCard(
                    children: [
                      _PrinterStatus(ref: ref),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showPrinterDialog(context, ref),
                          icon: const Icon(Icons.bluetooth_searching),
                          label: const Text('Scan for Printers'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.accentBlue,
                            side: const BorderSide(color: AppTheme.accentBlue),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _testPrint(context, ref),
                          icon: const Icon(Icons.print),
                          label: const Text('Test Print'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                            side: const BorderSide(color: AppTheme.borderColor),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  _SectionTitle(title: 'Cash Drawer'),
                  _SettingsCard(
                    children: [
                      _SwitchTile(
                        title: 'Auto-open drawer',
                        subtitle: 'Open drawer after cash payment',
                        value: true,
                        onChanged: (v) {},
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _openCashDrawer(context),
                          icon: const Icon(Icons.point_of_sale),
                          label: const Text('Open Cash Drawer'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                            side: const BorderSide(color: AppTheme.borderColor),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  _SectionTitle(title: 'Sync & Backup'),
                  _SettingsCard(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.cloud_done, color: AppTheme.accentGreen),
                        ),
                        title: const Text('Last synced', style: TextStyle(color: AppTheme.textPrimary)),
                        subtitle: const Text('Today at 14:23', style: TextStyle(color: AppTheme.textSecondary)),
                        trailing: TextButton(
                          onPressed: () {},
                          child: const Text('Sync Now'),
                        ),
                      ),
                      const Divider(color: AppTheme.borderColor),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.accentBlue.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.backup, color: AppTheme.accentBlue),
                        ),
                        title: const Text('Backup data', style: TextStyle(color: AppTheme.textPrimary)),
                        subtitle: const Text('Export all transactions', style: TextStyle(color: AppTheme.textSecondary)),
                        trailing: TextButton(
                          onPressed: () {},
                          child: const Text('Export'),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  _SectionTitle(title: 'About'),
                  _SettingsCard(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('RingPOS', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                        subtitle: const Text('Version 1.0.0', style: TextStyle(color: AppTheme.textSecondary)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrinterDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryDark,
        title: Row(
          children: const [
            Icon(Icons.bluetooth, color: AppTheme.accentBlue),
            SizedBox(width: 12),
            Text('Available Printers', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: SizedBox(
          width: 400,
          height: 300,
          child: Column(
            children: [
              const LinearProgressIndicator(),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    _PrinterTile(
                      name: 'EPSON TM-T82',
                      address: 'BT:AA:BB:CC:DD:EE',
                      onTap: () {
                        ref.read(printerConnectedProvider.notifier).state = true;
                        ref.read(printerNameProvider.notifier).state = 'EPSON TM-T82';
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Connected to EPSON TM-T82'),
                            backgroundColor: AppTheme.accentGreen,
                          ),
                        );
                      },
                    ),
                    _PrinterTile(
                      name: 'XPrinter XP-58',
                      address: 'BT:11:22:33:44:55',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _testPrint(BuildContext context, WidgetRef ref) {
    final connected = ref.read(printerConnectedProvider);
    if (!connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No printer connected'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Printing test page...'),
        backgroundColor: AppTheme.accentBlue,
      ),
    );
  }

  void _openCashDrawer(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening cash drawer...'),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final String label;
  final String value;
  final Function(String) onChanged;
  final int maxLines;
  final TextInputType keyboardType;

  const _TextField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value,
          style: const TextStyle(color: AppTheme.textPrimary),
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.secondaryDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final Function(String?) onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.secondaryDark,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: AppTheme.secondaryDark,
            style: const TextStyle(color: AppTheme.textPrimary),
            items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final Function(bool) onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(color: AppTheme.textPrimary)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      activeColor: AppTheme.accentBlue,
    );
  }
}

class _PrinterStatus extends StatelessWidget {
  final WidgetRef ref;
  const _PrinterStatus({required this.ref});

  @override
  Widget build(BuildContext context) {
    final connected = ref.watch(printerConnectedProvider);
    final printerName = ref.watch(printerNameProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryDark,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: connected ? AppTheme.accentGreen.withOpacity(0.15) : Colors.red.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              connected ? Icons.print : Icons.print_disabled,
              color: connected ? AppTheme.accentGreen : Colors.red,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connected ? 'Connected' : 'Not Connected',
                  style: TextStyle(
                    color: connected ? AppTheme.accentGreen : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (printerName != null)
                  Text(
                    printerName,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
              ],
            ),
          ),
          if (connected)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () {
                ref.read(printerConnectedProvider.notifier).state = false;
                ref.read(printerNameProvider.notifier).state = null;
              },
            ),
        ],
      ),
    );
  }
}

class _PrinterTile extends StatelessWidget {
  final String name;
  final String address;
  final VoidCallback onTap;

  const _PrinterTile({
    required this.name,
    required this.address,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.accentBlue.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.print, color: AppTheme.accentBlue),
      ),
      title: Text(name, style: const TextStyle(color: AppTheme.textPrimary)),
      subtitle: Text(address, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
    );
  }
}
