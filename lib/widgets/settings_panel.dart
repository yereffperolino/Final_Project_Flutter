import 'package:flutter/material.dart';

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({
    super.key,
    required this.displayName,
    required this.email,
  });

  final String? displayName;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final name = displayName?.trim();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Store settings',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Basic account and store connection details.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
              const SizedBox(height: 16),
              _SettingValue(
                label: 'Signed-in user',
                value: name == null || name.isEmpty ? 'Admin' : name,
                icon: Icons.person_outline,
              ),
              const Divider(height: 22),
              _SettingValue(
                label: 'Email',
                value: email ?? 'Not available',
                icon: Icons.email_outlined,
              ),
              const Divider(height: 22),
              const _SettingValue(
                label: 'Store data',
                value: 'Synced to this signed-in Firebase account',
                icon: Icons.cloud_done_outlined,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Products, inventory movements, and sales update live through Firebase Firestore.',
          style: TextStyle(
            color: Color(0xFF64748B),
            height: 1.5,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _SettingValue extends StatelessWidget {
  const _SettingValue({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFF97316), size: 20),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
