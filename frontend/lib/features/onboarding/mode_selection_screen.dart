import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';

// Simple provider to store the selected mode
final selectedModeProvider = StateProvider<String>((ref) => 'RETAIL');
final configProvider = StateProvider<Map<String, dynamic>>((ref) => {});

class ModeSelectionScreen extends ConsumerStatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  ConsumerState<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends ConsumerState<ModeSelectionScreen> {
  bool _isLoading = false;

  void _selectMode(String mode) async {
    setState(() => _isLoading = true);
    
    // Simulate API call to fetch config
    await Future.delayed(const Duration(milliseconds: 800));

    ref.read(selectedModeProvider.notifier).state = mode;
    
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.point_of_sale, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Select Your Business Type',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This selection will customize your POS dashboard',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                  ),
                  const SizedBox(height: 48),
                  Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    alignment: WrapAlignment.center,
                    children: [
                      _ModeCard(
                        title: 'RETAIL',
                        subtitle: 'Toko Kelontong, Minimarket',
                        icon: Icons.store_mall_directory,
                        color: AppTheme.accentBlue,
                        features: ['Barcode Scanning', 'Wholesale Pricing', 'Quick Keys'],
                        onTap: () => _selectMode('RETAIL'),
                      ),
                      _ModeCard(
                        title: 'F&B',
                        subtitle: 'Resto, Cafe, Warkop',
                        icon: Icons.restaurant,
                        color: AppTheme.accentOrange,
                        features: ['Table Map', 'Kitchen Print', 'Menu Modifiers'],
                        onTap: () => _selectMode('FB'),
                      ),
                      _ModeCard(
                        title: 'SERVICE',
                        subtitle: 'Laundry, Repair Shop',
                        icon: Icons.local_laundry_service,
                        color: AppTheme.accentGreen,
                        features: ['Kanban Board', 'Status Pipeline', 'WhatsApp Notify'],
                        onTap: () => _selectMode('SERVICE'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppTheme.accentBlue),
                    const SizedBox(height: 24),
                    const Text(
                      'Configuring Dashboard...',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Fetching settings from server',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> features;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.features,
    required this.onTap,
  });

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _isHovered
            ? (Matrix4.identity()..translate(0, -8))
            : Matrix4.identity(),
        child: Material(
          color: AppTheme.secondaryDark,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isHovered ? widget.color : AppTheme.borderColor,
                  width: _isHovered ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 32),
                  ),
                  const SizedBox(height: 20),
                  
                  // Title
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: widget.color,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Features
                  ...widget.features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.check, color: widget.color, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          feature,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )),
                  
                  const SizedBox(height: 16),
                  
                  // Select Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: widget.onTap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: widget.color,
                        side: BorderSide(color: widget.color),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('SELECT'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
