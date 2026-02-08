import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'features/auth/login_screen.dart';
import 'features/onboarding/mode_selection_screen.dart';
import 'features/dashboard/dashboard_router.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/reporting/screens/reporting_screen.dart';
import 'features/inventory/screens/stock_management_screen.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'features/superadmin/screens/superadmin_dashboard_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: RingPosApp(),
    ),
  );
}

class RingPosApp extends StatelessWidget {
  const RingPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RingPOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/mode_selection': (context) => const ModeSelectionScreen(),
        '/dashboard': (context) => const DashboardRouter(),
        '/settings': (context) => const SettingsScreen(),
        '/reports': (context) => const ReportingScreen(),
        '/stock': (context) => const StockManagementScreen(),
        '/admin': (context) => const AdminDashboardScreen(),
        '/admin/dashboard': (context) => const AdminDashboardScreen(),
        '/superadmin': (context) => const SuperadminDashboardScreen(),
      },
    );
  }
}

