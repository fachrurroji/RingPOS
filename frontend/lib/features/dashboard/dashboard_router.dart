import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../onboarding/mode_selection_screen.dart';
import '../retail/screens/retail_dashboard_screen.dart';
import '../fnb/screens/fnb_dashboard_screen.dart';
import '../service/screens/service_dashboard_screen.dart';

class DashboardRouter extends ConsumerWidget {
  const DashboardRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(selectedModeProvider);

    return _buildDashboard(mode);
  }

  Widget _buildDashboard(String mode) {
    switch (mode) {
      case 'RETAIL':
        return const RetailDashboardScreen();
      case 'FB':
        return const FnBDashboardScreen();
      case 'SERVICE':
        return const ServiceDashboardScreen();
      default:
        return const Center(child: Text('Unknown Mode'));
    }
  }
}
