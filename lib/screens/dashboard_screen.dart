import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/dashboard_profile.dart';
import '../services/dashboard_service.dart';
import '../services/store_service.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/settings_panel.dart';
import '../widgets/sidebar.dart';
import 'analytics_page.dart';
import 'home_dashboard_screen.dart';
import 'inventory_page.dart';
import 'pos_register.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  static const _background = Color(0xFFF8FAFC);
  static const _navy = Color(0xFF1E293B);

  final _dashboardService = DashboardService();
  final _storeService = StoreService();
  String _activeDestination = 'Home Dashboard';

  Future<void> _logout() async {
    try {
      await _dashboardService.signOut();
    } catch (error) {
      if (!mounted) return;
      _showMessage('Unable to log out: $error', error: true);
    }
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? const Color(0xFF991B1B) : _navy,
        ),
      );
  }

  Widget _page(String userName, DashboardProfile? profile) {
    switch (_activeDestination) {
      case 'POS Register':
        return PosRegisterPage(storeService: _storeService);
      case 'Inventory Control':
        return InventoryPage(storeService: _storeService);
      case 'Sales Analytics':
        return AnalyticsPage(storeService: _storeService);
      case 'Settings':
        return SettingsPanel(
          displayName: profile?.displayName,
          email: profile?.email,
        );
      default:
        return HomeDashboardPage(
          userName: userName,
          storeService: _storeService,
          onNavigate: (destination) {
            setState(() => _activeDestination = destination);
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _dashboardService.currentProfile;
    final userName = profile?.userName ?? 'Admin';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _background,
      ),
      child: Scaffold(
        backgroundColor: _background,
        drawer: GearTrackSidebar(
          activeDestination: _activeDestination,
          userName: userName,
          email: profile?.email ?? '',
          role: 'ADMIN · ALL ACCESS',
          onDestinationSelected: (destination) {
            setState(() => _activeDestination = destination);
          },
          onLogout: _logout,
        ),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.9, -0.55),
              radius: 1.25,
              colors: [Color(0xFFFFF1E8), _background],
              stops: [0, 0.82],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Builder(
                  builder: (menuContext) => DashboardHeader(
                    title: _activeDestination,
                    userName: userName,
                    photoUrl: profile?.photoUrl,
                    onMenuTap: () => Scaffold.of(menuContext).openDrawer(),
                    onAccountSettings: () {
                      setState(() => _activeDestination = 'Settings');
                    },
                    onLogout: _logout,
                  ),
                ),
                Expanded(
                  child: KeyedSubtree(
                    key: ValueKey(_activeDestination),
                    child: _page(userName, profile),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
