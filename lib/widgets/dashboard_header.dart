import 'package:flutter/material.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.title,
    required this.userName,
    required this.onMenuTap,
    required this.onAccountSettings,
    required this.onLogout,
    this.photoUrl,
  });

  final String title;
  final String userName;
  final String? photoUrl;
  final VoidCallback onMenuTap;
  final VoidCallback onAccountSettings;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Material(
            color: const Color(0xFFFFEDD5),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onMenuTap,
              borderRadius: BorderRadius.circular(10),
              child: const SizedBox(
                width: 39,
                height: 39,
                child: Icon(
                  Icons.menu_rounded,
                  color: Color(0xFFF97316),
                  size: 21,
                ),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Profile and account actions',
            onSelected: (action) async {
              if (action == 'settings') {
                onAccountSettings();
              } else if (action == 'logout') {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Log out?'),
                    content: const Text(
                      'Are you sure you want to log out of GearTrack POS?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: const Text('Log out'),
                      ),
                    ],
                  ),
                );
                if (shouldLogout == true) await onLogout();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.manage_accounts_outlined),
                  title: Text('Account settings'),
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.logout_rounded),
                  title: Text('Log out'),
                ),
              ),
            ],
            child: CircleAvatar(
              radius: 17,
              backgroundColor: const Color(0xFFFFEDD5),
              foregroundImage: photoUrl == null || photoUrl!.isEmpty
                  ? null
                  : NetworkImage(photoUrl!),
              child: photoUrl == null || photoUrl!.isEmpty
                  ? Text(
                      userName.isEmpty ? 'A' : userName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
