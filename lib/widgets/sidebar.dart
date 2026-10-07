import 'package:flutter/material.dart';

class GearTrackSidebar extends StatelessWidget {
  const GearTrackSidebar({
    super.key,
    required this.onDestinationSelected,
    required this.onLogout,
    this.activeDestination = 'Home Dashboard',
    this.userName = 'Admin',
    this.email = '',
    this.role = 'ADMIN',
  });

  static const _background = Color(0xFFF8FAFC);
  static const _surface = Color(0xFFFFFFFF);
  static const _border = Color(0xFFE2E8F0);
  static const _text = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _orange = Color(0xFFF97316);
  static const _navy = Color(0xFF1E293B);
  final ValueChanged<String> onDestinationSelected;
  final Future<void> Function() onLogout;
  final String activeDestination;
  final String userName;
  final String email;
  final String role;

  static const _destinations = [
    _SidebarDestination(label: 'Home Dashboard', icon: Icons.home_outlined),
    _SidebarDestination(
      label: 'POS Register',
      icon: Icons.shopping_bag_outlined,
    ),
    _SidebarDestination(
      label: 'Inventory Control',
      icon: Icons.inventory_2_outlined,
    ),
    _SidebarDestination(
      label: 'Sales Analytics',
      icon: Icons.bar_chart_rounded,
    ),
    _SidebarDestination(label: 'Settings', icon: Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 300,
      backgroundColor: _background,
      child: SafeArea(
        child: Column(
          children: [
            _ProfileHeader(userName: userName, email: email, role: role),
            const Divider(height: 1, color: _border),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                children: [
                  for (final destination in _destinations)
                    _DestinationTile(
                      destination: destination,
                      selected: activeDestination == destination.label,
                      onTap: () {
                        Navigator.of(context).pop();
                        onDestinationSelected(destination.label);
                      },
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: _border),
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 10, 13, 12),
              child: _LogoutButton(onLogout: onLogout),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.userName,
    required this.email,
    required this.role,
  });

  final String userName;
  final String email;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 27, 18, 24),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFFFEDD5),
                child: Icon(
                  Icons.person,
                  color: GearTrackSidebar._navy,
                  size: 27,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: GearTrackSidebar._text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: GearTrackSidebar._muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: GearTrackSidebar._surface,
              border: Border.all(color: GearTrackSidebar._border),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEDD5),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: const TextStyle(
                      color: GearTrackSidebar._orange,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationTile extends StatelessWidget {
  const _DestinationTile({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _SidebarDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? GearTrackSidebar._orange
        : GearTrackSidebar._muted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: selected ? const Color(0xFFFFF1E8) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 48,
            child: Row(
              children: [
                const SizedBox(width: 13),
                Icon(destination.icon, size: 20, color: foreground),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    destination.label,
                    style: TextStyle(
                      color: selected
                          ? GearTrackSidebar._orange
                          : GearTrackSidebar._text,
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 3,
                    height: 22,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: GearTrackSidebar._orange,
                      borderRadius: BorderRadius.circular(4),
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

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onLogout});

  final Future<void> Function() onLogout;

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: GearTrackSidebar._surface,
        title: const Text(
          'Log out?',
          style: TextStyle(color: GearTrackSidebar._text),
        ),
        content: const Text(
          'Are you sure you want to log out of GearTrack POS?',
          style: TextStyle(color: GearTrackSidebar._muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: GearTrackSidebar._muted),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: GearTrackSidebar._orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await onLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => _confirmLogout(context),
        icon: const Icon(Icons.logout_rounded, size: 19),
        label: const Text('Log out'),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          foregroundColor: const Color(0xFFDC2626),
          side: const BorderSide(color: Color(0xFFFECACA)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class _SidebarDestination {
  const _SidebarDestination({required this.label, required this.icon});

  final String label;
  final IconData icon;
}
